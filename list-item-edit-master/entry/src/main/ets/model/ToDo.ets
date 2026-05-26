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

  /**
   * Creates a new instance of a to-do item.
   * @param {string} name - To-do item name.
   */
  constructor(name: string, priority: number = 1, deadline: number = 0) {
    this.name = name;
    this.priority = priority;
    this.deadline = deadline;
  }

  static fromStorage(key: string, name: string, createdAt: number, priority: number, isCompleted: boolean,
    focusCount: number, focusDurationMinutes: number, deadline: number = 0): ToDo {
    let todoItem = new ToDo(name, priority, deadline);
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
