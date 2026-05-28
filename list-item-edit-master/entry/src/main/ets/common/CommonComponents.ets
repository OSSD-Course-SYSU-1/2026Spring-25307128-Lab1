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

import { STYLE_CONFIG, UI_COLORS, Constant } from './Constants';

/**
 * 通用卡片基座
 */
@Component
export struct CommonCard {
  @Prop cardBgColor: ResourceColor = Color.White;
  @Prop cardRadius: number = STYLE_CONFIG.UI_RADIUS_LARGE;
  @Prop cardShadowRadius: number = 10;
  @Prop cardShadowOffsetY: number = 4;
  @Prop cardPadding: number = STYLE_CONFIG.UI_CARD_PADDING;
  @Prop cardContentSpace: number = STYLE_CONFIG.LIST_ITEM_GUTTER;

  @BuilderParam content: () => void = this.emptyContent;

  @Builder
  emptyContent() {
  }

  build() {
    Column({ space: this.cardContentSpace }) {
      this.content()
    }
    .width(Constant.PERCENT_FULL)
    .padding(this.cardPadding)
    .borderRadius(this.cardRadius)
    .backgroundColor(this.cardBgColor)
    .shadow({
      radius: this.cardShadowRadius,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: this.cardShadowOffsetY
    })
  }
}

/**
 * 无阴影卡片基座
 */
@Component
export struct CommonCardNoShadow {
  @Prop cardBgColor: ResourceColor = Color.White;
  @Prop cardRadius: number = 20;
  @Prop cardPadding: number = STYLE_CONFIG.LIST_ITEM_GUTTER;
  @Prop cardContentSpace: number = STYLE_CONFIG.LIST_ITEM_GUTTER;

  @BuilderParam content: () => void = this.emptyContent;

  @Builder
  emptyContent() {
  }

  build() {
    Column({ space: this.cardContentSpace }) {
      this.content()
    }
    .width(Constant.PERCENT_FULL)
    .padding(this.cardPadding)
    .borderRadius(this.cardRadius)
    .backgroundColor(this.cardBgColor)
  }
}

/**
 * 通用药丸标签（Pill）
 */
@Component
export struct CommonPill {
  @Prop pillLabel: string = '';
  @Prop pillTextColor: ResourceColor = UI_COLORS.TEXT_SECONDARY;
  @Prop pillBgColor: ResourceColor = '#F7F8FA';
  @Prop pillFontSize: number = 14;
  @Prop pillHPadding: number = STYLE_CONFIG.OPERATION_BUTTON_PADDING * 2;
  @Prop pillVPadding: number = STYLE_CONFIG.OPERATION_BUTTON_PADDING;

  build() {
    Text(this.pillLabel)
      .fontSize(this.pillFontSize)
      .fontColor(this.pillTextColor)
      .padding({
        left: this.pillHPadding,
        right: this.pillHPadding,
        top: this.pillVPadding,
        bottom: this.pillVPadding
      })
      .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
      .backgroundColor(this.pillBgColor)
      .maxLines(1)
  }
}

/**
 * 通用进展条
 */
@Component
export struct CommonProgressBar {
  @Prop progressPercent: number = 0;
  @Prop progressBarColor: ResourceColor = UI_COLORS.MINT;
  @Prop progressTrackColor: ResourceColor = UI_COLORS.MINT_LIGHT;
  @Prop progressHeight: number = 8;

  build() {
    Row() {
      Row()
        .height(this.progressHeight)
        .width(`${this.progressPercent}%`)
        .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
        .backgroundColor(this.progressBarColor)
    }
    .width(Constant.PERCENT_FULL)
    .height(this.progressHeight)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_PILL)
    .backgroundColor(this.progressTrackColor)
  }
}

/**
 * 通用指标卡片（图标 + 标签 + 值）
 */
@Component
export struct CommonMetricCard {
  @Prop metricLabel: string = '';
  @Prop metricValue: string = '';
  @Prop metricColor: ResourceColor = UI_COLORS.TEXT_PRIMARY;
  @Prop metricBgColor: ResourceColor = Color.White;
  @Prop metricIcon: string = '';

  build() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      if (this.metricIcon.length > 0) {
        Row() {
          Text(this.metricIcon)
            .fontSize(22)
          Blank()
        }
        .width(Constant.PERCENT_FULL)
      }
      Text(this.metricValue)
        .fontSize($r('sys.float.ohos_id_text_size_headline7'))
        .fontColor(this.metricColor)
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
      Text(this.metricLabel)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .maxLines(1)
    }
    .layoutWeight(1)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_MEDIUM)
    .backgroundColor(this.metricBgColor)
    .shadow({
      radius: 10,
      color: UI_COLORS.CARD_SHADOW,
      offsetX: 0,
      offsetY: 4
    })
  }
}

/**
 * 通用标签值双行卡片
 */
@Component
export struct CommonInfoCard {
  @Prop infoLabel: string = '';
  @Prop infoValue: string = '';
  @Prop infoColor: ResourceColor = UI_COLORS.TEXT_PRIMARY;
  @Prop infoBgColor: ResourceColor = Color.White;

  build() {
    Column({ space: STYLE_CONFIG.ICON_GUTTER }) {
      Text(this.infoLabel)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .maxLines(1)
      Text(this.infoValue)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(this.infoColor)
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
    }
    .layoutWeight(1)
    .padding(STYLE_CONFIG.LIST_ITEM_GUTTER)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_MEDIUM)
    .backgroundColor(this.infoBgColor)
  }
}

/**
 * 通用两列信息卡片
 */
@Component
export struct CommonTwoColCard {
  @Prop twoColTitle: string = '';
  @Prop twoColBgColor: ResourceColor = Color.White;

  @BuilderParam content: () => void = this.emptyContent;

  @Builder
  emptyContent() {
  }

  build() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      if (this.twoColTitle.length > 0) {
        Text(this.twoColTitle)
          .fontSize($r('sys.float.ohos_id_text_size_headline8'))
          .fontColor(UI_COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .width(Constant.PERCENT_FULL)
      }
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.content()
      }
      .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(this.twoColBgColor)
  }
}
