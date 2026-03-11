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

### 房产资产管理
- 房产信息管理（位置、面积、户型等）
- 房产价格历史记录和趋势图表
- 租赁收入管理（月租金、租期、租客信息）
- 贷款管理（商业贷款、公积金贷款、组合贷款等）
- 贷款还款进度跟踪
- 租金收益率计算
- 位置选择器（支持省市区选择）

### 基金定投管理
- 定投计划创建（日投、周投、双周投、月投）
- 定投计划执行和跟踪
- 定投历史记录查看
- 支持暂停/恢复/取消定投计划
- 基金收益图表展示

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
- **图表**: syncfusion_flutter_charts
- **状态管理**: provider
- **文件路径**: path_provider
- **国际化**: intl

## 项目结构

```
lib/
├── main.dart
├── models/           # 数据模型
│   ├── asset.dart              # 资产模型
│   ├── asset_type.dart         # 资产类型模型
│   ├── asset_record.dart       # 资产记录模型
│   ├── asset_detail.dart       # 资产详情模型
│   ├── stock_data.dart         # 股票数据模型
│   ├── fund_portfolio.dart     # 基金投资组合模型
│   ├── fund_plan.dart          # 基金定投计划模型
│   ├── loan.dart               # 贷款模型
│   ├── real_estate_price.dart  # 房产价格模型
│   ├── rental_income.dart      # 租赁收入模型
│   └── dashboard/              # Dashboard 相关模型
│       ├── dashboard_config.dart
│       └── portfolio_metrics.dart
├── database/         # 数据库层
│   ├── database_helper.dart    # 数据库帮助类
│   └── migrations.dart         # 数据库迁移
├── repositories/     # 数据访问层
│   ├── asset_repository.dart
│   ├── asset_type_repository.dart
│   ├── asset_record_repository.dart
│   ├── asset_detail_repository.dart
│   ├── dashboard_repository.dart
│   ├── fund_plan_repository.dart
│   ├── loan_repository.dart
│   ├── real_estate_price_repository.dart
│   └── rental_income_repository.dart
├── providers/        # 状态管理
│   ├── asset_provider.dart
│   ├── asset_type_provider.dart
│   ├── asset_record_provider.dart
│   ├── asset_detail_provider.dart
│   ├── dashboard_provider.dart
│   ├── fund_sync_provider.dart
│   ├── fund_plan_provider.dart
│   ├── loan_provider.dart
│   ├── real_estate_price_provider.dart
│   └── rental_income_provider.dart
├── screens/          # 页面
│   ├── dashboard_screen.dart           # Dashboard 仪表盘主页
│   ├── asset_list_screen.dart          # 资产列表页面
│   ├── asset_detail_screen.dart        # 通用资产详情页面
│   ├── fund_asset_detail_screen.dart   # 基金资产详情页面
│   ├── enhanced_fund_asset_detail_screen.dart  # 增强版基金资产详情页面
│   ├── stock_asset_detail_screen.dart  # 股票资产详情页面
│   ├── real_estate_asset_detail_screen.dart  # 房产资产详情页面
│   └── asset_detail_list_screen.dart   # 资产详情列表页面
├── widgets/          # 可复用组件
│   ├── asset_form_dialog.dart
│   ├── asset_type_form_dialog.dart
│   ├── asset_detail_form_dialog.dart
│   ├── fund_form_dialog.dart
│   ├── fund_plan_dialog.dart
│   ├── fund_return_chart.dart
│   ├── real_estate_form_dialog.dart
│   ├── real_estate_loan_dialog.dart
│   ├── real_estate_rental_dialog.dart
│   ├── real_estate_price_history_dialog.dart
│   ├── real_estate_price_trend_chart.dart
│   ├── location_picker.dart
│   ├── asset_distribution_chart.dart
│   ├── asset_trend_chart.dart
│   ├── total_assets_card.dart
│   ├── quick_actions_bar.dart
│   └── dashboard/              # Dashboard 组件
│       ├── add_widget_dialog.dart
│       ├── chart_card.dart
│       ├── stat_card.dart
│       └── widget_config_dialog.dart
├── services/         # 服务层
│   ├── akshare_api_service.dart    # AKShare API 服务（股票数据）
│   ├── fund_api_service.dart       # 基金 API 服务
│   ├── fund_history_api_service.dart  # 基金历史数据服务
│   ├── fund_asset_mapper.dart      # 基金资产映射器
│   ├── fund_update_scheduler.dart  # 基金更新调度器
│   ├── fund_plan_executor.dart     # 基金定投执行器
│   ├── real_estate_asset_mapper.dart  # 房产资产映射器
│   ├── data_source_service.dart    # 数据源服务
│   └── portfolio_analyzer.dart     # 投资组合分析器
├── utils/            # 工具类
│   ├── grid_layout_manager.dart
│   └── constants.dart
└── theme/            # 主题
    └── app_theme.dart
```

