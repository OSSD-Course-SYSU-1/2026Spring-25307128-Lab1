/**
 * 样式常量 - 用于替代 Index.ets 中的散落硬编码值
 */

interface StyleColorsMap {
  readonly DANGER_RED: string;
  readonly LIGHT_RED_BG: string;
  readonly LIGHT_GRAY_BG: string;
  readonly LIGHT_GRAY_TEXT: string;
  readonly PALE_GRAY_BG: string;
  readonly DARK_TITLE: string;
  readonly FOCUS_LIGHT_BLUE: string;
  readonly FOCUS_BTN_WHITE: string;
  readonly FOCUS_SUBTLE_BLUE: string;
  readonly FOCUS_MUTED_BLUE: string;
  readonly FOCUS_WHITE_TRANSPARENT: string;
}

export const STYLE_COLORS: StyleColorsMap = {
  DANGER_RED: '#D94838',
  LIGHT_RED_BG: '#FFF1F0',
  LIGHT_GRAY_BG: '#F1F3F5',
  LIGHT_GRAY_TEXT: '#8A8A8A',
  PALE_GRAY_BG: '#FAFAFA',
  DARK_TITLE: '#182431',
  FOCUS_LIGHT_BLUE: '#DDE7FF',
  FOCUS_BTN_WHITE: '#32FFFFFF',
  FOCUS_SUBTLE_BLUE: '#EAF0FF',
  FOCUS_MUTED_BLUE: '#C9D4F7',
  FOCUS_WHITE_TRANSPARENT: '#22FFFFFF',
}

interface StyleRadiusMap {
  readonly XS: number;
  readonly SM: number;
  readonly MD: number;
  readonly ROUND_BTN: number;
  readonly TIMER_CIRCLE: number;
}

export const STYLE_RADIUS: StyleRadiusMap = {
  XS: 4,
  SM: 8,
  MD: 12,
  ROUND_BTN: 27,
  TIMER_CIRCLE: 125,
}

interface StyleSpacingMap {
  readonly XS: number;
  readonly SM: number;
  readonly MD: number;
  readonly LG: number;
}

export const STYLE_SPACING: StyleSpacingMap = {
  XS: 2,
  SM: 6,
  MD: 10,
  LG: 16,
}

interface ShadowConfig {
  readonly radius: number;
  readonly color: string;
  readonly offsetX: number;
  readonly offsetY: number;
}

interface StyleShadowsMap {
  readonly CARD: ShadowConfig;
  readonly DARK: ShadowConfig;
}

export const STYLE_SHADOWS: StyleShadowsMap = {
  CARD: {
    radius: 10,
    color: '#120D1F18',
    offsetX: 0,
    offsetY: 4,
  },
  DARK: {
    radius: 22,
    color: '#18000000',
    offsetX: 0,
    offsetY: 8,
  },
}

interface StyleFontMap {
  readonly BODY2: number;
  readonly BODY1: number;
}

export const STYLE_FONT: StyleFontMap = {
  BODY2: 14,
  BODY1: 16,
}
