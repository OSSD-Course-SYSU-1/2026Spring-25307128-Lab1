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
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

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
  @State themeIndex: number = 0;
  @State hasCheckedToday: boolean = false;
  @State unlockedThemes: boolean[] = [true, true, false, false, false, false];
  @State lastDeliveryRecord: string = '\u6682\u65E0\u6295\u9001\u8BB0\u5F55';
  @State searchKeyword: string = '';
  @State sortIndex: number = 0;
  @State isWideScreen: boolean = false;
  @State focusTaskKey: string = '';
  @State focusRemainingSeconds: number = 0;
  @State focusTotalSeconds: number = 0;
  @State isFocusRunning: boolean = false;

  private focusTimer: number = -1;
  private themeNames: string[] = ['\u84DD\u8272', '\u7EFF\u8272', '\u7D2B\u8272', '\u6A59\u8272',
    '\u6A31\u82B1\u7C89', '\u661F\u7A7A\u9ED1'];
  private themeColors: string[] = ['#0A59F7', '#1E8E3E', '#7E3FF2', '#F57C00', '#E85D9E', '#222831'];
  private themeLightColors: string[] = ['#EAF1FF', '#EAF7EE', '#F1EAFF', '#FFF3E0', '#FFF0F6', '#ECEFF3'];
  private themePrices: number[] = [0, 0, 50, 80, 120, 200];
  private deliveryDevices: string[] = ['\u624B\u673A', '\u5E73\u677F', '\u667A\u6167\u5C4F', '\u7535\u8111'];
  private sortNames: string[] = ['\u521B\u5EFA\u65F6\u95F4', '\u540D\u79F0', '\u5B8C\u6210\u72B6\u6001', '\u4F18\u5148\u7EA7'];
  private priorityNames: string[] = ['\u4F4E', '\u4E2D', '\u9AD8'];
  private focusMinuteNames: string[] = ['5\u5206\u949F', '15\u5206\u949F', '25\u5206\u949F'];
  private focusMinuteValues: number[] = [5, 15, 25];

  aboutToDisappear() {
    this.clearFocusTimer();
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

  getThemeColor(): string {
    return this.themeColors[this.themeIndex];
  }

  getThemeLightColor(): string {
    return this.themeLightColors[this.themeIndex];
  }

  getPetName(): string {
    if (this.score >= 800) {
      return '\u4E13\u6CE8\u5B88\u62A4\u8005';
    }
    if (this.score >= 450) {
      return '\u81EA\u5F8B\u4F19\u4F34';
    }
    if (this.score >= 200) {
      return '\u6D3B\u529B\u5B66\u5F92';
    }
    if (this.score >= 80) {
      return '\u840C\u65B0\u5C0F\u4F34';
    }
    return '\u5B66\u4E60\u86CB';
  }

  getPetEmoji(): string {
    if (this.score >= 800) {
      return '\uD83D\uDC32';
    }
    if (this.score >= 450) {
      return '\uD83D\uDC09';
    }
    if (this.score >= 200) {
      return '\uD83E\uDD8A';
    }
    if (this.score >= 80) {
      return '\uD83D\uDC31';
    }
    return '\uD83E\uDD5A';
  }

  getPetLevel(): number {
    if (this.score >= 800) {
      return 5;
    }
    if (this.score >= 450) {
      return 4;
    }
    if (this.score >= 200) {
      return 3;
    }
    if (this.score >= 80) {
      return 2;
    }
    return 1;
  }

  getCurrentLevelScore(): number {
    if (this.score >= 800) {
      return 800;
    }
    if (this.score >= 450) {
      return 450;
    }
    if (this.score >= 200) {
      return 200;
    }
    if (this.score >= 80) {
      return 80;
    }
    return 0;
  }

  getNextLevelScore(): number {
    if (this.score >= 800) {
      return 800;
    }
    if (this.score >= 450) {
      return 800;
    }
    if (this.score >= 200) {
      return 450;
    }
    if (this.score >= 80) {
      return 200;
    }
    return 80;
  }

  getPetProgress(): number {
    let currentLevelScore = this.getCurrentLevelScore();
    let nextLevelScore = this.getNextLevelScore();
    if (nextLevelScore === currentLevelScore) {
      return 100;
    }
    return Math.round((this.score - currentLevelScore) * 100 / (nextLevelScore - currentLevelScore));
  }

  getPetStatusText(): string {
    if (this.getTotalFocusMinutes() >= 120) {
      return '\u4E13\u6CE8\u5145\u6C9B';
    }
    if (this.getCompletedCount() > 0) {
      return '\u7A33\u6B65\u6210\u957F';
    }
    return '\u7B49\u5F85\u966A\u4F34';
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
          this.toDoData = [new ToDo(availableThings[Number(value.index)], priority), ...this.toDoData];
        }
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
    this.clearFocusTimer();
    this.toDoData = this.toDoData.map((todoItem: ToDo) => {
      if (todoItem.key === this.focusTaskKey) {
        todoItem.focusCount += 1;
        todoItem.focusDurationMinutes += focusMinutes;
        hasFocusTask = true;
      }
      return todoItem;
    });
    if (hasFocusTask) {
      this.score += 15;
    }
    this.focusTaskKey = '';
    this.focusRemainingSeconds = 0;
    this.focusTotalSeconds = 0;
    this.isFocusRunning = false;
    this.showToastMessage(hasFocusTask ? '\u4E13\u6CE8\u5B8C\u6210\uFF0C\u79EF\u5206 +15' : '\u4E13\u6CE8\u5DF2\u7ED3\u675F');
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

  toggleTodoStatus(item: ToDo) {
    this.toDoData = this.toDoData.map((todoItem: ToDo) => {
      if (todoItem.key === item.key) {
        todoItem.isCompleted = !todoItem.isCompleted;
      }
      return todoItem;
    });
    if (item.isCompleted) {
      this.score += 10;
    } else {
      this.score = Math.max(0, this.score - 10);
    }
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
    if (this.hasCheckedToday) {
      this.showToastMessage('\u4ECA\u65E5\u5DF2\u6253\u5361');
      return;
    }
    this.hasCheckedToday = true;
    this.score += 20;
    this.showToastMessage('\u6253\u5361\u6210\u529F\uFF0C\u79EF\u5206 +20');
  }

  handleThemeTap(index: number) {
    if (this.unlockedThemes[index]) {
      this.themeIndex = index;
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
  }

  showDeliveryPicker(item: ToDo) {
    this.getUIContext().showTextPickerDialog({
      range: this.deliveryDevices,
      onAccept: (value: TextPickerResult) => {
        let deviceName = this.deliveryDevices[Number(value.index)];
        this.lastDeliveryRecord = `${item.name} \u2192 ${deviceName}`;
        this.showToastMessage(`\u5DF2\u6295\u9001\u5230${deviceName}`);
      },
    });
  }

  /**
   * Delete a to-do/completed item.
   */
  deleteTodoItem(item: ToDo) {
    this.toDoData = this.toDoData.filter(todoItem => item.key !== todoItem.key);
    this.showToastMessage('\u5DF2\u5220\u9664');
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
  petCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.sectionTitle('\u5BA0\u7269\u6210\u957F')
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        Text(this.getPetEmoji())
          .fontSize(44)
        Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
          Text(`Lv.${this.getPetLevel()} ${this.getPetName()}`)
            .fontSize($r('sys.float.ohos_id_text_size_headline8'))
            .fontColor(this.getThemeColor())
          Text(`${this.getPetStatusText()} \u00B7 \u79EF\u5206 ${this.score}`)
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
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
      Row() {
        Text(`\u4E0B\u4E00\u7EA7 ${this.getPetProgress()}%`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .layoutWeight(1)
        Text(`\u4E13\u6CE8 ${this.getTotalFocusCount()}\u6B21 / ${this.getTotalFocusMinutes()}\u5206\u949F`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
      }
      .width(Constant.PERCENT_FULL)
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
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      this.sectionTitle('\u6700\u8FD1\u6295\u9001')
      Text(this.lastDeliveryRecord)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
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
      this.searchSortPanel()
      List({ initialIndex: 0, space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        if (this.getVisibleTodos().length === 0) {
          ListItem() {
            Text(this.getTotalCount() === 0 ? '\u70B9\u51FB\u65B0\u589E\u5F85\u529E\uFF0C\u65B0\u4EFB\u52A1\u4F1A\u51FA\u73B0\u5728\u8FD9\u91CC' :
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
              toggleTodoStatus: (item: ToDo) => {
                this.toggleTodoStatus(item);
              },
              deliverTodo: (item: ToDo) => {
                this.showDeliveryPicker(item);
              },
              startFocus: (item: ToDo) => {
                this.showFocusPicker(item);
              }
            })
          }
          .swipeAction({ end: this.itemEnd(toDoItem), edgeEffect: SwipeEdgeEffect.Spring })
        }, (toDoItem: ToDo) => toDoItem.key)
      }
      .layoutWeight(1)
      .listDirection(Axis.Vertical)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width(Constant.PERCENT_FULL)
    .height(Constant.PERCENT_FULL)
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
          this.getUIContext().getPromptAction().showToast({ message: $r('app.string.incomplete') });
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
          Scroll() {
            this.dashboardPanel()
          }
          .width('38%')
          .height(Constant.PERCENT_FULL)

          Column() {
            this.taskListPanel()
          }
          .layoutWeight(1)
          .height(Constant.PERCENT_FULL)
        }
        .layoutWeight(1)
        .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
      } else {
        List({ initialIndex: 0, space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
          ListItem() {
            Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
              Text(`\u5F53\u524D\u79EF\u5206\uFF1A${this.score}`)
                .fontSize($r('sys.float.ohos_id_text_size_headline8'))
                .fontColor(this.getThemeColor())
                .width(Constant.PERCENT_FULL)
              this.checkInCard()
              this.focusCard()
            }
          }

          ListItem() {
            Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
              Text('\u4EFB\u52A1\u5217\u8868')
                .fontSize($r('sys.float.ohos_id_text_size_headline8'))
                .fontColor('#182431')
                .layoutWeight(1)
              Text(`\u603B\u6570 ${this.getTotalCount()} / \u5DF2\u5B8C\u6210 ${this.getCompletedCount()}`)
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .fontColor(this.getThemeColor())
            }
          }

          ListItem() {
            this.searchSortPanel()
          }

          if (this.getVisibleTodos().length === 0) {
            ListItem() {
              Text(this.getTotalCount() === 0 ? '\u70B9\u51FB\u65B0\u589E\u5F85\u529E\uFF0C\u65B0\u4EFB\u52A1\u4F1A\u51FA\u73B0\u5728\u8FD9\u91CC' :
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
                toggleTodoStatus: (item: ToDo) => {
                  this.toggleTodoStatus(item);
                },
                deliverTodo: (item: ToDo) => {
                  this.showDeliveryPicker(item);
                },
                startFocus: (item: ToDo) => {
                  this.showFocusPicker(item);
                }
              })
            }
            .swipeAction({ end: this.itemEnd(toDoItem), edgeEffect: SwipeEdgeEffect.Spring })
          }, (toDoItem: ToDo) => toDoItem.key)

          ListItem() {
            this.petCard()
          }

          ListItem() {
            this.statisticsPanel()
          }

          ListItem() {
            this.themeStore()
          }

          ListItem() {
            this.deliveryRecordCard()
          }
        }
        .layoutWeight(1)
        .listDirection(Axis.Vertical)
        .edgeEffect(EdgeEffect.Spring)
        .padding({
          top: STYLE_CONFIG.LIST_ITEM_GUTTER,
          left: $r('sys.float.ohos_id_default_padding_start'),
          right: $r('sys.float.ohos_id_default_padding_end'),
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
}
