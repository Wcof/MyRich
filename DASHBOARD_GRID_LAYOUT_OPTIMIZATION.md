# 仪表盘2D网格布局优化方案

## 问题分析

### 当前问题
1. **组件重叠** - 所有新添加的组件都从 (0, 0) 开始，导致相互遮掩
2. **无自动布局** - 没有自动寻找下一个可用位置的算法
3. **布局算法不完整** - `_handleDrop` 只在拖拽时运行，添加新组件时不运行
4. **Stack 绝对定位** - 使用 Stack + Positioned，没有真正的网格系统

### 代码问题位置
- `add_widget_dialog.dart` 第 174-175 行：新组件总是 `x: 0, y: 0`
- `dashboard_screen.dart` 第 189 行：使用 Stack 而不是真正的网格布局
- `dashboard_screen.dart` 第 295-320 行：`_handleDrop` 方法只在拖拽时调用

---

## 优化方案

### Phase 1: 实现自动布局算法

#### Task 1.1: 创建网格布局管理器
**New File**: `lib/utils/grid_layout_manager.dart`

功能：
- 计算下一个可用的网格位置
- 检测网格中的空闲空间
- 支持不同大小的组件放置
- 类似 Grafana 的自动布局算法

**核心方法**:
```
findNextAvailablePosition(
  List<DashboardWidget> widgets,
  int newWidgetWidth,
  int newWidgetHeight,
  int maxColumns
) -> (x, y)
```

**算法逻辑**:
1. 创建网格占用矩阵（记录每个网格单元是否被占用）
2. 从左到右、从上到下扫描网格
3. 找到第一个能容纳新组件的位置
4. 返回 (x, y) 坐标

#### Task 1.2: 修改添加组件逻辑
**File**: `lib/widgets/dashboard/add_widget_dialog.dart`

修改 `_onSubmit` 方法：
- 调用 `GridLayoutManager.findNextAvailablePosition()`
- 使用计算出的位置而不是硬编码的 (0, 0)
- 需要从 Provider 获取当前仪表盘的所有组件

#### Task 1.3: 修改 Provider 添加组件方法
**File**: `lib/providers/dashboard_provider.dart`

在 `addWidget` 方法中：
- 调用布局管理器计算位置
- 自动设置新组件的 x, y 坐标
- 保存到数据库

---

### Phase 2: 改进网格渲染

#### Task 2.1: 优化 Stack 布局
**File**: `lib/screens/dashboard_screen.dart`

改进 `_buildDashboardContent` 方法：
- 确保 Stack 的大小正确计算
- 使用 `LayoutBuilder` 获取实际可用宽度
- 根据实际宽度计算可用列数

#### Task 2.2: 修复网格高度计算
**File**: `lib/screens/dashboard_screen.dart`

改进 `_calculateGridHeight` 方法：
- 正确计算所有组件占用的最大高度
- 考虑组件的实际大小（w * cellWidth, h * cellHeight）
- 添加底部 padding

#### Task 2.3: 改进 Positioned 定位
**File**: `lib/screens/dashboard_screen.dart`

在 `_buildDraggableWidget` 中：
- 确保 Positioned 的 left, top 计算正确
- 考虑 grid padding
- 确保组件不会超出容器边界

---

### Phase 3: 实现拖拽后的自动重排

#### Task 3.1: 改进拖拽逻辑
**File**: `lib/screens/dashboard_screen.dart`

改进 `_handleDrop` 方法：
- 当拖拽完成后，重新计算所有组件的位置
- 使用网格布局管理器重新排列
- 或者保持用户拖拽的位置，只填充空隙

#### Task 3.2: 支持自由拖拽定位
**New File**: `lib/widgets/dashboard/draggable_grid_widget.dart`

创建可拖拽的网格组件：
- 支持在网格中自由拖拽组件
- 实时显示目标位置
- 拖拽完成后更新组件坐标

---

### Phase 4: 优化用户体验

#### Task 4.1: 添加视觉反馈
**File**: `lib/screens/dashboard_screen.dart`

在编辑模式下：
- 显示网格线（可选）
- 拖拽时显示目标位置高亮
- 显示组件将要放置的位置

#### Task 4.2: 支持紧凑布局
**New File**: `lib/utils/compact_layout_algorithm.dart`

实现紧凑布局算法：
- 删除组件后，自动填充空隙
- 类似 Grafana 的紧凑模式
- 可选的自动整理功能

#### Task 4.3: 保存布局状态
**File**: `lib/providers/dashboard_provider.dart`

- 每次修改后自动保存到数据库
- 支持撤销/重做（可选）
- 保存布局历史

---

## 网格布局算法详解

### 占用矩阵方法
```
1. 初始化网格矩阵 (maxRows x maxColumns)
2. 遍历所有现有组件，标记其占用的单元格
3. 从 (0, 0) 开始扫描，找到第一个空闲位置
4. 检查该位置是否能容纳新组件
5. 如果不能，继续扫描下一个位置
6. 返回找到的位置
```

### 扫描顺序
- 优先级：从左到右，从上到下
- 这样可以保持布局紧凑，类似 Grafana

### 边界处理
- 如果组件宽度超过可用列数，自动换行
- 如果没有找到位置，添加到最后一行

---

## 实现优先级

1. **Critical**: 网格布局管理器 (Phase 1.1)
2. **Critical**: 修改添加组件逻辑 (Phase 1.2-1.3)
3. **High**: 改进网格渲染 (Phase 2)
4. **High**: 改进拖拽逻辑 (Phase 3)
5. **Medium**: 用户体验优化 (Phase 4)

---

## 关键文件修改清单

### 新建文件
- `lib/utils/grid_layout_manager.dart` - 网格布局管理器
- `lib/widgets/dashboard/draggable_grid_widget.dart` - 可拖拽网格组件（可选）
- `lib/utils/compact_layout_algorithm.dart` - 紧凑布局算法（可选）

### 修改文件
- `lib/screens/dashboard_screen.dart` - 改进网格渲染和拖拽逻辑
- `lib/widgets/dashboard/add_widget_dialog.dart` - 使用自动布局
- `lib/providers/dashboard_provider.dart` - 集成布局管理器
- `lib/models/dashboard_model.dart` - 可能需要添加辅助方法

---

## 测试检查清单

- [ ] 添加第一个组件时，自动放在 (0, 0)
- [ ] 添加第二个组件时，自动放在 (2, 0)（假设第一个宽度为 2）
- [ ] 添加第三个组件时，自动放在下一行
- [ ] 组件不再相互遮掩
- [ ] 拖拽组件后，其他组件自动调整位置
- [ ] 删除组件后，空隙被填充
- [ ] 布局与 Grafana 类似
- [ ] 布局与 DingTalk/Feishu 类似
- [ ] 所有更改自动保存到数据库

---

## 参考实现

### Grafana 布局方式
- 使用网格系统（通常 24 列）
- 自动填充空隙
- 支持自由拖拽
- 拖拽时显示目标位置

### DingTalk/Feishu 仪表盘
- 类似网格布局
- 自动排列组件
- 支持拖拽调整
- 紧凑显示

---

## 性能考虑

- 网格布局计算应该是 O(n) 复杂度
- 避免频繁重新计算整个布局
- 只在必要时更新组件位置
- 使用缓存优化性能
