# MyRich 仪表盘设计方案 - Grafana 风格可拖拽仪表盘

## 核心设计理念
- **左侧菜单栏导航** - 固定左侧菜单，主内容区域可扩展
- **用户自定义仪表盘** - 类似 Grafana，用户可拖拽添加/删除卡片
- **开源组件优先** - 使用成熟的开源库，避免自己写组件
- **默认空白** - 仪表盘初始为空，用户自行搭建

---

## 架构设计

### 1. 应用整体布局
```
┌─────────────────────────────────────────┐
│         MyRich - 个人资产管理系统         │
├──────────┬──────────────────────────────┤
│          │                              │
│  左侧    │      主内容区域              │
│  菜单栏  │   (Dashboard/Assets)        │
│          │                              │
│ • 仪表盘 │                              │
│ • 我的   │                              │
│   资产   │                              │
│          │                              │
└──────────┴──────────────────────────────┘
```

### 2. 菜单结构
- **仪表盘** - 可拖拽的自定义仪表盘
- **我的资产** - 资产列表管理

---

## Phase 1: 左侧菜单栏实现

### Task 1.1: 重构主应用布局
**File**: `lib/main.dart`
- 改为 Scaffold + NavigationRail（左侧菜单）
- 使用 NavigationRail 替代 BottomNavigationBar
- 支持菜单项的图标和标签

### Task 1.2: 创建菜单导航组件
**New File**: `lib/widgets/sidebar_navigation.dart`
- 使用 NavigationRail 组件
- 菜单项：仪表盘、我的资产
- 支持菜单项选中状态

### Task 1.3: 调整屏幕布局
**Files**:
- `lib/screens/dashboard_screen.dart` - 改为仪表盘编辑器
- `lib/screens/asset_list_screen.dart` - 保持不变

---

## Phase 2: 仪表盘编辑器实现（Grafana 风格）

### Task 2.1: 仪表盘数据模型
**New Files**:
- `lib/models/dashboard.dart` - 仪表盘配置模型
- `lib/models/dashboard_widget.dart` - 仪表盘卡片模型

**Dashboard 结构**:
```dart
class Dashboard {
  int id;
  String name;
  String description;
  List<DashboardWidget> widgets;  // 卡片列表
  DateTime createdAt;
  DateTime updatedAt;
}

class DashboardWidget {
  String id;
  String type;  // 'stat', 'chart', 'table', 'gauge'
  int x, y;     // 网格位置
  int width, height;  // 网格大小
  Map<String, dynamic> config;  // 卡片配置
}
```

### Task 2.2: 仪表盘编辑器屏幕
**File**: `lib/screens/dashboard_screen.dart`
- 显示网格布局（类似 Grafana）
- 顶部工具栏：编辑/查看模式切换、添加卡片、保存
- 可拖拽的卡片（使用 flutter_staggered_grid_view）
- 编辑模式下支持拖拽调整大小

### Task 2.3: 仪表盘卡片组件
**New Files**:
- `lib/widgets/dashboard_widgets/stat_card.dart` - 统计卡片（显示数值）
- `lib/widgets/dashboard_widgets/chart_card.dart` - 图表卡片（使用 Syncfusion）
- `lib/widgets/dashboard_widgets/table_card.dart` - 表格卡片
- `lib/widgets/dashboard_widgets/gauge_card.dart` - 仪表盘卡片

### Task 2.4: 卡片添加对话框
**New File**: `lib/widgets/add_widget_dialog.dart`
- 显示可用的卡片类型列表
- 用户选择卡片类型后添加到仪表盘
- 新卡片默认添加到网格末尾

### Task 2.5: 卡片配置编辑器
**New File**: `lib/widgets/widget_config_editor.dart`
- 根据卡片类型显示不同的配置选项
- 支持选择数据源（资产类型、时间范围等）
- 支持自定义标题、颜色等

---

## Phase 3: 仪表盘数据持久化

