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
import { STYLE_CONFIG, Constant } from '../common/Constants';
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
  toDoData?: StoredToDo[];
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

  private focusTimer: number = -1;
  private appPreferences: preferences.Preferences | null = null;
  private taskTransferService: TaskTransferService = new TaskTransferService();
  private realDeliveryDevices: TransferDevice[] = [];
  private hasInitializedTransfer: boolean = false;
  private todayPomodoroDate: string = '';
  private dailyGoalDate: string = '';
  private dailyGoalStreakDate: string = '';
  private themeNames: string[] = ['\u84DD\u8272', '\u7EFF\u8272', '\u7D2B\u8272', '\u6A59\u8272',
    '\u6A31\u82B1\u7C89', '\u661F\u7A7A\u9ED1'];
  private themeColors: string[] = ['#0A59F7', '#1E8E3E', '#7E3FF2', '#F57C00', '#E85D9E', '#222831'];
  private themeLightColors: string[] = ['#EAF1FF', '#EAF7EE', '#F1EAFF', '#FFF3E0', '#FFF0F6', '#ECEFF3'];
  private themePrices: number[] = [0, 0, 50, 80, 120, 200];
  private deliveryDevices: string[] = ['\u624B\u673A', '\u5E73\u677F', '\u667A\u6167\u5C4F', '\u7535\u8111'];
  private sortNames: string[] = ['\u521B\u5EFA\u65F6\u95F4', '\u540D\u79F0', '\u5B8C\u6210\u72B6\u6001', '\u4F18\u5148\u7EA7'];
  private tabNames: string[] = ['\u9996\u9875', '\u4EFB\u52A1', '\u65E5\u5386', '\u4E13\u6CE8', '\u7EDF\u8BA1', '\u5BA0\u7269', '\u8DE8\u8BBE\u5907', '\u6211\u7684'];
  private priorityNames: string[] = ['\u4F4E', '\u4E2D', '\u9AD8'];
  private deadlineNames: string[] = ['\u65E0\u622A\u6B62\u65E5\u671F', '\u4ECA\u5929', '\u660E\u5929', '3\u5929\u540E', '\u4E00\u5468\u540E'];
  private deadlineOffsets: number[] = [-1, 0, 1, 3, 7];
  private focusMinuteNames: string[] = ['5\u5206\u949F', '15\u5206\u949F', '25\u5206\u949F'];
  private focusMinuteValues: number[] = [5, 15, 25];
  private dailyGoalTypeNames: string[] = ['\u4EFB\u52A1\u5B8C\u6210', '\u756A\u8304\u5B8C\u6210',
    '\u4E13\u6CE8\u5206\u949F', '\u9605\u8BFB\u5206\u949F'];
  private dailyGoalTargetOptions: number[] = [1, 2, 3, 5, 10, 15, 20, 30, 45, 60];
  private dailyGoalTargetNames: string[] = ['1', '2', '3', '5', '10', '15', '20', '30', '45', '60'];
  private outfitNames: string[] = ['\uD83C\uDF92 \u5B66\u4E60\u80CC\u5305', '\uD83D\uDC51 \u81EA\u5F8B\u738B\u51A0',
    '\uD83E\uDDE3 \u4E13\u6CE8\u56F4\u5DFE', '\uD83C\uDF1F \u661F\u5149\u80CC\u666F',
    '\uD83D\uDCDA \u4E66\u672C\u4F19\u4F34', '\uD83C\uDFC5 \u4E13\u6CE8\u5956\u7AE0'];
  private outfitPrices: number[] = [30, 80, 60, 100, 50, 120];

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
      this.toDoData = storedTodos.map((item: StoredToDo) => this.restoreTodo(item));
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

  getThemeColor(): string {
    return this.themeColors[this.themeIndex];
  }

  getThemeLightColor(): string {
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

  showTodoNamePicker(priority: number) {
    this.getUIContext().showTextPickerDialog({
      range: this.getUIContext().getHostContext()?.resourceManager.getStringArrayValueSync($r('app.strarray.available_things').id),
      onAccept: (value: TextPickerResult) => {
        let availableThings = this.getUIContext().getHostContext()?.resourceManager
          .getStringArrayValueSync($r('app.strarray.available_things').id);
        if (availableThings) {
          this.showDeadlinePickerForNewTodo(availableThings[Number(value.index)], priority);
        }
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
    this.clearFocusTimer();
    this.focusTaskKey = item.key;
    this.focusTotalSeconds = minutes * 60;
    this.focusRemainingSeconds = this.focusTotalSeconds;
    this.isFocusRunning = true;
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
        this.completeFocus();
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
    this.isFocusRunning = !this.isFocusRunning;
    this.showToastMessage(this.isFocusRunning ? '\u4E13\u6CE8\u5DF2\u7EE7\u7EED' : '\u4E13\u6CE8\u5DF2\u6682\u505C');
  }

  cancelFocus() {
    this.clearFocusTimer();
    this.focusTaskKey = '';
    this.focusRemainingSeconds = 0;
    this.focusTotalSeconds = 0;
    this.isFocusRunning = false;
    this.showToastMessage('\u5DF2\u53D6\u6D88\u672C\u8F6E\u4E13\u6CE8');
  }

  completeFocus() {
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
    this.showToastMessage(hasFocusTask ? '\u4E13\u6CE8\u5B8C\u6210\uFF0C\u79EF\u5206 +15' : '\u4E13\u6CE8\u5DF2\u7ED3\u675F');
    if (hasFocusTask) {
      this.grantAchievedDailyGoals();
      this.saveAppState();
    }
  }

  getFocusTaskName(): string {
    let matchedItems = this.getAllTodos().filter((item: ToDo) => item.key === this.focusTaskKey);
    if (matchedItems.length === 0) {
      return '\u672A\u9009\u62E9\u4EFB\u52A1';
    }
    return matchedItems[0].name;
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
    return Math.round((this.focusTotalSeconds - this.focusRemainingSeconds) * 100 / this.focusTotalSeconds);
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
      this.sectionTitle('\u4E3B\u9898\u5546\u5E97')
      Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(this.themeNames, (themeName: string, index: number) => {
        Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
          Text(themeName)
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor(this.themeIndex === index ? Color.White : this.themeColors[index])
          Text(this.unlockedThemes[index] ? (this.themeIndex === index ? '\u4F7F\u7528\u4E2D' : '\u5DF2\u89E3\u9501') :
            `${this.themePrices[index]}\u79EF\u5206`)
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(this.themeIndex === index ? Color.White : $r('sys.color.ohos_id_color_text_secondary'))
        }
        .width('31%')
        .margin({
          right: STYLE_CONFIG.ICON_GUTTER,
          bottom: STYLE_CONFIG.ICON_GUTTER
        })
        .padding(STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2)
        .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
        .backgroundColor(this.themeIndex === index ? this.themeColors[index] : this.themeLightColors[index])
        .onClick(() => {
          this.handleThemeTap(index);
        })
      }, (themeName: string) => themeName)
      }
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
    .backgroundColor(Color.White)
  }

  @Builder
  dailyGoalCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Row() {
        this.sectionTitle('\u81EA\u5F8B\u76EE\u6807')
        Text(`\u8FDE\u7EED ${this.dailyGoalStreak} \u5929`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(this.getThemeColor())
      }
      .width(Constant.PERCENT_FULL)
      if (!this.hasVisibleDailyGoals()) {
        Text('\u76EE\u6807\u5DF2\u5168\u90E8\u5220\u9664\uFF0C\u53EF\u968F\u65F6\u6062\u590D\u9ED8\u8BA4\u76EE\u6807')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .width(Constant.PERCENT_FULL)
      }
      ForEach(this.getActiveDailyGoalIndexes(), (goalIndex: number) => {
        this.dailyGoalItem(this.dailyGoalNames[goalIndex], goalIndex)
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
        .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
        .backgroundColor(this.getThemeColor())
        .onClick(() => {
          if (this.isAddingGoal) {
            this.isAddingGoal = false;
          } else {
            this.showAddGoalEditor();
          }
        })
      Text('\u65B0\u589E\u76EE\u6807\u4F7F\u7528\u5361\u7247\u5F0F\u8F93\u5165\uFF1A\u586B\u540D\u79F0\u3001\u9009\u7C7B\u578B\u548C\u6570\u91CF\u540E\u786E\u8BA4\u3002')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .width(Constant.PERCENT_FULL)
      Text('\u6062\u590D\u9ED8\u8BA4\u76EE\u6807')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(this.getThemeColor())
        .textAlign(TextAlign.Center)
        .width(Constant.PERCENT_FULL)
        .padding({
          top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
          bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
        })
        .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
        .backgroundColor(this.getThemeLightColor())
        .onClick(() => {
          this.restoreDefaultDailyGoals();
        })
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
    .backgroundColor(Color.White)
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
        this.getDailyGoalPercent(index), `${this.dailyGoalTypeNames[this.normalizeGoalType(this.dailyGoalTypes[index])]} · ${this.isDailyGoalAchieved(index) ? '\u5DF2\u8FBE\u6210' : '\u672A\u8FBE\u6210'}`)
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
        this.sectionTitle('\u5BA0\u7269\u88C5\u626E\u5546\u5E97')
        Text(`\u79EF\u5206 ${this.score}`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(this.getThemeColor())
      }
      .width(Constant.PERCENT_FULL)
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.outfitNames, (outfitName: string, index: number) => {
          Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
            Text(outfitName)
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontColor(this.equippedOutfitIndex === index ? Color.White : '#182431')
              .maxLines(1)
            Text(this.ownedOutfits[index] ? (this.equippedOutfitIndex === index ? '\u88C5\u5907\u4E2D' : '\u5DF2\u62E5\u6709') :
              `${this.outfitPrices[index]}\u79EF\u5206`)
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontColor(this.equippedOutfitIndex === index ? Color.White : $r('sys.color.ohos_id_color_text_secondary'))
          }
          .width('48%')
          .margin({ right: STYLE_CONFIG.ICON_GUTTER, bottom: STYLE_CONFIG.ICON_GUTTER })
          .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
          .backgroundColor(this.equippedOutfitIndex === index ? this.getThemeColor() : this.getThemeLightColor())
          .onClick(() => {
            this.handleOutfitTap(index);
          })
        }, (outfitName: string) => outfitName)
      }
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
    .backgroundColor(Color.White)
  }

  @Builder
  petCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.sectionTitle('\u5BA0\u7269\u6210\u957F')
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        Text(this.getPetEmoji())
          .fontSize(52)
        Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
          Text(`Lv.${this.getPetLevel()} ${this.getPetName()}`)
            .fontSize($r('sys.float.ohos_id_text_size_headline8'))
            .fontColor(this.getThemeColor())
          Text(this.getPetStatusText())
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .maxLines(2)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
          Text(`${this.score}`)
            .fontSize($r('sys.float.ohos_id_text_size_headline8'))
            .fontColor(this.getThemeColor())
          Text('\u5F53\u524D\u79EF\u5206')
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
          Text(`${this.petExp}`)
            .fontSize($r('sys.float.ohos_id_text_size_headline8'))
            .fontColor(this.getThemeColor())
          Text('\u5BA0\u7269\u6210\u957F\u503C')
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width(Constant.PERCENT_FULL)
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
      Row() {
        Text(this.getPetExpToNextLevel() === 0 ? '\u5DF2\u8FBE\u5230\u5F53\u524D\u6700\u9AD8\u7B49\u7EA7' :
          `\u8DDD\u79BB\u4E0B\u4E00\u7EA7\u8FD8\u5DEE ${this.getPetExpToNextLevel()}\u6210\u957F\u503C`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .layoutWeight(1)
        Text(`${this.getPetProgress()}%`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(this.getThemeColor())
      }
      .width(Constant.PERCENT_FULL)
      Text(`\u4E13\u6CE8 ${this.getTotalFocusCount()}\u6B21 / ${this.getTotalFocusMinutes()}\u5206\u949F`)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .width(Constant.PERCENT_FULL)
      this.deliveryStatusRow('\u5F53\u524D\u88C5\u626E', this.getEquippedOutfitName())
      this.deliveryStatusRow('\u5DF2\u62E5\u6709\u88C5\u626E', `${this.getOwnedOutfitCount()} / ${this.outfitNames.length}`)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
    .backgroundColor(this.getThemeLightColor())
  }

  @Builder
  focusCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.sectionTitle('\u756A\u8304\u4E13\u6CE8')
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
          Text(this.focusTaskKey.length > 0 ? this.getFocusTaskName() : '\u4ECE\u4EFB\u52A1\u5361\u70B9\u51FB\u4E13\u6CE8\u5F00\u59CB')
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor('#182431')
            .maxLines(1)
          Text(this.focusTaskKey.length > 0 ? (this.isFocusRunning ? '\u4E13\u6CE8\u4E2D' : '\u5DF2\u6682\u505C') :
            '\u53EF\u9009 5 / 15 / 25 \u5206\u949F')
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text(this.focusTaskKey.length > 0 ? this.formatFocusTime() : '25:00')
          .fontSize(28)
          .fontColor(this.getThemeColor())
      }
      Row() {
        Row()
          .height(8)
          .width(`${this.getFocusProgress()}%`)
          .borderRadius(4)
          .backgroundColor(this.getThemeColor())
      }
      .width(Constant.PERCENT_FULL)
      .height(8)
      .borderRadius(4)
      .backgroundColor(this.getThemeLightColor())
      if (this.focusTaskKey.length > 0) {
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
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
            .backgroundColor(this.getThemeColor())
            .onClick(() => {
              this.pauseOrResumeFocus();
            })
          Text('\u53D6\u6D88')
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor('#182431')
            .padding({
              left: STYLE_CONFIG.LIST_ITEM_GUTTER,
              right: STYLE_CONFIG.LIST_ITEM_GUTTER,
              top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
              bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
            })
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
            .backgroundColor('#F1F3F5')
            .onClick(() => {
              this.cancelFocus();
            })
        }
        .width(Constant.PERCENT_FULL)
        .justifyContent(FlexAlign.End)
      }
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
    .backgroundColor(Color.White)
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
      this.sectionTitle('\u8DE8\u8BBE\u5907\u6295\u9001\u72B6\u6001')
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
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
          .backgroundColor(this.lastDeliveryType === '\u6A21\u62DF\u8BB0\u5F55' ? '#8A8A8A' : this.getThemeColor())
        Text(`\u5F53\u524D\u53D1\u73B0\u8BBE\u5907\u6570\uFF1A${this.discoveredDeviceCount}`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .layoutWeight(1)
      }
      .width(Constant.PERCENT_FULL)
      Text(this.realDeliveryStatus)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(this.getThemeColor())
        .width(Constant.PERCENT_FULL)
      this.deliveryStatusRow('\u6743\u9650\u72B6\u6001', '\u771F\u5B9E\u6295\u9001\u524D\u4F1A\u81EA\u52A8\u68C0\u67E5/\u7533\u8BF7')
      this.deliveryStatusRow('\u6700\u8FD1\u53D1\u9001\u4EFB\u52A1', this.lastRealSentTask)
      this.deliveryStatusRow('\u6700\u8FD1\u63A5\u6536\u4EFB\u52A1', this.lastRealReceivedTask)
      this.deliveryStatusRow('\u6700\u8FD1\u8BB0\u5F55', this.lastDeliveryRecord)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
    .backgroundColor(Color.White)
  }

  @Builder
  deliveryStatusRow(label: string, value: string) {
    Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text(label)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .width(116)
      Text(value)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor('#182431')
        .layoutWeight(1)
        .maxLines(2)
    }
    .width(Constant.PERCENT_FULL)
  }

  @Builder
  deviceTestGuideCard() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      this.sectionTitle('\u771F\u673A\u6295\u9001\u6D4B\u8BD5\u6307\u5F15')
      Text('1\uFF09\u4E24\u53F0\u8BBE\u5907\u5F00\u542F\u84DD\u7259/Wi-Fi')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor('#182431')
        .width(Constant.PERCENT_FULL)
      Text('2\uFF09\u767B\u5F55\u540C\u4E00\u534E\u4E3A\u8D26\u53F7\u6216\u5EFA\u7ACB\u53EF\u4FE1\u5173\u7CFB')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor('#182431')
        .width(Constant.PERCENT_FULL)
      Text('3\uFF09\u8BBE\u5907B\u5148\u6253\u5F00App')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor('#182431')
        .width(Constant.PERCENT_FULL)
      Text('4\uFF09\u8BBE\u5907A\u9009\u62E9\u4EFB\u52A1\u5E76\u70B9\u51FB\u771F\u5B9E\u6295\u9001')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor('#182431')
        .width(Constant.PERCENT_FULL)
      Text('5\uFF09\u8BBE\u5907B\u6536\u5230\u540E\u4F1A\u52A0\u5165\u5F85\u529E\u5217\u8868')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor('#182431')
        .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
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
          .backgroundColor('#F7F8FA')
          .onChange((value: string) => {
            this.searchKeyword = value;
          })
        Text('\u65B0\u589E')
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor(Color.White)
          .padding({
            left: STYLE_CONFIG.LIST_ITEM_GUTTER,
            right: STYLE_CONFIG.LIST_ITEM_GUTTER,
            top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
            bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
          })
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
          .backgroundColor(this.getThemeColor())
          .onClick(() => {
            this.showAddTodoDialog();
          })
      }

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.sortNames, (sortName: string, index: number) => {
          Text(sortName)
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(this.sortIndex === index ? Color.White : this.getThemeColor())
            .padding({
              left: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 3,
              right: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 3,
              top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
              bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
            })
            .margin({
              right: STYLE_CONFIG.ICON_GUTTER,
              bottom: STYLE_CONFIG.ICON_GUTTER
            })
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
            .backgroundColor(this.sortIndex === index ? this.getThemeColor() : this.getThemeLightColor())
            .onClick(() => {
              this.sortIndex = index;
            })
        }, (sortName: string) => sortName)
      }
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
    .backgroundColor(Color.White)
  }

  @Builder
  taskListPanel() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        Text('\u4EFB\u52A1\u5217\u8868')
          .fontSize($r('sys.float.ohos_id_text_size_headline8'))
          .fontColor('#182431')
          .layoutWeight(1)
        Text(`\u603B\u6570 ${this.getTotalCount()} / \u5DF2\u5B8C\u6210 ${this.getCompletedCount()}`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(this.getThemeColor())
      }
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text('\u4ECA\u5929\u8FD8\u6CA1\u6709\u4EFB\u52A1\uFF0C\u6DFB\u52A0\u4E00\u4E2A\u5C0F\u76EE\u6807\u5427')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .layoutWeight(1)
        Text('\u6E05\u7406\u5DF2\u5B8C\u6210')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(this.getCompletedCount() > 0 ? '#D94838' : $r('sys.color.ohos_id_color_text_secondary'))
          .padding({
            left: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
            right: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
            top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
            bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
          })
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
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
            Text(this.getTotalCount() === 0 ? '\u4ECA\u5929\u8FD8\u6CA1\u6709\u4EFB\u52A1\uFF0C\u6DFB\u52A0\u4E00\u4E2A\u5C0F\u76EE\u6807\u5427' :
              '\u6CA1\u6709\u5339\u914D\u7684\u5F85\u529E')
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .width(Constant.PERCENT_FULL)
              .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
              .backgroundColor(Color.White)
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
  pageContainer() {
    if (this.currentTab === 1) {
      this.taskListPanel()
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
        .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
      }
      .layoutWeight(1)
      .edgeEffect(EdgeEffect.Spring)
    }
  }

  @Builder
  homePage() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.pageTitle('\u4ECA\u65E5\u6982\u89C8')
      this.welcomeCard()
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.overviewMetric('\u4ECA\u65E5\u4EFB\u52A1', `${this.getTotalCount()}`)
        this.overviewMetric('\u4ECA\u65E5\u5B8C\u6210\u7387', `${this.getCompletionRate()}%`)
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.overviewMetric('\u4ECA\u65E5\u756A\u8304', `${this.todayPomodoroCount}`)
        this.overviewMetric('\u5F53\u524D\u79EF\u5206', `${this.score}`)
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.overviewMetric('\u4ECA\u65E5\u4E13\u6CE8', `${this.todayFocusMinutes}\u5206`)
        this.overviewMetric('\u76EE\u6807\u8FBE\u6210\u7387', `${this.getDailyGoalCompletionRate()}%`)
      }
      .width(Constant.PERCENT_FULL)
      this.todayAdviceCard()
      this.checkInCard()
      this.dailyGoalCard()
      this.petMiniCard()
      this.focusMiniCard()
      this.countdownCard()
    }
    .width(Constant.PERCENT_FULL)
  }

  @Builder
  welcomeCard() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text('\u4ECA\u5929\u4E5F\u8981\u9AD8\u6548\u5B8C\u6210\u4EFB\u52A1')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(this.getThemeColor())
        .width(Constant.PERCENT_FULL)
      Text(`\u5F85\u529E ${this.getUncompletedCount()} \u4EF6\uFF0C\u5BA0\u7269 Lv.${this.getPetLevel()} \u6B63\u5728\u966A\u4F60\u5B66\u4E60`)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
    .backgroundColor(Color.White)
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
  calendarPage() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.pageTitle('\u65E5\u5386\u4E0E\u5012\u8BA1\u65F6')
      this.countdownCard()
      this.calendarGroupCard('\u5DF2\u903E\u671F', this.getOverdueTodos())
      this.calendarGroupCard('\u4ECA\u5929', this.getTodosByDeadlineRange(0, 0))
      this.calendarGroupCard('\u660E\u5929', this.getTodosByDeadlineRange(1, 1))
      this.calendarGroupCard('\u672C\u5468', this.getTodosByDeadlineRange(2, 7))
      this.calendarGroupCard('\u4EE5\u540E', this.getFutureTodosAfterWeek())
    }
    .width(Constant.PERCENT_FULL)
  }

  @Builder
  focusPage() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.pageTitle('\u756A\u8304\u4E13\u6CE8')
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.overviewMetric('\u5F53\u524D\u4EFB\u52A1', this.getFocusTaskName())
        this.overviewMetric('\u4ECA\u65E5\u756A\u8304', `${this.todayPomodoroCount}`)
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.overviewMetric('\u672C\u8F6E\u65F6\u957F', this.focusTotalSeconds > 0 ? `${Math.round(this.focusTotalSeconds / 60)}\u5206\u949F` : '25\u5206\u949F')
        this.overviewMetric('\u7D2F\u8BA1\u4E13\u6CE8', `${this.getTotalFocusMinutes()}\u5206\u949F`)
      }
      .width(Constant.PERCENT_FULL)
      this.focusCard()
      if (this.focusTaskKey.length > 0) {
        Text('\u5B8C\u6210\u672C\u8F6E\u4E13\u6CE8')
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor(Color.White)
          .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
          .backgroundColor(this.getThemeColor())
          .onClick(() => {
            this.completeFocus();
          })
      }
      this.quickFocusTasks()
    }
    .width(Constant.PERCENT_FULL)
  }

  @Builder
  quickFocusTasks() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      this.sectionTitle('\u5FEB\u901F\u5F00\u59CB\u4E13\u6CE8')
      ForEach(this.getAllTodos().filter((item: ToDo) => !item.isCompleted).slice(0, 3), (item: ToDo) => {
        Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
          Text(item.name)
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor('#182431')
            .layoutWeight(1)
            .maxLines(1)
          Text('\u5F00\u59CB')
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(Color.White)
            .padding({
              left: STYLE_CONFIG.LIST_ITEM_GUTTER,
              right: STYLE_CONFIG.LIST_ITEM_GUTTER,
              top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
              bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
            })
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
            .backgroundColor(this.getThemeColor())
            .onClick(() => {
              this.showFocusPicker(item);
            })
        }
        .width(Constant.PERCENT_FULL)
      }, (item: ToDo) => item.key)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
    .backgroundColor(Color.White)
  }

  @Builder
  statisticsPage() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.pageTitle('\u7EDF\u8BA1')
      this.statisticsPanel()
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.overviewMetric('\u76EE\u6807\u8FBE\u6210\u7387', `${this.getDailyGoalCompletionRate()}%`)
        this.overviewMetric('\u5F53\u524D\u79EF\u5206', `${this.score}`)
      }
      .width(Constant.PERCENT_FULL)
      this.progressCard('\u4EFB\u52A1\u5B8C\u6210\u7387', this.getCompletionRate(), `${this.getCompletedCount()} / ${this.getTotalCount()}`)
      this.progressCard('\u81EA\u5F8B\u76EE\u6807\u8FBE\u6210\u7387', this.getDailyGoalCompletionRate(), `${this.getActiveDailyGoalIndexes().length}\u9879\u76EE\u6807`)
      this.progressCard('\u5BA0\u7269\u6210\u957F\u8FDB\u5EA6', this.getPetProgress(), `Lv.${this.getPetLevel()} ${this.getPetName()}`)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.overviewMetric('\u4ECA\u65E5\u5B8C\u6210', `${this.todayCompletedCount}`)
        this.overviewMetric('\u4ECA\u65E5\u756A\u8304', `${this.todayPomodoroCount}`)
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.overviewMetric('\u4ECA\u65E5\u4E13\u6CE8', `${this.todayFocusMinutes}\u5206\u949F`)
        this.overviewMetric('\u8FDE\u7EED\u8FBE\u6210', `${this.dailyGoalStreak}\u5929`)
      }
      .width(Constant.PERCENT_FULL)
      this.dailyGoalCard()
      this.progressCard('\u7D2F\u8BA1\u4E13\u6CE8\u65F6\u957F', Math.min(100, Math.round(this.getTotalFocusMinutes() * 100 / 300)),
        `${this.getTotalFocusMinutes()}\u5206\u949F`)
      this.achievementBadgeCard()
    }
    .width(Constant.PERCENT_FULL)
  }

  @Builder
  petPage() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.pageTitle('\u5BA0\u7269')
      this.petCard()
      this.outfitStore()
      this.achievementBadgeCard()
      this.themeStore()
    }
    .width(Constant.PERCENT_FULL)
  }

  @Builder
  devicePage() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.pageTitle('\u8DE8\u8BBE\u5907')
      this.deliveryRecordCard()
      this.deviceTestGuideCard()
      this.mockDeliveryNoteCard()
    }
    .width(Constant.PERCENT_FULL)
  }

  @Builder
  profilePage() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.pageTitle('\u6211\u7684')
      this.profileInfoCard()
      this.dataManagementCard()
      this.featureHighlightsCard()
      this.themeStore()
    }
    .width(Constant.PERCENT_FULL)
  }

  @Builder
  petMiniCard() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        Text(this.getPetEmoji())
          .fontSize(40)
        Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
          Text(`Lv.${this.getPetLevel()} ${this.getPetName()}`)
            .fontSize($r('sys.float.ohos_id_text_size_headline8'))
            .fontColor(this.getThemeColor())
          Text(`\u6210\u957F\u503C ${this.petExp} / \u8DDD\u4E0B\u4E00\u7EA7 ${this.getPetExpToNextLevel()}`)
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
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
    .backgroundColor(this.getThemeLightColor())
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
      this.sectionTitle('\u6700\u8FD1\u622A\u6B62')
      if (this.getUpcomingTodos().length === 0) {
        Text('\u6682\u65E0\u5373\u5C06\u622A\u6B62\u7684\u4EFB\u52A1')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .width(Constant.PERCENT_FULL)
      }
      ForEach(this.getUpcomingTodos(), (item: ToDo) => {
        this.calendarTaskRow(item)
      }, (item: ToDo) => item.key)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
    .backgroundColor(Color.White)
  }

  @Builder
  calendarGroupCard(title: string, items: ToDo[]) {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Row() {
        this.sectionTitle(title)
        Text(`${items.length}`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(this.getThemeColor())
      }
      .width(Constant.PERCENT_FULL)
      if (items.length === 0) {
        Text('\u6682\u65E0\u4EFB\u52A1')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .width(Constant.PERCENT_FULL)
      }
      ForEach(items, (item: ToDo) => {
        this.calendarTaskRow(item)
      }, (item: ToDo) => item.key)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
    .backgroundColor(Color.White)
  }

  @Builder
  calendarTaskRow(item: ToDo) {
    Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text(item.name)
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor('#182431')
          .maxLines(1)
        Text(this.getDeadlineDateText(item.deadline))
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text(this.getDeadlineText(item.deadline))
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(this.getDeadlineText(item.deadline).startsWith('\u5DF2\u903E\u671F') ? '#D94838' : this.getThemeColor())
    }
    .width(Constant.PERCENT_FULL)
    .padding({
      top: STYLE_CONFIG.ICON_GUTTER,
      bottom: STYLE_CONFIG.ICON_GUTTER
    })
    .onClick(() => {
      this.showTodoDetail(item);
    })
  }

  @Builder
  achievementBadgeCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.sectionTitle('\u6210\u5C31\u5FBD\u7AE0')
      Flex({ wrap: FlexWrap.Wrap }) {
        this.badgeItem('\u9996\u6B21\u5B8C\u6210', this.getCompletedCount() >= 1)
        this.badgeItem('\u5341\u9879\u8FBE\u6210', this.getCompletedCount() >= 10)
        this.badgeItem('\u756A\u8304\u65B0\u661F', this.getTotalFocusCount() >= 5)
        this.badgeItem('\u8FDE\u7EED\u81EA\u5F8B', this.dailyGoalStreak >= 3)
        this.badgeItem('\u88C5\u626E\u6536\u85CF', this.getOwnedOutfitCount() >= 3)
        this.badgeItem('\u8DE8\u8BBE\u5907\u5C1D\u8BD5', this.lastRealSentTask !== '\u6682\u65E0' || this.lastRealReceivedTask !== '\u6682\u65E0')
        this.badgeItem('\u622A\u6B62\u65E5\u89C4\u5212', this.getAllTodos().some((item: ToDo) => item.deadline > 0))
      }
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
    .backgroundColor(Color.White)
  }

  @Builder
  badgeItem(label: string, unlocked: boolean) {
    Text(label)
      .fontSize($r('sys.float.ohos_id_text_size_body2'))
      .fontColor(unlocked ? Color.White : $r('sys.color.ohos_id_color_text_secondary'))
      .padding({
        left: STYLE_CONFIG.LIST_ITEM_GUTTER,
        right: STYLE_CONFIG.LIST_ITEM_GUTTER,
        top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
        bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
      })
      .margin({ right: STYLE_CONFIG.ICON_GUTTER, bottom: STYLE_CONFIG.ICON_GUTTER })
      .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
      .backgroundColor(unlocked ? this.getThemeColor() : '#F1F3F5')
  }

  @Builder
  mockDeliveryNoteCard() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      this.sectionTitle('\u6A21\u62DF\u8BB0\u5F55\u8BF4\u660E')
      Text('\u6A21\u62DF\u8BB0\u5F55\u53EA\u4FDD\u5B58\u672C\u5730\u6587\u5B57\u8BB0\u5F55\uFF0C\u4E0D\u662F\u771F\u5B9E\u8DE8\u8BBE\u5907\u6295\u9001\u3002')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
    .backgroundColor(Color.White)
  }

  @Builder
  profileInfoCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.sectionTitle('\u5E94\u7528\u4FE1\u606F')
      this.deliveryStatusRow('\u5F53\u524D\u4E3B\u9898', this.themeNames[this.themeIndex])
      this.deliveryStatusRow('\u5F53\u524D\u79EF\u5206', `${this.score}`)
      this.deliveryStatusRow('\u6570\u636E\u4FDD\u5B58', '\u672C\u5730Preferences\u81EA\u52A8\u4FDD\u5B58')
      this.deliveryStatusRow('App', '\u5F85\u529E\u3001\u756A\u8304\u3001\u5BA0\u7269\u6210\u957F\u4E0E\u8DE8\u8BBE\u5907\u6295\u9001')
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
    .backgroundColor(Color.White)
  }

  @Builder
  dataManagementCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.sectionTitle('\u6570\u636E\u7BA1\u7406')
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
        .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
        .backgroundColor('#FFF1F0')
        .onClick(() => {
          this.confirmResetTodayGoals();
        })
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
    .backgroundColor(Color.White)
  }

  @Builder
  featureHighlightsCard() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      this.sectionTitle('\u4F5C\u4E1A\u4EAE\u70B9')
      Text('List\u5F85\u529E\u7F16\u8F91 / \u672C\u5730\u6301\u4E45\u5316 / \u756A\u8304\u4E13\u6CE8 / \u5BA0\u7269\u6210\u957F')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor('#182431')
        .width(Constant.PERCENT_FULL)
      Text('\u81EA\u5F8B\u76EE\u6807 / \u65E5\u5386\u5012\u8BA1\u65F6 / \u88C5\u626E\u5546\u5E97 / \u771F\u5B9E\u8DE8\u8BBE\u5907\u6295\u9001')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor('#182431')
        .width(Constant.PERCENT_FULL)
      Text(`\u5DF2\u89E3\u9501\u6210\u5C31 ${this.getAchievementCount()} / 7`)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(this.getThemeColor())
        .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
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
          this.pageContainer()
          this.bottomNavigation()
        }
        .layoutWeight(1)
        .padding({
          top: STYLE_CONFIG.LIST_ITEM_GUTTER,
          left: $r('sys.float.ohos_id_default_padding_start'),
          right: $r('sys.float.ohos_id_default_padding_end'),
          bottom: STYLE_CONFIG.LIST_ITEM_GUTTER
        })
      }
    }
    .backgroundColor($r('app.color.background_color'))
    .height(Constant.PERCENT_FULL)
    .width(Constant.PERCENT_FULL)
    .onAreaChange((oldValue: Area, newValue: Area) => {
      this.isWideScreen = Number(newValue.width) >= 720;
    })
  }

  @Builder
  sideNavigation() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      ForEach(this.tabNames, (tabName: string, index: number) => {
        this.navButton(tabName, index, true)
      }, (tabName: string) => tabName)
    }
    .width(132)
    .height(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
    .backgroundColor(Color.White)
  }

  @Builder
  bottomNavigation() {
    Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
      ForEach(this.tabNames, (tabName: string, index: number) => {
        this.navButton(tabName, index, false)
      }, (tabName: string) => tabName)
    }
    .width(Constant.PERCENT_FULL)
    .padding({
      top: STYLE_CONFIG.ICON_GUTTER,
      bottom: STYLE_CONFIG.ICON_GUTTER
    })
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
    .backgroundColor(Color.White)
  }

  @Builder
  navButton(label: string, index: number, isSide: boolean) {
    if (isSide) {
      Text(label)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(this.currentTab === index ? Color.White : this.getThemeColor())
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .padding({
          left: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
          right: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
          top: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
          bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2
        })
        .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
        .backgroundColor(this.currentTab === index ? this.getThemeColor() : this.getThemeLightColor())
        .width(Constant.PERCENT_FULL)
        .onClick(() => {
          this.currentTab = index;
        })
    } else {
      Text(label)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(this.currentTab === index ? Color.White : this.getThemeColor())
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .padding({
          left: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
          right: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
          top: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
          bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2
        })
        .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
        .backgroundColor(this.currentTab === index ? this.getThemeColor() : this.getThemeLightColor())
        .layoutWeight(1)
        .onClick(() => {
          this.currentTab = index;
        })
    }
  }
}
