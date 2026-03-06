import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/asset_type_provider.dart';
import '../providers/asset_provider.dart';
import '../providers/asset_record_provider.dart';
import '../models/dashboard_model.dart';
import '../models/asset.dart';
import '../theme/app_theme.dart';
import '../utils/grid_layout_manager.dart';
import '../widgets/dashboard/stat_card.dart';
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
  static const int _gridColumns = 48;
  static const double _cellSize = 10.0;
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

  double _calculateTotalAssets(List<Asset> assets) {
    double total = 0.0;
    for (final asset in assets) {
      if (asset.customData != null) {
        try {
          final data = Map<String, dynamic>.from(asset.customData as Map);
          total += (data['value'] as num?)?.toDouble() ?? 0.0;
        } catch (_) {
          continue;
        }
      }
    }
    return total;
  }

  Map<String, double> _getAssetDistribution(List<Asset> assets, List<dynamic> assetTypes) {
    final Map<String, double> distribution = {};
    for (final asset in assets) {
      if (asset.customData != null) {
        try {
          final data = Map<String, dynamic>.from(asset.customData as Map);
          final value = (data['value'] as num?)?.toDouble() ?? 0.0;
          final typeId = asset.typeId;
          final typeName = assetTypes.firstWhere(
            (t) => t.id == typeId,
            orElse: () => assetTypes.first,
          ).name;
          distribution[typeName] = (distribution[typeName] ?? 0) + value;
        } catch (_) {
          continue;
        }
      }
    }
    return distribution;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _buildDashboardContent(),
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
              const Spacer(),
              IconButton(
                icon: Icon(
                  provider.isEditMode ? Icons.visibility : Icons.edit_outlined,
                  color: provider.isEditMode ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
                ),
                onPressed: () {
                  provider.toggleEditMode();
                  setState(() {
                    _selectedWidgetId = null;
                  });
                },
                tooltip: provider.isEditMode ? '查看模式' : '编辑模式',
              ),
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
          ),
        );
      },
    );
  }

  Widget _buildDashboardContent() {
    return Consumer4<DashboardProvider, AssetProvider, AssetTypeProvider, AssetRecordProvider>(
      builder: (context, dashboardProvider, assetProvider, assetTypeProvider, recordProvider, child) {
        final dashboard = dashboardProvider.currentDashboard;
        final assets = assetProvider.assets;
        final assetTypes = assetTypeProvider.assetTypes;
        
        if (dashboard == null || dashboard.widgets.isEmpty) {
          return _buildEmptyState(dashboardProvider);
        }

        final totalValue = _calculateTotalAssets(assets);
        final distribution = _getAssetDistribution(assets, assetTypes);
        final isEditMode = dashboardProvider.isEditMode;

        return LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final availableHeight = constraints.maxHeight;
            
            return Padding(
              padding: const EdgeInsets.all(16),
              child: _buildGrid(
                dashboard.widgets,
                totalValue,
                distribution,
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
    double totalValue,
    Map<String, double> distribution,
    DashboardProvider provider,
    bool isEditMode,
    double availableWidth,
    double availableHeight,
  ) {
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
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isEditMode) _buildGridLines(availableWidth, availableHeight),
            ...widgets.map((widget) {
              return _buildWidget(
                widget,
                widgets,
                totalValue,
                distribution,
                provider,
                isEditMode,
              );
            }).toList(),
          ],
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
    double totalValue,
    Map<String, double> distribution,
    DashboardProvider provider,
    bool isEditMode,
  ) {
    final isSelected = _selectedWidgetId == widget.id;
    final left = widget.x * _cellSize + _gridPadding;
    final top = widget.y * _cellSize + _gridPadding;
    final width = widget.w * _cellSize - _gridPadding * 2;
    final height = widget.h * _cellSize - _gridPadding * 2;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: _DraggableResizableWidget(
        widget: widget,
        allWidgets: allWidgets,
        isSelected: isSelected,
        isEditMode: isEditMode,
        cellSize: _cellSize,
        gridColumns: _gridColumns,
        onSelect: () {
          if (isEditMode) {
            setState(() {
              _selectedWidgetId = widget.id;
            });
          }
        },
        onPositionChanged: (newX, newY) {
          final updatedWidget = widget.copyWith(x: newX, y: newY);
          provider.updateWidget(updatedWidget);
        },
        onSizeChanged: (newW, newH) {
          final updatedWidget = widget.copyWith(w: newW, h: newH);
          provider.updateWidget(updatedWidget);
        },
        child: _buildWidgetContent(widget, totalValue, distribution, provider),
      ),
    );
  }

  Widget _buildWidgetContent(
    DashboardWidget widget, 
    double totalValue,
    Map<String, double> distribution,
    DashboardProvider provider,
  ) {
    switch (widget.type) {
      case WidgetType.stat:
        return _buildStatCard(widget, provider, totalValue);
      case WidgetType.chart:
        final chartType = widget.config['chartType'] as String? ?? 'pie';
        final List<ChartData> chartData = [];
        
        if (chartType == 'pie') {
          distribution.forEach((key, value) {
            chartData.add(ChartData(key, value));
          });
        } else {
          chartData.add(ChartData('1月', totalValue * 0.9));
          chartData.add(ChartData('2月', totalValue * 0.95));
          chartData.add(ChartData('3月', totalValue * 1.1));
          chartData.add(ChartData('4月', totalValue));
        }
        
        return ChartCard(
          title: widget.title,
          chartType: chartType,
          data: chartData,
          isEditMode: provider.isEditMode,
          onDelete: () => provider.deleteWidget(widget.id),
          onEdit: () => _showConfigDialog(context, widget),
        );
      case WidgetType.table:
        return _buildTableCard(widget, provider);
      case WidgetType.gauge:
        return _buildGaugeCard(widget, provider);
      case WidgetType.progress:
        return _buildProgressCard(widget, provider, totalValue);
      case WidgetType.kpi:
        return _buildKPICard(widget, provider, totalValue);
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

  Widget _buildFallbackWidget(DashboardWidget widget, DashboardProvider provider) {
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
                        child: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF9CA3AF)),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => provider.deleteWidget(widget.id),
                        child: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF9CA3AF)),
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
                    const Icon(Icons.widgets_outlined, size: 32, color: Color(0xFF9CA3AF)),
                    const SizedBox(height: 8),
                    Text(
                      '未知组件类型: ${widget.type.name}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
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

  Widget _buildStatCard(DashboardWidget widget, DashboardProvider provider, double totalValue) {
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
                        child: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF9CA3AF)),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => provider.deleteWidget(widget.id),
                        child: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF9CA3AF)),
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
                  _formatValue(totalValue),
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
                          child: Icon(Icons.edit_outlined, size: 18, color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => provider.deleteWidget(widget.id),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.delete_outline, size: 18, color: Colors.grey[600]),
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
                      Text('资产 ${index + 1}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      Text('¥ ${(index + 1) * 10000}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
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

  Widget _buildGaugeCard(DashboardWidget widget, DashboardProvider provider) {
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                if (provider.isEditMode)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _showConfigDialog(context, widget),
                        child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.edit_outlined, size: 18, color: Colors.grey[600])),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => provider.deleteWidget(widget.id),
                        child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.delete_outline, size: 18, color: Colors.grey[600])),
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
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                        ),
                      ),
                      const Text('75%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text('健康度', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(DashboardWidget widget, DashboardProvider provider, double totalValue) {
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
                        child: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF9CA3AF)),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => provider.deleteWidget(widget.id),
                        child: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('目标完成率', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
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
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const Text('72%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICard(DashboardWidget widget, DashboardProvider provider, double totalValue) {
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
                        child: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF9CA3AF)),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => provider.deleteWidget(widget.id),
                        child: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF9CA3AF)),
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
                    _formatValue(totalValue * 1.2),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.arrow_upward, size: 16, color: const Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      const Text('+12.5%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF10B981))),
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

  Widget _buildTimelineCard(DashboardWidget widget, DashboardProvider provider) {
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
                        child: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF9CA3AF)),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => provider.deleteWidget(widget.id),
                        child: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF9CA3AF)),
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
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
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
                        child: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF9CA3AF)),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => provider.deleteWidget(widget.id),
                        child: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF9CA3AF)),
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
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1 + intensity * 0.7),
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

  Widget _buildCalendarCard(DashboardWidget widget, DashboardProvider provider) {
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
                        child: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF9CA3AF)),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => provider.deleteWidget(widget.id),
                        child: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF9CA3AF)),
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
                      color: isToday ? const Color(0xFF6366F1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        day > 0 && day <= 31 ? day.toString() : '',
                        style: TextStyle(
                          fontSize: 14,
                          color: isToday ? Colors.white : const Color(0xFF1E293B),
                          fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
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
                        child: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF9CA3AF)),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => provider.deleteWidget(widget.id),
                        child: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF9CA3AF)),
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
            child: const Icon(Icons.dashboard_customize_outlined, size: 64, color: Color(0xFF6366F1)),
          ),
          const SizedBox(height: AppTheme.spacingL),
          const Text('自定义你的仪表盘', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
          const SizedBox(height: AppTheme.spacingS),
          Text('添加组件来构建你的个人仪表盘', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          const SizedBox(height: AppTheme.spacingXL),
          ElevatedButton.icon(
            onPressed: () => _showAddWidgetDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('添加第一个组件'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXL, vertical: AppTheme.spacingM),
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
            child: const CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1))),
          ),
          const SizedBox(height: AppTheme.spacingM),
          const Text('正在加载数据...', style: TextStyle(fontSize: 16, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showAddWidgetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddWidgetDialog(
        onAdd: (widget) {
          context.read<DashboardProvider>().addWidget(widget);
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
  final int gridColumns;
  final VoidCallback onSelect;
  final Function(int, int) onPositionChanged;
  final Function(int, int) onSizeChanged;
  final Widget child;

  const _DraggableResizableWidget({
    required this.widget,
    required this.allWidgets,
    required this.isSelected,
    required this.isEditMode,
    required this.cellSize,
    required this.gridColumns,
    required this.onSelect,
    required this.onPositionChanged,
    required this.onSizeChanged,
    required this.child,
  });

  @override
  State<_DraggableResizableWidget> createState() => _DraggableResizableWidgetState();
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
  int _lastX = 0;
  int _lastY = 0;
  int _lastW = 0;
  int _lastH = 0;

  @override
  void initState() {
    super.initState();
    _lastX = widget.widget.x;
    _lastY = widget.widget.y;
    _lastW = widget.widget.w;
    _lastH = widget.widget.h;
  }

  bool _checkOverlap(int x, int y, int w, int h) {
    final testWidget = widget.widget.copyWith(x: x, y: y, w: w, h: h);
    return GridLayoutManager.checkOverlap(
      testWidget,
      widget.allWidgets,
      excludeId: widget.widget.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: widget.isEditMode ? widget.onSelect : null,
          child: Listener(
            onPointerDown: widget.isEditMode && widget.isSelected && !_isResizing
                ? (details) {
                    setState(() {
                      _isDragging = true;
                      _startX = details.position.dx;
                      _startY = details.position.dy;
                      _initialGridX = widget.widget.x;
                      _initialGridY = widget.widget.y;
                    });
                  }
                : null,
            onPointerMove: _isDragging
                ? (details) {
                    final deltaX = details.position.dx - _startX;
                    final deltaY = details.position.dy - _startY;
                    
                    final gridDeltaX = (deltaX / widget.cellSize).round();
                    final gridDeltaY = (deltaY / widget.cellSize).round();
                    
                    int newX = (_initialGridX + gridDeltaX).clamp(0, widget.gridColumns - widget.widget.w);
                    int newY = (_initialGridY + gridDeltaY).clamp(0, 1000);
                    
                    if (_checkOverlap(newX, newY, widget.widget.w, widget.widget.h)) {
                      return;
                    }
                    
                    if (newX != _lastX || newY != _lastY) {
                      _lastX = newX;
                      _lastY = newY;
                      widget.onPositionChanged(newX, newY);
                    }
                  }
                : null,
            onPointerUp: _isDragging
                ? (details) {
                    setState(() {
                      _isDragging = false;
                    });
                  }
                : null,
            onPointerCancel: _isDragging
                ? (details) {
                    setState(() {
                      _isDragging = false;
                    });
                  }
                : null,
            child: Transform(
              transform: _isDragging 
                  ? (Matrix4.identity()..scale(1.02))
                  : Matrix4.identity(),
              alignment: Alignment.center,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  border: widget.isSelected && widget.isEditMode
                      ? Border.all(color: const Color(0xFF6366F1), width: 2)
                      : null,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  boxShadow: _isDragging
                      ? [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : [],
                ),
                child: widget.child,
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
      _buildResizeHandle('top-left', Alignment.topLeft, -1, -1),
      _buildResizeHandle('top-right', Alignment.topRight, 1, -1),
      _buildResizeHandle('bottom-left', Alignment.bottomLeft, -1, 1),
      _buildResizeHandle('bottom-right', Alignment.bottomRight, 1, 1),
    ];
  }

  Widget _buildResizeHandle(String handleName, Alignment alignment, int dx, int dy) {
    return Positioned(
      left: alignment.x == -1 ? -5 : null,
      right: alignment.x == 1 ? -5 : null,
      top: alignment.y == -1 ? -5 : null,
      bottom: alignment.y == 1 ? -5 : null,
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
              _initialGridX = widget.widget.x;
              _initialGridY = widget.widget.y;
              _initialGridW = widget.widget.w;
              _initialGridH = widget.widget.h;
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
                  
                  if (handleName.contains('left')) {
                    final delta = gridDeltaX;
                    newX = (_initialGridX + delta).clamp(0, _initialGridX + _initialGridW - 1);
                    newW = (_initialGridW - delta).clamp(1, widget.gridColumns - newX);
                  }
                  if (handleName.contains('right')) {
                    newW = (_initialGridW + gridDeltaX).clamp(1, widget.gridColumns - _initialGridX);
                  }
                  if (handleName.contains('top')) {
                    final delta = gridDeltaY;
                    newY = (_initialGridY + delta).clamp(0, _initialGridY + _initialGridH - 1);
                    newH = (_initialGridH - delta).clamp(1, 1000);
                  }
                  if (handleName.contains('bottom')) {
                    newH = (_initialGridH + gridDeltaY).clamp(1, 1000);
                  }
                  
                  if (_checkOverlap(newX, newY, newW, newH)) {
                    return;
                  }
                  
                  if (newX != _lastX || newY != _lastY) {
                    _lastX = newX;
                    _lastY = newY;
                    widget.onPositionChanged(newX, newY);
                  }
                  if (newW != _lastW || newH != _lastH) {
                    _lastW = newW;
                    _lastH = newH;
                    widget.onSizeChanged(newW, newH);
                  }
                }
              : null,
          onPointerUp: _isResizing && _activeResizeHandle == handleName
              ? (details) {
                  setState(() {
                    _isResizing = false;
                    _activeResizeHandle = null;
                  });
                }
              : null,
          onPointerCancel: _isResizing && _activeResizeHandle == handleName
              ? (details) {
                  setState(() {
                    _isResizing = false;
                    _activeResizeHandle = null;
                  });
                }
              : null,
          child: Container(
            width: 10,
            height: 10,
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
    );
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
