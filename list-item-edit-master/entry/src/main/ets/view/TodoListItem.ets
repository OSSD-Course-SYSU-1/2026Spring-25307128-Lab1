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

import { STYLE_CONFIG, Constant } from '../common/Constants';
import { ToDo } from '../model/ToDo';

@Component
export struct ToDoListItem {
  UIContext = this.getUIContext()
  @ObjectLink toDoItem: ToDo;
  toggleTodoStatus: (item: ToDo) => void = () => {};
  deliverTodo: (item: ToDo) => void = () => {};
  startFocus: (item: ToDo) => void = () => {};
  showTodoDetail: (item: ToDo) => void = () => {};
  updateTodoItem: (item: ToDo) => void = () => {};
  @State isEdited: boolean = false;

  /**
   * Add a completed data item.
   */
  addAchieveData() {
    this.UIContext.animateTo({ duration: STYLE_CONFIG.ANIMATION_DURATION }, () => {
      this.toggleTodoStatus(this.toDoItem);
    });
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
      return '#D94838';
    }
    if (this.toDoItem.priority === 1) {
      return '#F57C00';
    }
    return '#1E8E3E';
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
    Text(label)
      .fontSize($r('sys.float.ohos_id_text_size_body2'))
      .fontColor(textColor)
      .textAlign(TextAlign.Center)
      .maxLines(1)
      .padding({
        left: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 3,
        right: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 3,
        top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
        bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
      })
      .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
      .backgroundColor(backgroundColor)
      .height(30)
      .onClick(action)
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
          .backgroundColor(this.toDoItem.isCompleted ? $r('sys.color.ohos_id_color_floating_button_bg_normal') :
            Color.Transparent)
          .borderWidth(1)
          .borderColor($r('sys.color.ohos_id_color_focused_content_tertiary'))
          .onClick(() => {
            this.addAchieveData();
          })

          Text(`${this.toDoItem.name}`)
            .maxLines(1)
            .fontSize($r('sys.float.ohos_id_text_size_headline9'))
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
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
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
        Text(`\u4E13\u6CE8 ${this.toDoItem.focusCount}\u6B21 / ${this.toDoItem.focusDurationMinutes}\u5206\u949F`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .layoutWeight(1)
        Text(this.getDeadlineText())
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(this.getDeadlineColor())
          .maxLines(1)
      }
      .width(Constant.PERCENT_FULL)
      .height(22)

      Scroll() {
        Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
          if (!this.isEdited) {
            this.actionButton(this.toDoItem.isCompleted ? '\u53D6\u6D88\u5B8C\u6210' : '\u5B8C\u6210', Color.White,
              this.toDoItem.isCompleted ? '#8A8A8A' : $r('sys.color.ohos_id_color_floating_button_bg_normal'), () => {
                this.addAchieveData();
              })
            this.actionButton('\u4E13\u6CE8', Color.White, '#0A59F7', () => {
              this.startFocus(this.toDoItem);
            })
            this.actionButton('\u6295\u9001', '#182431', '#F1F3F5', () => {
              this.deliverTodo(this.toDoItem);
            })
            this.actionButton('\u8BE6\u60C5', '#182431', '#F7F8FA', () => {
              this.showTodoDetail(this.toDoItem);
            })
          }
          Blank()
          if (!this.isEdited) {
            this.actionButton('\u7F16\u8F91', '#182431', '#F7F8FA', () => {
              this.isEdited = true;
            })
          }
        }
        .height(34)
      }
      .width(Constant.PERCENT_FULL)
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)

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
    .constraintSize({ minHeight: 132 })
    .padding({
      left: $r('sys.float.ohos_id_default_padding_start'),
      right: $r('sys.float.ohos_id_default_padding_end'),
      top: STYLE_CONFIG.LIST_ITEM_GUTTER,
      bottom: STYLE_CONFIG.LIST_ITEM_GUTTER
    })
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
    .backgroundColor(Color.White)
  }
}
