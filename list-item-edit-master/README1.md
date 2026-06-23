# 基于List组件实现待办事项列表编辑效果

### 介绍

本示例基于List组件，实现待办事项管理、文件管理、备忘录的等场景列表编辑效果。

### 效果预览

|                               List                               |
| :--------------------------------------------------------------: |
| <img src="./screenshots/device/listitem_edit.gif" width="320"/> |

##### 使用说明

- 点击添加按钮，选择需要添加的待办事项。
- 点击左侧checkbox按钮，待办事项状态变更为已完成。
- 左滑单个待办事项，点击删除按钮后，当前待办事项被删除。

### 工程目录

```

├──entry/src/main/ets/
│  ├──common
│  │  └──Constants.ets               // 公共常量类
│  ├──entryability
│  │  └──EntryAbility.ets            // 程序入口类
│  ├──model
│  │  └──ToDo.ets                    // 待办事项数据
│  ├──pages
│  │  └──Index.ets                   // 首页
│  └──view
│     └──TodoListItem.ets            // 待办选项
└──entry/src/main/resources          // 应用静态资源目录
```

### 工程文件解析

1. Constants.ets

Constants.ets 是公共常量文件，主要用于保存项目中重复使用的常量内容，例如页面尺寸、资源路径、样式参数等。通过统一管理常量，可以减少代码中的硬编码，使项目结构更加清晰。

2. EntryAbility.ets

EntryAbility.ets 是应用程序入口类，负责应用启动后的窗口创建和页面加载。应用启动后会加载首页 pages/Index，因此该文件是整个工程运行流程的起点。

3. ToDo.ets

ToDo.ets 是待办事项的数据模型文件，用于描述一条待办事项的数据结构。该模型中包含待办事项的唯一标识、名称以及完成状态等信息，是列表展示、状态切换和删除操作的数据基础。

4. Index.ets

Index.ets 是项目首页，也是待办列表功能的核心页面。该文件主要负责维护待办事项数据数组，使用 List 组件渲染待办事项列表，并处理新增、删除等主要业务逻辑。

5. TodoListItem.ets

TodoListItem.ets 是单条待办事项的列表项组件，负责展示待办事项内容、checkbox 完成状态以及编辑交互。通过将单条列表项封装成组件，可以让首页代码更加简洁，也便于后续维护和扩展。

6. resources 目录

resources 目录用于存放应用静态资源，包括颜色、字符串、图片、页面配置等内容。其中页面配置文件用于声明应用页面路径，图片资源用于展示运行效果或界面图标。

### 具体实现

1. List组件绑定@State修饰的数组变量toDoData。

2. ListItem组件设置左滑动效swipeAction属性，使得单个ListItem可以进行左右滑动，并显示自定义的UIBuilder。

3. 新增/删除列表项，更新数组变量toDoData，并同时更新List组件UI。

### 相关权限

不涉及

### 约束与限制

1. 本示例仅支持标准系统上运行，支持设备：华为手机。

2. HarmonyOS系统：HarmonyOS 5.0.5 Release及以上。

3. DevEco Studio版本：DevEco Studio 5.0.5 Release及以上。

4. HarmonyOS SDK版本：HarmonyOS 5.0.5 Release SDK及以上。

### 总结

本工程结构简单清晰，主要展示了 HarmonyOS ArkTS 中 List 组件、ListItem 组件、状态变量和组件封装的基本使用方法。通过分析该工程，可以了解一个基础待办列表应用的页面入口、数据模型、组件划分和列表交互实现方式。
