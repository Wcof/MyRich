import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/asset.dart';
import '../models/stock_data.dart';
import '../services/akshare_api_service.dart';
import '../theme/app_theme.dart';

class StockAssetDetailScreen extends StatefulWidget {
  final Asset asset;
  final VoidCallback? onBack;

  const StockAssetDetailScreen({
    super.key,
    required this.asset,
    this.onBack,
  });

  @override
  State<StockAssetDetailScreen> createState() => _StockAssetDetailScreenState();
}

class _StockAssetDetailScreenState extends State<StockAssetDetailScreen> {
  final AkshareApiService _akshareApi = AkshareApiService();
  StockData? _stockData;
  List<StockKLine> _klineData = [];
  KLinePeriod _selectedPeriod = KLinePeriod.minute1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStockData();
  }

  Future<void> _loadStockData() async {
    setState(() => _isLoading = true);

    try {
      final stockCode = _extractStockCode();
      if (stockCode != null) {
        final data = await _akshareApi.getStockRealtime(stockCode);
        final kline = await _akshareApi.getStockKLine(
          stockCode,
          period: _selectedPeriod,
          limit: 100,
        );

        if (mounted) {
          setState(() {
            _stockData = data;
            _klineData = kline;
          });
        }
      }
    } catch (e) {
      print('加载股票数据失败: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _extractStockCode() {
    return widget.asset.customData;
  }

  List<StockPricePoint> _buildPriceSeries() {
    final points = _klineData
        .map((k) => StockPricePoint(time: k.time, close: k.close))
        .toList();
    points.sort((a, b) => a.time.compareTo(b.time));
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'zh_CN',
      symbol: '¥',
      decimalDigits: 2,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildHeader(formatter),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Column(
                children: [
                  _buildStockInfoCard(formatter),
                  const SizedBox(height: AppTheme.spacingM),
                  _buildKLineCard(),
                  const SizedBox(height: AppTheme.spacingM),
                  _buildQuickActions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(NumberFormat formatter) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: widget.onBack != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: widget.onBack,
            )
          : null,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2196F3),
                Color(0xFF1976D2),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: widget.onBack != null ? 72 : AppTheme.spacingM,
                right: AppTheme.spacingM,
                bottom: AppTheme.spacingM,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _stockData?.stockName ?? widget.asset.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _stockData?.stockCode ?? '--',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    _stockData != null
                        ? formatter.format(_stockData!.currentPrice)
                        : '--',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_stockData != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _stockData!.changeRate >= 0
                                ? Colors.white.withValues(alpha: 0.25)
                                : Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_stockData!.changeRate >= 0 ? '+' : ''}${(_stockData!.changeRate * 100).toStringAsFixed(2)}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStockInfoCard(NumberFormat formatter) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '股票信息',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          if (_stockData != null) ...[
            _buildInfoRow('今开', formatter.format(_stockData!.openPrice)),
            const Divider(height: 24),
            _buildInfoRow('昨收', formatter.format(_stockData!.closePrice)),
            const Divider(height: 24),
            _buildInfoRow('最高', formatter.format(_stockData!.highPrice)),
            const Divider(height: 24),
            _buildInfoRow('最低', formatter.format(_stockData!.lowPrice)),
            const Divider(height: 24),
            _buildInfoRow(
                '成交量', '${(_stockData!.volume / 10000).toStringAsFixed(2)}万手'),
          ] else
            const Center(child: Text('暂无股票数据')),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildKLineCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'K线图',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: KLinePeriod.values.map((period) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(period.label),
                    selected: _selectedPeriod == period,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedPeriod = period);
                        _loadStockData();
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_klineData.isNotEmpty)
            _buildPriceChart()
          else
            Center(
              child: Text(
                '暂无K线数据',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '快速操作',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _loadStockData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('刷新'),
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit),
                  label: const Text('编辑'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceChart() {
    final data = _buildPriceSeries();
    if (data.isEmpty) {
      return Center(
        child: Text(
          '暂无K线数据',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return SizedBox(
      height: 300,
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
            decimalDigits: 2,
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
          format: 'point.x: ¥point.y',
        ),
        title: ChartTitle(
          text: '股票走势',
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        series: <CartesianSeries>[
          LineSeries<StockPricePoint, DateTime>(
            dataSource: data,
            xValueMapper: (p, _) => p.time,
            yValueMapper: (p, _) => p.close,
            color: const Color(0xFF2563EB),
            width: 2.5,
            animationDuration: 1200,
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
}

class StockPricePoint {
  final DateTime time;
  final double close;

  StockPricePoint({
    required this.time,
    required this.close,
  });
}
