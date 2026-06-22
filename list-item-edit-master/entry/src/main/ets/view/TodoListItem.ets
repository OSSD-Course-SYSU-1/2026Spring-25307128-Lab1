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

import { STYLE_CONFIG, UI_COLORS, Constant } from '../common/Constants';
import { STYLE_COLORS } from '../common/StyleConstants';
import { ToDo } from '../model/ToDo';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Component
export struct ToDoListItem {
  UIContext = this.getUIContext()
  @ObjectLink toDoItem: ToDo;
  onToggleComplete: (key: string) => void = () => {};
  deliverTodo: (item: ToDo) => void = () => {};
  startFocus: (item: ToDo) => void = () => {};
  showTodoDetail: (item: ToDo) => void = () => {};
  updateTodoItem: (item: ToDo) => void = () => {};
  @State isEdited: boolean = false;

  /**
   * Add a completed data item.
   */
  addAchieveData() {
    hilog.info(0x0000, 'TodoListItem', `click complete button, key=${this.toDoItem.key}, isCompleted=${this.toDoItem.isCompleted}`);
    this.onToggleComplete(this.toDoItem.key);
  }

  getPriorityText(): string {
    if (this.toDoItem.priority >= 2) {
      return '\u9AD8';
    }
    if (this.toDoItem.priority === 1) {
      return '\u4E2D';
    }
    return '\u4F4E';
  }

  getPriorityColor(): string {
    if (this.toDoItem.priority >= 2) {
      return STYLE_COLORS.PRIORITY_HIGH;
    }
    if (this.toDoItem.priority === 1) {
      return STYLE_COLORS.PRIORITY_MIDDLE;
    }
    return STYLE_COLORS.PRIORITY_LOW;
  }

  getStartOfDay(timestamp: number): number {
    let dateValue = new Date(timestamp);
    dateValue.setHours(0, 0, 0, 0);
    return dateValue.getTime();
  }

  getDeadlineText(): string {
    if (this.toDoItem.deadline <= 0) {
      return '\u65E0\u622A\u6B62\u65E5\u671F';
    }
    let diffDays = Math.round((this.getStartOfDay(this.toDoItem.deadline) - this.getStartOfDay(Date.now())) /
      (24 * 60 * 60 * 1000));
    if (diffDays === 0) {
      return '\u4ECA\u5929\u622A\u6B62';
    }
    if (diffDays > 0) {
      return `\u8FD8\u6709 ${diffDays} \u5929`;
    }
    return `\u5DF2\u903E\u671F ${Math.abs(diffDays)} \u5929`;
  }

  getDeadlineColor(): string {
    if (this.toDoItem.deadline <= 0) {
      return '#6B7280';
    }
    let diffDays = Math.round((this.getStartOfDay(this.toDoItem.deadline) - this.getStartOfDay(Date.now())) /
      (24 * 60 * 60 * 1000));
    if (diffDays < 0) {
      return '#D94838';
    }
    if (diffDays <= 1) {
      return '#F57C00';
    }
    return '#1E8E3E';
  }

  @Builder
  actionButton(label: string, textColor: ResourceColor, backgroundColor: ResourceColor, action: () => void) {
    Button(label)
      .type(ButtonType.Normal)
      .fontSize($r('sys.float.ohos_id_text_size_body2'))
      .fontColor(textColor)
      .padding({
        left: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 3,
        right: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 3,
        top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
        bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
      })
      .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
      .backgroundColor(backgroundColor)
      .height(32)
      .enabled(true)
      .onClick(action)
  }

  @Builder
  primaryActionButton(label: string, textColor: ResourceColor, backgroundColor: ResourceColor, action: () => void) {
    Button(label)
      .type(ButtonType.Normal)
      .fontSize($r('sys.float.ohos_id_text_size_body2'))
      .fontColor(textColor)
      .fontWeight(FontWeight.Medium)
      .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
      .backgroundColor(backgroundColor)
      .height(36)
      .layoutWeight(1)
      .onClick(action)
  }

  @Builder
  secondaryActionButton(label: string, action: () => void) {
    Button(label)
      .type(ButtonType.Normal)
      .fontSize($r('sys.float.ohos_id_text_size_body2'))
      .fontColor(UI_COLORS.TEXT_SECONDARY)
      .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
      .backgroundColor('#F4F5F2')
      .height(30)
      .layoutWeight(1)
      .onClick(action)
  }

