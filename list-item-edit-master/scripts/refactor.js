const fs = require('fs');
const f = 'entry/src/main/ets/pages/Index.ets';
let c = fs.readFileSync(f, 'utf-8');

// Helper: find the closing brace of a @Builder/method at the same indent level
function findBlockEnd(text, startIdx) {
  let i = startIdx;
  let depth = 0;
  let inString = false;
  let inTemplate = false;
  let strChar = '';
  while (i < text.length) {
    const ch = text[i];
    const prev = i > 0 ? text[i-1] : '';
    if (!inString && !inTemplate) {
      if (ch === '{') depth++;
      else if (ch === '}') { depth--; if (depth === 0) return i + 1; }
      else if (ch === '\'' || ch === '"') { inString = true; strChar = ch; }
      else if (ch === '`') { inTemplate = true; }
    } else if (inString) {
      if (ch === '\\') i++; // skip escaped
      else if (ch === strChar) inString = false;
    } else if (inTemplate) {
      if (ch === '\\') i++;
      else if (ch === '`') inTemplate = false;
    }
    i++;
  }
  return -1;
}

// Find the start of the builder and its scope start
function findBuilder(text, name) {
  // Try both "@Builder\n  name() {" and "  name() {"
  const patterns = [
    '@Builder\n  ' + name + '() {',
    '  ' + name + '() {'
  ];
  for (const p of patterns) {
    const idx = text.indexOf(p);
    if (idx >= 0) {
      // Find the opening brace after name()
      const brace = text.indexOf('{', idx + p.length - 1);
      if (brace >= 0) {
        return { start: idx, blockStart: brace, end: findBlockEnd(text, brace) };
      }
    }
  }
  return null;
}

function safeReplace(text, name, replacement) {
  const loc = findBuilder(text, name);
  if (!loc) { console.log('  NOT FOUND: ' + name); return text; }
  const oldBlock = text.substring(loc.start, loc.end);
  console.log('  Replaced: ' + name + ' (lines ' + (loc.start/40|0) + '-' + (loc.end/40|0) + ', len=' + oldBlock.length + ')');
  return text.substring(0, loc.start) + replacement + text.substring(loc.end);
}

// === petPage() ===
const pp = '  petPage() {\n    Scroll() {\n      Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {\n        this.studyBuddySpaceHero()\n        this.studyBuddyTodayCard()\n        this.studyBuddyGrowthCard()\n        this.studyBuddyActionsCard()\n        this.outfitStore()\n      }\n      .width(Constant.PERCENT_FULL)\n      .padding({ bottom: STYLE_CONFIG.UI_PAGE_BOTTOM_SPACE })\n    }\n    .layoutWeight(1)\n    .edgeEffect(EdgeEffect.Spring)\n  }';
c = safeReplace(c, 'petPage', pp);

// === studyBuddySpaceHero() ===
const sh = `  studyBuddySpaceHero() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        Text(this.getPetEmoji())
          .fontSize(80)
          .textAlign(TextAlign.Center)
          .width(Constant.PERCENT_FULL)
        Text(this.getStudyBuddyName())
          .fontSize($r('sys.float.ohos_id_text_size_headline7'))
          .fontColor(UI_COLORS.TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .width(Constant.PERCENT_FULL)
        Row({ space: 8 }) {
          CommonPill({ pillLabel: 'Lv.' + this.getPetLevel(), pillTextColor: Color.White, pillBgColor: UI_COLORS.PET_PURPLE })
          CommonPill({ pillLabel: this.getStudyBuddyMood(), pillTextColor: UI_COLORS.TEXT_PRIMARY, pillBgColor: Color.White })
        }
        .justifyContent(FlexAlign.Center)
        .width(Constant.PERCENT_FULL)
        if (this.equippedOutfitIndex >= 0 && this.ownedOutfits[this.equippedOutfitIndex]) {
          Text('穿着 ' + this.getEquippedOutfitName())
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(UI_COLORS.TEXT_SECONDARY)
            .textAlign(TextAlign.Center)
            .width(Constant.PERCENT_FULL)
        }
      }
      .width(Constant.PERCENT_FULL)
      .padding({ top: STYLE_CONFIG.UI_CARD_PADDING * 2, bottom: STYLE_CONFIG.UI_CARD_PADDING, left: STYLE_CONFIG.UI_CARD_PADDING, right: STYLE_CONFIG.UI_CARD_PADDING })
      .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
      .backgroundColor(UI_COLORS.MINT_LIGHT)
    }
  }`;
c = safeReplace(c, 'studyBuddySpaceHero', sh);