## 页面代码对应关系

### 1. Dashboard 仪表盘页面
**文件**: `lib/screens/dashboard_screen.dart`

**功能说明**:
- 应用主页面，展示资产可视化看板
- 支持网格布局系统，可拖拽调整组件位置和大小
- 包含多种组件类型：统计卡片、图表卡片、表格、仪表盘、进度条、KPI、时间线、热力图、日历、便签
- 支持编辑模式和查看模式切换
- 可添加、删除、配置各个组件

**主要组件**:
- `DashboardScreen`: 主页面组件
- `_DraggableResizableWidget`: 可拖拽调整大小的组件包装器
- `_GridPainter`: 网格背景绘制器

### 2. 资产列表页面
**文件**: `lib/screens/asset_list_screen.dart`

**功能说明**:
- 展示所有资产的列表
- 按资产类型分组显示
- 支持添加、编辑、删除资产
- 点击资产可进入对应的详情页面

### 3. 通用资产详情页面
**文件**: `lib/screens/asset_detail_screen.dart`

**功能说明**:
- 适用于所有非特殊类型资产的详情展示
- 包含三个标签页：概览、价值走势、资金记录
- **概览页**: 显示资产基本信息（名称、类型、位置、创建时间等）和快速统计（当前价值、平均价值、最高价值、最低价值）
- **价值走势页**: 使用折线图展示资产价值变化，支持日/周/月/年时间筛选
- **资金记录页**: 展示资产的所有历史记录列表
- 支持添加、编辑、删除记录

**主要方法**:
- `_buildOverviewTab()`: 构建概览标签页
- `_buildTrendsTab()`: 构建价值走势标签页
- `_buildHistoryTab()`: 构建资金记录标签页
- `_buildValueTrendCard()`: 构建价值趋势图表卡片
- `_showAddRecordDialog()`: 显示添加记录对话框

### 4. 基金资产详情页面
**文件**: `lib/screens/fund_asset_detail_screen.dart`

**功能说明**:
- 专门针对基金类型资产的详情页面
- 展示基金特有信息：基金代码、基金名称、持有份额、买入净值、当前净值、买入日期
- **收益分析卡片**: 显示投入成本、当前价值、累计收益、收益率
- **交易记录卡片**: 展示基金交易历史
- **快速操作区**:
  - 更新净值：手动刷新基金净值
  - 自动/停止：开启或停止自动同步
  - 买入：添加买入记录
  - 卖出：添加卖出记录
  - 编辑：修改基金信息
  - 删除：删除该基金资产
- 支持自动同步基金净值（通过 `FundSyncProvider`）

