# Dashboard 产品方案（面向开发 Agent）

## 1. 目标与范围

基于现有 `MyRich` 代码，落地一个可持续扩展的基金资产 Dashboard：

1. 资产占比（饼图）
2. 收益统计（总资产、总收益、收益率）
3. 趋势展示（按日/周/月）
4. 可配置组件（保留当前拖拽能力）

不在本方案范围：

1. 云同步
2. 多用户权限
3. 复杂量化指标（夏普/最大回撤等）

## 2. 现有代码复用清单

直接复用：

1. `Provider` 框架：`lib/providers/dashboard_provider.dart`、`lib/providers/asset_provider.dart`
2. 图表与卡片组件：`lib/widgets/dashboard/chart_card.dart`、`lib/widgets/dashboard/stat_card.dart`、`lib/widgets/asset_distribution_chart.dart`、`lib/widgets/asset_trend_chart.dart`
3. 页面承载：`lib/screens/dashboard_screen.dart`
4. 数据存储：`lib/repositories/dashboard_repository.dart`、`lib/database/database_helper.dart`
5. 资产模型：`lib/models/asset.dart`、`lib/models/asset_record.dart`

扩展点（新增）：

1. `lib/services/portfolio_analyzer.dart`
2. `lib/models/dashboard/portfolio_metrics.dart`

## 3. 业务口径（统一）

1. 当前价值 `currentValue = quantity * currentPrice`
2. 成本价值 `costValue = quantity * purchasePrice`
3. 收益额 `profit = currentValue - costValue`
4. 收益率 `returnRate = profit / costValue`（`costValue == 0` 时返回 `0`）
5. 占比 `allocation = currentValue / totalCurrentValue`

说明：`quantity/purchasePrice/currentPrice` 先从 `assets.custom_data` 读取；没有则降级为 `asset_records` 的最近值。

## 4. 技术设计

### 4.1 领域模型

新增 `PortfolioMetrics`（纯计算结果）：

1. `totalCurrentValue`
2. `totalCostValue`
3. `totalProfit`
4. `totalReturnRate`
5. `allocationItems`（名称、价值、占比）
6. `trendSeries`（时间点、价值）

### 4.2 服务层

新增 `PortfolioAnalyzer`：

1. `buildMetrics(List<Asset> assets, List<AssetRecord> records)`
2. `buildAllocation(...)`
3. `buildTrend(...)`
4. `sanitizeAssetNumericFields(...)`

要求：

1. 纯函数优先，可单测
2. 空数据返回可渲染默认值，不抛 UI 异常

### 4.3 Provider 改造

在 `DashboardProvider` 增加：

1. `PortfolioMetrics? _metrics`
2. `Future<void> refreshMetrics({bool force = false})`
3. 缓存策略：资产数据未变时不重复重算

数据来源：

1. 从 `AssetProvider` 注入数据（通过 `DashboardScreen` 触发）
2. 需要时从 `AssetRecordProvider` 拉趋势源数据

### 4.4 UI 改造

`dashboard_screen.dart` 负责：

1. 读取 `metrics`，把已有 `stat_card` 与 `chart_card` 绑定真实数据
2. 无数据态：显示“去添加基金资产”引导
3. 刷新动作：手动刷新触发 `refreshMetrics(force: true)`

## 5. Agent 执行任务拆分

### Agent A：数据计算层

1. 新建 `portfolio_metrics.dart`
2. 新建 `portfolio_analyzer.dart`
3. 补充单元测试：`test/services/portfolio_analyzer_test.dart`

验收：

1. 关键公式测试通过
2. 边界数据（空、0、负值）处理稳定

### Agent B：Provider 集成

1. 修改 `dashboard_provider.dart` 增加 metrics 状态与刷新入口
2. 保持现有拖拽/布局逻辑不回归

验收：

1. 切页返回后数据可复用
2. 刷新时 UI 可见 loading 态

### Agent C：UI 绑定与交互

1. 修改 `dashboard_screen.dart` 映射 metrics 到现有组件
2. 对接空数据态、错误态、刷新按钮

验收：

1. 图表与统计卡数据一致
2. 无数据时不报错

## 6. 风险与约束

1. 当前 `Asset.customData` 是字符串，存在脏数据风险；需统一解析函数
2. 现有 Dashboard 有大量组件类型，先覆盖 `stat/chart/table` 的基金场景
3. 计算口径必须固定，否则后续基金模块会出现对账偏差

## 7. 最小可交付（MVP-Dashboard）

1. 总资产/总收益/收益率三张统计卡
2. 基金占比饼图
3. 最近 30 天趋势折线图
4. 手动刷新按钮

## 8. 完成定义（DoD）

1. `flutter analyze` 无新增 `error`
2. 新增测试通过
3. 无基金、单基金、多基金三种场景截图可提供
4. 代码评审通过（至少 1 位 Agent reviewer）

