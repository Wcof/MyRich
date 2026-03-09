# Agent 提示词 - 基金资产管理模块开发

## 任务目标

基于现有的 MyRich 项目架构，实现**基金资产的完整管理系统**，包括基金的增删改查、API 对接和自动更新。

## 核心需求

1. **基金数据管理** - 用户可以添加、编辑、删除基金
2. **API 对接** - 通过国内基金 API 获取当前净值
3. **自动更新** - 后台定时自动更新基金净值
4. **手动刷新** - 用户可以手动触发更新

## 现有架构复用

### 已有的 Repository 模式
- `lib/repositories/asset_repository.dart` - 资产数据访问（可复用）
- `lib/repositories/asset_type_repository.dart` - 资产类型管理
- `lib/database/database_helper.dart` - SQLite 单例

### 已有的 Provider 模式
- `lib/providers/asset_provider.dart` - 资产状态管理（可复用）
- `lib/providers/asset_type_provider.dart` - 资产类型管理
- 使用 `ChangeNotifier` 和 `MultiProvider` 模式

### 已有的数据模型
- `lib/models/asset.dart` - 资产模型（可复用）
- `lib/models/asset_type.dart` - 资产类型模型
- `lib/models/asset_record.dart` - 资产记录模型

### 已有的 UI 组件
- `lib/widgets/asset_type_form_dialog.dart` - 表单对话框（参考）
- `lib/screens/asset_list_screen.dart` - 列表页面（参考）

### 已有的数据库
- `lib/database/migrations.dart` - 数据库迁移（需要扩展）
- SQLite 已集成，支持本地存储

## 开发指导

### 第一步：扩展数据库表

在 `lib/database/migrations.dart` 中添加基金表：
```sql
CREATE TABLE funds (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  quantity REAL NOT NULL,
  purchase_price REAL NOT NULL,
  current_price REAL NOT NULL,
  purchase_date INTEGER NOT NULL,
  last_update INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)
```

### 第二步：创建 Fund 模型

创建 `lib/models/fund.dart`：
- 基金代码、名称、份额、购买价格、当前净值
- 计算字段：当前价值、收益率
- toMap() 和 fromMap() 方法

### 第三步：创建 Fund Repository

创建 `lib/repositories/fund_repository.dart`：
- 继承现有的 Repository 模式
- 实现 CRUD 操作（getAll, getById, insert, update, delete）
- 使用 DatabaseHelper 进行数据库操作

### 第四步：创建 Fund Provider

创建 `lib/providers/fund_provider.dart`：
- 继承 ChangeNotifier
- 管理基金列表状态
- 调用 FundRepository 进行数据操作
- 实现 loadFunds(), addFund(), updateFund(), deleteFund()

### 第五步：创建 API 服务

创建 `lib/services/fund_api_service.dart`：
- 调用国内基金 API（推荐：天天基金或新浪财经）
- 实现 fetchFundPrice(code) 方法
- 处理 API 错误和异常
- 实现缓存机制（避免频繁调用）

### 第六步：创建自动更新服务

创建 `lib/services/fund_update_scheduler.dart`：
- 使用 Timer 实现定时更新
- 支持灵活的更新频率（每天、每小时、每分钟）
- 后台更新基金净值
- 更新失败时的重试机制

### 第七步：创建 UI 页面

创建 `lib/screens/fund_list_screen.dart`：
- 显示基金列表
- 添加基金按钮
- 编辑/删除基金功能
- 手动刷新按钮

创建 `lib/widgets/fund_form_dialog.dart`：
- 输入基金代码、份额、购买价格
- 自动查询基金信息
- 表单验证

### 第八步：集成到主导航

在 `lib/main.dart` 中：
- 添加 FundProvider 到 MultiProvider
- 在导航菜单中添加基金管理选项
- 初始化自动更新服务

## 文件结构参考

```
lib/
├── models/
│   └── fund.dart (新建)
├── repositories/
│   └── fund_repository.dart (新建)
├── providers/
│   └── fund_provider.dart (新建)
├── services/
│   ├── fund_api_service.dart (新建)
│   └── fund_update_scheduler.dart (新建)
├── screens/
│   └── fund_list_screen.dart (新建)
├── widgets/
│   └── fund_form_dialog.dart (新建)
└── database/
    └── migrations.dart (扩展)
```

## 关键实现细节

### Fund 模型计算
```dart
double get currentValue => quantity * currentPrice;
double get purchaseValue => quantity * purchasePrice;
double get returnRate => (currentValue - purchaseValue) / purchaseValue;
```

### API 对接建议
- 使用 http 包调用 API
- 推荐 API：天天基金、新浪财经、Yahoo Finance
- 实现错误处理和超时控制

### 自动更新机制
- 默认每小时更新一次
- 用户可以在设置中配置更新频率
- 支持手动刷新

## 注意事项

1. **复用现有模式** - 遵循 Repository + Provider 模式，不要创建新的架构
2. **数据库迁移** - 使用现有的迁移机制，添加新表
3. **错误处理** - API 调用失败时要有降级方案
4. **性能考虑** - 避免频繁的 API 调用，实现缓存
5. **本地优先** - 所有数据本地存储，API 只用于更新净值

## 测试点

- [ ] 基金的增删改查正常
- [ ] API 调用成功获取净值
- [ ] 自动更新定时执行
- [ ] 手动刷新正常工作
- [ ] 数据持久化到 SQLite
- [ ] 错误处理正确
- [ ] 无网络时的降级方案

## 参考文件

- CLAUDE.md - 项目架构说明
- PROJECT_PLAN.md - 项目整体方案
- lib/main.dart - Provider 配置
- lib/repositories/asset_repository.dart - Repository 模式参考
- lib/providers/asset_provider.dart - Provider 模式参考
- lib/database/database_helper.dart - 数据库操作参考
