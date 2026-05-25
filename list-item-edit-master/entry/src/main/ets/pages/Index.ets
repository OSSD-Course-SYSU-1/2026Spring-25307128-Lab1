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
  @State achieveData: ToDo[] = [];
  @State score: number = 0;
  @State themeIndex: number = 0;

  private themeNames: string[] = ['\u84DD\u8272', '\u7EFF\u8272', '\u7D2B\u8272', '\u6A59\u8272'];
  private themeColors: string[] = ['#0A59F7', '#1E8E3E', '#7E3FF2', '#F57C00'];
  private themeLightColors: string[] = ['#EAF1FF', '#EAF7EE', '#F1EAFF', '#FFF3E0'];

  getTotalCount(): number {
    return this.toDoData.length + this.achieveData.length;
  }

  getCompleteRate(): number {
    let totalCount = this.getTotalCount();
    if (totalCount === 0) {
      return 0;
    }
    return Math.round(this.achieveData.length * 100 / totalCount);
  }

  getThemeColor(): string {
    return this.themeColors[this.themeIndex];
  }

  getThemeLightColor(): string {
    return this.themeLightColors[this.themeIndex];
  }

  getPetName(): string {
    if (this.score >= 600) {
      return '\u5B66\u4E60\u795E\u9F99';
    }
    if (this.score >= 300) {
      return '\u667A\u6167\u5C0F\u72D0';
    }
    if (this.score >= 100) {
      return '\u52AA\u529B\u5C0F\u732B';
    }
    return '\u5B66\u4E60\u5E7C\u5D3D';
  }

  getPetEmoji(): string {
    if (this.score >= 600) {
      return '\uD83D\uDC09';
    }
    if (this.score >= 300) {
      return '\uD83E\uDD8A';
    }
    if (this.score >= 100) {
      return '\uD83D\uDC31';
    }
    return '\uD83D\uDC23';
  }

  toggleTodoStatus(item: ToDo) {
    item.isCompleted = !item.isCompleted;
    if (item.isCompleted) {
      this.toDoData = this.toDoData.filter(todoItem => item.key !== todoItem.key);
      this.achieveData = [item, ...this.achieveData];
      this.score += 10;
    } else {
      this.achieveData = this.achieveData.filter(todoItem => item.key !== todoItem.key);
      this.toDoData = [item, ...this.toDoData];
      this.score = Math.max(0, this.score - 10);
    }
  }

  /**
   * Delete a to-do/completed item.
   */
  deleteTodoItem(item: ToDo) {
    if (item.isCompleted) {
      this.achieveData = this.achieveData.filter(todoItem => item.key !== todoItem.key);
    } else {
      this.toDoData = this.toDoData.filter(todoItem => item.key !== todoItem.key);
    }
    try {
      this.getUIContext().getPromptAction().showToast({ message: $r('app.string.deleted') });
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0000, 'Index', `showToast failed. error code=${err.code}, message=${err.message}`);
    }
  }

  @Builder
  themeSwitcher() {
    Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
      ForEach(this.themeNames, (themeName: string, index: number) => {
        Text(themeName)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(this.themeIndex === index ? Color.White : this.themeColors[index])
          .padding({
            left: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 3,
            right: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 3,
            top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
            bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
          })
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
          .backgroundColor(this.themeIndex === index ? this.themeColors[index] : Color.White)
          .onClick(() => {
            this.themeIndex = index;
          })
      }, (themeName: string) => themeName)
    }
    .width(Constant.PERCENT_FULL)
  }

  @Builder
  petCard() {
    Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text(this.getPetEmoji())
        .fontSize(40)
      Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
        Text(this.getPetName())
          .fontSize($r('sys.float.ohos_id_text_size_headline8'))
          .fontColor(this.getThemeColor())
        Text(`\u79EF\u5206 ${this.score}`)
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
    .backgroundColor(this.getThemeLightColor())
  }

  @Builder
  statisticsPanel() {
    Row() {
      this.statItem('\u603B\u6570', `${this.getTotalCount()}`)
      this.statItem('\u5DF2\u5B8C\u6210', `${this.achieveData.length}`)
      this.statItem('\u672A\u5B8C\u6210', `${this.toDoData.length}`)
      this.statItem('\u5B8C\u6210\u7387', `${this.getCompleteRate()}%`)
    }
    .width(Constant.PERCENT_FULL)
    .padding({
      top: STYLE_CONFIG.LIST_ITEM_GUTTER,
      bottom: STYLE_CONFIG.LIST_ITEM_GUTTER
    })
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

  // Item Swipe left to display the toolbar.
  @Builder
  itemEnd(item: ToDo) {
    Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Image($r('app.media.ic_public_settings_filled')).ImageStyle()
        .onClick(() => {
          this.getUIContext().getPromptAction().showToast({ message: $r('app.string.incomplete') });
        })
      Image($r('app.media.ic_public_detail_filled')).ImageStyle()
        .onClick(() => {
          this.getUIContext().getPromptAction().showToast({ message: $r('app.string.incomplete') });
        })
      Image($r('app.media.ic_public_delete_filled')).ImageStyle()
        .onClick(() => {
          this.deleteTodoItem(item);
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
            // Adds data to the to-do list array based on the selection result of the text selection.
            this.getUIContext().showTextPickerDialog({
              range: this.getUIContext().getHostContext()?.resourceManager.getStringArrayValueSync($r('app.strarray.available_things').id),
              onAccept: (value: TextPickerResult) => {
                let availableThings = this.getUIContext().getHostContext()?.resourceManager
                  .getStringArrayValueSync($r('app.strarray.available_things').id);
                if (availableThings) {
                  this.toDoData = [new ToDo(availableThings[Number(value.index)]), ...this.toDoData];
                }
              },
            });
          })
      }
      .height(Constant.PERCENT_12)
      .width(Constant.PERCENT_FULL)
      .padding({
        left: $r('sys.float.ohos_id_max_padding_start'),
        right: $r('sys.float.ohos_id_max_padding_end'),
      })
      .backgroundColor(Color.White)

      Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        Text(`\u5F53\u524D\u79EF\u5206\uFF1A${this.score}`)
          .fontSize($r('sys.float.ohos_id_text_size_headline8'))
          .fontColor(this.getThemeColor())
          .width(Constant.PERCENT_FULL)
        this.petCard()
        this.statisticsPanel()
        this.themeSwitcher()
      }
      .width(Constant.PERCENT_FULL)
      .padding({
        top: STYLE_CONFIG.LIST_ITEM_GUTTER,
        left: $r('sys.float.ohos_id_default_padding_start'),
        right: $r('sys.float.ohos_id_default_padding_end'),
        bottom: STYLE_CONFIG.LIST_ITEM_GUTTER
      })
      .backgroundColor($r('app.color.background_color'))

      // The to-do data display list gadget is bound to the data variable toDoData.
      List({ initialIndex: 0, space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        if (this.toDoData.length !== 0) {
          ListItem() {
            Text($r('app.string.undo'))
              .fontSize($r('sys.float.ohos_id_text_size_headline8'))
          }
        }
        ForEach(this.toDoData, (toDoItem: ToDo) => {
          ListItem() {
            ToDoListItem({
              toDoItem: toDoItem,
              achieveData: this.achieveData,
              toDoData: this.toDoData,
              toggleTodoStatus: (item: ToDo) => {
                this.toggleTodoStatus(item);
              }
            })
          }
          // Set the swipeAction property of the ListItem. When you swipe left, the customized UI view is displayed.
          .swipeAction({ end: this.itemEnd(toDoItem), edgeEffect: SwipeEdgeEffect.Spring })
        }, (toDoItem: ToDo) => toDoItem.key)

        if (this.achieveData.length !== 0) {
          ListItem() {
            Text($r('app.string.done'))
              .fontSize($r('sys.float.ohos_id_text_size_headline8'))
          }
        }
        ForEach(this.achieveData, (toDoItem: ToDo) => {
          ListItem() {
            ToDoListItem({
              toDoItem: toDoItem,
              achieveData: this.achieveData,
              toDoData: this.toDoData,
              toggleTodoStatus: (item: ToDo) => {
                this.toggleTodoStatus(item);
              }
            })
          }
          .swipeAction({ end: this.itemEnd(toDoItem), edgeEffect: SwipeEdgeEffect.Spring })
        }, (toDoItem: ToDo) => toDoItem.key)
      }
      .layoutWeight(1)
      .listDirection(Axis.Vertical)
      .edgeEffect(EdgeEffect.Spring)
      .padding({
        top: $r('sys.float.ohos_id_default_padding_top'),
        left: $r('sys.float.ohos_id_default_padding_start'),
        right: $r('sys.float.ohos_id_default_padding_end'),
      })
    }
    .backgroundColor($r('app.color.background_color'))
    .height(Constant.PERCENT_FULL)
    .width(Constant.PERCENT_FULL)
  }
}
