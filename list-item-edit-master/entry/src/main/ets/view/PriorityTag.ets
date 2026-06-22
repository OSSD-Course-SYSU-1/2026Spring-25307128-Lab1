import { STYLE_CONFIG } from '../common/Constants';
import { getPriorityBgColor, getPriorityColor } from '../common/StyleConstants';

@Component
export struct PriorityTag {
  @Prop priority: number = 1;

  getPriorityColor(): string {
    return getPriorityColor(`${this.priority}`);
  }

  getPriorityBgColor(): string {
    return getPriorityBgColor(`${this.priority}`);
  }

  getPriorityText(): string {
    if (this.priority >= 2) {
      return '\u9AD8';
    }
    if (this.priority === 1) {
      return '\u4E2D';
    }
    return '\u4F4E';
  }

  build() {
    Text(this.getPriorityText())
      .fontSize($r('sys.float.ohos_id_text_size_body2'))
      .fontColor(this.getPriorityColor())
      .fontWeight(FontWeight.Medium)
      .padding({
        left: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
        right: STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2,
        top: STYLE_CONFIG.OPERATION_BUTTON_PADDING,
        bottom: STYLE_CONFIG.OPERATION_BUTTON_PADDING
      })
      .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
      .backgroundColor(this.getPriorityBgColor())
  }
}
