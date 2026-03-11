import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../models/real_estate_price.dart';

class RealEstatePriceTrendChart extends StatelessWidget {
  final List<RealEstatePrice> prices;

  const RealEstatePriceTrendChart({
    super.key,
    required this.prices,
  });

  List<ChartData> _getChartData() {
    if (prices.isEmpty) return [];

    final sortedPrices = List<RealEstatePrice>.from(prices)
      ..sort((a, b) => a.recordDate.compareTo(b.recordDate));

    return sortedPrices.map((price) => ChartData(
      date: DateTime.fromMillisecondsSinceEpoch(price.recordDate),
      price: price.price,
      source: price.source,
    )).toList();
  }

  @override
  Widget build(BuildContext context) {
    final chartData = _getChartData();

    if (chartData.isEmpty) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart,
                size: 48,
                color: Colors.grey,
              ),
              SizedBox(height: 8),
              Text(
                '暂无价格趋势数据',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: const Text(
              '价格走势',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          SizedBox(
            height: 250,
            child: SfCartesianChart(
              primaryXAxis: DateTimeAxis(
                dateFormat: DateFormat('yyyy-MM'),
                intervalType: DateTimeIntervalType.months,
                majorGridLines: const MajorGridLines(width: 0),
                labelStyle: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
              primaryYAxis: NumericAxis(
                numberFormat: NumberFormat.compactCurrency(
                  locale: 'zh_CN',
                  symbol: '¥',
                ),
                labelFormat: '¥{value}',
                majorGridLines: const MajorGridLines(
                  width: 1,
                  color: Color(0xFFE5E7EB),
                  dashArray: <double>[5, 5],
                ),
                labelStyle: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                format: 'point.x: ¥point.y',
                color: const Color(0xFF1E293B),
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              series: <CartesianSeries>[
                LineSeries<ChartData, DateTime>(
                  name: '房产价格',
                  dataSource: chartData,
                  xValueMapper: (data, _) => data.date,
                  yValueMapper: (data, _) => data.price,
                  markerSettings: const MarkerSettings(
                    isVisible: true,
                    height: 6,
                    width: 6,
                    shape: DataMarkerType.circle,
                    color: Color(0xFFFF9800),
                    borderColor: Colors.white,
                    borderWidth: 2,
                  ),
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: false,
                  ),
                  enableTooltip: true,
                  color: const Color(0xFFFF9800),
                  width: 3,
                  animationDuration: 1000,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChartData {
  final DateTime date;
  final double price;
  final String source;

  ChartData({
    required this.date,
    required this.price,
    required this.source,
  });
}