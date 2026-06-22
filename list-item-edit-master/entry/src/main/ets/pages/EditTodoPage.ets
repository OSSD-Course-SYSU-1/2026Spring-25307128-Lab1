import { STYLE_CONFIG, UI_COLORS, Constant } from '../common/Constants';
import { STYLE_COLORS } from '../common/StyleConstants';
import { ToDo } from '../model/ToDo';
import { EditFormItem } from '../view/EditFormItem';

@Component
export struct AddOrEditTodoForm {
  @ObjectLink todoItem: ToDo;
  @Prop formMode: string = 'edit';
  onSaveTodo: (item: ToDo, name: string, focusMinutes: number, priority: number, deadlineOffset: number,
    category: string, repeatType: string, taskType: string, cardThemeIndex: number) => void = () => {};
  onCancelEdit: () => void = () => {};

  @State editingName: string = '';
  @State draftFocusMinutes: string = '25';
  @State draftPriority: number = 1;
  @State draftDeadlineOffset: number = -1;
  @State draftCategory: string = '\u5B66\u4E60';
  @State draftRepeatType: string = '\u4E0D\u91CD\u590D';
  @State draftTaskType: string = 'focus';
  @State draftCardThemeIndex: number = -1;

  private priorityNames: string[] = ['\u4F4E', '\u4E2D', '\u9AD8'];
  private taskTypeNames: string[] = ['\u4E00\u6B21\u6027', '\u4E13\u6CE8', '\u4E60\u60EF'];
  private taskTypeValues: string[] = ['once', 'focus', 'habit'];
  private cardThemeNames: string[] = ['\u84DD', '\u7D2B', '\u7C89', '\u7EFF'];
  private deadlineNames: string[] = ['\u65E0\u622A\u6B62\u65E5\u671F', '\u4ECA\u5929', '\u660E\u5929', '3\u5929\u540E', '\u4E00\u5468\u540E'];
  private deadlineOffsets: number[] = [-1, 0, 1, 3, 7];
  private repeatNames: string[] = ['\u4E0D\u91CD\u590D', '\u6BCF\u5929', '\u6BCF\u5468', '\u6BCF\u6708'];
  private categoryNames: string[] = ['\u5B66\u4E60', '\u9605\u8BFB', '\u5DE5\u4F5C', '\u5065\u8EAB', '\u81EA\u5B9A\u4E49'];
  private quickNameTags: string[] = ['\u8BFB\u4E66', '\u5B66\u4E60', '\u80CC\u5355\u8BCD', '\u559D\u6C34', '\u8FD0\u52A8', 'HarmonyOS\u9879\u76EE'];

  aboutToAppear() {
    this.editingName = this.todoItem.name;
    this.draftFocusMinutes = `${this.todoItem.plannedFocusMinutes}`;
    this.draftPriority = this.todoItem.priority;
    this.draftDeadlineOffset = this.formMode === 'edit' && this.todoItem.deadline > 0 ? -2 : -1;
    this.draftCategory = this.todoItem.category.length > 0 ? this.todoItem.category : '\u5B66\u4E60';
    this.draftRepeatType = this.todoItem.repeatType.length > 0 ? this.todoItem.repeatType : '\u4E0D\u91CD\u590D';
    this.draftTaskType = ToDo.normalizeTaskType(this.todoItem.taskType);
    this.draftCardThemeIndex = this.todoItem.cardThemeIndex;
  }

  getSafeFocusMinutes(): number {
    let parsedValue = Number(this.draftFocusMinutes);
    if (Number.isNaN(parsedValue)) {
      return 25;
    }
    return Math.max(1, Math.min(240, Math.round(parsedValue)));
  }

  getDeadlineLabel(): string {
    let matchedIndex = this.deadlineOffsets.indexOf(this.draftDeadlineOffset);
    if (matchedIndex >= 0) {
      return this.deadlineNames[matchedIndex];
    }
    return this.todoItem.deadline > 0 ? '\u4FDD\u6301\u539F\u622A\u6B62\u65E5' : this.deadlineNames[0];
  }

  showPriorityPicker() {
    this.getUIContext().showTextPickerDialog({
      range: this.priorityNames,
      selected: this.draftPriority,
      onAccept: (value: TextPickerResult) => {
        this.draftPriority = Number(value.index);
      }
    });
  }

  showDeadlinePicker() {
    this.getUIContext().showTextPickerDialog({
      range: this.deadlineNames,
      selected: 0,
      onAccept: (value: TextPickerResult) => {
        this.draftDeadlineOffset = this.deadlineOffsets[Number(value.index)];
      }
    });
  }

  showRepeatPicker() {
    this.getUIContext().showTextPickerDialog({
      range: this.repeatNames,
      selected: Math.max(0, this.repeatNames.indexOf(this.draftRepeatType)),
      onAccept: (value: TextPickerResult) => {
        this.draftRepeatType = this.repeatNames[Number(value.index)];
      }
    });
  }

