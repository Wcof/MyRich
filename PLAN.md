# 个人资产管理系统 - 开发计划

## Context
用户需要一个个人资产管理系统,用于追踪和可视化个人资产的分布和走势。系统需要支持多种资产类型(现金、股票、基金、房产、加密货币等),并提供类似钉钉/飞书的Dashboard看板功能。技术栈选用Flutter以支持跨平台(优先PC端),数据存储使用SQLite本地存储。

核心需求:
1. 灵活的资产类型管理(可自定义添加/删除)
2. Dashboard可视化看板系统
3. 资产分布和走势展示
4. 支持手动录入和自动接口(架构预留)

## Phase 1: 项目初始化和基础架构

### 1.1 创建Flutter项目
- 初始化Flutter桌面项目
- 配置支持Windows和macOS平台
- 设置项目基础目录结构

### 1.2 依赖配置
添加核心依赖:
- `sqflite_common_ffi` - SQLite数据库(桌面端)
- `fl_chart` - 图表可视化
- `provider` 或 `riverpod` - 状态管理
- `path_provider` - 文件路径管理
- `intl` - 日期和数字格式化

### 1.3 项目结构设计
```
lib/
├── main.dart
├── models/           # 数据模型
│   ├── asset.dart
│   ├── asset_type.dart
│   └── asset_record.dart
├── database/         # 数据库层
│   ├── database_helper.dart
│   └── migrations/
├── repositories/     # 数据访问层
│   ├── asset_repository.dart
│   └── asset_type_repository.dart
├── providers/        # 状态管理
│   ├── asset_provider.dart
│   └── dashboard_provider.dart
├── screens/          # 页面
│   ├── dashboard_screen.dart
│   ├── asset_list_screen.dart
│   └── asset_detail_screen.dart
├── widgets/          # 可复用组件
│   ├── charts/
│   │   ├── asset_distribution_chart.dart
│   │   └── asset_trend_chart.dart
│   └── dashboard/
│       ├── dashboard_card.dart
│       └── dashboard_grid.dart
└── utils/            # 工具类
    └── constants.dart
```

## Phase 2: 数据库设计和模型

### 2.1 数据库表设计

**asset_types 表** (资产类型)
```sql
CREATE TABLE asset_types (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  icon TEXT,
  color TEXT,
  fields_schema TEXT,  -- JSON格式存储自定义字段定义
  is_system INTEGER DEFAULT 0,  -- 是否系统预定义
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
```

**assets 表** (资产)
```sql
CREATE TABLE assets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  location TEXT,  -- 资产所在位置(银行、券商等)
  custom_data TEXT,  -- JSON格式存储自定义字段数据
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (type_id) REFERENCES asset_types(id)
);
```

**asset_records 表** (资产记录/快照)
```sql
CREATE TABLE asset_records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  asset_id INTEGER NOT NULL,
  value REAL NOT NULL,  -- 资产价值
  quantity REAL,  -- 数量(如股票数量)
  unit_price REAL,  -- 单价
  note TEXT,
  record_date INTEGER NOT NULL,  -- 记录日期
  created_at INTEGER NOT NULL,
  FOREIGN KEY (asset_id) REFERENCES assets(id)
);
```

**dashboard_configs 表** (看板配置)
```sql
CREATE TABLE dashboard_configs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  layout TEXT NOT NULL,  -- JSON格式存储看板布局配置
  is_default INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
```

### 2.2 数据模型类
- `AssetType` - 资产类型模型(支持自定义字段schema)
- `Asset` - 资产模型(支持自定义字段数据)
- `AssetRecord` - 资产记录模型
- `DashboardConfig` - 看板配置模型

## Phase 3: 核心功能实现

### 3.1 资产类型管理
- 预定义常用资产类型(现金、股票、基金、房产等)
- 支持添加自定义资产类型
- 支持为资产类型定义自定义字段(字段名、类型、是否必填)
- 支持编辑和删除自定义资产类型

### 3.2 资产管理
- 资产列表展示(按类型分组)
- 添加资产(选择类型,填写基础信息和自定义字段)
- 编辑资产信息
- 删除资产
- 资产详情页(显示历史记录和走势)

### 3.3 资产记录管理
- 为资产添加价值记录(手动录入)
- 支持批量导入记录(预留接口)
- 记录历史查看

## Phase 4: Dashboard可视化

### 4.1 图表组件开发
使用 `fl_chart` 实现:
- **资产分布饼图** - 显示各类资产占比
- **资产走势折线图** - 显示总资产或单个资产的价值变化
- **资产卡片** - 显示单个资产的关键信息(当前价值、收益率等)
- **统计卡片** - 显示总资产、总收益等汇总数据

### 4.2 Dashboard看板系统
参考钉钉/飞书的交互方式:
- 网格布局系统(支持拖拽调整位置和大小)
- 支持添加/删除图表卡片
- 支持创建多个看板(不同的视图配置)
- 看板配置持久化存储
- 默认看板模板

### 4.3 数据筛选和时间范围
- 支持按资产类型筛选
- 支持按时间范围筛选(日/周/月/年/自定义)
- 实时计算收益率和变化趋势

## Phase 5: UI/UX实现

### 5.1 主界面布局
- 侧边栏导航(Dashboard、资产列表、设置等)
- 顶部工具栏(添加资产、时间范围选择等)
- 主内容区(Dashboard或资产列表)

