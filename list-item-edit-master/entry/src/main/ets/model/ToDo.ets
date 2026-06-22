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

import { util } from '@kit.ArkTS'

/**
 * Indicates the type of a to-do task.
 * @class
 */
@Observed
export class ToDo {
  key: string = util.generateRandomUUID(true);
  name: string;
  createdAt: number = Date.now();
  priority: number = 1;
  isCompleted: boolean = false;
  focusCount: number = 0;
  focusDurationMinutes: number = 0;
  deadline: number = 0;
  taskType: string = 'focus';
  plannedFocusMinutes: number = 25;
  cardThemeIndex: number = -1;
  category: string = '\u9ED8\u8BA4';
  repeatType: string = '\u4E0D\u91CD\u590D';

  /**
   * Creates a new instance of a to-do item.
   * @param {string} name - To-do item name.
   */
  constructor(name: string, priority: number = 1, deadline: number = 0, category: string = '\u9ED8\u8BA4',
    repeatType: string = '\u4E0D\u91CD\u590D', taskType: string = 'focus', plannedFocusMinutes: number = 25,
    cardThemeIndex: number = -1) {
    this.name = name;
    this.priority = priority;
    this.deadline = deadline;
    this.category = category.length > 0 ? category : name;
    this.repeatType = repeatType.length > 0 ? repeatType : '\u4E0D\u91CD\u590D';
    this.taskType = ToDo.normalizeTaskType(taskType);
    this.plannedFocusMinutes = Math.max(1, Math.round(plannedFocusMinutes));
    this.cardThemeIndex = cardThemeIndex;
  }

  static normalizeTaskType(taskType: string): string {
    if (taskType === 'once' || taskType === 'todo') {
      return 'once';
    }
    if (taskType === 'habit') {
      return 'habit';
    }
    return 'focus';
  }

  static fromStorage(key: string, name: string, createdAt: number, priority: number, isCompleted: boolean,
    focusCount: number, focusDurationMinutes: number, deadline: number = 0, category: string = '\u9ED8\u8BA4',
    repeatType: string = '\u4E0D\u91CD\u590D', taskType: string = 'focus', plannedFocusMinutes: number = 25,
    cardThemeIndex: number = -1): ToDo {
    let todoItem = new ToDo(name, priority, deadline, category, repeatType, taskType, plannedFocusMinutes,
      cardThemeIndex);
    if (key.length > 0) {
      todoItem.key = key;
    }
    todoItem.createdAt = createdAt;
    todoItem.isCompleted = isCompleted;
    todoItem.focusCount = focusCount;
    todoItem.focusDurationMinutes = focusDurationMinutes;
    return todoItem;
  }
}