  showCategoryPicker() {
    this.getUIContext().showTextPickerDialog({
      range: this.categoryNames,
      selected: 0,
      onAccept: (value: TextPickerResult) => {
        let selectedName = this.categoryNames[Number(value.index)];
        if (selectedName !== '\u81EA\u5B9A\u4E49') {
          this.draftCategory = selectedName;
        }
      }
    });
  }

  getPrioritySelectedColor(index: number): string {
    if (index >= 2) {
      return STYLE_COLORS.PRIORITY_HIGH;
    }
    if (index === 1) {
      return STYLE_COLORS.PRIORITY_MIDDLE;
    }
    return STYLE_COLORS.PRIORITY_LOW;
  }

  getCardThemeSelectedColor(index: number): string {
    if (index === 0) {
      return STYLE_COLORS.ACCENT_BLUE;
    }
    if (index === 1) {
      return STYLE_COLORS.ACCENT_PURPLE;
    }
    if (index === 2) {
      return STYLE_COLORS.ACCENT_PINK;
    }
    return STYLE_COLORS.ACCENT_GREEN;
  }

  @Builder
  segmentOptionButton(label: string, isSelected: boolean, selectedColor: ResourceColor, action: () => void) {
    Text(label)
      .fontSize($r('sys.float.ohos_id_text_size_body2'))
      .fontColor(isSelected ? Color.White : UI_COLORS.TEXT_SECONDARY)
      .fontWeight(isSelected ? FontWeight.Medium : FontWeight.Regular)
      .textAlign(TextAlign.Center)
      .layoutWeight(1)
      .height(40)
      .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
      .backgroundColor(isSelected ? selectedColor : '#F4F5F6')
      .shadow({
        radius: isSelected ? 6 : 0,
        color: '#14000000',
        offsetX: 0,
        offsetY: 2
      })
      .onClick(action)
  }

  @Builder
  taskTypeOptionButton(index: number) {
    Text(this.taskTypeNames[index])
      .fontSize($r('sys.float.ohos_id_text_size_body2'))
      .fontColor(this.draftTaskType === this.taskTypeValues[index] ? Color.White : UI_COLORS.TEXT_SECONDARY)
      .fontWeight(this.draftTaskType === this.taskTypeValues[index] ? FontWeight.Medium : FontWeight.Regular)
      .textAlign(TextAlign.Center)
      .layoutWeight(1)
      .height(40)
      .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
      .backgroundColor(this.draftTaskType === this.taskTypeValues[index] ? STYLE_COLORS.ACCENT_PURPLE : '#F4F5F6')
      .shadow({
        radius: this.draftTaskType === this.taskTypeValues[index] ? 6 : 0,
        color: '#14000000',
        offsetX: 0,
        offsetY: 2
      })
      .onClick(() => {
        this.draftTaskType = this.taskTypeValues[index];
      })
  }

  @Builder
  priorityOptionButton(index: number) {
    Text(this.priorityNames[index])
      .fontSize($r('sys.float.ohos_id_text_size_body2'))
      .fontColor(this.draftPriority === index ? Color.White : UI_COLORS.TEXT_SECONDARY)
      .fontWeight(this.draftPriority === index ? FontWeight.Medium : FontWeight.Regular)
      .textAlign(TextAlign.Center)
      .layoutWeight(1)
      .height(40)
      .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
      .backgroundColor(this.draftPriority === index ? this.getPrioritySelectedColor(index) : '#F4F5F6')
      .shadow({
        radius: this.draftPriority === index ? 6 : 0,
        color: '#14000000',
        offsetX: 0,
        offsetY: 2
      })
      .onClick(() => {
        this.draftPriority = index;
      })
  }

  @Builder
  cardThemeOptionButton(index: number) {
    Text(this.draftCardThemeIndex === index ? `\u2713 ${this.cardThemeNames[index]}` : this.cardThemeNames[index])
      .fontSize($r('sys.float.ohos_id_text_size_body2'))
      .fontColor(this.draftCardThemeIndex === index ? Color.White : UI_COLORS.TEXT_SECONDARY)
      .fontWeight(this.draftCardThemeIndex === index ? FontWeight.Medium : FontWeight.Regular)
      .textAlign(TextAlign.Center)
      .layoutWeight(1)
      .height(40)
      .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
      .backgroundColor(this.draftCardThemeIndex === index ? this.getCardThemeSelectedColor(index) : '#F4F5F6')
      .shadow({
        radius: this.draftCardThemeIndex === index ? 6 : 0,
        color: '#14000000',
        offsetX: 0,
        offsetY: 2
      })
      .onClick(() => {
        this.draftCardThemeIndex = index;
      })
  }

  @Builder
  quickNameTag(tagName: string) {
    Text(tagName)
      .fontSize($r('sys.float.ohos_id_text_size_body2'))
      .fontColor(UI_COLORS.TEXT_SECONDARY)
      .padding({
        left: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
        right: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
        top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
        bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
      })
      .margin({ right: STYLE_CONFIG.ICON_GUTTER, bottom: STYLE_CONFIG.ICON_GUTTER })
      .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
      .backgroundColor('#F4F5F6')
      .onClick(() => {
        this.editingName = tagName;
      })
  }

