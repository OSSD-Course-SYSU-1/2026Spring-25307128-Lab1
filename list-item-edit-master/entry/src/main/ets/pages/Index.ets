/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { ToDo } from '../model/ToDo';
import { ToDoListItem } from '../view/TodoListItem';
import { STYLE_CONFIG, UI_COLORS, Constant } from '../common/Constants';
import { STYLE_COLORS } from '../common/StyleConstants';
import {
  CommonCard,
  CommonCardNoShadow,
  CommonPill,
  CommonProgressBar,
  CommonMetricCard,
  CommonInfoCard,
  CommonTwoColCard
} from '../common/CommonComponents';
import { preferences } from '@kit.ArkData';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  TaskTransferPayload,
  TaskTransferService,
  TransferDevice,
  TransferTodoData
} from '../service/TaskTransferService';

interface StoredToDo {
  key?: string;
  name?: string;
  createdAt?: number;
  priority?: number;
  isCompleted?: boolean;
  focusCount?: number;
  focusDurationMinutes?: number;
  deadline?: number;
}

interface StoredAppState {
  toDoData?: (StoredToDo | null)[];
  score?: number;
  petExp?: number;
  themeIndex?: number;
  unlockedThemes?: boolean[];
  hasCheckedToday?: boolean;
  lastCheckInDate?: string;
  todayPomodoroCount?: number;
  todayPomodoroDate?: string;
  todayCompletedCount?: number;
  todayFocusMinutes?: number;
  todayReadingMinutes?: number;
  dailyGoalDate?: string;
  dailyGoalNames?: string[];
  dailyGoalTargets?: number[];
  dailyGoalRewards?: number[];
  dailyGoalTypes?: number[];
  dailyGoalRewardClaimed?: boolean[];
  dailyGoalEnabled?: boolean[];
  dailyGoalStreak?: number;
  dailyGoalStreakDate?: string;
  ownedOutfits?: boolean[];
  equippedOutfitIndex?: number;
  lastDeliveryRecord?: string;
  realDeliveryStatus?: string;
  lastRealSentTask?: string;
  lastRealReceivedTask?: string;
  lastDeliveryType?: string;
  discoveredDeviceCount?: number;
  receivedTransferIds?: string[];
}

const APP_STATE_PREFERENCES_NAME: string = 'todo_app_state_preferences';
const APP_STATE_KEY: string = 'todo_app_state';
const DISTRIBUTED_DATASYNC_PERMISSION: Permissions = 'ohos.permission.DISTRIBUTED_DATASYNC';

@Extend(Image)
function ImageStyle() {
  .width(STYLE_CONFIG.IMAGE_SIZE)
  .aspectRatio(1)
  .margin(STYLE_CONFIG.IMAGE_MARGIN)
}

@Entry
@Component
struct ToDoList {
  @State toDoData: ToDo[] = [];
  @State score: number = 0;
  @State petExp: number = 0;
  @State themeIndex: number = 0;
  @State hasCheckedToday: boolean = false;
  @State lastCheckInDate: string = '';
  @State todayPomodoroCount: number = 0;
  @State todayCompletedCount: number = 0;
  @State todayFocusMinutes: number = 0;
  @State todayReadingMinutes: number = 0;
  @State dailyGoalNames: string[] = ['\u5B8C\u62103\u4E2A\u4EFB\u52A1', '\u5B8C\u62102\u4E2A\u756A\u8304',
    '\u4E13\u6CE830\u5206\u949F', '\u9605\u8BFB30\u5206\u949F'];
  @State dailyGoalTargets: number[] = [3, 2, 30, 30];
  @State dailyGoalRewards: number[] = [15, 15, 20, 20];
  @State dailyGoalTypes: number[] = [0, 1, 2, 3];
  @State dailyGoalRewardClaimed: boolean[] = [false, false, false, false];
  @State dailyGoalEnabled: boolean[] = [true, true, true, true];
  @State dailyGoalStreak: number = 0;
  @State isAddingGoal: boolean = false;
  @State newGoalName: string = '';
  @State newGoalTargetIndex: number = 0;
  @State newGoalTypeIndex: number = 0;
  @State ownedOutfits: boolean[] = [false, false, false, false, false, false];
  @State equippedOutfitIndex: number = -1;
  @State unlockedThemes: boolean[] = [true, true, false, false, false, false];
  @State lastDeliveryRecord: string = '\u6682\u65E0\u6295\u9001\u8BB0\u5F55';
  @State realDeliveryStatus: string = '\u771F\u5B9E\u6295\u9001\u672A\u5F00\u59CB';
  @State lastRealSentTask: string = '\u6682\u65E0';
  @State lastRealReceivedTask: string = '\u6682\u65E0';
  @State lastDeliveryType: string = '\u771F\u5B9E\u6295\u9001';
  @State discoveredDeviceCount: number = 0;
  @State receivedTransferIds: string[] = [];
  @State searchKeyword: string = '';
  @State sortIndex: number = 0;
  @State currentTab: number = 0;
  @State isWideScreen: boolean = false;
  @State focusTaskKey: string = '';
  @State focusRemainingSeconds: number = 0;
  @State focusTotalSeconds: number = 0;
  @State isFocusRunning: boolean = false;
  @State isFocusFinished: boolean = false;
  @State selectedFocusMinutes: number = 25;
  @State isFocusImmersiveMode: boolean = false;
  @State isFocusRoomVisible: boolean = false;
  @State todayEarlyExitCount: number = 0;
  @State focusThemeIndex: number = 0;

  private focusTimer: number = -1;
  private appPreferences: preferences.Preferences | null = null;
  private taskTransferService: TaskTransferService = new TaskTransferService();
  private realDeliveryDevices: TransferDevice[] = [];
  private hasInitializedTransfer: boolean = false;
  private todayPomodoroDate: string = '';
  private dailyGoalDate: string = '';
  private dailyGoalStreakDate: string = '';
  private themeNames: string[] = ['\u68EE\u7EFF', '\u9759\u6D77', '\u591C\u7D2B', '\u6696\u91D1',
    '\u67D4\u7C89', '\u661F\u591C'];
  private themeColors: string[] = ['#28513F', '#304E63', '#51476F', '#A96F2D', '#A66B80', '#222831'];
  private themeLightColors: string[] = ['#ECF8F0', '#EEF4F8', '#F1EEF8', '#FFF7EA', '#F8EEF3', '#ECEFF3'];
  private themePrices: number[] = [0, 0, 50, 80, 120, 200];
  private deliveryDevices: string[] = ['\u624B\u673A', '\u5E73\u677F', '\u667A\u6167\u5C4F', '\u7535\u8111'];
  private sortNames: string[] = ['\u521B\u5EFA\u65F6\u95F4', '\u540D\u79F0', '\u5B8C\u6210\u72B6\u6001', '\u4F18\u5148\u7EA7'];
  private tabNames: string[] = ['\u9996\u9875', '\u4EFB\u52A1', '\u65E5\u5386', '\u4E13\u6CE8', '\u7EDF\u8BA1', '\u5BA0\u7269', '\u8DE8\u8BBE\u5907', '\u6211\u7684'];
  private visibleTabIndexes: number[] = [0, 1, 2, 4, 5, 7];
  private priorityNames: string[] = ['\u4F4E', '\u4E2D', '\u9AD8'];
  private deadlineNames: string[] = ['\u65E0\u622A\u6B62\u65E5\u671F', '\u4ECA\u5929', '\u660E\u5929', '3\u5929\u540E', '\u4E00\u5468\u540E'];
  private deadlineOffsets: number[] = [-1, 0, 1, 3, 7];
  private focusMinuteNames: string[] = ['5\u5206\u949F', '15\u5206\u949F', '25\u5206\u949F'];
  private focusMinuteValues: number[] = [5, 15, 25];
  private focusRoomNames: string[] = ['\u591C\u665A\u81EA\u4E60\u5BA4', '\u7D2B\u7C89\u665A\u971E', '\u6DF1\u6D77\u4E66\u623F',
    '\u96E8\u591C\u7070\u84DD', '\u65E5\u843D\u7A97\u8FB9', '\u6E05\u6668\u8584\u8377'];
  private focusRoomColors: string[] = ['#101D18', '#241B32', '#102C3A', '#202A32', '#332232', '#14241D'];
  private focusRoomLightColors: string[] = ['#224D7CFE', '#28FFB7C5', '#2440C4FF', '#306B7C93', '#30FF9F43',
    '#5536C98B'];
  private focusRoomAccentColors: string[] = ['#FFB86B', '#FFB7C5', '#7DD3FC', '#C9D4F7', '#FFC46B', '#36C98B'];
  private dailyGoalTypeNames: string[] = ['\u4EFB\u52A1\u5B8C\u6210', '\u756A\u8304\u5B8C\u6210',
    '\u4E13\u6CE8\u5206\u949F', '\u9605\u8BFB\u5206\u949F'];
  private dailyGoalTargetOptions: number[] = [1, 2, 3, 5, 10, 15, 20, 30, 45, 60];
  private dailyGoalTargetNames: string[] = ['1', '2', '3', '5', '10', '15', '20', '30', '45', '60'];
  private outfitNames: string[] = ['\uD83C\uDF92 \u5B66\u4E60\u80CC\u5305', '\uD83D\uDC51 \u81EA\u5F8B\u738B\u51A0',
    '\uD83E\uDDE3 \u4E13\u6CE8\u56F4\u5DFE', '\uD83C\uDF1F \u661F\u5149\u80CC\u666F',
    '\uD83D\uDCDA \u4E66\u672C\u4F19\u4F34', '\uD83C\uDFC5 \u4E13\u6CE8\u5956\u7AE0'];
  private outfitPrices: number[] = [30, 80, 60, 100, 50, 120];
  private motivationalQuotes: string[] = [
    '\u5148\u5F00\u59CB 5 \u5206\u949F\u5C31\u597D\uFF0C\u72B6\u6001\u4F1A\u6162\u6162\u56DE\u6765 \uD83C\uDF31',
    '\u4ECA\u5929\u7684\u5C0F\u52AA\u529B\uFF0C\u4F1A\u53D8\u6210\u672A\u6765\u7684\u5927\u60CA\u559C \u2728',
    '\u5B8C\u6210\u4E00\u4E2A\u756A\u8304\uFF0C\u5C31\u662F\u4ECA\u5929\u7684\u4E00\u6B21\u5C0F\u80DC\u5229 \uD83C\uDF45',
    '\u522B\u6025\uFF0C\u6162\u6162\u6765\u4E5F\u7B97\u524D\u8FDB \u2601\uFE0F',
    '\u4F60\u7684\u52AA\u529B\uFF0C\u5C0F\u4F19\u4F34\u90FD\u770B\u89C1\u5566 \uD83D\uDC3E',
    '\u628A\u4EFB\u52A1\u62C6\u5C0F\u4E00\u70B9\uFF0C\u5C31\u6CA1\u90A3\u4E48\u96BE\u4E86 \uD83D\uDCDA',
    '\u4ECA\u5929\u4E5F\u4E0D\u7528\u5B8C\u7F8E\uFF0C\u53EA\u8981\u6BD4\u6628\u5929\u591A\u4E00\u70B9\u70B9 \uD83C\uDF1F',
    '\u4E13\u6CE8\u4E0D\u662F\u786C\u6491\uFF0C\u662F\u6E29\u67D4\u5730\u628A\u6CE8\u610F\u529B\u5E26\u56DE\u6765 \uD83E\uDDE0',
    '\u5148\u5B8C\u6210\u6700\u5C0F\u7684\u4E00\u6B65\uFF0C\u5269\u4E0B\u7684\u8DEF\u4F1A\u6E05\u695A\u8D77\u6765 \uD83D\uDEB6',
    '\u5B66\u4E60\u5F88\u8F9B\u82E6\uFF0C\u4F46\u4F60\u5DF2\u7ECF\u5728\u8DEF\u4E0A\u4E86 \uD83D\uDD25'
  ];

  aboutToAppear() {
    this.startApp();
  }

  aboutToDisappear() {
    this.clearFocusTimer();
  }

  async startApp(): Promise<void> {
    await this.loadAppState();
    await this.initTaskTransfer();
  }

