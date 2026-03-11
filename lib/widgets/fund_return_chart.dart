import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../models/asset_record.dart';
import '../services/fund_asset_mapper.dart';
import '../services/fund_history_api_service.dart';

enum TimeRange {
  week,
  month,
  threeMonths,
  sixMonths,
  year,
  all,
}

class FundReturnPoint {
  final DateTime date;
  final double nav;
  final double returnAmount;
  final bool isBuyPoint;
  final bool isSellPoint;
  final double? buyAmount;
  final double? sellAmount;

  FundReturnPoint({
    required this.date,
    required this.nav,
    required this.returnAmount,
    this.isBuyPoint = false,
    this.isSellPoint = false,
    this.buyAmount,
    this.sellAmount,
  });
}

class FundNavPoint {
  final DateTime date;
  final double nav;

  FundNavPoint({
    required this.date,
    required this.nav,
  });
}

class FundReturnChart extends StatefulWidget {
  final FundData fundData;
  final List<AssetRecord> records;

  const FundReturnChart({
    super.key,
    required this.fundData,
    required this.records,
  });

  @override
  State<FundReturnChart> createState() => _FundReturnChartState();
}

class _FundReturnChartState extends State<FundReturnChart> {
  TimeRange _selectedRange = TimeRange.all;
  int _selectedChartIndex = 0;
  List<FundNavPoint> _navHistory = [];
  bool _isLoadingNavHistory = false;
  final _historyApiService = FundHistoryApiService();

  @override
  void initState() {
    super.initState();
    _loadNavHistory();
  }