**主要方法**:
- `_buildHeader()`: 构建顶部渐变标题栏，显示基金名称、代码、当前价值、收益率
- `_buildFundInfoCard()`: 构建基金信息卡片
- `_buildReturnCard()`: 构建收益分析卡片
- `_buildTransactionRecordsCard()`: 构建交易记录卡片
- `_buildQuickActions()`: 构建快速操作按钮区
- `_showBuyDialog()`: 显示买入对话框
- `_showSellDialog()`: 显示卖出对话框
- `_handleBuy()`: 处理买入逻辑
- `_handleSell()`: 处理卖出逻辑

### 5. 股票资产详情页面
**文件**: `lib/screens/stock_asset_detail_screen.dart`

**功能说明**:
- 专门针对股票类型资产的详情页面
- 通过 AKShare API 获取实时股票数据
- **股票信息卡片**: 显示今开、昨收、最高、最低、成交量
- **K线图卡片**: 展示股票K线数据，支持多种周期（1分钟、5分钟、15分钟、30分钟、60分钟、日、周、月）
- **快速操作**: 刷新数据、编辑资产

**主要方法**:
- `_buildHeader()`: 构建顶部标题栏，显示股票名称、代码、当前价格、涨跌幅
- `_buildStockInfoCard()`: 构建股票信息卡片
- `_buildKLineCard()`: 构建K线图卡片
- `_loadStockData()`: 加载股票实时数据和K线数据

### 6. 资产详情列表页面
**文件**: `lib/screens/asset_detail_list_screen.dart`

**功能说明**:
- 展示某个资产的所有详情记录列表
- 支持添加、编辑、删除详情记录
- 用于管理资产的额外详细信息

### 7. 房产资产详情页面
**文件**: `lib/screens/real_estate_asset_detail_screen.dart`

**功能说明**:
- 专门针对房产类型资产的详情页面
- **房产信息卡片**: 显示位置、面积、户型、购买价格、当前价值
- **租赁信息卡片**: 显示租赁状态、月租金、租期、租客信息、年租金收入
- **贷款信息卡片**: 显示贷款类型、贷款金额、利率、期限、还款方式、已还金额、剩余金额
- **价格历史卡片**: 展示房产价格历史记录和趋势图表
- **快速操作**:
  - 添加价格记录：手动添加房产价格记录
  - 编辑租赁信息：修改租赁相关信息
  - 编辑贷款信息：修改贷款相关信息
  - 编辑资产：修改房产基本信息
  - 删除：删除该房产资产
- 支持租金收益率计算
- 支持贷款还款进度跟踪

**主要方法**:
- `_buildHeader()`: 构建顶部标题栏，显示房产名称、位置、当前价值
- `_buildPropertyInfoCard()`: 构建房产信息卡片
- `_buildRentalInfoCard()`: 构建租赁信息卡片
- `_buildLoanInfoCard()`: 构建贷款信息卡片
- `_buildPriceHistoryCard()`: 构建价格历史卡片
- `_buildQuickActions()`: 构建快速操作按钮区
- `_showAddPriceDialog()`: 显示添加价格对话框
- `_showEditRentalDialog()`: 显示编辑租赁对话框
- `_showEditLoanDialog()`: 显示编辑贷款对话框

### 8. 增强版基金资产详情页面
**文件**: `lib/screens/enhanced_fund_asset_detail_screen.dart`

**功能说明**:
- 增强版的基金资产详情页面，包含更多功能
- 在原有基金详情页基础上增加了定投计划管理
- **定投计划卡片**: 显示定投计划列表，支持创建、暂停、恢复、取消定投
- **基金收益图表**: 展示基金历史收益走势
- 支持定投计划自动执行

## 数据模型对应关系

### 资产相关模型
- `Asset` (`lib/models/asset.dart`): 基础资产模型，包含名称、类型ID、位置、自定义数据等
- `AssetType` (`lib/models/asset_type.dart`): 资产类型模型，包含类型名称、图标、颜色、自定义字段定义
- `AssetRecord` (`lib/models/asset_record.dart`): 资产记录模型，包含资产ID、价值、数量、单价、记录日期等
- `AssetDetail` (`lib/models/asset_detail.dart`): 资产详情模型，用于存储资产的额外详细信息

