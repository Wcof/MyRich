# MyRich 项目概览

## 项目简介

MyRich 是一个基于 Flutter 开发的跨平台个人资产管理系统，用于追踪和可视化个人资产的分布和走势。系统支持多种资产类型（现金、股票、基金、房产、加密货币等），提供 Dashboard 看板功能，数据存储使用 SQLite 本地存储。

## 技术栈

- **框架**: Flutter (跨平台，优先 macOS 桌面端)
- **数据库**: SQLite (sqflite_common_ffi)
- **状态管理**: Provider
- **图表**: fl_chart
- **文件路径**: path_provider
- **国际化**: intl

## 项目架构

### 分层架构

```
┌─────────────────────────────────────────┐
│         UI Layer (Screens)        │
│  - DashboardScreen                 │
│  - AssetListScreen                 │
│  - AssetDetailScreen               │
└──────────────┬──────────────────┘
               │
┌──────────────▼──────────────────┐
│      Provider Layer                │
│  - AssetTypeProvider              │
│  - AssetProvider                  │
│  - AssetRecordProvider            │
└──────────────┬──────────────────┘
               │
┌──────────────▼──────────────────┐
│    Repository Layer               │
│  - AssetTypeRepository           │
│  - AssetRepository               │
│  - AssetRecordRepository         │
└──────────────┬──────────────────┘
               │
┌──────────────▼──────────────────┐
│      Model Layer                 │
│  - AssetType                   │
│  - Asset                       │
│  - AssetRecord                 │
│  - DashboardConfig              │
└──────────────┬──────────────────┘
               │
┌──────────────▼──────────────────┐
│    Database Layer                │
│  - DatabaseHelper               │
│  - Migrations                  │
└───────────────────────────────────┘
```

## 核心功能模块

### 1. 数据库模块 (lib/database/)

#### DatabaseHelper
- 单例模式管理数据库连接
- 初始化数据库和表结构
- 创建索引优化查询性能
- 插入默认数据（预定义资产类型和默认看板）

#### Migrations
- 定义所有表的创建语句
- 当前版本: 1
- 包含 4 个核心表：
  - asset_types (资产类型)
  - assets (资产)
  - asset_records (资产记录)
  - dashboard_configs (看板配置)

### 2. 数据模型模块 (lib/models/)

#### AssetType
资产类型模型，支持自定义字段定义
- 字段: id, name, icon, color, fieldsSchema, isSystem, createdAt, updatedAt
- 方法: toMap(), fromMap(), copyWith()

#### Asset
资产模型，支持自定义字段数据
- 字段: id, typeId, name, location, customData, createdAt, updatedAt
- 方法: toMap(), fromMap(), copyWith()

#### AssetRecord
资产记录模型，存储资产价值快照
- 字段: id, assetId, value, quantity, unitPrice, note, recordDate, createdAt
- 方法: toMap(), fromMap(), copyWith()

#### DashboardConfig
看板配置模型
- 字段: id, name, layout, isDefault, createdAt, updatedAt
- 方法: toMap(), fromMap(), copyWith()

### 3. Repository 模块 (lib/repositories/)

#### AssetTypeRepository
资产类型数据访问层
- getAll() - 获取所有资产类型
- getById(int id) - 根据 ID 获取
- insert(AssetType) - 插入
- update(AssetType) - 更新
- delete(int id) - 删除
- getSystemTypes() - 获取系统预定义类型
- getCustomTypes() - 获取自定义类型

#### AssetRepository
资产数据访问层
- getAll() - 获取所有资产
- getByTypeId(int typeId) - 根据类型获取
- getById(int id) - 根据 ID 获取
- insert(Asset) - 插入
- update(Asset) - 更新
- delete(int id) - 删除

#### AssetRecordRepository
资产记录数据访问层
- getAll() - 获取所有记录
- getByAssetId(int assetId) - 根据资产 ID 获取
- getById(int id) - 根据 ID 获取
- getLatestByAssetId(int assetId) - 获取最新记录
- getByDateRange(int assetId, int startDate, int endDate) - 按日期范围获取
- insert(AssetRecord) - 插入
- update(AssetRecord) - 更新
- delete(int id) - 删除
- deleteByAssetId(int assetId) - 删除资产的所有记录

### 4. Provider 模块 (lib/providers/)

#### AssetTypeProvider
资产类型状态管理
- loadAssetTypes() - 加载所有类型
- addAssetType(AssetType) - 添加类型
- updateAssetType(AssetType) - 更新类型
- deleteAssetType(int id) - 删除类型
- systemTypes - 系统预定义类型 getter
- customTypes - 自定义类型 getter

#### AssetProvider
资产状态管理
- loadAssets() - 加载所有资产
- loadAssetsByType(int typeId) - 按类型加载
- addAsset(Asset) - 添加资产
- updateAsset(Asset) - 更新资产
- deleteAsset(int id) - 删除资产
- getAssetsByType(int typeId) - 按类型筛选

#### AssetRecordProvider
资产记录状态管理
- loadRecords() - 加载所有记录
- loadRecordsByAsset(int assetId) - 按资产加载
- addRecord(AssetRecord) - 添加记录
- updateRecord(AssetRecord) - 更新记录
- deleteRecord(int id, int assetId) - 删除记录
- getRecordsByAsset(int assetId) - 按资产筛选
- getLatestRecord(int assetId) - 获取最新记录

### 5. UI 模块 (lib/screens/)

