import 'dart:convert';
import '../models/asset.dart';
import '../models/asset_record.dart';
import '../models/dashboard/portfolio_metrics.dart';

class PortfolioAnalyzer {
  static PortfolioMetrics buildMetrics(
    List<Asset> assets,
    List<AssetRecord> records,
  ) {
    double totalCurrentValue = 0;
    double totalCostValue = 0;
    final allocationItems = <AllocationItem>[];

    for (final asset in assets) {
      final (currentValue, costValue) = _calculateAssetValues(asset, records);
      totalCurrentValue += currentValue;
      totalCostValue += costValue;

      allocationItems.add(
        AllocationItem(
          name: asset.name,
          value: currentValue,
          allocation: 0,
        ),
      );
    }

    final totalProfit = totalCurrentValue - totalCostValue;
    final totalReturnRate =
        totalCostValue > 0 ? totalProfit / totalCostValue : 0.0;

    for (int i = 0; i < allocationItems.length; i++) {
      final item = allocationItems[i];
      final allocation =
          totalCurrentValue > 0 ? item.value / totalCurrentValue : 0.0;
      allocationItems[i] = AllocationItem(
        name: item.name,
        value: item.value,
        allocation: allocation,
      );
    }

    final trendSeries = _buildTrendSeries(assets, records);

    return PortfolioMetrics(
      totalCurrentValue: totalCurrentValue,
      totalCostValue: totalCostValue,
      totalProfit: totalProfit,
      totalReturnRate: totalReturnRate,
      allocationItems: allocationItems,
      trendSeries: trendSeries,
    );
  }

  static (double currentValue, double costValue) _calculateAssetValues(
    Asset asset,
    List<AssetRecord> records,
  ) {
    double? quantity;
    double? purchasePrice;
    double? currentPrice;

    if (asset.customData != null && asset.customData!.isNotEmpty) {
      try {
        final data = jsonDecode(asset.customData!) as Map<String, dynamic>;
        quantity = (data['quantity'] as num?)?.toDouble();
        purchasePrice = (data['purchasePrice'] as num?)?.toDouble();
        currentPrice = (data['currentPrice'] as num?)?.toDouble();
      } catch (_) {}
    }

    if (quantity == null || purchasePrice == null || currentPrice == null) {
      final assetRecords = records
          .where((r) => r.assetId == asset.id)
          .toList()
        ..sort((a, b) => b.recordDate.compareTo(a.recordDate));

      if (assetRecords.isNotEmpty) {
        final latest = assetRecords.first;
        quantity ??= latest.quantity ?? 0.0;
        purchasePrice ??= latest.unitPrice ?? 0.0;
        currentPrice ??= latest.unitPrice ?? 0.0;
      }
    }

    quantity ??= 0.0;
    purchasePrice ??= 0.0;
    currentPrice ??= 0.0;

    final currentValue = quantity * currentPrice;
    final costValue = quantity * purchasePrice;

    return (currentValue, costValue);
  }

  static List<TrendPoint> _buildTrendSeries(
    List<Asset> assets,
    List<AssetRecord> records,
  ) {
    final trendPoints = <TrendPoint>[];
    final now = DateTime.now();

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateOnly = DateTime(date.year, date.month, date.day);

      double dayValue = 0.0;

      for (final asset in assets) {
        final assetRecords = records
            .where((r) =>
                r.assetId == asset.id &&
                DateTime.fromMillisecondsSinceEpoch(r.recordDate).isAtSameMomentAs(dateOnly))
            .toList();

        if (assetRecords.isNotEmpty) {
          assetRecords.sort((a, b) => b.recordDate.compareTo(a.recordDate));
          final latest = assetRecords.first;
          final quantity = latest.quantity ?? 0.0;
          final currentPrice = latest.unitPrice ?? 0.0;
          dayValue += quantity * currentPrice;
        }
      }

      trendPoints.add(
        TrendPoint(
          date: dateOnly,
          value: dayValue,
        ),
      );
    }

    return trendPoints;
  }
}
