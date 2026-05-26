import { distributedKVStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { distributedDeviceManager } from '@kit.DistributedServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

export interface TransferDevice {
  deviceName: string;
  deviceType: string;
  networkId: string;
  displayName: string;
}

export interface TransferTodoData {
  key: string;
  name: string;
  createdAt: number;
  priority: number;
  isCompleted: boolean;
  focusCount: number;
  focusDurationMinutes: number;
  deadline: number;
}

export interface TaskTransferPayload {
  transferId: string;
  sourceDeviceId?: string;
  sourceDeviceName: string;
  sentAt: number;
  task: TransferTodoData;
}

const TASK_TRANSFER_STORE_ID: string = 'todo_task_transfer_store';
const TASK_TRANSFER_KEY_PREFIX: string = 'todo_transfer_';

export class TaskTransferService {
  private context: common.UIAbilityContext | null = null;
  private deviceManager: distributedDeviceManager.DeviceManager | null = null;
  private kvManager: distributedKVStore.KVManager | null = null;
  private kvStore: distributedKVStore.SingleKVStore | null = null;
  private onReceiveTask: ((payload: TaskTransferPayload) => void) | null = null;
  private hasSubscribed: boolean = false;

  async init(context: common.UIAbilityContext, onReceiveTask: (payload: TaskTransferPayload) => void): Promise<void> {
    this.context = context;
    this.onReceiveTask = onReceiveTask;
    this.ensureDeviceManager();
    await this.ensureKVStore();
    this.subscribeRemoteTasks();
    await this.loadPendingTasks();
  }

  async getAvailableDevices(): Promise<TransferDevice[]> {
    this.ensureDeviceManager();
    if (this.deviceManager === null) {
      return [];
    }
    let devices = await this.deviceManager.getAvailableDeviceList();
    return devices
      .filter((device: distributedDeviceManager.DeviceBasicInfo) => {
        return typeof device.networkId === 'string' && device.networkId.length > 0;
      })
      .map((device: distributedDeviceManager.DeviceBasicInfo) => {
        let deviceType = device.deviceType.length > 0 ? device.deviceType : 'device';
        let deviceName = device.deviceName.length > 0 ? device.deviceName : deviceType;
        let networkId = device.networkId === undefined ? '' : device.networkId;
        let transferDevice: TransferDevice = {
          deviceName: deviceName,
          deviceType: deviceType,
          networkId: networkId,
          displayName: `${deviceName} (${deviceType})`
        };
        return transferDevice;
      });
  }

  async sendTask(targetDevice: TransferDevice, payload: TaskTransferPayload): Promise<void> {
    let store = await this.ensureKVStore();
    let transferKey = `${TASK_TRANSFER_KEY_PREFIX}${payload.transferId}`;
    await store.put(transferKey, JSON.stringify(payload));
    await store.enableSync(true);
    try {
      store.sync([targetDevice.networkId], distributedKVStore.SyncMode.PUSH_ONLY, 0);
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0000, 'TaskTransfer', `sync task failed. code=${err.code}, message=${err.message}`);
      throw new Error(err.message);
    }
  }

  async loadPendingTasks(): Promise<void> {
    let store = await this.ensureKVStore();
    let query = new distributedKVStore.Query();
    let entries = await store.getEntries(query.prefixKey(TASK_TRANSFER_KEY_PREFIX));
    this.handleEntries(entries);
  }

  buildTransferId(): string {
    return `${Date.now()}_${Math.round(Math.random() * 1000000)}`;
  }

  getLocalDeviceId(): string {
    this.ensureDeviceManager();
    if (this.deviceManager === null) {
      return '';
    }
    try {
      return this.deviceManager.getLocalDeviceNetworkId();
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0000, 'TaskTransfer', `get local device id failed. code=${err.code}, message=${err.message}`);
      return '';
    }
  }

  getLocalDeviceName(): string {
    this.ensureDeviceManager();
    if (this.deviceManager === null) {
      return '';
    }
    try {
      return this.deviceManager.getLocalDeviceName();
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0000, 'TaskTransfer', `get local device name failed. code=${err.code}, message=${err.message}`);
      return '';
    }
  }

  private ensureDeviceManager() {
    if (this.deviceManager !== null || this.context === null) {
      return;
    }
    try {
      this.deviceManager = distributedDeviceManager.createDeviceManager(this.context.abilityInfo.bundleName);
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0000, 'TaskTransfer', `create device manager failed. code=${err.code}, message=${err.message}`);
      this.deviceManager = null;
    }
  }

  private async ensureKVStore(): Promise<distributedKVStore.SingleKVStore> {
    if (this.kvStore !== null) {
      return this.kvStore;
    }
    if (this.context === null) {
      throw new Error('TaskTransferService context is not ready.');
    }
    try {
      if (this.kvManager === null) {
        this.kvManager = distributedKVStore.createKVManager({
          bundleName: this.context.abilityInfo.bundleName,
          context: this.context
        });
      }
      this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(
        TASK_TRANSFER_STORE_ID,
        {
          createIfMissing: true,
          encrypt: false,
          backup: false,
          autoSync: true,
          kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
          securityLevel: distributedKVStore.SecurityLevel.S1
        }
      );
      return this.kvStore;
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0000, 'TaskTransfer', `init kv store failed. code=${err.code}, message=${err.message}`);
      this.kvStore = null;
      throw new Error(err.message);
    }
  }

  private subscribeRemoteTasks() {
    if (this.kvStore === null || this.hasSubscribed) {
      return;
    }
    try {
      this.kvStore.on('dataChange', distributedKVStore.SubscribeType.SUBSCRIBE_TYPE_REMOTE,
        (notification: distributedKVStore.ChangeNotification) => {
          this.handleEntries([...notification.insertEntries, ...notification.updateEntries]);
        });
      this.hasSubscribed = true;
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0000, 'TaskTransfer', `subscribe remote task failed. code=${err.code}, message=${err.message}`);
    }
  }

  private handleEntries(entries: distributedKVStore.Entry[]) {
    entries.forEach((entry: distributedKVStore.Entry) => {
      if (!entry.key.startsWith(TASK_TRANSFER_KEY_PREFIX) || typeof entry.value.value !== 'string') {
        return;
      }
      try {
        let payload = JSON.parse(entry.value.value) as TaskTransferPayload;
        if (payload.sourceDeviceId === this.getLocalDeviceId()) {
          return;
        }
        if (this.isValidPayload(payload) && this.onReceiveTask !== null) {
          this.onReceiveTask(payload);
        }
      } catch (error) {
        let err = error as BusinessError;
        hilog.error(0x0000, 'TaskTransfer', `parse transfer payload failed. code=${err.code}, message=${err.message}`);
      }
    });
  }

  private isValidPayload(payload: TaskTransferPayload): boolean {
    return payload !== undefined &&
      typeof payload.transferId === 'string' &&
      payload.transferId.length > 0 &&
      payload.task !== undefined &&
      typeof payload.task.name === 'string' &&
      payload.task.name.length > 0;
  }
}
