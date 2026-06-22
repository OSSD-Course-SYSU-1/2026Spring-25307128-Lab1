import { STYLE_CONFIG, UI_COLORS, Constant } from '../common/Constants';
import { STYLE_COLORS, STYLE_RADIUS, STYLE_SPACING, STYLE_SHADOWS } from '../common/StyleConstants';
import { ToDo } from '../model/ToDo';
import { PriorityTag } from './PriorityTag';

@Component
export struct TodoCard {
  @ObjectLink todoItem: ToDo;
  deadlineText: string = '';
  onStart: (item: ToDo) => void = () => {};
  onToggleComplete: (item: ToDo) => void = () => {};
  onEdit: (item: ToDo) => void = () => {};
  onDelete: (item: ToDo) => void = () => {};

  getPriorityColor(): string {
    if (this.todoItem.priority >= 2) {
      return STYLE_COLORS.PRIORITY_HIGH;
    }
    if (this.todoItem.priority === 1) {
      return STYLE_COLORS.PRIORITY_MIDDLE;
    }
    return STYLE_COLORS.PRIORITY_LOW;
  }

  getCardThemeIndex(): number {
    if (this.todoItem.cardThemeIndex >= 0) {
      return this.todoItem.cardThemeIndex % 4;
    }
    let seed = 0;
    for (let index = 0; index < this.todoItem.key.length; index++) {
      seed += this.todoItem.key.charCodeAt(index);
    }
    return seed % 4;
  }

  getPrimaryActionText(): string {
    if (this.todoItem.isCompleted) {
      return '\u5DF2\u5B8C\u6210';
    }
    if (this.todoItem.taskType === 'once') {
      return '\u5B8C\u6210';
    }
    if (this.todoItem.taskType === 'habit') {
      return '\u6253\u5361';
    }
    return '\u5F00\u59CB';
  }

  getTaskTypeText(): string {
    if (this.todoItem.taskType === 'once') {
      return '\u4E00\u6B21\u6027';
    }
    if (this.todoItem.taskType === 'habit') {
      return '\u4E60\u60EF';
    }
    return '\u4E13\u6CE8';
  }

  getPrimaryActionIcon(): string {
    if (this.todoItem.taskType === 'focus') {
      return '';
    }
    return '\u2713';
  }

  handlePrimaryAction() {
    if (this.todoItem.isCompleted) {
      return;
    }
    if (this.todoItem.taskType === 'focus') {
      this.onStart(this.todoItem);
      return;
    }
    this.onToggleComplete(this.todoItem);
  }

  getCardBackgroundColor(): string {
    let backgrounds: string[] = [
      STYLE_COLORS.CARD_BLUE,
      STYLE_COLORS.CARD_PURPLE,
      STYLE_COLORS.CARD_PINK,
      STYLE_COLORS.CARD_GREEN
    ];
    return backgrounds[this.getCardThemeIndex()];
  }

  getCardAccentColor(): string {
    let accents: string[] = [
      STYLE_COLORS.ACCENT_BLUE,
      STYLE_COLORS.ACCENT_PURPLE,
      STYLE_COLORS.ACCENT_PINK,
      STYLE_COLORS.ACCENT_GREEN
    ];
    return accents[this.getCardThemeIndex()];
  }

  build() {
    Row({ space: STYLE_SPACING.LG }) {
      Column({ space: STYLE_SPACING.MD }) {
        Text(this.todoItem.name)
          .fontSize($r('sys.float.ohos_id_text_size_headline7'))
          .fontColor(this.todoItem.isCompleted ? UI_COLORS.TEXT_WEAK : UI_COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width(Constant.PERCENT_FULL)
        Text(`${this.deadlineText} \u00B7 ${this.todoItem.category}`)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(UI_COLORS.TEXT_SECONDARY)
          .maxLines(1)
          .width(Constant.PERCENT_FULL)
        Row({ space: STYLE_SPACING.SM }) {
          PriorityTag({ priority: this.todoItem.priority })
          Text(this.getTaskTypeText())
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(this.getCardAccentColor())
            .padding({ left: 9, right: 9, top: 4, bottom: 4 })
            .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
            .backgroundColor('#66FFFFFF')
            .maxLines(1)
          Text(this.todoItem.taskType === 'focus' ? `${this.todoItem.plannedFocusMinutes}\u5206\u949F` :
            (this.todoItem.taskType === 'habit' ? '\u5F85\u6253\u5361' : '\u5F85\u5B8C\u6210'))
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(UI_COLORS.TEXT_SECONDARY)
            .padding({ left: 9, right: 9, top: 4, bottom: 4 })
            .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
            .backgroundColor('#55FFFFFF')
            .maxLines(1)
        }
        .width(Constant.PERCENT_FULL)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Column({ space: STYLE_SPACING.MD }) {
        Row({ space: STYLE_SPACING.XS }) {
          if (this.getPrimaryActionIcon().length > 0) {
            Text(this.getPrimaryActionIcon())
              .fontSize(12)
              .fontColor(Color.White)
          }
          Text(this.getPrimaryActionText())
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)
        }
          .width(76)
          .height(42)
          .justifyContent(FlexAlign.Center)
          .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
          .backgroundColor(this.todoItem.isCompleted ? UI_COLORS.TEXT_WEAK : this.getCardAccentColor())
          .shadow({ radius: 12, color: '#20000000', offsetX: 0, offsetY: 5 })
          .onClick(() => {
            this.handlePrimaryAction();
          })
        Text('\u00B7\u00B7\u00B7')
          .fontSize(20)
          .fontColor('#8A6F7772')
          .textAlign(TextAlign.Center)
          .width(76)
          .height(30)
          .onClick(() => {
            this.onEdit(this.todoItem);
          })
      }
    }
    .width(Constant.PERCENT_FULL)
    .padding(22)
    .borderRadius(STYLE_RADIUS.CARD)
    .backgroundColor(this.todoItem.isCompleted ? STYLE_COLORS.LIGHT_GRAY_BG : this.getCardBackgroundColor())
    .opacity(this.todoItem.isCompleted ? 0.72 : 1)
    .shadow(STYLE_SHADOWS.CARD)
    .animation({ duration: 180, curve: Curve.EaseOut })
    .gesture(
      LongPressGesture()
        .onAction(() => {
          this.onDelete(this.todoItem);
        })
    )
  }
}
