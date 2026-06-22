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
  taskType: string;
  plannedFocusMinutes: number;
  category: string;
  repeatType: string;
  cardThemeIndex: number;
}

export interface TransferFocusData {
  taskTitle: string;
  remainingSeconds: number;
  totalSeconds: number;
  isPaused: boolean;
}

export interface TaskTransferPayload {
  type?: string;
  version?: number;
  transferId: string;
  sourceDeviceId?: string;
  sourceDeviceName: string;
  fromDevice?: string;
  sentAt: number;
  timestamp?: number;
  task: TransferTodoData;
}

export interface FocusTransferPayload {
  type: string;
  version: number;
  transferId: string;
  sourceDeviceId?: string;
  sourceDeviceName: string;
  fromDevice: string;
  sentAt: number;
  timestamp: number;
  focus: TransferFocusData;
}

export interface TransferResult {
  success: boolean;
  fallback: boolean;
  message: string;
}

export type FreeFlowPayload = TaskTransferPayload | FocusTransferPayload;

const TASK_TRANSFER_STORE_ID: string = 'todo_task_transfer_store';
const TASK_TRANSFER_KEY_PREFIX: string = 'todo_transfer_';
const FOCUS_TRANSFER_KEY_PREFIX: string = 'focus_transfer_';

export class TaskTransferService {
  private context: common.UIAbilityContext | null = null;
  private deviceManager: distributedDeviceManager.DeviceManager | null = null;
  private kvManager: distributedKVStore.KVManager | null = null;
  private kvStore: distributedKVStore.SingleKVStore | null = null;
  private onReceivePayload: ((payload: FreeFlowPayload) => void) | null = null;
  private hasSubscribed: boolean = false;

  async init(context: common.UIAbilityContext, onReceivePayload: (payload: FreeFlowPayload) => void): Promise<void> {
    this.context = context;
    this.onReceivePayload = onReceivePayload;
    this.ensureDeviceManager();
    await this.ensureKVStore();
    this.subscribeRemotePayloads();
    await this.loadPendingPayloads();
  }

