# 修复资产详情页面路由规格

## Why
当前项目中虽然存在 `stock_asset_detail_screen.dart` 股票资产详情页面，但在 `main.dart` 的 `_getAssetDetailScreen` 方法中没有为股票类型配置路由，导致股票资产仍然使用通用的 `AssetDetailScreen`，无法展示股票特有的功能（如K线图、实时行情等）。

## What Changes
- 修改 `main.dart` 中的 `_getAssetDetailScreen` 方法，为股票类型添加路由到 `StockAssetDetailScreen`
- 确保导入 `stock_asset_detail_screen.dart`

## Impact
- Affected specs: 资产详情页面路由逻辑
- Affected code: `lib/main.dart`

## ADDED Requirements
### Requirement: 股票资产详情页面路由
系统 SHALL 为股票类型的资产提供专门的详情页面路由。

#### Scenario: 用户点击股票资产
- **WHEN** 用户点击类型为"股票"的资产
- **THEN** 系统应导航到 `StockAssetDetailScreen` 而不是通用的 `AssetDetailScreen`

## MODIFIED Requirements
### Requirement: 资产详情页面路由逻辑
修改 `_getAssetDetailScreen` 方法，根据资产类型名称路由到对应的详情页面：
- "基金" → `FundAssetDetailScreen`
- "股票" → `StockAssetDetailScreen`
- 其他类型 → `AssetDetailScreen`
