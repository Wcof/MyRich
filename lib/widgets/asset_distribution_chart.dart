import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/asset.dart';
import '../models/asset_type.dart';

class AssetDistributionData {
  final String typeName;
  final double value;
  final Color color;

  AssetDistributionData({
    required this.typeName,
    required this.value,
    required this.color,
  });
}

class AssetDistributionChart extends StatelessWidget {
  final List<Asset> assets;
  final List<AssetType> assetTypes;

  const AssetDistributionChart({
    super.key,
    required this.assets,
    required this.assetTypes,
  });

  Color _parseColor(String colorString) {
    try {
      String color = colorString;
      if (color.startsWith('#')) {
        color = color.substring(1);
        if (color.length == 6) {
          color = 'FF$color';
        }
      }
      return Color(int.parse(color, radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }

  List<AssetDistributionData> _getChartData() {
    final Map<int, double> typeValues = {};
    
    for (final asset in assets) {
      final value = _getAssetValue(asset);
      typeValues[asset.typeId] = (typeValues[asset.typeId] ?? 0) + value;
    }

    final List<AssetDistributionData> data = [];
    final defaultColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
    ];

    int colorIndex = 0;
    for (final entry in typeValues.entries) {
      final assetType = assetTypes.firstWhere(
        (type) => type.id == entry.key,
        orElse: () => AssetType(
          id: entry.key,
          name: '未知类型',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      Color color = defaultColors[colorIndex % defaultColors.length];
      if (assetType.color != null) {
        color = _parseColor(assetType.color!);
      }

      data.add(AssetDistributionData(
        typeName: assetType.name,
        value: entry.value,
        color: color,
      ));
      colorIndex++;
    }

    return data;
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
              '暂无资产数据',
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
              '资产分布',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: SfCircularChart(
                legend: const Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                  overflowMode: LegendItemOverflowMode.wrap,
                ),
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  format: 'point.x: ¥point.y',
                ),
                series: <CircularSeries>[
                  PieSeries<AssetDistributionData, String>(
                    dataSource: chartData,
                    xValueMapper: (data, _) => data.typeName,
                    yValueMapper: (data, _) => data.value,
                    pointColorMapper: (data, _) => data.color,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                      labelIntersectAction: LabelIntersectAction.shift,
                      textStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    enableTooltip: true,
                    explode: true,
                    explodeIndex: 0,
                    explodeOffset: '10%',
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