### Task 3.1: 仪表盘数据库表
**File**: `lib/database/migrations.dart`
- 创建 `dashboards` 表
- 创建 `dashboard_widgets` 表
- 存储仪表盘配置和卡片信息

### Task 3.2: 仪表盘数据库操作
**New Files**:
- `lib/repositories/dashboard_repository.dart` - 仪表盘 CRUD
- `lib/repositories/dashboard_widget_repository.dart` - 卡片 CRUD

### Task 3.3: 仪表盘 Provider
**New File**: `lib/providers/dashboard_provider.dart`
- 加载仪表盘列表
- 创建/编辑/删除仪表盘
- 管理当前选中的仪表盘

---

## Phase 4: 开源组件集成

### 推荐使用的开源库
```yaml
dependencies:
  # 网格布局和拖拽
  flutter_staggered_grid_view: ^0.7.0  # 网格布局

  # 图表库
  syncfusion_flutter_charts: ^25.1.35  # 已有

  # 其他可选
  flutter_colorpicker: ^1.0.3  # 颜色选择器
  intl: ^0.18.1  # 国际化（已有）
```

### 不使用的库
- ❌ 不自己写拖拽逻辑
- ❌ 不自己写网格布局
- ❌ 不自己写图表组件

---

## Phase 5: 用户交互流程

### 仪表盘使用流程
1. 用户进入仪表盘页面 → 显示空白仪表盘
2. 点击"添加卡片"按钮 → 显示卡片类型选择对话框
3. 选择卡片类型 → 卡片添加到仪表盘
4. 点击卡片 → 显示配置编辑器
5. 配置卡片（选择数据源、时间范围等）
6. 拖拽调整卡片位置和大小
7. 点击"保存"→ 保存仪表盘配置到数据库

---

## 实现优先级

1. **Critical**: 左侧菜单栏 + 仪表盘编辑器基础框架 (Phase 1-2)
2. **High**: 卡片类型实现 (stat, chart) (Phase 2)
3. **High**: 数据持久化 (Phase 3)
4. **Medium**: 高级卡片类型 (table, gauge) (Phase 2)
5. **Low**: UI 美化和交互优化 (Phase 5)

---

## 文件结构

```
lib/
├── models/
│   ├── dashboard.dart
│   └── dashboard_widget.dart
├── repositories/
│   ├── dashboard_repository.dart
│   └── dashboard_widget_repository.dart
├── providers/
│   └── dashboard_provider.dart
├── screens/
│   ├── dashboard_screen.dart (改造)
│   └── asset_list_screen.dart
├── widgets/
│   ├── sidebar_navigation.dart
│   ├── add_widget_dialog.dart
│   ├── widget_config_editor.dart
│   ├── dashboard_widgets/
│   │   ├── stat_card.dart
│   │   ├── chart_card.dart
│   │   ├── table_card.dart
│   │   └── gauge_card.dart
│   └── ...
└── main.dart (改造)
```

---

## 关键设计决策

1. **网格系统** - 使用 flutter_staggered_grid_view 实现响应式网格
2. **卡片类型** - 支持 stat, chart, table, gauge 四种基础类型
3. **数据源** - 卡片通过配置指定数据源（资产类型、时间范围等）
4. **编辑模式** - 编辑/查看两种模式，编辑模式下支持拖拽
5. **持久化** - 仪表盘配置存储在本地数据库

---

## 测试检查清单

- [ ] 左侧菜单栏正常显示
- [ ] 菜单项切换正常工作
- [ ] 仪表盘页面默认为空白
- [ ] 可以添加卡片到仪表盘
- [ ] 卡片可以拖拽调整位置
- [ ] 卡片可以调整大小
- [ ] 卡片配置可以编辑
- [ ] 仪表盘配置可以保存到数据库
- [ ] 刷新后仪表盘配置保持不变
- [ ] 支持多个仪表盘