  @override
  void didUpdateWidget(covariant FundReturnChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fundData.fundCode != widget.fundData.fundCode) {
      _selectedChartIndex = 0;
      _loadNavHistory();
    }
  }

  Future<void> _loadNavHistory() async {
    if (widget.fundData.fundCode.isEmpty) return;

    if (mounted) {
      setState(() {
        _isLoadingNavHistory = true;
      });
    }

    try {
      final now = DateTime.now();
      DateTime startDate;

      switch (_selectedRange) {
        case TimeRange.week:
          startDate = now.subtract(const Duration(days: 7));
          break;
        case TimeRange.month:
          startDate = now.subtract(const Duration(days: 30));
          break;
        case TimeRange.threeMonths:
          startDate = now.subtract(const Duration(days: 90));
          break;
        case TimeRange.sixMonths:
          startDate = now.subtract(const Duration(days: 180));
          break;
        case TimeRange.year:
          startDate = now.subtract(const Duration(days: 365));
          break;
        case TimeRange.all:
          startDate = now.subtract(const Duration(days: 365 * 3));
          break;
      }

      final history = await _historyApiService.fetchNavHistory(
        widget.fundData.fundCode,
        startDate: startDate,
        endDate: now,
      );

      if (!mounted) return;
      setState(() {
        _navHistory = history
            .map((h) => FundNavPoint(
                  date: h.date,
                  nav: h.nav,
                ))
            .toList();
        _isLoadingNavHistory = false;
      });
    } catch (e) {
      print('加载历史净值失败: $e');
      if (mounted) {
        setState(() {
          _isLoadingNavHistory = false;
        });
      }
    }
  }

  List<FundReturnPoint> _calculateChartData() {
    if (widget.records.isEmpty) return [];

    final validRecords = widget.records.where((r) => !r.isRevoked).toList();
    if (validRecords.isEmpty) return [];

    validRecords.sort((a, b) => a.recordDate.compareTo(b.recordDate));

    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedRange) {
      case TimeRange.week:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case TimeRange.month:
        startDate = now.subtract(const Duration(days: 30));
        break;
      case TimeRange.threeMonths:
        startDate = now.subtract(const Duration(days: 90));
        break;
      case TimeRange.sixMonths:
        startDate = now.subtract(const Duration(days: 180));
        break;
      case TimeRange.year:
        startDate = now.subtract(const Duration(days: 365));
        break;
      case TimeRange.all:
        startDate = DateTime(2000);
        break;
    }

    final filteredRecords = validRecords.where((r) {
      final date = DateTime.fromMillisecondsSinceEpoch(r.recordDate);
      return date.isAfter(startDate) || date.isAtSameMomentAs(startDate);
    }).toList();

    final points = <FundReturnPoint>[];
    double cumulativeCost = 0.0;
    double cumulativeQuantity = 0.0;

    for (final record in filteredRecords) {
      final date = DateTime.fromMillisecondsSinceEpoch(record.recordDate);
      final quantity = record.quantity?.abs() ?? 0;
      final amount = record.value.abs();
      final unitPrice = record.unitPrice ?? widget.fundData.purchasePrice;

      final isBuy = record.note == '买入';
      final isSell = record.note == '卖出';

      if (isBuy) {
        cumulativeCost += amount;
        cumulativeQuantity += quantity;
      } else if (isSell) {
        cumulativeCost -=
            amount * (cumulativeCost / (cumulativeQuantity * unitPrice));
        cumulativeQuantity -= quantity;
      }

      if (cumulativeQuantity > 0 || isBuy || isSell) {
        final currentValue = cumulativeQuantity * unitPrice;
        final returnAmount = currentValue - cumulativeCost;

        points.add(FundReturnPoint(
          date: date,
          nav: unitPrice,
          returnAmount: returnAmount,
          isBuyPoint: isBuy,
          isSellPoint: isSell,
          buyAmount: isBuy ? amount : null,
          sellAmount: isSell ? amount : null,
        ));
      }
    }

    if (points.isEmpty && cumulativeQuantity > 0) {
      points.add(FundReturnPoint(
        date: DateTime.now(),
        nav: widget.fundData.currentPrice,
        returnAmount: widget.fundData.returnAmount,
      ));
    }

    return points;
  }

  @override
  Widget build(BuildContext context) {
    final chartData = _calculateChartData();

    if (_selectedChartIndex == 1 && chartData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.show_chart_rounded,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                '暂无收益数据',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildTimeRangeSelector(),
        const SizedBox(height: 12),
        _buildChartSelector(),
        const SizedBox(height: 12),
        _selectedChartIndex == 0
            ? _buildNavChart()
            : _buildReturnChart(chartData),
      ],
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: TimeRange.values.map((range) {
            final isSelected = _selectedRange == range;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(_getRangeLabel(range)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected && _selectedRange != range) {
                    setState(() {
                      _selectedRange = range;
                    });
                    _loadNavHistory();
                  }
                },
                selectedColor: const Color(0xFFFF9800).withValues(alpha: 0.2),
                checkmarkColor: const Color(0xFFFF9800),
                labelStyle: TextStyle(
                  color: isSelected
                      ? const Color(0xFFFF9800)
                      : const Color(0xFF64748B),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
                backgroundColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFFFF9800)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildChartSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedChartIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedChartIndex == 0
                      ? const Color(0xFFFF9800)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '基金净值走势',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedChartIndex == 0
                        ? Colors.white
                        : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedChartIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedChartIndex == 1
                      ? const Color(0xFF10B981)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '个人收益走势',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedChartIndex == 1
                        ? Colors.white
                        : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRangeLabel(TimeRange range) {
    switch (range) {
      case TimeRange.week:
        return '1周';
      case TimeRange.month:
        return '1月';
      case TimeRange.threeMonths:
        return '3月';
      case TimeRange.sixMonths:
        return '6月';
      case TimeRange.year:
        return '1年';
      case TimeRange.all:
        return '全部';
    }
  }

  Widget _buildNavChart() {
    if (_isLoadingNavHistory) {
      return Container(
        height: 320,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
          ),
        ),
      );
    }

    if (_navHistory.isEmpty) {
      return Container(
        height: 320,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart_rounded,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                '暂无历史净值数据',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 320,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SfCartesianChart(
        primaryXAxis: DateTimeAxis(
          dateFormat: DateFormat('MM/dd'),
          intervalType: DateTimeIntervalType.auto,
          majorGridLines: const MajorGridLines(width: 0),
          axisLine: const AxisLine(width: 0),
        ),
        primaryYAxis: NumericAxis(
          numberFormat: NumberFormat.currency(
            locale: 'zh_CN',
            symbol: '¥',
            decimalDigits: 4,
          ),
          labelFormat: '¥{value}',
          majorGridLines: MajorGridLines(
            width: 0.5,
            color: Colors.grey[300] ?? Colors.grey,
            dashArray: const <double>[5, 5],
          ),
          axisLine: const AxisLine(width: 0),
        ),
        tooltipBehavior: TooltipBehavior(
          enable: true,
          builder: (dynamic data, dynamic point, dynamic series, int pointIndex,
              int seriesIndex) {
            final pointData = _navHistory[pointIndex];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('yyyy-MM-dd').format(pointData.date),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF9800),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '净值: ¥${pointData.nav.toStringAsFixed(4)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        title: ChartTitle(
          text: '基金净值走势',
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        series: <CartesianSeries>[
          LineSeries<FundNavPoint, DateTime>(
            dataSource: _navHistory,
            xValueMapper: (data, _) => data.date,
            yValueMapper: (data, _) => data.nav,
            color: const Color(0xFFFF9800),
            width: 2.5,
            animationDuration: 1500,
          ),
        ],
        zoomPanBehavior: ZoomPanBehavior(
          enablePanning: true,
          enablePinching: true,
          zoomMode: ZoomMode.x,
        ),
      ),
    );
  }

  Widget _buildReturnChart(List<FundReturnPoint> chartData) {
    final minValue =
        chartData.map((p) => p.returnAmount).reduce((a, b) => a < b ? a : b);
    final maxValue =
        chartData.map((p) => p.returnAmount).reduce((a, b) => a > b ? a : b);
    final hasPositive = maxValue > 0;
    final hasNegative = minValue < 0;

    final buyPoints = chartData.where((p) => p.isBuyPoint).toList();
    final sellPoints = chartData.where((p) => p.isSellPoint).toList();

    return Container(
      height: 320,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SfCartesianChart(
        primaryXAxis: DateTimeAxis(
          dateFormat: DateFormat('MM/dd'),
          intervalType: DateTimeIntervalType.auto,
          majorGridLines: const MajorGridLines(width: 0),
          axisLine: const AxisLine(width: 0),
        ),
        primaryYAxis: NumericAxis(
          numberFormat: NumberFormat.compactCurrency(
            locale: 'zh_CN',
            symbol: '¥',
            decimalDigits: 0,
          ),
          labelFormat: '¥{value}',
          majorGridLines: MajorGridLines(
            width: 0.5,
            color: Colors.grey[300] ?? Colors.grey,
            dashArray: const <double>[5, 5],
          ),
          axisLine: const AxisLine(width: 0),
          plotBands: hasPositive && hasNegative
              ? <PlotBand>[
                  PlotBand(
                    isVisible: true,
                    start: 0,
                    end: 0,
                    borderColor: Colors.grey[400] ?? Colors.grey,
                    borderWidth: 1,
                    dashArray: const <double>[5, 5],
                  ),
                ]
              : <PlotBand>[],
        ),
        tooltipBehavior: TooltipBehavior(
          enable: true,
          builder: (dynamic data, dynamic point, dynamic series, int pointIndex,
              int seriesIndex) {
            final pointData = chartData[pointIndex];
            return _buildTooltip(
              date: pointData.date,
              returnAmount: pointData.returnAmount,
              isBuyPoint: pointData.isBuyPoint,
              isSellPoint: pointData.isSellPoint,
              buyAmount: pointData.buyAmount,
              sellAmount: pointData.sellAmount,
            );
          },
        ),
        title: ChartTitle(
          text: '个人收益走势',
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        legend: Legend(
          isVisible: buyPoints.isNotEmpty || sellPoints.isNotEmpty,
          position: LegendPosition.top,
          alignment: ChartAlignment.center,
          overflowMode: LegendItemOverflowMode.wrap,
          legendItemBuilder:
              (String name, dynamic series, dynamic point, int index) {
            Color color;
            IconData icon;
            if (name == '买入') {
              color = const Color(0xFF10B981);
              icon = Icons.arrow_upward;
            } else {
              color = const Color(0xFFEF4444);
              icon = Icons.arrow_downward;
            }
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 4),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        series: <CartesianSeries>[
          LineSeries<FundReturnPoint, DateTime>(
            name: '累计收益',
            dataSource: chartData,
            xValueMapper: (data, _) => data.date,
            yValueMapper: (data, _) => data.returnAmount,
            color: const Color(0xFF10B981),
            width: 2.5,
            markerSettings: const MarkerSettings(
              isVisible: true,
              height: 5,
              width: 5,
              shape: DataMarkerType.circle,
              color: Color(0xFF10B981),
            ),
            animationDuration: 1500,
          ),
          if (buyPoints.isNotEmpty)
            ScatterSeries<FundReturnPoint, DateTime>(
              name: '买入',
              dataSource: buyPoints,
              xValueMapper: (data, _) => data.date,
              yValueMapper: (data, _) => data.returnAmount,
              markerSettings: MarkerSettings(
                isVisible: true,
                height: 12,
                width: 12,
                shape: DataMarkerType.triangle,
                color: const Color(0xFF10B981),
              ),
              animationDuration: 1500,
            ),
          if (sellPoints.isNotEmpty)
            ScatterSeries<FundReturnPoint, DateTime>(
              name: '卖出',
              dataSource: sellPoints,
              xValueMapper: (data, _) => data.date,
              yValueMapper: (data, _) => data.returnAmount,
              markerSettings: MarkerSettings(
                isVisible: true,
                height: 12,
                width: 12,
                shape: DataMarkerType.invertedTriangle,
                color: const Color(0xFFEF4444),
              ),
              animationDuration: 1500,
            ),
        ],
        zoomPanBehavior: ZoomPanBehavior(
          enablePanning: true,
          enablePinching: true,
          zoomMode: ZoomMode.x,
        ),
      ),
    );
  }

  Widget _buildTooltip({
    required DateTime date,
    double? nav,
    double? returnAmount,
    bool isBuyPoint = false,
    bool isSellPoint = false,
    double? buyAmount,
    double? sellAmount,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('yyyy-MM-dd').format(date),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          if (nav != null) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF9800),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '净值: ¥${nav.toStringAsFixed(4)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
          if (returnAmount != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: returnAmount >= 0
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '收益: ${returnAmount >= 0 ? '+' : ''}¥${returnAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: returnAmount >= 0
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          if (isBuyPoint && buyAmount != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_upward,
                    size: 12, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Text(
                  '买入: ¥${buyAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          if (isSellPoint && sellAmount != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_downward,
                    size: 12, color: Color(0xFFEF4444)),
                const SizedBox(width: 8),
                Text(
                  '卖出: ¥${sellAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
