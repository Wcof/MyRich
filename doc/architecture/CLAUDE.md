# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

MyRich 是一个基于 Flutter 开发的跨平台个人资产管理系统，支持多种资产类型（现金、股票、基金、房产等），提供类似钉钉/飞书的 Dashboard 看板功能。

## 常用命令

### 开发和运行
```bash
# 获取依赖
flutter pub get

# 运行项目（macOS）
flutter run -d macos

# 运行项目（Windows）
flutter run -d windows

# 构建项目（macOS）
flutter build macos

# 构建项目（Windows）
flutter build windows

# 运行测试
flutter test

# 运行单个测试文件
flutter test test/widget_test.dart

# 代码分析
flutter analyze

# 格式化代码
dart format lib/
```

## 项目架构

### 分层架构（Repository Pattern）

```
lib/
├── main.dart                 # 应用入口，Provider 配置
├── models/                   # 数据模型层
│   ├── asset.dart
│   ├── asset_type.dart
│   ├── asset_detail.dart
│   ├── asset_record.dart
│   ├── dashboard_model.dart
│   └── data_source/
│       └── data_source_config.dart
├── database/                 # 数据库层
│   ├── database_helper.dart  # SQLite 单例管理
│   └── migrations.dart       # 数据库迁移
├── repositories/             # 数据访问层（Repository Pattern）
│   ├── asset_repository.dart
│   ├── asset_type_repository.dart
│   ├── asset_detail_repository.dart
│   ├── asset_record_repository.dart
│   └── dashboard_repository.dart
├── providers/                # 状态管理层（Provider）
│   ├── asset_provider.dart
│   ├── asset_type_provider.dart
│   ├── asset_detail_provider.dart
│   ├── asset_record_provider.dart
│   └── dashboard_provider.dart
├── services/                 # 业务逻辑服务
│   └── data_source_service.dart
├── screens/                  # 页面层
│   ├── dashboard_screen.dart
│   ├── asset_list_screen.dart
│   ├── asset_detail_screen.dart
│   └── asset_detail_list_screen.dart
├── widgets/                  # 可复用组件
│   ├── dashboard/
│   │   ├── chart_card.dart
│   │   ├── stat_card.dart
│   │   ├── add_widget_dialog.dart
│   │   └── widget_config_dialog.dart
│   ├── asset_distribution_chart.dart
│   ├── asset_trend_chart.dart
│   ├── asset_type_form_dialog.dart
│   ├── asset_detail_form_dialog.dart
│   ├── total_assets_card.dart
│   └── quick_actions_bar.dart
├── theme/                    # 主题配置
│   └── app_theme.dart
└── utils/                    # 工具类
    └── grid_layout_manager.dart
```

### 数据流

1. **UI 层** (Screens/Widgets) → 调用 Provider 方法
2. **状态管理** (Providers) → 调用 Repository 方法，管理状态
3. **数据访问** (Repositories) → 调用 DatabaseHelper 执行 SQL
4. **数据库** (DatabaseHelper) → SQLite 操作

### 关键设计决策

#### 1. 状态管理：Provider
- 使用 `ChangeNotifier` 和 `MultiProvider` 管理全局状态
- 每个主要功能模块有对应的 Provider（Asset、AssetType、Dashboard 等）
- Provider 负责数据加载、缓存和错误处理

#### 2. 数据库：SQLite + sqflite_common_ffi
- 使用 `sqflite_common_ffi` 支持 macOS/Windows 桌面平台
- 单例模式管理数据库连接
- 支持数据库迁移机制（DatabaseMigrations）

#### 3. 架构模式：Repository Pattern
- Repository 层完全隔离数据库操作
- Provider 只依赖 Repository，不直接操作数据库
- 便于测试和数据源切换

#### 4. Dashboard 系统
- 网格布局系统（4 列网格）
- 支持自定义组件配置（类型、数据源、位置、大小）
- 组件类型：stat（统计卡片）、chart（图表）、table（表格）、gauge（仪表）
- 数据源配置支持 4 种类型：单个资产、资产类型聚合、多个资产、时间序列

#### 5. 资产管理三层结构
- **Asset**：资产基本信息（名称、类型、位置）
- **AssetDetail**：资产具体明细（针对不同资产类型的详细数据）
- **AssetRecord**：资产历史记录（价值变化、时间序列数据）

**关键设计原则**：不同资产类型有不同的数据结构
- 每种资产类型只存储它需要的字段，避免冗余
- 例如：房产需要地理位置，基金不需要；基金需要基金代码，房产不需要
- 这样设计提高了灵活性和可扩展性

## 核心模块说明

### Asset 模块
- 管理用户的资产列表
- 支持按类型分组显示
- 支持添加、编辑、删除资产

