const fs = require('fs');
const c = fs.readFileSync('entry/src/main/ets/pages/Index.ets', 'utf-8');

// Brace count
let open = 0, close = 0;
for (const ch of c) {
  if (ch === '{') open++;
  if (ch === '}') close++;
}
console.log('Braces: {', open, '} =', close, open === close ? 'OK' : 'MISMATCH (diff: ' + (open - close) + ')');

// Feature checks
const checks = [
  // Core business
  ['completeFocus', 'completeFocus()'],
  ['cancelFocus', 'cancelFocus()'],
  ['pauseOrResumeFocus', 'pauseOrResumeFocus'],
  ['saveAppState', 'saveAppState()'],
  ['resetDailyStateIfNeeded', 'resetDailyStateIfNeeded'],
  ['toggleTaskCompleteByKey', 'toggleTaskCompleteByKey'],
  ['AddOrEditTodoForm', 'AddOrEditTodoForm'],
  ['saveNewTodoFromForm', 'saveNewTodoFromForm'],
  ['focusReturnTab', 'focusReturnTab'],
  ['consumeFocusReturnTab', 'consumeFocusReturnTab'],
  ['focus task filter', "item.taskType === 'focus'"],
  ['once task type', "taskType === 'once'"],
  ['completeOnceTaskAndRemove', 'completeOnceTaskAndRemove'],
  ['completeTaskByKey', 'completeTaskByKey'],
  // Pages
  ['build()', 'build()'],
  ['bottomNavigation', 'bottomNavigation'],
  ['homePage', 'homePage'],
  ['focusPage', 'focusPage'],
  ['immersiveFocusClockPage', 'immersiveFocusClockPage'],
  ['petPage', 'petPage'],
  ['calendarPage', 'calendarPage'],
  ['statisticsPage', 'statisticsPage'],
  ['devicePage', 'devicePage'],
  ['profilePage', 'profilePage'],
  // Pet page builders
  ['studyBuddySpaceHero', 'studyBuddySpaceHero'],
  ['studyBuddyTodayCard', 'studyBuddyTodayCard'],
  ['studyBuddyGrowthCard', 'studyBuddyGrowthCard'],
  ['studyBuddyActionsCard', 'studyBuddyActionsCard'],
  // Pet data state
  ['ownedOutfits', 'ownedOutfits'],
  ['equippedOutfitIndex', 'equippedOutfitIndex'],
  ['petExp', 'petExp'],
  ['unlockedThemes', 'unlockedThemes'],
  // Pet functions
  ['getStudyBuddyMood', 'getStudyBuddyMood'],
  ['getStudyBuddyMessage', 'getStudyBuddyMessage'],
  ['getStudyBuddyCompanionState', 'getStudyBuddyCompanionState'],
  ['getStudyBuddyHealingQuote', 'getStudyBuddyHealingQuote'],
  // Outfits
  ['outfitStore', 'outfitStore'],
  ['outfitProductCard', 'outfitProductCard'],
  ['handleOutfitTap', 'handleOutfitTap'],
  ['getOutfitActionText', 'getOutfitActionText'],
  // Achievements
  ['achievementBadgeCard', 'achievementBadgeCard'],
  // Focus room
  ['focusRoomStatusCard', 'focusRoomStatusCard'],
  ['focusRoomPrimaryAction', 'focusRoomPrimaryAction'],
  ['focusRoomBuddyHint', 'focusRoomBuddyHint'],
  ['currentFocusQuote', 'currentFocusQuote'],
  ['focusPreferencesCard', 'focusPreferencesCard'],
  ['focusClockStyleIndex', 'focusClockStyleIndex'],
  ['todoActionPanel', 'todoActionPanel'],
  ['todoSoftActionButton', 'todoSoftActionButton'],
  ['focusRoomFloatingIcon', 'focusRoomFloatingIcon'],
  ['focusRoomThemePanel', 'focusRoomThemePanel'],
  ['focusRoomNoisePanel', 'focusRoomNoisePanel'],
  // Const imports
  ['STYLE_CONFIG ref', 'STYLE_CONFIG'],
  ['UI_COLORS ref', 'UI_COLORS'],
  ['Constant ref', 'Constant'],
  ['STYLE_COLORS import', "from '../common/StyleConstants'"],
  ['CommonCard import', 'CommonCard'],
  ['CommonPill import', 'CommonPill'],
  ['CommonProgressBar import', 'CommonProgressBar'],
  // Nav
  ['visibleTabIndexes has 5 main tabs', '[0, 2, 4, 5, 7]'],
  // Cross-device
  ['TaskTransferService', 'TaskTransferService'],
  ['receivedTransferIds', 'receivedTransferIds'],
  ['discoveredDeviceCount', 'discoveredDeviceCount'],
];

const failed = checks.filter(([name, pattern]) => !c.includes(pattern));
if (failed.length === 0) {
  console.log('All feature checks: OK (' + checks.length + ' items)');
} else {
  console.log('FAILED (' + failed.length + '):');
  failed.forEach(([name]) => console.log('  - ' + name));
}
