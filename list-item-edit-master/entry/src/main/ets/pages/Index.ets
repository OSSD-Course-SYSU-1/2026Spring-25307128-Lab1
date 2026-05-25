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
  @State hasCheckedToday: boolean = false;
  @State unlockedThemes: boolean[] = [true, true, false, false, false, false];
  @State lastDeliveryRecord: string = '\u6682\u65E0\u6295\u9001\u8BB0\u5F55';

  private themeNames: string[] = ['\u84DD\u8272', '\u7EFF\u8272', '\u7D2B\u8272', '\u6A59\u8272',
    '\u6A31\u82B1\u7C89', '\u661F\u7A7A\u9ED1'];
  private themeColors: string[] = ['#0A59F7', '#1E8E3E', '#7E3FF2', '#F57C00', '#E85D9E', '#222831'];
  private themeLightColors: string[] = ['#EAF1FF', '#EAF7EE', '#F1EAFF', '#FFF3E0', '#FFF0F6', '#ECEFF3'];
  private themePrices: number[] = [0, 0, 50, 80, 120, 200];
  private deliveryDevices: string[] = ['\u624B\u673A', '\u5E73\u677F', '\u667A\u6167\u5C4F', '\u7535\u8111'];

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
    if (item.isCompleted) {
      this.achieveData = this.achieveData.filter(todoItem => item.key !== todoItem.key);
    } else {
      this.toDoData = this.toDoData.filter(todoItem => item.key !== todoItem.key);
    }
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
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
    .backgroundColor(this.getThemeLightColor())
  }

  @Builder
  statisticsPanel() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      this.sectionTitle('\u4EFB\u52A1\u7EDF\u8BA1')
      Row() {
        this.statItem('\u603B\u6570', `${this.getTotalCount()}`)
        this.statItem('\u5DF2\u5B8C\u6210', `${this.achieveData.length}`)
        this.statItem('\u672A\u5B8C\u6210', `${this.toDoData.length}`)
        this.statItem('\u5B8C\u6210\u7387', `${this.getCompleteRate()}%`)
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
      .margin({
        left: STYLE_CONFIG.LIST_ITEM_GUTTER,
        right: STYLE_CONFIG.LIST_ITEM_GUTTER,
        top: STYLE_CONFIG.LIST_ITEM_GUTTER
      })
      .borderRadius($r('sys.float.ohos_id_corner_radius_default_m'))
      .backgroundColor(Color.White)

      Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        Text(`\u5F53\u524D\u79EF\u5206\uFF1A${this.score}`)
          .fontSize($r('sys.float.ohos_id_text_size_headline8'))
          .fontColor(this.getThemeColor())
          .width(Constant.PERCENT_FULL)
        this.checkInCard()
        this.petCard()
        this.statisticsPanel()
        this.themeStore()
        this.deliveryRecordCard()
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
        ListItem() {
          this.sectionTitle('\u4EFB\u52A1\u5217\u8868')
        }

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
              },
              deliverTodo: (item: ToDo) => {
                this.showDeliveryPicker(item);
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
              },
              deliverTodo: (item: ToDo) => {
                this.showDeliveryPicker(item);
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