  async getAvailableDevices(): Promise<TransferDevice[]> {
    this.ensureDeviceManager();
    let localDevice = this.getFallbackLocalDevice();
    if (this.deviceManager === null) {
      return this.getFallbackDevices(localDevice);
    }
    try {
      let devices = await this.deviceManager.getAvailableDeviceList();
      let remoteDevices = devices
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
      if (remoteDevices.length === 0) {
        return this.getFallbackDevices(localDevice);
      }
      return [localDevice, ...remoteDevices];
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0000, 'TaskTransfer', `get available devices failed. code=${err.code}, message=${err.message}`);
      return this.getFallbackDevices(localDevice);
    }
  }

  async transferTaskToDevice(task: TransferTodoData, deviceId: string): Promise<TransferResult> {
    let targetDevice = await this.getDeviceById(deviceId);
    let payload = this.buildTaskTransferPayload(task);
    return this.sendPayload(targetDevice, payload, TASK_TRANSFER_KEY_PREFIX);
  }

  async transferFocusState(focus: TransferFocusData, deviceId: string): Promise<TransferResult> {
    let targetDevice = await this.getDeviceById(deviceId);
    let payload = this.buildFocusTransferPayload(focus);
    return this.sendPayload(targetDevice, payload, FOCUS_TRANSFER_KEY_PREFIX);
  }

  receiveTransferredTask(payloadText: string): TaskTransferPayload | null {
    try {
      let parsed = JSON.parse(payloadText) as TaskTransferPayload;
      if (this.isValidTaskPayload(parsed)) {
        return this.normalizeTaskPayload(parsed);
      }
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0000, 'TaskTransfer', `receive transferred task failed. code=${err.code}, message=${err.message}`);
    }
    return null;
  }

  async sendTask(targetDevice: TransferDevice, payload: TaskTransferPayload): Promise<void> {
    let result = await this.sendPayload(targetDevice, this.normalizeTaskPayload(payload), TASK_TRANSFER_KEY_PREFIX);
    if (!result.success) {
      throw new Error(result.message);
    }
  }

  private async sendPayload(targetDevice: TransferDevice, payload: FreeFlowPayload, keyPrefix: string): Promise<TransferResult> {
    let store = await this.ensureKVStore();
    let transferKey = `${keyPrefix}${payload.transferId}`;
    await store.put(transferKey, JSON.stringify(payload));
    await store.enableSync(true);
    if (this.isFallbackDevice(targetDevice)) {
      this.dispatchLocalPayload(payload);
      return {
        success: true,
        fallback: true,
        message: '\u672A\u53D1\u73B0\u771F\u5B9E\u8BBE\u5907\uFF0C\u5DF2\u8FDB\u5165\u672C\u5730\u53EF\u9A8C\u8BC1\u6D41\u8F6C\u6F14\u793A'
      };
    }
    try {
      store.sync([targetDevice.networkId], distributedKVStore.SyncMode.PUSH_ONLY, 0);
      return {
        success: true,
        fallback: false,
        message: '\u5DF2\u5199\u5165\u5206\u5E03\u5F0FKV\u5E76\u53D1\u8D77\u8BBE\u5907\u540C\u6B65'
      };
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0000, 'TaskTransfer', `sync free flow payload failed. code=${err.code}, message=${err.message}`);
      this.dispatchLocalPayload(payload);
      return {
        success: true,
        fallback: true,
        message: `\u771F\u5B9Esync\u5931\u8D25\uFF0C\u5DF2\u4F7F\u7528\u672C\u5730\u515C\u5E95\u6F14\u793A\uFF1A${err.message}`
      };
    }
  }

  async loadPendingPayloads(): Promise<void> {
    let store = await this.ensureKVStore();
    let query = new distributedKVStore.Query();
    let entries = await store.getEntries(query.prefixKey(TASK_TRANSFER_KEY_PREFIX));
    this.handleEntries(entries);
    let focusQuery = new distributedKVStore.Query();
    let focusEntries = await store.getEntries(focusQuery.prefixKey(FOCUS_TRANSFER_KEY_PREFIX));
    this.handleEntries(focusEntries);
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

  private subscribeRemotePayloads() {
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
      hilog.error(0x0000, 'TaskTransfer', `subscribe remote free flow failed. code=${err.code}, message=${err.message}`);
    }
  }

  private handleEntries(entries: distributedKVStore.Entry[]) {
    entries.forEach((entry: distributedKVStore.Entry) => {
      if (!entry.key.startsWith(TASK_TRANSFER_KEY_PREFIX) || typeof entry.value.value !== 'string') {
        return;
      }
      try {
        let payload = JSON.parse(entry.value.value) as FreeFlowPayload;
        if (payload.sourceDeviceId === this.getLocalDeviceId() && !this.isLocalFallbackPayload(payload)) {
          return;
        }
        if (this.isValidPayload(payload) && this.onReceivePayload !== null) {
          this.onReceivePayload(this.normalizePayload(payload));
        }
      } catch (error) {
        let err = error as BusinessError;
        hilog.error(0x0000, 'TaskTransfer', `parse transfer payload failed. code=${err.code}, message=${err.message}`);
      }
    });
  }

  private isValidPayload(payload: FreeFlowPayload): boolean {
    if (this.isValidTaskPayload(payload as TaskTransferPayload)) {
      return true;
    }
    return this.isValidFocusPayload(payload as FocusTransferPayload);
  }

  private isValidTaskPayload(payload: TaskTransferPayload): boolean {
    return payload !== undefined &&
      typeof payload.transferId === 'string' &&
      payload.transferId.length > 0 &&
      payload.task !== undefined &&
      typeof payload.task.name === 'string' &&
      payload.task.name.length > 0;
  }

  private isValidFocusPayload(payload: FocusTransferPayload): boolean {
    return payload !== undefined &&
      typeof payload.transferId === 'string' &&
      payload.transferId.length > 0 &&
      payload.focus !== undefined &&
      typeof payload.focus.taskTitle === 'string' &&
      payload.focus.taskTitle.length > 0;
  }

  private normalizePayload(payload: FreeFlowPayload): FreeFlowPayload {
    if (this.isValidFocusPayload(payload as FocusTransferPayload)) {
      return this.normalizeFocusPayload(payload as FocusTransferPayload);
    }
    return this.normalizeTaskPayload(payload as TaskTransferPayload);
  }

  private normalizeTaskPayload(payload: TaskTransferPayload): TaskTransferPayload {
    let task = payload.task;
    return {
      type: 'todo_transfer',
      version: 1,
      transferId: payload.transferId,
      sourceDeviceId: payload.sourceDeviceId === undefined ? '' : payload.sourceDeviceId,
      sourceDeviceName: payload.sourceDeviceName.length > 0 ? payload.sourceDeviceName : this.getLocalDeviceName(),
      fromDevice: payload.fromDevice === undefined ? payload.sourceDeviceName : payload.fromDevice,
      sentAt: payload.sentAt > 0 ? payload.sentAt : Date.now(),
      timestamp: payload.timestamp === undefined ? payload.sentAt : payload.timestamp,
      task: {
        key: task.key === undefined ? '' : task.key,
        name: task.name,
        createdAt: task.createdAt > 0 ? task.createdAt : Date.now(),
        priority: this.normalizePriority(task.priority),
        isCompleted: task.isCompleted === true,
        focusCount: Math.max(0, task.focusCount),
        focusDurationMinutes: Math.max(0, task.focusDurationMinutes),
        deadline: Math.max(0, task.deadline),
        taskType: task.taskType === undefined ? 'focus' : this.normalizeTaskType(task.taskType),
        plannedFocusMinutes: task.plannedFocusMinutes > 0 ? task.plannedFocusMinutes : 25,
        category: task.category === undefined || task.category.length === 0 ? task.name : task.category,
        repeatType: task.repeatType === undefined || task.repeatType.length === 0 ? '\u4E0D\u91CD\u590D' : task.repeatType,
        cardThemeIndex: task.cardThemeIndex === undefined ? -1 : task.cardThemeIndex
      }
    };
  }

  private normalizeFocusPayload(payload: FocusTransferPayload): FocusTransferPayload {
    return {
      type: 'focus_transfer',
      version: 1,
      transferId: payload.transferId,
      sourceDeviceId: payload.sourceDeviceId === undefined ? '' : payload.sourceDeviceId,
      sourceDeviceName: payload.sourceDeviceName.length > 0 ? payload.sourceDeviceName : this.getLocalDeviceName(),
      fromDevice: payload.fromDevice === undefined ? payload.sourceDeviceName : payload.fromDevice,
      sentAt: payload.sentAt > 0 ? payload.sentAt : Date.now(),
      timestamp: payload.timestamp > 0 ? payload.timestamp : Date.now(),
      focus: {
        taskTitle: payload.focus.taskTitle,
        remainingSeconds: Math.max(0, payload.focus.remainingSeconds),
        totalSeconds: Math.max(60, payload.focus.totalSeconds),
        isPaused: payload.focus.isPaused === true
      }
    };
  }

  private buildTaskTransferPayload(task: TransferTodoData): TaskTransferPayload {
    return this.normalizeTaskPayload({
      type: 'todo_transfer',
      version: 1,
      transferId: this.buildTransferId(),
      sourceDeviceId: this.getLocalDeviceId(),
      sourceDeviceName: this.getLocalDeviceName(),
      fromDevice: this.getLocalDeviceName(),
      sentAt: Date.now(),
      timestamp: Date.now(),
      task: task
    });
  }

  private buildFocusTransferPayload(focus: TransferFocusData): FocusTransferPayload {
    return this.normalizeFocusPayload({
      type: 'focus_transfer',
      version: 1,
      transferId: this.buildTransferId(),
      sourceDeviceId: this.getLocalDeviceId(),
      sourceDeviceName: this.getLocalDeviceName(),
      fromDevice: this.getLocalDeviceName(),
      sentAt: Date.now(),
      timestamp: Date.now(),
      focus: focus
    });
  }

  private async getDeviceById(deviceId: string): Promise<TransferDevice> {
    let devices = await this.getAvailableDevices();
    let matchedDevices = devices.filter((device: TransferDevice) => device.networkId === deviceId);
    if (matchedDevices.length > 0) {
      return matchedDevices[0];
    }
    return this.getFallbackLocalDevice();
  }

  private getFallbackLocalDevice(): TransferDevice {
    let localName = this.getLocalDeviceName();
    return {
      deviceName: localName.length > 0 ? localName : '\u672C\u673A',
      deviceType: 'local',
      networkId: this.getLocalDeviceId().length > 0 ? this.getLocalDeviceId() : 'fallback_local',
      displayName: '\u672C\u673A'
    };
  }

  private getFallbackDevices(localDevice: TransferDevice): TransferDevice[] {
    return [
      localDevice,
      { deviceName: 'MatePad', deviceType: 'tablet', networkId: 'fallback_matepad', displayName: 'MatePad' },
      { deviceName: '\u624B\u673A', deviceType: 'phone', networkId: 'fallback_phone', displayName: '\u624B\u673A' },
      { deviceName: '\u667A\u6167\u5C4F', deviceType: 'tv', networkId: 'fallback_vision', displayName: '\u667A\u6167\u5C4F' },
      { deviceName: '\u7535\u8111', deviceType: 'pc', networkId: 'fallback_pc', displayName: '\u7535\u8111' }
    ];
  }

  private isFallbackDevice(device: TransferDevice): boolean {
    return device.networkId.startsWith('fallback_') || device.networkId === this.getLocalDeviceId();
  }

  private isLocalFallbackPayload(payload: FreeFlowPayload): boolean {
    return payload.sourceDeviceId === this.getLocalDeviceId() && payload.sourceDeviceId.length > 0;
  }

  private dispatchLocalPayload(payload: FreeFlowPayload) {
    if (this.onReceivePayload !== null) {
      this.onReceivePayload(payload);
    }
  }

  private normalizePriority(priority: number): number {
    if (priority < 0) {
      return 0;
    }
    if (priority > 2) {
      return 2;
    }
    return Math.round(priority);
  }

  private normalizeTaskType(taskType: string): string {
    if (taskType === 'once' || taskType === 'todo') {
      return 'once';
    }
    if (taskType === 'habit') {
      return 'habit';
    }
    return 'focus';
  }
}
