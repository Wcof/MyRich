# MyRich - 个人资产管理系统

一个基于 Flutter 开发的跨平台个人资产管理系统，帮助你追踪和可视化个人资产的分布和走势。

## 项目简介

MyRich 是一个功能强大的个人资产管理工具，支持多种资产类型（现金、股票、基金、房产、加密货币等），提供类似钉钉/飞书的 Dashboard 看板功能，让你能够直观地了解自己的财务状况。

## 主要功能

### 资产类型管理
- 预定义常用资产类型（现金、银行存款、股票、基金、债券、房产、加密货币等）
- 支持添加自定义资产类型
- 支持为资产类型定义自定义字段（字段名、类型、是否必填）
- 支持编辑和删除自定义资产类型

### 资产管理
- 资产列表展示（按类型分组）
- 添加资产（选择类型，填写基础信息和自定义字段）
- 编辑资产信息
- 删除资产
- 资产详情页（显示历史记录和走势）

### 资产记录管理
- 为资产添加价值记录（手动录入）
- 支持批量导入记录（预留接口）
- 记录历史查看

### Dashboard 可视化
- 资产分布饼图 - 显示各类资产占比
- 资产走势折线图 - 显示总资产或单个资产的价值变化
- 资产卡片 - 显示单个资产的关键信息（当前价值、收益率等）
- 统计卡片 - 显示总资产、总收益等汇总数据
- 网格布局系统（支持拖拽调整位置和大小）
- 支持添加/删除图表卡片
- 支持创建多个看板（不同的视图配置）
- 看板配置持久化存储

### 数据筛选
- 按资产类型筛选
- 按时间范围筛选（日/周/月/年/自定义）
- 实时计算收益率和变化趋势

## 技术栈

- **框架**: Flutter (跨平台，优先 PC 端)
- **数据库**: SQLite (sqflite_common_ffi)
- **图表**: fl_chart
- **状态管理**: provider
- **文件路径**: path_provider
- **国际化**: intl

## 项目结构

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

## 开发计划

### Phase 1: 项目初始化和基础架构
- 创建 Flutter 桌面项目
- 配置 Windows 和 macOS 平台
- 添加核心依赖
- 设置项目基础目录结构

### Phase 2: 数据库设计和模型
- 设计数据库表结构
- 实现数据模型类
- 创建数据库迁移机制

### Phase 3: 核心功能实现
- 资产类型管理
- 资产管理
- 资产记录管理

### Phase 4: Dashboard 可视化
- 图表组件开发
- Dashboard 看板系统
- 数据筛选和时间范围

### Phase 5: UI/UX 实现
- 主界面布局
- 响应式设计
- 主题和样式

### Phase 6: 数据接口架构（预留）
- 接口抽象层
- 后续扩展方向（股票/基金 API 对接、加密货币 API 对接等）

## 数据库设计

### asset_types 表（资产类型）
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

### assets 表（资产）
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

### asset_records 表（资产记录/快照）
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

### dashboard_configs 表（看板配置）
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

## 运行项目

### 前置要求
- Flutter SDK (3.0 或更高版本)
- Dart SDK
- Windows/macOS 开发环境

### 安装步骤

1. 克隆仓库
```bash
git clone https://github.com/Wcof/MyRich.git
cd MyRich
```

2. 获取依赖
```bash
flutter pub get
```

3. 运行项目
```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos
```

## 技术特点

1. **灵活的数据模型** - 使用 JSON 字段存储自定义字段定义和数据，支持动态扩展
2. **最小化实现** - 只实现核心功能，避免过度设计
3. **可扩展架构** - 数据源接口预留，方便后续对接 API
4. **简洁的 UI** - 使用 Flutter Material Design，保持界面简洁高效
5. **本地优先** - 所有数据本地存储，无需网络依赖

## 预定义资产类型

- 现金
- 银行存款
- 股票
- 基金
- 债券
- 房产
- 加密货币
- 期货
- 借款
- 贷款

## 后续扩展

- 股票/基金 API 对接
- 加密货币 API 对接
- 自动定时更新
- 数据导出功能
- 多设备数据同步

## 许可证

本项目采用 MIT 许可证。

## 贡献

欢迎提交 Issue 和 Pull Request！

## 联系方式

如有问题或建议，请通过 GitHub Issues 联系。