// === studyBuddyStatusPanel() → studyBuddyTodayCard() ===
const st = `  studyBuddyTodayCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('今日陪伴')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.currentOutfitInfo('专注', this.todayFocusMinutes + '分', UI_COLORS.FOCUS_BLUE)
        this.currentOutfitInfo('任务', this.todayCompletedCount + '', UI_COLORS.MINT)
      }
      .width(Constant.PERCENT_FULL)
      CommonPill({ pillLabel: this.getStudyBuddyCompanionState(), pillTextColor: UI_COLORS.MINT, pillBgColor: UI_COLORS.MINT_LIGHT })
      Text(this.getStudyBuddyMessage())
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
    .shadow({ radius: 10, color: UI_COLORS.CARD_SHADOW, offsetX: 0, offsetY: 4 })
  }`;
c = safeReplace(c, 'studyBuddyStatusPanel', st);

// === studyBuddyTodayRecord() → studyBuddyGrowthCard() ===
const sr = `  studyBuddyGrowthCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('成长进度')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        this.currentOutfitInfo('当前等级', 'Lv.' + this.getPetLevel(), UI_COLORS.PET_PURPLE)
        this.currentOutfitInfo('经验值', this.petExp + '', UI_COLORS.ORANGE)
      }
      .width(Constant.PERCENT_FULL)
      CommonProgressBar({ progressPercent: this.getPetProgress(), progressBarColor: UI_COLORS.PET_PURPLE, progressTrackColor: UI_COLORS.PINK_LIGHT })
      Text(this.getPetExpToNextLevel() === 0 ? '已达到当前最高等级' : '距离下一级还差 ' + this.getPetExpToNextLevel() + ' 经验')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(UI_COLORS.TEXT_SECONDARY)
        .width(Constant.PERCENT_FULL)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
    .shadow({ radius: 10, color: UI_COLORS.CARD_SHADOW, offsetX: 0, offsetY: 4 })
  }`;
c = safeReplace(c, 'studyBuddyTodayRecord', sr);

// === studyBuddyRecentFocus() → studyBuddyActionsCard() ===
const sf = `  studyBuddyActionsCard() {
    Column({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
      Text('互动')
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontColor(UI_COLORS.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width(Constant.PERCENT_FULL)
      Row({ space: STYLE_CONFIG.LIST_ITEM_GUTTER }) {
        CommonPill({ pillLabel: '💬 换一句', pillTextColor: Color.White, pillBgColor: UI_COLORS.MINT })
          .onClick(() => { this.showToastMessage(this.getStudyBuddyHealingQuote()); })
        CommonPill({ pillLabel: '🎀 查看装扮', pillTextColor: Color.White, pillBgColor: UI_COLORS.PET_PURPLE })
          .onClick(() => { this.currentTab = 7; })
      }
      .width(Constant.PERCENT_FULL)
      .justifyContent(FlexAlign.Center)
    }
    .width(Constant.PERCENT_FULL)
    .padding(STYLE_CONFIG.UI_CARD_PADDING)
    .borderRadius(STYLE_CONFIG.UI_RADIUS_LARGE)
    .backgroundColor(Color.White)
    .shadow({ radius: 10, color: UI_COLORS.CARD_SHADOW, offsetX: 0, offsetY: 4 })
  }`;
c = safeReplace(c, 'studyBuddyRecentFocus', sf);

// === Outfit store subtitle ===
c = c.replace(
  "Text('用自律积分兑换小装扮，给学习伙伴换一个新心情')",
  "Text('用积分兑换装扮，装扮搭配后会显示在角色页')"
);

// === outfitProductCard ownership label ===
c = c.replace(
  "Text(this.ownedOutfits[index] ? '已拥有' : `${this.outfitPrices[index]}积分`)",
  "Text(this.ownedOutfits[index] ? (this.equippedOutfitIndex === index ? '✅ 使用中' : '已拥有') : '🔒 ' + this.outfitPrices[index] + '积分')"
);

// === getOutfitActionText ===
const oaStart = c.indexOf('  getOutfitActionText(index: number): string {');
const oaEnd = c.indexOf('  }', oaStart);
const oaOld = c.substring(oaStart, oaEnd + 3);
const oaNew = `  getOutfitActionText(index: number): string {
    if (this.ownedOutfits[index]) {
      return this.equippedOutfitIndex === index ? '使用中' : '点击装备';
    }
    return this.score >= this.outfitPrices[index] ? '可购买' : '积分不足';
  }`;
c = c.replace(oaOld, oaNew);

fs.writeFileSync(f, c, 'utf-8');
console.log('Done. Pet page redesigned.');