### AssetType 模块
- 预定义资产类型：现金、银行存款、股票、基金、债券、房产、加密货币等
- 支持自定义资产类型和字段定义
- 字段定义存储为 JSON，支持动态扩展

**10 种预定义资产类型及其 AssetDetail 字段**：

| 资产类型 | AssetDetail 字段 | 说明 |
|---------|-----------------|------|
| 现金 (Cash) | 钱包名称、币种、金额、时间 | 手持现金或钱包中的现金 |
| 银行存款 (Bank Deposit) | 银行、卡号、账户类型、余额、时间 | 银行账户中的存款 |
| 股票 (Stock) | 股票代码、持仓数量、购买价格、当前价格 | A股、港股等股票投资 |
| 基金 (Fund) | 基金代码、份额、购买价格、当前净值 | 公募基金、私募基金等 |
| 债券 (Bond) | 债券名称、代码、数量、面值、购买价格、当前价格 | 国债、企业债等 |
| 房产 (Real Estate) | 名称、地址、面积、购买价格、当前价值 | 住宅、商业地产等 |
| 加密货币 (Cryptocurrency) | 币种、数量、购买价格、当前价格 | 比特币、以太坊等 |
| 期货 (Futures) | 合约代码、数量、购买价格、当前价格、到期日期 | 商品期货、金融期货等 |
| 借款 (Loan) | 借款人、金额、利率、借款日期、到期日期 | 个人借出的款项 |
| 贷款 (Debt) | 贷款机构、金额、利率、贷款日期、到期日期 | 个人欠下的债务 |

**关键设计原则**：
- 每种资产类型只存储必需的字段，避免冗余
- AssetDetail 层存储资产类型特定的详细信息
- Asset 层存储通用信息（名称、类型、位置）
- AssetRecord 层存储历史记录（价值变化）

### Dashboard 模块
- 可视化看板系统
- 支持多个看板配置
- 组件自动布局算法（GridLayoutManager）
- 支持拖拽调整组件位置和大小（编辑模式）

### DataSource 模块
- 为 Dashboard 组件提供灵活的数据源配置
- 支持字段映射和数据聚合
- DataSourceService 负责数据查询和缓存

## 开发指南

### 添加新的资产类型
1. 在 `DatabaseMigrations` 中添加预定义资产类型
2. 在 `AssetTypeProvider` 中加载资产类型
3. 在相应的 Form Dialog 中添加字段定义

### 添加新的 Dashboard 组件
1. 在 `chart_card.dart` 中添加新的组件渲染逻辑
2. 在 `add_widget_dialog.dart` 中添加组件选项
3. 在 `widget_config_dialog.dart` 中添加配置选项
4. 在 `DataSourceService` 中添加数据查询逻辑

### 修改数据库结构
1. 在 `DatabaseMigrations` 中添加新的迁移
2. 更新对应的 Model 类
3. 更新对应的 Repository 类

### 添加新的 Provider
1. 创建新的 Provider 类（继承 ChangeNotifier）
2. 在 `main.dart` 的 `MultiProvider` 中注册
3. 在需要的地方使用 `Provider.of<YourProvider>(context)` 或 `context.watch<YourProvider>()`

## 重要文件

- **lib/main.dart**：应用入口，Provider 配置，主导航结构
- **lib/database/database_helper.dart**：数据库单例管理
- **lib/database/migrations.dart**：数据库表定义和迁移
- **lib/theme/app_theme.dart**：全局主题配置
- **lib/utils/grid_layout_manager.dart**：Dashboard 网格布局算法
- **lib/services/data_source_service.dart**：Dashboard 数据源服务

## 依赖说明

- **provider**：状态管理
- **sqflite_common_ffi**：SQLite 数据库（支持桌面平台）
- **syncfusion_flutter_charts**：图表库
- **flutter_staggered_grid_view**：网格布局
- **intl**：国际化和日期格式化
- **path_provider**：获取应用文档目录

## 测试

- 测试文件位于 `test/` 目录
- 当前只有基础的 widget_test.dart
- 建议为 Repository 和 Provider 添加单元测试

## 已知问题和设计文档

项目根目录有多个设计文档：
- `ASSET_DETAIL_MANAGEMENT_DESIGN.md`：资产明细管理设计
- `DASHBOARD_DATA_SOURCE_OPTIMIZATION.md`：Dashboard 数据源优化设计
- `DASHBOARD_GRID_LAYOUT_OPTIMIZATION.md`：网格布局优化设计

## 开发环境

- Flutter SDK：3.0+
- Dart SDK：3.0+
- macOS 开发环境：Xcode + CocoaPods
- Windows 开发环境：Visual Studio Build Tools
