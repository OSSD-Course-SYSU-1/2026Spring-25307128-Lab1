import { STYLE_CONFIG, UI_COLORS, Constant } from '../common/Constants';

@Component
export struct EditFormItem {
  @Prop itemLabel: string = '';
  @Prop itemValue: string = '';
  @Prop itemPlaceholder: string = '';
  @Prop isInput: boolean = false;
  onChangeValue: (value: string) => void = () => {};
  onTapItem: () => void = () => {};

  build() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text(this.itemLabel)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
      if (this.isInput) {
        TextInput({ text: this.itemValue, placeholder: this.itemPlaceholder })
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor(UI_COLORS.TEXT_PRIMARY)
          .backgroundColor('#F7F8FA')
          .borderRadius(STYLE_CONFIG.UI_RADIUS_MEDIUM)
          .onChange((value: string) => {
            this.onChangeValue(value);
          })
      } else {
        Row() {
          Text(this.itemValue.length > 0 ? this.itemValue : this.itemPlaceholder)
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor(this.itemValue.length > 0 ? UI_COLORS.TEXT_PRIMARY : UI_COLORS.TEXT_SECONDARY)
            .layoutWeight(1)
            .maxLines(1)
          Text('\u203A')
            .fontSize(20)
            .fontColor(UI_COLORS.TEXT_SECONDARY)
        }
        .width(Constant.PERCENT_FULL)
        .height(44)
        .padding({
          left: STYLE_CONFIG.LIST_ITEM_GUTTER,
          right: STYLE_CONFIG.LIST_ITEM_GUTTER
        })
        .borderRadius(STYLE_CONFIG.UI_RADIUS_MEDIUM)
        .backgroundColor('#F7F8FA')
        .onClick(() => {
          this.onTapItem();
        })
      }
    }
    .width(Constant.PERCENT_FULL)
  }
}