  build() {
    Scroll() {
      Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        Row() {
          Text(this.formMode === 'add' ? '\u65B0\u589E\u4EE3\u529E' : '\u7F16\u8F91\u4EFB\u52A1')
            .fontSize($r('sys.float.ohos_id_text_size_headline8'))
            .fontColor(UI_COLORS.TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
          Text('\u53D6\u6D88')
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(UI_COLORS.TEXT_SECONDARY)
            .onClick(() => {
              this.onCancelEdit();
            })
        }
        .width(Constant.PERCENT_FULL)

        Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
          Text('\u540D\u79F0')
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(UI_COLORS.TEXT_SECONDARY)
            .width(Constant.PERCENT_FULL)
          TextArea({ placeholder: '\u8F93\u5165\u4EFB\u52A1\u540D\u79F0', text: this.editingName })
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor(UI_COLORS.TEXT_PRIMARY)
            .backgroundColor('#F7F8FA')
            .borderRadius(STYLE_CONFIG.UI_RADIUS_MEDIUM)
            .height(48)
            .onChange((value: string) => {
              this.editingName = value;
            })
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.quickNameTags, (tagName: string) => {
              this.quickNameTag(tagName)
            }, (tagName: string) => tagName)
          }
          .width(Constant.PERCENT_FULL)
        }
        .width(Constant.PERCENT_FULL)
        Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
          Text('\u4EFB\u52A1\u7C7B\u578B')
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(UI_COLORS.TEXT_SECONDARY)
            .width(Constant.PERCENT_FULL)
          Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
            ForEach(this.taskTypeNames, (taskTypeName: string, index: number) => {
              this.taskTypeOptionButton(index)
            }, (taskTypeName: string) => `${taskTypeName}_${this.draftTaskType}`)
          }
          .width(Constant.PERCENT_FULL)
        }
        if (this.draftTaskType === 'focus') {
          EditFormItem({
            itemLabel: '\u4E13\u6CE8\u65F6\u957F\uFF08\u5206\u949F\uFF09',
            itemValue: this.draftFocusMinutes,
            itemPlaceholder: '25',
            isInput: true,
            onChangeValue: (value: string) => {
              this.draftFocusMinutes = value;
            }
          })
        }
        if (this.draftTaskType !== 'habit') {
          EditFormItem({
            itemLabel: '\u622A\u6B62\u65E5\u671F',
            itemValue: this.getDeadlineLabel(),
            itemPlaceholder: '\u9009\u62E9\u622A\u6B62\u65E5\u671F',
            onTapItem: () => {
              this.showDeadlinePicker();
            }
          })
        }
        Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
          Text('\u4F18\u5148\u7EA7')
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(UI_COLORS.TEXT_SECONDARY)
            .width(Constant.PERCENT_FULL)
          Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
            ForEach(this.priorityNames, (priorityName: string, index: number) => {
              this.priorityOptionButton(index)
            }, (priorityName: string) => `${priorityName}_${this.draftPriority}`)
          }
          .width(Constant.PERCENT_FULL)
        }
        .width(Constant.PERCENT_FULL)
        EditFormItem({
          itemLabel: '\u5206\u7C7B',
          itemValue: this.draftCategory,
          itemPlaceholder: '\u5B66\u4E60',
          onTapItem: () => {
            this.showCategoryPicker();
          }
        })
        Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
          Text('\u80CC\u666F\u989C\u8272')
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(UI_COLORS.TEXT_SECONDARY)
            .width(Constant.PERCENT_FULL)
          Row({ space: STYLE_CONFIG.ICON_GUTTER }) {
            ForEach(this.cardThemeNames, (themeName: string, index: number) => {
              this.cardThemeOptionButton(index)
            }, (themeName: string) => `${themeName}_${this.draftCardThemeIndex}`)
          }
          .width(Constant.PERCENT_FULL)
        }

        Text('\u2713 \u4FDD\u5B58\u4EFB\u52A1')
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .width(Constant.PERCENT_FULL)
          .height(50)
          .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
          .backgroundColor(STYLE_COLORS.ACCENT_PURPLE)
          .shadow({ radius: 10, color: '#18000000', offsetX: 0, offsetY: 4 })
          .onClick(() => {
            this.onSaveTodo(this.todoItem, this.editingName, this.getSafeFocusMinutes(), this.draftPriority,
              this.draftDeadlineOffset, this.draftCategory, this.draftRepeatType, this.draftTaskType,
              this.draftCardThemeIndex);
          })
      }
      .width(Constant.PERCENT_FULL)
      .padding(STYLE_CONFIG.UI_CARD_PADDING)
    }
    .width(Constant.PERCENT_FULL)
    .height(Constant.PERCENT_FULL)
    .backgroundColor(Color.White)
  }
}
