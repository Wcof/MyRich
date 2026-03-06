import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../models/asset.dart';
import '../models/asset_record.dart';

class AssetTrendData {
  final DateTime date;
  final double value;

  AssetTrendData({
    required this.date,
    required this.value,
  });
}

class AssetTrendChart extends StatelessWidget {
  final List<Asset> assets;
  final List<AssetRecord> records;

  const AssetTrendChart({
    super.key,
    required this.assets,
    required this.records,
  });

  List<AssetTrendData> _getChartData() {
    final Map<DateTime, double> dailyValues = {};
    final now = DateTime.now();
    
    for (int i = 29; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      dailyValues[date] = 0.0;
    }

    for (final asset in assets) {
      final value = _getAssetValue(asset);
      final assetRecords = records.where((r) => r.assetId == asset.id).toList();
      
      if (assetRecords.isEmpty) {
        final createdAt = DateTime.fromMillisecondsSinceEpoch(asset.createdAt);
        final dateKey = DateTime(createdAt.year, createdAt.month, createdAt.day);
        if (dailyValues.containsKey(dateKey)) {
          dailyValues[dateKey] = dailyValues[dateKey]! + value;
        }
      } else {
        for (final record in assetRecords) {
          final recordDate = DateTime.fromMillisecondsSinceEpoch(record.createdAt);
          final dateKey = DateTime(recordDate.year, recordDate.month, recordDate.day);
          if (dailyValues.containsKey(dateKey)) {
            dailyValues[dateKey] = dailyValues[dateKey]! + _getRecordValue(record);
          }
        }
      }
    }

    final sortedData = dailyValues.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return sortedData.map((entry) => AssetTrendData(
      date: entry.key,
      value: entry.value,
    )).toList();
  }

  double _getAssetValue(Asset asset) {
    if (asset.customData != null) {
      try {
        final data = Map<String, dynamic>.from(
          // ignore: avoid_dynamic_calls
          asset.customData as Map,
        );
        return (data['value'] as num?)?.toDouble() ?? 0.0;
      } catch (_) {
        return 0.0;
      }
    }
    return 0.0;
  }

  double _getRecordValue(AssetRecord record) {
    return record.value;
  }

  @override
  Widget build(BuildContext context) {
    final chartData = _getChartData();

    if (chartData.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          height: 300,
          padding: const EdgeInsets.all(20),
          child: const Center(
            child: Text(
              '暂无趋势数据',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '资产趋势 (近30天)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: SfCartesianChart(
                primaryXAxis: DateTimeAxis(
                  dateFormat: DateFormat.Md(),
                  intervalType: DateTimeIntervalType.days,
                  interval: 5,
                ),
                primaryYAxis: NumericAxis(
                  numberFormat: NumberFormat.compactCurrency(
                    locale: 'zh_CN',
                    symbol: '¥',
                  ),
                  labelFormat: '¥{value}',
                ),
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  format: 'point.x: ¥point.y',
                ),
                legend: const Legend(
                  isVisible: true,
                  position: LegendPosition.top,
                ),
                series: <CartesianSeries>[
                  LineSeries<AssetTrendData, DateTime>(
                    name: '总资产',
                    dataSource: chartData,
                    xValueMapper: (data, _) => data.date,
                    yValueMapper: (data, _) => data.value,
                    markerSettings: const MarkerSettings(
                      isVisible: true,
                      height: 4,
                      width: 4,
                      shape: DataMarkerType.circle,
                    ),
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: false,
                    ),
                    enableTooltip: true,
                    color: Colors.blue,
                    width: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
