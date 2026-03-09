import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/dashboard_provider.dart';
import '../providers/asset_type_provider.dart';
import '../providers/asset_provider.dart';
import '../providers/asset_record_provider.dart';
import '../models/dashboard_model.dart';
import '../models/dashboard/portfolio_metrics.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard/chart_card.dart';
import '../widgets/dashboard/add_widget_dialog.dart';
import '../widgets/dashboard/widget_config_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  static const double _cellSize = 12.0;
  static const double _gridPadding = 1.0;
  String? _selectedWidgetId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      final dashboardProvider = context.read<DashboardProvider>();
      final assetTypeProvider = context.read<AssetTypeProvider>();
      final assetProvider = context.read<AssetProvider>();
      final assetRecordProvider = context.read<AssetRecordProvider>();

      await Future.wait([
        dashboardProvider.loadDashboards(),
        assetTypeProvider.loadAssetTypes(),
        assetProvider.loadAssets(),
        assetRecordProvider.loadRecords(),
      ]);

      await dashboardProvider.refreshMetrics(
        assets: assetProvider.assets,
        records: assetRecordProvider.records,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading ? _buildLoadingState() : _buildDashboardContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingS,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E293B).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Text(
                '仪表盘',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  provider.isEditMode ? Icons.visibility : Icons.edit_outlined,
                  color: provider.isEditMode
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF1E293B),
                ),
                onPressed: () {
                  provider.toggleEditMode();
                  setState(() {
                    _selectedWidgetId = null;
                  });
                },
                tooltip: provider.isEditMode ? '查看模式' : '编辑模式',
              ),
              if (provider.isEditMode) ...[
                const SizedBox(width: AppTheme.spacingS),
                ElevatedButton.icon(
                  onPressed: () => _showAddWidgetDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('添加'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingM,
                      vertical: AppTheme.spacingS,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboardContent() {
    return Consumer4<DashboardProvider, AssetProvider, AssetTypeProvider,
        AssetRecordProvider>(
      builder: (context, dashboardProvider, assetProvider, assetTypeProvider,
          recordProvider, child) {
        final dashboard = dashboardProvider.currentDashboard;
        final metrics = dashboardProvider.metrics;

        if (dashboard == null || dashboard.widgets.isEmpty) {
          return _buildEmptyState(dashboardProvider);
        }

        final isEditMode = dashboardProvider.isEditMode;

        return LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final availableHeight = constraints.maxHeight;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: _buildGrid(
                dashboard.widgets,
                metrics,
                dashboardProvider,
                isEditMode,
                availableWidth,
                availableHeight,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGrid(
    List<DashboardWidget> widgets,
    PortfolioMetrics? metrics,
    DashboardProvider provider,
    bool isEditMode,
    double availableWidth,
    double availableHeight,
  ) {
    final maxBottomRow = widgets.fold<int>(
      0,
      (maxRow, item) => math.max(maxRow, item.y + item.h),
    );
    final gridColumns = math.max(1, (availableWidth / _cellSize).floor());
    final canvasWidth = availableWidth;
    final canvasHeight = math.max(
        availableHeight, maxBottomRow * _cellSize + _gridPadding * 2 + 80);

    return GestureDetector(
      onTap: () {
        if (isEditMode) {
          setState(() {
            _selectedWidgetId = null;
          });
        }
      },
      child: Container(
        width: availableWidth,
        height: availableHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E293B).withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: SizedBox(
            width: canvasWidth,
            height: canvasHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (isEditMode) _buildGridLines(canvasWidth, canvasHeight),
                ...widgets.map((widget) {
                  return _buildWidget(
                    widget,
                    widgets,
                    metrics,
                    provider,
                    isEditMode,
                    gridColumns,
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridLines(double width, double height) {
    return CustomPaint(
      size: Size(width, height),
      painter: _GridPainter(_cellSize),
    );
  }

  Widget _buildWidget(
    DashboardWidget widget,
    List<DashboardWidget> allWidgets,
    PortfolioMetrics? metrics,
    DashboardProvider provider,
    bool isEditMode,
    int gridColumns,
  ) {
    final isSelected = _selectedWidgetId == widget.id;
    final left = widget.x * _cellSize + _gridPadding;
    final top = widget.y * _cellSize + _gridPadding;

    return Positioned(
      left: left,
      top: top,
      child: _DraggableResizableWidget(
        widget: widget,
        allWidgets: allWidgets,
        isSelected: isSelected,
        isEditMode: isEditMode,
        cellSize: _cellSize,
        gridPadding: _gridPadding,
        gridColumns: gridColumns,
        onSelect: () {
          if (isEditMode) {
            setState(() {
              _selectedWidgetId = widget.id;
            });
          }
        },
        onBoundsChanged: (newX, newY, newW, newH) {
          provider.updateWidget(
            widget.copyWith(x: newX, y: newY, w: newW, h: newH),
            persist: true,
            resolveOverlap: true,
            maxColumns: gridColumns,
          );
        },
        child: _buildWidgetContent(widget, metrics, provider),
      ),
    );
  }

  Widget _buildWidgetContent(
    DashboardWidget widget,
    PortfolioMetrics? metrics,
    DashboardProvider provider,
  ) {
    switch (widget.type) {
      case WidgetType.stat:
        return _buildStatCard(widget, provider, metrics);
      case WidgetType.chart:
        return _buildChartCard(widget, provider, metrics);
      case WidgetType.table:
        return _buildTableCard(widget, provider);
      case WidgetType.gauge:
        return _buildGaugeCard(widget, provider, metrics);
      case WidgetType.progress:
        return _buildProgressCard(widget, provider, metrics);
      case WidgetType.kpi:
        return _buildKPICard(widget, provider, metrics);
      case WidgetType.timeline:
        return _buildTimelineCard(widget, provider);
      case WidgetType.heatmap:
        return _buildHeatmapCard(widget, provider);
      case WidgetType.calendar:
        return _buildCalendarCard(widget, provider);
      case WidgetType.note:
        return _buildNoteCard(widget, provider);
      default:
        return _buildFallbackWidget(widget, provider);
    }
  }

  Widget _buildChartCard(
    DashboardWidget widget,
    DashboardProvider provider,
    PortfolioMetrics? metrics,
  ) {
    final chartType = widget.config['chartType'] as String? ?? 'pie';
    final List<ChartData> chartData = [];

    if (metrics != null) {
      if (chartType == 'pie') {
        for (final item in metrics.allocationItems) {
          chartData.add(ChartData(item.name, item.value));
        }
      } else {
        for (final point in metrics.trendSeries) {
          chartData.add(
            ChartData(
              '${point.date.month}/${point.date.day}',
              point.value,
            ),
          );
        }
      }
    }

    return ChartCard(
      title: widget.title,
      chartType: chartType,
      data: chartData,
      isEditMode: provider.isEditMode,
      onDelete: () => provider.deleteWidget(widget.id),
      onEdit: () => _showConfigDialog(context, widget),
    );
  }

  Widget _buildFallbackWidget(
      DashboardWidget widget, DashboardProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (provider.isEditMode)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _showConfigDialog(context, widget),
                        child: const Icon(Icons.edit_outlined,
                            size: 18, color: Color(0xFF9CA3AF)),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => provider.deleteWidget(widget.id),
                        child: const Icon(Icons.delete_outline,
                            size: 18, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.widgets_outlined,
                        size: 32, color: Color(0xFF9CA3AF)),
                    const SizedBox(height: 8),
                    Text(
                      '未知组件类型: ${widget.type.name}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    DashboardWidget widget,
    DashboardProvider provider,
    PortfolioMetrics? metrics,
  ) {
    double displayValue = 0;
    if (metrics != null) {
      final metric = widget.config['metric'] as String?;
      if (metric == 'total_value') {
        displayValue = metrics.totalCurrentValue;
      } else if (metric == 'total_profit') {
        displayValue = metrics.totalProfit;
      } else if (metric == 'return_rate') {
        displayValue = metrics.totalReturnRate * 100;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (provider.isEditMode)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _showConfigDialog(context, widget),
                        child: const Icon(Icons.edit_outlined,
                            size: 18, color: Color(0xFF9CA3AF)),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => provider.deleteWidget(widget.id),
                        child: const Icon(Icons.delete_outline,
                            size: 18, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _formatValue(displayValue),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCard(DashboardWidget widget, DashboardProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                if (provider.isEditMode)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _showConfigDialog(context, widget),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.edit_outlined,
                              size: 18, color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => provider.deleteWidget(widget.id),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.delete_outline,
                              size: 18, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacingS),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('资产 ${index + 1}',
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[600])),
                      Text('¥ ${(index + 1) * 10000}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B))),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeCard(
    DashboardWidget widget,
    DashboardProvider provider,
    PortfolioMetrics? metrics,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B)),
                ),
                if (provider.isEditMode)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _showConfigDialog(context, widget),
                        child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.edit_outlined,
                                size: 18, color: Colors.grey[600])),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => provider.deleteWidget(widget.id),
                        child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.delete_outline,
                                size: 18, color: Colors.grey[600])),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: 0.75,
                          strokeWidth: 8,
                          backgroundColor: const Color(0xFFF5F7FA),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF6366F1)),
                        ),
                      ),
                      const Text('75%',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B))),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text('健康度',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
    DashboardWidget widget,
    DashboardProvider provider,
    PortfolioMetrics? metrics,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (provider.isEditMode)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _showConfigDialog(context, widget),
                        child: const Icon(Icons.edit_outlined,
                            size: 18, color: Color(0xFF9CA3AF)),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => provider.deleteWidget(widget.id),
                        child: const Icon(Icons.delete_outline,
                            size: 18, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('目标完成率',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            const SizedBox(height: 8),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 24,
                    width: double.infinity,
                    child: LinearProgressIndicator(
                      value: 0.72,
                      backgroundColor: const Color(0xFFF5F7FA),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF10B981)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const Text('72%',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICard(
    DashboardWidget widget,
    DashboardProvider provider,
    PortfolioMetrics? metrics,
  ) {
    final totalValue = metrics?.totalCurrentValue ?? 0;
    final totalReturnRate = metrics?.totalReturnRate ?? 0;
    final isPositive = totalReturnRate >= 0;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (provider.isEditMode)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _showConfigDialog(context, widget),
                        child: const Icon(Icons.edit_outlined,
                            size: 18, color: Color(0xFF9CA3AF)),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => provider.deleteWidget(widget.id),
                        child: const Icon(Icons.delete_outline,
                            size: 18, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatValue(totalValue),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 16, color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                      const SizedBox(width: 4),
                      Text('${isPositive ? '+' : ''}${(totalReturnRate * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard(
      DashboardWidget widget, DashboardProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (provider.isEditMode)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _showConfigDialog(context, widget),
                        child: const Icon(Icons.edit_outlined,
                            size: 18, color: Color(0xFF9CA3AF)),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => provider.deleteWidget(widget.id),
                        child: const Icon(Icons.delete_outline,
                            size: 18, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimelineItem('添加资产', '完成', const Color(0xFF10B981)),
                  _buildTimelineItem('更新数据', '进行中', const Color(0xFFF59E0B)),
                  _buildTimelineItem('生成报告', '待处理', const Color(0xFF6B7280)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String title, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
            ),
          ),
          Text(
            status,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapCard(DashboardWidget widget, DashboardProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (provider.isEditMode)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _showConfigDialog(context, widget),
                        child: const Icon(Icons.edit_outlined,
                            size: 18, color: Color(0xFF9CA3AF)),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => provider.deleteWidget(widget.id),
                        child: const Icon(Icons.delete_outline,
                            size: 18, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: 28,
                itemBuilder: (context, index) {
                  final intensity = (index % 5) / 5;
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1)
                          .withValues(alpha: 0.1 + intensity * 0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarCard(
      DashboardWidget widget, DashboardProvider provider) {
    final now = DateTime.now();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (provider.isEditMode)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _showConfigDialog(context, widget),
                        child: const Icon(Icons.edit_outlined,
                            size: 18, color: Color(0xFF9CA3AF)),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => provider.deleteWidget(widget.id),
                        child: const Icon(Icons.delete_outline,
                            size: 18, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${now.year}年${now.month}月',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: 35,
                itemBuilder: (context, index) {
                  final day = index - 2;
                  final isToday = day == now.day;
                  return Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isToday
                          ? const Color(0xFF6366F1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        day > 0 && day <= 31 ? day.toString() : '',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              isToday ? Colors.white : const Color(0xFF1E293B),
                          fontWeight:
                              isToday ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(DashboardWidget widget, DashboardProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (provider.isEditMode)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _showConfigDialog(context, widget),
                        child: const Icon(Icons.edit_outlined,
                            size: 18, color: Color(0xFF9CA3AF)),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => provider.deleteWidget(widget.id),
                        child: const Icon(Icons.delete_outline,
                            size: 18, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9C4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '在这里记录你的想法...',
                  style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(DashboardProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.dashboard_customize_outlined,
                size: 64, color: Color(0xFF6366F1)),
          ),
          const SizedBox(height: AppTheme.spacingL),
          const Text('自定义你的仪表盘',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: AppTheme.spacingS),
          Text('添加组件来构建你的个人仪表盘',
              style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          const SizedBox(height: AppTheme.spacingXL),
          ElevatedButton.icon(
            onPressed: () => _showAddWidgetDialog(context, autoEnterEditMode: true),
            icon: const Icon(Icons.add),
            label: const Text('添加第一个组件'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingXL, vertical: AppTheme.spacingM),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1))),
          ),
          const SizedBox(height: AppTheme.spacingM),
          const Text('正在加载数据...',
              style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showAddWidgetDialog(BuildContext context, {bool autoEnterEditMode = false}) {
    final width = MediaQuery.of(context).size.width;
    final availableWidth = math.max(0.0, width - 32.0);
    final gridColumns = math.max(1, (availableWidth / _cellSize).floor());
    showDialog(
      context: context,
      builder: (context) => AddWidgetDialog(
        onAdd: (widget) {
          final provider = context.read<DashboardProvider>();
          provider.addWidget(
                widget,
                maxColumns: gridColumns,
              );
          if (autoEnterEditMode && !provider.isEditMode) {
            provider.toggleEditMode();
          }
        },
      ),
    );
  }

  void _showConfigDialog(BuildContext context, DashboardWidget widget) {
    showDialog(
      context: context,
      builder: (context) => WidgetConfigDialog(
        widget: widget,
        onSave: (updatedWidget) {
          context.read<DashboardProvider>().updateWidget(updatedWidget);
        },
      ),
    );
  }

  String _formatValue(double value) {
    if (value >= 10000) {
      return '¥${(value / 10000).toStringAsFixed(2)}万';
    }
    return '¥${value.toStringAsFixed(2)}';
  }
}

class _DraggableResizableWidget extends StatefulWidget {
  final DashboardWidget widget;
  final List<DashboardWidget> allWidgets;
  final bool isSelected;
  final bool isEditMode;
  final double cellSize;
  final double gridPadding;
  final int gridColumns;
  final VoidCallback onSelect;
  final Function(int, int, int, int) onBoundsChanged;
  final Widget child;

  const _DraggableResizableWidget({
    required this.widget,
    required this.allWidgets,
    required this.isSelected,
    required this.isEditMode,
    required this.cellSize,
    required this.gridPadding,
    required this.gridColumns,
    required this.onSelect,
    required this.onBoundsChanged,
    required this.child,
  });

  @override
  State<_DraggableResizableWidget> createState() =>
      _DraggableResizableWidgetState();
}

class _DraggableResizableWidgetState extends State<_DraggableResizableWidget> {
  bool _isDragging = false;
  bool _isResizing = false;
  String? _activeResizeHandle;
  double _startX = 0;
  double _startY = 0;
  int _initialGridX = 0;
  int _initialGridY = 0;
  int _initialGridW = 0;
  int _initialGridH = 0;
  late int _draftX;
  late int _draftY;
  late int _draftW;
  late int _draftH;

  @override
  void initState() {
    super.initState();
    _syncDraftFromWidget();
  }

  @override
  void didUpdateWidget(covariant _DraggableResizableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging && !_isResizing) {
      _syncDraftFromWidget();
    }
  }

  void _syncDraftFromWidget() {
    _draftX = widget.widget.x;
    _draftY = widget.widget.y;
    _draftW = widget.widget.w;
    _draftH = widget.widget.h;
  }

  @override
  Widget build(BuildContext context) {
    final dx = (_draftX - widget.widget.x) * widget.cellSize;
    final dy = (_draftY - widget.widget.y) * widget.cellSize;
    final displayWidth = _draftW * widget.cellSize - widget.gridPadding * 2;
    final displayHeight = _draftH * widget.cellSize - widget.gridPadding * 2;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Listener(
          onPointerDown: widget.isEditMode && !_isResizing
              ? (details) {
                  final local = details.localPosition;
                  final nearLeft = local.dx <= 20;
                  final nearRight = local.dx >= displayWidth - 20;
                  final nearTop = local.dy <= 20;
                  final nearBottom = local.dy >= displayHeight - 20;
                  final nearResizeHandle =
                      (nearLeft || nearRight) && (nearTop || nearBottom);
                  if (widget.isSelected && nearResizeHandle) {
                    return;
                  }
                  if (widget.isSelected) {
                    setState(() {
                      _isDragging = true;
                      _startX = details.position.dx;
                      _startY = details.position.dy;
                      _initialGridX = _draftX;
                      _initialGridY = _draftY;
                    });
                  } else {
                    widget.onSelect();
                  }
                }
              : null,
          onPointerMove: _isDragging
              ? (details) {
                  final deltaX = details.position.dx - _startX;
                  final deltaY = details.position.dy - _startY;

                  final gridDeltaX = (deltaX / widget.cellSize).round();
                  final gridDeltaY = (deltaY / widget.cellSize).round();

                  final newX = (_initialGridX + gridDeltaX)
                      .clamp(0, widget.gridColumns - _draftW);
                  final newY = (_initialGridY + gridDeltaY).clamp(0, 1000);

                  setState(() {
                    _draftX = newX;
                    _draftY = newY;
                  });
                }
              : null,
          onPointerUp: _isDragging
              ? (details) {
                  _finishDrag();
                }
              : null,
          onPointerCancel: _isDragging
              ? (details) {
                  _finishDrag();
                }
              : null,
          child: Transform(
            transform: Matrix4.identity()
              ..translateByDouble(dx, dy, 0, 1)
              ..scaleByDouble(
                  _isDragging ? 1.02 : 1.0, _isDragging ? 1.02 : 1.0, 1, 1),
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: displayWidth,
              height: displayHeight,
              child: Container(
                decoration: BoxDecoration(
                  border: widget.isSelected && widget.isEditMode
                      ? Border.all(color: const Color(0xFF6366F1), width: 2)
                      : null,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  color: Colors.white,
                  boxShadow: _isDragging
                      ? [
                          BoxShadow(
                            color:
                                const Color(0xFF6366F1).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
        if (widget.isSelected && widget.isEditMode) ..._buildResizeHandles(),
      ],
    );
  }

  List<Widget> _buildResizeHandles() {
    return [
      _buildResizeHandle('top-left', Alignment.topLeft),
      _buildResizeHandle('top-right', Alignment.topRight),
      _buildResizeHandle('bottom-left', Alignment.bottomLeft),
      _buildResizeHandle('bottom-right', Alignment.bottomRight),
    ];
  }

  Widget _buildResizeHandle(String handleName, Alignment alignment) {
    return Positioned(
      left: alignment.x == -1 ? -10 : null,
      right: alignment.x == 1 ? -10 : null,
      top: alignment.y == -1 ? -10 : null,
      bottom: alignment.y == 1 ? -10 : null,
      child: MouseRegion(
        cursor: _getCursorForHandle(handleName),
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (details) {
            setState(() {
              _isResizing = true;
              _activeResizeHandle = handleName;
              _startX = details.position.dx;
              _startY = details.position.dy;
              _initialGridX = _draftX;
              _initialGridY = _draftY;
              _initialGridW = _draftW;
              _initialGridH = _draftH;
            });
          },
          onPointerMove: _isResizing && _activeResizeHandle == handleName
              ? (details) {
                  final deltaX = details.position.dx - _startX;
                  final deltaY = details.position.dy - _startY;

                  final gridDeltaX = (deltaX / widget.cellSize).round();
                  final gridDeltaY = (deltaY / widget.cellSize).round();

                  int newX = _initialGridX;
                  int newY = _initialGridY;
                  int newW = _initialGridW;
                  int newH = _initialGridH;

                  if (handleName == 'top-left') {
                    newX = _initialGridX + gridDeltaX;
                    newY = _initialGridY + gridDeltaY;
                    newW = _initialGridW - gridDeltaX;
                    newH = _initialGridH - gridDeltaY;
                  } else if (handleName == 'top-right') {
                    newY = _initialGridY + gridDeltaY;
                    newW = _initialGridW + gridDeltaX;
                    newH = _initialGridH - gridDeltaY;
                  } else if (handleName == 'bottom-left') {
                    newX = _initialGridX + gridDeltaX;
                    newW = _initialGridW - gridDeltaX;
                    newH = _initialGridH + gridDeltaY;
                  } else if (handleName == 'bottom-right') {
                    newW = _initialGridW + gridDeltaX;
                    newH = _initialGridH + gridDeltaY;
                  }

                  newX = newX.clamp(0, widget.gridColumns - 1);
                  newY = newY.clamp(0, 1000);
                  newW = newW.clamp(2, widget.gridColumns - newX);
                  newH = newH.clamp(2, 1000);

                  setState(() {
                    _draftX = newX;
                    _draftY = newY;
                    _draftW = newW;
                    _draftH = newH;
                  });
                }
              : null,
          onPointerUp: _isResizing && _activeResizeHandle == handleName
              ? (details) {
                  _finishResize();
                }
              : null,
          onPointerCancel: _isResizing && _activeResizeHandle == handleName
              ? (details) {
                  _finishResize();
                }
              : null,
          child: SizedBox(
            width: 24,
            height: 24,
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _finishDrag() {
    final changed = _draftX != widget.widget.x || _draftY != widget.widget.y;
    setState(() {
      _isDragging = false;
    });
    if (changed) {
      widget.onBoundsChanged(_draftX, _draftY, _draftW, _draftH);
    }
  }

  void _finishResize() {
    final positionChanged =
        _draftX != widget.widget.x || _draftY != widget.widget.y;
    final sizeChanged =
        _draftW != widget.widget.w || _draftH != widget.widget.h;

    setState(() {
      _isResizing = false;
      _activeResizeHandle = null;
    });

    if (positionChanged || sizeChanged) {
      widget.onBoundsChanged(_draftX, _draftY, _draftW, _draftH);
    }
  }

  MouseCursor _getCursorForHandle(String handleName) {
    if (handleName == 'top-left' || handleName == 'bottom-right') {
      return SystemMouseCursors.resizeUpLeftDownRight;
    }
    if (handleName == 'top-right' || handleName == 'bottom-left') {
      return SystemMouseCursors.resizeUpRightDownLeft;
    }
    if (handleName.contains('left') || handleName.contains('right')) {
      return SystemMouseCursors.resizeLeftRight;
    }
    return SystemMouseCursors.resizeUpDown;
  }
}

class _GridPainter extends CustomPainter {
  final double cellSize;

  _GridPainter(this.cellSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE5E7EB).withValues(alpha: 0.15)
      ..strokeWidth = 0.5;

    for (double x = 0; x <= size.width; x += cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += cellSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) {
    return oldDelegate.cellSize != cellSize;
  }
}
