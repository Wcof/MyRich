# Agent 提示词 - Dashboard 仪表盘模块开发

## 任务目标

基于现有的 MyRich 项目架构，实现**基金资产的 Dashboard 可视化系统**。

## 核心需求

1. **资产占比展示** - 饼图显示各基金的资产占比
2. **收益率计算** - 简单收益率 = (当前价值 - 购买价值) / 购买价值
3. **统计卡片** - 显示总资产、总收益、平均收益率等
4. **趋势分析** - 基于占比变化看资产增长

## 现有架构复用

### 已有的 Provider 模式
- `lib/providers/dashboard_provider.dart` - 已实现 Dashboard 状态管理
- `lib/providers/asset_provider.dart` - 资产数据管理
- 使用 `ChangeNotifier` 和 `MultiProvider` 模式

### 已有的 UI 组件
- `lib/widgets/dashboard/chart_card.dart` - 图表卡片组件
- `lib/widgets/dashboard/stat_card.dart` - 统计卡片组件
- `lib/widgets/asset_distribution_chart.dart` - 资产分布图表
- `lib/widgets/asset_trend_chart.dart` - 资产趋势图表
- Syncfusion Charts 库已集成

### 已有的数据模型
- `lib/models/asset.dart` - 资产模型
- `lib/models/dashboard_model.dart` - Dashboard 配置模型
- `lib/models/data_source/data_source_config.dart` - 数据源配置

### 已有的数据访问层
- `lib/repositories/asset_repository.dart` - 资产数据访问
- `lib/repositories/dashboard_repository.dart` - Dashboard 配置存储
- `lib/database/database_helper.dart` - SQLite 单例

## 开发指导

### 第一步：扩展 Dashboard Provider

在 `lib/providers/dashboard_provider.dart` 中添加：
- 占比计算方法：`calculatePortfolioAllocation()`
- 收益率计算方法：`calculateReturns()`
- 统计数据计算方法：`calculateStatistics()`

### 第二步：创建数据分析服务

创建 `lib/services/portfolio_analyzer.dart`：
- 计算各基金的当前价值
- 计算占比百分比
- 计算收益率
- 生成趋势数据

### 第三步：更新 Dashboard UI

在 `lib/screens/dashboard_screen.dart` 中：
- 调用 Provider 获取占比数据
- 使用 `asset_distribution_chart.dart` 显示饼图
- 使用 `stat_card.dart` 显示统计信息
- 支持数据刷新

### 第四步：集成基金数据

- 从 Asset Provider 获取基金列表
- 计算每个基金的当前价值（份额 × 当前净值）
- 计算总资产和占比

## 关键计算公式

```
当前价值 = 份额 × 当前净值
总资产 = 所有基金的当前价值之和
占比 = 单个基金当前价值 / 总资产 × 100%
收益率 = (当前价值 - 购买价值) / 购买价值 × 100%
购买价值 = 份额 × 购买价格
```

## 文件结构参考

```
lib/
├── providers/
│   └── dashboard_provider.dart (扩展占比和收益计算)
├── services/
│   └── portfolio_analyzer.dart (新建 - 数据分析)
├── screens/
│   └── dashboard_screen.dart (更新 - 集成基金数据)
└── widgets/
    └── dashboard/
        ├── chart_card.dart (已有 - 复用)
        ├── stat_card.dart (已有 - 复用)
        └── portfolio_summary.dart (可选 - 新建)
```

## 注意事项

1. **复用现有组件** - 不要重新创建图表组件，使用已有的 `asset_distribution_chart.dart`
2. **遵循 Provider 模式** - 所有状态管理通过 Provider，不要直接操作数据库
3. **本地存储** - 所有数据从 SQLite 读取，不需要 API 调用
4. **性能考虑** - 占比计算应该缓存，避免频繁重新计算
5. **错误处理** - 处理空数据、异常情况

## 测试点

- [ ] 占比计算正确（总和 = 100%）
- [ ] 收益率计算正确
- [ ] 饼图显示正确
- [ ] 统计卡片数据准确
- [ ] 数据刷新正常
- [ ] 无基金时的处理

## 参考文件

- CLAUDE.md - 项目架构说明
- PROJECT_PLAN.md - 项目整体方案
- lib/main.dart - Provider 配置
- lib/theme/app_theme.dart - 主题配置
