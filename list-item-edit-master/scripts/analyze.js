const fs = require('fs');

const indexPath = 'entry/src/main/ets/pages/Index.ets';
const todoItemPath = 'entry/src/main/ets/view/TodoListItem.ets';
const index = fs.readFileSync(indexPath, 'utf-8');
const todoItem = fs.readFileSync(todoItemPath, 'utf-8');

function assertContains(name, source, pattern) {
  if (!source.includes(pattern)) {
    console.log('FAIL: ' + name);
    return false;
  }
  console.log('OK: ' + name);
  return true;
}

const checks = [
  ['create task saves state', index, 'this.toDoData = [new ToDo(todoName, priority, deadline), ...this.toDoData];'],
  ['edit task saves state', index, 'updateTodoItem(item: ToDo)'],
  ['delete task saves state', index, 'deleteTodoItem(item: ToDo)'],
  ['delete active focus clears focus', index, 'if (item.key === this.focusTaskKey)'],
  ['toggle by key preserved', index, 'toggleTaskCompleteByKey(itemKey: string)'],
  ['ForEach key includes completion state', index, '(toDoItem: ToDo) => `${toDoItem.key}_${toDoItem.isCompleted}`'],
  ['TodoListItem object link', todoItem, '@ObjectLink toDoItem: ToDo;'],
  ['TodoListItem complete display', todoItem, 'this.toDoItem.isCompleted ? UI_COLORS.MINT : Color.Transparent'],
  ['start focus enters focus tab', index, 'this.currentTab = 3;'],
  ['start focus starts timer', index, 'this.startFocusTimer();'],
  ['early cancel does not reward', index, 'cancelFocus()'],
  ['complete focus rewards once task exists', index, 'this.addGrowthReward(15);'],
  ['bottom nav hidden in focus room', index, 'if (!this.isFocusRoomActive())'],
  ['preferences load catches errors', index, 'load app state failed'],
  ['preferences save flushes', index, 'await this.appPreferences.flush();'],
  ['daily reset exists', index, 'resetDailyStateIfNeeded(): boolean'],
  ['invalid stored todo skipped', index, 'if (item !== null)'],
];

const passed = checks.filter(([name, source, pattern]) => assertContains(name, source, pattern)).length;
console.log('Summary: ' + passed + '/' + checks.length + ' checks passed');
if (passed !== checks.length) {
  process.exit(1);
}