  @Builder
  infoTag(label: string, value: string, color: ResourceColor, backgroundColor: ResourceColor) {
    Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text(label)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(color)
      Text(value)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(color)
        .maxLines(1)
    }
    .padding({
      left: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
      right: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
      top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
      bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
    })
    .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
    .backgroundColor(backgroundColor)
  }

  build() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        if (!this.isEdited) {
          Row() {
            if (this.toDoItem.isCompleted) {
              Image($r('app.media.ic_public_ok_filled'))
                .width(STYLE_CONFIG.IMAGE_ICON_OK_SIZE)
                .aspectRatio(1)
                .borderRadius(STYLE_CONFIG.IMAGE_ICON_OK_SIZE)
                .fillColor(Color.White)
                .transition(TransitionEffect.IDENTITY)
            }
          }
          .width(STYLE_CONFIG.CUSTOM_CHECKBOX_SIZE)
          .justifyContent(FlexAlign.Center)
          .aspectRatio(1)
          .borderRadius(STYLE_CONFIG.CUSTOM_CHECKBOX_SIZE)
          .backgroundColor(this.toDoItem.isCompleted ? UI_COLORS.MINT : Color.Transparent)
          .borderWidth(1)
          .borderColor(this.toDoItem.isCompleted ? UI_COLORS.MINT : UI_COLORS.TEXT_WEAK)
          .onClick(() => {
            this.addAchieveData();
          })

          Text(`${this.toDoItem.name}`)
            .maxLines(1)
            .fontSize($r('sys.float.ohos_id_text_size_headline9'))
            .fontColor(this.toDoItem.isCompleted ? UI_COLORS.TEXT_WEAK : UI_COLORS.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .decoration({ type: this.toDoItem.isCompleted ? TextDecorationType.LineThrough : TextDecorationType.None })
            .onClick(() => {
              this.showTodoDetail(this.toDoItem);
            })
          Text(this.getPriorityText())
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(Color.White)
            .padding({
              left: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
              right: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
              top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
              bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
            })
            .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
            .backgroundColor(this.getPriorityColor())
        } else {
          TextInput({ text: `${this.toDoItem.name}` })
            .maxLines(1)
            .fontSize($r('sys.float.ohos_id_text_size_headline9'))
            .layoutWeight(1)
            .backgroundColor(Color.Transparent)
            .id('textEdit')
            .onChange((value: string) => {
              // Update to-do data.
              this.toDoItem.name = value;
            })
            .onAppear(() => {
              // Requests the input box to obtain the focus.
              focusControl.requestFocus('textEdit');
            })
        }
      }
      .width(Constant.PERCENT_FULL)
      .height(28)

      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        this.infoTag('\uD83C\uDF45', `${this.toDoItem.focusCount}\u6B21`, UI_COLORS.FOCUS_BLUE, UI_COLORS.BLUE_LIGHT)
        this.infoTag('\u23F1', `${this.toDoItem.focusDurationMinutes}\u5206\u949F`, UI_COLORS.MINT, UI_COLORS.MINT_LIGHT)
        Blank()
        this.infoTag('\uD83D\uDCC5', this.getDeadlineText(), this.getDeadlineColor(), '#F7F8FA')
      }
      .width(Constant.PERCENT_FULL)
      .height(30)

      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        if (!this.isEdited) {
          this.primaryActionButton(this.toDoItem.isCompleted ? '\u53D6\u6D88' : '\u2713 \u5B8C\u6210', Color.White,
            this.toDoItem.isCompleted ? UI_COLORS.TEXT_WEAK : UI_COLORS.MINT, () => {
              this.addAchieveData();
            })
          this.primaryActionButton('\u5F00\u59CB\u4E13\u6CE8', Color.White, UI_COLORS.FOCUS_BLUE, () => {
            this.startFocus(this.toDoItem);
          })
        }
      }
      .width(Constant.PERCENT_FULL)
      .height(36)

      Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
        if (!this.isEdited) {
          this.secondaryActionButton('\u8BE6\u60C5', () => {
            this.showTodoDetail(this.toDoItem);
          })
          this.secondaryActionButton('\u7F16\u8F91', () => {
            this.isEdited = true;
          })
          this.secondaryActionButton('\u6295\u9001', () => {
            this.deliverTodo(this.toDoItem);
          })
        }
      }
      .width(Constant.PERCENT_FULL)
      .height(30)

      if (this.isEdited) {
        Row() {
          Blank()
          Image($r('app.media.ic_public_ok_filled'))
            .width(STYLE_CONFIG.MENU_IMAGE_SIZE)
            .aspectRatio(1)
            .onClick(() => {
              this.updateTodoItem(this.toDoItem);
              this.isEdited = false;
            })
        }
        .width(Constant.PERCENT_FULL)
        .height(30)
      }
    }
    .width(Constant.PERCENT_FULL)
    .constraintSize({ minHeight: 162 })
    .padding({
      left: STYLE_CONFIG.UI_CARD_PADDING,
      right: STYLE_CONFIG.UI_CARD_PADDING,
      top: STYLE_CONFIG.LIST_ITEM_GUTTER,
      bottom: STYLE_CONFIG.LIST_ITEM_GUTTER
    })
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(this.toDoItem.isCompleted ? '#F4F5F2' : UI_COLORS.CARD_WHITE)
    .border({
      width: 1,
      color: this.toDoItem.isCompleted ? '#E3E6E1' : '#EEF1EC'
    })
    .opacity(this.toDoItem.isCompleted ? 0.72 : 1)
    .shadow({
      radius: this.toDoItem.isCompleted ? 3 : 14,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: this.toDoItem.isCompleted ? 1 : 5
    })
  }
}
