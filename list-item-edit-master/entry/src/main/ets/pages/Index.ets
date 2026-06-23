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
import { TodoCard } from '../view/TodoCard';
import { AddOrEditTodoForm } from './EditTodoPage';
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
  FocusTransferPayload,
  FreeFlowPayload,
  TransferFocusData,
  TaskTransferPayload,
  TaskTransferService,
  TransferDevice,
  TransferResult,
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
  taskType?: string;
  plannedFocusMinutes?: number;
  cardThemeIndex?: number;
  category?: string;
  repeatType?: string;
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
  selectedStudyRoomIndex?: number;
  lastDeliveryRecord?: string;
  realDeliveryStatus?: string;
  lastRealSentTask?: string;
  lastRealReceivedTask?: string;
  lastDeliveryType?: string;
  discoveredDeviceCount?: number;
  receivedTransferIds?: string[];
  focusThemeIndex?: number;
  focusClockStyleIndex?: number;
}

interface FocusTaskShare {
  name: string;
  minutes: number;
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
  @State selectedStudyRoomIndex: number = 0;
  @State studyBuddyReply: string = '';
  @State themeIndex: number = 0;
  @State hasCheckedToday: boolean = false;
  @State lastCheckInDate: string = '';
  @State todayPomodoroCount: number = 0;
  @State todayCompletedCount: number = 0;
  @State todayFocusMinutes: number = 0;
  @State todayReadingMinutes: number = 0;
  @State todayScoreGain: number = 0;
  @State recentScoreSource: string = '\u6682\u65E0';
  @State achievementRewardClaimed: boolean[] = [false, false, false, false, false];
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
  @State ownedOutfits: boolean[] = [true, false, false, false, false];
  @State equippedOutfitIndex: number = 0;
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
  @State calendarMonthOffset: number = 0;
  @State selectedCalendarDate: number = 0;
  @State editingTodoKey: string = '';
  @State actionMenuTodoKey: string = '';
  @State isAddingTodo: boolean = false;
  @State addingTodoDraft: ToDo = new ToDo('');
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
  @State focusClockStyleIndex: number = 0;
  @State currentFocusQuote: string = '';
  @State isFocusThemePanelVisible: boolean = false;
  @State isFocusNoisePanelVisible: boolean = false;
  @State focusNoiseIndex: number = 0;
  @State focusReturnTab: number = 0;
  @State pendingTransferKind: string = '';
  @State pendingTransferId: string = '';
  @State pendingTransferSource: string = '';
  @State pendingTaskName: string = '';
  @State pendingTaskType: string = 'focus';
  @State pendingTaskPriority: number = 1;
  @State pendingTaskDeadline: number = 0;
  @State pendingTaskCategory: string = '\u9ED8\u8BA4';
  @State pendingTaskRepeatType: string = '\u4E0D\u91CD\u590D';
  @State pendingTaskFocusCount: number = 0;
  @State pendingTaskFocusMinutes: number = 0;
  @State pendingTaskPlannedMinutes: number = 25;
  @State pendingTaskCardThemeIndex: number = -1;
  @State pendingFocusTaskTitle: string = '';
  @State pendingFocusRemainingSeconds: number = 0;
  @State pendingFocusTotalSeconds: number = 0;
  @State pendingFocusIsPaused: boolean = false;
  @State moSceneScale: number = 1;
  @State moSceneRotate: number = 0;
  @State moSceneOffsetY: number = 0;

