/**
 * 样式常量 - 用于替代 Index.ets 中的散落硬编码值
 */

interface StyleColorsMap {
  readonly DANGER_RED: string;
  readonly PRIORITY_HIGH: string;
  readonly PRIORITY_MIDDLE: string;
  readonly PRIORITY_LOW: string;
  readonly PRIORITY_HIGH_BG: string;
  readonly PRIORITY_MIDDLE_BG: string;
  readonly PRIORITY_LOW_BG: string;
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
  readonly CARD_BLUE: string;
  readonly CARD_PURPLE: string;
  readonly CARD_PINK: string;
  readonly CARD_GREEN: string;
  readonly ACCENT_BLUE: string;
  readonly ACCENT_PURPLE: string;
  readonly ACCENT_PINK: string;
  readonly ACCENT_GREEN: string;
}

export const STYLE_COLORS: StyleColorsMap = {
  DANGER_RED: '#D94838',
  PRIORITY_HIGH: '#FF6B6B',
  PRIORITY_MIDDLE: '#FFB347',
  PRIORITY_LOW: '#8FA3BF',
  PRIORITY_HIGH_BG: '#FFF1F1',
  PRIORITY_MIDDLE_BG: '#FFF6E8',
  PRIORITY_LOW_BG: '#EEF3F8',
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
  CARD_BLUE: '#EEF6FF',
  CARD_PURPLE: '#F4F0FF',
  CARD_PINK: '#FFF1F5',
  CARD_GREEN: '#EEF9F1',
  ACCENT_BLUE: '#6A9FE8',
  ACCENT_PURPLE: '#9A86D8',
  ACCENT_PINK: '#E89AAF',
  ACCENT_GREEN: '#78B995',
}

export function getPriorityColor(priority: string): string {
  if (priority === '2' || priority === '\u9AD8') {
    return STYLE_COLORS.PRIORITY_HIGH;
  }
  if (priority === '1' || priority === '\u4E2D') {
    return STYLE_COLORS.PRIORITY_MIDDLE;
  }
  return STYLE_COLORS.PRIORITY_LOW;
}

export function getPriorityBgColor(priority: string): string {
  if (priority === '2' || priority === '\u9AD8') {
    return STYLE_COLORS.PRIORITY_HIGH_BG;
  }
  if (priority === '1' || priority === '\u4E2D') {
    return STYLE_COLORS.PRIORITY_MIDDLE_BG;
  }
  return STYLE_COLORS.PRIORITY_LOW_BG;
}

interface StyleRadiusMap {
  readonly XS: number;
  readonly SM: number;
  readonly MD: number;
  readonly ROUND_BTN: number;
  readonly TIMER_CIRCLE: number;
  readonly CARD: number;
}

export const STYLE_RADIUS: StyleRadiusMap = {
  XS: 4,
  SM: 8,
  MD: 12,
  ROUND_BTN: 27,
  TIMER_CIRCLE: 125,
  CARD: 24,
}

interface StyleSpacingMap {
  readonly XS: number;
  readonly SM: number;
  readonly MD: number;
  readonly LG: number;
  readonly XL: number;
}

export const STYLE_SPACING: StyleSpacingMap = {
  XS: 2,
  SM: 6,
  MD: 10,
  LG: 16,
  XL: 20,
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