### 基金相关模型
- `FundData` (`lib/services/fund_asset_mapper.dart`): 基金数据模型，包含基金代码、名称、份额、净值、收益率等
- `FundPortfolio` (`lib/models/fund_portfolio.dart`): 基金投资组合模型

### 股票相关模型
- `StockData` (`lib/models/stock_data.dart`): 股票数据模型，包含股票代码、名称、价格、涨跌幅、成交量等
- `StockKLine` (`lib/models/stock_data.dart`): K线数据模型

### 房产相关模型
- `RealEstatePrice` (`lib/models/real_estate_price.dart`): 房产价格模型，包含价格、来源、记录日期等
- `RentalIncome` (`lib/models/rental_income.dart`): 租赁收入模型，包含租赁状态、月租金、租期、租客信息等
- `Loan` (`lib/models/loan.dart`): 贷款模型，包含贷款类型、金额、利率、期限、还款方式等

### 基金定投相关模型
- `FundPlan` (`lib/models/fund_plan.dart`): 基金定投计划模型，包含定投周期、金额、执行状态等

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

### asset_details 表（资产详情）
```sql
CREATE TABLE asset_details (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  asset_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  content TEXT,
  detail_type TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
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

### fund_plans 表（基金定投计划）
```sql
CREATE TABLE fund_plans (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  asset_id INTEGER NOT NULL,
  fund_code TEXT NOT NULL,
  fund_name TEXT NOT NULL,
  amount REAL NOT NULL,
  period INTEGER NOT NULL,  -- 0:日投, 1:周投, 2:双周投, 3:月投
  week_day INTEGER,  -- 周几 (1-7)
  month_day INTEGER,  -- 几号 (1-31)
  start_date INTEGER NOT NULL,
  end_date INTEGER,
  status INTEGER DEFAULT 0,  -- 0:active, 1:paused, 2:completed, 3:cancelled
  created_at INTEGER NOT NULL,
  last_executed_at INTEGER,
  next_execute_at INTEGER,
  FOREIGN KEY (asset_id) REFERENCES assets(id)
);
```

### loans 表（贷款信息）
```sql
CREATE TABLE loans (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  asset_id INTEGER NOT NULL,
  loan_type TEXT NOT NULL,
  custom_loan_type TEXT,
  loan_amount REAL NOT NULL,
  loan_rate REAL NOT NULL,
  loan_period INTEGER NOT NULL,  -- 贷款期限（月）
  repayment_method TEXT NOT NULL,
  loan_date INTEGER NOT NULL,
  due_date INTEGER NOT NULL,
  paid_amount REAL DEFAULT 0,
  remaining_amount REAL NOT NULL,
  monthly_payment REAL NOT NULL,
  status TEXT DEFAULT 'active',
  receiving_bank_account_id INTEGER,
  payment_bank_account_id INTEGER,
  related_asset_id INTEGER,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (asset_id) REFERENCES assets(id)
);
```

### real_estate_prices 表（房产价格历史）
```sql
CREATE TABLE real_estate_prices (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  asset_id INTEGER NOT NULL,
  price REAL NOT NULL,
  source TEXT NOT NULL,
  record_date INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (asset_id) REFERENCES assets(id)
);
```

### rental_incomes 表（租赁收入）
```sql
CREATE TABLE rental_incomes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  asset_id INTEGER NOT NULL,
  rental_status TEXT NOT NULL,
  monthly_rent REAL NOT NULL,
  rental_start_date INTEGER NOT NULL,
  rental_end_date INTEGER,
  tenant_name TEXT,
  annual_income REAL NOT NULL,
  status TEXT DEFAULT 'active',
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (asset_id) REFERENCES assets(id)
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
6. **多类型资产支持** - 针对不同资产类型（基金、股票等）提供专门的详情页面

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