#### DashboardScreen
Dashboard 主页面
- 显示欢迎界面
- 后续将添加图表组件

#### AssetListScreen
资产列表页面
- 显示所有资产
- 后续将添加筛选和搜索功能

#### AssetDetailScreen
资产详情页面
- 显示资产详细信息
- 显示历史记录和走势
- 后续将添加图表

#### MainScreen (在 main.dart 中)
主界面，包含底部导航栏
- 切换 Dashboard 和资产列表
- 使用 NavigationBar 实现导航

## 数据库设计

### 表结构

#### asset_types
```sql
CREATE TABLE asset_types (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  icon TEXT,
  color TEXT,
  fields_schema TEXT,
  is_system INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
```

#### assets
```sql
CREATE TABLE assets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  location TEXT,
  custom_data TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (type_id) REFERENCES asset_types(id)
);
```

#### asset_records
```sql
CREATE TABLE asset_records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  asset_id INTEGER NOT NULL,
  value REAL NOT NULL,
  quantity REAL,
  unit_price REAL,
  note TEXT,
  record_date INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (asset_id) REFERENCES assets(id)
);
```

#### dashboard_configs
```sql
CREATE TABLE dashboard_configs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  layout TEXT NOT NULL,
  is_default INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
```

### 索引

- idx_asset_records_asset_id - 优化按资产 ID 查询
- idx_asset_records_record_date - 优化按日期查询
- idx_assets_type_id - 优化按类型查询

## 预定义数据

### 系统预定义资产类型（10 种）

1. 现金 (#4CAF50)
2. 银行存款 (#2196F3)
3. 股票 (#F44336)
4. 基金 (#FF9800)
5. 债券 (#9C27B0)
6. 房产 (#795548)
7. 加密货币 (#FF5722)
8. 期货 (#607D8B)
9. 借款 (#8BC34A)
10. 贷款 (#E91E63)

### 默认看板配置

包含 3 个卡片：
1. 总资产统计卡片
2. 资产分布饼图
3. 资产走势折线图

## 关键设计决策

1. **使用 JSON 存储自定义字段** - 保持灵活性，支持动态扩展
2. **Unix 时间戳（毫秒）** - 统一时间格式，便于跨平台
3. **Provider 状态管理** - 轻量级，适合中小型应用
4. **Repository 模式** - 分离数据访问和控制逻辑
5. **单例 DatabaseHelper** - 确保数据库连接唯一

## 待开发功能

### Phase 4: Dashboard 可视化
- [ ] 资产分布饼图组件
- [ ] 资产走势折线图组件
- [ ] 资产卡片组件
- [ ] 统计卡片组件
- [ ] 网格布局系统

### Phase 5: UI/UX 完善
- [ ] 侧边栏导航
- [ ] 顶部工具栏
- [ ] 响应式设计
- [ ] 主题切换

### Phase 6: 数据接口（预留）
- [ ] 数据源接口抽象
- [ ] 股票/基金 API 对接
- [ ] 加密货币 API 对接
- [ ] 自动定时更新

## 运行项目

### 前置要求
1. 安装 Flutter SDK (3.0+)
2. 安装 Dart SDK
3. macOS 开发环境

### 运行命令

```bash
# 获取依赖
flutter pub get

# 运行 macOS 版本
flutter run -d macos
```

## 文件清单

### 核心文件
- `lib/main.dart`' - 应用入口
- `lib/database/database_helper.dart` - 数据库管理
- `lib/database/migrations.dart` - 数据库迁移
- `lib/models/asset_type.dart` - 资产类型模型
- `lib/models/asset.dart` - 资产模型
- `lib/models/asset_record.dart` - 资产记录模型
- `lib/models/dashboard/dashboard_config.dart` - 看板配置模型
- `lib/repositories/asset_type_repository.dart` - 资产类型数据访问
- `lib/repositories/asset_repository.dart` - 资产数据访问
- `lib/repositories/asset_record_repository.dart` - 资产记录数据访问
- `lib/providers/asset_type_provider.dart` - 资产类型状态管理
- `lib/providers/asset_provider.dart` - 资产状态管理
- `lib/providers/asset_record_provider.dart` - 资产记录状态管理
- `lib/screens/dashboard_screen.dart` - Dashboard 主页面
- `lib/screens/asset_list_screen.dart` - 资产列表页面
- `lib/screens/asset_detail_screen.dart` - 资产详情页面

### 配置文件
- `pubspec.yaml` - 依赖配置
- `.gitignore` - Git 忽略配置

### 文档文件
- `doc/project_overview.md` - 项目概览（本文档）
- `doc/database_schema.md` - 数据库表结构
- `doc/asset_types.md` - 预定义资产类型
- `doc/dashboard_config.md` - Dashboard 配置格式

## 注意事项

1. **ui-ux-pro-max 文件夹** - 本地 skill，不提交到 Git
2. **所有时间戳使用毫秒** - Unix 时间戳
3. **系统预定义类型不可删除** - isSystem = 1
4. **自定义字段使用 JSON 存储** - fieldsSchema 和 customData
5. **Dashboard 配置使用 JSON 存储** - layout 字段

## 开发规范

1. **最小化实现** - 只实现核心功能，避免过度设计
2. **避免冗余** - 不添加未明确要求的功能
3. **简洁优先** - 保持代码简洁，避免不必要的抽象
4. **数据层优先** - 先实现数据库和模型，确保数据流通
5. **功能迭代** - 按 Phase 顺序逐步实现功能