  private focusTimer: number = -1;
  private moAnimationTimer: number = -1;
  private appPreferences: preferences.Preferences | null = null;
  private taskTransferService: TaskTransferService = new TaskTransferService();
  private focusTaskPieContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
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
  private sampleTransferDevices: string[] = ['\u6F14\u793A\u8BBE\u5907', '\u6F14\u793A\u8BBE\u5907',
    '\u6F14\u793A\u8BBE\u5907', '\u6F14\u793A\u8BBE\u5907'];
  private sortNames: string[] = ['\u521B\u5EFA\u65F6\u95F4', '\u540D\u79F0', '\u5B8C\u6210\u72B6\u6001', '\u4F18\u5148\u7EA7'];
  private tabNames: string[] = ['\u4EE3\u529E', '\u4EFB\u52A1', '\u65E5\u5386', '\u4E13\u6CE8', '\u7EDF\u8BA1', '\u5C0Fmo\u7A7A\u95F4', '\u8DE8\u8BBE\u5907', '\u6211\u7684'];
  private visibleTabIndexes: number[] = [0, 2, 4, 5, 7];
  private priorityNames: string[] = ['\u4F4E', '\u4E2D', '\u9AD8'];
  private deadlineNames: string[] = ['\u65E0\u622A\u6B62\u65E5\u671F', '\u4ECA\u5929', '\u660E\u5929', '3\u5929\u540E', '\u4E00\u5468\u540E'];
  private sampleTaskNames: string[] = ['\u9AD8\u6570\u590D\u4E60', '\u82F1\u8BED\u80CC\u5355\u8BCD', 'HarmonyOS \u9879\u76EE',
    '\u9605\u8BFB', '\u8FD0\u52A8\u6253\u5361'];
  private deadlineOffsets: number[] = [-1, 0, 1, 3, 7];
  private focusMinuteNames: string[] = ['5\u5206\u949F', '15\u5206\u949F', '25\u5206\u949F'];
  private focusMinuteValues: number[] = [5, 15, 25];
  private focusRoomNames: string[] = ['\u68EE\u7EFF', '\u9759\u6D77\u84DD', '\u591C\u7D2B', '\u6696\u91D1', '\u67D4\u7C89'];
  private focusRoomColors: string[] = ['#142B24', '#142A3A', '#241D35', '#352719', '#35222B'];
  private focusRoomLightColors: string[] = ['#5536C98B', '#445FA8D3', '#449A86D8', '#44D9953D', '#44E89AAF'];
  private focusRoomAccentColors: string[] = ['#78B995', '#7DD3FC', '#B8A7E8', '#FFC46B', '#F0A7BA'];
  private focusClockStyleNames: string[] = ['\u5706\u73AF\u65F6\u949F', '\u6781\u7B80\u6570\u5B57', '\u5361\u7247\u65F6\u949F'];
  private focusQuotes: string[] = ['\u5148\u4E13\u6CE8 5 \u5206\u949F\uFF0C\u72B6\u6001\u4F1A\u6162\u6162\u56DE\u6765\u3002',
    '\u4ECA\u5929\u53EA\u8981\u524D\u8FDB\u4E00\u70B9\u70B9\u5C31\u5F88\u597D\u3002',
    '\u628A\u8FD9\u4E00\u5C0F\u6BB5\u65F6\u95F4\u7559\u7ED9\u81EA\u5DF1\u3002',
    '\u5C0Fmo\u966A\u4F60\u4E00\u8D77\u5B8C\u6210\u8FD9\u4E2A\u76EE\u6807\u3002',
    '\u4E0D\u6025\uFF0C\u6162\u6162\u8FDB\u5165\u72B6\u6001\u3002'];
  private focusNoiseNames: string[] = ['\u65E0\u97F3\u4E50', '\u96E8\u58F0', '\u6D77\u6D6A', '\u68EE\u6797'];
  private dailyGoalTypeNames: string[] = ['\u4EFB\u52A1\u5B8C\u6210', '\u756A\u8304\u5B8C\u6210',
    '\u4E13\u6CE8\u5206\u949F', '\u9605\u8BFB\u5206\u949F'];
  private dailyGoalTargetOptions: number[] = [1, 2, 3, 5, 10, 15, 20, 30, 45, 60];
  private dailyGoalTargetNames: string[] = ['1', '2', '3', '5', '10', '15', '20', '30', '45', '60'];
  private outfitNames: string[] = ['\u5976\u6CB9\u56F4\u5DFE', '\u661F\u661F\u5E3D\u5B50',
    '\u68EE\u6797\u4E66\u5305', '\u591C\u8BFB\u773C\u955C', '\u5B66\u9738\u5C0F\u5FBD\u7AE0'];
  private outfitPrices: number[] = [30, 50, 80, 120, 180];
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
    this.startMoSceneAnimation();
  }

  aboutToDisappear() {
    this.clearFocusTimer();
    this.clearMoSceneAnimation();
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
          let restoredTodo = this.restoreTodo(item);
          if (!restoredTodo.isCompleted) {
            restoredTodos.push(restoredTodo);
          }
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
    let updatedOutfits = [true, false, false, false, false];
    if (Array.isArray(storedOutfits)) {
      storedOutfits.forEach((isOwned: boolean, index: number) => {
        if (index < updatedOutfits.length && typeof isOwned === 'boolean') {
          updatedOutfits[index] = index === 0 ? true : isOwned;
        }
      });
    }
    this.ownedOutfits = updatedOutfits;
    let storedOutfitIndex = this.getStoredNumber(storedState.equippedOutfitIndex, this.equippedOutfitIndex);
    if (storedOutfitIndex >= 0 && storedOutfitIndex < this.outfitNames.length && this.ownedOutfits[storedOutfitIndex]) {
      this.equippedOutfitIndex = storedOutfitIndex;
    } else {
      this.equippedOutfitIndex = 0;
    }
    let storedStudyRoomIndex = this.getStoredNumber(storedState.selectedStudyRoomIndex, this.selectedStudyRoomIndex);
    if (storedStudyRoomIndex >= 0 && storedStudyRoomIndex < 4) {
      this.selectedStudyRoomIndex = storedStudyRoomIndex;
    }
    this.lastDeliveryRecord = this.getStoredString(storedState.lastDeliveryRecord, this.lastDeliveryRecord);
    this.realDeliveryStatus = this.getStoredString(storedState.realDeliveryStatus, this.realDeliveryStatus);
    this.lastRealSentTask = this.getStoredString(storedState.lastRealSentTask, this.lastRealSentTask);
    this.lastRealReceivedTask = this.getStoredString(storedState.lastRealReceivedTask, this.lastRealReceivedTask);
    this.lastDeliveryType = this.getStoredString(storedState.lastDeliveryType, this.lastDeliveryType);
    this.discoveredDeviceCount = Math.max(0, this.getStoredNumber(storedState.discoveredDeviceCount,
      this.discoveredDeviceCount));
    let storedFocusThemeIndex = this.getStoredNumber(storedState.focusThemeIndex, this.focusThemeIndex);
    if (storedFocusThemeIndex >= 0 && storedFocusThemeIndex < this.focusRoomNames.length) {
      this.focusThemeIndex = storedFocusThemeIndex;
    }
    let storedFocusClockStyleIndex = this.getStoredNumber(storedState.focusClockStyleIndex, this.focusClockStyleIndex);
    if (storedFocusClockStyleIndex >= 0 && storedFocusClockStyleIndex < this.focusClockStyleNames.length) {
      this.focusClockStyleIndex = storedFocusClockStyleIndex;
    }
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
      Math.max(0, this.getStoredNumber(item.deadline, 0)),
      this.getStoredString(item.category, todoName),
      this.getStoredString(item.repeatType, '\u4E0D\u91CD\u590D'),
      this.getStoredString(item.taskType, 'focus'),
      Math.max(1, this.getStoredNumber(item.plannedFocusMinutes, 25)),
      this.getStoredNumber(item.cardThemeIndex, -1)
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

  getPriorityColor(priority: number): string {
    if (priority >= 2) {
      return STYLE_COLORS.PRIORITY_HIGH;
    }
    if (priority === 1) {
      return STYLE_COLORS.PRIORITY_MIDDLE;
    }
    return STYLE_COLORS.PRIORITY_LOW;
  }

  getPriorityBgColor(priority: number): string {
    if (priority >= 2) {
      return STYLE_COLORS.PRIORITY_HIGH_BG;
    }
    if (priority === 1) {
      return STYLE_COLORS.PRIORITY_MIDDLE_BG;
    }
    return STYLE_COLORS.PRIORITY_LOW_BG;
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
      this.todayScoreGain = 0;
      this.recentScoreSource = '\u6682\u65E0';
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
      if (this.lastCheckInDate !== today) {
        this.hasCheckedToday = true;
        this.lastCheckInDate = today;
        this.addGrowthReward(2, '\u6BCF\u65E5\u6253\u5F00App');
      }
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
      toDoData: this.toDoData
        .filter((item: ToDo) => !item.isCompleted)
        .map((item: ToDo) => this.buildStoredToDo(item)),
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
      selectedStudyRoomIndex: this.selectedStudyRoomIndex,
      lastDeliveryRecord: this.lastDeliveryRecord,
      realDeliveryStatus: this.realDeliveryStatus,
      lastRealSentTask: this.lastRealSentTask,
      lastRealReceivedTask: this.lastRealReceivedTask,
      lastDeliveryType: this.lastDeliveryType,
      discoveredDeviceCount: this.discoveredDeviceCount,
      receivedTransferIds: [...this.receivedTransferIds],
      focusThemeIndex: this.focusThemeIndex,
      focusClockStyleIndex: this.focusClockStyleIndex
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
      deadline: item.deadline,
      taskType: item.taskType,
      plannedFocusMinutes: item.plannedFocusMinutes,
      cardThemeIndex: item.cardThemeIndex,
      category: item.category,
      repeatType: item.repeatType
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
    if (diffDays === 1) {
      return '\u660E\u5929\u622A\u6B62';
    }
    if (diffDays > 0) {
      return `\u8FD8\u6709 ${diffDays} \u5929`;
    }
    return `\u5DF2\u903E\u671F ${Math.abs(diffDays)} \u5929`;
  }

  getDeadlineStatusColor(deadline: number, isCompleted: boolean): string {
    if (isCompleted) {
      return UI_COLORS.TEXT_WEAK;
    }
    let diffDays = Math.round((this.getStartOfDay(deadline) - this.getTodayStart()) / (24 * 60 * 60 * 1000));
    if (diffDays < 0) {
      return STYLE_COLORS.PRIORITY_HIGH;
    }
    if (diffDays === 0) {
      return UI_COLORS.ORANGE;
    }
    return UI_COLORS.FOCUS_BLUE;
  }

  getDeadlineStatusNote(deadline: number): string {
    let deadlineText = this.getDeadlineText(deadline);
    if (deadlineText.startsWith('\u5DF2\u903E\u671F')) {
      return `${deadlineText}\uFF0C\u5C3D\u5FEB\u5904\u7406`;
    }
    if (deadlineText === '\u4ECA\u5929\u622A\u6B62') {
      return '\u4ECA\u5929\u622A\u6B62\uFF0C\u8BB0\u5F97\u5B8C\u6210\u54E6';
    }
    return deadlineText;
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
      return '\u4ECA\u65E5\u76EE\u6807\u8FD8\u6709\u7A7A\u95F4\uFF0C\u5B8C\u6210\u4E00\u9879\u5C31\u80FD\u63A8\u52A8\u5C0Fmo\u6210\u957F\u3002';
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
      return '\u270E';
    }
    if (index === 2) {
      return '\u25F7';
    }
    if (index === 3) {
      return '\u25CC';
    }
    if (index === 4) {
      return '\u2726';
    }
    if (index === 5) {
      return '\u2661';
    }
    if (index === 6) {
      return '\u25C7';
    }
    return '\u25E1';
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

  addGrowthReward(scoreValue: number, reason: string = '') {
    let safeScore = Math.max(0, Math.floor(scoreValue));
    if (safeScore <= 0) {
      return;
    }
    this.score += safeScore;
    this.petExp += safeScore;
    this.todayScoreGain += safeScore;
    if (reason.length > 0) {
      this.recentScoreSource = `${reason} +${safeScore}`;
      this.showToastMessage(`+${safeScore} \u79EF\u5206\uFF08${reason}\uFF09`);
    } else {
      this.recentScoreSource = `\u83B7\u5F97\u79EF\u5206 +${safeScore}`;
    }
  }

  getFocusScoreReward(focusMinutes: number): number {
    if (focusMinutes === 5) {
      return 2;
    }
    if (focusMinutes === 15) {
      return 6;
    }
    if (focusMinutes === 25) {
      return 10;
    }
    return Math.max(1, Math.floor(focusMinutes / 2));
  }

  getTaskScoreReward(item: ToDo | undefined): number {
    if (item !== undefined && item.priority >= 2) {
      return 5;
    }
    if (item !== undefined && item.priority === 1) {
      return 4;
    }
    return 3;
  }

  getTaskScoreReason(item: ToDo | undefined): string {
    if (item !== undefined && item.priority >= 2) {
      return '\u5B8C\u6210\u9AD8\u4F18\u4EFB\u52A1';
    }
    if (item !== undefined && item.priority === 1) {
      return '\u5B8C\u6210\u4E2D\u4F18\u4EFB\u52A1';
    }
    return '\u5B8C\u6210\u666E\u901A\u4EFB\u52A1';
  }

  grantAchievementRewards() {
    let updatedClaims = [...this.achievementRewardClaimed];
    if (!updatedClaims[0] && this.isFirstFocusAchievementUnlocked()) {
      updatedClaims[0] = true;
      this.addGrowthReward(20, '\u8FBE\u6210\u6210\u5C31\uFF1A\u9996\u6B21\u4E13\u6CE8');
    }
    if (!updatedClaims[1] && this.getCompletedCount() >= 10) {
      updatedClaims[1] = true;
      this.addGrowthReward(20, '\u8FBE\u6210\u6210\u5C31\uFF1A\u5B8C\u621010\u4E2A\u4EFB\u52A1');
    }
    if (!updatedClaims[2] && this.getCompletedCount() >= 50) {
      updatedClaims[2] = true;
      this.addGrowthReward(50, '\u8FBE\u6210\u6210\u5C31\uFF1A\u5B8C\u621050\u4E2A\u4EFB\u52A1');
    }
    if (!updatedClaims[3] && this.getTotalFocusMinutes() >= 100) {
      updatedClaims[3] = true;
      this.addGrowthReward(30, '\u8FBE\u6210\u6210\u5C31\uFF1A\u4E13\u6CE8100\u5206\u949F');
    }
    if (!updatedClaims[4] && this.dailyGoalStreak >= 3) {
      updatedClaims[4] = true;
      this.addGrowthReward(50, '\u8FBE\u6210\u6210\u5C31\uFF1A\u8FDE\u7EED\u5B66\u4E603\u5929');
    }
    this.achievementRewardClaimed = updatedClaims;
  }

  getPetName(): string {
    if (this.getPetLevel() >= 8) {
      return '\u5C0Fmo\u5B66\u4E60\u4F19\u4F34';
    }
    if (this.getPetLevel() >= 5) {
      return '\u6210\u957F\u4E2D\u7684\u5C0Fmo';
    }
    if (this.getPetLevel() >= 3) {
      return '\u5C0Fmo\u5E7C\u5D3D';
    }
    if (this.getPetLevel() >= 2 || this.todayFocusMinutes >= 30) {
      return '\u5FEB\u7834\u58F3\u7684\u5C0Fmo';
    }
    return '\u7761\u5728\u86CB\u91CC\u7684\u5C0Fmo';
  }

  getPetEmoji(): string {
    return 'mo';
  }

  getPetLevel(): number {
    if (this.petExp >= 1400) {
      return 8;
    }
    if (this.petExp >= 1000) {
      return 7;
    }
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
    if (this.petExp >= 1400) {
      return 1400;
    }
    if (this.petExp >= 1000) {
      return 1000;
    }
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
    if (this.petExp >= 1400) {
      return 1400;
    }
    if (this.petExp >= 1000) {
      return 1400;
    }
    if (this.petExp >= 700) {
      return 1000;
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
    if (this.getPetLevel() >= 8) {
      return '\u5C0Fmo\u5750\u5728\u4E66\u684C\u65C1\uFF0C\u966A\u4F60\u4E00\u8D77\u5B66\u4E60';
    }
    if (this.getPetLevel() >= 5) {
      return '\u5C0Fmo\u6B63\u5728\u957F\u5927\uFF0C\u88C5\u9970\u4E5F\u53D8\u5F97\u66F4\u4E30\u5BCC';
    }
    if (this.getPetLevel() >= 3) {
      return '\u5C0Fmo\u8BDE\u751F\u5566\uFF0C\u6BCF\u4E2A\u4EFB\u52A1\u90FD\u5728\u5E2E\u5B83\u6210\u957F';
    }
    if (this.getPetLevel() >= 2 || this.todayFocusMinutes >= 30) {
      return '\u86CB\u58F3\u51FA\u73B0\u5C0F\u88C2\u7F1D\uFF0C\u5C0Fmo\u597D\u50CF\u5FEB\u51FA\u6765\u5566';
    }
    return '\u5C0Fmo\u6B63\u5728\u86CB\u91CC\u7761\u89C9';
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
    return this.outfitNames[0];
  }

  getOutfitIcon(index: number): string {
    let icons: string[] = ['A', 'S', 'F', 'H', 'M', 'R'];
    return icons[Math.max(0, index) % icons.length];
  }

  getOutfitDisplayName(index: number): string {
    return this.outfitNames[Math.max(0, index) % this.outfitNames.length];
  }

  getOutfitStyleTag(index: number): string {
    let tags: string[] = ['\u56F4\u5DFE', '\u5E3D\u5B50', '\u4E66\u5305', '\u773C\u955C', '\u5FBD\u7AE0'];
    return tags[Math.max(0, index) % tags.length];
  }

  getOutfitPreviewColor(index: number): string {
    let colors: string[] = ['#F6E6C8', '#A9D6B2', '#B9B7E8', '#F4CBB9', '#BFD6EA'];
    return colors[Math.max(0, index) % colors.length];
  }

  getOutfitScarfColor(index: number): string {
    let colors: string[] = ['#E5B86E', '#7CB894', '#8D84CE', '#EAA679', '#7FA7C7'];
    return colors[Math.max(0, index) % colors.length];
  }

  getOutfitRoomBgColor(index: number): string {
    let colors: string[] = ['#FFF3DF', '#E9F8ED', '#F3EDFF', '#FFF7EA', '#E9F1FA'];
    return colors[Math.max(0, index) % colors.length];
  }

  getOutfitActionText(index: number): string {
    if (this.ownedOutfits[index]) {
      return this.equippedOutfitIndex === index ? '\u4F69\u6234\u4E2D' : '\u4F69\u6234';
    }
    return this.score >= this.outfitPrices[index] ? '\u5151\u6362' : '\u79EF\u5206\u4E0D\u8DB3';
  }

  canRedeemOutfit(index: number): boolean {
    return index >= 0 && index < this.outfitNames.length && !this.ownedOutfits[index] && this.score >= this.outfitPrices[index];
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
    this.addingTodoDraft = new ToDo('', 1, 0, '\u9ED8\u8BA4', '\u4E0D\u91CD\u590D', 'focus', 25, -1);
    this.isAddingTodo = true;
    this.editingTodoKey = '';
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
    if (item.taskType !== 'focus') {
      this.showToastMessage('\u53EA\u6709\u4E13\u6CE8\u4EFB\u52A1\u53EF\u4EE5\u8FDB\u5165\u4E13\u6CE8\u623F');
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
    if (item === undefined || item.isCompleted || item.key.length === 0 || item.taskType !== 'focus') {
      this.showToastMessage('\u8BF7\u9009\u62E9\u4E00\u4E2A\u672A\u5B8C\u6210\u4EFB\u52A1');
      return;
    }
    let safeMinutes = Math.max(1, Math.round(minutes));
    this.focusReturnTab = this.getSafeFocusReturnTab(this.currentTab);
    this.clearFocusTimer();
    this.selectedFocusMinutes = safeMinutes;
    this.focusTaskKey = item.key;
    this.focusTotalSeconds = safeMinutes * 60;
    this.focusRemainingSeconds = this.focusTotalSeconds;
    this.isFocusRunning = true;
    this.isFocusFinished = false;
    this.isFocusImmersiveMode = true;
    this.isFocusRoomVisible = true;
    this.isFocusThemePanelVisible = false;
    this.isFocusNoisePanelVisible = false;
    this.currentFocusQuote = this.getRandomFocusQuote();
    this.currentTab = 3;
    this.startFocusTimer();
    this.showToastMessage('\u756A\u8304\u4E13\u6CE8\u5DF2\u5F00\u59CB');
  }

  getSafeFocusReturnTab(tabIndex: number): number {
    if (tabIndex === 0 || tabIndex === 2 || tabIndex === 4 || tabIndex === 5 || tabIndex === 7) {
      return tabIndex;
    }
    return 0;
  }

  consumeFocusReturnTab(): number {
    this.focusReturnTab = 0;
    return 0;
  }

  getRandomFocusQuote(): string {
    return this.focusQuotes[Math.floor(Math.random() * this.focusQuotes.length)];
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

  startMoSceneAnimation() {
    this.clearMoSceneAnimation();
    this.applyMoSceneLoopFrame();
    this.moAnimationTimer = setInterval(() => {
      this.applyMoSceneLoopFrame();
    }, 1500);
  }

  clearMoSceneAnimation() {
    if (this.moAnimationTimer >= 0) {
      clearInterval(this.moAnimationTimer);
      this.moAnimationTimer = -1;
    }
  }

  applyMoSceneLoopFrame() {
    let stageName = this.getMoStageName();
    if (stageName === '\u86CB') {
      this.moSceneScale = this.moSceneScale > 1 ? 1 : 1.035;
      this.moSceneRotate = 0;
      this.moSceneOffsetY = 0;
      return;
    }
    if (stageName === '\u7834\u58F3') {
      this.moSceneScale = 1.025;
      this.moSceneRotate = this.moSceneRotate >= 0 ? -2 : 2;
      this.moSceneOffsetY = 0;
      return;
    }
    this.moSceneScale = 1;
    this.moSceneRotate = 0;
    this.moSceneOffsetY = this.moSceneOffsetY < 0 ? 0 : -7;
  }

  popMoScene() {
    this.moSceneScale = 1.08;
    setTimeout(() => {
      this.applyMoSceneLoopFrame();
    }, 180);
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
    if (!this.isFocusRoomActive()) {
      this.showToastMessage(this.isFocusRunning ? '\u4E13\u6CE8\u5DF2\u7EE7\u7EED' : '\u4E13\u6CE8\u5DF2\u6682\u505C');
    }
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
    this.isFocusThemePanelVisible = false;
    this.isFocusNoisePanelVisible = false;
    this.currentFocusQuote = '';
    this.currentTab = this.consumeFocusReturnTab();
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
      this.addGrowthReward(this.getFocusScoreReward(focusMinutes), `\u5B8C\u6210${focusMinutes}\u5206\u949F\u4E13\u6CE8`);
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
    this.isFocusThemePanelVisible = false;
    this.isFocusNoisePanelVisible = false;
    this.currentFocusQuote = '';
    this.currentTab = this.consumeFocusReturnTab();
    if (!hasFocusTask) {
      this.showToastMessage('\u4E13\u6CE8\u5DF2\u7ED3\u675F');
    }
    if (hasFocusTask) {
      this.grantAchievedDailyGoals();
      this.grantAchievementRewards();
      this.saveAppState();
    }
  }

  exitFocusRoom() {
    this.isFocusRoomVisible = false;
    this.isFocusImmersiveMode = false;
    this.isFocusThemePanelVisible = false;
    this.isFocusNoisePanelVisible = false;
    this.currentTab = this.consumeFocusReturnTab();
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
    return this.focusRoomColors[safeIndex];
  }

  getFocusRoomLightColor(): string {
    let safeIndex = Math.max(0, this.focusThemeIndex) % this.focusRoomLightColors.length;
    return this.focusRoomLightColors[safeIndex];
  }

  getFocusRoomAccentColor(): string {
    let safeIndex = Math.max(0, this.focusThemeIndex) % this.focusRoomAccentColors.length;
    return this.focusRoomAccentColors[safeIndex];
  }

  getStudyBuddyName(): string {
    if (this.petExp >= 700) {
      return '\u95EA\u5149\u5C0Fmo';
    }
    if (this.petExp >= 400) {
      return '\u8FDB\u9636\u5C0Fmo';
    }
    if (this.petExp >= 200) {
      return '\u4E13\u6CE8\u5C0Fmo';
    }
    if (this.petExp >= 100) {
      return '\u52AA\u529B\u5C0Fmo';
    }
    return '\u65B0\u624B\u5C0Fmo';
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
    if (this.focusTaskKey.length > 0) {
      return '\u4E13\u6CE8';
    }
    if (this.todayFocusMinutes >= 60) {
      return '\u8BA4\u771F';
    }
    if (this.todayPomodoroCount >= 2) {
      return '\u5F00\u5FC3';
    }
    if (this.todayCompletedCount >= 3) {
      return '\u6210\u5C31\u611F';
    }
    if (this.todayEarlyExitCount > 0) {
      return '\u56F0\u5026';
    }
    return '\u8BA4\u771F';
  }

  getStudyBuddyTodayState(): string {
    if (this.todayFocusMinutes >= 60) {
      return '\u5E72\u52B2\u5341\u8DB3';
    }
    if (this.todayFocusMinutes >= 20 || this.todayPomodoroCount > 0) {
      return '\u72B6\u6001\u4E0D\u9519';
    }
    return '\u9700\u8981\u4F11\u606F';
  }

  getMoExpressionState(): string {
    if (this.todayCompletedCount >= 3) {
      return 'achieve';
    }
    if (this.todayEarlyExitCount > 0 && this.todayPomodoroCount === 0) {
      return 'sleepy';
    }
    if (this.focusTaskKey.length > 0) {
      return 'focus';
    }
    if (this.todayFocusMinutes >= 60 || this.focusTaskKey.length > 0) {
      return 'serious';
    }
    if (this.todayPomodoroCount >= 2 || this.todayCompletedCount > 0) {
      return 'happy';
    }
    return 'serious';
  }

  getMoMoodName(): string {
    let expressionState = this.getMoExpressionState();
    if (expressionState === 'achieve') {
      return '\u6210\u5C31\u611F';
    }
    if (expressionState === 'sleepy') {
      return '\u56F0\u5026';
    }
    if (expressionState === 'happy') {
      return '\u5F00\u5FC3';
    }
    return '\u8BA4\u771F';
  }

  getMoMoodColor(): ResourceColor {
    let moodName = this.getMoMoodName();
    if (moodName === '\u6210\u5C31\u611F') {
      return UI_COLORS.ORANGE;
    }
    if (moodName === '\u56F0\u5026') {
      return UI_COLORS.TEXT_WEAK;
    }
    if (moodName === '\u5F00\u5FC3') {
      return UI_COLORS.MINT;
    }
    return UI_COLORS.PET_PURPLE;
  }

  getStudyBuddyMessage(): string {
    if (this.todayFocusMinutes >= 60) {
      return '\u4ECA\u5929\u72B6\u6001\u5F88\u597D\uFF0C\u5C0Fmo\u90FD\u88AB\u4F60\u5E26\u52A8\u5566\u3002';
    }
    if (this.todayPomodoroCount >= 2) {
      return '\u5B8C\u6210\u597D\u51E0\u4E2A\u756A\u8304\u5566\uFF0C\u7EE7\u7EED\u4FDD\u6301\u3002';
    }
    if (this.todayCompletedCount >= 3) {
      return '\u4EFB\u52A1\u63A8\u8FDB\u5F97\u5F88\u68D2\u3002';
    }
    if (this.todayEarlyExitCount > 0) {
      return '\u6CA1\u5173\u7CFB\uFF0C\u4E0B\u4E00\u6B21\u6211\u4EEC\u4E00\u8D77\u575A\u6301\u4E45\u4E00\u70B9\u3002';
    }
    return '\u5148\u4ECE\u4E00\u4E2A\u5C0F\u76EE\u6807\u5F00\u59CB\u5427\u3002';
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

  getMoStageName(): string {
    let level = this.getPetLevel();
    if (level <= 1 && this.todayFocusMinutes < 30) {
      return '\u86CB';
    }
    if (level <= 2) {
      return '\u7834\u58F3';
    }
    if (level <= 4) {
      return '\u5E7C\u5D3D';
    }
    if (level <= 7) {
      return '\u6210\u957F\u671F';
    }
    return '\u5B66\u4E60\u4F19\u4F34';
  }

  getMoNextStageName(): string {
    let level = this.getPetLevel();
    if (level <= 1 && this.todayFocusMinutes < 30) {
      return '\u7834\u58F3';
    }
    if (level <= 2) {
      return '\u5E7C\u5D3D';
    }
    if (level <= 4) {
      return '\u6210\u957F\u671F';
    }
    if (level <= 7) {
      return '\u5B66\u4E60\u4F19\u4F34';
    }
    return '\u5DF2\u8FBE\u5230\u5F53\u524D\u6700\u9AD8\u9636\u6BB5';
  }

  getMoStageProgress(): number {
    let level = this.getPetLevel();
    if (level <= 1 && this.todayFocusMinutes < 30) {
      return this.getPetProgress();
    }
    if (level <= 2) {
      return this.getPetProgress();
    }
    if (level <= 4) {
      return level === 3 ? 50 : 100;
    }
    if (level <= 7) {
      return Math.round((level - 4) * 100 / 4);
    }
    return 100;
  }

  getMoNextStageText(): string {
    let level = this.getPetLevel();
    if (level <= 1 && this.todayFocusMinutes < 30) {
      return '\u8FBE\u5230 Lv2 \u6216\u4ECA\u65E5\u7D2F\u8BA1\u4E13\u6CE8 30 \u5206\u949F\uFF0C\u5C0Fmo\u5C31\u4F1A\u5F00\u59CB\u7834\u58F3';
    }
    if (level <= 2) {
      return '\u8FBE\u5230 Lv3 \u540E\uFF0C\u5C0Fmo\u4F1A\u6B63\u5F0F\u8BDE\u751F';
    }
    if (level <= 4) {
      return '\u8FBE\u5230 Lv5 \u540E\uFF0C\u5C0Fmo\u4F1A\u8FDB\u5165\u6210\u957F\u671F';
    }
    if (level <= 7) {
      return '\u8FBE\u5230 Lv8 \u540E\uFF0C\u5C0Fmo\u4F1A\u6210\u4E3A\u5B66\u4E60\u4F19\u4F34';
    }
    return '\u5DF2\u8FBE\u5230\u5F53\u524D\u6700\u9AD8\u9636\u6BB5';
  }

  getMoGrowthStageName(): string {
    let level = this.getPetLevel();
    if (level <= 2) {
      return '\u5B75\u5316\u4E2D';
    }
    if (level <= 4) {
      return '\u7834\u58F3\u671F';
    }
    if (level <= 7) {
      return '\u5E7C\u5D3D\u671F';
    }
    return '\u5B66\u4E60\u4F19\u4F34';
  }

  getMoNextGrowthStageName(): string {
    let level = this.getPetLevel();
    if (level <= 2) {
      return '\u7834\u58F3\u671F';
    }
    if (level <= 4) {
      return '\u5E7C\u5D3D\u671F';
    }
    if (level <= 7) {
      return '\u5B66\u4E60\u4F19\u4F34';
    }
    return '\u5DF2\u8FBE\u5230\u5F53\u524D\u6700\u9AD8\u9636\u6BB5';
  }

  getMoGrowthStageGap(): number {
    let level = this.getPetLevel();
    if (level <= 2) {
      return 3 - level;
    }
    if (level <= 4) {
      return 5 - level;
    }
    if (level <= 7) {
      return 8 - level;
    }
    return 0;
  }

  getMoGrowthStageText(): string {
    let gap = this.getMoGrowthStageGap();
    if (gap <= 0) {
      return '\u5C0Fmo\u5DF2\u6210\u4E3A\u5B66\u4E60\u4F19\u4F34\uFF0C\u4F1A\u7EE7\u7EED\u966A\u4F60\u5B66\u4E60\u3002';
    }
    return `\u5C0Fmo\u6B63\u5728\u6162\u6162\u957F\u5927\uFF0C\u518D\u5347 ${gap} \u7EA7\u5C31\u8FDB\u5165${this.getMoNextGrowthStageName()}\u3002`;
  }

  getMoStageMessage(): string {
    let stageName = this.getMoStageName();
    if (stageName === '\u86CB') {
      return '\u5C0Fmo\u6B63\u5728\u86CB\u91CC\u7761\u89C9';
    }
    if (stageName === '\u7834\u58F3') {
      return '\u5C0Fmo\u597D\u50CF\u5FEB\u51FA\u6765\u5566';
    }
    if (stageName === '\u5E7C\u5D3D') {
      return '\u5C0Fmo\u8BDE\u751F\u5566';
    }
    if (stageName === '\u6210\u957F\u671F') {
      return '\u5C0Fmo\u957F\u5927\u4E86\u4E00\u70B9\uFF0C\u60F3\u5E26\u7740\u88C5\u9970\u966A\u4F60\u5B66\u4E60';
    }
    return '\u5C0Fmo\u5750\u5728\u4E66\u684C\u65C1\uFF0C\u5B89\u9759\u966A\u4F60\u5B66\u4E60';
  }

  getMoTodayCompanionText(): string {
    return this.getMoMoodName();
  }

  getDailyCompanionQuote(): string {
    let quotes: string[] = [
      '\u4ECA\u5929\u4E5F\u4E00\u8D77\u52A0\u6CB9\u5427',
      '\u5148\u5B8C\u6210\u4E00\u4E2A\u5C0F\u76EE\u6807',
      '\u5C0F\u6B65\u524D\u8FDB\u4E5F\u662F\u8FDB\u6B65',
      '\u4F11\u606F\u4E00\u4E0B\u518D\u51FA\u53D1'
    ];
    let seed = 0;
    let todayText = this.getTodayString();
    for (let index = 0; index < todayText.length; index++) {
      seed += todayText.charCodeAt(index);
    }
    return quotes[seed % quotes.length];
  }

  getStudyRoomName(index: number): string {
    let names: string[] = ['\u5976\u6CB9\u4E66\u684C', '\u6DF1\u591C\u81EA\u4E60\u5BA4', '\u6E05\u6668\u7A97\u8FB9',
      '\u661F\u7A7A\u623F\u95F4'];
    return names[Math.max(0, index) % names.length];
  }

  getStudyRoomTag(index: number): string {
    let tags: string[] = ['\u67D4\u8F6F\u5976\u6CB9', '\u5B89\u9759\u6DF1\u591C', '\u6E05\u65B0\u5149\u611F',
      '\u7F13\u6162\u661F\u5149'];
    return tags[Math.max(0, index) % tags.length];
  }

  getStudyRoomDesc(index: number): string {
    let descriptions: string[] = ['\u6E29\u67D4\u5F00\u59CB\u4ECA\u5929\u7684\u5B66\u4E60',
      '\u5B89\u9759\u5730\u628A\u601D\u8DEF\u6536\u56DE\u6765',
      '\u8BA9\u6E05\u723D\u8282\u594F\u5E26\u4F60\u8FDB\u5165\u72B6\u6001',
      '\u653E\u6162\u4E00\u70B9\uFF0C\u628A\u76EE\u6807\u6536\u597D',
      '\u5728\u96E8\u58F0\u91CC\u7559\u4E00\u4E2A\u5B89\u9759\u89D2\u843D'];
    return descriptions[Math.max(0, index) % descriptions.length];
  }

  getStudyRoomColor(index: number): string {
    let colors: string[] = ['#FFF3DF', '#E9ECFF', '#E9F8ED', '#F3EDFF'];
    return colors[Math.max(0, index) % colors.length];
  }

  getStudyRoomAccentColor(index: number): string {
    let colors: string[] = ['#E5B86E', '#7D83C7', '#8CC79B', '#A991DA'];
    return colors[Math.max(0, index) % colors.length];
  }

  touchStudyBuddy() {
    let replies: string[] = ['\u5C0Fmo\u5728\u5462\uff5e', '\u4ECA\u5929\u4E5F\u4E00\u8D77\u52AA\u529B\u5440\u3002',
      '\u4F60\u5DF2\u7ECF\u5F88\u68D2\u5566\u3002', '\u518D\u6765\u4E00\u4E2A\u5C0F\u76EE\u6807\u5427\u3002'];
    this.studyBuddyReply = replies[Math.floor(Math.random() * replies.length)];
  }

  formatFocusTime(): string {
    let minute = Math.floor(this.focusRemainingSeconds / 60);
    let second = this.focusRemainingSeconds % 60;
    let minuteText = minute < 10 ? `0${minute}` : `${minute}`;
    let secondText = second < 10 ? `0${second}` : `${second}`;
    return `${minuteText}:${secondText}`;
  }

  formatSecondsText(totalSeconds: number): string {
    let safeSeconds = Math.max(0, Math.round(totalSeconds));
    let minute = Math.floor(safeSeconds / 60);
    let second = safeSeconds % 60;
    let secondText = second < 10 ? `0${second}` : `${second}`;
    return `${minute}:${secondText}`;
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
    hilog.info(0x0000, 'Index',
      `toggle key=${normalizedKey}, targetIndex=${targetIndex}, before=${wasCompleted}, after=removed`);
    let targetItem = this.toDoData[targetIndex];
    this.toDoData = this.toDoData.filter((todoItem: ToDo) => String(todoItem.key) !== normalizedKey);
    if (!wasCompleted) {
      this.recordTaskCompletion(targetItem);
    }
    this.saveAppState();
  }

  recordTaskCompletion(item?: ToDo) {
    this.addGrowthReward(this.getTaskScoreReward(item), this.getTaskScoreReason(item));
    this.todayCompletedCount += 1;
    try {
      this.grantAchievedDailyGoals();
      this.grantAchievementRewards();
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0000, 'Index', `grant daily goal failed. error code=${err.code}, message=${err.message}`);
    }
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
    if (message === '\u4E13\u6CE8\u5DF2\u6682\u505C' || message === '\u4E13\u6CE8\u5DF2\u7EE7\u7EED') {
      return;
    }
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
    this.addGrowthReward(2, '\u6BCF\u65E5\u7B7E\u5230');
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
      this.equipOutfit(index);
      return;
    }
    this.redeemOutfit(index);
  }

  redeemOutfit(index: number) {
    if (index < 0 || index >= this.outfitNames.length || this.ownedOutfits[index]) {
      return;
    }
    let price = this.outfitPrices[index];
    if (this.score < price) {
      this.showToastMessage('\u79EF\u5206\u4E0D\u8DB3\uFF0C\u65E0\u6CD5\u5151\u6362\u88C5\u9970');
      return;
    }
    let updatedOutfits = [...this.ownedOutfits];
    updatedOutfits[index] = true;
    this.ownedOutfits = updatedOutfits;
    this.equippedOutfitIndex = index;
    this.score -= price;
    this.showToastMessage('\u88C5\u9970\u5DF2\u5151\u6362\u5E76\u4F69\u6234');
    this.saveAppState();
  }

  equipOutfit(index: number) {
    if (index < 0 || index >= this.outfitNames.length || !this.ownedOutfits[index]) {
      return;
    }
    this.equippedOutfitIndex = index;
    this.showToastMessage('\u88C5\u9970\u5DF2\u4F69\u6234');
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
      await this.taskTransferService.init(hostContext as common.UIAbilityContext, (payload: FreeFlowPayload) => {
        this.receiveFreeFlowPayload(payload);
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
      title: '\u6D41\u8F6C\u5230\u5176\u4ED6\u8BBE\u5907',
      message: '\u5C06\u4EFB\u52A1\u5199\u5165\u5206\u5E03\u5F0FKV\u5E76\u53D1\u8D77\u540C\u6B65\uFF1B\u65E0\u771F\u673A\u65F6\u53EF\u9009\u6F14\u793A\u8BBE\u5907\u3002',
      primaryButton: {
        value: '\u9009\u62E9\u8BBE\u5907',
        action: () => {
          this.showRealDeliveryDevicePicker(item);
        }
      },
      secondaryButton: {
        value: '\u6F14\u793A\u8BBE\u5907',
        action: () => {
          this.showMockDeliveryPicker(item);
        }
      }
    });
  }

  showMockDeliveryPicker(item: ToDo) {
    this.getUIContext().showTextPickerDialog({
      range: this.sampleTransferDevices,
      onAccept: (value: TextPickerResult) => {
        let deviceName = this.sampleTransferDevices[Number(value.index)];
        this.lastDeliveryType = '\u6F14\u793A\u8BBE\u5907';
        this.lastDeliveryRecord = `\u6F14\u793A\u8BBE\u5907\uFF1A${item.name} \u2192 ${deviceName}\uFF08\u4E0D\u4EE3\u8868\u771F\u5B9E\u6295\u9001\u6210\u529F\uFF09`;
        this.realDeliveryStatus = '\u6F14\u793A\u8BBE\u5907\u8BB0\u5F55\u5DF2\u4FDD\u7559\uFF0C\u672A\u8FDB\u884C\u771F\u5B9E\u8DE8\u8BBE\u5907\u540C\u6B65';
        this.showToastMessage('\u5DF2\u4FDD\u7559\u6F14\u793A\u8BBE\u5907\u8BB0\u5F55');
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
        range: devices.map((device: TransferDevice) => this.getTransferDeviceDisplayName(device)),
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
    let displayName = this.getTransferDeviceDisplayName(targetDevice);
    this.realDeliveryStatus = `\u6D41\u8F6C\u4E2D\uFF1A${item.name} \u2192 ${displayName}`;
    this.lastDeliveryType = '\u771F\u5B9E\u6295\u9001';
    this.lastRealSentTask = `${item.name} \u2192 ${displayName}`;
    this.lastDeliveryRecord = this.realDeliveryStatus;
    this.saveAppState();
    try {
      let result = await this.taskTransferService.transferTaskToDevice(this.buildTransferTodoData(item),
        targetDevice.networkId);
      this.realDeliveryStatus = `${result.fallback ? '\u6F14\u793A\u8BBE\u5907' : '\u540C\u6B65\u5DF2\u53D1\u8D77'}\uFF1A${item.name} \u2192 ${displayName}`;
      this.lastDeliveryRecord = this.realDeliveryStatus;
      this.showToastMessage(result.message);
    } catch (error) {
      let err = error as BusinessError;
      this.realDeliveryStatus = `\u53D1\u9001\u5931\u8D25\uFF1A${err.message}`;
      this.lastDeliveryRecord = `\u53D1\u9001\u5931\u8D25\uFF1A${item.name} \u2192 ${displayName}`;
      this.showToastMessage('\u771F\u5B9E\u6295\u9001\u5931\u8D25\uFF0C\u8BF7\u68C0\u67E5\u8BBE\u5907\u4FE1\u4EFB\u548C\u6743\u9650');
    }
    this.saveAppState();
  }

  async showFocusTransferDevicePicker(): Promise<void> {
    if (this.focusTaskKey.length === 0) {
      this.showToastMessage('\u8BF7\u5148\u9009\u62E9\u4E00\u4E2A\u4E13\u6CE8\u4EFB\u52A1');
      return;
    }
    let hasPermission = await this.ensureDistributedDataSyncPermission();
    if (!hasPermission) {
      return;
    }
    await this.initTaskTransfer();
    if (!this.hasInitializedTransfer) {
      this.showToastMessage('\u81EA\u7531\u6D41\u8F6C\u521D\u59CB\u5316\u5931\u8D25');
      return;
    }
    try {
      let devices = await this.taskTransferService.getAvailableDevices();
      this.discoveredDeviceCount = devices.length;
      this.realDeliveryDevices = devices;
      this.getUIContext().showTextPickerDialog({
        range: devices.map((device: TransferDevice) => this.getTransferDeviceDisplayName(device)),
        onAccept: (value: TextPickerResult) => {
          let selectedDevice = this.realDeliveryDevices[Number(value.index)];
          if (selectedDevice !== undefined) {
            this.sendFocusState(selectedDevice);
          }
        }
      });
    } catch (error) {
      let err = error as BusinessError;
      this.realDeliveryStatus = `\u4E13\u6CE8\u6D41\u8F6C\u5931\u8D25\uFF1A${err.message}`;
      this.showToastMessage('\u83B7\u53D6\u8BBE\u5907\u5931\u8D25');
      this.saveAppState();
    }
  }

  async sendFocusState(targetDevice: TransferDevice): Promise<void> {
    let focusData: TransferFocusData = {
      taskTitle: this.getFocusTaskName(),
      remainingSeconds: Math.max(0, this.focusRemainingSeconds),
      totalSeconds: Math.max(60, this.focusTotalSeconds),
      isPaused: !this.isFocusRunning
    };
    this.lastDeliveryType = '\u4E13\u6CE8\u6D41\u8F6C';
    let displayName = this.getTransferDeviceDisplayName(targetDevice);
    this.lastRealSentTask = `${focusData.taskTitle} \u2192 ${displayName}`;
    this.realDeliveryStatus = `\u4E13\u6CE8\u6D41\u8F6C\u4E2D\uFF1A${focusData.taskTitle}`;
    this.saveAppState();
    try {
      let result: TransferResult = await this.taskTransferService.transferFocusState(focusData, targetDevice.networkId);
      this.realDeliveryStatus = `${result.fallback ? '\u6F14\u793A\u8BBE\u5907' : '\u540C\u6B65\u5DF2\u53D1\u8D77'}\uFF1A\u4E13\u6CE8\u72B6\u6001 \u2192 ${displayName}`;
      this.lastDeliveryRecord = this.realDeliveryStatus;
      this.showToastMessage(result.message);
    } catch (error) {
      let err = error as BusinessError;
      this.realDeliveryStatus = `\u4E13\u6CE8\u6D41\u8F6C\u5931\u8D25\uFF1A${err.message}`;
      this.showToastMessage('\u4E13\u6CE8\u72B6\u6001\u6D41\u8F6C\u5931\u8D25');
    }
    this.saveAppState();
  }

  getTransferDeviceDisplayName(device: TransferDevice): string {
    if (device.networkId.startsWith('fallback_')) {
      return '\u6F14\u793A\u8BBE\u5907';
    }
    return device.displayName.length > 0 ? device.displayName : device.deviceName;
  }

  buildTransferTodoData(item: ToDo): TransferTodoData {
    return {
      key: item.key,
      name: item.name,
      createdAt: item.createdAt,
      priority: item.priority,
      isCompleted: item.isCompleted,
      focusCount: item.focusCount,
      focusDurationMinutes: item.focusDurationMinutes,
      deadline: item.deadline,
      taskType: item.taskType,
      plannedFocusMinutes: item.plannedFocusMinutes,
      category: item.category,
      repeatType: item.repeatType,
      cardThemeIndex: item.cardThemeIndex
    };
  }

  buildTaskTransferPayload(item: ToDo): TaskTransferPayload {
    let taskData: TransferTodoData = this.buildTransferTodoData(item);
    return {
      type: 'todo_transfer',
      version: 1,
      transferId: this.taskTransferService.buildTransferId(),
      sourceDeviceId: this.taskTransferService.getLocalDeviceId(),
      sourceDeviceName: this.taskTransferService.getLocalDeviceName(),
      fromDevice: this.taskTransferService.getLocalDeviceName(),
      sentAt: Date.now(),
      timestamp: Date.now(),
      task: taskData
    };
  }

  receiveFreeFlowPayload(payload: FreeFlowPayload) {
    if ((payload as FocusTransferPayload).focus !== undefined) {
      this.receiveRemoteFocus(payload as FocusTransferPayload);
      return;
    }
    this.receiveRemoteTask(payload as TaskTransferPayload);
  }

  receiveRemoteTask(payload: TaskTransferPayload) {
    if (this.receivedTransferIds.includes(payload.transferId)) {
      return;
    }
    this.receivedTransferIds = [payload.transferId, ...this.receivedTransferIds].slice(0, 100);
    this.lastDeliveryType = '\u771F\u5B9E\u6295\u9001';
    this.lastRealReceivedTask = payload.task.name;
    this.realDeliveryStatus = `\u5DF2\u63A5\u6536\uFF1A${payload.task.name}\uFF0C\u7B49\u5F85\u786E\u8BA4\u52A0\u5165`;
    this.lastDeliveryRecord = this.realDeliveryStatus;
    this.pendingTransferKind = 'todo';
    this.pendingTransferId = payload.transferId;
    this.pendingTransferSource = payload.fromDevice === undefined ? payload.sourceDeviceName : payload.fromDevice;
    this.pendingTaskName = payload.task.name;
    this.pendingTaskType = ToDo.normalizeTaskType(payload.task.taskType);
    this.pendingTaskPriority = this.normalizePriority(payload.task.priority);
    this.pendingTaskDeadline = Math.max(0, payload.task.deadline);
    this.pendingTaskCategory = payload.task.category.length > 0 ? payload.task.category : payload.task.name;
    this.pendingTaskRepeatType = payload.task.repeatType.length > 0 ? payload.task.repeatType : '\u4E0D\u91CD\u590D';
    this.pendingTaskFocusCount = Math.max(0, payload.task.focusCount);
    this.pendingTaskFocusMinutes = Math.max(0, payload.task.focusDurationMinutes);
    this.pendingTaskPlannedMinutes = Math.max(1, payload.task.plannedFocusMinutes);
    this.pendingTaskCardThemeIndex = payload.task.cardThemeIndex;
    this.showToastMessage(`\u6536\u5230\u6765\u81EA ${this.pendingTransferSource} \u7684\u4EFB\u52A1`);
    this.saveAppState();
  }

  receiveRemoteFocus(payload: FocusTransferPayload) {
    if (this.receivedTransferIds.includes(payload.transferId)) {
      return;
    }
    this.receivedTransferIds = [payload.transferId, ...this.receivedTransferIds].slice(0, 100);
    this.lastDeliveryType = '\u4E13\u6CE8\u6D41\u8F6C';
    this.lastRealReceivedTask = payload.focus.taskTitle;
    this.realDeliveryStatus = `\u6536\u5230\u4E13\u6CE8\u4EFB\u52A1\uFF1A${payload.focus.taskTitle}`;
    this.lastDeliveryRecord = this.realDeliveryStatus;
    this.pendingTransferKind = 'focus';
    this.pendingTransferId = payload.transferId;
    this.pendingTransferSource = payload.fromDevice === undefined ? payload.sourceDeviceName : payload.fromDevice;
    this.pendingFocusTaskTitle = payload.focus.taskTitle;
    this.pendingFocusRemainingSeconds = Math.max(0, payload.focus.remainingSeconds);
    this.pendingFocusTotalSeconds = Math.max(60, payload.focus.totalSeconds);
    this.pendingFocusIsPaused = payload.focus.isPaused;
    this.showToastMessage(`\u6536\u5230\u6765\u81EA ${this.pendingTransferSource} \u7684\u4E13\u6CE8\u4EFB\u52A1`);
    this.saveAppState();
  }

  buildPendingReceivedTodo(): ToDo {
    return new ToDo(
      this.pendingTaskName,
      this.normalizePriority(this.pendingTaskPriority),
      Math.max(0, this.pendingTaskDeadline),
      this.pendingTaskCategory.length > 0 ? this.pendingTaskCategory : this.pendingTaskName,
      this.pendingTaskRepeatType.length > 0 ? this.pendingTaskRepeatType : '\u4E0D\u91CD\u590D',
      ToDo.normalizeTaskType(this.pendingTaskType),
      Math.max(1, this.pendingTaskPlannedMinutes),
      this.pendingTaskCardThemeIndex
    );
  }

  acceptPendingTask(shouldStartFocus: boolean) {
    if (this.pendingTransferKind !== 'todo' || this.pendingTaskName.length === 0) {
      return;
    }
    let newItem = this.buildPendingReceivedTodo();
    newItem.focusCount = Math.max(0, this.pendingTaskFocusCount);
    newItem.focusDurationMinutes = Math.max(0, this.pendingTaskFocusMinutes);
    this.toDoData = [newItem, ...this.toDoData];
    this.lastDeliveryRecord = `\u5DF2\u52A0\u5165\u6D41\u8F6C\u4EFB\u52A1\uFF1A${newItem.name}`;
    this.realDeliveryStatus = this.lastDeliveryRecord;
    this.clearPendingTransfer();
    this.saveAppState();
    if (shouldStartFocus) {
      if (newItem.taskType !== 'focus') {
        newItem.taskType = 'focus';
      }
      this.startFocus(newItem, newItem.plannedFocusMinutes);
    } else {
      this.showToastMessage('\u5DF2\u52A0\u5165\u6211\u7684\u4EE3\u529E');
    }
  }

  startPendingFocusTransfer() {
    if (this.pendingTransferKind !== 'focus' || this.pendingFocusTaskTitle.length === 0) {
      return;
    }
    let focusMinutes = Math.max(1, Math.round(this.pendingFocusTotalSeconds / 60));
    let newItem = new ToDo(this.pendingFocusTaskTitle, 1, 0, this.pendingFocusTaskTitle, '\u4E0D\u91CD\u590D',
      'focus', focusMinutes, -1);
    this.toDoData = [newItem, ...this.toDoData];
    this.lastDeliveryRecord = `\u4ECE\u6D41\u8F6C\u4E13\u6CE8\u91CD\u65B0\u5F00\u59CB\uFF1A${newItem.name}`;
    this.realDeliveryStatus = this.lastDeliveryRecord;
    this.clearPendingTransfer();
    this.saveAppState();
    this.startFocus(newItem, focusMinutes);
  }

  clearPendingTransfer() {
    this.pendingTransferKind = '';
    this.pendingTransferId = '';
    this.pendingTransferSource = '';
    this.pendingTaskName = '';
    this.pendingTaskType = 'focus';
    this.pendingTaskPriority = 1;
    this.pendingTaskDeadline = 0;
    this.pendingTaskCategory = '\u9ED8\u8BA4';
    this.pendingTaskRepeatType = '\u4E0D\u91CD\u590D';
    this.pendingTaskFocusCount = 0;
    this.pendingTaskFocusMinutes = 0;
    this.pendingTaskPlannedMinutes = 25;
    this.pendingTaskCardThemeIndex = -1;
    this.pendingFocusTaskTitle = '';
    this.pendingFocusRemainingSeconds = 0;
    this.pendingFocusTotalSeconds = 0;
    this.pendingFocusIsPaused = false;
  }

  @Builder
  receivedFreeFlowCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Row() {
        Text(this.pendingTransferKind === 'focus' ? `\u6536\u5230\u6765\u81EA ${this.pendingTransferSource} \u7684\u4E13\u6CE8\u4EFB\u52A1` :
          `\u6536\u5230\u6765\u81EA ${this.pendingTransferSource} \u7684\u4EFB\u52A1`)
          .fontSize($r('sys.float.ohos_id_text_size_headline8'))
          .fontColor(UI_COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text('\u5FFD\u7565')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.TEXT_SECONDARY)
          .padding({
            left: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
            right: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
            top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
            bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
          })
          .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
          .backgroundColor('#F1F3F5')
          .onClick(() => {
            this.clearPendingTransfer();
          })
      }
      .width(Constant.PERCENT_FULL)
      if (this.pendingTransferKind === 'focus') {
        this.receivedFocusContent()
      } else {
        this.receivedTaskContent()
      }
    }
    .width(Constant.PERCENT_FULL)
    .constraintSize({ maxWidth: 760 })
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor('#F6F1FF')
    .shadow({ radius: 14, color: UI_COLORS.CARD_SHADOW, offsetX: 0, offsetY: 5 })
  }

  @Builder
  receivedTaskContent() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.deliveryStatusRow('\u4EFB\u52A1\u540D', this.pendingTaskName)
      this.deliveryStatusRow('\u4EFB\u52A1\u7C7B\u578B', this.getTaskTypeText(this.pendingTaskType))
      this.deliveryStatusRow('\u622A\u6B62\u65E5\u671F', this.getDeadlineDateText(this.pendingTaskDeadline))
      this.deliveryStatusRow('\u4F18\u5148\u7EA7', this.getPriorityName(this.pendingTaskPriority))
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        this.freeFlowActionButton('\u52A0\u5165\u6211\u7684\u4EE3\u529E', UI_COLORS.MINT, () => {
          this.acceptPendingTask(false);
        })
        this.freeFlowActionButton('\u7ACB\u5373\u5F00\u59CB\u4E13\u6CE8', UI_COLORS.FOCUS_BLUE, () => {
          this.acceptPendingTask(true);
        })
      }
      .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
  }

  @Builder
  receivedFocusContent() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.deliveryStatusRow('\u4E13\u6CE8\u4EFB\u52A1', this.pendingFocusTaskTitle)
      this.deliveryStatusRow('\u603B\u65F6\u957F', `${Math.round(this.pendingFocusTotalSeconds / 60)}\u5206\u949F`)
      this.deliveryStatusRow('\u5269\u4F59\u65F6\u95F4', this.formatSecondsText(this.pendingFocusRemainingSeconds))
      this.deliveryStatusRow('\u72B6\u6001', this.pendingFocusIsPaused ? '\u5DF2\u6682\u505C' : '\u6D41\u8F6C\u65F6\u6B63\u5728\u4E13\u6CE8')
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        this.freeFlowActionButton('\u4EE5\u5B8C\u6574\u65F6\u957F\u91CD\u65B0\u5F00\u59CB', UI_COLORS.FOCUS_BLUE, () => {
          this.startPendingFocusTransfer();
        })
      }
      .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
  }

  @Builder
  freeFlowActionButton(labelText: string, bgColor: ResourceColor, action: () => void) {
    Text(labelText)
      .fontSize($r('sys.float.ohos_id_text_size_body2'))
      .fontColor(Color.White)
      .fontWeight(FontWeight.Medium)
      .textAlign(TextAlign.Center)
      .layoutWeight(1)
      .padding({
        top: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
        bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2
      })
      .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
      .backgroundColor(bgColor)
      .onClick(action)
  }

  showTodoDetail(item: ToDo) {
    AlertDialog.show({
      title: '\u4EFB\u52A1\u8BE6\u60C5',
      message: `\u4EFB\u52A1\u540D\u79F0\uFF1A${item.name}\n` +
        `\u4F18\u5148\u7EA7\uFF1A${this.getPriorityName(item.priority)}\n` +
        `\u5206\u7C7B\uFF1A${item.category}\n` +
        `\u91CD\u590D\uFF1A${item.repeatType}\n` +
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

  completeOnceTaskAndRemove(itemKey: string) {
    let normalizedKey = String(itemKey);
    let targetItem = this.toDoData.find((todoItem: ToDo) => String(todoItem.key) === normalizedKey);
    if (targetItem === undefined || targetItem.taskType !== 'once') {
      return;
    }
    this.toDoData = this.toDoData.filter((todoItem: ToDo) => String(todoItem.key) !== normalizedKey);
    this.recordTaskCompletion(targetItem);
    this.saveAppState();
  }

  completeTaskByKey(itemKey: string) {
    let normalizedKey = String(itemKey);
    let targetItem = this.toDoData.find((todoItem: ToDo) => String(todoItem.key) === normalizedKey);
    if (targetItem === undefined) {
      return;
    }
    this.toDoData = this.toDoData.filter((todoItem: ToDo) => String(todoItem.key) !== normalizedKey);
    if (!targetItem.isCompleted) {
      this.recordTaskCompletion(targetItem);
    }
    this.saveAppState();
  }

  getDeadlineByEditOffset(offset: number, currentDeadline: number): number {
    if (offset === -2) {
      return currentDeadline;
    }
    if (offset < 0) {
      return 0;
    }
    return this.getDeadlineByOffset(offset);
  }

  openTodoEditor(item: ToDo) {
    this.isAddingTodo = false;
    this.editingTodoKey = item.key;
  }

  closeTodoEditor() {
    this.editingTodoKey = '';
    this.isAddingTodo = false;
    this.currentTab = 0;
  }

  getEditingTodo(): ToDo | null {
    let matchedItems = this.getAllTodos().filter((item: ToDo) => item.key === this.editingTodoKey);
    if (matchedItems.length === 0) {
      return null;
    }
    return matchedItems[0];
  }

  saveTodoFromEditor(item: ToDo, name: string, focusMinutes: number, priority: number, deadlineOffset: number,
    category: string, repeatType: string, taskType: string, cardThemeIndex: number) {
    let safeName = name.trim().length > 0 ? name.trim() : item.name;
    let normalizedTaskType = ToDo.normalizeTaskType(taskType);
    item.name = safeName;
    item.plannedFocusMinutes = Math.max(1, focusMinutes);
    item.priority = this.normalizePriority(priority);
    item.deadline = normalizedTaskType === 'habit' ? 0 : this.getDeadlineByEditOffset(deadlineOffset, item.deadline);
    item.category = category.trim().length > 0 ? category.trim() : safeName;
    item.repeatType = repeatType.length > 0 ? repeatType : '\u4E0D\u91CD\u590D';
    item.taskType = normalizedTaskType;
    item.cardThemeIndex = cardThemeIndex;
    this.updateTodoItem(item);
    this.closeTodoEditor();
    this.showToastMessage('\u4EFB\u52A1\u5DF2\u66F4\u65B0');
  }

  saveNewTodoFromForm(item: ToDo, name: string, focusMinutes: number, priority: number, deadlineOffset: number,
    category: string, repeatType: string, taskType: string, cardThemeIndex: number) {
    let safeName = name.trim();
    if (safeName.length === 0) {
      this.showToastMessage('\u8BF7\u8F93\u5165\u4EFB\u52A1\u540D\u79F0');
      return;
    }
    let normalizedTaskType = ToDo.normalizeTaskType(taskType);
    let newItem = new ToDo(
      safeName,
      this.normalizePriority(priority),
      normalizedTaskType === 'habit' ? 0 : this.getDeadlineByEditOffset(deadlineOffset, item.deadline),
      category.trim().length > 0 ? category.trim() : safeName,
      repeatType.length > 0 ? repeatType : '\u4E0D\u91CD\u590D',
      normalizedTaskType,
      Math.max(1, focusMinutes),
      cardThemeIndex
    );
    this.toDoData = [newItem, ...this.toDoData];
    this.closeTodoEditor();
    this.showToastMessage('\u5DF2\u65B0\u589E\u4EE3\u529E');
    this.saveAppState();
  }

  createSampleTodo(taskName: string) {
    let newItem = new ToDo(taskName, 1, this.getDeadlineByEditOffset(1, 0), taskName, '\u4E0D\u91CD\u590D',
      'focus', 25, -1);
    this.toDoData = [newItem, ...this.toDoData];
    this.showToastMessage('\u5DF2\u65B0\u589E\u4EE3\u529E');
    this.saveAppState();
  }

  isSampleTaskName(taskName: string): boolean {
    return this.sampleTaskNames.indexOf(taskName) >= 0;
  }

  hasSampleData(): boolean {
    return this.toDoData.some((todoItem: ToDo) => this.isSampleTaskName(todoItem.name));
  }

  generateSampleData() {
    let sampleItems: ToDo[] = [
      new ToDo('\u9AD8\u6570\u590D\u4E60', 2, this.getDeadlineByEditOffset(0, 0), '\u5B66\u4E60',
        '\u4E0D\u91CD\u590D', 'focus', 45, 0),
      new ToDo('\u82F1\u8BED\u80CC\u5355\u8BCD', 1, this.getDeadlineByEditOffset(1, 0), '\u82F1\u8BED',
        '\u6BCF\u5929', 'focus', 25, 1),
      new ToDo('HarmonyOS \u9879\u76EE', 2, this.getDeadlineByEditOffset(3, 0), '\u9879\u76EE',
        '\u4E0D\u91CD\u590D', 'focus', 30, 2),
      new ToDo('\u9605\u8BFB', 0, this.getDeadlineByEditOffset(7, 0), '\u9605\u8BFB',
        '\u4E0D\u91CD\u590D', 'focus', 25, 3),
      new ToDo('\u8FD0\u52A8\u6253\u5361', 1, 0, '\u5065\u5EB7', '\u6BCF\u5929', 'habit', 15, 4)
    ];
    sampleItems[0].focusCount = 1;
    sampleItems[0].focusDurationMinutes = 45;
    sampleItems[1].focusCount = 2;
    sampleItems[1].focusDurationMinutes = 50;
    sampleItems[2].focusCount = 1;
    sampleItems[2].focusDurationMinutes = 30;
    this.toDoData = [...sampleItems, ...this.toDoData.filter((todoItem: ToDo) => !this.isSampleTaskName(todoItem.name))];
    this.showToastMessage('\u793A\u4F8B\u6570\u636E\u5DF2\u751F\u6210');
    this.saveAppState();
  }

  clearSampleData() {
    if (!this.hasSampleData()) {
      this.showToastMessage('\u6CA1\u6709\u53EF\u6E05\u7A7A\u7684\u793A\u4F8B\u6570\u636E');
      return;
    }
    this.toDoData = this.toDoData.filter((todoItem: ToDo) => !this.isSampleTaskName(todoItem.name));
    this.showToastMessage('\u793A\u4F8B\u6570\u636E\u5DF2\u6E05\u7A7A');
    this.saveAppState();
  }

  showTodoActionMenu(item: ToDo) {
    this.actionMenuTodoKey = item.key;
  }

  closeTodoActionMenu() {
    this.actionMenuTodoKey = '';
  }

  getActionMenuTodo(): ToDo | undefined {
    return this.toDoData.find((todoItem: ToDo) => todoItem.key === this.actionMenuTodoKey);
  }

  pinTodoItem(item: ToDo) {
    this.toDoData = [item, ...this.toDoData.filter((todoItem: ToDo) => todoItem.key !== item.key)];
    this.closeTodoActionMenu();
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
        Text('\u5C0F\u52A8\u7269\u88C5\u9970')
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
      Text(`\u5F53\u524D\u88C5\u9970\uFF1A${this.getEquippedOutfitName()} \u00B7 \u5DF2\u62E5\u6709 ${this.getOwnedOutfitCount()} / ${this.outfitNames.length}`)
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
      Row() {
        Stack() {
          Row()
            .width(68)
            .height(48)
            .borderRadius(14)
            .backgroundColor(this.getOutfitRoomBgColor(index))
          Row()
            .width(46)
            .height(12)
            .borderRadius(6)
            .backgroundColor(this.getOutfitScarfColor(index))
            .position({ x: 11, y: 29 })
          Row()
            .width(24)
            .height(20)
            .borderRadius(7)
            .backgroundColor(this.getOutfitPreviewColor(index))
            .position({ x: 22, y: 15 })
          Row()
            .width(20)
            .height(18)
            .borderRadius(6)
            .backgroundColor('#AAFFFFFF')
            .position({ x: 40, y: 8 })
        }
        .width(68)
        .height(48)
        Text(this.getOutfitStyleTag(index))
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(this.equippedOutfitIndex === index ? UI_COLORS.PET_PURPLE : UI_COLORS.TEXT_SECONDARY)
          .layoutWeight(1)
          .textAlign(TextAlign.End)
          .maxLines(1)
      }
      .width(Constant.PERCENT_FULL)
      Text(this.getOutfitDisplayName(index))
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text(`\u9700\u8981 ${this.outfitPrices[index]}\u79EF\u5206`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(this.ownedOutfits[index] ? UI_COLORS.TEXT_SECONDARY : UI_COLORS.ORANGE)
          .layoutWeight(1)
        Text(this.equippedOutfitIndex === index ? '\u5DF2\u4F69\u6234' : (this.ownedOutfits[index] ? '\u53EF\u4F69\u6234' : '\u672A\u62E5\u6709'))
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(this.equippedOutfitIndex === index ? UI_COLORS.PET_PURPLE :
            (this.ownedOutfits[index] ? UI_COLORS.MINT : UI_COLORS.TEXT_WEAK))
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text(this.ownedOutfits[index] ? '\u5DF2\u89E3\u9501' : '\u5151\u6362')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(this.canRedeemOutfit(index) ? Color.White : UI_COLORS.TEXT_SECONDARY)
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .padding({
            top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
            bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
          })
          .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
          .backgroundColor(this.canRedeemOutfit(index) ? UI_COLORS.ORANGE : '#F1F3F5')
          .onClick(() => {
            this.redeemOutfit(index);
          })
        Text(this.equippedOutfitIndex === index ? '\u4F69\u6234\u4E2D' : '\u4F69\u6234')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(this.ownedOutfits[index] ? Color.White : UI_COLORS.TEXT_SECONDARY)
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .padding({
            top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
            bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
          })
          .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
          .backgroundColor(this.equippedOutfitIndex === index ? UI_COLORS.PET_PURPLE :
            (this.ownedOutfits[index] ? UI_COLORS.MINT : '#F1F3F5'))
          .onClick(() => {
            this.equipOutfit(index);
          })
      }
        .width(Constant.PERCENT_FULL)
    }
    .width('48%')
    .margin({ right: STYLE_CONFIG.ICON_GUTTER, bottom: STYLE_CONFIG.ICON_GUTTER })
    .padding(14)
    .borderRadius(24)
    .backgroundColor(this.equippedOutfitIndex === index ? '#F7EEFF' : (this.ownedOutfits[index] ? '#FFFFFF' : '#FAFAFA'))
    .opacity(this.ownedOutfits[index] || this.score >= this.outfitPrices[index] ? 1 : 0.62)
    .border({
      width: this.equippedOutfitIndex === index ? 1 : 0,
      color: UI_COLORS.PET_PURPLE
    })
    .shadow({
      radius: this.equippedOutfitIndex === index ? 12 : 6,
      color: '#10000000',
      offsetX: 0,
      offsetY: 3
    })
  }

  @Builder
  petCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('\u5B66\u4E60\u4F19\u4F34')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
        this.moOutfitAvatar(128)
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
        this.petStagePill('\u86CB', this.getMoStageName() === '\u86CB')
        this.petStagePill('\u7834\u58F3', this.getMoStageName() === '\u7834\u58F3')
        this.petStagePill('\u5E7C\u5D3D', this.getMoStageName() === '\u5E7C\u5D3D')
        this.petStagePill('\u6210\u957F\u671F', this.getMoStageName() === '\u6210\u957F\u671F')
        this.petStagePill('\u5B66\u4E60\u4F19\u4F34', this.getMoStageName() === '\u5B66\u4E60\u4F19\u4F34')
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
      Text('\u771F\u5B9E\u6295\u9001\u72B6\u6001')
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
          .backgroundColor(this.lastDeliveryType === '\u6F14\u793A\u8BBE\u5907' ? UI_COLORS.TEXT_WEAK : UI_COLORS.MINT)
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
  deviceVerifyGuideCard() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text('\u771F\u673A\u9A8C\u8BC1\u6B65\u9AA4')
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
      this.deviceVerifyGuideCard()
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
      if (this.pendingTransferKind.length > 0) {
        this.receivedFreeFlowCard()
      }
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
                this.completeTaskByKey(itemKey);
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
      this.emptyPanel('\u25CC',
        this.getTotalCount() === 0 ? '\u8FD8\u6CA1\u6709\u4EFB\u52A1' : '\u6CA1\u6709\u5339\u914D\u7684\u5F85\u529E',
        this.getTotalCount() === 0 ? '\u70B9\u51FB + \u6DFB\u52A0\u4E00\u4E2A\u4EE3\u529E\u3002' :
          '\u6362\u4E2A\u5173\u952E\u8BCD\uFF0C\u6216\u56DE\u5230\u5168\u90E8\u4EFB\u52A1\u67E5\u770B\u3002')
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(24)
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
    if (this.isAddingTodo) {
      AddOrEditTodoForm({
        todoItem: this.addingTodoDraft,
        formMode: 'add',
        onSaveTodo: (todoItem: ToDo, name: string, focusMinutes: number, priority: number, deadlineOffset: number,
          category: string, repeatType: string, taskType: string, cardThemeIndex: number) => {
          this.saveNewTodoFromForm(todoItem, name, focusMinutes, priority, deadlineOffset, category, repeatType,
            taskType, cardThemeIndex);
        },
        onCancelEdit: () => {
          this.closeTodoEditor();
        }
      })
    } else if (this.editingTodoKey.length > 0 && this.getEditingTodo() !== null) {
      ForEach(this.toDoData.filter((item: ToDo) => item.key === this.editingTodoKey), (item: ToDo) => {
        AddOrEditTodoForm({
          todoItem: item,
          formMode: 'edit',
          onSaveTodo: (todoItem: ToDo, name: string, focusMinutes: number, priority: number, deadlineOffset: number,
            category: string, repeatType: string, taskType: string, cardThemeIndex: number) => {
            this.saveTodoFromEditor(todoItem, name, focusMinutes, priority, deadlineOffset, category, repeatType,
              taskType, cardThemeIndex);
          },
          onCancelEdit: () => {
            this.closeTodoEditor();
          }
        })
      }, (item: ToDo) => item.key)
    } else if (this.currentTab === 3) {
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
          if (this.pendingTransferKind.length > 0) {
            this.receivedFreeFlowCard()
          }
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
    if (this.isWideScreen) {
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
          if (this.focusTaskKey.length > 0) {
            this.continueFocusCard()
          }
          if (this.actionMenuTodoKey.length > 0 && this.getActionMenuTodo() !== undefined) {
            this.todoActionPanel(this.getActionMenuTodo() as ToDo)
          }
          this.homeTodoListCard()
        }
        .layoutWeight(58)
        .constraintSize({ maxWidth: 760 })
        .alignSelf(ItemAlign.Start)
        Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
          this.homeTabletOverviewPanel()
        }
        .layoutWeight(42)
        .constraintSize({ maxWidth: 430 })
        .alignSelf(ItemAlign.Start)
      }
      .width(Constant.PERCENT_FULL)
      .alignItems(VerticalAlign.Top)
    } else {
      Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        if (this.focusTaskKey.length > 0) {
          this.continueFocusCard()
        }
        if (this.actionMenuTodoKey.length > 0 && this.getActionMenuTodo() !== undefined) {
          this.todoActionPanel(this.getActionMenuTodo() as ToDo)
        }
        this.homeTodoListCard()
      }
      .width(Constant.PERCENT_FULL)
    }
  }

  @Builder
  homeTabletOverviewPanel() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.homeTabletTodayCard()
      this.countdownCard()
      this.petMiniCard()
      this.homeTabletQuickAddCard()
    }
    .width(Constant.PERCENT_FULL)
  }

  @Builder
  homeTabletTodayCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('\u4ECA\u65E5\u6982\u89C8')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        this.homeTabletMetric('\u4E13\u6CE8', `${this.todayFocusMinutes}\u5206`, UI_COLORS.FOCUS_BLUE, UI_COLORS.BLUE_LIGHT)
        this.homeTabletMetric('\u756A\u8304', `${this.todayPomodoroCount}`, UI_COLORS.ORANGE, UI_COLORS.CREAM_WHITE)
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        this.homeTabletMetric('\u5B8C\u6210', `${this.todayCompletedCount}`, UI_COLORS.MINT, UI_COLORS.MINT_LIGHT)
        this.homeTabletMetric('\u5269\u4F59', `${this.getUncompletedCount()}`, UI_COLORS.PET_PURPLE, UI_COLORS.PINK_LIGHT)
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
  homeTabletMetric(labelText: string, valueText: string, valueColor: ResourceColor, bgColor: ResourceColor) {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text(valueText)
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(valueColor)
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
      Text(labelText)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .maxLines(1)
    }
    .layoutWeight(1)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_MEDIUM)
    .backgroundColor(bgColor)
  }

  @Builder
  homeTabletQuickAddCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('\u5FEB\u6377\u65B0\u589E')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.sampleTaskNames, (taskName: string) => {
          this.sampleTaskButton(taskName)
        }, (taskName: string) => taskName)
      }
      .width(Constant.PERCENT_FULL)
      Text('\u751F\u6210\u793A\u4F8B\u6570\u636E')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .width(Constant.PERCENT_FULL)
        .padding({ top: 12, bottom: 12 })
        .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
        .backgroundColor(UI_COLORS.PET_PURPLE)
        .onClick(() => {
          this.generateSampleData();
        })
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor('#FFFBF4')
    .shadow({
      radius: 10,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 4
    })
  }

  getHomeTodos(): ToDo[] {
    let allItems = this.getAllTodos();
    allItems.sort((firstItem: ToDo, secondItem: ToDo) => {
      if (firstItem.isCompleted !== secondItem.isCompleted) {
        return Number(firstItem.isCompleted) - Number(secondItem.isCompleted);
      }
      if (firstItem.deadline > 0 && secondItem.deadline > 0) {
        return firstItem.deadline - secondItem.deadline;
      }
      if (firstItem.deadline > 0) {
        return -1;
      }
      if (secondItem.deadline > 0) {
        return 1;
      }
      return secondItem.createdAt - firstItem.createdAt;
    });
    return allItems;
  }

  @Builder
  homeTodoListCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text('\u4EE3\u529E')
          .fontSize($r('sys.float.ohos_id_text_size_headline8'))
          .fontColor(UI_COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
      }
      .width(Constant.PERCENT_FULL)
      if (this.getHomeTodos().length === 0) {
        this.homeTodoEmptyState()
      }
      ForEach(this.getHomeTodos(), (item: ToDo) => {
        TodoCard({
          todoItem: item,
          deadlineText: item.deadline > 0 ? this.getDeadlineText(item.deadline) : '\u65E0\u622A\u6B62\u65E5\u671F',
          onStart: (todoItem: ToDo) => {
            this.startFocus(todoItem, todoItem.plannedFocusMinutes);
          },
          onToggleComplete: (todoItem: ToDo) => {
            this.completeTaskByKey(todoItem.key);
          },
          onEdit: (todoItem: ToDo) => {
            this.showTodoActionMenu(todoItem);
          },
          onDelete: (todoItem: ToDo) => {
            this.showTodoActionMenu(todoItem);
          }
        })
      }, (item: ToDo) => `${item.key}_${item.isCompleted}`)
    }
    .width(Constant.PERCENT_FULL)
    .padding(22)
    .borderRadius(24)
    .backgroundColor('#FFFEFC')
    .shadow({
      radius: 16,
      color: '#10000000',
      offsetX: 0,
      offsetY: 6
    })
  }

  @Builder
  todoActionPanel(item: ToDo) {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Row() {
        Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
          Text('\u4EFB\u52A1\u64CD\u4F5C')
            .fontSize($r('sys.float.ohos_id_text_size_headline8'))
            .fontColor(UI_COLORS.TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
          Text(item.name)
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(UI_COLORS.TEXT_SECONDARY)
            .maxLines(1)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        Text('\u00D7')
          .fontSize(24)
          .fontColor(UI_COLORS.TEXT_SECONDARY)
          .onClick(() => {
            this.closeTodoActionMenu();
          })
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.todoSoftActionButton('\u270E', '\u7F16\u8F91', UI_COLORS.BLUE_LIGHT, UI_COLORS.FOCUS_BLUE, () => {
          this.closeTodoActionMenu();
          this.openTodoEditor(item);
        })
        this.todoSoftActionButton('\u2191', '\u7F6E\u9876', UI_COLORS.CREAM_WHITE, UI_COLORS.ORANGE, () => {
          this.pinTodoItem(item);
        })
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.todoSoftActionButton('\u2713', item.isCompleted ? '\u53D6\u6D88\u5B8C\u6210' : '\u5B8C\u6210',
          UI_COLORS.MINT_LIGHT, UI_COLORS.MINT, () => {
          this.closeTodoActionMenu();
          this.completeTaskByKey(item.key);
        })
        this.todoSoftActionButton('\u232B', '\u5220\u9664', '#FFF1F0', '#D94838', () => {
          this.closeTodoActionMenu();
          this.confirmDeleteItem(item);
        })
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.todoSoftActionButton('\u21C4', '\u6D41\u8F6C\u5230\u5176\u4ED6\u8BBE\u5907',
          UI_COLORS.BLUE_LIGHT, UI_COLORS.FOCUS_BLUE, () => {
          this.closeTodoActionMenu();
          this.showDeliveryPicker(item);
        })
      }
      .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor('#F8FFFFFF')
    .shadow({ radius: 18, color: UI_COLORS.CARD_SHADOW, offsetX: 0, offsetY: 8 })
  }

  @Builder
  todoSoftActionButton(iconText: string, labelText: string, backgroundColor: ResourceColor,
    textColor: ResourceColor, action: () => void) {
    Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text(iconText)
        .fontSize(20)
        .fontColor(textColor)
      Text(labelText)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(textColor)
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
    }
    .layoutWeight(1)
    .height(58)
    .justifyContent(FlexAlign.Center)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(backgroundColor)
    .onClick(action)
  }

  @Builder
  homeTodoEmptyState() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text('\u25CC')
        .fontSize(34)
        .fontColor(UI_COLORS.TEXT_WEAK)
      Text('\u8FD8\u6CA1\u6709\u4EFB\u52A1')
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .width(Constant.PERCENT_FULL)
      Text('\u53EF\u4EE5\u5148\u6DFB\u52A0\u4E00\u4E2A\u793A\u4F8B\u4EFB\u52A1\u3002')
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
        .width(Constant.PERCENT_FULL)
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.sampleTaskNames, (taskName: string) => {
          this.sampleTaskButton(taskName)
        }, (taskName: string) => taskName)
      }
      .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(22)
    .borderRadius(24)
    .backgroundColor('#FFFBF4')
  }

  @Builder
  sampleTaskButton(taskName: string) {
    Text(taskName)
      .fontSize($r('sys.float.ohos_id_text_size_body2'))
      .fontColor(Color.White)
      .fontWeight(FontWeight.Medium)
      .padding({
        left: STYLE_CONFIG.LIST_ITEM_GUTTER,
        right: STYLE_CONFIG.LIST_ITEM_GUTTER,
        top: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
        bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2
      })
      .margin({ right: STYLE_CONFIG.ICON_GUTTER, bottom: STYLE_CONFIG.ICON_GUTTER })
      .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
      .backgroundColor(this.getThemeColor())
      .onClick(() => {
        this.createSampleTodo(taskName);
      })
  }

  @Builder
  homeTodoCard(item: ToDo) {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
          Text(item.name)
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor(item.isCompleted ? UI_COLORS.TEXT_WEAK : UI_COLORS.TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
            .maxLines(2)
            .width(Constant.PERCENT_FULL)
          Text(`${item.focusDurationMinutes}\u5206\u949F\u4E13\u6CE8 \u00B7 ${item.deadline > 0 ? this.getDeadlineText(item.deadline) : '\u65E0\u622A\u6B62\u65E5\u671F'}`)
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(UI_COLORS.TEXT_SECONDARY)
            .maxLines(1)
            .width(Constant.PERCENT_FULL)
          Text(`\u5DF2\u4E13\u6CE8 ${item.focusCount}\u6B21 \u00B7 ${this.getPriorityName(item.priority)}`)
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(this.getDeadlineStatusColor(item.deadline, item.isCompleted))
            .maxLines(1)
            .width(Constant.PERCENT_FULL)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        Text(item.isCompleted ? '\u5DF2\u5B8C\u6210' : '\u5F00\u59CB')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .width(64)
          .height(36)
          .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
          .backgroundColor(item.isCompleted ? UI_COLORS.TEXT_WEAK : UI_COLORS.FOCUS_BLUE)
          .onClick(() => {
            if (!item.isCompleted) {
              this.startFocus(item, this.selectedFocusMinutes);
            }
          })
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        CommonPill({ pillLabel: item.isCompleted ? '\u53D6\u6D88\u5B8C\u6210' : '\u5B8C\u6210', pillTextColor: Color.White, pillBgColor: item.isCompleted ? UI_COLORS.TEXT_WEAK : UI_COLORS.MINT })
          .onClick(() => {
            this.completeTaskByKey(item.key);
          })
        CommonPill({ pillLabel: '\u8BE6\u60C5', pillTextColor: UI_COLORS.FOCUS_BLUE, pillBgColor: UI_COLORS.BLUE_LIGHT })
          .onClick(() => {
            this.showTodoDetail(item);
          })
        CommonPill({ pillLabel: '\u8C03\u6574', pillTextColor: UI_COLORS.PET_PURPLE, pillBgColor: UI_COLORS.PINK_LIGHT })
          .onClick(() => {
            this.showPriorityPicker(item);
          })
        CommonPill({ pillLabel: '\u5220\u9664', pillTextColor: '#D94838', pillBgColor: '#FFF1F0' })
          .onClick(() => {
            this.confirmDeleteItem(item);
          })
      }
      .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(item.isCompleted ? '#F6F6F6' : '#FFF8EE')
    .onClick(() => {
      this.showTodoDetail(item);
    })
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
          Text('\u4ECA\u5929\u4E5F\u6162\u6162\u5411\u524D\u5427')
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
        this.moOutfitAvatar(66)
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
    if (this.isWideScreen) {
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
          this.calendarMonthGridCard()
          this.calendarDeadlineOverview()
        }
        .layoutWeight(48)
        .constraintSize({ maxWidth: 560 })
        .alignSelf(ItemAlign.Start)
        Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
          this.selectedCalendarTasksCard()
          this.calendarGroupCard('\u6700\u8FD1 deadline', this.getUpcomingTodos())
          this.countdownCard()
        }
        .layoutWeight(52)
        .constraintSize({ maxWidth: 620 })
        .alignSelf(ItemAlign.Start)
      }
      .width(Constant.PERCENT_FULL)
      .alignItems(VerticalAlign.Top)
    } else {
      Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.calendarMonthGridCard()
        this.selectedCalendarTasksCard()
      }
      .width(Constant.PERCENT_FULL)
    }
  }

  @Builder
  calendarHeroCard() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text('\uD83D\uDCC5 \u5B66\u4E60\u65E5\u5386')
        .fontSize($r('sys.float.ohos_id_text_size_headline7'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Text('\u770B\u770B\u4EE3\u529E\u90FD\u5B89\u6392\u5728\u54EA\u4E9B\u65E5\u5B50')
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor('#F6F1FF')
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
      this.focusRoomAtmosphereLayer()
      this.focusRoomContentLayer()
    }
    .width(Constant.PERCENT_FULL)
    .height(Constant.PERCENT_FULL)
    .backgroundColor(this.getFocusRoomBackgroundColor())
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  focusRoomAtmosphereLayer() {
    Stack() {
      Column()
      .width(Constant.PERCENT_FULL)
      .height(Constant.PERCENT_FULL)
      .backgroundColor(this.getFocusRoomBackgroundColor())

      Row()
        .width(260)
        .height(260)
        .borderRadius(130)
        .backgroundColor('#1F6EA8FF')
        .position({ x: -76, y: 92 })
      Row()
        .width(220)
        .height(220)
        .borderRadius(110)
        .backgroundColor('#22BBD7FF')
        .position({ x: 210, y: 210 })
      Row()
        .width(150)
        .height(150)
        .borderRadius(75)
        .backgroundColor('#24FFD8A8')
        .position({ x: 42, y: 520 })

      this.focusRoomStar(32, 86, 3)
      this.focusRoomStar(88, 142, 2)
      this.focusRoomStar(278, 92, 2)
      this.focusRoomStar(318, 176, 3)
      this.focusRoomStar(46, 272, 2)
      this.focusRoomStar(238, 328, 2)
      this.focusRoomStar(330, 438, 2)
    }
    .width(Constant.PERCENT_FULL)
    .height(Constant.PERCENT_FULL)
  }

  @Builder
  focusRoomStar(left: number, top: number, size: number) {
    Row()
      .width(size)
      .height(size)
      .borderRadius(size)
      .backgroundColor('#CCFFFFFF')
      .position({ x: left, y: top })
  }

  @Builder
  focusRoomContentLayer() {
    Column() {
      Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text(this.currentFocusQuote.length > 0 ? this.currentFocusQuote : this.getTodayQuote())
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor('#F2FFFFFF')
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .maxLines(2)
          .width(Constant.PERCENT_FULL)
        Text(this.focusTaskKey.length > 0 ? this.getFocusTaskName() : '\u51C6\u5907\u8FDB\u5165\u4E13\u6CE8')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor('#AFFFFFFF')
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .width(Constant.PERCENT_FULL)
      }
      .width(Constant.PERCENT_FULL)
      .padding({ left: 18, right: 18, top: 12, bottom: 12 })
      .borderRadius(24)
      .backgroundColor('#16FFFFFF')
      if (this.focusTaskKey.length > 0 && !this.isFocusRunning && !this.isFocusFinished) {
        Text('\u5DF2\u6682\u505C')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor('#B8FFFFFF')
          .textAlign(TextAlign.Center)
          .width(Constant.PERCENT_FULL)
          .margin({ top: STYLE_CONFIG.ICON_GUTTER })
      }
      if (this.isFocusThemePanelVisible) {
        this.focusRoomThemePanel()
      }
      if (this.isFocusNoisePanelVisible) {
        this.focusRoomNoisePanel()
      }

      Blank()

      this.focusRoomTimerCore()

      this.focusRoomBuddyHint()

      Blank()

      this.focusRoomBottomActions()
    }
    .width(Constant.PERCENT_FULL)
    .height(Constant.PERCENT_FULL)
    .padding({
      left: STYLE_CONFIG.UI_CARD_PADDING,
      right: STYLE_CONFIG.UI_CARD_PADDING,
      top: STYLE_CONFIG.UI_CARD_PADDING * 2,
      bottom: STYLE_CONFIG.UI_CARD_PADDING * 2
    })
  }

  @Builder
  focusRoomTimerCore() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      if (this.focusClockStyleIndex === 1) {
        this.focusRoomMinimalClock()
      } else if (this.focusClockStyleIndex === 2) {
        this.focusRoomCardClock()
      } else {
        this.focusRoomRingClock()
      }

      Text(this.isFocusRunning ? '\u4E13\u6CE8\u4E2D' : (this.isFocusFinished ? '\u4E13\u6CE8\u5B8C\u6210' : '\u4F11\u606F\u4E00\u4E0B'))
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor('#AFFFFFFF')
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
        .maxLines(1)
    }
    .width(Constant.PERCENT_FULL)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  focusRoomRingClock() {
    Stack() {
      Row()
        .width(320)
        .height(320)
        .borderRadius(160)
        .border({ width: 2, color: '#28FFFFFF' })
      this.focusRoomClockText()
      Text(`${this.getFocusProgress()}%`)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(this.getFocusRoomAccentColor())
        .textAlign(TextAlign.Center)
        .position({ x: 136, y: 226 })
    }
    .width(320)
    .height(320)
  }

  @Builder
  focusRoomMinimalClock() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      this.focusRoomClockText()
      Text(`${this.getFocusProgress()}%`)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(this.getFocusRoomAccentColor())
    }
    .width(Constant.PERCENT_FULL)
    .padding({ top: 54, bottom: 54 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  focusRoomCardClock() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      this.focusRoomClockText()
      Text(`${this.getFocusProgress()}%`)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(this.getFocusRoomAccentColor())
    }
    .width(304)
    .padding({ top: 58, bottom: 58 })
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor('#24FFFFFF')
    .shadow({ radius: 24, color: '#44000000', offsetX: 0, offsetY: 10 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  focusRoomClockText() {
    Text(this.focusTaskKey.length > 0 ? this.formatFocusTime() : `${this.selectedFocusMinutes}:00`)
      .fontSize(86)
      .fontColor(Color.White)
      .fontWeight(FontWeight.Bold)
      .textAlign(TextAlign.Center)
  }

  @Builder
  focusRoomBuddyHint() {
    Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
      this.moOutfitAvatar(34)
      Text('\u5C0Fmo\u966A\u4F60')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor('#B8FFFFFF')
    }
    .justifyContent(FlexAlign.Center)
    .padding({ left: 14, right: 14, top: 8, bottom: 8 })
    .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
    .backgroundColor('#12FFFFFF')
  }

  @Builder
  focusRoomBottomActions() {
    if (this.focusTaskKey.length === 0) {
      Text('\u2190 \u56DE\u5230\u4EFB\u52A1\u9875')
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(Color.White)
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
        .width(Constant.PERCENT_FULL)
        .height(52)
        .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
        .backgroundColor('#28FFFFFF')
        .onClick(() => {
          this.exitFocusRoom();
        })
    } else if (this.isFocusFinished || this.focusRemainingSeconds === 0) {
      this.focusRoomPrimaryAction('\u2713 \u5B8C\u6210\u4E13\u6CE8', this.getFocusRoomAccentColor(), () => {
        this.completeFocus();
      })
    } else {
      Row() {
        this.focusRoomSideControl(true, () => {
          this.isFocusNoisePanelVisible = false;
          this.isFocusThemePanelVisible = !this.isFocusThemePanelVisible;
        })
        Blank()
        this.focusRoomTransferControl(() => {
          this.showFocusTransferDevicePicker();
        })
        Blank()
        Row({ space: 56 }) {
          this.focusRoomPauseResumeControl(() => {
            this.pauseOrResumeFocus();
          })
          this.focusRoomStopControl(() => {
            this.cancelFocus();
          })
        }
        Blank()
        this.focusRoomSideControl(false, () => {
          this.isFocusThemePanelVisible = false;
          this.isFocusNoisePanelVisible = !this.isFocusNoisePanelVisible;
        })
      }
      .width(Constant.PERCENT_FULL)
      .alignItems(VerticalAlign.Center)
    }
  }

  @Builder
  focusRoomTransferControl(action: () => void) {
    Text('\u6D41\u8F6C')
      .fontSize($r('sys.float.ohos_id_text_size_body2'))
      .fontColor('#DDE7FF')
      .fontWeight(FontWeight.Medium)
      .textAlign(TextAlign.Center)
      .width(54)
      .height(34)
      .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
      .backgroundColor('#18FFFFFF')
      .onClick(action)
  }

  @Builder
  focusRoomPauseResumeControl(action: () => void) {
    Stack() {
      if (this.isFocusRunning) {
        this.focusRoomPauseGlyph()
      } else {
        this.focusRoomPlayGlyph()
      }
    }
    .width(54)
    .height(54)
    .borderRadius(27)
    .backgroundColor('#00FFFFFF')
    .onClick(action)
  }

  @Builder
  focusRoomStopControl(action: () => void) {
    Stack() {
      Row()
        .width(20)
        .height(20)
        .borderRadius(4)
        .backgroundColor('#EFA5A5')
    }
    .width(54)
    .height(54)
    .borderRadius(27)
    .backgroundColor('#00FFFFFF')
    .onClick(action)
  }

  @Builder
  focusRoomPauseGlyph() {
    Row({ space: 6 }) {
      Row()
        .width(4)
        .height(23)
        .borderRadius(2)
        .backgroundColor('#F2FFFFFF')
      Row()
        .width(4)
        .height(23)
        .borderRadius(2)
        .backgroundColor('#F2FFFFFF')
    }
    .width(26)
    .height(26)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  focusRoomPlayGlyph() {
    Column({ space: 0 }) {
      Row().width(4).height(2).borderRadius(1).backgroundColor('#F2FFFFFF')
      Row().width(8).height(2).borderRadius(1).backgroundColor('#F2FFFFFF')
      Row().width(12).height(2).borderRadius(1).backgroundColor('#F2FFFFFF')
      Row().width(16).height(2).borderRadius(1).backgroundColor('#F2FFFFFF')
      Row().width(20).height(2).borderRadius(1).backgroundColor('#F2FFFFFF')
      Row().width(16).height(2).borderRadius(1).backgroundColor('#F2FFFFFF')
      Row().width(12).height(2).borderRadius(1).backgroundColor('#F2FFFFFF')
      Row().width(8).height(2).borderRadius(1).backgroundColor('#F2FFFFFF')
      Row().width(4).height(2).borderRadius(1).backgroundColor('#F2FFFFFF')
    }
    .width(24)
    .height(24)
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  focusRoomSideControl(isThemeControl: boolean, action: () => void) {
    Stack() {
      if (isThemeControl) {
        Row({ space: 3 }) {
          Row().width(5).height(5).borderRadius(3).backgroundColor('#88FFFFFF')
          Row().width(5).height(5).borderRadius(3).backgroundColor(this.getFocusRoomAccentColor())
          Row().width(5).height(5).borderRadius(3).backgroundColor('#66FFFFFF')
        }
      } else {
        Row({ space: 4 }) {
          Row().width(3).height(15).borderRadius(2).backgroundColor('#88FFFFFF')
          Row().width(3).height(21).borderRadius(2).backgroundColor('#88FFFFFF')
          Row().width(3).height(11).borderRadius(2).backgroundColor('#88FFFFFF')
        }
        .alignItems(VerticalAlign.Center)
      }
    }
    .width(40)
    .height(40)
    .borderRadius(20)
    .backgroundColor('#10FFFFFF')
    .opacity(0.72)
      .onClick(action)
  }

  @Builder
  focusRoomThemePanel() {
    Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
      ForEach(this.focusRoomNames, (themeName: string, index: number) => {
        Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
          Row()
            .width(index === this.focusThemeIndex ? 22 : 18)
            .height(index === this.focusThemeIndex ? 22 : 18)
            .borderRadius(11)
            .backgroundColor(this.focusRoomAccentColors[index])
            .border({
              width: index === this.focusThemeIndex ? 2 : 0,
              color: Color.White
            })
          Text(themeName)
            .fontSize(11)
            .fontColor(index === this.focusThemeIndex ? Color.White : '#C9D4F7')
            .maxLines(1)
        }
        .layoutWeight(1)
        .height(54)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.focusThemeIndex = index;
          this.isFocusThemePanelVisible = false;
          this.saveAppState();
        })
      }, (themeName: string) => themeName)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor('#24FFFFFF')
  }

  @Builder
  focusRoomNoisePanel() {
    Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
      ForEach(this.focusNoiseNames, (noiseName: string, index: number) => {
        Text(noiseName)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(index === this.focusNoiseIndex ? Color.White : '#C9D4F7')
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .height(38)
          .onClick(() => {
            this.focusNoiseIndex = index;
            this.isFocusNoisePanelVisible = false;
          })
      }, (noiseName: string) => noiseName)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.OPERATION_BUTTON_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor('#18FFFFFF')
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
      .shadow({ radius: 12, color: '#22000000', offsetX: 0, offsetY: 4 })
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
        this.saveAppState();
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
      this.moOutfitAvatar(58)
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
      if (this.getAvailableFocusTodos().length === 0) {
        Text('\u6682\u65E0\u53EF\u4E13\u6CE8\u4EFB\u52A1\uFF0C\u5148\u53BB\u4EFB\u52A1\u9875\u6DFB\u52A0\u4E00\u4E2A\u5C0F\u76EE\u6807')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor('#DDE7FF')
          .textAlign(TextAlign.Center)
          .width(Constant.PERCENT_FULL)
      }
      ForEach(this.getAvailableFocusTodos().slice(0, 3), (item: ToDo) => {
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
      if (this.getAvailableFocusTodos().length === 0) {
        Text('\u6682\u65E0\u53EF\u4E13\u6CE8\u7684\u4EFB\u52A1\uFF0C\u5148\u6DFB\u52A0\u4E00\u4E2A\u5C0F\u76EE\u6807\u5427')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.TEXT_SECONDARY)
          .width(Constant.PERCENT_FULL)
      }
      ForEach(this.getAvailableFocusTodos().slice(0, 4), (item: ToDo) => {
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
    if (this.isWideScreen) {
      Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.statisticsTodayMetrics()
        Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
          Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
            this.statisticsFocusTypeDonutCard()
          }
          .layoutWeight(48)
          .constraintSize({ maxWidth: 520 })
          .alignSelf(ItemAlign.Start)
          Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
            this.statisticsCumulativeCard()
            this.statisticsWeeklyTrendCard()
            this.statisticsMonthlyTrendCard()
            this.statisticsSummaryNoteCard()
          }
          .layoutWeight(52)
          .constraintSize({ maxWidth: 620 })
          .alignSelf(ItemAlign.Start)
        }
        .width(Constant.PERCENT_FULL)
        .alignItems(VerticalAlign.Top)
      }
      .width(Constant.PERCENT_FULL)
    } else {
      Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.statisticsTodayMetrics()
        this.statisticsCumulativeCard()
        this.statisticsFocusTypeDonutCard()
      }
      .width(Constant.PERCENT_FULL)
    }
  }

  getAvailableFocusTodos(): ToDo[] {
    return this.getAllTodos().filter((item: ToDo) => !item.isCompleted && item.taskType === 'focus');
  }

  getStatisticsFeedback(): string {
    if (this.todayFocusMinutes >= 60) {
      return '\u4ECA\u65E5\u4E13\u6CE8\u65F6\u957F\u5DF2\u8FBE 60 \u5206\u949F\u3002';
    }
    if (this.todayPomodoroCount >= 2) {
      return '\u4ECA\u65E5\u5DF2\u5B8C\u6210\u591A\u4E2A\u4E13\u6CE8\u6BB5\u3002';
    }
    if (this.todayCompletedCount >= 3) {
      return '\u4ECA\u65E5\u5DF2\u5B8C\u6210 3 \u4E2A\u4EE5\u4E0A\u4EFB\u52A1\u3002';
    }
    if (this.todayFocusMinutes > 0 || this.todayPomodoroCount > 0 || this.todayCompletedCount > 0) {
      return '\u4ECA\u65E5\u5DF2\u6709\u4EFB\u52A1\u6216\u4E13\u6CE8\u8BB0\u5F55\u3002';
    }
    return '\u5B8C\u6210\u4EFB\u52A1\u6216\u4E13\u6CE8\u540E\uFF0C\u8FD9\u91CC\u4F1A\u66F4\u65B0\u53CD\u9988\u3002';
  }

  getWeeklyPreviewValue(index: number): number {
    if (this.todayFocusMinutes === 0 && this.getTotalFocusMinutes() === 0) {
      return [8, 12, 10, 16, 14, 18, 0][index];
    }
    let seed = Math.max(this.todayFocusMinutes, Math.round(this.getTotalFocusMinutes() / 7));
    if (index === 6) {
      return this.todayFocusMinutes;
    }
    return Math.max(5, Math.round(seed * (index + 2) / 8));
  }

  getTrendBarHeight(value: number): number {
    if (value <= 0) {
      return 8;
    }
    return Math.min(96, Math.max(18, value + 14));
  }

  getTimeDistributionPercent(index: number): number {
    let total = Math.max(1, this.todayFocusMinutes + this.todayReadingMinutes + this.todayCompletedCount * 8);
    if (index === 0) {
      return Math.round(this.todayFocusMinutes * 100 / total);
    }
    if (index === 1) {
      return Math.round(this.todayReadingMinutes * 100 / total);
    }
    return Math.max(0, 100 - this.getTimeDistributionPercent(0) - this.getTimeDistributionPercent(1));
  }

  getFocusTaskShareColor(index: number): string {
    if (index === 0) {
      return '#E89AAF';
    }
    if (index === 1) {
      return '#9CBDE8';
    }
    if (index === 2) {
      return '#9FD7BF';
    }
    if (index === 3) {
      return '#F2C078';
    }
    if (index === 4) {
      return '#BFA7E6';
    }
    return '#D8C9B8';
  }

  getTaskFocusShareMinutes(item: ToDo): number {
    if (item.focusDurationMinutes > 0) {
      return item.focusDurationMinutes;
    }
    return item.focusCount * item.plannedFocusMinutes;
  }

  getTaskFocusShares(): FocusTaskShare[] {
    let taskNames: string[] = [];
    let taskMinutes: number[] = [];
    this.getAllTodos().forEach((item: ToDo) => {
      if (item.taskType !== 'focus') {
        return;
      }
      let minutes = this.getTaskFocusShareMinutes(item);
      if (minutes > 0) {
        let name = item.category.trim().length > 0 ? item.category.trim() : item.name;
        let matchedIndex = taskNames.indexOf(name);
        if (matchedIndex >= 0) {
          taskMinutes[matchedIndex] += minutes;
        } else {
          taskNames.push(name);
          taskMinutes.push(minutes);
        }
      }
    });
    let shares: FocusTaskShare[] = [];
    taskNames.forEach((name: string, index: number) => {
      shares.push({ name: name, minutes: taskMinutes[index] } as FocusTaskShare);
    });
    shares.sort((firstItem: FocusTaskShare, secondItem: FocusTaskShare) => secondItem.minutes - firstItem.minutes);
    if (shares.length <= 5) {
      return shares;
    }
    let visibleShares = shares.slice(0, 5);
    let otherMinutes = 0;
    shares.slice(5).forEach((item: FocusTaskShare) => {
      otherMinutes += item.minutes;
    });
    if (otherMinutes > 0) {
      visibleShares.push({ name: '\u5176\u4ED6', minutes: otherMinutes } as FocusTaskShare);
    }
    return visibleShares;
  }

  getTaskFocusShareTotalMinutes(): number {
    let totalMinutes = 0;
    this.getTaskFocusShares().forEach((item: FocusTaskShare) => {
      totalMinutes += item.minutes;
    });
    return totalMinutes;
  }

  getTaskFocusSharePercent(index: number): number {
    let totalMinutes = this.getTaskFocusShareTotalMinutes();
    if (totalMinutes <= 0) {
      return 0;
    }
    let shares = this.getTaskFocusShares();
    if (index < 0 || index >= shares.length) {
      return 0;
    }
    return Math.round(shares[index].minutes * 100 / totalMinutes);
  }

  drawFocusTaskPieChart() {
    let context = this.focusTaskPieContext;
    let shares = this.getTaskFocusShares();
    context.clearRect(0, 0, 180, 180);
    if (shares.length === 0) {
      context.beginPath();
      context.arc(90, 90, 72, 0, Math.PI * 2);
      context.fillStyle = '#F6DDE8';
      context.fill();
      return;
    }
    let totalMinutes = this.getTaskFocusShareTotalMinutes();
    let startAngle = -Math.PI / 2;
    shares.forEach((item: FocusTaskShare, index: number) => {
      let sweepAngle = Math.PI * 2 * item.minutes / totalMinutes;
      context.beginPath();
      context.moveTo(90, 90);
      context.arc(90, 90, 72, startAngle, startAngle + sweepAngle);
      context.closePath();
      context.fillStyle = this.getFocusTaskShareColor(index);
      context.fill();
      startAngle += sweepAngle;
    });
    context.beginPath();
    context.arc(90, 90, 72, 0, Math.PI * 2);
    context.strokeStyle = '#FFFFFFFF';
    context.lineWidth = 2;
    context.stroke();
  }

  @Builder
  statisticsHeroCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('\u6210\u957F\u6982\u89C8')
        .fontSize($r('sys.float.ohos_id_text_size_headline7'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Text(this.getStatisticsFeedback())
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.bannerPill(this.getTodayStudyMoodTitle(), UI_COLORS.PET_PURPLE, Color.White)
        this.bannerPill(`Lv.${this.getPetLevel()} ${this.getPetName()}`, UI_COLORS.ORANGE, Color.White)
      }
      .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor('#FFF1F5')
    .shadow({
      radius: 12,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 5
    })
  }

  @Builder
  statisticsTodayMetrics() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('\u4ECA\u65E5\u5B66\u4E60\u53CD\u9988')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.growthMetricCard('\u4ECA\u65E5\u4E13\u6CE8', `${this.todayFocusMinutes}\u5206`, UI_COLORS.FOCUS_BLUE, UI_COLORS.BLUE_LIGHT)
        this.growthMetricCard('\u4ECA\u65E5\u756A\u8304', `${this.todayPomodoroCount}`, UI_COLORS.ORANGE, UI_COLORS.CREAM_WHITE)
        this.growthMetricCard('\u5B8C\u6210\u4EFB\u52A1', `${this.todayCompletedCount}`, UI_COLORS.MINT, UI_COLORS.MINT_LIGHT)
      }
      .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
  }

  @Builder
  growthMetricCard(label: string, value: string, color: ResourceColor, cardBgColor: ResourceColor) {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text(value)
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(color)
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
      Text(label)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .maxLines(1)
    }
    .layoutWeight(1)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_MEDIUM)
    .backgroundColor(cardBgColor)
  }

  @Builder
  statisticsCumulativeCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('\u7D2F\u8BA1\u4E13\u6CE8')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.currentOutfitInfo('\u603B\u4E13\u6CE8', `${this.getTotalFocusMinutes()}\u5206`, UI_COLORS.FOCUS_BLUE)
        this.currentOutfitInfo('\u603B\u756A\u8304', `${this.getTotalFocusCount()}`, UI_COLORS.ORANGE)
      }
      .width(Constant.PERCENT_FULL)
      CommonProgressBar({ progressPercent: this.getCompletionRate(), progressBarColor: UI_COLORS.PET_PURPLE, progressTrackColor: UI_COLORS.PINK_LIGHT })
      Text(`\u4EFB\u52A1\u5B8C\u6210\u7387 ${this.getCompletionRate()}%\uFF0C\u6210\u957F\u7ECF\u9A8C ${this.petExp}`)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor('#FFF8EE')
  }

  @Builder
  statisticsFocusTypeDonutCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Row() {
        Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
          Text('\u5206\u7C7B\u4E13\u6CE8\u5360\u6BD4')
            .fontSize($r('sys.float.ohos_id_text_size_headline8'))
            .fontColor(UI_COLORS.TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
            .width(Constant.PERCENT_FULL)
          Text('\u6309\u4EFB\u52A1\u81EA\u52A8\u7EDF\u8BA1\u65F6\u95F4\u5206\u5E03')
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(UI_COLORS.TEXT_SECONDARY)
            .width(Constant.PERCENT_FULL)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        Text(`${this.getTaskFocusShareTotalMinutes()}\u5206`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.PET_PURPLE)
          .fontWeight(FontWeight.Medium)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
          .backgroundColor(UI_COLORS.PINK_LIGHT)
      }
      .width(Constant.PERCENT_FULL)
      if (this.getTaskFocusShareTotalMinutes() <= 0) {
        this.emptyPanel('\u25CC', '\u6CA1\u6709\u4E13\u6CE8\u6570\u636E',
          '\u5B8C\u6210\u4E13\u6CE8\u540E\u4F1A\u751F\u6210\u5206\u7C7B\u5360\u6BD4\u3002')
      } else {
        Row({ space: STYLE_CONFIG.UI_CARD_GUTTER }) {
          Stack() {
            Canvas(this.focusTaskPieContext)
              .width(188)
              .height(188)
              .onReady(() => {
                this.drawFocusTaskPieChart();
              })
            Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
              Text(`${this.getTaskFocusShareTotalMinutes()}`)
                .fontSize($r('sys.float.ohos_id_text_size_headline7'))
                .fontColor(UI_COLORS.TEXT_PRIMARY)
                .fontWeight(FontWeight.Bold)
              Text('\u603B\u5206\u949F')
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .fontColor(UI_COLORS.TEXT_SECONDARY)
            }
            .width(94)
            .height(94)
            .justifyContent(FlexAlign.Center)
            .borderRadius(47)
            .backgroundColor('#FDFBFF')
            .shadow({ radius: 12, color: '#10000000', offsetX: 0, offsetY: 4 })
          }
          .width(188)
          .height(188)
          Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
            ForEach(this.getTaskFocusShares(), (item: FocusTaskShare, index: number) => {
              this.focusTaskShareLegend(item, index)
            }, (item: FocusTaskShare) => item.name)
          }
          .layoutWeight(1)
          .padding({ top: STYLE_CONFIG.ICON_GUTTER })
        }
        .width(Constant.PERCENT_FULL)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor('#FFFEFC')
    .shadow({ radius: 10, color: UI_COLORS.CARD_SHADOW, offsetX: 0, offsetY: 4 })
  }

  @Builder
  emptyPanel(iconText: string, title: string, description: string) {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text(iconText)
        .fontSize(34)
        .fontColor(UI_COLORS.TEXT_WEAK)
      Text(title)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .width(Constant.PERCENT_FULL)
      Text(description)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
        .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor('#F7F4FF')
  }

  @Builder
  focusTaskShareLegend(item: FocusTaskShare, index: number) {
    Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Row()
        .width(10)
        .height(10)
        .borderRadius(5)
        .backgroundColor(this.getFocusTaskShareColor(index))
      Column({ space: 2 }) {
        Text(item.name)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
        Text(`${item.minutes}\u5206\u949F`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.TEXT_SECONDARY)
          .maxLines(1)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text(`${this.getTaskFocusSharePercent(index)}%`)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(this.getFocusTaskShareColor(index))
        .fontWeight(FontWeight.Bold)
    }
    .width(Constant.PERCENT_FULL)
    .padding({ left: 10, right: 10, top: 8, bottom: 8 })
    .borderRadius(STYLE_CONFIG.UI_RADIUS_MEDIUM)
    .backgroundColor('#F8F6FB')
  }

  @Builder
  statisticsWeeklyTrendCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Row() {
        Text('\u5468\u8D8B\u52BF\u9884\u89C8')
          .fontSize($r('sys.float.ohos_id_text_size_headline8'))
          .fontColor(UI_COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text('\u975E\u5386\u53F2\u8BB0\u5F55')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.TEXT_WEAK)
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        ForEach([0, 1, 2, 3, 4, 5, 6], (dayIndex: number) => {
          this.weekTrendBar(dayIndex)
        }, (dayIndex: number) => `${dayIndex}`)
      }
      .width(Constant.PERCENT_FULL)
      .height(118)
      .alignItems(VerticalAlign.Bottom)
      Text('\u6D45\u8272\u67F1\u5B50\u7528\u4E8E\u8282\u594F\u9884\u89C8\uFF0C\u4ECA\u65E5\u6570\u636E\u4F1A\u5728\u6700\u53F3\u4FA7\u66F4\u65B0\u3002')
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
  weekTrendBar(dayIndex: number) {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Blank()
      Row()
        .width(Constant.PERCENT_FULL)
        .height(this.getTrendBarHeight(this.getWeeklyPreviewValue(dayIndex)))
        .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
        .backgroundColor(dayIndex === 6 ? UI_COLORS.PET_PURPLE : '#F6DDE8')
      Text(dayIndex === 6 ? '\u4ECA' : `${dayIndex + 1}`)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(dayIndex === 6 ? UI_COLORS.PET_PURPLE : UI_COLORS.TEXT_WEAK)
        .textAlign(TextAlign.Center)
        .width(Constant.PERCENT_FULL)
    }
    .layoutWeight(1)
    .height(118)
  }

  @Builder
  statisticsMonthlyTrendCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('\u6708\u8D8B\u52BF')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      CommonProgressBar({ progressPercent: this.getPetProgress(), progressBarColor: UI_COLORS.ORANGE, progressTrackColor: UI_COLORS.CREAM_WHITE })
      Text(`\u672C\u6708\u6210\u957F\u611F\u6765\u81EA\uFF1A${this.score}\u79EF\u5206\u3001${this.petExp}\u7ECF\u9A8C\u3001${this.getCompletedCount()}\u4E2A\u5DF2\u5B8C\u6210\u4EFB\u52A1\u3002`)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor('#FFF1F5')
  }

  @Builder
  statisticsTimeDistributionCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('\u5B66\u4E60\u65F6\u6BB5\u5206\u5E03')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      this.distributionRow('\u4E13\u6CE8\u65F6\u95F4', this.getTimeDistributionPercent(0), UI_COLORS.FOCUS_BLUE)
      this.distributionRow('\u9605\u8BFB\u65F6\u95F4', this.getTimeDistributionPercent(1), UI_COLORS.MINT)
      this.distributionRow('\u4EFB\u52A1\u63A8\u8FDB', this.getTimeDistributionPercent(2), UI_COLORS.ORANGE)
      Text('\u57FA\u4E8E\u4ECA\u65E5\u4E13\u6CE8\u3001\u9605\u8BFB\u548C\u4EFB\u52A1\u5B8C\u6210\u6570\u751F\u6210\u3002')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_WEAK)
        .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
  }

  @Builder
  distributionRow(label: string, percent: number, color: ResourceColor) {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text(label)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.TEXT_SECONDARY)
          .layoutWeight(1)
        Text(`${percent}%`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(color)
      }
      .width(Constant.PERCENT_FULL)
      Row() {
        Row()
          .height(8)
          .width(`${percent}%`)
          .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
          .backgroundColor(color)
      }
      .width(Constant.PERCENT_FULL)
      .height(8)
      .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
      .backgroundColor('#F7EEF2')
    }
    .width(Constant.PERCENT_FULL)
  }

  @Builder
  statisticsSummaryNoteCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('\u5C0F\u603B\u7ED3')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Text(this.getStatisticsFeedback())
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
      Text(`\u63A8\u8350\uFF1A${this.getNextStepSuggestion()}`)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.FOCUS_BLUE)
        .width(Constant.PERCENT_FULL)
      Text('\u8FDB\u5165\u4E13\u6CE8\u72B6\u6001')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(Color.White)
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
        .width(Constant.PERCENT_FULL)
        .height(40)
        .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
        .backgroundColor(UI_COLORS.PET_PURPLE)
        .onClick(() => {
          this.currentTab = 3;
        })
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor('#FFF8EE')
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
    if (this.isWideScreen) {
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
          this.studyBuddySpaceHero()
          this.studyBuddyQuoteCard()
          this.currentOutfitCard()
          this.moRoomCard()
          this.moStageCard()
        }
        .layoutWeight(45)
        .constraintSize({ maxWidth: 560 })
        .alignSelf(ItemAlign.Start)
        Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
          this.studyBuddyTodayCard()
          this.outfitStore()
          this.moGrowthTasksCard()
          this.studyBuddyGrowthCard()
          this.moBadgeCard()
          this.studyBuddyInteractionCard()
        }
        .layoutWeight(55)
        .constraintSize({ maxWidth: 680 })
        .alignSelf(ItemAlign.Start)
      }
      .width(Constant.PERCENT_FULL)
      .alignItems(VerticalAlign.Top)
    } else {
      Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.studyBuddySpaceHero()
        this.studyBuddyTodayCard()
        this.studyBuddyQuoteCard()
        this.moGrowthTasksCard()
        this.outfitStore()
        this.moRoomCard()
        this.moStageCard()
        this.moBadgeCard()
        this.studyBuddyInteractionCard()
      }
      .width(Constant.PERCENT_FULL)
    }
  }

  getMoSceneHeight(): number {
    return this.isWideScreen ? 560 : 316;
  }

  getMoSceneActorSize(): number {
    let stageName = this.getMoStageName();
    if (stageName === '\u86CB' || stageName === '\u7834\u58F3') {
      return this.isWideScreen ? 304 : 146;
    }
    if (stageName === '\u5E7C\u5D3D') {
      return this.isWideScreen ? 302 : 142;
    }
    if (stageName === '\u5B66\u4E60\u4F19\u4F34') {
      return this.isWideScreen ? 328 : 132;
    }
    return this.isWideScreen ? 320 : 160;
  }

  @Builder
  moStudyRoomScene() {
    Stack({ alignContent: Alignment.Center }) {
      this.moStudyRoomBackground()
      Stack({ alignContent: Alignment.Center }) {
        Stack({ alignContent: Alignment.Center }) {
          if (this.getMoStageName() === '\u86CB' || this.getMoStageName() === '\u7834\u58F3') {
            this.moEggVisual(this.getMoSceneActorSize(), this.getMoStageName() === '\u7834\u58F3')
          } else if (this.getMoStageName() === '\u5B66\u4E60\u4F19\u4F34') {
            this.moSeatedBuddy(this.getMoSceneActorSize())
          } else {
            this.moRabbitBuddy(this.getMoSceneActorSize())
          }
        }
        .width(this.getMoSceneActorSize())
        .height(this.getMoSceneActorSize())
        .zIndex(2)
        Stack() {
          this.moSceneOutfitLayer(this.getMoSceneActorSize())
        }
      }
      .width(this.getMoSceneActorSize())
      .height(this.getMoSceneActorSize())
      .zIndex(3)
      .scale({ x: this.moSceneScale, y: this.moSceneScale })
      .rotate({ angle: this.moSceneRotate })
      .translate({ y: this.moSceneOffsetY })
      .animation({ duration: 760, curve: Curve.EaseInOut })
      .onClick(() => {
        this.popMoScene();
      })
    }
    .width(Constant.PERCENT_FULL)
    .height(this.getMoSceneHeight())
    .borderRadius(28)
    .clip(true)
  }

  @Builder
  moStudyRoomBackground() {
    Stack() {
      Column()
        .width(Constant.PERCENT_FULL)
        .height(this.getMoSceneHeight())
        .borderRadius(28)
        .backgroundColor(this.getStudyRoomColor(this.selectedStudyRoomIndex))
      Row()
        .width(this.isWideScreen ? 390 : 270)
        .height(this.isWideScreen ? 210 : 130)
        .borderRadius(34)
        .backgroundColor('#66FFFFFF')
        .position({ x: this.isWideScreen ? 28 : 18, y: this.isWideScreen ? 34 : 24 })
      Row()
        .width(this.isWideScreen ? 132 : 94)
        .height(this.isWideScreen ? 116 : 82)
        .borderRadius(18)
        .backgroundColor(this.selectedStudyRoomIndex === 1 ? '#38405F' : '#F8FCFF')
        .border({ width: 3, color: '#FFFFFFFF' })
        .position({ x: this.isWideScreen ? 250 : 188, y: this.isWideScreen ? 58 : 42 })
      Row()
        .width(this.isWideScreen ? 104 : 74)
        .height(4)
        .borderRadius(2)
        .backgroundColor(this.selectedStudyRoomIndex === 1 ? '#F4D27C' : '#BFD6EA')
        .position({ x: this.isWideScreen ? 264 : 198, y: this.isWideScreen ? 114 : 82 })
      if (this.selectedStudyRoomIndex === 2) {
        this.moRoomPlant(this.isWideScreen ? 46 : 36, this.isWideScreen ? 278 : 130, this.isWideScreen ? 1.5 : 1.1)
        this.moRoomPlant(this.isWideScreen ? 356 : 232, this.isWideScreen ? 286 : 138, this.isWideScreen ? 1.25 : 0.9)
      } else if (this.selectedStudyRoomIndex === 1) {
        this.moRoomStar(this.isWideScreen ? 280 : 208, this.isWideScreen ? 76 : 56)
        this.moRoomStar(this.isWideScreen ? 344 : 244, this.isWideScreen ? 98 : 72)
        this.moRoomStar(this.isWideScreen ? 314 : 224, this.isWideScreen ? 142 : 103)
      } else if (this.selectedStudyRoomIndex === 3) {
        Row()
          .width(this.isWideScreen ? 58 : 36)
          .height(this.isWideScreen ? 58 : 36)
          .borderRadius(this.isWideScreen ? 29 : 18)
          .backgroundColor('#F4C57D')
          .position({ x: this.isWideScreen ? 310 : 218, y: this.isWideScreen ? 84 : 58 })
        Row()
          .width(this.isWideScreen ? 118 : 72)
          .height(6)
          .borderRadius(3)
          .backgroundColor('#F4C57D')
          .opacity(0.32)
          .position({ x: this.isWideScreen ? 278 : 200, y: this.isWideScreen ? 148 : 98 })
      } else if (this.equippedOutfitIndex === 4) {
        this.moRoomShelf(this.isWideScreen ? 54 : 42, this.isWideScreen ? 90 : 46)
      } else {
        this.moRoomShelf(this.isWideScreen ? 54 : 38, this.isWideScreen ? 98 : 54)
        this.moRoomPlant(this.isWideScreen ? 350 : 236, this.isWideScreen ? 286 : 138, this.isWideScreen ? 1.15 : 0.8)
      }
      Row()
        .width(this.isWideScreen ? 180 : 120)
        .height(this.isWideScreen ? 16 : 12)
        .borderRadius(6)
        .backgroundColor(this.getStudyRoomAccentColor(this.selectedStudyRoomIndex))
        .opacity(0.34)
        .position({ x: this.isWideScreen ? 70 : 52, y: this.isWideScreen ? 170 : 112 })
      Row()
        .width(this.isWideScreen ? 326 : 232)
        .height(this.isWideScreen ? 78 : 56)
        .borderRadius(18)
        .backgroundColor(this.selectedStudyRoomIndex === 1 ? '#C7BEDF' : '#EAD4B5')
        .position({ x: this.isWideScreen ? 58 : 40, y: this.isWideScreen ? 392 : 198 })
      Row()
        .width(this.isWideScreen ? 360 : 250)
        .height(this.isWideScreen ? 24 : 18)
        .borderRadius(12)
        .backgroundColor(this.getStudyRoomAccentColor(this.selectedStudyRoomIndex))
        .opacity(0.78)
        .position({ x: this.isWideScreen ? 42 : 30, y: this.isWideScreen ? 382 : 192 })
      Row()
        .width(this.isWideScreen ? 32 : 24)
        .height(this.isWideScreen ? 82 : 58)
        .borderRadius(16)
        .backgroundColor('#D0B58E')
        .position({ x: this.isWideScreen ? 88 : 70, y: this.isWideScreen ? 438 : 234 })
      Row()
        .width(this.isWideScreen ? 32 : 24)
        .height(this.isWideScreen ? 82 : 58)
        .borderRadius(16)
        .backgroundColor('#D0B58E')
        .position({ x: this.isWideScreen ? 312 : 220, y: this.isWideScreen ? 438 : 234 })
      this.moRoomLamp(this.isWideScreen ? 76 : 64, this.isWideScreen ? 286 : 128)
      Row()
        .width(this.isWideScreen ? 92 : 66)
        .height(this.isWideScreen ? 18 : 14)
        .borderRadius(9)
        .backgroundColor('#F8F2E7')
        .position({ x: this.isWideScreen ? 270 : 172, y: this.isWideScreen ? 358 : 178 })
      Row()
        .width(this.isWideScreen ? 62 : 42)
        .height(this.isWideScreen ? 10 : 8)
        .borderRadius(5)
        .backgroundColor('#B8D4EF')
        .position({ x: this.isWideScreen ? 288 : 184, y: this.isWideScreen ? 344 : 168 })
    }
    .width(Constant.PERCENT_FULL)
    .height(this.getMoSceneHeight())
    .borderRadius(28)
  }

  @Builder
  moEggVisual(displaySize: number, cracked: boolean) {
    Stack() {
      Row()
        .width(displaySize * 0.72)
        .height(displaySize * 0.18)
        .borderRadius(displaySize * 0.09)
        .backgroundColor('#16000000')
        .position({ x: displaySize * 0.14, y: displaySize * 0.78 })
      Row()
        .width(displaySize * 0.64)
        .height(displaySize * 0.82)
        .borderRadius(displaySize * 0.32)
        .backgroundColor('#FFF3D7')
        .border({ width: 3, color: '#FFFFFFFF' })
        .position({ x: displaySize * 0.18, y: displaySize * 0.08 })
      Row()
        .width(displaySize * 0.16)
        .height(displaySize * 0.1)
        .borderRadius(displaySize * 0.05)
        .backgroundColor('#AAFFFFFF')
        .position({ x: displaySize * 0.34, y: displaySize * 0.18 })
      Row()
        .width(displaySize * 0.08)
        .height(displaySize * 0.05)
        .borderRadius(displaySize * 0.025)
        .backgroundColor('#AAFFFFFF')
        .position({ x: displaySize * 0.5, y: displaySize * 0.3 })
      if (cracked) {
        Row()
          .width(displaySize * 0.08)
          .height(displaySize * 0.32)
          .borderRadius(displaySize * 0.02)
          .backgroundColor('#C6A77B')
          .rotate({ angle: -28 })
          .position({ x: displaySize * 0.44, y: displaySize * 0.18 })
        Row()
          .width(displaySize * 0.08)
          .height(displaySize * 0.22)
          .borderRadius(displaySize * 0.02)
          .backgroundColor('#C6A77B')
          .rotate({ angle: 34 })
          .position({ x: displaySize * 0.51, y: displaySize * 0.42 })
      }
    }
    .width(displaySize)
    .height(displaySize)
  }

  @Builder
  moRabbitBuddy(displaySize: number) {
    Stack() {
      Row()
        .width(displaySize * 0.68)
        .height(displaySize * 0.1)
        .borderRadius(displaySize * 0.05)
        .backgroundColor('#16000000')
        .position({ x: displaySize * 0.16, y: displaySize * 0.88 })
      Row()
        .width(displaySize * 0.5)
        .height(displaySize * 0.38)
        .borderRadius(displaySize * 0.2)
        .backgroundColor('#F6E5D1')
        .position({ x: displaySize * 0.25, y: displaySize * 0.55 })
      Row()
        .width(displaySize * 0.16)
        .height(displaySize * 0.38)
        .borderRadius(displaySize * 0.08)
        .backgroundColor('#F6E5D1')
        .rotate({ angle: -16 })
        .position({ x: displaySize * 0.28, y: displaySize * 0.02 })
      Row()
        .width(displaySize * 0.16)
        .height(displaySize * 0.38)
        .borderRadius(displaySize * 0.08)
        .backgroundColor('#F6E5D1')
        .rotate({ angle: 16 })
        .position({ x: displaySize * 0.56, y: displaySize * 0.02 })
      Row()
        .width(displaySize * 0.1)
        .height(displaySize * 0.28)
        .borderRadius(displaySize * 0.05)
        .backgroundColor('#F4BFC5')
        .rotate({ angle: -16 })
        .position({ x: displaySize * 0.31, y: displaySize * 0.08 })
      Row()
        .width(displaySize * 0.1)
        .height(displaySize * 0.28)
        .borderRadius(displaySize * 0.05)
        .backgroundColor('#F4BFC5')
        .rotate({ angle: 16 })
        .position({ x: displaySize * 0.59, y: displaySize * 0.08 })
      Row()
        .width(displaySize * 0.62)
        .height(displaySize * 0.58)
        .borderRadius(displaySize * 0.31)
        .backgroundColor('#FFF1DE')
        .border({ width: 2, color: '#FFFFFFFF' })
        .position({ x: displaySize * 0.19, y: displaySize * 0.24 })
      Row()
        .width(displaySize * 0.09)
        .height(displaySize * 0.09)
        .borderRadius(displaySize * 0.045)
        .backgroundColor('#34323A')
        .position({ x: displaySize * 0.36, y: displaySize * 0.47 })
      Row()
        .width(displaySize * 0.09)
        .height(displaySize * 0.09)
        .borderRadius(displaySize * 0.045)
        .backgroundColor('#34323A')
        .position({ x: displaySize * 0.56, y: displaySize * 0.47 })
      Row()
        .width(displaySize * 0.08)
        .height(displaySize * 0.055)
        .borderRadius(displaySize * 0.028)
        .backgroundColor('#E7A0AA')
        .position({ x: displaySize * 0.46, y: displaySize * 0.57 })
      Row()
        .width(displaySize * 0.14)
        .height(displaySize * 0.025)
        .borderRadius(displaySize * 0.013)
        .backgroundColor('#A85F67')
        .position({ x: displaySize * 0.43, y: displaySize * 0.65 })
      Row()
        .width(displaySize * 0.1)
        .height(displaySize * 0.06)
        .borderRadius(displaySize * 0.03)
        .backgroundColor('#F7C2C8')
        .opacity(0.75)
        .position({ x: displaySize * 0.27, y: displaySize * 0.59 })
      Row()
        .width(displaySize * 0.1)
        .height(displaySize * 0.06)
        .borderRadius(displaySize * 0.03)
        .backgroundColor('#F7C2C8')
        .opacity(0.75)
        .position({ x: displaySize * 0.63, y: displaySize * 0.59 })
      this.moAnimalDecorations(displaySize)
    }
    .width(displaySize)
    .height(displaySize)
  }

  @Builder
  moSeatedBuddy(displaySize: number) {
    Stack() {
      this.moRabbitBuddy(displaySize)
      Row()
        .width(displaySize * 0.44)
        .height(displaySize * 0.18)
        .borderRadius(displaySize * 0.03)
        .backgroundColor('#F8F2E7')
        .border({ width: 1, color: '#FFFFFFFF' })
        .position({ x: displaySize * 0.28, y: displaySize * 0.7 })
      Row()
        .width(displaySize * 0.018)
        .height(displaySize * 0.16)
        .borderRadius(displaySize * 0.009)
        .backgroundColor('#B8D4EF')
        .position({ x: displaySize * 0.49, y: displaySize * 0.71 })
    }
    .width(displaySize)
    .height(displaySize)
  }

  @Builder
  moAnimalDecorations(displaySize: number) {
    if (this.equippedOutfitIndex === 0) {
      Row()
        .width(displaySize * 0.58)
        .height(displaySize * 0.105)
        .borderRadius(displaySize * 0.052)
        .backgroundColor('#D59B38')
        .border({ width: 1, color: '#FFFFF4D8' })
        .position({ x: displaySize * 0.21, y: displaySize * 0.735 })
      Row()
        .width(displaySize * 0.13)
        .height(displaySize * 0.2)
        .borderRadius(displaySize * 0.05)
        .backgroundColor('#C98F30')
        .rotate({ angle: 10 })
        .position({ x: displaySize * 0.61, y: displaySize * 0.8 })
    } else if (this.equippedOutfitIndex === 1) {
      Stack() {
        Row()
          .width(displaySize * 0.32)
          .height(displaySize * 0.12)
          .borderRadius(displaySize * 0.06)
          .backgroundColor('#8D84CE')
        Row()
          .width(displaySize * 0.08)
          .height(displaySize * 0.08)
          .borderRadius(displaySize * 0.02)
          .backgroundColor('#F5C86B')
          .rotate({ angle: 45 })
          .position({ x: displaySize * 0.12, y: displaySize * 0.02 })
      }
      .width(displaySize * 0.34)
      .height(displaySize * 0.14)
      .position({ x: displaySize * 0.33, y: displaySize * 0.23 })
    } else if (this.equippedOutfitIndex === 2) {
      Row()
        .width(displaySize * 0.24)
        .height(displaySize * 0.28)
        .borderRadius(displaySize * 0.06)
        .backgroundColor('#7CB894')
        .position({ x: displaySize * 0.64, y: displaySize * 0.62 })
    } else if (this.equippedOutfitIndex === 3) {
      Row()
        .width(displaySize * 0.16)
        .height(displaySize * 0.08)
        .borderRadius(displaySize * 0.04)
        .border({ width: 2, color: '#4F5B66' })
        .position({ x: displaySize * 0.32, y: displaySize * 0.47 })
      Row()
        .width(displaySize * 0.16)
        .height(displaySize * 0.08)
        .borderRadius(displaySize * 0.04)
        .border({ width: 2, color: '#4F5B66' })
        .position({ x: displaySize * 0.52, y: displaySize * 0.47 })
      Row()
        .width(displaySize * 0.06)
        .height(displaySize * 0.018)
        .borderRadius(displaySize * 0.009)
        .backgroundColor('#4F5B66')
        .position({ x: displaySize * 0.47, y: displaySize * 0.5 })
    } else if (this.equippedOutfitIndex === 4) {
      Row()
        .width(displaySize * 0.18)
        .height(displaySize * 0.18)
        .borderRadius(displaySize * 0.09)
        .backgroundColor('#F5C86B')
        .border({ width: 2, color: '#FFFFFFFF' })
        .position({ x: displaySize * 0.66, y: displaySize * 0.67 })
    }
  }

  @Builder
  moSceneOutfitLayer(displaySize: number) {
    if (this.getMoStageName() === '\u86CB' || this.getMoStageName() === '\u7834\u58F3') {
      this.moEggOutfitDecoration(displaySize)
    } else {
      this.moBuddyOutfitDecoration(displaySize)
    }
  }

  @Builder
  moEggOutfitDecoration(displaySize: number) {
    if (this.equippedOutfitIndex === 0) {
      Row()
        .width(displaySize * 0.76)
        .height(displaySize * 0.14)
        .borderRadius(displaySize * 0.07)
        .backgroundColor('#D99D35')
        .border({ width: 2, color: '#FFFFF4D8' })
        .position({ x: displaySize * 0.12, y: displaySize * 0.56 })
      Row()
        .width(displaySize * 0.25)
        .height(displaySize * 0.14)
        .borderRadius(displaySize * 0.065)
        .backgroundColor('#C98F30')
        .rotate({ angle: -16 })
        .position({ x: displaySize * 0.56, y: displaySize * 0.665 })
      Row()
        .width(displaySize * 0.14)
        .height(displaySize * 0.3)
        .borderRadius(displaySize * 0.06)
        .backgroundColor('#D49A32')
        .position({ x: displaySize * 0.655, y: displaySize * 0.69 })
      Row()
        .width(displaySize * 0.12)
        .height(displaySize * 0.12)
        .borderRadius(displaySize * 0.06)
        .backgroundColor('#FFE8A8')
        .position({ x: displaySize * 0.28, y: displaySize * 0.568 })
    } else if (this.equippedOutfitIndex === 1) {
      Row()
        .width(displaySize * 0.2)
        .height(displaySize * 0.2)
        .borderRadius(displaySize * 0.05)
        .backgroundColor('#F5C86B')
        .border({ width: 2, color: '#FFFFFFFF' })
        .rotate({ angle: 45 })
        .position({ x: displaySize * 0.6, y: displaySize * 0.26 })
      Row()
        .width(displaySize * 0.24)
        .height(displaySize * 0.07)
        .borderRadius(displaySize * 0.035)
        .backgroundColor('#8D84CE')
        .position({ x: displaySize * 0.5, y: displaySize * 0.39 })
    } else if (this.equippedOutfitIndex === 2) {
      Row()
        .width(displaySize * 0.22)
        .height(displaySize * 0.26)
        .borderRadius(displaySize * 0.07)
        .backgroundColor('#7CB894')
        .border({ width: 2, color: '#FFFFFFFF' })
        .position({ x: displaySize * 0.68, y: displaySize * 0.54 })
      Row()
        .width(displaySize * 0.08)
        .height(displaySize * 0.16)
        .borderRadius(displaySize * 0.04)
        .backgroundColor('#5F9C78')
        .position({ x: displaySize * 0.73, y: displaySize * 0.58 })
    } else if (this.equippedOutfitIndex === 3) {
      Row()
        .width(displaySize * 0.17)
        .height(displaySize * 0.08)
        .borderRadius(displaySize * 0.04)
        .border({ width: 2, color: '#4F5B66' })
        .backgroundColor('#22FFFFFF')
        .position({ x: displaySize * 0.31, y: displaySize * 0.44 })
      Row()
        .width(displaySize * 0.17)
        .height(displaySize * 0.08)
        .borderRadius(displaySize * 0.04)
        .border({ width: 2, color: '#4F5B66' })
        .backgroundColor('#22FFFFFF')
        .position({ x: displaySize * 0.52, y: displaySize * 0.44 })
      Row()
        .width(displaySize * 0.06)
        .height(displaySize * 0.018)
        .borderRadius(displaySize * 0.009)
        .backgroundColor('#4F5B66')
        .position({ x: displaySize * 0.47, y: displaySize * 0.475 })
    } else if (this.equippedOutfitIndex === 4) {
      Row()
        .width(displaySize * 0.18)
        .height(displaySize * 0.18)
        .borderRadius(displaySize * 0.09)
        .backgroundColor('#F5C86B')
        .border({ width: 2, color: '#FFFFFFFF' })
        .position({ x: displaySize * 0.62, y: displaySize * 0.5 })
      Text('A')
        .fontSize(displaySize * 0.085)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .position({ x: displaySize * 0.67, y: displaySize * 0.525 })
    }
  }

  @Builder
  moBuddyOutfitDecoration(displaySize: number) {
    if (this.equippedOutfitIndex === 0) {
      Row()
        .width(displaySize * 0.82)
        .height(displaySize * 0.135)
        .borderRadius(displaySize * 0.068)
        .backgroundColor('#D99D35')
        .border({ width: 2, color: '#FFFFF4D8' })
        .position({ x: displaySize * 0.09, y: displaySize * 0.625 })
      Row()
        .width(displaySize * 0.27)
        .height(displaySize * 0.15)
        .borderRadius(displaySize * 0.065)
        .backgroundColor('#C98F30')
        .rotate({ angle: 18 })
        .position({ x: displaySize * 0.55, y: displaySize * 0.72 })
      Row()
        .width(displaySize * 0.14)
        .height(displaySize * 0.245)
        .borderRadius(displaySize * 0.06)
        .backgroundColor('#D49A32')
        .position({ x: displaySize * 0.66, y: displaySize * 0.735 })
      Row()
        .width(displaySize * 0.12)
        .height(displaySize * 0.12)
        .borderRadius(displaySize * 0.06)
        .backgroundColor('#FFE8A8')
        .position({ x: displaySize * 0.3, y: displaySize * 0.638 })
    } else if (this.equippedOutfitIndex === 1) {
      Stack() {
        Row()
          .width(displaySize * 0.32)
          .height(displaySize * 0.12)
          .borderRadius(displaySize * 0.06)
          .backgroundColor('#8D84CE')
        Row()
          .width(displaySize * 0.1)
          .height(displaySize * 0.1)
          .borderRadius(displaySize * 0.025)
          .backgroundColor('#F5C86B')
          .border({ width: 1, color: '#FFFFFFFF' })
          .rotate({ angle: 45 })
          .position({ x: displaySize * 0.12, y: displaySize * 0.01 })
      }
      .width(displaySize * 0.34)
      .height(displaySize * 0.14)
      .position({ x: displaySize * 0.33, y: displaySize * 0.2 })
    } else if (this.equippedOutfitIndex === 2) {
      Row()
        .width(displaySize * 0.24)
        .height(displaySize * 0.3)
        .borderRadius(displaySize * 0.07)
        .backgroundColor('#7CB894')
        .border({ width: 2, color: '#FFFFFFFF' })
        .position({ x: displaySize * 0.64, y: displaySize * 0.58 })
      Row()
        .width(displaySize * 0.07)
        .height(displaySize * 0.18)
        .borderRadius(displaySize * 0.035)
        .backgroundColor('#5F9C78')
        .position({ x: displaySize * 0.69, y: displaySize * 0.62 })
    } else if (this.equippedOutfitIndex === 3) {
      Row()
        .width(displaySize * 0.17)
        .height(displaySize * 0.08)
        .borderRadius(displaySize * 0.04)
        .border({ width: 2, color: '#4F5B66' })
        .backgroundColor('#22FFFFFF')
        .position({ x: displaySize * 0.31, y: displaySize * 0.465 })
      Row()
        .width(displaySize * 0.17)
        .height(displaySize * 0.08)
        .borderRadius(displaySize * 0.04)
        .border({ width: 2, color: '#4F5B66' })
        .backgroundColor('#22FFFFFF')
        .position({ x: displaySize * 0.52, y: displaySize * 0.465 })
      Row()
        .width(displaySize * 0.06)
        .height(displaySize * 0.018)
        .borderRadius(displaySize * 0.009)
        .backgroundColor('#4F5B66')
        .position({ x: displaySize * 0.47, y: displaySize * 0.5 })
    } else if (this.equippedOutfitIndex === 4) {
      Row()
        .width(displaySize * 0.18)
        .height(displaySize * 0.18)
        .borderRadius(displaySize * 0.09)
        .backgroundColor('#F5C86B')
        .border({ width: 2, color: '#FFFFFFFF' })
        .position({ x: displaySize * 0.62, y: displaySize * 0.68 })
      Text('A')
        .fontSize(displaySize * 0.085)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .position({ x: displaySize * 0.67, y: displaySize * 0.705 })
    }
  }

  @Builder
  moRoomLamp(x: number, y: number) {
    Row()
      .width(34)
      .height(24)
      .borderRadius(10)
      .backgroundColor('#F6D98A')
      .position({ x: x, y: y })
    Row()
      .width(8)
      .height(48)
      .borderRadius(4)
      .backgroundColor('#B9A17D')
      .position({ x: x + 13, y: y + 24 })
    Row()
      .width(48)
      .height(8)
      .borderRadius(4)
      .backgroundColor('#B9A17D')
      .position({ x: x - 7, y: y + 68 })
  }

  @Builder
  moRoomShelf(x: number, y: number) {
    Row()
      .width(112)
      .height(12)
      .borderRadius(6)
      .backgroundColor('#D7B990')
      .position({ x: x, y: y })
    Row()
      .width(18)
      .height(38)
      .borderRadius(5)
      .backgroundColor('#BFD6EA')
      .position({ x: x + 12, y: y - 32 })
    Row()
      .width(18)
      .height(32)
      .borderRadius(5)
      .backgroundColor('#F4CBB9')
      .position({ x: x + 36, y: y - 26 })
    Row()
      .width(18)
      .height(36)
      .borderRadius(5)
      .backgroundColor('#A9D6B2')
      .position({ x: x + 60, y: y - 30 })
  }

  @Builder
  moRoomPlant(x: number, y: number, scaleValue: number) {
    Row()
      .width(30 * scaleValue)
      .height(26 * scaleValue)
      .borderRadius(8 * scaleValue)
      .backgroundColor('#D7B990')
      .position({ x: x, y: y + 34 * scaleValue })
    Row()
      .width(28 * scaleValue)
      .height(44 * scaleValue)
      .borderRadius(14 * scaleValue)
      .backgroundColor('#7CB894')
      .rotate({ angle: -22 })
      .position({ x: x - 8 * scaleValue, y: y })
    Row()
      .width(28 * scaleValue)
      .height(44 * scaleValue)
      .borderRadius(14 * scaleValue)
      .backgroundColor('#8CC79B')
      .rotate({ angle: 24 })
      .position({ x: x + 12 * scaleValue, y: y + 2 * scaleValue })
  }

  @Builder
  moRoomStar(x: number, y: number) {
    Row()
      .width(8)
      .height(8)
      .borderRadius(4)
      .backgroundColor('#F6D98A')
      .position({ x: x, y: y })
  }

  @Builder
  moOutfitAvatar(displaySize: number) {
    Stack() {
      if (this.getMoStageName() === '\u86CB' || this.getMoStageName() === '\u7834\u58F3') {
        Stack() {
          this.moEggVisual(displaySize * 0.82, this.getMoStageName() === '\u7834\u58F3')
        }
        .width(displaySize * 0.82)
        .height(displaySize * 0.82)
        .position({ x: displaySize * 0.09, y: displaySize * 0.1 })
      } else {
        Stack() {
          this.moRabbitBuddy(displaySize * 0.86)
        }
        .width(displaySize * 0.86)
        .height(displaySize * 0.86)
        .position({ x: displaySize * 0.07, y: displaySize * 0.06 })
      }
    }
    .width(displaySize)
    .height(displaySize)
    .backgroundColor(this.getOutfitRoomBgColor(this.equippedOutfitIndex))
    .borderRadius(displaySize * 0.22)
  }

  @Builder
  moCartoonBuddy(displaySize: number) {
    Stack() {
      Row()
        .width(displaySize * 0.62)
        .height(displaySize * 0.08)
        .borderRadius(displaySize * 0.04)
        .backgroundColor('#18000000')
        .position({ x: displaySize * 0.19, y: displaySize * 0.9 })
      Row()
        .width(displaySize * 0.5)
        .height(displaySize * 0.24)
        .borderRadius(displaySize * 0.12)
        .backgroundColor('#EEF6EF')
        .position({ x: displaySize * 0.25, y: displaySize * 0.62 })
      Row()
        .width(displaySize * 0.4)
        .height(displaySize * 0.34)
        .borderRadius(displaySize * 0.16)
        .backgroundColor('#DCEEE2')
        .position({ x: displaySize * 0.3, y: displaySize * 0.5 })
      Row()
        .width(displaySize * 0.42)
        .height(displaySize * 0.1)
        .borderRadius(displaySize * 0.05)
        .backgroundColor('#F4E5CC')
        .position({ x: displaySize * 0.29, y: displaySize * 0.52 })
      Row()
        .width(displaySize * 0.18)
        .height(displaySize * 0.08)
        .borderRadius(displaySize * 0.04)
        .backgroundColor('#8CBFA7')
        .position({ x: displaySize * 0.41, y: displaySize * 0.62 })
      Row()
        .width(displaySize * 0.14)
        .height(displaySize * 0.24)
        .borderRadius(displaySize * 0.07)
        .backgroundColor('#ADCBB9')
        .rotate({ angle: -8 })
        .position({ x: displaySize * 0.34, y: displaySize * 0.78 })
      Row()
        .width(displaySize * 0.14)
        .height(displaySize * 0.24)
        .borderRadius(displaySize * 0.07)
        .backgroundColor('#ADCBB9')
        .rotate({ angle: 8 })
        .position({ x: displaySize * 0.52, y: displaySize * 0.78 })
      Row()
        .width(displaySize * 0.14)
        .height(displaySize * 0.08)
        .borderRadius(displaySize * 0.04)
        .backgroundColor('#F7F0E4')
        .position({ x: displaySize * 0.33, y: displaySize * 0.88 })
      Row()
        .width(displaySize * 0.14)
        .height(displaySize * 0.08)
        .borderRadius(displaySize * 0.04)
        .backgroundColor('#F7F0E4')
        .position({ x: displaySize * 0.53, y: displaySize * 0.88 })
      this.moCartoonArms(displaySize, this.getMoExpressionState())
      Row()
        .width(displaySize * 0.68)
        .height(displaySize * 0.64)
        .borderRadius(displaySize * 0.32)
        .backgroundColor('#F8DDBB')
        .position({ x: displaySize * 0.16, y: displaySize * 0.08 })
      Row()
        .width(displaySize * 0.72)
        .height(displaySize * 0.28)
        .borderRadius(displaySize * 0.14)
        .backgroundColor('#D9B98D')
        .position({ x: displaySize * 0.14, y: displaySize * 0.05 })
      Row()
        .width(displaySize * 0.2)
        .height(displaySize * 0.22)
        .borderRadius(displaySize * 0.1)
        .backgroundColor('#D9B98D')
        .rotate({ angle: -18 })
        .position({ x: displaySize * 0.22, y: displaySize * 0.18 })
      Row()
        .width(displaySize * 0.18)
        .height(displaySize * 0.2)
        .borderRadius(displaySize * 0.09)
        .backgroundColor('#D9B98D')
        .rotate({ angle: 15 })
        .position({ x: displaySize * 0.41, y: displaySize * 0.13 })
      Row()
        .width(displaySize * 0.17)
        .height(displaySize * 0.2)
        .borderRadius(displaySize * 0.085)
        .backgroundColor('#D9B98D')
        .rotate({ angle: 24 })
        .position({ x: displaySize * 0.56, y: displaySize * 0.16 })
      Row()
        .width(displaySize * 0.08)
        .height(displaySize * 0.08)
        .borderRadius(displaySize * 0.04)
        .backgroundColor('#F3C8BA')
        .opacity(0.65)
        .position({ x: displaySize * 0.29, y: displaySize * 0.44 })
      Row()
        .width(displaySize * 0.08)
        .height(displaySize * 0.08)
        .borderRadius(displaySize * 0.04)
        .backgroundColor('#F3C8BA')
        .opacity(0.65)
        .position({ x: displaySize * 0.63, y: displaySize * 0.44 })
      this.moCartoonEyes(displaySize, this.getMoExpressionState())
      this.moCartoonMouth(displaySize, this.getMoExpressionState())
      if (this.getMoExpressionState() === 'achieve') {
        this.moStar(displaySize)
      }
      if (this.getMoExpressionState() === 'focus') {
        this.moDesk(displaySize)
      }
    }
    .width(displaySize)
    .height(displaySize)
  }

  @Builder
  moCartoonArms(displaySize: number, expressionState: string) {
    if (expressionState === 'happy') {
      Row()
        .width(displaySize * 0.12)
        .height(displaySize * 0.34)
        .borderRadius(displaySize * 0.06)
        .backgroundColor('#DCEEE2')
        .rotate({ angle: -34 })
        .position({ x: displaySize * 0.18, y: displaySize * 0.48 })
      Row()
        .width(displaySize * 0.1)
        .height(displaySize * 0.1)
        .borderRadius(displaySize * 0.05)
        .backgroundColor('#F8DDBB')
        .position({ x: displaySize * 0.13, y: displaySize * 0.38 })
      Row()
        .width(displaySize * 0.12)
        .height(displaySize * 0.28)
        .borderRadius(displaySize * 0.06)
        .backgroundColor('#DCEEE2')
        .rotate({ angle: 22 })
        .position({ x: displaySize * 0.68, y: displaySize * 0.53 })
    } else if (expressionState === 'achieve') {
      Row()
        .width(displaySize * 0.11)
        .height(displaySize * 0.36)
        .borderRadius(displaySize * 0.055)
        .backgroundColor('#DCEEE2')
        .rotate({ angle: -28 })
        .position({ x: displaySize * 0.23, y: displaySize * 0.47 })
      Row()
        .width(displaySize * 0.11)
        .height(displaySize * 0.36)
        .borderRadius(displaySize * 0.055)
        .backgroundColor('#DCEEE2')
        .rotate({ angle: 30 })
        .position({ x: displaySize * 0.66, y: displaySize * 0.39 })
      Row()
        .width(displaySize * 0.1)
        .height(displaySize * 0.1)
        .borderRadius(displaySize * 0.05)
        .backgroundColor('#F8DDBB')
        .position({ x: displaySize * 0.76, y: displaySize * 0.32 })
    } else if (expressionState === 'focus') {
      Row()
        .width(displaySize * 0.22)
        .height(displaySize * 0.1)
        .borderRadius(displaySize * 0.05)
        .backgroundColor('#DCEEE2')
        .rotate({ angle: 6 })
        .position({ x: displaySize * 0.28, y: displaySize * 0.68 })
      Row()
        .width(displaySize * 0.22)
        .height(displaySize * 0.1)
        .borderRadius(displaySize * 0.05)
        .backgroundColor('#DCEEE2')
        .rotate({ angle: -6 })
        .position({ x: displaySize * 0.5, y: displaySize * 0.68 })
    } else {
      Row()
        .width(displaySize * 0.12)
        .height(displaySize * 0.3)
        .borderRadius(displaySize * 0.06)
        .backgroundColor('#DCEEE2')
        .rotate({ angle: -16 })
        .position({ x: displaySize * 0.2, y: displaySize * 0.52 })
      Row()
        .width(displaySize * 0.12)
        .height(displaySize * 0.3)
        .borderRadius(displaySize * 0.06)
        .backgroundColor('#DCEEE2')
        .rotate({ angle: 16 })
        .position({ x: displaySize * 0.68, y: displaySize * 0.52 })
      this.moBook(displaySize)
    }
  }

  @Builder
  moBook(displaySize: number) {
    Row()
      .width(displaySize * 0.34)
      .height(displaySize * 0.2)
      .borderRadius(displaySize * 0.025)
      .backgroundColor('#BBD3F2')
      .border({ width: 1, color: '#FFFFFFFF' })
      .position({ x: displaySize * 0.33, y: displaySize * 0.63 })
    Row()
      .width(displaySize * 0.018)
      .height(displaySize * 0.18)
      .borderRadius(displaySize * 0.009)
      .backgroundColor('#F7F0E4')
      .position({ x: displaySize * 0.49, y: displaySize * 0.64 })
  }

  @Builder
  moDesk(displaySize: number) {
    Row()
      .width(displaySize * 0.66)
      .height(displaySize * 0.1)
      .borderRadius(displaySize * 0.05)
      .backgroundColor('#EAD4B5')
      .position({ x: displaySize * 0.17, y: displaySize * 0.75 })
    Row()
      .width(displaySize * 0.3)
      .height(displaySize * 0.16)
      .borderRadius(displaySize * 0.025)
      .backgroundColor('#F8F2E7')
      .border({ width: 1, color: '#FFFFFFFF' })
      .position({ x: displaySize * 0.35, y: displaySize * 0.62 })
    Row()
      .width(displaySize * 0.12)
      .height(displaySize * 0.05)
      .borderRadius(displaySize * 0.025)
      .backgroundColor('#95BDE5')
      .position({ x: displaySize * 0.6, y: displaySize * 0.58 })
  }

  @Builder
  moStar(displaySize: number) {
    Stack() {
      Row()
        .width(displaySize * 0.16)
        .height(displaySize * 0.16)
        .borderRadius(displaySize * 0.025)
        .backgroundColor('#F5C86B')
        .rotate({ angle: 45 })
      Row()
        .width(displaySize * 0.16)
        .height(displaySize * 0.16)
        .borderRadius(displaySize * 0.025)
        .backgroundColor('#F5C86B')
    }
    .width(displaySize * 0.18)
    .height(displaySize * 0.18)
    .position({ x: displaySize * 0.79, y: displaySize * 0.25 })
  }

  @Builder
  moCartoonEyes(displaySize: number, expressionState: string) {
    if (expressionState === 'sleepy') {
      Row()
        .width(displaySize * 0.12)
        .height(displaySize * 0.018)
        .borderRadius(displaySize * 0.009)
        .backgroundColor('#3C3640')
        .position({ x: displaySize * 0.33, y: displaySize * 0.39 })
      Row()
        .width(displaySize * 0.12)
        .height(displaySize * 0.018)
        .borderRadius(displaySize * 0.009)
        .backgroundColor('#3C3640')
        .position({ x: displaySize * 0.55, y: displaySize * 0.39 })
    } else if (expressionState === 'serious' || expressionState === 'focus') {
      Row()
        .width(displaySize * 0.105)
        .height(displaySize * 0.04)
        .borderRadius(displaySize * 0.02)
        .backgroundColor('#3C3640')
        .position({ x: displaySize * 0.34, y: displaySize * 0.37 })
      Row()
        .width(displaySize * 0.105)
        .height(displaySize * 0.04)
        .borderRadius(displaySize * 0.02)
        .backgroundColor('#3C3640')
        .position({ x: displaySize * 0.56, y: displaySize * 0.37 })
    } else {
      Row()
        .width(displaySize * 0.11)
        .height(displaySize * 0.11)
        .borderRadius(displaySize * 0.055)
        .backgroundColor('#3C3640')
        .position({ x: displaySize * 0.34, y: displaySize * 0.34 })
      Row()
        .width(displaySize * 0.11)
        .height(displaySize * 0.11)
        .borderRadius(displaySize * 0.055)
        .backgroundColor('#3C3640')
        .position({ x: displaySize * 0.56, y: displaySize * 0.34 })
      Row()
        .width(displaySize * 0.035)
        .height(displaySize * 0.035)
        .borderRadius(displaySize * 0.018)
        .backgroundColor(Color.White)
        .position({ x: displaySize * 0.37, y: displaySize * 0.355 })
      Row()
        .width(displaySize * 0.035)
        .height(displaySize * 0.035)
        .borderRadius(displaySize * 0.018)
        .backgroundColor(Color.White)
        .position({ x: displaySize * 0.59, y: displaySize * 0.355 })
    }
  }

  @Builder
  moCartoonMouth(displaySize: number, expressionState: string) {
    if (expressionState === 'happy' || expressionState === 'achieve') {
      Row()
        .width(displaySize * 0.16)
        .height(displaySize * 0.045)
        .borderRadius(displaySize * 0.023)
        .backgroundColor('#B86F64')
        .position({ x: displaySize * 0.42, y: displaySize * 0.49 })
    } else if (expressionState === 'sleepy') {
      Row()
        .width(displaySize * 0.14)
        .height(displaySize * 0.018)
        .borderRadius(displaySize * 0.009)
        .backgroundColor('#8B5C64')
        .position({ x: displaySize * 0.43, y: displaySize * 0.5 })
    } else if (expressionState === 'serious' || expressionState === 'focus') {
      Row()
        .width(displaySize * 0.13)
        .height(displaySize * 0.016)
        .borderRadius(displaySize * 0.008)
        .backgroundColor('#6B5B5B')
        .position({ x: displaySize * 0.435, y: displaySize * 0.5 })
    } else {
      Row()
        .width(displaySize * 0.14)
        .height(displaySize * 0.018)
        .borderRadius(displaySize * 0.009)
        .backgroundColor('#6B5B5B')
        .position({ x: displaySize * 0.43, y: displaySize * 0.47 })
    }
  }

  @Builder
  studyBuddySpaceHero() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.moStudyRoomScene()
      Text(this.getMoStageName())
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .width(Constant.PERCENT_FULL)
      Text(`\u201C${this.studyBuddyReply.length > 0 ? this.studyBuddyReply : this.getDailyCompanionQuote()}\u201D`)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Medium)
        .width(Constant.PERCENT_FULL)
        .padding({ left: 18, right: 18, top: 14, bottom: 14 })
        .borderRadius(24)
        .backgroundColor(Color.White)
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        this.moRoomInfoPill('\u7B49\u7EA7', `Lv.${this.getPetLevel()}`)
        this.moRoomInfoPill('\u7ECF\u9A8C', `${this.petExp}`)
        this.moRoomInfoPill('\u79EF\u5206', `${this.score}`)
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        this.moRoomInfoPill('\u5FC3\u60C5', this.getMoMoodName())
        this.moRoomInfoPill('\u88C5\u9970', this.getEquippedOutfitName())
      }
      .width(Constant.PERCENT_FULL)
      CommonProgressBar({ progressPercent: this.getPetProgress(), progressBarColor: UI_COLORS.PET_PURPLE, progressTrackColor: '#AAFFFFFF' })
    }
    .width(Constant.PERCENT_FULL)
    .padding(24)
    .borderRadius(28)
    .backgroundColor(this.getOutfitRoomBgColor(this.equippedOutfitIndex))
    .shadow({ radius: 22, color: '#12000000', offsetX: 0, offsetY: 8 })
  }

  @Builder
  moRoomInfoPill(labelText: string, valueText: string) {
    Column({ space: 2 }) {
      Text(labelText)
        .fontSize(10)
        .fontColor(UI_COLORS.TEXT_WEAK)
      Text(valueText)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
    }
    .layoutWeight(1)
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .borderRadius(18)
    .backgroundColor('#AAFFFFFF')
  }

  @Builder
  studyBuddyQuoteCard() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text('\u4ECA\u65E5\u966A\u4F34\u8BED')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Text(`\u201C${this.getDailyCompanionQuote()}\u201D`)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
        .padding({ left: 16, right: 16, top: 14, bottom: 14 })
        .borderRadius(24)
        .backgroundColor('#FFF8EE')
    }
    .width(Constant.PERCENT_FULL)
    .padding(22)
    .borderRadius(26)
    .backgroundColor(Color.White)
    .shadow({ radius: 16, color: '#10000000', offsetX: 0, offsetY: 6 })
  }

  @Builder
  moStageCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Row() {
        Text('\u5C0Fmo\u6210\u957F\u9636\u6BB5')
          .fontSize($r('sys.float.ohos_id_text_size_headline8'))
          .fontColor(UI_COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text(`Lv.${this.getPetLevel()}`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
          .backgroundColor(UI_COLORS.PET_PURPLE)
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.moStageInfo('\u5F53\u524D\u9636\u6BB5', this.getMoGrowthStageName(), UI_COLORS.PET_PURPLE)
        this.moStageInfo('\u4E0B\u4E00\u9636\u6BB5', this.getMoNextGrowthStageName(), UI_COLORS.ORANGE)
        this.moStageInfo('\u8FD8\u5DEE\u7B49\u7EA7', this.getMoGrowthStageGap() > 0 ? `${this.getMoGrowthStageGap()}\u7EA7` : '\u5DF2\u8FBE\u6210', UI_COLORS.MINT)
      }
      .width(Constant.PERCENT_FULL)
      CommonProgressBar({ progressPercent: this.getMoStageProgress(), progressBarColor: UI_COLORS.PET_PURPLE, progressTrackColor: UI_COLORS.PINK_LIGHT })
      Text(this.getMoGrowthStageText())
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(22)
    .borderRadius(26)
    .backgroundColor('#F7F2FF')
    .shadow({ radius: 16, color: '#10000000', offsetX: 0, offsetY: 6 })
  }

  @Builder
  moStageInfo(labelText: string, valueText: string, color: ResourceColor) {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text(labelText)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
      Text(valueText)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(color)
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
    }
    .layoutWeight(1)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius(20)
    .backgroundColor(Color.White)
  }

  @Builder
  moGrowthTasksCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Row() {
        Text('\u6210\u957F\u4EFB\u52A1')
          .fontSize($r('sys.float.ohos_id_text_size_headline8'))
          .fontColor(UI_COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text(this.getMoTodayCompanionText())
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.PET_PURPLE)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
          .backgroundColor(UI_COLORS.PINK_LIGHT)
      }
      .width(Constant.PERCENT_FULL)
      this.moGrowthTaskRow('\u5B8C\u6210\u4E00\u4E2A\u5F85\u529E', this.todayCompletedCount >= 1,
        `${this.todayCompletedCount} / 1`)
      this.moGrowthTaskRow('\u4E13\u6CE8 25 \u5206\u949F', this.todayFocusMinutes >= 25,
        `${Math.min(this.todayFocusMinutes, 25)} / 25\u5206`)
      this.moGrowthTaskRow('\u4ECA\u65E5\u6253\u5361', this.hasCheckedToday, this.hasCheckedToday ? '\u5DF2\u6253\u5361' : '\u672A\u6253\u5361')
    }
    .width(Constant.PERCENT_FULL)
    .padding(22)
    .borderRadius(26)
    .backgroundColor(Color.White)
    .shadow({ radius: 16, color: '#10000000', offsetX: 0, offsetY: 6 })
  }

  @Builder
  moGrowthTaskRow(taskName: string, finished: boolean, progressText: string) {
    Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text(finished ? '\u2713' : '\u25CB')
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(finished ? Color.White : UI_COLORS.TEXT_WEAK)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .width(28)
        .height(28)
        .borderRadius(14)
        .backgroundColor(finished ? UI_COLORS.MINT : '#F1F3F5')
      Text(taskName)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .maxLines(1)
      Text(progressText)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(finished ? UI_COLORS.MINT : UI_COLORS.TEXT_SECONDARY)
        .maxLines(1)
    }
    .width(Constant.PERCENT_FULL)
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .borderRadius(18)
    .backgroundColor(finished ? '#F0FAF4' : '#FAFAFA')
  }

  @Builder
  moRoomCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Row() {
        Text('\u623F\u95F4\u4E3B\u9898')
          .fontSize($r('sys.float.ohos_id_text_size_headline8'))
          .fontColor(UI_COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text(this.getStudyRoomName(this.selectedStudyRoomIndex))
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.PET_PURPLE)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
          .backgroundColor(UI_COLORS.PINK_LIGHT)
      }
      .width(Constant.PERCENT_FULL)
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach([0, 1, 2, 3], (roomIndex: number) => {
          this.studyRoomOption(roomIndex)
        }, (roomIndex: number) => `${roomIndex}`)
      }
      .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(22)
    .borderRadius(26)
    .backgroundColor(Color.White)
    .shadow({ radius: 16, color: '#10000000', offsetX: 0, offsetY: 6 })
  }

  @Builder
  studyRoomOption(roomIndex: number) {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Stack() {
        Row()
          .width(Constant.PERCENT_FULL)
          .height(52)
          .borderRadius(16)
          .backgroundColor(this.getStudyRoomColor(roomIndex))
        Row()
          .width(54)
          .height(16)
          .borderRadius(8)
          .backgroundColor(this.getStudyRoomAccentColor(roomIndex))
          .opacity(0.45)
          .position({ x: 16, y: 26 })
        Row()
          .width(26)
          .height(26)
          .borderRadius(13)
          .backgroundColor('#AAFFFFFF')
          .position({ x: 86, y: 12 })
      }
      .width(Constant.PERCENT_FULL)
      .height(52)
      Text(this.getStudyRoomName(roomIndex))
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
      Text(this.getStudyRoomTag(roomIndex))
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .maxLines(1)
      Text(this.selectedStudyRoomIndex === roomIndex ? '\u5F53\u524D\u4F7F\u7528' : '\u70B9\u51FB\u5207\u6362')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(this.selectedStudyRoomIndex === roomIndex ? this.getStudyRoomAccentColor(roomIndex) : UI_COLORS.TEXT_WEAK)
        .fontWeight(this.selectedStudyRoomIndex === roomIndex ? FontWeight.Medium : FontWeight.Regular)
    }
    .width('48%')
    .margin({ right: STYLE_CONFIG.ICON_GUTTER, bottom: STYLE_CONFIG.ICON_GUTTER })
    .padding(14)
    .borderRadius(22)
    .backgroundColor(this.selectedStudyRoomIndex === roomIndex ? '#FFFBF4' : '#FAFAFA')
    .border({
      width: this.selectedStudyRoomIndex === roomIndex ? 1 : 0,
      color: this.getStudyRoomAccentColor(roomIndex)
    })
      .onClick(() => {
        this.selectedStudyRoomIndex = roomIndex;
        this.saveAppState();
      })
  }

  @Builder
  moBadgeCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Row() {
        Text('\u6210\u5C31\u5899')
          .fontSize($r('sys.float.ohos_id_text_size_headline8'))
          .fontColor(UI_COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text(`${this.getMoAchievementCount()} / 6`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.ORANGE)
      }
      .width(Constant.PERCENT_FULL)
      Flex({ wrap: FlexWrap.Wrap }) {
        this.moBadgeItem('01', '\u9996\u6B21\u4E13\u6CE8', '\u756A\u8304\u22651\u6216\u4E13\u6CE8>0\u5206', this.isFirstFocusAchievementUnlocked())
        this.moBadgeItem('10', '\u5B8C\u621010\u4E2A\u4EFB\u52A1', '\u7D2F\u8BA1\u5B8C\u6210\u226510\u4E2A', this.getCompletedCount() >= 10)
        this.moBadgeItem('50', '\u5B8C\u621050\u4E2A\u4EFB\u52A1', '\u7D2F\u8BA1\u5B8C\u6210\u226550\u4E2A', this.getCompletedCount() >= 50)
        this.moBadgeItem('100', '\u4E13\u6CE8100\u5206\u949F', '\u7D2F\u8BA1\u4E13\u6CE8\u2265100\u5206', this.getTotalFocusMinutes() >= 100)
        this.moBadgeItem('3D', '\u8FDE\u7EED\u5B66\u4E603\u5929', '\u8FDE\u7EED\u5929\u6570\u22653', this.dailyGoalStreak >= 3)
        this.moBadgeItem('D1', '\u89E3\u9501\u7B2C\u4E00\u4E2A\u88C5\u626E', '\u5DF2\u62E5\u6709\u88C5\u626E>1', this.getOwnedOutfitCount() > 1)
      }
      .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(22)
    .borderRadius(26)
    .backgroundColor(Color.White)
    .shadow({ radius: 16, color: '#10000000', offsetX: 0, offsetY: 6 })
  }

  @Builder
  moBadgeItem(iconText: string, label: string, conditionText: string, unlocked: boolean) {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text(iconText)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(unlocked ? Color.White : UI_COLORS.TEXT_WEAK)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .width(42)
        .height(42)
        .borderRadius(21)
        .backgroundColor(unlocked ? UI_COLORS.PET_PURPLE : '#E5E7EB')
      Text(label)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(unlocked ? UI_COLORS.TEXT_PRIMARY : UI_COLORS.TEXT_WEAK)
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
      Text(unlocked ? '\u5DF2\u83B7\u5F97' : '\u672A\u83B7\u5F97')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(unlocked ? UI_COLORS.MINT : UI_COLORS.TEXT_WEAK)
      Text(conditionText)
        .fontSize(10)
        .fontColor(UI_COLORS.TEXT_WEAK)
        .maxLines(1)
    }
    .width('48%')
    .margin({ right: STYLE_CONFIG.ICON_GUTTER, bottom: STYLE_CONFIG.ICON_GUTTER })
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius(22)
    .backgroundColor(unlocked ? '#FFF8EE' : '#F4F5F6')
  }

  getMoAchievementCount(): number {
    let count = 0;
    if (this.isFirstFocusAchievementUnlocked()) {
      count += 1;
    }
    if (this.getCompletedCount() >= 10) {
      count += 1;
    }
    if (this.getCompletedCount() >= 50) {
      count += 1;
    }
    if (this.getTotalFocusMinutes() >= 100) {
      count += 1;
    }
    if (this.dailyGoalStreak >= 3) {
      count += 1;
    }
    if (this.getOwnedOutfitCount() > 1) {
      count += 1;
    }
    return count;
  }

  isFirstFocusAchievementUnlocked(): boolean {
    return this.getTotalFocusCount() >= 1 || this.getTotalFocusMinutes() > 0;
  }

  @Builder
  studyBuddyInteractionCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('\u548C\u5C0Fmo\u4E92\u52A8')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        this.moInteractionButton('\u6478\u6478\u5C0Fmo', UI_COLORS.MINT, () => {
          this.touchStudyBuddy();
        })
        this.moInteractionButton('\u6362\u4E00\u53E5\u8BDD', UI_COLORS.ORANGE, () => {
          this.touchStudyBuddy();
        })
        this.moInteractionButton('\u53BB\u6362\u88C5', UI_COLORS.PET_PURPLE, () => {
          this.studyBuddyReply = '\u8863\u6A71\u5C31\u5728\u4E0A\u65B9\uFF0C\u4ECA\u5929\u60F3\u6362\u54EA\u4E00\u5957\u5462\uFF1F';
        })
      }
      .width(Constant.PERCENT_FULL)
      Text(this.studyBuddyReply.length > 0 ? this.studyBuddyReply : '\u8F7B\u8F7B\u70B9\u4E00\u4E0B\uFF0C\u5C0Fmo\u4F1A\u56DE\u5E94\u4F60\u3002')
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .borderRadius(22)
        .backgroundColor('#F0FAF4')
    }
    .width(Constant.PERCENT_FULL)
    .padding(22)
    .borderRadius(26)
    .backgroundColor(Color.White)
    .shadow({ radius: 16, color: '#10000000', offsetX: 0, offsetY: 6 })
  }

  @Builder
  moInteractionButton(labelText: string, bgColor: ResourceColor, action: () => void) {
    Text(labelText)
      .fontSize($r('sys.float.ohos_id_text_size_body2'))
      .fontColor(Color.White)
      .fontWeight(FontWeight.Medium)
      .textAlign(TextAlign.Center)
      .layoutWeight(1)
      .padding({ top: 10, bottom: 10 })
      .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
      .backgroundColor(bgColor)
      .onClick(action)
  }

  @Builder
  studyBuddyTodayCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Row() {
        Text('\u4ECA\u65E5\u72B6\u6001')
          .fontSize($r('sys.float.ohos_id_text_size_headline8'))
          .fontColor(UI_COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text(this.getMoMoodName())
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
          .backgroundColor(this.getMoMoodColor())
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.studyBuddyMetric('\u25CC', '\u4ECA\u65E5\u4E13\u6CE8', this.todayFocusMinutes + '\u5206', UI_COLORS.FOCUS_BLUE)
        this.studyBuddyMetric('\u2713', '\u4ECA\u65E5\u5B8C\u6210', this.todayCompletedCount + '', UI_COLORS.MINT)
        this.studyBuddyMetric('\u25B3', '\u4ECA\u65E5\u756A\u8304', this.todayPomodoroCount + '', UI_COLORS.ORANGE)
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.currentOutfitInfo('\u4ECA\u65E5\u83B7\u5F97', `+${this.todayScoreGain}`, UI_COLORS.ORANGE)
        this.currentOutfitInfo('\u7D2F\u8BA1\u79EF\u5206', `${this.score}`, UI_COLORS.PET_PURPLE)
      }
      .width(Constant.PERCENT_FULL)
      Text(`\u6700\u8FD1\u83B7\u5F97\uFF1A${this.recentScoreSource}`)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(22)
    .borderRadius(24)
    .backgroundColor(Color.White)
    .shadow({ radius: 16, color: '#10000000', offsetX: 0, offsetY: 6 })
  }

  @Builder
  studyBuddyMetric(iconText: string, label: string, value: string, color: ResourceColor) {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text(iconText)
        .fontSize(22)
        .fontColor(color)
      Text(value)
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
      Text(label)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
    }
    .layoutWeight(1)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius(22)
    .backgroundColor('#FFFBF4')
  }

  @Builder
  studyBuddyGrowthCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Row() {
        Text('\u6210\u957F\u8FDB\u5EA6')
          .fontSize($r('sys.float.ohos_id_text_size_headline8'))
          .fontColor(UI_COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text(`Lv.${this.getPetLevel()}`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
          .backgroundColor(UI_COLORS.PET_PURPLE)
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.currentOutfitInfo('\u7ECF\u9A8C', this.petExp + '', UI_COLORS.ORANGE)
        this.currentOutfitInfo('\u8DDD\u4E0B\u4E00\u7EA7', this.getPetExpToNextLevel() === 0 ? '\u5DF2\u6EE1\u7EA7' : this.getPetExpToNextLevel() + '', UI_COLORS.PET_PURPLE)
        this.currentOutfitInfo('\u79EF\u5206', this.score + '', UI_COLORS.MINT)
      }
      .width(Constant.PERCENT_FULL)
      CommonProgressBar({ progressPercent: this.getPetProgress(), progressBarColor: UI_COLORS.PET_PURPLE, progressTrackColor: UI_COLORS.PINK_LIGHT })
      Text(this.getPetExpToNextLevel() === 0 ? '\u5DF2\u8FBE\u5230\u5F53\u524D\u6700\u9AD8\u7B49\u7EA7' : '\u518D\u6536\u96C6 ' + this.getPetExpToNextLevel() + ' \u7ECF\u9A8C\u5C31\u80FD\u5347\u7EA7')
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
      Text('\u966A\u4F34\u884C\u52A8')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        CommonPill({ pillLabel: '\u6253\u5361', pillTextColor: Color.White, pillBgColor: UI_COLORS.MINT })
          .onClick(() => { this.checkInToday(); })
        CommonPill({ pillLabel: '\u5F00\u59CB\u4E13\u6CE8', pillTextColor: Color.White, pillBgColor: UI_COLORS.FOCUS_BLUE })
          .onClick(() => { this.currentTab = 3; })
        CommonPill({ pillLabel: '\u8863\u67DC', pillTextColor: Color.White, pillBgColor: UI_COLORS.PET_PURPLE })
          .onClick(() => { this.showToastMessage('\u8863\u67DC\u5F00\u53D1\u4E2D'); })
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
      Text('\u5F53\u524D\u642D\u914D')
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
        this.currentOutfitInfo('\u4F19\u4F34\u7B49\u7EA7', `Lv.${this.getPetLevel()} ${this.getPetName()}`, UI_COLORS.MINT)
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
      this.deviceVerifyGuideCard()
      this.mockDeliveryNoteCard()
    }
    .width(Constant.PERCENT_FULL)
  }

  @Builder
  deviceHeroCard() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text('\u591A\u8BBE\u5907\u540C\u6B65')
        .fontSize($r('sys.float.ohos_id_text_size_headline7'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Text('\u4EFB\u52A1\u53EF\u4EE5\u5728\u53EF\u4FE1\u8BBE\u5907\u4E4B\u95F4\u771F\u5B9E\u6295\u9001')
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        this.bannerPill(`${this.discoveredDeviceCount}\u53F0\u8BBE\u5907`, UI_COLORS.FOCUS_BLUE, UI_COLORS.BLUE_LIGHT)
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
      Text('\u771F\u5B9E\u6295\u9001\u8BF4\u660E')
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
    if (this.isWideScreen) {
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
          this.profileSettingsCard()
          this.focusPreferencesCard()
          this.profileInfoCard()
          this.sampleDataCard()
          this.profileCrossDeviceCard()
          this.dataManagementCard()
          this.profileAboutPrivacyCard()
        }
        .layoutWeight(46)
        .constraintSize({ maxWidth: 560 })
        .alignSelf(ItemAlign.Start)
        Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
          this.profileTodayOverviewCard()
          this.profileBuddyCard()
          this.themeStore()
          this.profileEntryGrid()
        }
        .layoutWeight(54)
        .constraintSize({ maxWidth: 660 })
        .alignSelf(ItemAlign.Start)
      }
      .width(Constant.PERCENT_FULL)
      .alignItems(VerticalAlign.Top)
    } else {
      Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.profileSettingsCard()
        this.focusPreferencesCard()
        this.themeStore()
        this.profileInfoCard()
        this.sampleDataCard()
        this.profileCrossDeviceCard()
        this.dataManagementCard()
        this.profileAboutPrivacyCard()
      }
      .width(Constant.PERCENT_FULL)
    }
  }

  @Builder
  petSimpleMetricsCard() {
    Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.currentOutfitInfo('\u79EF\u5206', `${this.score}`, UI_COLORS.ORANGE)
      this.currentOutfitInfo('\u6210\u957F\u503C', `${this.petExp}`, UI_COLORS.PET_PURPLE)
    }
    .width(Constant.PERCENT_FULL)
  }

  @Builder
  petRoomAtmosphereCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Row() {
        Text('\u623F\u95F4\u6C1B\u56F4')
          .fontSize($r('sys.float.ohos_id_text_size_headline8'))
          .fontColor(UI_COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text('\u5C55\u793A')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.PET_PURPLE)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
          .backgroundColor(UI_COLORS.PINK_LIGHT)
      }
      .width(Constant.PERCENT_FULL)
      Text('\u9009\u4E00\u4E2A\u559C\u6B22\u7684\u5B66\u4E60\u573A\u666F\uFF0C\u5148\u4F5C\u4E3A\u6C1B\u56F4\u5C55\u793A\u3002')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
      Flex({ wrap: FlexWrap.Wrap }) {
        this.petRoomAtmosphereItem('\u2615', '\u5976\u6CB9\u4E66\u684C', '\u6E29\u67D4\u5F00\u59CB', UI_COLORS.CREAM_WHITE)
        this.petRoomAtmosphereItem('\uD83C\uDF19', '\u6DF1\u591C\u81EA\u4E60\u5BA4', '\u5B89\u9759\u6C89\u6D78', UI_COLORS.BLUE_LIGHT)
        this.petRoomAtmosphereItem('\u2600\uFE0F', '\u6E05\u6668\u7A97\u8FB9', '\u6E05\u65B0\u8F7B\u5FEB', UI_COLORS.MINT_LIGHT)
        this.petRoomAtmosphereItem('\u2728', '\u661F\u7A7A\u623F\u95F4', '\u653E\u677E\u6536\u5C3E', UI_COLORS.PINK_LIGHT)
      }
      .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(22)
    .borderRadius(24)
    .backgroundColor(Color.White)
    .shadow({ radius: 16, color: '#10000000', offsetX: 0, offsetY: 6 })
  }

  @Builder
  petRoomAtmosphereItem(iconText: string, title: string, subtitle: string, bgColor: ResourceColor) {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text(iconText)
        .fontSize(28)
      Text(title)
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
      Text(subtitle)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .maxLines(1)
    }
    .width('48%')
    .margin({ right: STYLE_CONFIG.ICON_GUTTER, bottom: STYLE_CONFIG.ICON_GUTTER })
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_MEDIUM)
    .backgroundColor(bgColor)
  }

  @Builder
  profileHeroCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('\uD83C\uDFE1 \u6211\u7684\u5B66\u4E60\u7A7A\u95F4')
        .fontSize($r('sys.float.ohos_id_text_size_headline7'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Text('\u4E3B\u9898\u3001\u6570\u636E\u548C\u540C\u6B65\u8BBE\u7F6E\u90FD\u6536\u5728\u8FD9\u91CC')
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
    .backgroundColor('#FFF8EE')
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
  profileSettingsCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('\u8BBE\u7F6E')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      this.deliveryStatusRow('\u5F53\u524D\u4E3B\u9898', this.themeNames[this.themeIndex])
      this.deliveryStatusRow('\u5B66\u4E60\u79F0\u53F7', this.getLearningTitle())
      this.deliveryStatusRow('\u4F19\u4F34\u7B49\u7EA7', `Lv.${this.getPetLevel()} ${this.getPetName()}`)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
  }

  @Builder
  focusPreferencesCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('\u4E13\u6CE8\u504F\u597D')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Text('\u4E13\u6CE8\u4E3B\u9898\u989C\u8272')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.focusRoomNames, (themeName: string, index: number) => {
          this.focusPreferencePill(themeName, index === this.focusThemeIndex, this.focusRoomAccentColors[index], () => {
            this.focusThemeIndex = index;
            this.saveAppState();
          })
        }, (themeName: string) => themeName)
      }
      .width(Constant.PERCENT_FULL)
      Text('\u65F6\u949F\u6837\u5F0F')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.focusClockStyleNames, (styleName: string, index: number) => {
          this.focusPreferencePill(styleName, index === this.focusClockStyleIndex, UI_COLORS.FOCUS_BLUE, () => {
            this.focusClockStyleIndex = index;
            this.saveAppState();
          })
        }, (styleName: string) => styleName)
      }
      .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(UI_COLORS.BLUE_LIGHT)
  }

  @Builder
  focusPreferencePill(label: string, isSelected: boolean, selectedColor: ResourceColor, action: () => void) {
    Text(label)
      .fontSize($r('sys.float.ohos_id_text_size_body2'))
      .fontColor(isSelected ? Color.White : UI_COLORS.TEXT_SECONDARY)
      .padding({
        left: STYLE_CONFIG.LIST_ITEM_GUTTER,
        right: STYLE_CONFIG.LIST_ITEM_GUTTER,
        top: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
        bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2
      })
      .margin({ right: STYLE_CONFIG.ICON_GUTTER, bottom: STYLE_CONFIG.ICON_GUTTER })
      .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
      .backgroundColor(isSelected ? selectedColor : Color.White)
      .onClick(action)
  }

  @Builder
  profileCrossDeviceCard() {
    Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text('\u8DE8\u8BBE\u5907')
          .fontSize($r('sys.float.ohos_id_text_size_headline8'))
          .fontColor(UI_COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .width(Constant.PERCENT_FULL)
        Text('\u4EFB\u52A1\u6295\u9001\u3001\u8BBE\u5907\u72B6\u6001\u548C\u540C\u6B65\u8BB0\u5F55')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.TEXT_SECONDARY)
          .width(Constant.PERCENT_FULL)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text('\u8FDB\u5165')
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
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(UI_COLORS.BLUE_LIGHT)
    .onClick(() => {
      this.currentTab = 6;
    })
  }

  @Builder
  profileAboutPrivacyCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('\u5173\u4E8E\u4E0E\u9690\u79C1')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      this.deliveryStatusRow('\u5173\u4E8E', '\u4E13\u6CE8\u3001\u4EFB\u52A1\u548C\u5C0Fmo\u966A\u4F34\u7684\u672C\u5730\u5B66\u4E60\u7A7A\u95F4')
      this.deliveryStatusRow('\u9690\u79C1\u8BF4\u660E', '\u6570\u636E\u4F18\u5148\u4FDD\u5B58\u5728\u672C\u5730\uFF0C\u8DE8\u8BBE\u5907\u4EC5\u5728\u4F60\u4E3B\u52A8\u6295\u9001\u65F6\u4F7F\u7528')
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor('#F6F1FF')
  }

  @Builder
  profileTodayOverviewCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('\u4ECA\u65E5\u6982\u89C8')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.currentOutfitInfo('\u4E13\u6CE8', `${this.todayFocusMinutes}\u5206`, UI_COLORS.FOCUS_BLUE)
        this.currentOutfitInfo('\u756A\u8304', `${this.todayPomodoroCount}`, UI_COLORS.ORANGE)
        this.currentOutfitInfo('\u4EFB\u52A1', `${this.todayCompletedCount}`, UI_COLORS.MINT)
      }
      .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
  }

  @Builder
  profileEntryGrid() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('\u6211\u7684\u5B66\u4E60\u7A7A\u95F4')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.profileEntryCard('\u5B66\u4E60\u7EDF\u8BA1', '\u8D8B\u52BF\u548C\u5706\u76D8\u56FE', UI_COLORS.PINK_LIGHT, () => {
          this.currentTab = 4;
        })
        this.profileEntryCard('\u5C0Fmo\u7A7A\u95F4', '\u4F19\u4F34\u548C\u88C5\u626E', UI_COLORS.MINT_LIGHT, () => {
          this.currentTab = 5;
        })
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.profileEntryCard('\u4E3B\u9898\u88C5\u626E', this.themeNames[this.themeIndex], UI_COLORS.CREAM_WHITE, () => {
          this.currentTab = 5;
        })
        this.profileEntryCard('\u8DE8\u8BBE\u5907', '\u6295\u9001\u4E0E\u540C\u6B65', UI_COLORS.BLUE_LIGHT, () => {
          this.currentTab = 6;
        })
      }
      .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
  }

  @Builder
  profileEntryCard(title: string, subtitle: string, cardBgColor: ResourceColor, action: () => void) {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text(title)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
      Text(subtitle)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .maxLines(1)
    }
    .layoutWeight(1)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_MEDIUM)
    .backgroundColor(cardBgColor)
    .onClick(action)
  }

  @Builder
  profileBuddyCard() {
    Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.moOutfitAvatar(70)
      Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text(`${this.getStudyBuddyName()} · Lv.${this.getPetLevel()}`)
          .fontSize($r('sys.float.ohos_id_text_size_headline8'))
          .fontColor(UI_COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
        Text(this.getStudyBuddyCompanionState())
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.MINT)
          .maxLines(1)
        Text(this.getStudyBuddyMessage())
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.TEXT_SECONDARY)
          .maxLines(2)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(UI_COLORS.MINT_LIGHT)
    .onClick(() => {
      this.currentTab = 5;
    })
  }

  @Builder
  petMiniCard() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text('\u5C0Fmo')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.moOutfitAvatar(68)
        Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
          Text(this.getStudyBuddyMood())
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor(UI_COLORS.MINT)
            .fontWeight(FontWeight.Medium)
          Text(this.getStudyBuddyMessage())
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(UI_COLORS.TEXT_SECONDARY)
            .maxLines(2)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      Text('\u8FDB\u5165\u5C0Fmo\u7A7A\u95F4')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(Color.White)
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
        .padding({
          top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
          bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
          left: STYLE_CONFIG.LIST_ITEM_GUTTER,
          right: STYLE_CONFIG.LIST_ITEM_GUTTER
        })
        .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
        .backgroundColor(UI_COLORS.PET_PURPLE)
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

  getCalendarMonthStartTime(): number {
    let dateValue = new Date();
    dateValue.setMonth(dateValue.getMonth() + this.calendarMonthOffset, 1);
    dateValue.setHours(0, 0, 0, 0);
    return dateValue.getTime();
  }

  getCalendarMonthTitle(): string {
    let dateValue = new Date(this.getCalendarMonthStartTime());
    return `${dateValue.getFullYear()}\u5E74${dateValue.getMonth() + 1}\u6708`;
  }

  getCalendarGridTimestamp(index: number): number {
    let monthStart = new Date(this.getCalendarMonthStartTime());
    let firstWeekday = monthStart.getDay();
    return this.getCalendarMonthStartTime() - firstWeekday * 24 * 60 * 60 * 1000 + index * 24 * 60 * 60 * 1000;
  }

  getSelectedCalendarStart(): number {
    if (this.selectedCalendarDate > 0) {
      return this.getStartOfDay(this.selectedCalendarDate);
    }
    if (this.calendarMonthOffset === 0) {
      return this.getTodayStart();
    }
    return this.getCalendarMonthStartTime();
  }

  isCalendarCurrentMonth(index: number): boolean {
    let cellDate = new Date(this.getCalendarGridTimestamp(index));
    let monthDate = new Date(this.getCalendarMonthStartTime());
    return cellDate.getFullYear() === monthDate.getFullYear() && cellDate.getMonth() === monthDate.getMonth();
  }

  isCalendarToday(index: number): boolean {
    return this.getStartOfDay(this.getCalendarGridTimestamp(index)) === this.getTodayStart();
  }

  isCalendarSelected(index: number): boolean {
    return this.getStartOfDay(this.getCalendarGridTimestamp(index)) === this.getSelectedCalendarStart();
  }

  getCalendarCellTextColor(index: number): ResourceColor {
    if (this.isCalendarSelected(index)) {
      return Color.White;
    }
    if (this.isCalendarToday(index)) {
      return this.getThemeColor();
    }
    if (!this.isCalendarCurrentMonth(index)) {
      return UI_COLORS.TEXT_WEAK;
    }
    return UI_COLORS.TEXT_PRIMARY;
  }

  getCalendarCellBgColor(index: number): ResourceColor {
    if (this.isCalendarSelected(index)) {
      return this.getThemeColor();
    }
    if (this.isCalendarToday(index)) {
      return this.getThemeLightColor();
    }
    return '#00FFFFFF';
  }

  getTodosByCalendarDate(timestamp: number): ToDo[] {
    let targetDay = this.getStartOfDay(timestamp);
    let items = this.getAllTodos().filter((item: ToDo) => item.deadline > 0 && this.getStartOfDay(item.deadline) === targetDay);
    items.sort((firstItem: ToDo, secondItem: ToDo) => {
      if (firstItem.isCompleted !== secondItem.isCompleted) {
        return Number(firstItem.isCompleted) - Number(secondItem.isCompleted);
      }
      return secondItem.priority - firstItem.priority;
    });
    return items;
  }

  getCalendarTaskCount(index: number): number {
    return this.getTodosByCalendarDate(this.getCalendarGridTimestamp(index)).length;
  }

  getCalendarOpenTaskCount(index: number): number {
    return this.getTodosByCalendarDate(this.getCalendarGridTimestamp(index))
      .filter((item: ToDo) => !item.isCompleted).length;
  }

  getCalendarDotColor(dayIndex: number, dotIndex: number): string {
    let items = this.getTodosByCalendarDate(this.getCalendarGridTimestamp(dayIndex));
    if (dotIndex < 0 || dotIndex >= items.length) {
      return STYLE_COLORS.LIGHT_GRAY_TEXT;
    }
    let item = items[dotIndex];
    if (item.isCompleted) {
      return STYLE_COLORS.LIGHT_GRAY_TEXT;
    }
    if (item.taskType === 'once') {
      return STYLE_COLORS.PRIORITY_LOW;
    }
    if (item.taskType === 'habit') {
      return STYLE_COLORS.ACCENT_GREEN;
    }
    return STYLE_COLORS.ACCENT_PURPLE;
  }

  getTaskTypeText(taskType: string): string {
    if (taskType === 'once') {
      return '\u4E00\u6B21\u6027';
    }
    if (taskType === 'habit') {
      return '\u4E60\u60EF';
    }
    return '\u4E13\u6CE8';
  }

  getTaskTypeColor(taskType: string): string {
    if (taskType === 'once') {
      return STYLE_COLORS.PRIORITY_LOW;
    }
    if (taskType === 'habit') {
      return STYLE_COLORS.ACCENT_GREEN;
    }
    return STYLE_COLORS.ACCENT_PURPLE;
  }

  getCountdownTodo(): ToDo | null {
    let items = this.getOpenTodosWithDeadline();
    if (items.length === 0) {
      return null;
    }
    return items[0];
  }

  getSelectedCalendarTitle(): string {
    let dateValue = new Date(this.getSelectedCalendarStart());
    if (this.getSelectedCalendarStart() === this.getTodayStart()) {
      return '\u4ECA\u5929\u7684\u4EE3\u529E';
    }
    return `${dateValue.getMonth() + 1}\u6708${dateValue.getDate()}\u65E5\u7684\u4EE3\u529E`;
  }

  getWeekdayLabel(index: number): string {
    let labels: string[] = ['\u65E5', '\u4E00', '\u4E8C', '\u4E09', '\u56DB', '\u4E94', '\u516D'];
    return labels[index];
  }

  @Builder
  countdownCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('\u6700\u8FD1\u5012\u8BA1\u65F6')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      if (this.getCountdownTodo() === null) {
        Text('\u8FD8\u6CA1\u6709\u5012\u8BA1\u65F6\u4EFB\u52A1\uFF0C\u7ED9\u4EE3\u529E\u8BBE\u7F6E\u622A\u6B62\u65E5\u671F\u5427\u3002')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.TEXT_SECONDARY)
          .width(Constant.PERCENT_FULL)
      } else {
        ForEach(this.getOpenTodosWithDeadline().slice(0, 1), (item: ToDo) => {
          this.countdownTaskCard(item)
        }, (item: ToDo) => item.key)
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
  countdownTaskCard(item: ToDo) {
    Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text(`\u8DDD\u79BB ${item.name}`)
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor(UI_COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .width(Constant.PERCENT_FULL)
        Text(`${this.getDeadlineDateText(item.deadline)} \u00B7 ${this.getDeadlineStatusNote(item.deadline)}`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.TEXT_SECONDARY)
          .maxLines(1)
          .width(Constant.PERCENT_FULL)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text(this.getDeadlineText(item.deadline))
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(Color.White)
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
        .padding({
          left: STYLE_CONFIG.LIST_ITEM_GUTTER,
          right: STYLE_CONFIG.LIST_ITEM_GUTTER,
          top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
          bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
        })
        .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
        .backgroundColor(this.getDeadlineStatusColor(item.deadline, item.isCompleted))
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor('#FFF8EE')
    .onClick(() => {
      this.showTodoDetail(item);
    })
  }

  @Builder
  calendarMonthGridCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        Text('\u2039')
          .fontSize(26)
          .fontColor(this.getThemeColor())
          .textAlign(TextAlign.Center)
          .width(36)
          .height(36)
          .borderRadius(18)
          .backgroundColor(this.getThemeLightColor())
          .onClick(() => {
            this.calendarMonthOffset -= 1;
            this.selectedCalendarDate = 0;
          })
        Text(this.getCalendarMonthTitle())
          .fontSize($r('sys.float.ohos_id_text_size_headline8'))
          .fontColor(UI_COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
        Text('\u203A')
          .fontSize(26)
          .fontColor(this.getThemeColor())
          .textAlign(TextAlign.Center)
          .width(36)
          .height(36)
          .borderRadius(18)
          .backgroundColor(this.getThemeLightColor())
          .onClick(() => {
            this.calendarMonthOffset += 1;
            this.selectedCalendarDate = 0;
          })
      }
      .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        ForEach([0, 1, 2, 3, 4, 5, 6], (weekdayIndex: number) => {
          Text(this.getWeekdayLabel(weekdayIndex))
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(UI_COLORS.TEXT_SECONDARY)
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
        }, (weekdayIndex: number) => `${weekdayIndex}`)
      }
      .width(Constant.PERCENT_FULL)
      Grid() {
        ForEach([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13,
          14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27,
          28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41], (dayIndex: number) => {
          GridItem() {
            this.calendarDayCell(dayIndex)
          }
        }, (dayIndex: number) => `${dayIndex}`)
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
      .rowsGap(STYLE_CONFIG.ICON_GUTTER)
      .columnsGap(STYLE_CONFIG.ICON_GUTTER)
      .width(Constant.PERCENT_FULL)
      .height(312)
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
  calendarDayCell(dayIndex: number) {
    Column({ space: 2 }) {
      Text(`${new Date(this.getCalendarGridTimestamp(dayIndex)).getDate()}`)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(this.getCalendarCellTextColor(dayIndex))
        .fontWeight(this.isCalendarToday(dayIndex) || this.isCalendarSelected(dayIndex) ? FontWeight.Bold : FontWeight.Regular)
        .textAlign(TextAlign.Center)
      Row({ space: 2 }) {
        ForEach([0, 1, 2], (dotIndex: number) => {
          if (dotIndex < this.getCalendarTaskCount(dayIndex)) {
            Row()
              .width(5)
              .height(5)
              .borderRadius(3)
              .backgroundColor(this.getCalendarDotColor(dayIndex, dotIndex))
          }
        }, (dotIndex: number) => `${dotIndex}`)
      }
      .height(10)
      .justifyContent(FlexAlign.Center)
      .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .height(44)
    .justifyContent(FlexAlign.Center)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_MEDIUM)
    .backgroundColor(this.getCalendarCellBgColor(dayIndex))
    .opacity(this.isCalendarCurrentMonth(dayIndex) ? 1 : 0.45)
    .onClick(() => {
      this.selectedCalendarDate = this.getCalendarGridTimestamp(dayIndex);
    })
  }

  @Builder
  selectedCalendarTasksCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Row() {
        Text(this.getSelectedCalendarTitle())
          .fontSize($r('sys.float.ohos_id_text_size_headline8'))
          .fontColor(UI_COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text(`${this.getTodosByCalendarDate(this.getSelectedCalendarStart()).length}`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(this.getThemeColor())
      }
      .width(Constant.PERCENT_FULL)
      if (this.getTodosByCalendarDate(this.getSelectedCalendarStart()).length === 0) {
        this.emptyPanel('\u25CC', '\u5F53\u5929\u6CA1\u6709\u4EFB\u52A1', '\u6709\u622A\u6B62\u65E5\u671F\u7684\u4EE3\u529E\u4F1A\u663E\u793A\u5728\u8FD9\u91CC\u3002')
      }
      ForEach(this.getTodosByCalendarDate(this.getSelectedCalendarStart()), (item: ToDo) => {
        this.calendarTaskRow(item)
      }, (item: ToDo) => `${item.key}_${item.isCompleted}`)
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
        this.emptyPanel('\u25CC', '\u6CA1\u6709\u8FD1\u671F\u622A\u6B62', '\u8BBE\u7F6E\u622A\u6B62\u65E5\u671F\u540E\u4F1A\u81EA\u52A8\u6C47\u603B\u3002')
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
        Text(`${this.getPriorityName(item.priority)} \u00B7 ${this.getDeadlineDateText(item.deadline)}`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.TEXT_SECONDARY)
        Text(this.getTaskTypeText(item.taskType))
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(this.getTaskTypeColor(item.taskType))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text(item.isCompleted ? '\u5DF2\u5B8C\u6210' : this.getDeadlineText(item.deadline))
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(this.getDeadlineStatusColor(item.deadline, item.isCompleted))
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
          .backgroundColor(this.getPriorityColor(item.priority))
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
      Text('\u6F14\u793A\u8BBE\u5907\u8BF4\u660E')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Text('\u6F14\u793A\u8BBE\u5907\u53EA\u4FDD\u5B58\u672C\u5730\u8BB0\u5F55\uFF0C\u4E0D\u4EE3\u8868\u771F\u5B9E\u8DE8\u8BBE\u5907\u6295\u9001\u6210\u529F\u3002')
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
      this.deliveryStatusRow('\u65E5\u7A0B\u72B6\u6001', '\u6309\u65E5\u671F\u81EA\u52A8\u91CD\u7F6E\u756A\u8304/\u76EE\u6807\u8FDB\u5EA6')
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
  sampleDataCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Row() {
        Text('\u793A\u4F8B\u6570\u636E')
          .fontSize($r('sys.float.ohos_id_text_size_headline8'))
          .fontColor(UI_COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text(this.hasSampleData() ? '\u5DF2\u751F\u6210' : '\u53EF\u751F\u6210')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(this.hasSampleData() ? UI_COLORS.MINT : UI_COLORS.PET_PURPLE)
      }
      .width(Constant.PERCENT_FULL)
      Text('\u7528\u4E8E\u5FEB\u901F\u586B\u5145\u4EFB\u52A1\u3001\u65E5\u5386\u3001\u7EDF\u8BA1\u548C\u5C0Fmo\u6210\u957F\uFF0C\u53EF\u968F\u65F6\u6E05\u7A7A\u3002')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text('\u751F\u6210\u793A\u4F8B\u6570\u636E')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .padding({ top: 12, bottom: 12 })
          .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
          .backgroundColor(UI_COLORS.PET_PURPLE)
          .onClick(() => {
            this.generateSampleData();
          })
        Text('\u6E05\u7A7A')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor('#D94838')
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .width(92)
          .padding({ top: 12, bottom: 12 })
          .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
          .backgroundColor('#FFF1F0')
          .onClick(() => {
            this.clearSampleData();
          })
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
  dataManagementCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('\uD83D\uDEE0 \u6570\u636E\u7BA1\u7406')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      this.deliveryStatusRow('\u672C\u5730\u4FDD\u5B58', '\u6570\u636E\u5DF2\u672C\u5730\u4FDD\u5B58')
      this.deliveryStatusRow('\u76EE\u6807\u65E5\u671F', this.dailyGoalDate.length > 0 ? this.dailyGoalDate : this.getTodayString())
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
        this.pageHeader()

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

  getPageHeaderTitle(): string {
    if (this.currentTab === 0) {
      return '\u4EE3\u529E';
    }
    if (this.currentTab === 1) {
      return '\u4EFB\u52A1\u6E05\u5355';
    }
    if (this.currentTab === 2) {
      return '\u65E5\u5386';
    }
    if (this.currentTab === 3) {
      return '\u4E13\u6CE8\u72B6\u6001';
    }
    if (this.currentTab === 4) {
      return '\u7EDF\u8BA1';
    }
    if (this.currentTab === 5) {
      return '\u5C0Fmo\u7A7A\u95F4';
    }
    if (this.currentTab === 6) {
      return '\u8DE8\u8BBE\u5907';
    }
    if (this.currentTab === 7) {
      return '\u6211\u7684';
    }
    return '\u4EE3\u529E';
  }

  getPageHeaderSubtitle(): string {
    if (this.currentTab === 0) {
      return `\u8FD8\u6709 ${this.getUncompletedCount()} \u4EF6\u4EE3\u529E\uFF0C\u70B9\u51FB\u4EFB\u52A1\u5F00\u59CB\u4E13\u6CE8`;
    }
    if (this.currentTab === 1) {
      return '\u6536\u62FE\u4EFB\u52A1\uFF0C\u4ECE\u4E00\u4EF6\u5C0F\u4E8B\u5F00\u59CB';
    }
    if (this.currentTab === 2) {
      return '\u622A\u6B62\u65E5\u3001\u5012\u8BA1\u65F6\u548C\u6708\u5386\u89C6\u56FE';
    }
    if (this.currentTab === 3) {
      return '\u9009\u4E00\u4E2A\u4EFB\u52A1\uFF0C\u518D\u8FDB\u5165\u6C89\u6D78\u4E13\u6CE8';
    }
    if (this.currentTab === 4) {
      return '\u4F60\u7684\u4E13\u6CE8\u6B63\u5728\u6162\u6162\u53D8\u6210\u6210\u957F';
    }
    if (this.currentTab === 5) {
      return '\u5C0Fmo\u966A\u4F60\u4E00\u8D77\u5B66\u4E60\u548C\u6210\u957F';
    }
    if (this.currentTab === 6) {
      return '\u4EFB\u52A1\u6295\u9001\u548C\u8BBE\u5907\u72B6\u6001';
    }
    if (this.currentTab === 7) {
      return '\u8BBE\u7F6E\u4E0E\u6570\u636E';
    }
    return this.getTodayDisplayText();
  }

  isTaskEntryPage(): boolean {
    return this.currentTab === 0 || this.currentTab === 1;
  }

  getPageHeaderBgColor(): ResourceColor {
    if (this.currentTab === 2) {
      return '#F6F1FF';
    }
    if (this.currentTab === 4) {
      return '#FFF1F5';
    }
    if (this.currentTab === 5) {
      return UI_COLORS.MINT_LIGHT;
    }
    if (this.currentTab === 7) {
      return UI_COLORS.CREAM_WHITE;
    }
    return Color.White;
  }

  isNavIndexSelected(index: number): boolean {
    if (index === 7) {
      return this.currentTab === 7 || this.currentTab === 6;
    }
    return this.currentTab === index;
  }

  @Builder
  pageHeader() {
    Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text(this.getPageHeaderTitle())
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(this.getThemeColor())
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
        .layoutWeight(1)
      if (this.isTaskEntryPage()) {
        Image($r('app.media.ic_public_add_filled'))
          .width(STYLE_CONFIG.MENU_IMAGE_SIZE)
          .aspectRatio(1)
          .onClick(() => {
            this.showAddTodoDialog();
          })
      }
    }
    .height(52)
    .width(Constant.PERCENT_FULL)
    .padding({
      left: STYLE_CONFIG.UI_CARD_PADDING,
      right: STYLE_CONFIG.UI_CARD_PADDING
    })
    .margin({
      left: STYLE_CONFIG.LIST_ITEM_GUTTER,
      right: STYLE_CONFIG.LIST_ITEM_GUTTER,
      top: STYLE_CONFIG.LIST_ITEM_GUTTER
    })
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(this.getPageHeaderBgColor())
    .shadow({
      radius: 8,
      color: '#0D0D1F18',
      offsetX: 0,
      offsetY: 2
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
      .height(62)
      .padding({
        left: STYLE_CONFIG.UI_NAV_PADDING,
        right: STYLE_CONFIG.UI_NAV_PADDING,
        top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
        bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
      })
      .margin({
        top: STYLE_CONFIG.ICON_GUTTER,
        bottom: STYLE_CONFIG.ICON_GUTTER
      })
      .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
      .backgroundColor('#FAFFFFFF')
      .border({
        width: 1,
        color: '#30FFFFFF'
      })
      .shadow({
        radius: 20,
        color: '#12000000',
        offsetX: 0,
        offsetY: 7
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
          .fontColor(this.isNavIndexSelected(index) ? Color.White : this.getThemeColor())
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
        .backgroundColor(this.isNavIndexSelected(index) ? this.getThemeColor() : this.getThemeLightColor())
        .width(Constant.PERCENT_FULL)
        .onClick(() => {
          this.currentTab = index;
        })
    } else {
      Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text(this.getTabIcon(index))
          .fontSize(this.isNavIndexSelected(index) ? 18 : 16)
          .fontColor(this.isNavIndexSelected(index) ? this.getThemeColor() : UI_COLORS.TEXT_WEAK)
        Text(label)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(this.isNavIndexSelected(index) ? this.getThemeColor() : UI_COLORS.TEXT_WEAK)
          .fontWeight(this.isNavIndexSelected(index) ? FontWeight.Medium : FontWeight.Regular)
          .maxLines(1)
      }
        .justifyContent(FlexAlign.Center)
        .padding({
          top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
          bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
        })
        .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
        .backgroundColor(this.isNavIndexSelected(index) ? this.getThemeLightColor() : '#00FFFFFF')
        .opacity(this.isNavIndexSelected(index) ? 1 : 0.76)
        .height(50)
        .layoutWeight(1)
        .onClick(() => {
          this.currentTab = index;
        })
    }
  }
}
