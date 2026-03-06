# 仪表盘细节调整计划

## 问题分析

### 1. 组件拖拽功能不完整
**当前状态**:
- 仅支持长按拖拽进行组件重新排序
- 不支持在网格中自由移动组件位置

**需要调整**:
- 在编辑模式下，组件应该可以拖拽到网格中的任意位置
- 需要实现网格坐标系统，记录每个组件的 x, y 位置
- 使用 `flutter_staggered_grid_view` 的拖拽功能或自定义拖拽逻辑

### 2. 组件高度宽度设置问题
**当前状态**:
- 添加组件时需要设置固定的高度和宽度值
- 高度通过 `widget.h * 120.0` 计算，宽度固定

**需要调整**:
- 添加/编辑组件时，不显示高度宽度设置字段
- 使用默认尺寸（例如：宽度 2 列，高度 1 行）
- 在编辑模式下，用户可以通过拖拽组件边缘来调整大小
- 需要实现 resize handle（调整大小的手柄）

### 3. 仪表盘标题冗余
**当前状态**:
- Header 显示仪表盘名称、组件数量、编辑按钮、添加按钮
- 占用了大量空间

**需要调整**:
- 移除仪表盘名称显示
- 移除"X 个组件"的统计显示
- 将编辑和添加按钮放在最上方
- 让整个页面空间都用于仪表盘内容

### 4. 左侧菜单不可折叠
**当前状态**:
- 菜单根据屏幕宽度自动展开/收缩
- 没有用户手动控制的折叠按钮

**需要调整**:
- 添加折叠/展开按钮
- 折叠状态下只显示图标
- 展开状态下显示完整菜单
- 保存折叠状态（可选）

---

## 修改计划

### Phase 1: 左侧菜单折叠功能

#### Task 1.1: 修改 MainScreen 状态管理
**File**: `lib/main.dart`
- 添加 `_isMenuExpanded` 状态变量
- 添加 `_toggleMenuExpanded()` 方法
- 修改 `NavigationRail` 的 `extended` 属性，使用 `_isMenuExpanded` 而不是 `isWideScreen`

#### Task 1.2: 添加菜单折叠按钮
**File**: `lib/main.dart`
- 在 `NavigationRail` 的 `leading` 中添加折叠/展开按钮
- 按钮显示不同的图标（展开/折叠）
- 点击按钮切换 `_isMenuExpanded` 状态

---

### Phase 2: 简化仪表盘 Header

#### Task 2.1: 移除冗余信息
**File**: `lib/screens/dashboard_screen.dart`
- 移除仪表盘名称显示（第 135-177 行）
- 移除"X 个组件"统计显示（第 180-189 行）
- 保留编辑模式切换按钮和添加组件按钮

#### Task 2.2: 调整 Header 布局
**File**: `lib/screens/dashboard_screen.dart`
- Header 只显示两个按钮：编辑/查看 + 添加组件
- 减少 Header 高度和 padding
- 让主内容区域占用更多空间

---

### Phase 3: 实现组件拖拽和调整大小

#### Task 3.1: 更新 DashboardWidget 模型
**File**: `lib/models/dashboard_model.dart`
- 确保 `DashboardWidget` 有 `x`, `y`, `w`, `h` 字段
- 这些字段表示网格中的位置和大小

#### Task 3.2: 修改网格布局为可拖拽
**File**: `lib/screens/dashboard_screen.dart`
- 将 `MasonryGridView` 改为支持拖拽的网格
- 实现拖拽逻辑：
  - 在编辑模式下，组件可以拖拽到新位置
  - 更新组件的 `x`, `y` 坐标
  - 保存到 Provider

#### Task 3.3: 实现组件大小调整
**File**: `lib/screens/dashboard_screen.dart`
- 在编辑模式下，组件右下角显示 resize handle
- 用户可以拖拽 handle 来调整组件大小
- 更新组件的 `w`, `h` 值
- 保存到 Provider

#### Task 3.4: 修改添加组件对话框
**File**: `lib/widgets/dashboard/add_widget_dialog.dart`
- 移除高度和宽度输入字段
- 使用默认值：`w: 2, h: 1`（或其他合理默认值）
- 新组件添加到网格末尾

#### Task 3.5: 修改组件配置对话框
**File**: `lib/widgets/dashboard/widget_config_dialog.dart`
- 移除高度和宽度编辑字段
- 只保留标题、数据源等配置选项

---

### Phase 4: 优化编辑模式交互

#### Task 4.1: 编辑模式视觉反馈
**File**: `lib/screens/dashboard_screen.dart`
- 编辑模式下，组件显示拖拽手柄和 resize handle
- 查看模式下，隐藏这些控件
- 添加视觉提示（例如：边框、阴影变化）

#### Task 4.2: 保存和取消操作
**File**: `lib/screens/dashboard_screen.dart`
- 编辑模式下显示"保存"按钮
- 点击"保存"后保存所有更改到数据库
- 可选：添加"取消"按钮来放弃更改

---

## 实现优先级

1. **Critical**: 左侧菜单折叠功能 (Phase 1)
2. **Critical**: 简化 Header (Phase 2)
3. **High**: 组件拖拽功能 (Phase 3.1-3.2)
4. **High**: 组件大小调整 (Phase 3.3)
5. **Medium**: 移除高度宽度设置 (Phase 3.4-3.5)
6. **Medium**: 编辑模式优化 (Phase 4)

---

## 关键技术点

### 网格坐标系统
- 使用网格单位而不是像素
- 每个组件有 `x`, `y`, `w`, `h` 四个属性
- `x`, `y` 表示网格中的起始位置
- `w`, `h` 表示占用的网格单元数

### 拖拽实现
- 可以使用 `flutter_staggered_grid_view` 的拖拽功能
- 或者使用 `Draggable` + `DragTarget` 自定义实现
- 需要实时更新组件位置

### 大小调整
- 在组件右下角添加 resize handle
- 使用 `GestureDetector` 监听拖拽事件
- 计算新的宽度和高度

---

## 测试检查清单

- [ ] 左侧菜单可以折叠/展开
- [ ] 折叠时只显示图标
- [ ] 展开时显示完整菜单
- [ ] Header 只显示编辑和添加按钮
- [ ] 编辑模式下组件可以拖拽
- [ ] 编辑模式下组件可以调整大小
- [ ] 添加组件时不需要设置高度宽度
- [ ] 组件配置对话框不显示高度宽度字段
- [ ] 保存后更改持久化到数据库
- [ ] 整个页面空间用于仪表盘内容