### 5.2 响应式设计
- 适配不同桌面分辨率
- 支持窗口大小调整

### 5.3 主题和样式
- 简洁现代的UI设计
- 支持浅色/深色主题(可选)

## Phase 6: 数据接口架构(预留)

### 6.1 接口抽象层
- 定义数据源接口(DataSource)
- 支持手动数据源和API数据源
- 数据同步策略

### 6.2 后续扩展方向
- 股票/基金API对接
- 加密货币API对接
- 自动定时更新

## 关键文件清单

**核心文件:**
- `lib/main.dart` - 应用入口
- `lib/database/database_helper.dart` - 数据库管理
- `lib/models/asset_type.dart` - 资产类型模型
- `lib/models/asset.dart` - 资产模型
- `lib/models/asset_record.dart` - 资产记录模型
- `lib/repositories/asset_repository.dart` - 资产数据访问
- `lib/screens/dashboard_screen.dart` - Dashboard主页面
- `lib/widgets/charts/asset_distribution_chart.dart` - 资产分布图
- `lib/widgets/charts/asset_trend_chart.dart` - 资产走势图
- `lib/widgets/dashboard/dashboard_grid.dart` - Dashboard网格布局

**配置文件:**
- `pubspec.yaml` - 依赖配置
- `windows/runner/main.cpp` - Windows平台配置
- `macos/Runner/MainFlutterWindow.swift` - macOS平台配置

## 验证和测试

### 功能验证
1. 创建多个自定义资产类型,验证字段定义功能
2. 添加不同类型的资产,录入多条历史记录
3. 在Dashboard中添加多个图表卡片,验证数据展示
4. 调整Dashboard布局,验证配置持久化
5. 切换时间范围,验证数据筛选和计算

### 数据验证
1. 验证SQLite数据库正确创建和迁移
2. 验证资产记录的增删改查
3. 验证收益率计算准确性

## 技术要点

1. **灵活的数据模型** - 使用JSON字段存储自定义字段定义和数据,支持动态扩展
2. **最小化实现** - 只实现核心功能,避免过度设计
3. **可扩展架构** - 数据源接口预留,方便后续对接API
4. **简洁的UI** - 使用Flutter Material Design,保持界面简洁高效
5. **本地优先** - 所有数据本地存储,无需网络依赖

## 开发顺序

1. 项目初始化和依赖配置
2. 数据库和模型层实现
3. 资产类型和资产管理功能
4. 图表组件开发
5. Dashboard看板系统
6. UI/UX完善和测试

## 实施说明(给智谱4.7)

本计划将由智谱4.7 AI执行实施。以下是关键实施要点:

### 代码风格要求
- **最小化实现** - 只编写必要的代码,避免过度设计
- **避免冗余** - 不添加未明确要求的功能
- **简洁优先** - 保持代码简洁,避免不必要的抽象

### 实施步骤建议
1. **先搭建骨架** - 创建项目结构和基础配置
2. **数据层优先** - 实现数据库和模型,确保数据流通
3. **功能迭代** - 按Phase顺序逐步实现功能
4. **视觉验证** - 每完成一个模块,运行验证功能是否正常

### 关键技术决策
- **状态管理**: 推荐使用 `provider` (更轻量,适合中小型应用)
- **图表库**: 使用 `fl_chart` (API简洁,文档完善)
- **数据库**: 使用 `sqflite_common_ffi` (桌面端SQLite支持)
- **自定义字段**: 使用JSON字段存储,保持灵活性

### 注意事项
- 资产类型的自定义字段使用JSON存储在 `fields_schema` 字段
- 资产的自定义数据使用JSON存储在 `custom_data` 字段
- Dashboard配置使用JSON存储在 `layout` 字段
- 所有时间戳使用Unix时间戳(毫秒)
- 预定义资产类型设置 `is_system=1`,不可删除

### Dashboard布局配置格式示例
```json
{
  "cards": [
    {
      "id": "card1",
      "type": "asset_distribution_pie",
      "position": {"x": 0, "y": 0},
      "size": {"width": 2, "height": 2},
      "config": {"timeRange": "all"}
    },
    {
      "id": "card2",
      "type": "asset_trend_line",
      "position": {"x": 2, "y": 0},
      "size": {"width": 2, "height": 2},
      "config": {"assetTypes": ["stock", "fund"]}
    }
  ]
}
```

### 预定义资产类型示例
```dart
final systemAssetTypes = [
  {'name': '现金', 'icon': 'cash', 'color': '#4CAF50'},
  {'name': '银行存款', 'icon': 'bank', 'color': '#2196F3'},
  {'name': '股票', 'icon': 'trending_up', 'color': '#F44336'},
  {'name': '基金', 'icon': 'pie_chart', 'color': '#FF9800'},
  {'name': '债券', 'icon': 'receipt', 'color': '#9C27B0'},
  {'name': '房产', 'icon': 'home', 'color': '#795548'},
  {'name': '加密货币', 'icon': 'currency_bitcoin', 'color': '#FF5722'},
  {'name': '期货', 'icon': 'show_chart', 'color': '#607D8B'},
  {'name': '借款', 'icon': 'arrow_upward', 'color': '#8BC34A'},
  {'name': '贷款', 'icon': 'arrow_downward', 'color': '#E91E63'},
];
```
