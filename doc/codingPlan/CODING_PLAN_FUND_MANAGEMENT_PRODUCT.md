# Fund Management 产品方案（面向开发 Agent）

## 1. 目标与范围

在现有资产系统上实现“基金资产管理”闭环：

1. 基金资产新增/编辑/删除
2. 净值拉取（手动 + 定时）
3. 本地持久化与历史记录
4. 与 Dashboard 指标联动

不在本次范围：

1. 云端账号体系
2. 券商直连交易
3. 多市场复杂税费计算

## 2. 复用策略（避免重造轮子）

优先复用现有 `assets` 主表与 Provider/Repository 结构，不新建 `funds` 平行主表。

复用点：

1. `lib/models/asset.dart`
2. `lib/repositories/asset_repository.dart`
3. `lib/providers/asset_provider.dart`
4. `lib/screens/asset_list_screen.dart`
5. `lib/widgets/asset_form_dialog.dart`
6. `lib/providers/asset_record_provider.dart` + `asset_records`（历史净值/估值）

新增点：

1. `lib/services/fund_api_service.dart`
2. `lib/services/fund_update_scheduler.dart`
3. `lib/services/fund_asset_mapper.dart`
4. 可选 `lib/providers/fund_sync_provider.dart`（仅负责更新任务，不替代 `AssetProvider`）

## 3. 数据建模方案（在现有 assets 上扩展）

### 3.1 资产类型约束

在 `asset_types` 确保存在 `基金` 类型（系统类型）。

### 3.2 `assets.custom_data` 约定（JSON）

基金资产使用以下字段：

1. `fundCode`：基金代码（必填）
2. `fundName`：基金名称（必填）
3. `quantity`：份额（必填）
4. `purchasePrice`：买入净值（必填）
5. `currentPrice`：当前净值（必填）
6. `purchaseDate`：买入日期毫秒时间戳（必填）
7. `lastUpdateAt`：最近更新毫秒时间戳（必填）
8. `apiSource`：数据源标识（可选）

说明：该方案与当前代码兼容，成本最低，可直接给 Dashboard 读取。

### 3.3 历史数据

通过 `asset_records` 存净值轨迹：

1. `asset_id` 指向基金资产
2. `value` 存当日估值（当前价值）
3. `unit_price` 存净值
4. `record_date` 为快照时间

## 4. API 与更新设计

### 4.1 FundApiService

接口定义：

1. `Future<FundQuoteResult> fetchQuote(String fundCode)`
2. `Future<List<FundQuoteResult>> fetchQuotes(List<String> fundCodes)`

结果包含：

1. `fundCode`
2. `fundName`
3. `nav`（净值）
4. `asOf`（时间）
5. `source`

容错要求：

1. 网络失败时返回可识别错误码，不阻塞本地读
2. 单只基金失败不影响批量更新其余基金

### 4.2 调度器 FundUpdateScheduler

能力：

1. `start({Duration interval})`
2. `stop()`
3. `runOnce({bool userTriggered = false})`

默认策略：

1. 前台运行时每 60 分钟一次
2. 用户点击刷新走 `runOnce(userTriggered: true)`
3. 最小更新间隔保护（例如 5 分钟）

## 5. UI 方案

## 5.1 基金列表入口

优先方案：复用现有资产页筛选 `基金` 类型，新增“基金模式”操作区。

UI 需求：

1. 顶部显示“上次更新”时间
2. “刷新净值”按钮
3. 每行显示：代码、份额、买入净值、当前净值、收益率

## 5.2 表单

在 `asset_form_dialog.dart` 增加基金分支：

1. 输入 `fundCode`
2. 自动查询 `fundName/currentPrice`
3. 输入 `quantity/purchasePrice`
4. 保存后写入 `assets.custom_data`

## 6. 与 Dashboard 联动契约

必须保证以下字段可直接被 Dashboard Analyzer 消费：

1. `quantity`
2. `purchasePrice`
3. `currentPrice`
4. `lastUpdateAt`

每次净值更新后：

1. 更新 `assets.updated_at`
2. 写入一条 `asset_records` 快照
3. 触发 `AssetProvider.loadAssets()`，让 Dashboard 可即时刷新

## 7. Agent 执行拆分

### Agent A：基金数据与 API

1. 新建 `fund_api_service.dart`
2. 新建 `fund_asset_mapper.dart`
3. 单测：API 解析与错误映射

### Agent B：更新链路

1. 新建 `fund_update_scheduler.dart`
2. 集成批量更新与写库
3. 增量更新策略（仅价格变化才写记录）

### Agent C：页面与交互

1. 资产页基金模式 UI
2. 基金表单联动 API 自动填充
3. 手动刷新按钮与状态提示

### Agent D：联调与验收

1. 验证 Dashboard 指标同步
2. 验证离线可用与失败重试
3. 回归现有非基金资产流程

## 8. 里程碑

1. M1：基金 CRUD（复用资产表）完成
2. M2：单只基金净值拉取完成
3. M3：批量更新 + 调度器完成
4. M4：Dashboard 联动完成

## 9. 验收标准（DoD）

1. 能新增基金并显示收益率
2. 刷新后净值变化可见，更新时间正确
3. Dashboard 的总资产/收益与基金列表一致
4. `flutter analyze` 无新增 `error`
5. 关键链路有测试（至少 API 解析 + 计算 + 更新写库）

## 10. 实施注意

1. 不建议新开 `funds` 主表，否则与现有 `assets` 生态割裂
2. 若后续资产类型扩展，可把 `custom_data` 解析下沉为 `AssetDataAdapter` 抽象
3. 定时任务先做前台稳定版，后台常驻可后续单独评估（macOS 生命周期差异）