  async ensurePreferences(): Promise<boolean> {
    if (this.appPreferences !== null) {
      return true;
    }
    let hostContext = this.getUIContext().getHostContext();
    if (hostContext === undefined) {
      hilog.error(0x0000, 'Index', 'getHostContext failed while preparing preferences.');
      return false;
    }
    try {
      this.appPreferences = await preferences.getPreferences(hostContext, APP_STATE_PREFERENCES_NAME);
      return true;
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0000, 'Index', `getPreferences failed. error code=${err.code}, message=${err.message}`);
      return false;
    }
  }

  async loadAppState(): Promise<void> {
    let hasPreferences = await this.ensurePreferences();
    if (!hasPreferences || this.appPreferences === null) {
      return;
    }
    try {
      let storedValue = await this.appPreferences.get(APP_STATE_KEY, '');
      if (typeof storedValue === 'string' && storedValue.length > 0) {
        this.applyStoredAppState(JSON.parse(storedValue) as StoredAppState);
      }
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0000, 'Index', `load app state failed. error code=${err.code}, message=${err.message}`);
    }
    if (this.resetDailyStateIfNeeded()) {
      this.saveAppState();
    }
  }

  applyStoredAppState(storedState: StoredAppState) {
    let storedTodos = storedState.toDoData;
    if (Array.isArray(storedTodos)) {
      let restoredTodos: ToDo[] = [];
      storedTodos.forEach((item: StoredToDo | null) => {
        if (item !== null) {
          restoredTodos.push(this.restoreTodo(item));
        }
      });
      this.toDoData = restoredTodos;
    }
    this.score = this.getStoredNumber(storedState.score, this.score);
    let storedThemeIndex = this.getStoredNumber(storedState.themeIndex, this.themeIndex);
    if (storedThemeIndex >= 0 && storedThemeIndex < this.themeNames.length) {
      this.themeIndex = storedThemeIndex;
    }
    let storedThemes = storedState.unlockedThemes;
    if (Array.isArray(storedThemes)) {
      let updatedThemes = [...this.unlockedThemes];
      storedThemes.forEach((isUnlocked: boolean, index: number) => {
        if (index < updatedThemes.length && typeof isUnlocked === 'boolean') {
          updatedThemes[index] = isUnlocked;
        }
      });
      updatedThemes[0] = true;
      updatedThemes[1] = true;
      this.unlockedThemes = updatedThemes;
    }
    this.hasCheckedToday = this.getStoredBoolean(storedState.hasCheckedToday, this.hasCheckedToday);
    this.lastCheckInDate = this.getStoredString(storedState.lastCheckInDate, this.lastCheckInDate);
    this.todayPomodoroCount = this.getStoredNumber(storedState.todayPomodoroCount, this.todayPomodoroCount);
    this.todayPomodoroDate = this.getStoredString(storedState.todayPomodoroDate, this.lastCheckInDate);
    this.todayCompletedCount = Math.max(0, this.getStoredNumber(storedState.todayCompletedCount,
      this.todayCompletedCount));
    this.todayFocusMinutes = Math.max(0, this.getStoredNumber(storedState.todayFocusMinutes, this.todayFocusMinutes));
    this.todayReadingMinutes = Math.max(0, this.getStoredNumber(storedState.todayReadingMinutes,
      this.todayReadingMinutes));
    this.dailyGoalDate = this.getStoredString(storedState.dailyGoalDate, this.getTodayString());
    this.restoreDailyGoalConfig(storedState);
    let storedGoalClaims = storedState.dailyGoalRewardClaimed;
    if (Array.isArray(storedGoalClaims)) {
      let updatedClaims: boolean[] = [];
      this.dailyGoalNames.forEach(() => {
        updatedClaims.push(false);
      });
      storedGoalClaims.forEach((isClaimed: boolean, index: number) => {
        if (index < updatedClaims.length && typeof isClaimed === 'boolean') {
          updatedClaims[index] = isClaimed;
        }
      });
      this.dailyGoalRewardClaimed = updatedClaims;
    }
    let storedGoalEnabled = storedState.dailyGoalEnabled;
    if (Array.isArray(storedGoalEnabled)) {
      let updatedEnabled: boolean[] = [];
      this.dailyGoalNames.forEach(() => {
        updatedEnabled.push(true);
      });
      storedGoalEnabled.forEach((isEnabled: boolean, index: number) => {
        if (index < updatedEnabled.length && typeof isEnabled === 'boolean') {
          updatedEnabled[index] = isEnabled;
        }
      });
      this.dailyGoalEnabled = updatedEnabled;
    }
    this.dailyGoalStreak = Math.max(0, this.getStoredNumber(storedState.dailyGoalStreak, this.dailyGoalStreak));
    this.dailyGoalStreakDate = this.getStoredString(storedState.dailyGoalStreakDate, this.dailyGoalStreakDate);
    let storedOutfits = storedState.ownedOutfits;
    if (Array.isArray(storedOutfits)) {
      let updatedOutfits = [false, false, false, false, false, false];
      storedOutfits.forEach((isOwned: boolean, index: number) => {
        if (index < updatedOutfits.length && typeof isOwned === 'boolean') {
          updatedOutfits[index] = isOwned;
        }
      });
      this.ownedOutfits = updatedOutfits;
    }
    let storedOutfitIndex = this.getStoredNumber(storedState.equippedOutfitIndex, this.equippedOutfitIndex);
    if (storedOutfitIndex >= -1 && storedOutfitIndex < this.outfitNames.length) {
      this.equippedOutfitIndex = storedOutfitIndex;
    }
    this.lastDeliveryRecord = this.getStoredString(storedState.lastDeliveryRecord, this.lastDeliveryRecord);
    this.realDeliveryStatus = this.getStoredString(storedState.realDeliveryStatus, this.realDeliveryStatus);
    this.lastRealSentTask = this.getStoredString(storedState.lastRealSentTask, this.lastRealSentTask);
    this.lastRealReceivedTask = this.getStoredString(storedState.lastRealReceivedTask, this.lastRealReceivedTask);
    this.lastDeliveryType = this.getStoredString(storedState.lastDeliveryType, this.lastDeliveryType);
    this.discoveredDeviceCount = Math.max(0, this.getStoredNumber(storedState.discoveredDeviceCount,
      this.discoveredDeviceCount));
    let storedTransferIds = storedState.receivedTransferIds;
    if (Array.isArray(storedTransferIds)) {
      this.receivedTransferIds = storedTransferIds.filter((transferId: string) => transferId.length > 0);
    }
    this.petExp = this.getInitialPetExp(storedState.petExp);
  }

  restoreDailyGoalConfig(storedState: StoredAppState) {
    let storedNames = storedState.dailyGoalNames;
    let storedTargets = storedState.dailyGoalTargets;
    let storedRewards = storedState.dailyGoalRewards;
    let storedTypes = storedState.dailyGoalTypes;
    if (!Array.isArray(storedNames) || !Array.isArray(storedTargets) || !Array.isArray(storedTypes)) {
      return;
    }
    let goalNames: string[] = storedNames;
    let goalTargets: number[] = storedTargets;
    let goalRewards: number[] = Array.isArray(storedRewards) ? storedRewards : [];
    let goalTypes: number[] = storedTypes;
    let restoredNames: string[] = [];
    let restoredTargets: number[] = [];
    let restoredRewards: number[] = [];
    let restoredTypes: number[] = [];
    goalNames.forEach((goalName: string, index: number) => {
      if (typeof goalName === 'string' && goalName.length > 0 &&
        typeof goalTargets[index] === 'number' && typeof goalTypes[index] === 'number') {
        restoredNames.push(goalName);
        restoredTargets.push(Math.max(1, Math.round(goalTargets[index])));
        restoredTypes.push(this.normalizeGoalType(goalTypes[index]));
        restoredRewards.push(typeof goalRewards[index] === 'number' ?
          Math.max(1, Math.round(goalRewards[index])) : 10);
      }
    });
    if (restoredNames.length > 0) {
      this.dailyGoalNames = restoredNames;
      this.dailyGoalTargets = restoredTargets;
      this.dailyGoalRewards = restoredRewards;
      this.dailyGoalTypes = restoredTypes;
    }
  }

  restoreTodo(item: StoredToDo): ToDo {
    let todoName = this.getStoredString(item.name, 'Task');
    let priority = this.normalizePriority(this.getStoredNumber(item.priority, 1));
    return ToDo.fromStorage(
      this.getStoredString(item.key, ''),
      todoName.length > 0 ? todoName : 'Task',
      this.getStoredNumber(item.createdAt, Date.now()),
      priority,
      this.getStoredBoolean(item.isCompleted, false),
      Math.max(0, this.getStoredNumber(item.focusCount, 0)),
      Math.max(0, this.getStoredNumber(item.focusDurationMinutes, 0)),
      Math.max(0, this.getStoredNumber(item.deadline, 0))
    );
  }

  getStoredNumber(value: number | undefined, defaultValue: number): number {
    if (typeof value === 'number') {
      return value;
    }
    return defaultValue;
  }

  getStoredString(value: string | undefined, defaultValue: string): string {
    if (typeof value === 'string') {
      return value;
    }
    return defaultValue;
  }

  getStoredBoolean(value: boolean | undefined, defaultValue: boolean): boolean {
    if (typeof value === 'boolean') {
      return value;
    }
    return defaultValue;
  }

  normalizePriority(priority: number): number {
    let normalizedPriority = Math.round(priority);
    if (normalizedPriority < 0) {
      return 0;
    }
    if (normalizedPriority > 2) {
      return 2;
    }
    return normalizedPriority;
  }

  getInitialPetExp(storedPetExp: number | undefined): number {
    let taskGrowth = this.getCompletedCount() * 10 + this.getTotalFocusCount() * 15 + (this.hasCheckedToday ? 20 : 0);
    if (typeof storedPetExp === 'number') {
      return Math.max(storedPetExp, this.score, taskGrowth);
    }
    return Math.max(this.score, taskGrowth);
  }

  resetDailyStateIfNeeded(): boolean {
    let today = this.getTodayString();
    let hasChanged = false;
    if (this.lastCheckInDate !== today && this.hasCheckedToday) {
      this.hasCheckedToday = false;
      hasChanged = true;
    }
    if (this.todayPomodoroDate !== today) {
      if (this.todayPomodoroCount !== 0) {
        this.todayPomodoroCount = 0;
      }
      this.todayPomodoroDate = today;
      hasChanged = true;
    }
    if (this.dailyGoalDate !== today) {
      this.dailyGoalRewardClaimed = [false, false, false, false];
      this.dailyGoalDate = today;
      if (this.todayFocusMinutes !== 0) {
        this.todayFocusMinutes = 0;
      }
      if (this.todayReadingMinutes !== 0) {
        this.todayReadingMinutes = 0;
      }
      if (this.todayCompletedCount !== 0) {
        this.todayCompletedCount = 0;
      }
      this.dailyGoalRewardClaimed = this.dailyGoalRewardClaimed.map(() => false);
      hasChanged = true;
    }
    return hasChanged;
  }

  async saveAppState(): Promise<void> {
    let hasPreferences = await this.ensurePreferences();
    if (!hasPreferences || this.appPreferences === null) {
      return;
    }
    try {
      await this.appPreferences.put(APP_STATE_KEY, JSON.stringify(this.buildStoredAppState()));
      await this.appPreferences.flush();
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0000, 'Index', `save app state failed. error code=${err.code}, message=${err.message}`);
    }
  }

  buildStoredAppState(): StoredAppState {
    return {
      toDoData: this.toDoData.map((item: ToDo) => this.buildStoredToDo(item)),
      score: this.score,
      petExp: this.petExp,
      themeIndex: this.themeIndex,
      unlockedThemes: [...this.unlockedThemes],
      hasCheckedToday: this.hasCheckedToday,
      lastCheckInDate: this.lastCheckInDate,
      todayPomodoroCount: this.todayPomodoroCount,
      todayPomodoroDate: this.todayPomodoroDate,
      todayCompletedCount: this.todayCompletedCount,
      todayFocusMinutes: this.todayFocusMinutes,
      todayReadingMinutes: this.todayReadingMinutes,
      dailyGoalDate: this.dailyGoalDate,
      dailyGoalNames: [...this.dailyGoalNames],
      dailyGoalTargets: [...this.dailyGoalTargets],
      dailyGoalRewards: [...this.dailyGoalRewards],
      dailyGoalTypes: [...this.dailyGoalTypes],
      dailyGoalRewardClaimed: [...this.dailyGoalRewardClaimed],
      dailyGoalEnabled: [...this.dailyGoalEnabled],
      dailyGoalStreak: this.dailyGoalStreak,
      dailyGoalStreakDate: this.dailyGoalStreakDate,
      ownedOutfits: [...this.ownedOutfits],
      equippedOutfitIndex: this.equippedOutfitIndex,
      lastDeliveryRecord: this.lastDeliveryRecord,
      realDeliveryStatus: this.realDeliveryStatus,
      lastRealSentTask: this.lastRealSentTask,
      lastRealReceivedTask: this.lastRealReceivedTask,
      lastDeliveryType: this.lastDeliveryType,
      discoveredDeviceCount: this.discoveredDeviceCount,
      receivedTransferIds: [...this.receivedTransferIds]
    };
  }

  buildStoredToDo(item: ToDo): StoredToDo {
    return {
      key: item.key,
      name: item.name,
      createdAt: item.createdAt,
      priority: item.priority,
      isCompleted: item.isCompleted,
      focusCount: item.focusCount,
      focusDurationMinutes: item.focusDurationMinutes,
      deadline: item.deadline
    };
  }

  getTodayString(): string {
    let currentDate = new Date();
    let month = currentDate.getMonth() + 1;
    let date = currentDate.getDate();
    let monthText = month < 10 ? `0${month}` : `${month}`;
    let dateText = date < 10 ? `0${date}` : `${date}`;
    return `${currentDate.getFullYear()}-${monthText}-${dateText}`;
  }

  getTodayDisplayText(): string {
    let currentDate = new Date();
    let weekNames: string[] = ['\u5468\u65E5', '\u5468\u4E00', '\u5468\u4E8C', '\u5468\u4E09',
      '\u5468\u56DB', '\u5468\u4E94', '\u5468\u516D'];
    return `${currentDate.getMonth() + 1}\u6708${currentDate.getDate()}\u65E5 ${weekNames[currentDate.getDay()]}`;
  }

  getYesterdayString(): string {
    let currentDate = new Date();
    currentDate.setDate(currentDate.getDate() - 1);
    let month = currentDate.getMonth() + 1;
    let date = currentDate.getDate();
    let monthText = month < 10 ? `0${month}` : `${month}`;
    let dateText = date < 10 ? `0${date}` : `${date}`;
    return `${currentDate.getFullYear()}-${monthText}-${dateText}`;
  }

  getStartOfDay(timestamp: number): number {
    let dateValue = new Date(timestamp);
    dateValue.setHours(0, 0, 0, 0);
    return dateValue.getTime();
  }

  getTodayStart(): number {
    return this.getStartOfDay(Date.now());
  }

  getDeadlineByOffset(offset: number): number {
    if (offset < 0) {
      return 0;
    }
    return this.getTodayStart() + offset * 24 * 60 * 60 * 1000;
  }

  getDeadlineText(deadline: number): string {
    if (deadline <= 0) {
      return '\u65E0\u622A\u6B62\u65E5\u671F';
    }
    let diffDays = Math.round((this.getStartOfDay(deadline) - this.getTodayStart()) / (24 * 60 * 60 * 1000));
    if (diffDays === 0) {
      return '\u4ECA\u5929\u622A\u6B62';
    }
    if (diffDays > 0) {
      return `\u8FD8\u6709 ${diffDays} \u5929`;
    }
    return `\u5DF2\u903E\u671F ${Math.abs(diffDays)} \u5929`;
  }

  getDeadlineDateText(deadline: number): string {
    if (deadline <= 0) {
      return '\u65E0';
    }
    return this.formatDateOnly(deadline);
  }

  formatDateOnly(timestamp: number): string {
    let dateValue = new Date(timestamp);
    let month = dateValue.getMonth() + 1;
    let date = dateValue.getDate();
    let monthText = month < 10 ? `0${month}` : `${month}`;
    let dateText = date < 10 ? `0${date}` : `${date}`;
    return `${dateValue.getFullYear()}-${monthText}-${dateText}`;
  }

  formatDateTime(timestamp: number): string {
    let dateValue = new Date(timestamp);
    let month = dateValue.getMonth() + 1;
    let date = dateValue.getDate();
    let hour = dateValue.getHours();
    let minute = dateValue.getMinutes();
    let monthText = month < 10 ? `0${month}` : `${month}`;
    let dateText = date < 10 ? `0${date}` : `${date}`;
    let hourText = hour < 10 ? `0${hour}` : `${hour}`;
    let minuteText = minute < 10 ? `0${minute}` : `${minute}`;
    return `${dateValue.getFullYear()}-${monthText}-${dateText} ${hourText}:${minuteText}`;
  }

  getTotalCount(): number {
    return this.getAllTodos().length;
  }

  getCompletionRate(): number {
    let totalCount = this.getTotalCount();
    if (totalCount === 0) {
      return 0;
    }
    return Math.round(this.getCompletedCount() * 100 / totalCount);
  }

  getAllTodos(): ToDo[] {
    if (!Array.isArray(this.toDoData)) {
      return [];
    }
    return [...this.toDoData];
  }

  getCompletedCount(): number {
    return this.getAllTodos().filter((item: ToDo) => item.isCompleted).length;
  }

  getUncompletedCount(): number {
    return this.getAllTodos().filter((item: ToDo) => !item.isCompleted).length;
  }

  getDailyGoalCompletionRate(): number {
    let activeGoalIndexes = this.getActiveDailyGoalIndexes();
    if (activeGoalIndexes.length === 0) {
      return 0;
    }
    let achievedCount = activeGoalIndexes.filter((index: number) => this.isDailyGoalAchieved(index)).length;
    return Math.round(achievedCount * 100 / activeGoalIndexes.length);
  }

  getAchievementCount(): number {
    let achievementCount = 0;
    if (this.getCompletedCount() >= 1) {
      achievementCount += 1;
    }
    if (this.getCompletedCount() >= 10) {
      achievementCount += 1;
    }
    if (this.getTotalFocusCount() >= 5) {
      achievementCount += 1;
    }
    if (this.dailyGoalStreak >= 3) {
      achievementCount += 1;
    }
    if (this.getOwnedOutfitCount() >= 3) {
      achievementCount += 1;
    }
    if (this.lastRealSentTask !== '\u6682\u65E0' || this.lastRealReceivedTask !== '\u6682\u65E0') {
      achievementCount += 1;
    }
    if (this.getAllTodos().some((item: ToDo) => item.deadline > 0)) {
      achievementCount += 1;
    }
    return achievementCount;
  }

  getTodayAdvice(): string {
    if (this.getUncompletedCount() >= 5) {
      return '\u5148\u6311\u4E00\u4EF6\u6700\u5C0F\u7684\u4EFB\u52A1\u5F00\u59CB\uFF0C\u628A\u538B\u529B\u62C6\u5C0F\u3002';
    }
    if (this.todayPomodoroCount === 0 && this.getUncompletedCount() > 0) {
      return '\u9009\u4E00\u4E2A\u4EFB\u52A1\u5F00\u542F\u4E00\u4E2A\u756A\u8304\uFF0C\u5148\u8FDB\u5165\u72B6\u6001\u3002';
    }
    if (this.getDailyGoalCompletionRate() < 50) {
      return '\u4ECA\u65E5\u76EE\u6807\u8FD8\u6709\u7A7A\u95F4\uFF0C\u5B8C\u6210\u4E00\u9879\u5C31\u80FD\u63A8\u52A8\u5BA0\u7269\u6210\u957F\u3002';
    }
    return '\u8282\u594F\u4E0D\u9519\uFF0C\u4FDD\u6301\u8FD9\u4E2A\u5B66\u4E60\u624B\u611F\u3002';
  }

  getHomeCurrentGoalText(): string {
    let activeGoalIndexes = this.getActiveDailyGoalIndexes();
    if (activeGoalIndexes.length === 0) {
      return '\u4FDD\u6301\u81EA\u5DF1\u7684\u8282\u594F';
    }
    for (let index = 0; index < activeGoalIndexes.length; index++) {
      let goalIndex = activeGoalIndexes[index];
      if (goalIndex >= 0 && goalIndex < this.dailyGoalNames.length && !this.isDailyGoalAchieved(goalIndex)) {
        return `${this.dailyGoalNames[goalIndex]} ${this.getDailyGoalProgress(goalIndex)} / ${this.dailyGoalTargets[goalIndex]}`;
      }
    }
    return '\u4ECA\u65E5\u76EE\u6807\u5DF2\u8FBE\u6210';
  }

  getTodayQuote(): string {
    let todayText = this.getTodayString();
    let quoteIndex = 0;
    for (let index = 0; index < todayText.length; index++) {
      quoteIndex += todayText.charCodeAt(index);
    }
    return this.motivationalQuotes[quoteIndex % this.motivationalQuotes.length];
  }

  getTodayStudyMoodTitle(): string {
    if (this.todayPomodoroCount >= 3 || this.todayFocusMinutes >= 60) {
      return '\uD83D\uDD25 \u7206\u53D1\u51B2\u523A\u65E5';
    }
    if (this.todayCompletedCount >= 3) {
      return '\uD83C\uDF1F \u9AD8\u6548\u5B8C\u6210\u65E5';
    }
    if (this.todayPomodoroCount >= 1 || this.todayFocusMinutes >= 15) {
      return '\uD83C\uDF31 \u7A33\u5B9A\u5B66\u4E60\u65E5';
    }
    return '\u2601\uFE0F \u6E29\u67D4\u542F\u52A8\u65E5';
  }

  getTodayStudyMoodDesc(): string {
    if (this.todayPomodoroCount >= 3 || this.todayFocusMinutes >= 60) {
      return '\u4ECA\u5929\u5B66\u4E60\u72B6\u6001\u5F88\u5F3A\uFF0C\u7EE7\u7EED\u4FDD\u6301\u8282\u594F\uFF01';
    }
    if (this.todayCompletedCount >= 3) {
      return '\u4ECA\u5929\u5B8C\u6210\u4E86\u4E0D\u5C11\u4EFB\u52A1\uFF0C\u5F88\u68D2\uFF01';
    }
    if (this.todayPomodoroCount >= 1 || this.todayFocusMinutes >= 15) {
      return '\u5DF2\u7ECF\u8FDB\u5165\u5B66\u4E60\u72B6\u6001\u5566\u3002';
    }
    return '\u5148\u4ECE\u4E00\u4E2A\u5C0F\u4EFB\u52A1\u5F00\u59CB\u5427\u3002';
  }

  getLearningTitle(): string {
    if (this.getCompletedCount() >= 10) {
      return '\u5341\u9879\u8FBE\u6210\u8005';
    }
    if (this.todayPomodoroCount >= 2) {
      return '\u756A\u8304\u65B0\u661F';
    }
    if (this.todayFocusMinutes >= 60) {
      return '\u6DF1\u5EA6\u4E13\u6CE8\u8005';
    }
    if (this.dailyGoalStreak >= 3) {
      return '\u8FDE\u7EED\u81EA\u5F8B\u8005';
    }
    if (this.getOwnedOutfitCount() >= 3) {
      return '\u88C5\u626E\u6536\u85CF\u5BB6';
    }
    if (this.discoveredDeviceCount > 0 || this.lastDeliveryType === '\u771F\u5B9E\u6295\u9001') {
      return '\u8DE8\u8BBE\u5907\u63A2\u7D22\u8005';
    }
    if (this.getAllTodos().some((item: ToDo) => item.deadline > 0)) {
      return '\u622A\u6B62\u65E5\u89C4\u5212\u5E08';
    }
    return '\u5B66\u4E60\u840C\u65B0';
  }

  getNextStepSuggestion(): string {
    if ((this.todayPomodoroCount >= 3 || this.todayFocusMinutes >= 60) && this.todayCompletedCount > 0) {
      return '\u4ECA\u5929\u72B6\u6001\u4E0D\u9519\uFF0C\u53EF\u4EE5\u6574\u7406\u4E00\u4E0B\u660E\u5929\u8BA1\u5212\u3002';
    }
    if (this.todayCompletedCount === 0 && this.todayPomodoroCount === 0 && this.todayFocusMinutes === 0) {
      return '\u5148\u6DFB\u52A0\u4E00\u4E2A 5 \u5206\u949F\u4EFB\u52A1\u5427\u3002';
    }
    if (this.getUncompletedCount() > 0 && this.todayPomodoroCount === 0 && this.todayFocusMinutes === 0) {
      return '\u8BD5\u8BD5\u5F00\u59CB\u4E00\u4E2A 5 \u5206\u949F\u4E13\u6CE8\u3002';
    }
    return '\u4F11\u606F\u4E00\u4E0B\uFF0C\u518D\u5B8C\u6210\u4E00\u4E2A\u5C0F\u4EFB\u52A1\u3002';
  }

  getTabIcon(index: number): string {
    if (index === 0) {
      return '\uD83C\uDFE0';
    }
    if (index === 1) {
      return '\uD83D\uDCDD';
    }
    if (index === 2) {
      return '\uD83D\uDCC5';
    }
    if (index === 3) {
      return '\uD83C\uDF45';
    }
    if (index === 4) {
      return '\uD83D\uDCCA';
    }
    if (index === 5) {
      return '\uD83D\uDC31';
    }
    if (index === 6) {
      return '\uD83D\uDCE1';
    }
    return '\uD83D\uDC64';
  }

  getThemeColor(): string {
    if (this.themeIndex < 0 || this.themeIndex >= this.themeColors.length) {
      return UI_COLORS.FOCUS_BLUE;
    }
    return this.themeColors[this.themeIndex];
  }

  getThemeLightColor(): string {
    if (this.themeIndex < 0 || this.themeIndex >= this.themeLightColors.length) {
      return UI_COLORS.BLUE_LIGHT;
    }
    return this.themeLightColors[this.themeIndex];
  }

  addGrowthReward(scoreValue: number) {
    this.score += scoreValue;
    this.petExp += scoreValue;
  }

  getPetName(): string {
    if (this.petExp >= 700) {
      return '\u5B66\u4E60\u795E\u9F99';
    }
    if (this.petExp >= 400) {
      return '\u667A\u6167\u5C0F\u72D0';
    }
    if (this.petExp >= 200) {
      return '\u4E13\u6CE8\u5C0F\u718A';
    }
    if (this.petExp >= 100) {
      return '\u52AA\u529B\u5C0F\u732B';
    }
    if (this.petExp >= 50) {
      return '\u5B66\u4E60\u5E7C\u5D3D';
    }
    return '\u5B66\u4E60\u86CB';
  }

  getPetEmoji(): string {
    if (this.petExp >= 700) {
      return '\uD83D\uDC32';
    }
    if (this.petExp >= 400) {
      return '\uD83E\uDD8A';
    }
    if (this.petExp >= 200) {
      return '\uD83D\uDC3B';
    }
    if (this.petExp >= 100) {
      return '\uD83D\uDC31';
    }
    if (this.petExp >= 50) {
      return '\uD83D\uDC23';
    }
    return '\uD83E\uDD5A';
  }

  getPetLevel(): number {
    if (this.petExp >= 700) {
      return 6;
    }
    if (this.petExp >= 400) {
      return 5;
    }
    if (this.petExp >= 200) {
      return 4;
    }
    if (this.petExp >= 100) {
      return 3;
    }
    if (this.petExp >= 50) {
      return 2;
    }
    return 1;
  }

  getCurrentLevelScore(): number {
    if (this.petExp >= 700) {
      return 700;
    }
    if (this.petExp >= 400) {
      return 400;
    }
    if (this.petExp >= 200) {
      return 200;
    }
    if (this.petExp >= 100) {
      return 100;
    }
    if (this.petExp >= 50) {
      return 50;
    }
    return 0;
  }

  getNextLevelScore(): number {
    if (this.petExp >= 700) {
      return 700;
    }
    if (this.petExp >= 400) {
      return 700;
    }
    if (this.petExp >= 200) {
      return 400;
    }
    if (this.petExp >= 100) {
      return 200;
    }
    if (this.petExp >= 50) {
      return 100;
    }
    return 50;
  }

  getPetProgress(): number {
    let currentLevelScore = this.getCurrentLevelScore();
    let nextLevelScore = this.getNextLevelScore();
    if (nextLevelScore === currentLevelScore) {
      return 100;
    }
    return Math.round((this.petExp - currentLevelScore) * 100 / (nextLevelScore - currentLevelScore));
  }

  getPetExpToNextLevel(): number {
    let nextLevelScore = this.getNextLevelScore();
    if (nextLevelScore <= this.petExp) {
      return 0;
    }
    return nextLevelScore - this.petExp;
  }

  getPetStatusText(): string {
    if (this.petExp >= 700) {
      return '\u5DF2\u6210\u4E3A\u5B66\u4E60\u795E\u9F99\uFF0C\u7EE7\u7EED\u4FDD\u6301\u8282\u594F';
    }
    if (this.getTotalFocusMinutes() >= 120) {
      return '\u4E13\u6CE8\u4E4B\u529B\u6B63\u5728\u5E2E\u5B83\u98DE\u5FEB\u6210\u957F';
    }
    if (this.getCompletedCount() > 0) {
      return '\u6BCF\u5B8C\u6210\u4E00\u4EF6\u5C0F\u4E8B\uFF0C\u5B83\u90FD\u4F1A\u66F4\u6709\u7CBE\u795E';
    }
    return '\u4ECE\u4E00\u4E2A\u5C0F\u4EFB\u52A1\u5F00\u59CB\uFF0C\u966A\u5B83\u6162\u6162\u957F\u5927';
  }

  getTotalFocusMinutes(): number {
    let totalMinutes = 0;
    this.getAllTodos().forEach((item: ToDo) => {
      totalMinutes += item.focusDurationMinutes;
    });
    return totalMinutes;
  }

  getTotalFocusCount(): number {
    let totalCount = 0;
    this.getAllTodos().forEach((item: ToDo) => {
      totalCount += item.focusCount;
    });
    return totalCount;
  }

  normalizeGoalType(goalType: number): number {
    let normalizedType = Math.round(goalType);
    if (normalizedType < 0) {
      return 0;
    }
    if (normalizedType > 3) {
      return 3;
    }
    return normalizedType;
  }

  getDailyGoalIcon(index: number): string {
    let goalType = this.normalizeGoalType(this.dailyGoalTypes[index]);
    if (goalType === 0) {
      return '\uD83D\uDCDD';
    }
    if (goalType === 1) {
      return '\uD83C\uDF45';
    }
    if (goalType === 2) {
      return '\uD83E\uDDE0';
    }
    return '\uD83D\uDCDA';
  }

  isReadingTask(item: ToDo): boolean {
    return item.name.includes('\u9605\u8BFB') || item.name.includes('\u8BFB\u4E66');
  }

  getOwnedOutfitCount(): number {
    return this.ownedOutfits.filter((isOwned: boolean) => isOwned).length;
  }

  getEquippedOutfitName(): string {
    if (this.equippedOutfitIndex >= 0 && this.equippedOutfitIndex < this.outfitNames.length &&
      this.ownedOutfits[this.equippedOutfitIndex]) {
      return this.outfitNames[this.equippedOutfitIndex];
    }
    return '\u6682\u672A\u88C5\u5907';
  }

  getOutfitIcon(index: number): string {
    if (index === 0) {
      return '\uD83C\uDF92';
    }
    if (index === 1) {
      return '\uD83D\uDC51';
    }
    if (index === 2) {
      return '\uD83E\uDDE3';
    }
    if (index === 3) {
      return '\uD83C\uDF1F';
    }
    if (index === 4) {
      return '\uD83D\uDCDA';
    }
    return '\uD83C\uDFC5';
  }

  getOutfitDisplayName(index: number): string {
    if (index === 0) {
      return '\u5B66\u4E60\u80CC\u5305';
    }
    if (index === 1) {
      return '\u81EA\u5F8B\u738B\u51A0';
    }
    if (index === 2) {
      return '\u4E13\u6CE8\u56F4\u5DFE';
    }
    if (index === 3) {
      return '\u661F\u5149\u80CC\u666F';
    }
    if (index === 4) {
      return '\u4E66\u672C\u4F19\u4F34';
    }
    return '\u4E13\u6CE8\u5956\u7AE0';
  }

  getOutfitActionText(index: number): string {
    if (this.ownedOutfits[index]) {
      return this.equippedOutfitIndex === index ? '使用中' : '点击装备';
    }
    return this.score >= this.outfitPrices[index] ? '可购买' : '积分不足';
  }

  getDailyGoalProgress(index: number): number {
    let goalType = this.normalizeGoalType(this.dailyGoalTypes[index]);
    if (goalType === 0) {
      return this.todayCompletedCount;
    }
    if (goalType === 1) {
      return this.todayPomodoroCount;
    }
    if (goalType === 2) {
      return this.todayFocusMinutes;
    }
    if (goalType === 3) {
      return this.todayReadingMinutes;
    }
    return 0;
  }

  getDailyGoalPercent(index: number): number {
    let target = this.dailyGoalTargets[index];
    if (target <= 0) {
      return 0;
    }
    return Math.min(100, Math.round(this.getDailyGoalProgress(index) * 100 / target));
  }

  isDailyGoalAchieved(index: number): boolean {
    return this.getDailyGoalProgress(index) >= this.dailyGoalTargets[index];
  }

  hasVisibleDailyGoals(): boolean {
    return this.dailyGoalEnabled.some((isEnabled: boolean) => isEnabled);
  }

  getActiveDailyGoalIndexes(): number[] {
    let indexes: number[] = [];
    this.dailyGoalNames.forEach((goalName: string, index: number) => {
      if (this.dailyGoalEnabled[index]) {
        indexes.push(index);
      }
    });
    return indexes;
  }

  updateDailyGoalStreak() {
    if (this.dailyGoalStreakDate === this.getTodayString()) {
      return;
    }
    if (this.dailyGoalStreakDate === this.getYesterdayString()) {
      this.dailyGoalStreak += 1;
    } else {
      this.dailyGoalStreak = 1;
    }
    this.dailyGoalStreakDate = this.getTodayString();
  }

  grantAchievedDailyGoals() {
    this.resetDailyStateIfNeeded();
    let gainedScore = 0;
    let updatedClaims = [...this.dailyGoalRewardClaimed];
    this.dailyGoalNames.forEach((goalName: string, index: number) => {
      if (this.dailyGoalEnabled[index] && this.isDailyGoalAchieved(index) && !updatedClaims[index]) {
        updatedClaims[index] = true;
        gainedScore += this.dailyGoalRewards[index];
      }
    });
    if (gainedScore > 0) {
      this.dailyGoalRewardClaimed = updatedClaims;
      this.addGrowthReward(gainedScore);
      let activeGoalIndexes = this.getActiveDailyGoalIndexes();
      if (activeGoalIndexes.length > 0 &&
        activeGoalIndexes.every((index: number) => this.dailyGoalRewardClaimed[index])) {
        this.updateDailyGoalStreak();
      }
      this.showToastMessage(`\u76EE\u6807\u8FBE\u6210\u5956\u52B1 +${gainedScore}`);
    }
  }

  getPriorityName(priority: number): string {
    if (priority >= 2) {
      return '\u9AD8\u4F18\u5148\u7EA7';
    }
    if (priority === 1) {
      return '\u4E2D\u4F18\u5148\u7EA7';
    }
    return '\u4F4E\u4F18\u5148\u7EA7';
  }

  getPriorityText(priority: number): string {
    if (priority >= 2) {
      return '\u9AD8';
    }
    if (priority === 1) {
      return '\u4E2D';
    }
    return '\u4F4E';
  }

  getVisibleTodos(): ToDo[] {
    let keyword = this.searchKeyword.trim().toLowerCase();
    let visibleData = this.getAllTodos();
    if (keyword.length > 0) {
      visibleData = visibleData.filter((item: ToDo) => item.name.toLowerCase().includes(keyword));
    }
    visibleData.sort((firstItem: ToDo, secondItem: ToDo) => {
      if (this.sortIndex === 1) {
        return firstItem.name.localeCompare(secondItem.name);
      }
      if (this.sortIndex === 2) {
        return Number(firstItem.isCompleted) - Number(secondItem.isCompleted);
      }
      if (this.sortIndex === 3) {
        return secondItem.priority - firstItem.priority;
      }
      return secondItem.createdAt - firstItem.createdAt;
    });
    return visibleData;
  }

  showAddTodoDialog() {
    this.showTodoNamePicker(1);
  }

  getAvailableThings(): string[] {
    try {
      let availableThings = this.getUIContext().getHostContext()?.resourceManager
        .getStringArrayValueSync($r('app.strarray.available_things').id);
      if (availableThings !== undefined && availableThings.length > 0) {
        return availableThings;
      }
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0000, 'Index', `load available things failed. error code=${err.code}, message=${err.message}`);
    }
    return ['Task'];
  }

  showTodoNamePicker(priority: number) {
    let availableThings = this.getAvailableThings();
    this.getUIContext().showTextPickerDialog({
      range: availableThings,
      onAccept: (value: TextPickerResult) => {
        let selectedIndex = Number(value.index);
        let safeIndex = selectedIndex >= 0 && selectedIndex < availableThings.length ? selectedIndex : 0;
        this.showDeadlinePickerForNewTodo(availableThings[safeIndex], priority);
      },
    });
  }

  showDeadlinePickerForNewTodo(todoName: string, priority: number) {
    this.getUIContext().showTextPickerDialog({
      range: this.deadlineNames,
      selected: 1,
      onAccept: (value: TextPickerResult) => {
        let deadline = this.getDeadlineByOffset(this.deadlineOffsets[Number(value.index)]);
        this.toDoData = [new ToDo(todoName, priority, deadline), ...this.toDoData];
        this.showToastMessage(deadline > 0 ? `\u5DF2\u65B0\u589E\uFF0C${this.getDeadlineText(deadline)}` : '\u5DF2\u65B0\u589E');
        this.saveAppState();
      },
    });
  }

  showPriorityPicker(item: ToDo) {
    this.getUIContext().showTextPickerDialog({
      range: this.priorityNames,
      selected: item.priority,
      onAccept: (value: TextPickerResult) => {
        item.priority = Number(value.index);
        this.toDoData = [...this.toDoData];
        this.showToastMessage('\u4F18\u5148\u7EA7\u5DF2\u66F4\u65B0');
        this.saveAppState();
      },
    });
  }

  showFocusPicker(item: ToDo) {
    if (item === undefined || item.key.length === 0) {
      this.showToastMessage('\u4EFB\u52A1\u72B6\u6001\u5F02\u5E38\uFF0C\u8BF7\u91CD\u65B0\u9009\u62E9');
      return;
    }
    if (item.isCompleted) {
      this.showToastMessage('\u5DF2\u5B8C\u6210\u4EFB\u52A1\u4E0D\u9700\u8981\u5F00\u59CB\u4E13\u6CE8');
      return;
    }
    this.getUIContext().showTextPickerDialog({
      range: this.focusMinuteNames,
      selected: 2,
      onAccept: (value: TextPickerResult) => {
        this.startFocus(item, this.focusMinuteValues[Number(value.index)]);
      },
    });
  }

  startFocus(item: ToDo, minutes: number) {
    if (item === undefined || item.isCompleted || item.key.length === 0) {
      this.showToastMessage('\u8BF7\u9009\u62E9\u4E00\u4E2A\u672A\u5B8C\u6210\u4EFB\u52A1');
      return;
    }
    let safeMinutes = Math.max(1, Math.round(minutes));
    this.clearFocusTimer();
    this.selectedFocusMinutes = safeMinutes;
    this.focusTaskKey = item.key;
    this.focusTotalSeconds = safeMinutes * 60;
    this.focusRemainingSeconds = this.focusTotalSeconds;
    this.isFocusRunning = true;
    this.isFocusFinished = false;
    this.isFocusImmersiveMode = true;
    this.isFocusRoomVisible = true;
    this.currentTab = 3;
    this.startFocusTimer();
    this.showToastMessage('\u756A\u8304\u4E13\u6CE8\u5DF2\u5F00\u59CB');
  }

  startFocusTimer() {
    this.clearFocusTimer();
    this.focusTimer = setInterval(() => {
      if (!this.isFocusRunning) {
        return;
      }
      if (this.focusRemainingSeconds <= 1) {
        this.focusRemainingSeconds = 0;
        this.isFocusRunning = false;
        this.isFocusFinished = true;
        this.clearFocusTimer();
        this.showToastMessage('\u756A\u8304\u8BA1\u65F6\u5B8C\u6210\uFF0C\u8BF7\u70B9\u51FB\u5B8C\u6210\u4E13\u6CE8');
        return;
      }
      this.focusRemainingSeconds -= 1;
    }, 1000);
  }

  clearFocusTimer() {
    if (this.focusTimer >= 0) {
      clearInterval(this.focusTimer);
      this.focusTimer = -1;
    }
  }

  pauseOrResumeFocus() {
    if (this.focusTaskKey.length === 0) {
      return;
    }
    if (this.isFocusFinished) {
      this.showToastMessage('\u672C\u8F6E\u8BA1\u65F6\u5DF2\u5B8C\u6210');
      return;
    }
    this.isFocusRunning = !this.isFocusRunning;
    this.showToastMessage(this.isFocusRunning ? '\u4E13\u6CE8\u5DF2\u7EE7\u7EED' : '\u4E13\u6CE8\u5DF2\u6682\u505C');
  }

  cancelFocus() {
    let isEarlyExit = this.focusTaskKey.length > 0 && this.focusRemainingSeconds > 0;
    this.clearFocusTimer();
    if (isEarlyExit) {
      this.todayEarlyExitCount += 1;
    }
    this.focusTaskKey = '';
    this.focusRemainingSeconds = 0;
    this.focusTotalSeconds = 0;
    this.isFocusRunning = false;
    this.isFocusFinished = false;
    this.isFocusImmersiveMode = false;
    this.isFocusRoomVisible = false;
    this.currentTab = 1;
    this.showToastMessage('\u5DF2\u53D6\u6D88\u672C\u8F6E\u4E13\u6CE8');
  }

  completeFocus() {
    if (!this.isFocusFinished && this.focusRemainingSeconds > 0) {
      this.showToastMessage('\u8BA1\u65F6\u7ED3\u675F\u540E\u624D\u80FD\u5B8C\u6210\u7ED3\u7B97');
      return;
    }
    let focusMinutes = Math.round(this.focusTotalSeconds / 60);
    let hasFocusTask = false;
    let isReadingFocus = false;
    this.clearFocusTimer();
    this.toDoData = this.toDoData.map((todoItem: ToDo) => {
      if (todoItem.key === this.focusTaskKey) {
        todoItem.focusCount += 1;
        todoItem.focusDurationMinutes += focusMinutes;
        hasFocusTask = true;
        isReadingFocus = this.isReadingTask(todoItem);
      }
      return todoItem;
    });
    if (hasFocusTask) {
      this.addGrowthReward(15);
      if (this.todayPomodoroDate !== this.getTodayString()) {
        this.todayPomodoroDate = this.getTodayString();
        this.todayPomodoroCount = 0;
      }
      this.todayPomodoroCount += 1;
      this.todayFocusMinutes += focusMinutes;
      if (isReadingFocus) {
        this.todayReadingMinutes += focusMinutes;
      }
    }
    this.focusTaskKey = '';
    this.focusRemainingSeconds = 0;
    this.focusTotalSeconds = 0;
    this.isFocusRunning = false;
    this.isFocusFinished = false;
    this.isFocusImmersiveMode = false;
    this.isFocusRoomVisible = false;
    this.currentTab = 1;
    this.showToastMessage(hasFocusTask ? '\u4E13\u6CE8\u5B8C\u6210\uFF0C\u79EF\u5206 +15' : '\u4E13\u6CE8\u5DF2\u7ED3\u675F');
    if (hasFocusTask) {
      this.grantAchievedDailyGoals();
      this.saveAppState();
    }
  }

  exitFocusRoom() {
    this.isFocusRoomVisible = false;
    this.isFocusImmersiveMode = false;
    this.currentTab = 1;
  }

  getFocusTaskName(): string {
    let matchedItems = this.getAllTodos().filter((item: ToDo) => item.key === this.focusTaskKey);
    if (matchedItems.length === 0) {
      return '\u672A\u9009\u62E9\u4EFB\u52A1';
    }
    return matchedItems[0].name;
  }

  getFocusTaskPriorityName(): string {
    let matchedItems = this.getAllTodos().filter((item: ToDo) => item.key === this.focusTaskKey);
    if (matchedItems.length === 0) {
      return '\u81EA\u7531\u4E13\u6CE8';
    }
    return this.getPriorityName(matchedItems[0].priority);
  }

  getFocusTaskDeadlineText(): string {
    let matchedItems = this.getAllTodos().filter((item: ToDo) => item.key === this.focusTaskKey);
    if (matchedItems.length === 0 || matchedItems[0].deadline <= 0) {
      return '\u6682\u65E0\u622A\u6B62\u65E5\u671F';
    }
    return `${this.getDeadlineDateText(matchedItems[0].deadline)} \u00B7 ${this.getDeadlineText(matchedItems[0].deadline)}`;
  }

  getFocusStateText(): string {
    if (this.focusTaskKey.length === 0) {
      return '\u51C6\u5907\u5F00\u59CB\u4E13\u6CE8';
    }
    if (this.isFocusFinished || this.focusRemainingSeconds === 0) {
      return '\u8BA1\u65F6\u5DF2\u5B8C\u6210';
    }
    if (this.getFocusProgress() >= 90) {
      return '\u5373\u5C06\u5B8C\u6210';
    }
    return this.isFocusRunning ? '\u6DF1\u5EA6\u4E13\u6CE8\u4E2D' : '\u4F11\u606F\u4E00\u4E0B\u4E5F\u6CA1\u5173\u7CFB \u2601\uFE0F';
  }

  getFocusRoomBackgroundColor(): string {
    let safeIndex = Math.max(0, this.focusThemeIndex) % this.focusRoomColors.length;
    if (this.focusTaskKey.length === 0) {
      return this.focusRoomColors[5];
    }
    if (!this.isFocusRunning) {
      return this.focusRoomColors[3];
    }
    if (this.getFocusProgress() >= 90) {
      return this.focusRoomColors[4];
    }
    return this.focusRoomColors[safeIndex];
  }

  getFocusRoomLightColor(): string {
    let safeIndex = Math.max(0, this.focusThemeIndex) % this.focusRoomLightColors.length;
    if (this.focusTaskKey.length === 0) {
      return this.focusRoomLightColors[5];
    }
    if (!this.isFocusRunning) {
      return this.focusRoomLightColors[3];
    }
    if (this.getFocusProgress() >= 90) {
      return this.focusRoomLightColors[4];
    }
    return this.focusRoomLightColors[safeIndex];
  }

  getFocusRoomAccentColor(): string {
    let safeIndex = Math.max(0, this.focusThemeIndex) % this.focusRoomAccentColors.length;
    if (this.focusTaskKey.length === 0) {
      return this.focusRoomAccentColors[5];
    }
    if (!this.isFocusRunning) {
      return this.focusRoomAccentColors[3];
    }
    if (this.getFocusProgress() >= 90) {
      return this.focusRoomAccentColors[4];
    }
    return this.focusRoomAccentColors[safeIndex];
  }

  getStudyBuddyName(): string {
    if (this.petExp >= 700) {
      return '\uD83D\uDC32 \u6DF1\u591C\u795E\u9F99';
    }
    if (this.petExp >= 400) {
      return '\uD83E\uDD8A \u6DF1\u591C\u5B66\u59D0';
    }
    if (this.petExp >= 200) {
      return '\uD83D\uDC3B \u81EA\u5F8B\u718A';
    }
    if (this.petExp >= 100) {
      return '\uD83D\uDC31 \u5C0F\u591C\u732B';
    }
    return '\uD83D\uDC30 \u5B66\u4E60\u5154';
  }

  getStudyBuddyIdentity(): string {
    if (this.todayFocusMinutes >= 60) {
      return '\u6DF1\u5EA6\u4E13\u6CE8\u5BB6';
    }
    if (this.dailyGoalStreak >= 3) {
      return '\u81EA\u5F8B\u5927\u5E08';
    }
    if (this.todayPomodoroCount >= 2) {
      return '\u51B2\u523A\u8FBE\u4EBA';
    }
    return '\u5B89\u9759\u5B66\u4E60\u5BB6';
  }

  getStudyBuddyMood(): string {
    if (this.todayEarlyExitCount > 0 && this.todayPomodoroCount === 0) {
      return '\uD83C\uDF27 \u7B49\u4F60\u56DE\u6765';
    }
    if (this.todayFocusMinutes >= 60 || this.todayPomodoroCount >= 3) {
      return '\uD83D\uDD25 \u4ECA\u5929\u8D85\u52AA\u529B';
    }
    if (!this.isFocusRunning && this.focusTaskKey.length > 0) {
      return '\uD83D\uDE2A \u6709\u70B9\u7D2F\u4E86\uFF0C\u6162\u6162\u6765';
    }
    if (this.todayCompletedCount > 0 || this.todayPomodoroCount > 0) {
      return '\uD83D\uDE0A \u72B6\u6001\u5F88\u597D';
    }
    return '\uD83C\uDF31 \u6162\u6162\u6765\u4E5F\u5F88\u597D';
  }

  getStudyBuddyMessage(): string {
    if (this.todayEarlyExitCount > 0 && this.todayPomodoroCount === 0) {
      return '\u521A\u624D\u505C\u4E0B\u4E5F\u6CA1\u5173\u7CFB\uFF0C\u4E0B\u4E00\u4E2A 5 \u5206\u949F\u6211\u8FD8\u966A\u4F60\u3002';
    }
    if (this.focusTaskKey.length > 0 && this.isFocusRunning) {
      return '\u518D\u575A\u6301\u4E00\u4E2A\u756A\u8304\u5C31\u4F11\u606F\uFF0C\u6211\u4F1A\u966A\u7740\u4F60\u3002';
    }
    if (this.focusTaskKey.length > 0) {
      return '\u4F11\u606F\u4E00\u4E0B\u4E5F\u662F\u8282\u594F\u7684\u4E00\u90E8\u5206\u3002';
    }
    return '\u5148\u9009\u4E00\u4E2A\u5C0F\u4EFB\u52A1\u5427\uFF0C\u6211\u4EEC\u4E00\u8D77\u5F00\u59CB\u3002';
  }

  getStudyBuddyCompanionState(): string {
    if (this.focusTaskKey.length > 0 && this.isFocusRunning) {
      return '\u966A\u4F60\u4E13\u6CE8\u4E2D';
    }
    if (this.focusTaskKey.length > 0) {
      return '\u966A\u4F60\u4F11\u606F\u4E2D';
    }
    if (this.todayFocusMinutes >= 60 || this.todayPomodoroCount >= 3) {
      return '\u4ECA\u5929\u8D85\u52AA\u529B';
    }
    if (this.todayEarlyExitCount > 0 && this.todayPomodoroCount === 0) {
      return '\u7B49\u4F60\u56DE\u6765';
    }
    if (this.todayCompletedCount > 0 || this.todayFocusMinutes > 0) {
      return '\u72B6\u6001\u7A33\u5B9A';
    }
    return '\u5B89\u9759\u5F85\u673A';
  }

  getStudyBuddyActivityText(): string {
    if (this.focusTaskKey.length > 0) {
      return `\u5F53\u524D\u966A\u4F34 ${this.formatFocusTime()}`;
    }
    if (this.todayFocusMinutes > 0) {
      return `\u4ECA\u65E5\u966A\u4F34 ${this.todayFocusMinutes} \u5206\u949F`;
    }
    if (this.todayEarlyExitCount > 0) {
      return '\u4ECA\u5929\u5C1D\u8BD5\u8FC7\u4E00\u6B21\u4E13\u6CE8';
    }
    return '\u4ECA\u5929\u8FD8\u5728\u7B49\u7B2C\u4E00\u6BB5\u4E13\u6CE8';
  }

  getStudyBuddyHealingQuote(): string {
    let quotes: string[] = ['\u6162\u6162\u6765\u4E5F\u5F88\u5389\u5BB3\u3002', '\u4ECA\u5929\u4E5F\u966A\u4F60\u4E00\u8D77\u8FDB\u6B65\u3002', '\u518D\u575A\u6301\u4E00\u4E2A\u756A\u8304\u5427\u3002', '\u4F60\u5DF2\u7ECF\u6BD4\u6628\u5929\u66F4\u597D\u4E86\u3002'];
    let today = new Date();
    let safeIndex = Math.abs(today.getDate() + this.todayPomodoroCount + this.todayCompletedCount) % quotes.length;
    return quotes[safeIndex];
  }

  formatFocusTime(): string {
    let minute = Math.floor(this.focusRemainingSeconds / 60);
    let second = this.focusRemainingSeconds % 60;
    let minuteText = minute < 10 ? `0${minute}` : `${minute}`;
    let secondText = second < 10 ? `0${second}` : `${second}`;
    return `${minuteText}:${secondText}`;
  }

  getFocusProgress(): number {
    if (this.focusTotalSeconds === 0) {
      return 0;
    }
    let progress = Math.round((this.focusTotalSeconds - this.focusRemainingSeconds) * 100 / this.focusTotalSeconds);
    if (progress < 0) {
      return 0;
    }
    if (progress > 100) {
      return 100;
    }
    return progress;
  }

  isFocusRoomActive(): boolean {
    return this.currentTab === 3 && (this.isFocusRoomVisible || this.focusTaskKey.length > 0);
  }

  toggleTaskCompleteByKey(itemKey: string) {
    let normalizedKey = String(itemKey);
    let targetIndex = this.toDoData.findIndex((todoItem: ToDo) => String(todoItem.key) === normalizedKey);
    if (targetIndex < 0) {
      hilog.info(0x0000, 'Index', `toggle key=${normalizedKey}, targetIndex=-1, before=not_found, after=not_found`);
      return;
    }
    let wasCompleted = this.toDoData[targetIndex].isCompleted;
    let sourceItem = this.toDoData[targetIndex];
    let updatedItem = ToDo.fromStorage(
      sourceItem.key,
      sourceItem.name,
      sourceItem.createdAt,
      sourceItem.priority,
      !wasCompleted,
      sourceItem.focusCount,
      sourceItem.focusDurationMinutes,
      sourceItem.deadline
    );
    let completedNow = updatedItem.isCompleted;
    this.toDoData[targetIndex] = updatedItem;
    hilog.info(0x0000, 'Index',
      `toggle key=${normalizedKey}, targetIndex=${targetIndex}, before=${wasCompleted}, after=${completedNow}`);
    this.toDoData = [...this.toDoData];
    if (completedNow) {
      this.addGrowthReward(10);
      this.todayCompletedCount += 1;
      try {
        this.grantAchievedDailyGoals();
      } catch (error) {
        let err = error as BusinessError;
        hilog.error(0x0000, 'Index', `grant daily goal failed. error code=${err.code}, message=${err.message}`);
      }
    } else {
      this.score = Math.max(0, this.score - 10);
      this.todayCompletedCount = Math.max(0, this.todayCompletedCount - 1);
    }
    this.saveAppState();
  }

  updateTodoItem(item: ToDo) {
    this.toDoData = this.toDoData.map((todoItem: ToDo) => {
      if (todoItem.key === item.key) {
        return item;
      }
      return todoItem;
    });
    this.saveAppState();
  }

  showToastMessage(message: string) {
    try {
      this.getUIContext().getPromptAction().showToast({ message: message });
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0000, 'Index', `showToast failed. error code=${err.code}, message=${err.message}`);
    }
  }

  checkInToday() {
    if (this.resetDailyStateIfNeeded()) {
      this.saveAppState();
    }
    if (this.hasCheckedToday) {
      this.showToastMessage('\u4ECA\u65E5\u5DF2\u6253\u5361');
      return;
    }
    this.hasCheckedToday = true;
    this.lastCheckInDate = this.getTodayString();
    this.addGrowthReward(20);
    this.showToastMessage('\u6253\u5361\u6210\u529F\uFF0C\u79EF\u5206 +20');
    this.saveAppState();
  }

  handleThemeTap(index: number) {
    if (this.unlockedThemes[index]) {
      this.themeIndex = index;
      this.saveAppState();
      return;
    }
    let price = this.themePrices[index];
    if (this.score < price) {
      this.showToastMessage('\u79EF\u5206\u4E0D\u8DB3\uFF0C\u65E0\u6CD5\u5151\u6362\u4E3B\u9898');
      return;
    }
    let updatedThemes = [...this.unlockedThemes];
    updatedThemes[index] = true;
    this.unlockedThemes = updatedThemes;
    this.score -= price;
    this.themeIndex = index;
    this.showToastMessage('\u4E3B\u9898\u5DF2\u89E3\u9501');
    this.saveAppState();
  }

  handleOutfitTap(index: number) {
    if (index < 0 || index >= this.outfitNames.length) {
      return;
    }
    if (this.ownedOutfits[index]) {
      this.equippedOutfitIndex = index;
      this.showToastMessage('\u88C5\u626E\u5DF2\u88C5\u5907');
      this.saveAppState();
      return;
    }
    let price = this.outfitPrices[index];
    if (this.score < price) {
      this.showToastMessage('\u79EF\u5206\u4E0D\u8DB3\uFF0C\u65E0\u6CD5\u5151\u6362\u88C5\u626E');
      return;
    }
    let updatedOutfits = [...this.ownedOutfits];
    updatedOutfits[index] = true;
    this.ownedOutfits = updatedOutfits;
    this.equippedOutfitIndex = index;
    this.score -= price;
    this.showToastMessage('\u88C5\u626E\u5DF2\u5151\u6362\u5E76\u88C5\u5907');
    this.saveAppState();
  }

  confirmDeleteDailyGoal(index: number) {
    AlertDialog.show({
      title: '\u5220\u9664\u76EE\u6807',
      message: `\u786E\u5B9A\u5220\u9664\u201C${this.dailyGoalNames[index]}\u201D\u5417\uFF1F\u5220\u9664\u540E\u91CD\u542FApp\u4E5F\u4E0D\u4F1A\u81EA\u52A8\u6062\u590D\u3002`,
      primaryButton: {
        value: '\u53D6\u6D88',
        action: () => {
        }
      },
      secondaryButton: {
        value: '\u5220\u9664',
        fontColor: '#D94838',
        action: () => {
          this.deleteDailyGoal(index);
        }
      }
    });
  }

  deleteDailyGoal(index: number) {
    if (index < 0 || index >= this.dailyGoalEnabled.length) {
      return;
    }
    let updatedEnabled = [...this.dailyGoalEnabled];
    updatedEnabled[index] = false;
    this.dailyGoalEnabled = updatedEnabled;
    this.showToastMessage('\u76EE\u6807\u5DF2\u5220\u9664');
    this.saveAppState();
  }

  restoreDefaultDailyGoals() {
    this.dailyGoalNames = ['\u5B8C\u62103\u4E2A\u4EFB\u52A1', '\u5B8C\u62102\u4E2A\u756A\u8304',
      '\u4E13\u6CE830\u5206\u949F', '\u9605\u8BFB30\u5206\u949F'];
    this.dailyGoalTargets = [3, 2, 30, 30];
    this.dailyGoalRewards = [15, 15, 20, 20];
    this.dailyGoalTypes = [0, 1, 2, 3];
    this.dailyGoalEnabled = [true, true, true, true];
    this.dailyGoalRewardClaimed = [false, false, false, false];
    this.dailyGoalDate = this.getTodayString();
    this.isAddingGoal = false;
    this.showToastMessage('\u5DF2\u6062\u590D\u9ED8\u8BA4\u76EE\u6807');
    this.saveAppState();
  }

  showAddGoalEditor() {
    this.newGoalName = '';
    this.newGoalTargetIndex = 0;
    this.newGoalTypeIndex = 0;
    this.isAddingGoal = true;
  }

  confirmAddDailyGoal() {
    let goalName = this.newGoalName.trim();
    if (goalName.length === 0) {
      this.showToastMessage('\u8BF7\u5148\u8F93\u5165\u76EE\u6807\u540D\u79F0');
      return;
    }
    let targetValue = this.dailyGoalTargetOptions[this.newGoalTargetIndex];
    if (targetValue === undefined) {
      targetValue = 1;
    }
    this.dailyGoalNames = [...this.dailyGoalNames, goalName];
    this.dailyGoalTargets = [...this.dailyGoalTargets, targetValue];
    this.dailyGoalRewards = [...this.dailyGoalRewards, 10];
    this.dailyGoalTypes = [...this.dailyGoalTypes, this.normalizeGoalType(this.newGoalTypeIndex)];
    this.dailyGoalEnabled = [...this.dailyGoalEnabled, true];
    this.dailyGoalRewardClaimed = [...this.dailyGoalRewardClaimed, false];
    this.isAddingGoal = false;
    this.showToastMessage('\u76EE\u6807\u5DF2\u65B0\u589E');
    this.grantAchievedDailyGoals();
    this.saveAppState();
  }

  async initTaskTransfer(): Promise<void> {
    if (this.hasInitializedTransfer) {
      return;
    }
    let hostContext = this.getUIContext().getHostContext();
    if (hostContext === undefined) {
      return;
    }
    try {
      await this.taskTransferService.init(hostContext as common.UIAbilityContext, (payload: TaskTransferPayload) => {
        this.receiveRemoteTask(payload);
      });
      this.hasInitializedTransfer = true;
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0000, 'Index', `init task transfer failed. error code=${err.code}, message=${err.message}`);
      this.realDeliveryStatus = `\u771F\u5B9E\u6295\u9001\u521D\u59CB\u5316\u5931\u8D25\uFF1A${err.message}`;
      this.saveAppState();
    }
  }

  async ensureDistributedDataSyncPermission(): Promise<boolean> {
    let hostContext = this.getUIContext().getHostContext();
    if (hostContext === undefined) {
      this.realDeliveryStatus = '\u53D1\u9001\u5931\u8D25\uFF1A\u65E0\u6CD5\u83B7\u53D6\u5E94\u7528\u4E0A\u4E0B\u6587';
      this.showToastMessage('\u65E0\u6CD5\u83B7\u53D6\u5E94\u7528\u4E0A\u4E0B\u6587\uFF0C\u4E0D\u80FD\u8FDB\u884C\u771F\u5B9E\u6295\u9001');
      this.saveAppState();
      return false;
    }
    let abilityContext = hostContext as common.UIAbilityContext;
    try {
      let atManager = abilityAccessCtrl.createAtManager();
      let grantStatus = await atManager.checkAccessToken(abilityContext.applicationInfo.accessTokenId,
        DISTRIBUTED_DATASYNC_PERMISSION);
      if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        return true;
      }
      let requestResult = await atManager.requestPermissionsFromUser(abilityContext, [DISTRIBUTED_DATASYNC_PERMISSION]);
      if (requestResult.authResults.length > 0 &&
        requestResult.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        return true;
      }
      this.realDeliveryStatus = '\u53D1\u9001\u5931\u8D25\uFF1A\u672A\u6388\u4E88\u5206\u5E03\u5F0F\u6570\u636E\u540C\u6B65\u6743\u9650';
      this.showToastMessage('\u672A\u6388\u4E88\u5206\u5E03\u5F0F\u6570\u636E\u540C\u6B65\u6743\u9650\uFF0C\u65E0\u6CD5\u8FDB\u884C\u771F\u5B9E\u6295\u9001');
      this.saveAppState();
      return false;
    } catch (error) {
      let err = error as BusinessError;
      if (err.code === 12100011) {
        return true;
      }
      this.realDeliveryStatus = `\u53D1\u9001\u5931\u8D25\uFF1A\u6743\u9650\u7533\u8BF7\u5931\u8D25 ${err.message}`;
      this.showToastMessage('\u5206\u5E03\u5F0F\u6570\u636E\u540C\u6B65\u6743\u9650\u7533\u8BF7\u5931\u8D25\uFF0C\u65E0\u6CD5\u8FDB\u884C\u771F\u5B9E\u6295\u9001');
      this.saveAppState();
      return false;
    }
  }

  showDeliveryPicker(item: ToDo) {
    AlertDialog.show({
      title: '\u6295\u9001\u4EFB\u52A1',
      message: '\u9009\u62E9\u771F\u5B9E\u8DE8\u8BBE\u5907\u6295\u9001\uFF0C\u6216\u4EC5\u4FDD\u7559\u4E00\u6761\u672C\u5730\u6A21\u62DF\u8BB0\u5F55\u3002',
      primaryButton: {
        value: '\u771F\u5B9E\u6295\u9001',
        action: () => {
          this.showRealDeliveryDevicePicker(item);
        }
      },
      secondaryButton: {
        value: '\u6A21\u62DF\u8BB0\u5F55',
        action: () => {
          this.showMockDeliveryPicker(item);
        }
      }
    });
  }

  showMockDeliveryPicker(item: ToDo) {
    this.getUIContext().showTextPickerDialog({
      range: this.deliveryDevices,
      onAccept: (value: TextPickerResult) => {
        let deviceName = this.deliveryDevices[Number(value.index)];
        this.lastDeliveryType = '\u6A21\u62DF\u8BB0\u5F55';
        this.lastDeliveryRecord = `\u6A21\u62DF\u8BB0\u5F55\uFF1A${item.name} \u2192 ${deviceName}\uFF08\u4E0D\u4EE3\u8868\u771F\u5B9E\u6295\u9001\u6210\u529F\uFF09`;
        this.realDeliveryStatus = '\u6A21\u62DF\u8BB0\u5F55\u5DF2\u4FDD\u7559\uFF0C\u672A\u8FDB\u884C\u771F\u5B9E\u8DE8\u8BBE\u5907\u540C\u6B65';
        this.showToastMessage('\u5DF2\u4FDD\u7559\u6A21\u62DF\u8BB0\u5F55\uFF0C\u8FD9\u4E0D\u662F\u771F\u5B9E\u6295\u9001');
        this.saveAppState();
      },
    });
  }

  async showRealDeliveryDevicePicker(item: ToDo): Promise<void> {
    let hasPermission = await this.ensureDistributedDataSyncPermission();
    if (!hasPermission) {
      return;
    }
    await this.initTaskTransfer();
    if (!this.hasInitializedTransfer) {
      this.showToastMessage('\u771F\u5B9E\u6295\u9001\u521D\u59CB\u5316\u5931\u8D25\uFF0C\u6682\u65F6\u65E0\u6CD5\u6295\u9001');
      return;
    }
    this.realDeliveryStatus = '\u53D1\u9001\u4E2D\uFF1A\u6B63\u5728\u67E5\u627E\u53EF\u7528\u8BBE\u5907';
    this.saveAppState();
    try {
      let devices = await this.taskTransferService.getAvailableDevices();
      this.discoveredDeviceCount = devices.length;
      if (devices.length === 0) {
        this.lastDeliveryType = '\u771F\u5B9E\u6295\u9001';
        this.realDeliveryStatus = '\u53D1\u9001\u5931\u8D25\uFF1A\u672A\u53D1\u73B0\u53EF\u4FE1\u8BBE\u5907';
        this.showNoTrustedDeviceDialog();
        this.saveAppState();
        return;
      }
      this.realDeliveryDevices = devices;
      this.getUIContext().showTextPickerDialog({
        range: devices.map((device: TransferDevice) => device.displayName),
        onAccept: (value: TextPickerResult) => {
          let selectedDevice = this.realDeliveryDevices[Number(value.index)];
          if (selectedDevice !== undefined) {
            this.sendRealTask(item, selectedDevice);
          }
        }
      });
    } catch (error) {
      let err = error as BusinessError;
      this.realDeliveryStatus = `\u53D1\u9001\u5931\u8D25\uFF1A${err.message}`;
      this.showToastMessage('\u83B7\u53D6\u771F\u5B9E\u8BBE\u5907\u5931\u8D25\uFF0C\u8BF7\u68C0\u67E5\u6743\u9650\u548C\u8BBE\u5907\u8FDE\u63A5');
      this.saveAppState();
    }
  }

  showNoTrustedDeviceDialog() {
    AlertDialog.show({
      title: '\u672A\u53D1\u73B0\u53EF\u4FE1\u8BBE\u5907',
      message: '\u672A\u53D1\u73B0\u53EF\u4FE1\u8BBE\u5907\u3002\n\u8BF7\u786E\u8BA4\u4E24\u53F0\u8BBE\u5907\u5F00\u542F\u84DD\u7259/Wi-Fi\u3002\n\u8BF7\u786E\u8BA4\u767B\u5F55\u540C\u4E00\u534E\u4E3A\u8D26\u53F7\u6216\u5DF2\u5EFA\u7ACB\u53EF\u4FE1\u5173\u7CFB\u3002',
      primaryButton: {
        value: '\u6211\u77E5\u9053\u4E86',
        action: () => {
        }
      }
    });
  }

  async sendRealTask(item: ToDo, targetDevice: TransferDevice): Promise<void> {
    this.realDeliveryStatus = `\u53D1\u9001\u4E2D\uFF1A${item.name} \u2192 ${targetDevice.displayName}`;
    this.lastDeliveryType = '\u771F\u5B9E\u6295\u9001';
    this.lastRealSentTask = `${item.name} \u2192 ${targetDevice.displayName}`;
    this.lastDeliveryRecord = this.realDeliveryStatus;
    this.saveAppState();
    try {
      await this.taskTransferService.sendTask(targetDevice, this.buildTaskTransferPayload(item));
      this.realDeliveryStatus = `\u540C\u6B65\u5DF2\u53D1\u8D77\uFF1A${item.name} \u2192 ${targetDevice.displayName}`;
      this.lastDeliveryRecord = this.realDeliveryStatus;
      this.showToastMessage('\u5DF2\u5199\u5165\u672C\u5730KV\u5E76\u53D1\u8D77\u540C\u6B65\uFF0C\u4E0D\u4EE3\u8868\u76EE\u6807\u8BBE\u5907\u5DF2\u6536\u5230');
    } catch (error) {
      let err = error as BusinessError;
      this.realDeliveryStatus = `\u53D1\u9001\u5931\u8D25\uFF1A${err.message}`;
      this.lastDeliveryRecord = `\u53D1\u9001\u5931\u8D25\uFF1A${item.name} \u2192 ${targetDevice.displayName}`;
      this.showToastMessage('\u771F\u5B9E\u6295\u9001\u5931\u8D25\uFF0C\u8BF7\u68C0\u67E5\u8BBE\u5907\u4FE1\u4EFB\u548C\u6743\u9650');
    }
    this.saveAppState();
  }

  buildTaskTransferPayload(item: ToDo): TaskTransferPayload {
    let taskData: TransferTodoData = {
      key: item.key,
      name: item.name,
      createdAt: item.createdAt,
      priority: item.priority,
      isCompleted: item.isCompleted,
      focusCount: item.focusCount,
      focusDurationMinutes: item.focusDurationMinutes,
      deadline: item.deadline
    };
    return {
      transferId: this.taskTransferService.buildTransferId(),
      sourceDeviceId: this.taskTransferService.getLocalDeviceId(),
      sourceDeviceName: this.taskTransferService.getLocalDeviceName(),
      sentAt: Date.now(),
      task: taskData
    };
  }

  receiveRemoteTask(payload: TaskTransferPayload) {
    if (this.receivedTransferIds.includes(payload.transferId)) {
      return;
    }
    let remoteTask = ToDo.fromStorage(
      '',
      payload.task.name,
      Date.now(),
      this.normalizePriority(payload.task.priority),
      false,
      Math.max(0, payload.task.focusCount),
      Math.max(0, payload.task.focusDurationMinutes),
      Math.max(0, payload.task.deadline)
    );
    this.toDoData = [remoteTask, ...this.toDoData];
    this.receivedTransferIds = [payload.transferId, ...this.receivedTransferIds].slice(0, 100);
    this.lastDeliveryType = '\u771F\u5B9E\u6295\u9001';
    this.lastRealReceivedTask = payload.task.name;
    this.realDeliveryStatus = `\u5DF2\u63A5\u6536\uFF1A${payload.task.name}`;
    this.lastDeliveryRecord = this.realDeliveryStatus;
    this.showToastMessage(`\u5DF2\u63A5\u6536\u8DE8\u8BBE\u5907\u4EFB\u52A1\uFF1A${payload.task.name}`);
    this.saveAppState();
  }

  showTodoDetail(item: ToDo) {
    AlertDialog.show({
      title: '\u4EFB\u52A1\u8BE6\u60C5',
      message: `\u4EFB\u52A1\u540D\u79F0\uFF1A${item.name}\n` +
        `\u4F18\u5148\u7EA7\uFF1A${this.getPriorityName(item.priority)}\n` +
        `\u5B8C\u6210\u72B6\u6001\uFF1A${item.isCompleted ? '\u5DF2\u5B8C\u6210' : '\u672A\u5B8C\u6210'}\n` +
        `\u521B\u5EFA\u65F6\u95F4\uFF1A${this.formatDateTime(item.createdAt)}\n` +
        `\u622A\u6B62\u65E5\u671F\uFF1A${this.getDeadlineDateText(item.deadline)}\n` +
        `\u5012\u8BA1\u65F6\uFF1A${this.getDeadlineText(item.deadline)}\n` +
        `\u4E13\u6CE8\u6B21\u6570\uFF1A${item.focusCount}\u6B21\n` +
        `\u4E13\u6CE8\u65F6\u957F\uFF1A${item.focusDurationMinutes}\u5206\u949F`,
      primaryButton: {
        value: '\u5173\u95ED',
        action: () => {
        }
      }
    });
  }

  /**
   * Delete a to-do/completed item.
   */
  deleteTodoItem(item: ToDo) {
    if (item.key === this.focusTaskKey) {
      this.cancelFocus();
    }
    this.toDoData = this.toDoData.filter(todoItem => item.key !== todoItem.key);
    this.showToastMessage('\u5DF2\u5220\u9664');
    this.saveAppState();
  }

  confirmClearCompletedTodos() {
    if (this.getCompletedCount() === 0) {
      this.showToastMessage('\u6682\u65E0\u5DF2\u5B8C\u6210\u4EFB\u52A1');
      return;
    }
    AlertDialog.show({
      title: '\u6E05\u7406\u5DF2\u5B8C\u6210',
      message: '\u786E\u5B9A\u6E05\u7406\u6240\u6709\u5DF2\u5B8C\u6210\u4EFB\u52A1\u5417\uFF1F',
      primaryButton: {
        value: '\u53D6\u6D88',
        action: () => {
        }
      },
      secondaryButton: {
        value: '\u6E05\u7406',
        fontColor: '#D94838',
        action: () => {
          this.toDoData = this.toDoData.filter((todoItem: ToDo) => !todoItem.isCompleted);
          this.showToastMessage('\u5DF2\u6E05\u7406\u5DF2\u5B8C\u6210\u4EFB\u52A1');
          this.saveAppState();
        }
      }
    });
  }

  confirmResetTodayGoals() {
    AlertDialog.show({
      title: '\u91CD\u7F6E\u4ECA\u65E5\u76EE\u6807',
      message: '\u5C06\u91CD\u7F6E\u4ECA\u65E5\u76EE\u6807\u9886\u53D6\u72B6\u6001\u3001\u4ECA\u65E5\u5B8C\u6210\u6570\u548C\u4ECA\u65E5\u4E13\u6CE8\u6570\u636E\u3002',
      primaryButton: {
        value: '\u53D6\u6D88',
        action: () => {
        }
      },
      secondaryButton: {
        value: '\u91CD\u7F6E',
        fontColor: '#D94838',
        action: () => {
          this.dailyGoalRewardClaimed = this.dailyGoalRewardClaimed.map(() => false);
          this.todayCompletedCount = 0;
          this.todayPomodoroCount = 0;
          this.todayFocusMinutes = 0;
          this.todayReadingMinutes = 0;
          this.dailyGoalDate = this.getTodayString();
          this.showToastMessage('\u4ECA\u65E5\u76EE\u6807\u5DF2\u91CD\u7F6E');
          this.saveAppState();
        }
      }
    });
  }

  confirmDeleteItem(item: ToDo) {
    AlertDialog.show({
      title: '\u5220\u9664\u786E\u8BA4',
      message: '\u786E\u5B9A\u5220\u9664\u8FD9\u6761\u5F85\u529E\u5417\uFF1F',
      primaryButton: {
        value: '\u53D6\u6D88',
        action: () => {
        }
      },
      secondaryButton: {
        value: '\u5220\u9664',
        fontColor: '#D94838',
        action: () => {
          this.deleteTodoItem(item);
        }
      }
    });
  }

  @Builder
  sectionTitle(title: string) {
    Text(title)
      .fontSize($r('sys.float.ohos_id_text_size_headline8'))
      .fontColor('#182431')
      .width(Constant.PERCENT_FULL)
  }

  @Builder
  checkInCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.sectionTitle('\u4ECA\u65E5\u6253\u5361')
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        Text(this.hasCheckedToday ? '\u4ECA\u65E5\u5DF2\u6253\u5361' : '\u4ECA\u65E5\u672A\u6253\u5361')
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor(this.hasCheckedToday ? this.getThemeColor() : $r('sys.color.ohos_id_color_text_secondary'))
          .layoutWeight(1)
        Text(this.hasCheckedToday ? '\u5DF2\u5B8C\u6210' : '\u6253\u5361 +20')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(Color.White)
          .padding({
            left: STYLE_CONFIG.LIST_ITEM_GUTTER,
            right: STYLE_CONFIG.LIST_ITEM_GUTTER,
            top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
            bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
          })
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
          .backgroundColor(this.hasCheckedToday ? '#8A8A8A' : this.getThemeColor())
          .onClick(() => {
            this.checkInToday();
          })
      }
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
    .backgroundColor(Color.White)
  }

  @Builder
  themeStore() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Row() {
        Text('\uD83C\uDFA8 \u4E3B\u9898\u5546\u5E97')
          .fontSize($r('sys.float.ohos_id_text_size_headline8'))
          .fontColor(UI_COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text(`${this.score}\u79EF\u5206`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.ORANGE)
          .padding({
            left: STYLE_CONFIG.LIST_ITEM_GUTTER,
            right: STYLE_CONFIG.LIST_ITEM_GUTTER,
            top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
            bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
          })
          .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
          .backgroundColor(UI_COLORS.CREAM_WHITE)
      }
      .width(Constant.PERCENT_FULL)
      Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(this.themeNames, (themeName: string, index: number) => {
        Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
          Row()
            .height(22)
            .width(Constant.PERCENT_FULL)
            .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
            .backgroundColor(this.themeColors[index])
          Text(themeName)
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor(this.themeIndex === index ? Color.White : UI_COLORS.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)
          Text(this.unlockedThemes[index] ? (this.themeIndex === index ? '\u4F7F\u7528\u4E2D' : '\u5DF2\u89E3\u9501') :
            (this.score >= this.themePrices[index] ? `${this.themePrices[index]}\u79EF\u5206` : '\u79EF\u5206\u4E0D\u8DB3'))
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(this.themeIndex === index ? Color.White : UI_COLORS.TEXT_SECONDARY)
        }
        .width('48%')
        .margin({
          right: STYLE_CONFIG.ICON_GUTTER,
          bottom: STYLE_CONFIG.ICON_GUTTER
        })
        .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
        .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
        .backgroundColor(this.themeIndex === index ? this.themeColors[index] : this.themeLightColors[index])
        .shadow({
          radius: 8,
          color: UI_COLORS.CARD_SHADOW,
          offsetX: 0,
          offsetY: 3
        })
        .onClick(() => {
          this.handleThemeTap(index);
        })
      }, (themeName: string) => themeName)
      }
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
    .shadow({
      radius: 10,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 4
    })
  }

  @Builder
  dailyGoalCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text('\uD83C\uDFAF \u4E13\u5C5E\u81EA\u5F8B\u8BA1\u5212')
          .fontSize($r('sys.float.ohos_id_text_size_headline8'))
          .fontColor(UI_COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .width(Constant.PERCENT_FULL)
        Text('\u6BCF\u5929\u8FDB\u6B65\u4E00\u70B9\u70B9')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.TEXT_SECONDARY)
          .width(Constant.PERCENT_FULL)
      }
      .width(Constant.PERCENT_FULL)
      .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
      .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
      .backgroundColor(UI_COLORS.MINT_LIGHT)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.goalSummaryPill('\u8FBE\u6210\u7387', `${this.getDailyGoalCompletionRate()}%`, UI_COLORS.MINT)
        this.goalSummaryPill('\u8FDE\u7EED\u8FBE\u6210', `${this.dailyGoalStreak}\u5929`, UI_COLORS.ORANGE)
      }
      .width(Constant.PERCENT_FULL)
      Row() {
        Row()
          .height(10)
          .width(`${this.getDailyGoalCompletionRate()}%`)
          .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
          .backgroundColor(UI_COLORS.MINT)
      }
      .width(Constant.PERCENT_FULL)
      .height(10)
      .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
      .backgroundColor(UI_COLORS.MINT_LIGHT)
      if (!this.hasVisibleDailyGoals()) {
        Text('\u76EE\u6807\u5DF2\u5168\u90E8\u5220\u9664\uFF0C\u53EF\u968F\u65F6\u6062\u590D\u9ED8\u8BA4\u76EE\u6807')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.TEXT_SECONDARY)
          .width(Constant.PERCENT_FULL)
      }
      ForEach(this.getActiveDailyGoalIndexes(), (goalIndex: number) => {
        this.dailyGoalProductItem(this.dailyGoalNames[goalIndex], goalIndex)
      }, (goalIndex: number) => `${goalIndex}`)
      if (this.isAddingGoal) {
        this.addGoalEditor()
      }
      Text(this.isAddingGoal ? '\u6536\u8D77\u65B0\u589E\u76EE\u6807' : '+ \u6DFB\u52A0\u76EE\u6807')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .width(Constant.PERCENT_FULL)
        .padding({
          top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
          bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
        })
        .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
        .backgroundColor(UI_COLORS.MINT)
        .onClick(() => {
          if (this.isAddingGoal) {
            this.isAddingGoal = false;
          } else {
            this.showAddGoalEditor();
          }
        })
      Text('\u65B0\u589E\u76EE\u6807\u4F7F\u7528\u5361\u7247\u5F0F\u8F93\u5165\uFF1A\u586B\u540D\u79F0\u3001\u9009\u7C7B\u578B\u548C\u6570\u91CF\u540E\u786E\u8BA4\u3002')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
      Text('\u6062\u590D\u9ED8\u8BA4\u76EE\u6807')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.MINT)
        .textAlign(TextAlign.Center)
        .width(Constant.PERCENT_FULL)
        .padding({
          top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
          bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
        })
        .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
        .backgroundColor(UI_COLORS.MINT_LIGHT)
        .onClick(() => {
          this.restoreDefaultDailyGoals();
        })
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
    .shadow({
      radius: 10,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 4
    })
  }

  @Builder
  goalSummaryPill(label: string, value: string, color: ResourceColor) {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text(value)
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(color)
        .fontWeight(FontWeight.Bold)
      Text(label)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .maxLines(1)
    }
    .layoutWeight(1)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_MEDIUM)
    .backgroundColor(Color.White)
  }

  @Builder
  dailyGoalProductItem(goalName: string, index: number) {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text(this.getDailyGoalIcon(index))
          .fontSize(24)
        Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
          Text(goalName)
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor(UI_COLORS.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
          Text(`${this.getDailyGoalProgress(index)} / ${this.dailyGoalTargets[index]} 路 +${this.dailyGoalRewards[index]}\u79EF\u5206`)
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(UI_COLORS.TEXT_SECONDARY)
            .maxLines(1)
        }
        .layoutWeight(1)
        Text(this.dailyGoalRewardClaimed[index] ? '\u5DF2\u9886\u53D6' :
          (this.isDailyGoalAchieved(index) ? '\u53EF\u9886\u53D6' : '\u8FDB\u884C\u4E2D'))
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(this.dailyGoalRewardClaimed[index] ? UI_COLORS.TEXT_WEAK :
            (this.isDailyGoalAchieved(index) ? Color.White : UI_COLORS.MINT))
          .padding({
            left: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
            right: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
            top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
            bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
          })
          .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
          .backgroundColor(this.dailyGoalRewardClaimed[index] ? '#F1F3F5' :
            (this.isDailyGoalAchieved(index) ? UI_COLORS.MINT : UI_COLORS.MINT_LIGHT))
        Text('\u5220\u9664')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor('#D94838')
          .padding({
            left: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
            right: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
            top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
            bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
          })
          .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
          .backgroundColor('#FFF1F0')
          .onClick(() => {
            this.confirmDeleteDailyGoal(index);
          })
      }
      .width(Constant.PERCENT_FULL)
      Row() {
        Row()
          .height(8)
          .width(`${this.getDailyGoalPercent(index)}%`)
          .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
          .backgroundColor(this.isDailyGoalAchieved(index) ? UI_COLORS.MINT : UI_COLORS.FOCUS_BLUE)
      }
      .width(Constant.PERCENT_FULL)
      .height(8)
      .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
      .backgroundColor(UI_COLORS.BLUE_LIGHT)
      Row() {
        Text(this.dailyGoalTypeNames[this.normalizeGoalType(this.dailyGoalTypes[index])])
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.TEXT_SECONDARY)
          .layoutWeight(1)
        Text(`${this.getDailyGoalPercent(index)}%`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(this.isDailyGoalAchieved(index) ? UI_COLORS.MINT : UI_COLORS.FOCUS_BLUE)
      }
      .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(this.isDailyGoalAchieved(index) ? UI_COLORS.MINT_LIGHT : Color.White)
  }

  @Builder
  dailyGoalItem(goalName: string, index: number) {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Row() {
        Text(goalName)
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor('#182431')
          .layoutWeight(1)
          .maxLines(1)
        Text(this.dailyGoalRewardClaimed[index] ? '\u5DF2\u9886\u53D6' :
          (this.isDailyGoalAchieved(index) ? `+${this.dailyGoalRewards[index]}` : '\u8FDB\u884C\u4E2D'))
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(this.dailyGoalRewardClaimed[index] ? '#8A8A8A' :
            (this.isDailyGoalAchieved(index) ? this.getThemeColor() : $r('sys.color.ohos_id_color_text_secondary')))
        Text('\u5220\u9664')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor('#D94838')
          .padding({
            left: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
            right: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
            top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
            bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
          })
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
          .backgroundColor('#FFF1F0')
          .onClick(() => {
            this.confirmDeleteDailyGoal(index);
          })
      }
      .width(Constant.PERCENT_FULL)
      this.progressCard(`${this.getDailyGoalProgress(index)} / ${this.dailyGoalTargets[index]}`,
        this.getDailyGoalPercent(index), `${this.dailyGoalTypeNames[this.normalizeGoalType(this.dailyGoalTypes[index])]} 路 ${this.isDailyGoalAchieved(index) ? '\u5DF2\u8FBE\u6210' : '\u672A\u8FBE\u6210'}`)
    }
    .width(Constant.PERCENT_FULL)
  }

  @Builder
  addGoalEditor() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      TextInput({ placeholder: '\u76EE\u6807\u540D\u79F0', text: this.newGoalName })
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .backgroundColor(Color.White)
        .onChange((value: string) => {
          this.newGoalName = value;
        })
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text('\u7C7B\u578B')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        Text(this.dailyGoalTypeNames[this.newGoalTypeIndex])
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(this.getThemeColor())
          .layoutWeight(1)
        Text('\u9009\u62E9')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(Color.White)
          .padding({
            left: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
            right: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
            top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
            bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
          })
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
          .backgroundColor(this.getThemeColor())
          .onClick(() => {
            this.getUIContext().showTextPickerDialog({
              range: this.dailyGoalTypeNames,
              selected: this.newGoalTypeIndex,
              onAccept: (value: TextPickerResult) => {
                this.newGoalTypeIndex = Number(value.index);
              }
            });
          })
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text('\u76EE\u6807\u6570\u503C')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        Text(this.dailyGoalTargetNames[this.newGoalTargetIndex])
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(this.getThemeColor())
          .layoutWeight(1)
        Text('\u9009\u62E9')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(Color.White)
          .padding({
            left: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
            right: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
            top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
            bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
          })
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
          .backgroundColor(this.getThemeColor())
          .onClick(() => {
            this.getUIContext().showTextPickerDialog({
              range: this.dailyGoalTargetNames,
              selected: this.newGoalTargetIndex,
              onAccept: (value: TextPickerResult) => {
                this.newGoalTargetIndex = Number(value.index);
              }
            });
          })
      }
      .width(Constant.PERCENT_FULL)
      Text('\u786E\u8BA4\u6DFB\u52A0')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .width(Constant.PERCENT_FULL)
        .padding({
          top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
          bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
        })
        .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
        .backgroundColor(this.getThemeColor())
        .onClick(() => {
          this.confirmAddDailyGoal();
        })
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
    .backgroundColor(this.getThemeLightColor())
  }

  @Builder
  outfitStore() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Row() {
        Text('\uD83C\uDF80 \u88C5\u626E\u5546\u57CE')
          .fontSize($r('sys.float.ohos_id_text_size_headline8'))
          .fontColor(UI_COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text(`${this.score}\u79EF\u5206`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.ORANGE)
          .padding({
            left: STYLE_CONFIG.LIST_ITEM_GUTTER,
            right: STYLE_CONFIG.LIST_ITEM_GUTTER,
            top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
            bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
          })
          .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
          .backgroundColor(UI_COLORS.CREAM_WHITE)
      }
      .width(Constant.PERCENT_FULL)
      Text('\u7528\u81EA\u5F8B\u79EF\u5206\u5151\u6362\u5C0F\u88C5\u626E\uFF0C\u7ED9\u5B66\u4E60\u4F19\u4F34\u6362\u4E00\u4E2A\u65B0\u5FC3\u60C5')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.outfitNames, (outfitName: string, index: number) => {
          this.outfitProductCard(index)
        }, (outfitName: string) => outfitName)
      }
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
    .shadow({
      radius: 10,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 4
    })
  }

  @Builder
  outfitProductCard(index: number) {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text(this.getOutfitIcon(index))
        .fontSize(34)
      Text(this.getOutfitDisplayName(index))
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(this.equippedOutfitIndex === index ? UI_COLORS.PET_PURPLE : UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
      Text(this.ownedOutfits[index] ? '\u5DF2\u62E5\u6709' : `${this.outfitPrices[index]}\u79EF\u5206`)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(this.ownedOutfits[index] ? UI_COLORS.MINT : UI_COLORS.ORANGE)
      Text(this.getOutfitActionText(index))
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(this.equippedOutfitIndex === index || (!this.ownedOutfits[index] && this.score >= this.outfitPrices[index]) ?
          Color.White : UI_COLORS.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
        .width(Constant.PERCENT_FULL)
        .padding({
          top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
          bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
        })
        .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
        .backgroundColor(this.equippedOutfitIndex === index ? UI_COLORS.PET_PURPLE :
          (!this.ownedOutfits[index] && this.score >= this.outfitPrices[index] ? UI_COLORS.ORANGE : '#F1F3F5'))
    }
    .width('48%')
    .margin({ right: STYLE_CONFIG.ICON_GUTTER, bottom: STYLE_CONFIG.ICON_GUTTER })
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(this.equippedOutfitIndex === index ? UI_COLORS.PINK_LIGHT : Color.White)
    .shadow({
      radius: 8,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 3
    })
    .onClick(() => {
      this.handleOutfitTap(index);
    })
  }

  @Builder
  petCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('\uD83D\uDC3E \u5B66\u4E60\u4F19\u4F34')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text(this.getPetEmoji())
          .fontSize(76)
        Text(`Lv.${this.getPetLevel()} ${this.getPetName()}`)
          .fontSize($r('sys.float.ohos_id_text_size_headline7'))
          .fontColor(UI_COLORS.PET_PURPLE)
          .fontWeight(FontWeight.Bold)
        Text('\u4ECA\u5929\u4E5F\u8BA4\u771F\u52AA\u529B\u5566\uFF01')
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor(UI_COLORS.TEXT_PRIMARY)
        Text(this.getPetStatusText())
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.TEXT_SECONDARY)
          .maxLines(2)
      }
      .width(Constant.PERCENT_FULL)
      .padding(STYLE_CONFIG.UI_CARD_PADDING)
      .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
      .backgroundColor(UI_COLORS.PINK_LIGHT)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.petInfoPill('\u5F53\u524D\u79EF\u5206', `${this.score}`, UI_COLORS.ORANGE)
        this.petInfoPill('\u5BA0\u7269\u6210\u957F\u503C', `${this.petExp}`, UI_COLORS.PET_PURPLE)
      }
      .width(Constant.PERCENT_FULL)
      Row() {
        Row()
          .height(10)
          .width(`${this.getPetProgress()}%`)
          .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
          .backgroundColor(UI_COLORS.PET_PURPLE)
      }
      .width(Constant.PERCENT_FULL)
      .height(10)
      .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
      .backgroundColor(Color.White)
      Row() {
        Text(this.getPetExpToNextLevel() === 0 ? '\u5DF2\u8FBE\u5230\u5F53\u524D\u6700\u9AD8\u7B49\u7EA7' :
          `\u8DDD\u79BB\u4E0B\u4E00\u7EA7\u8FD8\u5DEE ${this.getPetExpToNextLevel()}\u6210\u957F\u503C`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.TEXT_SECONDARY)
          .layoutWeight(1)
        Text(`${this.getPetProgress()}%`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.PET_PURPLE)
      }
      .width(Constant.PERCENT_FULL)
      this.petGrowthStageCard()
      Text(`\u4E13\u6CE8 ${this.getTotalFocusCount()}\u6B21 / ${this.getTotalFocusMinutes()}\u5206\u949F\uFF0C\u6BCF\u4E00\u6B21\u90FD\u5728\u7ED9\u5B83\u5145\u7535`)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(UI_COLORS.CREAM_WHITE)
    .shadow({
      radius: 12,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 5
    })
  }

  @Builder
  petInfoPill(label: string, value: string, color: ResourceColor) {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text(value)
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(color)
        .fontWeight(FontWeight.Bold)
      Text(label)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .maxLines(1)
    }
    .layoutWeight(1)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_MEDIUM)
    .backgroundColor(Color.White)
  }

  @Builder
  petGrowthStageCard() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Row() {
        Text('\u6210\u957F\u9636\u6BB5')
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor(UI_COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
        Text(`Lv.${this.getPetLevel()}`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.PET_PURPLE)
      }
      .width(Constant.PERCENT_FULL)
      Flex({ wrap: FlexWrap.Wrap }) {
        this.petStagePill('\u5B66\u4E60\u86CB', this.getPetLevel() === 1)
        this.petStagePill('\u5B66\u4E60\u5E7C\u5D3D', this.getPetLevel() === 2)
        this.petStagePill('\u52AA\u529B\u5C0F\u732B', this.getPetLevel() === 3)
        this.petStagePill('\u4E13\u6CE8\u5C0F\u718A', this.getPetLevel() === 4)
        this.petStagePill('\u667A\u6167\u5C0F\u72D0', this.getPetLevel() === 5)
        this.petStagePill('\u5B66\u4E60\u795E\u9F99', this.getPetLevel() === 6)
      }
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_MEDIUM)
    .backgroundColor(Color.White)
  }

  @Builder
  petStagePill(label: string, active: boolean) {
    Text(label)
      .fontSize($r('sys.float.ohos_id_text_size_body2'))
      .fontColor(active ? Color.White : UI_COLORS.TEXT_SECONDARY)
      .padding({
        left: STYLE_CONFIG.LIST_ITEM_GUTTER,
        right: STYLE_CONFIG.LIST_ITEM_GUTTER,
        top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
        bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
      })
      .margin({ right: STYLE_CONFIG.ICON_GUTTER, bottom: STYLE_CONFIG.ICON_GUTTER })
      .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
      .backgroundColor(active ? UI_COLORS.PET_PURPLE : '#F1F3F5')
  }

  @Builder
  focusCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.sectionTitle('\u5F53\u524D\u4EFB\u52A1')
      Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text(this.focusTaskKey.length > 0 ? this.getFocusTaskName() : '\u8FD8\u6CA1\u6709\u9009\u62E9\u4EFB\u52A1')
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor(UI_COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .width(Constant.PERCENT_FULL)
        Text(this.focusTaskKey.length > 0 ? (this.isFocusRunning ? '\u6B63\u5728\u4E13\u6CE8\u4E2D\uFF0C\u547C\u5438\u6162\u4E00\u70B9' : '\u5DF2\u6682\u505C\uFF0C\u72B6\u6001\u56DE\u6765\u5C31\u7EE7\u7EED') :
          '\u4ECE\u4E0B\u65B9\u9009\u4E00\u4E2A\u4EFB\u52A1\uFF0C\u518D\u7528\u80F6\u56CA\u9009\u62E9 5 / 15 / 25 \u5206\u949F')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.TEXT_SECONDARY)
          .width(Constant.PERCENT_FULL)
      }
      .width(Constant.PERCENT_FULL)
      .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
      .borderRadius(STYLE_CONFIG.UI_RADIUS_MEDIUM)
      .backgroundColor(UI_COLORS.BLUE_LIGHT)

      Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        Text(this.focusTaskKey.length > 0 ? this.formatFocusTime() : `${this.selectedFocusMinutes}:00`)
          .fontSize(48)
          .fontColor(UI_COLORS.FOCUS_BLUE)
          .fontWeight(FontWeight.Bold)
        Text(this.focusTaskKey.length > 0 ? `${this.getFocusProgress()}%` : '\u51C6\u5907\u5F00\u59CB')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.TEXT_SECONDARY)
      }
      .width(Constant.PERCENT_FULL)
      .padding({
        top: STYLE_CONFIG.UI_CARD_PADDING,
        bottom: STYLE_CONFIG.UI_CARD_PADDING
      })
      .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
      .backgroundColor(UI_COLORS.CARD_WHITE)
      Row() {
        Row()
          .height(10)
          .width(`${this.getFocusProgress()}%`)
          .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
          .backgroundColor(UI_COLORS.FOCUS_BLUE)
      }
      .width(Constant.PERCENT_FULL)
      .height(10)
      .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
      .backgroundColor(UI_COLORS.BLUE_LIGHT)
      if (this.focusTaskKey.length > 0) {
        Text('\u8FDB\u5165\u65F6\u949F\u754C\u9762')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.FOCUS_BLUE)
          .textAlign(TextAlign.Center)
          .width(Constant.PERCENT_FULL)
          .padding({
            top: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
            bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2
          })
          .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
          .backgroundColor(UI_COLORS.BLUE_LIGHT)
          .onClick(() => {
            this.isFocusImmersiveMode = true;
            this.isFocusRoomVisible = true;
            this.currentTab = 3;
          })
        Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
          Text(this.isFocusRunning ? '\u6682\u505C' : '\u7EE7\u7EED')
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(Color.White)
            .padding({
              left: STYLE_CONFIG.LIST_ITEM_GUTTER,
              right: STYLE_CONFIG.LIST_ITEM_GUTTER,
              top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
              bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
            })
            .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
            .backgroundColor(UI_COLORS.FOCUS_BLUE)
            .onClick(() => {
              this.pauseOrResumeFocus();
            })
          Text('\u63D0\u524D\u7ED3\u675F')
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(Color.White)
            .padding({
              left: STYLE_CONFIG.LIST_ITEM_GUTTER,
              right: STYLE_CONFIG.LIST_ITEM_GUTTER,
              top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
              bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
            })
            .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
            .backgroundColor(UI_COLORS.ORANGE)
            .onClick(() => {
              this.cancelFocus();
            })
        }
        .width(Constant.PERCENT_FULL)
        .justifyContent(FlexAlign.End)
      }
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
    .shadow({
      radius: 12,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 5
    })
  }

  @Builder
  statisticsPanel() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.sectionTitle('\u4EFB\u52A1\u7EDF\u8BA1')
      Row() {
        Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
          Text(`${this.getTotalCount()}`)
            .fontSize($r('sys.float.ohos_id_text_size_headline8'))
            .fontColor(this.getThemeColor())
          Text('\u603B\u6570')
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        }
        .layoutWeight(1)

        Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
          Text(`${this.getCompletedCount()}`)
            .fontSize($r('sys.float.ohos_id_text_size_headline8'))
            .fontColor(this.getThemeColor())
          Text('\u5DF2\u5B8C\u6210')
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        }
        .layoutWeight(1)

        Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
          Text(`${this.getUncompletedCount()}`)
            .fontSize($r('sys.float.ohos_id_text_size_headline8'))
            .fontColor(this.getThemeColor())
          Text('\u672A\u5B8C\u6210')
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        }
        .layoutWeight(1)

        Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
          Text(`${this.getCompletionRate()}%`)
            .fontSize($r('sys.float.ohos_id_text_size_headline8'))
            .fontColor(this.getThemeColor())
          Text('\u5B8C\u6210\u7387')
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        }
        .layoutWeight(1)
      }
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
    .backgroundColor(Color.White)
  }

  @Builder
  statItem(label: string, value: string) {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text(value)
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(this.getThemeColor())
      Text(label)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
    }
    .layoutWeight(1)
  }

  @Builder
  deliveryRecordCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('\uD83D\uDCE1 \u771F\u5B9E\u6295\u9001\u72B6\u6001')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text(this.lastDeliveryType)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(Color.White)
          .padding({
            left: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
            right: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
            top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
            bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
          })
          .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
          .backgroundColor(this.lastDeliveryType === '\u6A21\u62DF\u8BB0\u5F55' ? UI_COLORS.TEXT_WEAK : UI_COLORS.MINT)
        Text(`\u5F53\u524D\u53D1\u73B0\u8BBE\u5907\u6570\uFF1A${this.discoveredDeviceCount}`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.TEXT_SECONDARY)
          .layoutWeight(1)
      }
      .width(Constant.PERCENT_FULL)
      Text(this.realDeliveryStatus)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(UI_COLORS.FOCUS_BLUE)
        .width(Constant.PERCENT_FULL)
      this.deliveryStatusRow('\u6743\u9650\u72B6\u6001', '\u771F\u5B9E\u6295\u9001\u524D\u4F1A\u81EA\u52A8\u68C0\u67E5/\u7533\u8BF7')
      this.deliveryStatusRow('\u6700\u8FD1\u53D1\u9001\u4EFB\u52A1', this.lastRealSentTask)
      this.deliveryStatusRow('\u6700\u8FD1\u63A5\u6536\u4EFB\u52A1', this.lastRealReceivedTask)
      this.deliveryStatusRow('\u6700\u8FD1\u8BB0\u5F55', this.lastDeliveryRecord)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
    .shadow({
      radius: 10,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 4
    })
  }

  @Builder
  deliveryStatusRow(label: string, value: string) {
    Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text(label)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(116)
      Text(value)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .layoutWeight(1)
        .maxLines(2)
    }
    .width(Constant.PERCENT_FULL)
  }

  @Builder
  deviceTestGuideCard() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text('\uD83E\uDDEA \u771F\u673A\u6D4B\u8BD5\u6B65\u9AA4')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Text('1\uFF09\u4E24\u53F0 HarmonyOS \u8BBE\u5907\u5B89\u88C5\u540C\u4E00 App')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .width(Constant.PERCENT_FULL)
      Text('2\uFF09\u6253\u5F00\u84DD\u7259 / Wi-Fi\uFF0C\u767B\u5F55\u540C\u8D26\u53F7\u6216\u5EFA\u7ACB\u53EF\u4FE1\u5173\u7CFB')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .width(Constant.PERCENT_FULL)
      Text('3\uFF09\u6388\u6743\u5206\u5E03\u5F0F\u6570\u636E\u540C\u6B65\uFF0C\u8BBE\u5907 B \u5148\u6253\u5F00 App')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .width(Constant.PERCENT_FULL)
      Text('4\uFF09\u8BBE\u5907 A \u9009\u62E9\u4EFB\u52A1\u5E76\u53D1\u8D77\u771F\u5B9E\u6295\u9001')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .width(Constant.PERCENT_FULL)
      Text('5\uFF09\u8BBE\u5907 B \u6536\u5230\u540E\u4F1A\u52A0\u5165\u5F85\u529E\u5217\u8868')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
  }

  @Builder
  dashboardPanel() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text(`\u5F53\u524D\u79EF\u5206\uFF1A${this.score}`)
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(this.getThemeColor())
        .width(Constant.PERCENT_FULL)
      this.checkInCard()
      this.focusCard()
      this.petCard()
      this.statisticsPanel()
      this.themeStore()
      this.deliveryRecordCard()
      this.deviceTestGuideCard()
    }
    .width(Constant.PERCENT_FULL)
  }

  @Builder
  searchSortPanel() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        TextInput({ placeholder: '\u641C\u7D22\u5F85\u529E', text: this.searchKeyword })
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .layoutWeight(1)
          .height(42)
          .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
          .backgroundColor(UI_COLORS.CREAM_WHITE)
          .onChange((value: string) => {
            this.searchKeyword = value;
          })
        Text('+ \u65B0\u589E')
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor(Color.White)
          .padding({
            left: STYLE_CONFIG.UI_CARD_PADDING,
            right: STYLE_CONFIG.UI_CARD_PADDING,
            top: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
            bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2
          })
          .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
          .backgroundColor(UI_COLORS.MINT)
          .onClick(() => {
            this.showAddTodoDialog();
          })
      }

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.sortNames, (sortName: string, index: number) => {
          Text(sortName)
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(this.sortIndex === index ? Color.White : UI_COLORS.MINT)
            .padding({
              left: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 3,
              right: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 3,
              top: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
              bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2
            })
            .margin({
              right: STYLE_CONFIG.ICON_GUTTER,
              bottom: STYLE_CONFIG.ICON_GUTTER
            })
            .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
            .backgroundColor(this.sortIndex === index ? UI_COLORS.MINT : UI_COLORS.MINT_LIGHT)
            .onClick(() => {
              this.sortIndex = index;
            })
        }, (sortName: string) => sortName)
      }
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
    .shadow({
      radius: 10,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 4
    })
  }

  @Builder
  taskListPanel() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.taskHeroCard()
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.taskSummaryPill('\u603B\u4EFB\u52A1', `${this.getTotalCount()}`, UI_COLORS.FOCUS_BLUE)
        this.taskSummaryPill('\u5DF2\u5B8C\u6210', `${this.getCompletedCount()}`, UI_COLORS.MINT)
        this.taskSummaryPill('\u5B8C\u6210\u7387', `${this.getCompletionRate()}%`, UI_COLORS.ORANGE)
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text('\u4ECA\u65E5\u5C0F\u7EC4\u4EF6')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.TEXT_SECONDARY)
          .layoutWeight(1)
        Text('\u6E05\u7406\u5DF2\u5B8C\u6210')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(this.getCompletedCount() > 0 ? '#D94838' : UI_COLORS.TEXT_WEAK)
          .padding({
            left: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
            right: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
            top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
            bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
          })
          .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
          .backgroundColor('#FFF1F0')
          .onClick(() => {
            this.confirmClearCompletedTodos();
          })
      }
      .width(Constant.PERCENT_FULL)
      this.searchSortPanel()
      List({ initialIndex: 0, space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        if (this.getVisibleTodos().length === 0) {
          ListItem() {
            this.taskEmptyState()
          }
        }

        ForEach(this.getVisibleTodos(), (toDoItem: ToDo) => {
          ListItem() {
            ToDoListItem({
              toDoItem: toDoItem,
              onToggleComplete: (itemKey: string) => {
                this.toggleTaskCompleteByKey(itemKey);
              },
              deliverTodo: (item: ToDo) => {
                this.showDeliveryPicker(item);
              },
              startFocus: (item: ToDo) => {
                this.showFocusPicker(item);
              },
              showTodoDetail: (item: ToDo) => {
                this.showTodoDetail(item);
              },
              updateTodoItem: (item: ToDo) => {
                this.updateTodoItem(item);
              }
            })
          }
          .swipeAction({ end: this.itemEnd(toDoItem), edgeEffect: SwipeEdgeEffect.Spring })
        }, (toDoItem: ToDo) => `${toDoItem.key}_${toDoItem.isCompleted}`)
      }
      .layoutWeight(1)
      .listDirection(Axis.Vertical)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width(Constant.PERCENT_FULL)
    .height(Constant.PERCENT_FULL)
    .backgroundColor($r('app.color.background_color'))
  }

  @Builder
  taskHeroCard() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text('\uD83D\uDCDD \u4ECA\u65E5\u4EFB\u52A1')
        .fontSize($r('sys.float.ohos_id_text_size_headline7'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Text('\u628A\u5927\u76EE\u6807\u62C6\u6210\u4E00\u4E2A\u4E2A\u5C0F\u5B8C\u6210')
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(UI_COLORS.MINT_LIGHT)
    .shadow({
      radius: 12,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 5
    })
  }

  @Builder
  taskSummaryPill(label: string, value: string, color: ResourceColor) {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text(value)
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(color)
        .fontWeight(FontWeight.Bold)
      Text(label)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .maxLines(1)
    }
    .layoutWeight(1)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_MEDIUM)
    .backgroundColor(Color.White)
    .shadow({
      radius: 8,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 3
    })
  }

  @Builder
  taskEmptyState() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text('\uD83C\uDF31')
        .fontSize(42)
      Text(this.getTotalCount() === 0 ? '\u4ECA\u5929\u8FD8\u6CA1\u6709\u5B89\u6392\u4EFB\u52A1\u54E6' :
        '\u6CA1\u6709\u5339\u914D\u7684\u5F85\u529E')
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
      Text('\u5148\u5B8C\u6210\u4E00\u4E2A\u5C0F\u76EE\u6807\u5427 \u2728')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
  }

  @Builder
  overviewMetric(label: string, value: string) {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text(value)
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(this.getThemeColor())
      Text(label)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
    }
    .layoutWeight(1)
    .padding(STYLE_CONFIG.ICON_GUTTER)
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
    .backgroundColor(this.getThemeLightColor())
  }

  @Builder
  overviewMetricCard(iconText: string, label: string, value: string, color: ResourceColor, backgroundColor: ResourceColor) {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Row() {
        Text(iconText)
          .fontSize(22)
        Blank()
      }
      .width(Constant.PERCENT_FULL)
      Text(value)
        .fontSize($r('sys.float.ohos_id_text_size_headline7'))
        .fontColor(color)
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
      Text(label)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .maxLines(1)
    }
    .layoutWeight(1)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_MEDIUM)
    .backgroundColor(backgroundColor)
    .shadow({
      radius: 10,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 4
    })
  }

  @Builder
  pageContainer() {
    if (this.currentTab === 3) {
      this.focusPage()
    } else if (this.currentTab === 1) {
      Column() {
        this.taskListPanel()
      }
      .layoutWeight(1)
      .width(Constant.PERCENT_FULL)
      .padding({
        bottom: STYLE_CONFIG.UI_PAGE_BOTTOM_SPACE
      })
    } else {
      Scroll() {
        Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
          if (this.currentTab === 0) {
            this.homePage()
          } else if (this.currentTab === 2) {
            this.calendarPage()
          } else if (this.currentTab === 3) {
            this.focusPage()
          } else if (this.currentTab === 4) {
            this.statisticsPage()
          } else if (this.currentTab === 5) {
            this.petPage()
          } else if (this.currentTab === 6) {
            this.devicePage()
          } else {
            this.profilePage()
          }
        }
        .width(Constant.PERCENT_FULL)
        .padding({
          left: STYLE_CONFIG.LIST_ITEM_GUTTER,
          right: STYLE_CONFIG.LIST_ITEM_GUTTER,
          top: STYLE_CONFIG.LIST_ITEM_GUTTER,
          bottom: STYLE_CONFIG.UI_PAGE_BOTTOM_SPACE
        })
      }
      .layoutWeight(1)
      .edgeEffect(EdgeEffect.Spring)
    }
  }

  @Builder
  homePage() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.welcomeCard()
      this.todayFocusOverviewCard()
      if (this.focusTaskKey.length > 0) {
        this.continueFocusCard()
      }
      this.petMiniCard()
    }
    .width(Constant.PERCENT_FULL)
  }

  @Builder
  welcomeCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
          Text(this.getTodayDisplayText())
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(UI_COLORS.TEXT_SECONDARY)
            .width(Constant.PERCENT_FULL)
          Text('\u4ECA\u5929\u4E5F\u7EE7\u7EED\u52AA\u529B\u5427')
            .fontSize($r('sys.float.ohos_id_text_size_headline7'))
            .fontColor(UI_COLORS.TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
            .width(Constant.PERCENT_FULL)
          Text(`\u8FDE\u7EED\u4E13\u6CE8 ${this.dailyGoalStreak}\u5929`)
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor(UI_COLORS.TEXT_SECONDARY)
            .width(Constant.PERCENT_FULL)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        Text(this.getPetEmoji())
          .fontSize(48)
      }
      .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(UI_COLORS.CREAM_WHITE)
    .shadow({
      radius: 12,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 5
    })
  }

  @Builder
  todayFocusOverviewCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
          Text('\u4ECA\u65E5\u72B6\u6001')
            .fontSize($r('sys.float.ohos_id_text_size_headline8'))
            .fontColor(UI_COLORS.TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
            .width(Constant.PERCENT_FULL)
          Text(this.getStudyBuddyHealingQuote())
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(UI_COLORS.TEXT_SECONDARY)
            .maxLines(2)
            .width(Constant.PERCENT_FULL)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.currentOutfitInfo('\u4E13\u6CE8\u5206\u949F', `${this.todayFocusMinutes}\u5206`, UI_COLORS.FOCUS_BLUE)
        this.currentOutfitInfo('\u5B8C\u6210\u4EFB\u52A1', `${this.todayCompletedCount}`, UI_COLORS.MINT)
        this.currentOutfitInfo('\u5F53\u524D\u76EE\u6807', this.getHomeCurrentGoalText(), UI_COLORS.ORANGE)
      }
      .width(Constant.PERCENT_FULL)
      Text(this.getTodayQuote())
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
    .shadow({
      radius: 12,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 5
    })
  }

  @Builder
  continueFocusCard() {
    Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text('\u7EE7\u7EED\u4E13\u6CE8')
          .fontSize($r('sys.float.ohos_id_text_size_headline8'))
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
          .width(Constant.PERCENT_FULL)
        Text(`${this.getFocusTaskName()} · ${this.formatFocusTime()}`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor('#DDE7FF')
          .maxLines(1)
          .width(Constant.PERCENT_FULL)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text('\u8FDB\u5165')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.FOCUS_BLUE)
        .padding({
          left: STYLE_CONFIG.LIST_ITEM_GUTTER,
          right: STYLE_CONFIG.LIST_ITEM_GUTTER,
          top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
          bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
        })
        .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
        .backgroundColor(Color.White)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(UI_COLORS.FOCUS_BLUE)
    .shadow({
      radius: 10,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 4
    })
    .onClick(() => {
      this.isFocusRoomVisible = true;
      this.currentTab = 3;
    })
  }

  @Builder
  bannerPill(label: string, textColor: ResourceColor, backgroundColor: ResourceColor) {
    Text(label)
      .fontSize($r('sys.float.ohos_id_text_size_body2'))
      .fontColor(textColor)
      .maxLines(1)
      .padding({
        left: STYLE_CONFIG.LIST_ITEM_GUTTER,
        right: STYLE_CONFIG.LIST_ITEM_GUTTER,
        top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
        bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
      })
      .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
      .backgroundColor(backgroundColor)
  }

  @Builder
  todayAdviceCard() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      this.sectionTitle('\u4ECA\u65E5\u5B66\u4E60\u5EFA\u8BAE')
      Text(this.getTodayAdvice())
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor('#182431')
        .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
    .backgroundColor(Color.White)
  }

  @Builder
  studyAtmosphereCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text('\u2728')
          .fontSize(24)
        Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
          Text('\u4ECA\u65E5\u5B66\u4E60\u6C1B\u56F4')
            .fontSize($r('sys.float.ohos_id_text_size_headline8'))
            .fontColor(UI_COLORS.TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
            .width(Constant.PERCENT_FULL)
          Text(this.getTodayQuote())
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(UI_COLORS.TEXT_SECONDARY)
            .width(Constant.PERCENT_FULL)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        this.bannerPill(this.getTodayStudyMoodTitle(), UI_COLORS.MINT, UI_COLORS.MINT_LIGHT)
        this.bannerPill(`\uD83C\uDFC5 ${this.getLearningTitle()}`, UI_COLORS.PET_PURPLE, UI_COLORS.PINK_LIGHT)
      }
      .width(Constant.PERCENT_FULL)
      Text(this.getTodayStudyMoodDesc())
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
      Text(`\u4E0B\u4E00\u6B65\uFF1A${this.getNextStepSuggestion()}`)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.ORANGE)
        .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
    .shadow({
      radius: 10,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 4
    })
  }

  @Builder
  calendarPage() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.calendarHeroCard()
      this.calendarDeadlineOverview()
      this.countdownCard()
      this.calendarGroupCard('\uD83D\uDEA8 \u5DF2\u903E\u671F', this.getOverdueTodos())
      this.calendarGroupCard('\uD83C\uDF24 \u4ECA\u5929', this.getTodosByDeadlineRange(0, 0))
      this.calendarGroupCard('\uD83C\uDF05 \u660E\u5929', this.getTodosByDeadlineRange(1, 1))
      this.calendarGroupCard('\uD83D\uDCC6 \u672C\u5468', this.getTodosByDeadlineRange(2, 7))
      this.calendarGroupCard('\uD83C\uDF08 \u4EE5\u540E', this.getFutureTodosAfterWeek())
    }
    .width(Constant.PERCENT_FULL)
  }

  @Builder
  calendarHeroCard() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text('\uD83D\uDCC5 \u65E5\u5386\u89C6\u56FE')
        .fontSize($r('sys.float.ohos_id_text_size_headline7'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Text('\u91CD\u8981\u4EFB\u52A1\u548C\u622A\u6B62\u65E5\u671F\u4E00\u773C\u770B\u6E05')
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(UI_COLORS.CREAM_WHITE)
    .shadow({
      radius: 12,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 5
    })
  }

  @Builder
  calendarDeadlineOverview() {
    Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.taskSummaryPill('\u5DF2\u903E\u671F', `${this.getOverdueTodos().length}`, '#D94838')
      this.taskSummaryPill('\u4ECA\u5929', `${this.getTodosByDeadlineRange(0, 0).length}`, UI_COLORS.ORANGE)
      this.taskSummaryPill('\u660E\u5929', `${this.getTodosByDeadlineRange(1, 1).length}`, UI_COLORS.FOCUS_BLUE)
    }
    .width(Constant.PERCENT_FULL)
  }

  @Builder
  focusPage() {
    if (this.isFocusRoomVisible || this.focusTaskKey.length > 0) {
      this.immersiveFocusClockPage()
    } else {
      Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.focusHeroCard()
        this.focusModeSelector()
        this.focusTodayDataCard()
        this.focusEncourageCard()
        this.quickFocusTasks()
      }
      .width(Constant.PERCENT_FULL)
    }
  }

  @Builder
  immersiveFocusClockPage() {
    Stack() {
      Column() {
        Row() {
          Row()
            .width(190)
            .height(190)
            .borderRadius(95)
            .backgroundColor('#33FFB7C5')
          Blank()
        }
        .width(Constant.PERCENT_FULL)
        Row() {
          Blank()
          Row()
            .width(240)
            .height(240)
            .borderRadius(120)
            .backgroundColor('#224D7CFE')
        }
        .width(Constant.PERCENT_FULL)
        Row() {
          Row()
            .width(130)
            .height(130)
            .borderRadius(65)
            .backgroundColor('#22FFCF7A')
          Blank()
          Row()
            .width(92)
            .height(92)
            .borderRadius(46)
            .backgroundColor('#229B7CFF')
        }
        .width(Constant.PERCENT_FULL)
        Blank()
      }
      .width(Constant.PERCENT_FULL)
      .height(Constant.PERCENT_FULL)
      .padding(STYLE_CONFIG.UI_CARD_PADDING)
      .backgroundColor(this.getFocusRoomBackgroundColor())

      Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        Blank()

        Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
          Text('\u5F53\u524D\u4EFB\u52A1')
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor('#C9D4F7')
          Text(this.focusTaskKey.length > 0 ? this.getFocusTaskName() : '\u8BF7\u4ECE\u4EFB\u52A1\u9875\u9009\u62E9\u4E13\u6CE8\u4EFB\u52A1')
            .fontSize($r('sys.float.ohos_id_text_size_headline8'))
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
            .maxLines(2)
        }
        .width(Constant.PERCENT_FULL)
        .padding(STYLE_CONFIG.UI_CARD_PADDING)
        .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
        .backgroundColor('#22FFFFFF')

        Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
          Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
            Text(this.focusTaskKey.length > 0 ? this.formatFocusTime() : `${this.selectedFocusMinutes}:00`)
              .fontSize(78)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
              .textAlign(TextAlign.Center)
            Text(this.getFocusStateText())
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontColor('#EAF0FF')
              .textAlign(TextAlign.Center)
          }
          .width(250)
          .height(250)
          .justifyContent(FlexAlign.Center)
          .borderRadius(125)
          .border({
            width: 2,
            color: '#55FFFFFF'
          })
          .backgroundColor('#20FFFFFF')
          .shadow({
            radius: 28,
            color: '#55000000',
            offsetX: 0,
            offsetY: 12
          })
          Row() {
            Row()
              .height(8)
              .width(`${this.focusTaskKey.length > 0 ? this.getFocusProgress() : 0}%`)
              .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
              .backgroundColor(this.getFocusRoomAccentColor())
          }
          .width('78%')
          .height(8)
          .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
          .backgroundColor('#30FFFFFF')
        }
        .width(Constant.PERCENT_FULL)

        Text(this.getTodayQuote())
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor('#DDE7FF')
          .textAlign(TextAlign.Center)
          .width(Constant.PERCENT_FULL)
          .padding({
            left: STYLE_CONFIG.UI_CARD_PADDING,
            right: STYLE_CONFIG.UI_CARD_PADDING
          })

        if (this.focusTaskKey.length === 0) {
          Text('\u8FD4\u56DE\u4EFB\u52A1\u9875\u9009\u62E9\u4E00\u4E2A\u4EFB\u52A1\u5F00\u59CB\u4E13\u6CE8')
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
            .width(Constant.PERCENT_FULL)
            .height(48)
            .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
            .backgroundColor('#28FFFFFF')
            .onClick(() => {
              this.exitFocusRoom();
            })
        } else {
          Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
            if (this.isFocusFinished || this.focusRemainingSeconds === 0) {
              this.focusRoomPrimaryAction('\u5B8C\u6210\u4E13\u6CE8', this.getFocusRoomAccentColor(), () => {
                this.completeFocus();
              })
            } else {
              this.focusRoomPrimaryAction(this.isFocusRunning ? '\u6682\u505C\u4E13\u6CE8' : '\u7EE7\u7EED\u4E13\u6CE8',
                '#32FFFFFF', () => {
                this.pauseOrResumeFocus();
              })
              this.focusRoomPrimaryAction('\u63D0\u524D\u7ED3\u675F', UI_COLORS.ORANGE, () => {
                this.cancelFocus();
              })
            }
          }
          .width(Constant.PERCENT_FULL)
        }

        Blank()
      }
      .width(Constant.PERCENT_FULL)
      .height(Constant.PERCENT_FULL)
      .padding({
        left: STYLE_CONFIG.UI_CARD_PADDING,
        right: STYLE_CONFIG.UI_CARD_PADDING,
        top: STYLE_CONFIG.UI_CARD_PADDING,
        bottom: STYLE_CONFIG.UI_CARD_PADDING
      })
    }
    .width(Constant.PERCENT_FULL)
    .height(Constant.PERCENT_FULL)
    .backgroundColor(this.getFocusRoomBackgroundColor())
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  focusRoomPrimaryAction(labelText: string, backgroundColor: ResourceColor, action: () => void) {
    Text(labelText)
      .fontSize($r('sys.float.ohos_id_text_size_body1'))
      .fontColor(Color.White)
      .fontWeight(FontWeight.Medium)
      .textAlign(TextAlign.Center)
      .width(Constant.PERCENT_FULL)
      .height(52)
      .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
      .backgroundColor(backgroundColor)
      .onClick(action)
  }

  @Builder
  focusRoomStatusCard() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text('\uD83D\uDCDA \u5F53\u524D\u5B66\u4E60')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor('#C9D4F7')
          .layoutWeight(1)
        Text(this.focusTaskKey.length > 0 ? this.getFocusTaskName() : '\u7B49\u5F85\u5F00\u59CB')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(Color.White)
          .maxLines(1)
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text('\uD83C\uDF19 \u5F53\u524D\u6C1B\u56F4')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor('#C9D4F7')
          .layoutWeight(1)
        Text(this.focusRoomNames[this.focusThemeIndex])
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(Color.White)
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text('\uD83D\uDD25 \u5F53\u524D\u72B6\u6001')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor('#C9D4F7')
          .layoutWeight(1)
        Text(this.getFocusStateText())
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(Color.White)
          .maxLines(1)
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text(`\u4ECA\u65E5\u756A\u8304 ${this.todayPomodoroCount}`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor('#DDE7FF')
          .layoutWeight(1)
        Text(`\u4E13\u6CE8 ${this.todayFocusMinutes}\u5206`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor('#DDE7FF')
          .layoutWeight(1)
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text(`\u79EF\u5206 ${this.score}`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor('#DDE7FF')
          .layoutWeight(1)
        Text(`\u4F19\u4F34 Lv.${this.getPetLevel()}`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor('#DDE7FF')
          .layoutWeight(1)
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        ForEach(this.focusRoomNames, (roomName: string, index: number) => {
          this.focusRoomThemePill(index)
        }, (roomName: string) => roomName)
      }
      .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor('#22FFFFFF')
  }

  @Builder
  focusRoomThemePill(index: number) {
    Text(index === this.focusThemeIndex ? '\u25CF' : '\u25CB')
      .fontSize(16)
      .fontColor(index === this.focusThemeIndex ? this.getFocusRoomAccentColor() : '#C9D4F7')
      .onClick(() => {
        this.focusThemeIndex = index;
      })
  }

  @Builder
  focusRoomStudyDesk() {
    Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.focusRoomDeskItem('\uD83D\uDCA1', '\u53F0\u706F')
      this.focusRoomDeskItem('\uD83D\uDCD6', '\u4E66\u672C')
      this.focusRoomDeskItem('\u2615', '\u70ED\u996E')
      this.focusRoomDeskItem('\uD83C\uDF31', '\u5C0F\u690D\u7269')
      this.focusRoomDeskItem('\uD83D\uDCDD', '\u7B14\u8BB0')
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor('#18FFFFFF')
  }

  @Builder
  focusRoomDeskItem(iconText: string, labelText: string) {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text(iconText)
        .fontSize(22)
      Text(labelText)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor('#C9D4F7')
        .maxLines(1)
    }
    .layoutWeight(1)
  }

  @Builder
  focusRoomBuddyCard() {
    Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text(this.getStudyBuddyName().substring(0, 2))
        .fontSize(34)
      Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text(this.getStudyBuddyName())
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
        Text(`${this.getStudyBuddyIdentity()} \u00B7 ${this.getStudyBuddyMood()}`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor('#DDE7FF')
          .maxLines(1)
        Text(this.getStudyBuddyMessage())
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor('#C9D4F7')
          .maxLines(2)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor('#22FFFFFF')
  }

  @Builder
  focusRoomStartPanel() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        ForEach(this.focusMinuteValues, (minuteValue: number) => {
          this.focusRoomMinutePill(minuteValue)
        }, (minuteValue: number) => `${minuteValue}`)
      }
      .width(Constant.PERCENT_FULL)
      if (this.getAllTodos().filter((item: ToDo) => !item.isCompleted).length === 0) {
        Text('\u6682\u65E0\u53EF\u4E13\u6CE8\u4EFB\u52A1\uFF0C\u5148\u53BB\u4EFB\u52A1\u9875\u6DFB\u52A0\u4E00\u4E2A\u5C0F\u76EE\u6807')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor('#DDE7FF')
          .textAlign(TextAlign.Center)
          .width(Constant.PERCENT_FULL)
      }
      ForEach(this.getAllTodos().filter((item: ToDo) => !item.isCompleted).slice(0, 3), (item: ToDo) => {
        this.focusRoomTaskStartItem(item)
      }, (item: ToDo) => item.key)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor('#1FFFFFFF')
  }

  @Builder
  focusRoomMinutePill(minuteValue: number) {
    Text(`${minuteValue}\u5206`)
      .fontSize($r('sys.float.ohos_id_text_size_body2'))
      .fontColor(this.selectedFocusMinutes === minuteValue ? Color.White : '#DDE7FF')
      .textAlign(TextAlign.Center)
      .layoutWeight(1)
      .padding({
        top: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
        bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2
      })
      .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
      .backgroundColor(this.selectedFocusMinutes === minuteValue ? this.getFocusRoomAccentColor() : '#20FFFFFF')
      .onClick(() => {
        this.selectedFocusMinutes = minuteValue;
      })
  }

  @Builder
  focusRoomTaskStartItem(item: ToDo) {
    Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text('\uD83D\uDCD6')
        .fontSize(18)
      Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text(item.name)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
        Text(`${this.getPriorityName(item.priority)} \u00B7 ${item.deadline > 0 ? this.getDeadlineText(item.deadline) : '\u65E0\u622A\u6B62'}`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor('#C9D4F7')
          .maxLines(1)
      }
      .layoutWeight(1)
      Text('\u5F00\u59CB')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(Color.White)
        .padding({
          left: STYLE_CONFIG.LIST_ITEM_GUTTER,
          right: STYLE_CONFIG.LIST_ITEM_GUTTER,
          top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
          bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
        })
        .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
        .backgroundColor(this.getFocusRoomAccentColor())
        .onClick(() => {
          this.startFocus(item, this.selectedFocusMinutes);
        })
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_MEDIUM)
    .backgroundColor('#18FFFFFF')
  }

  @Builder
  focusRoomMetric(iconText: string, valueText: string, labelText: string) {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text(iconText)
        .fontSize(18)
      Text(valueText)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
      Text(labelText)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor('#C9D4F7')
        .maxLines(1)
    }
    .layoutWeight(1)
    .padding(STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor('#20FFFFFF')
  }

  @Builder
  focusRoomAction(labelText: string, action: () => void) {
    Text(labelText)
      .fontSize(24)
      .fontColor(Color.White)
      .fontWeight(FontWeight.Medium)
      .textAlign(TextAlign.Center)
      .width(54)
      .height(54)
      .borderRadius(27)
      .backgroundColor('#2EFFFFFF')
      .border({
        width: 1,
        color: '#44FFFFFF'
      })
      .onClick(action)
  }

  @Builder
  focusHeroCard() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text('\u591A\u6A21\u5F0F\u4E13\u6CE8')
        .fontSize($r('sys.float.ohos_id_text_size_headline7'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Text('\u756A\u8304\u949F\u3001\u77ED\u4E13\u6CE8\u3001\u957F\u4E13\u6CE8\uFF0C\u966A\u4F60\u8FDB\u5165\u72B6\u6001')
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(UI_COLORS.BLUE_LIGHT)
    .shadow({
      radius: 12,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 5
    })
  }

  @Builder
  focusModeSelector() {
    Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
      ForEach(this.focusMinuteValues, (minuteValue: number) => {
        this.focusModePill(minuteValue)
      }, (minuteValue: number) => `${minuteValue}`)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.ICON_GUTTER)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
    .backgroundColor(Color.White)
  }

  @Builder
  focusModePill(minuteValue: number) {
    Text(`${minuteValue}\u5206\u949F`)
      .fontSize($r('sys.float.ohos_id_text_size_body2'))
      .fontColor(this.selectedFocusMinutes === minuteValue ? Color.White : UI_COLORS.FOCUS_BLUE)
      .textAlign(TextAlign.Center)
      .padding({
        top: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
        bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2
      })
      .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
      .backgroundColor(this.selectedFocusMinutes === minuteValue ? UI_COLORS.FOCUS_BLUE : UI_COLORS.BLUE_LIGHT)
      .layoutWeight(1)
      .onClick(() => {
        this.selectedFocusMinutes = minuteValue;
      })
  }

  @Builder
  focusTodayDataCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.sectionTitle('\u4ECA\u65E5\u4E13\u6CE8\u6570\u636E')
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.overviewMetricCard('\u756A', '\u4ECA\u65E5\u756A\u8304', `${this.todayPomodoroCount}`, UI_COLORS.ORANGE, UI_COLORS.CREAM_WHITE)
        this.overviewMetricCard('\u65F6', '\u4ECA\u65E5\u4E13\u6CE8', `${this.todayFocusMinutes}\u5206`, UI_COLORS.FOCUS_BLUE, UI_COLORS.BLUE_LIGHT)
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.overviewMetricCard('\u6B21', '\u672C\u4EFB\u52A1\u6B21\u6570', `${this.getCurrentFocusCount()}`, UI_COLORS.MINT, UI_COLORS.MINT_LIGHT)
        this.overviewMetricCard('\u5206', '\u672C\u4EFB\u52A1\u5206\u949F', `${this.getCurrentFocusMinutes()}`, UI_COLORS.PET_PURPLE, UI_COLORS.PINK_LIGHT)
      }
      .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
  }

  @Builder
  focusEncourageCard() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text('\u5148\u4E13\u6CE8 5 \u5206\u949F\uFF0C\u72B6\u6001\u4F1A\u6162\u6162\u56DE\u6765\u3002')
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .width(Constant.PERCENT_FULL)
      Text('\u5B8C\u6210\u4E00\u4E2A\u756A\u8304\uFF0C\u5C31\u662F\u4ECA\u5929\u7684\u5C0F\u80DC\u5229\u3002')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(UI_COLORS.MINT_LIGHT)
  }

  getCurrentFocusCount(): number {
    let matchedItems = this.getAllTodos().filter((item: ToDo) => item.key === this.focusTaskKey);
    if (matchedItems.length === 0) {
      return 0;
    }
    return matchedItems[0].focusCount;
  }

  getCurrentFocusMinutes(): number {
    let matchedItems = this.getAllTodos().filter((item: ToDo) => item.key === this.focusTaskKey);
    if (matchedItems.length === 0) {
      return 0;
    }
    return matchedItems[0].focusDurationMinutes;
  }

  @Builder
  quickFocusTasks() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.sectionTitle('\u9009\u62E9\u4E13\u6CE8\u4EFB\u52A1')
      if (this.getAllTodos().filter((item: ToDo) => !item.isCompleted).length === 0) {
        Text('\u6682\u65E0\u53EF\u4E13\u6CE8\u7684\u4EFB\u52A1\uFF0C\u5148\u6DFB\u52A0\u4E00\u4E2A\u5C0F\u76EE\u6807\u5427')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.TEXT_SECONDARY)
          .width(Constant.PERCENT_FULL)
      }
      ForEach(this.getAllTodos().filter((item: ToDo) => !item.isCompleted).slice(0, 4), (item: ToDo) => {
        Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
          Text('\u7B7E')
            .fontSize(18)
          Text(item.name)
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor(UI_COLORS.TEXT_PRIMARY)
            .layoutWeight(1)
            .maxLines(1)
          Text(`${this.selectedFocusMinutes}\u5206\u949F`)
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(UI_COLORS.TEXT_SECONDARY)
          Text('\u5F00\u59CB\u6C89\u6D78\u4E13\u6CE8')
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(Color.White)
            .padding({
              left: STYLE_CONFIG.LIST_ITEM_GUTTER,
              right: STYLE_CONFIG.LIST_ITEM_GUTTER,
              top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
              bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
            })
            .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
            .backgroundColor(UI_COLORS.FOCUS_BLUE)
            .onClick(() => {
              this.startFocus(item, this.selectedFocusMinutes);
            })
        }
        .width(Constant.PERCENT_FULL)
        .padding({
          left: STYLE_CONFIG.LIST_ITEM_GUTTER,
          right: STYLE_CONFIG.LIST_ITEM_GUTTER,
          top: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
          bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2
        })
        .borderRadius(STYLE_CONFIG.UI_RADIUS_MEDIUM)
        .backgroundColor(UI_COLORS.BLUE_LIGHT)
      }, (item: ToDo) => item.key)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
    .shadow({
      radius: 10,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 4
    })
  }

  @Builder
  statisticsPage() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.statisticsHeroCard()
      this.todayStudySummaryCard()
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.overviewMetricCard('\uD83D\uDCDD', '\u4EFB\u52A1\u603B\u6570', `${this.getTotalCount()}`, UI_COLORS.FOCUS_BLUE, UI_COLORS.BLUE_LIGHT)
        this.overviewMetricCard('\u2705', '\u5DF2\u5B8C\u6210', `${this.getCompletedCount()}`, UI_COLORS.MINT, UI_COLORS.MINT_LIGHT)
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.overviewMetricCard('\uD83C\uDF31', '\u672A\u5B8C\u6210', `${this.getUncompletedCount()}`, UI_COLORS.ORANGE, UI_COLORS.CREAM_WHITE)
        this.overviewMetricCard('\uD83D\uDCCA', '\u5B8C\u6210\u7387', `${this.getCompletionRate()}%`, UI_COLORS.PET_PURPLE, UI_COLORS.PINK_LIGHT)
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.overviewMetricCard('\uD83C\uDF45', '\u4ECA\u65E5\u756A\u8304', `${this.todayPomodoroCount}`, UI_COLORS.ORANGE, UI_COLORS.PINK_LIGHT)
        this.overviewMetricCard('\u23F1', '\u4ECA\u65E5\u4E13\u6CE8', `${this.todayFocusMinutes}\u5206`, UI_COLORS.FOCUS_BLUE, UI_COLORS.BLUE_LIGHT)
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.overviewMetricCard('\uD83C\uDF1F', '\u5F53\u524D\u79EF\u5206', `${this.score}`, UI_COLORS.ORANGE, UI_COLORS.CREAM_WHITE)
        this.overviewMetricCard('\uD83D\uDC3E', '\u5BA0\u7269\u6210\u957F', `${this.petExp}`, UI_COLORS.PET_PURPLE, UI_COLORS.PINK_LIGHT)
      }
      .width(Constant.PERCENT_FULL)
      this.progressCard('\u4EFB\u52A1\u5B8C\u6210\u7387', this.getCompletionRate(), `${this.getCompletedCount()} / ${this.getTotalCount()}`)
      this.progressCard('\u81EA\u5F8B\u76EE\u6807\u8FBE\u6210\u7387', this.getDailyGoalCompletionRate(), `${this.getActiveDailyGoalIndexes().length}\u9879\u76EE\u6807`)
      this.progressCard('\u5BA0\u7269\u6210\u957F\u8FDB\u5EA6', this.getPetProgress(), `Lv.${this.getPetLevel()} ${this.getPetName()}`)
      this.focusAnalysisCard()
      this.achievementBadgeCard()
    }
    .width(Constant.PERCENT_FULL)
  }

  @Builder
  statisticsHeroCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('\uD83D\uDCCA \u6570\u636E\u7EDF\u8BA1')
        .fontSize($r('sys.float.ohos_id_text_size_headline7'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Text('\u770B\u89C1\u6BCF\u5929\u7684\u52AA\u529B\u548C\u6210\u957F')
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        this.bannerPill(`\u2705 ${this.todayCompletedCount}\u5B8C\u6210`, UI_COLORS.MINT, UI_COLORS.MINT_LIGHT)
        this.bannerPill(`\u23F1 ${this.todayFocusMinutes}\u5206`, UI_COLORS.FOCUS_BLUE, UI_COLORS.BLUE_LIGHT)
        this.bannerPill(`\uD83C\uDF1F ${this.score}\u79EF\u5206`, UI_COLORS.ORANGE, UI_COLORS.CREAM_WHITE)
      }
      .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(UI_COLORS.BLUE_LIGHT)
    .shadow({
      radius: 12,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 5
    })
  }

  @Builder
  todayStudySummaryCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('\uD83D\uDCD8 \u4ECA\u65E5\u72B6\u6001\u603B\u7ED3')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.currentOutfitInfo('\u5B66\u4E60\u72B6\u6001', this.getTodayStudyMoodTitle(), UI_COLORS.MINT)
        this.currentOutfitInfo('\u5F53\u524D\u79F0\u53F7', this.getLearningTitle(), UI_COLORS.PET_PURPLE)
      }
      .width(Constant.PERCENT_FULL)
      Text(this.getTodayStudyMoodDesc())
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
      Text(this.getTodayQuote())
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
      Text(`\u63A8\u8350\uFF1A${this.getNextStepSuggestion()}`)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.FOCUS_BLUE)
        .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
    .shadow({
      radius: 10,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 4
    })
  }

  @Builder
  focusAnalysisCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('\uD83C\uDF45 \u4ECA\u65E5\u4E13\u6CE8\u5206\u6790')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.currentOutfitInfo('\u4ECA\u65E5\u756A\u8304', `${this.todayPomodoroCount}`, UI_COLORS.ORANGE)
        this.currentOutfitInfo('\u7D2F\u8BA1\u4E13\u6CE8', `${this.getTotalFocusMinutes()}\u5206`, UI_COLORS.FOCUS_BLUE)
      }
      .width(Constant.PERCENT_FULL)
      Text(this.todayFocusMinutes > 0 ? '\u4ECA\u5929\u5DF2\u7ECF\u8FDB\u5165\u8FC7\u4E13\u6CE8\u72B6\u6001\uFF0C\u7EE7\u7EED\u4FDD\u6301\u8FD9\u4E2A\u8282\u594F\u3002' :
        '\u4ECA\u5929\u8FD8\u6CA1\u6709\u4E13\u6CE8\u8BB0\u5F55\uFF0C\u5148\u4ECE 5 \u5206\u949F\u5F00\u59CB\u5427\u3002')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
  }

  @Builder
  petPage() {
    Scroll() {
      Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.studyBuddySpaceHero()
        this.studyBuddyTodayCard()
        this.studyBuddyGrowthCard()
        this.studyBuddyActionsCard()
        this.outfitStore()
      }
      .width(Constant.PERCENT_FULL)
      .padding({ bottom: STYLE_CONFIG.UI_PAGE_BOTTOM_SPACE })
    }
    .layoutWeight(1)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  studyBuddySpaceHero() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        Text(this.getPetEmoji())
          .fontSize(80)
          .textAlign(TextAlign.Center)
          .width(Constant.PERCENT_FULL)
        Text(this.getStudyBuddyName())
          .fontSize($r('sys.float.ohos_id_text_size_headline7'))
          .fontColor(UI_COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .width(Constant.PERCENT_FULL)
        Row({ space: 8 }) {
          CommonPill({ pillLabel: 'Lv.' + this.getPetLevel(), pillTextColor: Color.White, pillBgColor: UI_COLORS.PET_PURPLE })
          CommonPill({ pillLabel: this.getStudyBuddyMood(), pillTextColor: UI_COLORS.TEXT_PRIMARY, pillBgColor: Color.White })
        }
        .justifyContent(FlexAlign.Center)
        .width(Constant.PERCENT_FULL)
        if (this.equippedOutfitIndex >= 0 && this.ownedOutfits[this.equippedOutfitIndex]) {
          Text('穿着 ' + this.getEquippedOutfitName())
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(UI_COLORS.TEXT_SECONDARY)
            .textAlign(TextAlign.Center)
            .width(Constant.PERCENT_FULL)
        }
      }
      .width(Constant.PERCENT_FULL)
      .padding({ top: STYLE_CONFIG.UI_CARD_PADDING * 2, bottom: STYLE_CONFIG.UI_CARD_PADDING, left: STYLE_CONFIG.UI_CARD_PADDING, right: STYLE_CONFIG.UI_CARD_PADDING })
      .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
      .backgroundColor(UI_COLORS.MINT_LIGHT)
    }
  }

  @Builder
  studyBuddyTodayCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('今日陪伴')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.currentOutfitInfo('专注', this.todayFocusMinutes + '分', UI_COLORS.FOCUS_BLUE)
        this.currentOutfitInfo('任务', this.todayCompletedCount + '', UI_COLORS.MINT)
      }
      .width(Constant.PERCENT_FULL)
      CommonPill({ pillLabel: this.getStudyBuddyCompanionState(), pillTextColor: UI_COLORS.MINT, pillBgColor: UI_COLORS.MINT_LIGHT })
      Text(this.getStudyBuddyMessage())
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
    .shadow({ radius: 10, color: UI_COLORS.CARD_SHADOW, offsetX: 0, offsetY: 4 })
  }

  @Builder
  studyBuddyGrowthCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('成长进度')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.currentOutfitInfo('当前等级', 'Lv.' + this.getPetLevel(), UI_COLORS.PET_PURPLE)
        this.currentOutfitInfo('经验值', this.petExp + '', UI_COLORS.ORANGE)
      }
      .width(Constant.PERCENT_FULL)
      CommonProgressBar({ progressPercent: this.getPetProgress(), progressBarColor: UI_COLORS.PET_PURPLE, progressTrackColor: UI_COLORS.PINK_LIGHT })
      Text(this.getPetExpToNextLevel() === 0 ? '已达到当前最高等级' : '距离下一级还差 ' + this.getPetExpToNextLevel() + ' 经验')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
    .shadow({ radius: 10, color: UI_COLORS.CARD_SHADOW, offsetX: 0, offsetY: 4 })
  }

  @Builder
  studyBuddyActionsCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('互动')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        CommonPill({ pillLabel: '💬 换一句', pillTextColor: Color.White, pillBgColor: UI_COLORS.MINT })
          .onClick(() => { this.showToastMessage(this.getStudyBuddyHealingQuote()); })
        CommonPill({ pillLabel: '🎀 查看装扮', pillTextColor: Color.White, pillBgColor: UI_COLORS.PET_PURPLE })
          .onClick(() => { this.currentTab = 7; })
      }
      .width(Constant.PERCENT_FULL)
      .justifyContent(FlexAlign.Center)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
    .shadow({ radius: 10, color: UI_COLORS.CARD_SHADOW, offsetX: 0, offsetY: 4 })
  }

  @Builder
  petDressBanner() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text('\uD83D\uDC31\u2728\uD83C\uDF80 \u53EF\u7231\u88C5\u626E')
        .fontSize($r('sys.float.ohos_id_text_size_headline7'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Text('\u6C89\u6D78\u5F0F\u81EA\u5F8B\uFF0C\u6253\u9020\u4F60\u7684\u5B66\u4E60\u4F19\u4F34')
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        this.bannerPill(`\uD83C\uDF1F ${this.score}\u79EF\u5206`, UI_COLORS.ORANGE, UI_COLORS.CREAM_WHITE)
        this.bannerPill(`\uD83D\uDCDA Lv.${this.getPetLevel()}`, UI_COLORS.PET_PURPLE, UI_COLORS.PINK_LIGHT)
        this.bannerPill(`\uD83C\uDF92 ${this.getOwnedOutfitCount()}/${this.outfitNames.length}`, UI_COLORS.MINT, UI_COLORS.MINT_LIGHT)
      }
      .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(UI_COLORS.PINK_LIGHT)
    .shadow({
      radius: 12,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 5
    })
  }

  @Builder
  currentOutfitCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('\uD83C\uDF08 \u5F53\u524D\u642D\u914D')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.currentOutfitInfo('\u5DF2\u88C5\u5907', this.getEquippedOutfitName(), UI_COLORS.PET_PURPLE)
        this.currentOutfitInfo('\u5F53\u524D\u4E3B\u9898', this.themeNames[this.themeIndex], this.getThemeColor())
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.currentOutfitInfo('\u5BA0\u7269\u7B49\u7EA7', `Lv.${this.getPetLevel()} ${this.getPetName()}`, UI_COLORS.MINT)
        this.currentOutfitInfo('\u6536\u85CF\u8FDB\u5EA6', `${this.getOwnedOutfitCount()} / ${this.outfitNames.length}`, UI_COLORS.ORANGE)
      }
      .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
    .shadow({
      radius: 10,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 4
    })
  }

  @Builder
  currentOutfitInfo(label: string, value: string, color: ResourceColor) {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text(label)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .maxLines(1)
      Text(value)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(color)
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
    }
    .layoutWeight(1)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_MEDIUM)
    .backgroundColor(UI_COLORS.CREAM_WHITE)
  }

  @Builder
  devicePage() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.deviceHeroCard()
      this.deliveryRecordCard()
      this.realTransferExplainCard()
      this.deviceTestGuideCard()
      this.mockDeliveryNoteCard()
    }
    .width(Constant.PERCENT_FULL)
  }

  @Builder
  deviceHeroCard() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text('\uD83D\uDCF1 \u591A\u8BBE\u5907\u540C\u6B65')
        .fontSize($r('sys.float.ohos_id_text_size_headline7'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Text('\u4EFB\u52A1\u53EF\u4EE5\u5728\u53EF\u4FE1\u8BBE\u5907\u4E4B\u95F4\u771F\u5B9E\u6295\u9001')
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        this.bannerPill(`\uD83D\uDCF6 ${this.discoveredDeviceCount}\u53F0\u8BBE\u5907`, UI_COLORS.FOCUS_BLUE, UI_COLORS.BLUE_LIGHT)
        this.bannerPill(this.lastDeliveryType, UI_COLORS.MINT, UI_COLORS.MINT_LIGHT)
      }
      .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(UI_COLORS.BLUE_LIGHT)
  }

  @Builder
  realTransferExplainCard() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text('\uD83D\uDD04 \u771F\u5B9E\u6295\u9001\u8BF4\u660E')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Text('distributedDeviceManager \u7528\u4E8E\u53D1\u73B0\u53EF\u4FE1\u8BBE\u5907\uFF0CdistributedKVStore \u5199\u5165\u4EFB\u52A1\u540E\u901A\u8FC7 sync \u53D1\u8D77\u540C\u6B65\u3002')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
      Text('transferId \u7528\u4E8E\u63A5\u6536\u53BB\u91CD\uFF1B\u201C\u540C\u6B65\u5DF2\u53D1\u8D77\u201D\u4E0D\u7B49\u4E8E\u76EE\u6807\u8BBE\u5907\u4E00\u5B9A\u5DF2\u6536\u5230\u3002')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
  }

  @Builder
  profilePage() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.profileHeroCard()
      this.studyIdentityCard()
      this.profileInfoCard()
      this.themeStore()
      this.dataManagementCard()
    }
    .width(Constant.PERCENT_FULL)
  }

  @Builder
  profileHeroCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('\uD83C\uDFE1 \u6211\u7684\u5B66\u4E60\u7A7A\u95F4')
        .fontSize($r('sys.float.ohos_id_text_size_headline7'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Text('\u4E3B\u9898\u3001\u79EF\u5206\u3001\u6570\u636E\u90FD\u5728\u8FD9\u91CC')
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        this.bannerPill(`\uD83C\uDF1F ${this.score}\u79EF\u5206`, UI_COLORS.ORANGE, UI_COLORS.CREAM_WHITE)
        this.bannerPill(`\uD83C\uDFA8 ${this.themeNames[this.themeIndex]}`, this.getThemeColor(), this.getThemeLightColor())
        this.bannerPill(`\uD83D\uDC3E Lv.${this.getPetLevel()}`, UI_COLORS.PET_PURPLE, UI_COLORS.PINK_LIGHT)
      }
      .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(UI_COLORS.CREAM_WHITE)
    .shadow({
      radius: 12,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 5
    })
  }

  @Builder
  studyIdentityCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text('\uD83C\uDFC5')
          .fontSize(28)
        Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
          Text('\u5B66\u4E60\u8EAB\u4EFD')
            .fontSize($r('sys.float.ohos_id_text_size_headline8'))
            .fontColor(UI_COLORS.TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
            .width(Constant.PERCENT_FULL)
          Text(`\u5F53\u524D\u79F0\u53F7\uFF1A${this.getLearningTitle()}`)
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor(UI_COLORS.PET_PURPLE)
            .fontWeight(FontWeight.Medium)
            .width(Constant.PERCENT_FULL)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        this.bannerPill(this.getTodayStudyMoodTitle(), UI_COLORS.MINT, UI_COLORS.MINT_LIGHT)
        this.bannerPill(`\uD83C\uDF1F ${this.score}\u79EF\u5206`, UI_COLORS.ORANGE, UI_COLORS.CREAM_WHITE)
        this.bannerPill(`\uD83D\uDC3E Lv.${this.getPetLevel()}`, UI_COLORS.PET_PURPLE, UI_COLORS.PINK_LIGHT)
      }
      .width(Constant.PERCENT_FULL)
      Text(this.getTodayStudyMoodDesc())
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
      Text(this.getTodayQuote())
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
    .shadow({
      radius: 10,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 4
    })
  }

  @Builder
  petMiniCard() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text('\u5B66\u4E60\u642D\u5B50')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        Text(this.getPetEmoji())
          .fontSize(40)
        Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
          Text(`${this.getStudyBuddyName()} · Lv.${this.getPetLevel()}`)
            .fontSize($r('sys.float.ohos_id_text_size_headline8'))
            .fontColor(this.getThemeColor())
          Text(this.getStudyBuddyMood())
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      Row() {
        Row()
          .height(8)
          .width(`${this.getPetProgress()}%`)
          .borderRadius(4)
          .backgroundColor(this.getThemeColor())
      }
      .width(Constant.PERCENT_FULL)
      .height(8)
      .borderRadius(4)
      .backgroundColor(Color.White)
      Text(this.getStudyBuddyMessage())
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(UI_COLORS.MINT_LIGHT)
    .shadow({
      radius: 10,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 4
    })
    .onClick(() => {
      this.currentTab = 5;
    })
  }

  @Builder
  focusMiniCard() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      this.sectionTitle('\u4E13\u6CE8\u72B6\u6001')
      Text(this.focusTaskKey.length > 0 ? this.getFocusTaskName() : '\u6682\u65E0\u8FDB\u884C\u4E2D\u4E13\u6CE8')
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor('#182431')
        .width(Constant.PERCENT_FULL)
      Text(this.focusTaskKey.length > 0 ? this.formatFocusTime() : `\u4ECA\u65E5\u756A\u8304 ${this.todayPomodoroCount}`)
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(this.getThemeColor())
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
    .backgroundColor(Color.White)
  }

  @Builder
  progressCard(title: string, percent: number, detail: string) {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Row() {
        Text(title)
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor('#182431')
          .layoutWeight(1)
        Text(detail)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(this.getThemeColor())
      }
      Row() {
        Row()
          .height(8)
          .width(`${percent}%`)
          .borderRadius(4)
          .backgroundColor(this.getThemeColor())
      }
      .width(Constant.PERCENT_FULL)
      .height(8)
      .borderRadius(4)
      .backgroundColor(this.getThemeLightColor())
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
    .backgroundColor(Color.White)
  }

  getOpenTodosWithDeadline(): ToDo[] {
    return this.getAllTodos()
      .filter((item: ToDo) => !item.isCompleted && item.deadline > 0)
      .sort((firstItem: ToDo, secondItem: ToDo) => firstItem.deadline - secondItem.deadline);
  }

  getUpcomingTodos(): ToDo[] {
    let today = this.getTodayStart();
    return this.getOpenTodosWithDeadline()
      .filter((item: ToDo) => item.deadline >= today)
      .slice(0, 3);
  }

  getOverdueTodos(): ToDo[] {
    let today = this.getTodayStart();
    return this.getOpenTodosWithDeadline().filter((item: ToDo) => item.deadline < today);
  }

  getTodosByDeadlineRange(startOffset: number, endOffset: number): ToDo[] {
    let startTime = this.getDeadlineByOffset(startOffset);
    let endTime = this.getDeadlineByOffset(endOffset);
    return this.getOpenTodosWithDeadline().filter((item: ToDo) => item.deadline >= startTime && item.deadline <= endTime);
  }

  getFutureTodosAfterWeek(): ToDo[] {
    let endOfWeek = this.getDeadlineByOffset(7);
    return this.getOpenTodosWithDeadline().filter((item: ToDo) => item.deadline > endOfWeek);
  }

  @Builder
  countdownCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('\u6700\u8FD1\u622A\u6B62')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      if (this.getUpcomingTodos().length === 0) {
        Text('\u6682\u65E0\u5373\u5C06\u622A\u6B62\u7684\u4EFB\u52A1')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.TEXT_SECONDARY)
          .width(Constant.PERCENT_FULL)
      }
      ForEach(this.getUpcomingTodos(), (item: ToDo) => {
        this.calendarTaskRow(item)
      }, (item: ToDo) => item.key)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
    .shadow({
      radius: 10,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 4
    })
  }

  @Builder
  calendarGroupCard(title: string, items: ToDo[]) {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Row() {
        Text(title)
          .fontSize($r('sys.float.ohos_id_text_size_headline8'))
          .fontColor(UI_COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text(`${items.length}`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.FOCUS_BLUE)
      }
      .width(Constant.PERCENT_FULL)
      if (items.length === 0) {
        Text('\u6682\u65E0\u4EFB\u52A1')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.TEXT_SECONDARY)
          .width(Constant.PERCENT_FULL)
      }
      ForEach(items, (item: ToDo) => {
        this.calendarTaskRow(item)
      }, (item: ToDo) => item.key)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
    .shadow({
      radius: 10,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 4
    })
  }

  @Builder
  calendarTaskRow(item: ToDo) {
    Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text(item.name)
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor(item.isCompleted ? UI_COLORS.TEXT_WEAK : UI_COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
        Text(`${this.getPriorityName(item.priority)} 路 ${this.getDeadlineDateText(item.deadline)}`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.TEXT_SECONDARY)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text(item.isCompleted ? '\u5DF2\u5B8C\u6210' : this.getDeadlineText(item.deadline))
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(item.isCompleted ? UI_COLORS.TEXT_WEAK :
            (this.getDeadlineText(item.deadline).startsWith('\u5DF2\u903E\u671F') ? '#D94838' : UI_COLORS.FOCUS_BLUE))
        Text(this.getPriorityText(item.priority))
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(Color.White)
          .padding({
            left: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
            right: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
            top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
            bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
          })
          .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
          .backgroundColor(item.priority >= 2 ? '#D94838' : (item.priority === 1 ? UI_COLORS.ORANGE : UI_COLORS.MINT))
      }
    }
    .width(Constant.PERCENT_FULL)
    .padding({
      top: STYLE_CONFIG.LIST_ITEM_GUTTER,
      bottom: STYLE_CONFIG.LIST_ITEM_GUTTER,
      left: STYLE_CONFIG.LIST_ITEM_GUTTER,
      right: STYLE_CONFIG.LIST_ITEM_GUTTER
    })
    .borderRadius(STYLE_CONFIG.UI_RADIUS_MEDIUM)
    .backgroundColor(item.isCompleted ? '#FAFAFA' : UI_COLORS.CREAM_WHITE)
    .onClick(() => {
      this.showTodoDetail(item);
    })
  }

  @Builder
  achievementBadgeCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Row() {
        Text('\uD83C\uDFC5 \u6210\u5C31\u5FBD\u7AE0\u5899')
          .fontSize($r('sys.float.ohos_id_text_size_headline8'))
          .fontColor(UI_COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text(`${this.getAchievementCount()} / 7`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.ORANGE)
      }
      .width(Constant.PERCENT_FULL)
      Text('\u628A\u6BCF\u4E00\u6B21\u5C0F\u80DC\u5229\u6536\u8FDB\u5FBD\u7AE0\u5899\u91CC')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
      Flex({ wrap: FlexWrap.Wrap }) {
        this.badgeItem('\uD83C\uDF96\uFE0F', '\u9996\u6B21\u5B8C\u6210', this.getCompletedCount() >= 1)
        this.badgeItem('\u2B50', '\u5341\u9879\u8FBE\u6210', this.getCompletedCount() >= 10)
        this.badgeItem('\uD83C\uDF45', '\u756A\u8304\u65B0\u661F', this.getTotalFocusCount() >= 5)
        this.badgeItem('\uD83D\uDD25', '\u8FDE\u7EED\u81EA\u5F8B', this.dailyGoalStreak >= 3)
        this.badgeItem('\uD83C\uDF80', '\u88C5\u626E\u6536\u85CF', this.getOwnedOutfitCount() >= 3)
        this.badgeItem('\u2728', '\u8DE8\u8BBE\u5907\u5C1D\u8BD5', this.lastRealSentTask !== '\u6682\u65E0' || this.lastRealReceivedTask !== '\u6682\u65E0')
        this.badgeItem('\uD83D\uDCC5', '\u622A\u6B62\u65E5\u89C4\u5212', this.getAllTodos().some((item: ToDo) => item.deadline > 0))
      }
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
    .shadow({
      radius: 10,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 4
    })
  }

  @Builder
  badgeItem(iconText: string, label: string, unlocked: boolean) {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text(iconText)
        .fontSize(26)
      Text(label)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(unlocked ? UI_COLORS.TEXT_PRIMARY : UI_COLORS.TEXT_WEAK)
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
      Text(unlocked ? '\u5DF2\u8FBE\u6210' : '\u5F85\u89E3\u9501')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(unlocked ? UI_COLORS.MINT : UI_COLORS.TEXT_WEAK)
    }
    .width('31%')
    .margin({ right: STYLE_CONFIG.ICON_GUTTER, bottom: STYLE_CONFIG.ICON_GUTTER })
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_MEDIUM)
    .backgroundColor(unlocked ? UI_COLORS.CREAM_WHITE : '#F1F3F5')
    .shadow({
      radius: unlocked ? 8 : 0,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: unlocked ? 3 : 0
    })
  }

  @Builder
  mockDeliveryNoteCard() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text('\uD83E\uDDFE \u6A21\u62DF\u6295\u9001\u8BF4\u660E')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Text('\u6A21\u62DF\u8BB0\u5F55\u53EA\u4FDD\u5B58\u672C\u5730\u6587\u5B57\u8BB0\u5F55\uFF0C\u4E0D\u662F\u771F\u5B9E\u8DE8\u8BBE\u5907\u6295\u9001\u3002')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(UI_COLORS.CREAM_WHITE)
  }

  @Builder
  profileInfoCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('\uD83D\uDCBE \u6570\u636E\u4FDD\u5B58\u72B6\u6001')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      this.deliveryStatusRow('Preferences', '\u672C\u5730\u6301\u4E45\u5316\uFF0CApp \u91CD\u542F\u540E\u53EF\u6062\u590D')
      this.deliveryStatusRow('\u4ECA\u65E5\u72B6\u6001', '\u6309\u65E5\u671F\u81EA\u52A8\u91CD\u7F6E\u756A\u8304/\u76EE\u6807\u8FDB\u5EA6')
      this.deliveryStatusRow('\u6295\u9001\u72B6\u6001', '\u6700\u8FD1\u53D1\u9001/\u63A5\u6536\u8BB0\u5F55\u4F1A\u4FDD\u5B58')
      this.deliveryStatusRow('\u5F53\u524D\u4E3B\u9898', this.themeNames[this.themeIndex])
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
    .shadow({
      radius: 10,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 4
    })
  }

  @Builder
  dataManagementCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('\uD83D\uDEE0 \u6570\u636E\u7BA1\u7406')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      this.deliveryStatusRow('\u672C\u5730\u4FDD\u5B58', '\u6570\u636E\u5DF2\u672C\u5730\u4FDD\u5B58')
      this.deliveryStatusRow('\u4ECA\u65E5\u76EE\u6807\u65E5\u671F', this.dailyGoalDate.length > 0 ? this.dailyGoalDate : this.getTodayString())
      this.deliveryStatusRow('\u5DF2\u62E5\u6709\u88C5\u626E', `${this.getOwnedOutfitCount()} / ${this.outfitNames.length}`)
      this.deliveryStatusRow('\u6295\u9001\u53BB\u91CD\u8BB0\u5F55', `${this.receivedTransferIds.length}`)
      Text('\u91CD\u7F6E\u4ECA\u65E5\u76EE\u6807')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor('#D94838')
        .textAlign(TextAlign.Center)
        .width(Constant.PERCENT_FULL)
        .padding({
          top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
          bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
        })
        .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
        .backgroundColor('#FFF1F0')
        .onClick(() => {
          this.confirmResetTodayGoals();
        })
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
  }

  @Builder
  pageTitle(title: string) {
    Text(title)
      .fontSize($r('sys.float.ohos_id_text_size_headline7'))
      .fontColor('#182431')
      .width(Constant.PERCENT_FULL)
  }

  // Item Swipe left to display the toolbar.
  @Builder
  itemEnd(item: ToDo) {
    Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Image($r('app.media.ic_public_settings_filled')).ImageStyle()
        .onClick(() => {
          this.showPriorityPicker(item);
        })
      Image($r('app.media.ic_public_detail_filled')).ImageStyle()
        .onClick(() => {
          this.showTodoDetail(item);
        })
      Image($r('app.media.ic_public_delete_filled')).ImageStyle()
        .onClick(() => {
          this.confirmDeleteItem(item);
        })
    }
    .padding(STYLE_CONFIG.OPERATION_BUTTON_PADDING)
    .justifyContent(FlexAlign.SpaceEvenly)
  }

  build() {
    Column() {
      if (this.isFocusRoomActive()) {
        Column() {
          this.immersiveFocusClockPage()
        }
        .width(Constant.PERCENT_FULL)
        .height(Constant.PERCENT_FULL)
        .layoutWeight(1)
        .backgroundColor(this.getFocusRoomBackgroundColor())
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      } else {
        Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
          Text($r('app.string.todo'))
            .fontSize($r('sys.float.ohos_id_text_size_headline7'))
            .fontColor(this.getThemeColor())
          Blank()
          Image($r('app.media.ic_public_add_filled'))
            .width(STYLE_CONFIG.MENU_IMAGE_SIZE)
            .aspectRatio(1)
            .onClick(() => {
              this.showAddTodoDialog();
            })
        }
        .height(Constant.PERCENT_12)
        .width(Constant.PERCENT_FULL)
        .padding({
          left: $r('sys.float.ohos_id_max_padding_start'),
          right: $r('sys.float.ohos_id_max_padding_end'),
        })
        .margin({
          left: STYLE_CONFIG.LIST_ITEM_GUTTER,
          right: STYLE_CONFIG.LIST_ITEM_GUTTER,
          top: STYLE_CONFIG.LIST_ITEM_GUTTER
        })
        .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
        .backgroundColor(Color.White)

        if (this.isWideScreen) {
          Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
            this.sideNavigation()
            Column() {
              this.pageContainer()
            }
            .layoutWeight(1)
            .height(Constant.PERCENT_FULL)
          }
          .layoutWeight(1)
          .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
        } else {
          Column() {
            Column() {
              this.pageContainer()
            }
            .layoutWeight(1)
            .width(Constant.PERCENT_FULL)
            this.bottomNavigation()
          }
          .layoutWeight(1)
          .padding({
            top: STYLE_CONFIG.LIST_ITEM_GUTTER,
            left: STYLE_CONFIG.UI_NAV_SIDE_MARGIN,
            right: STYLE_CONFIG.UI_NAV_SIDE_MARGIN,
            bottom: STYLE_CONFIG.UI_NAV_BOTTOM_MARGIN
          })
        }
      }
    }
    .backgroundColor(this.isFocusRoomActive() ? this.getFocusRoomBackgroundColor() : $r('app.color.background_color'))
    .height(Constant.PERCENT_FULL)
    .width(Constant.PERCENT_FULL)
    .expandSafeArea([SafeAreaType.SYSTEM], this.isFocusRoomActive() ? [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM] : [SafeAreaEdge.BOTTOM])
    .onAreaChange((oldValue: Area, newValue: Area) => {
      this.isWideScreen = Number(newValue.width) >= 720;
    })
  }

  @Builder
  sideNavigation() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      ForEach(this.visibleTabIndexes, (tabIndex: number) => {
        this.navButton(this.tabNames[tabIndex], tabIndex, true)
      }, (tabIndex: number) => `${tabIndex}`)
    }
    .width(132)
    .height(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
    .backgroundColor(Color.White)
  }

  @Builder
  bottomNavigation() {
    if (!this.isFocusRoomActive()) {
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        ForEach(this.visibleTabIndexes, (tabIndex: number) => {
          this.navButton(this.tabNames[tabIndex], tabIndex, false)
        }, (tabIndex: number) => `${tabIndex}`)
      }
      .width(Constant.PERCENT_FULL)
      .padding({
        left: STYLE_CONFIG.UI_NAV_PADDING,
        right: STYLE_CONFIG.UI_NAV_PADDING,
        top: STYLE_CONFIG.UI_NAV_PADDING,
        bottom: STYLE_CONFIG.UI_NAV_PADDING
      })
      .margin({
        top: STYLE_CONFIG.ICON_GUTTER,
        bottom: STYLE_CONFIG.ICON_GUTTER
      })
      .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
      .backgroundColor('#EFFFFFFF')
      .border({
        width: 1,
        color: '#66FFFFFF'
      })
      .shadow({
        radius: 22,
        color: '#18000000',
        offsetX: 0,
        offsetY: 8
      })
    }
  }

  @Builder
  navButton(label: string, index: number, isSide: boolean) {
    if (isSide) {
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text(this.getTabIcon(index))
          .fontSize(16)
        Text(label)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(this.currentTab === index ? Color.White : this.getThemeColor())
          .textAlign(TextAlign.Center)
          .maxLines(1)
      }
        .justifyContent(FlexAlign.Center)
        .padding({
          left: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
          right: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
          top: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
          bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2
        })
        .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
        .backgroundColor(this.currentTab === index ? this.getThemeColor() : this.getThemeLightColor())
        .width(Constant.PERCENT_FULL)
        .onClick(() => {
          this.currentTab = index;
        })
    } else {
      Row({ space: this.currentTab === index ? STYLE_CONFIG.ICON_GUTTER : 0 }) {
        Text(this.getTabIcon(index))
          .fontSize(this.currentTab === index ? 18 : 17)
        if (this.currentTab === index) {
          Text(label)
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
        }
      }
        .justifyContent(FlexAlign.Center)
        .padding({
          left: this.currentTab === index ? STYLE_CONFIG.LIST_ITEM_GUTTER : STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
          right: this.currentTab === index ? STYLE_CONFIG.LIST_ITEM_GUTTER : STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
          top: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
          bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2
        })
        .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
        .backgroundColor(this.currentTab === index ? this.getThemeColor() : '#00FFFFFF')
        .opacity(this.currentTab === index ? 1 : 0.82)
        .height(this.currentTab === index ? 46 : 40)
        .width(this.currentTab === index ? 86 : 34)
        .onClick(() => {
          this.currentTab = index;
        })
    }
  }
}
