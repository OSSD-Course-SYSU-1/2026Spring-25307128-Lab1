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

/**
 * Style config.
 */
export const STYLE_CONFIG: Record<string, number> = {
  'IMAGE_SIZE': 32,
  'IMAGE_MARGIN': 4,
  'ICON_GUTTER': 4,
  'OPERATION_BUTTON_PADDING': 4,
  'MENU_IMAGE_SIZE': 24,
  'MENU_HEIGHT': 56,
  'TEXT_MARGIN_LEFT': 40,
  'IMAGE_MARGIN_RIGHT': 30,
  'LIST_ITEM_GUTTER': 12,
  'BORDER_WIDTH': 3,
  'TODO_ITEM_HEIGHT': 80,
  'TODO_ITEM_PADDING_VERTICAL': 4,
  'IMAGE_ICON_OK_SIZE': 15,
  'ANIMATION_DURATION': 600,
  'CUSTOM_CHECKBOX_SIZE': 20,
  'UI_RADIUS_SMALL': 14,
  'UI_RADIUS_MEDIUM': 20,
  'UI_RADIUS_LARGE': 26,
  'UI_RADIUS_PILL': 999,
  'UI_CARD_PADDING': 18,
  'UI_CARD_GUTTER': 14,
  'UI_NAV_SIDE_MARGIN': 14,
  'UI_NAV_BOTTOM_MARGIN': 14,
  'UI_NAV_PADDING': 8,
  'UI_PAGE_BOTTOM_SPACE': 22
}

export const UI_COLORS: Record<string, string> = {
  'CREAM_WHITE': '#FFF7EA',
  'MINT_LIGHT': '#ECF8F0',
  'BLUE_LIGHT': '#EEF4F8',
  'PINK_LIGHT': '#F8EEF3',
  'MINT': '#4FAE7B',
  'ORANGE': '#D9953D',
  'FOCUS_BLUE': '#304E63',
  'PET_PURPLE': '#746B9F',
  'TEXT_PRIMARY': '#252A28',
  'TEXT_SECONDARY': '#6F7772',
  'TEXT_WEAK': '#A7AEA9',
  'CARD_WHITE': '#FFFFFF',
  'CARD_SHADOW': '#120D1F18'
}

export class Constant {
  /**
   * Percent 12.
   */
  static readonly PERCENT_12: string = '12%';

  /**
   * Percent 100
   */
  static readonly PERCENT_FULL: string = '100%';
}
