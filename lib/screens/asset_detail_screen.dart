import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/asset.dart';
import '../models/asset_type.dart';
import '../models/asset_record.dart';
import '../models/asset_detail.dart';
import '../providers/asset_provider.dart';
import '../providers/asset_type_provider.dart';
import '../providers/asset_record_provider.dart';
import '../providers/asset_detail_provider.dart';
import '../widgets/asset_form_dialog.dart';
import '../widgets/asset_detail_form_dialog.dart';
import '../theme/app_theme.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

enum Period { day, week, month, year }

class AssetDetailScreen extends StatefulWidget {
  final Asset asset;
  final VoidCallback? onBack;

  const AssetDetailScreen({
    super.key,
    required this.asset,
    this.onBack,
  });

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  Period _selectedPeriod = Period.month;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.asset.id != null) {
        context.read<AssetRecordProvider>().loadRecordsByAsset(widget.asset.id!);
        context.read<AssetDetailProvider>().loadDetails(widget.asset.id!);
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    setState(() {
      _selectedTabIndex = _tabController.index;
    });
  }

  double _getAssetValue() {
    if (widget.asset.customData != null) {
      try {
        final data = Map<String, dynamic>.from(
          widget.asset.customData as Map,
        );
        return (data['value'] as num?)?.toDouble() ?? 0.0;
      } catch (_) {
        return 0.0;
      }
    }
    return 0.0;
  }

  String _getAssetTypeName(List<AssetType> assetTypes) {
    final assetType = assetTypes.firstWhere(
      (type) => type.id == widget.asset.typeId,
      orElse: () => AssetType(
        id: widget.asset.typeId,
        name: '未知类型',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    return assetType.name;
  }

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
      return const Color(0xFF1E293B);
    }
  }

  Color _getAssetTypeColor(List<AssetType> assetTypes) {
    final assetType = assetTypes.firstWhere(
      (type) => type.id == widget.asset.typeId,
      orElse: () => AssetType(
        id: widget.asset.typeId,
        name: '未知类型',
        color: '#1E293B',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    return _parseColor(assetType.color ?? '#1E293B');
  }

    Map<String, double> _calculateStats(List<AssetRecord> records) {
    if (records.isEmpty) {
      return {
        'current': 0.0,
        'average': 0.0,
        'max': 0.0,
        'min': 0.0,
      };
    }

    final values = records.map((r) => r.value).toList();
    final current = values.last;
    final average = values.reduce((a, b) => a + b) / values.length;
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);

    return {
      'current': current,
      'average': average,
      'max': max,
      'min': min,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Consumer4<AssetProvider, AssetTypeProvider, AssetRecordProvider, AssetDetailProvider>(
        builder: (context, assetProvider, assetTypeProvider, recordProvider, detailProvider, child) {
          final assetTypes = assetTypeProvider.assetTypes;
          final records = recordProvider.records;
          final value = _getAssetValue();
          final typeName = _getAssetTypeName(assetTypes);
          final typeColor = _getAssetTypeColor(assetTypes);
          final formatter = NumberFormat.currency(
            locale: 'zh_CN',
            symbol: '¥',
            decimalDigits: 2,
          );
          final dateFormatter = DateFormat('yyyy-MM-dd HH:mm');
          final stats = _calculateStats(records);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 180,
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
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF1E293B),
                          const Color(0xFF6366F1),
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
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppTheme.spacingS),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                  ),
                                  child: Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingS),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.asset.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        typeName,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                            Text(
                              formatter.format(stats['current'] ?? 0),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -1,
                              ),
                            ),
                            if (records.length >= 2)
                              _buildChangeIndicator(records, formatter),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(top: AppTheme.spacingM),
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
                  child: Column(
                    children: [
                      _buildQuickActionsSection(context),
                      const SizedBox(height: AppTheme.spacingM),
                      _buildTabBar(),
                    ],
                  ),
                ),
              ),
              SliverFillRemaining(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(records, stats, formatter, dateFormatter, typeColor),
                      _buildTrendsTab(records, formatter),
                      _buildHistoryTab(records, formatter, dateFormatter),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChangeIndicator(List<AssetRecord> records, NumberFormat formatter) {
    if (records.length < 2) return const SizedBox.shrink();

    final sortedRecords = List<AssetRecord>.from(records)
      ..sort((a, b) => a.recordDate.compareTo(b.recordDate));

    final first = sortedRecords.first.value;
    final last = sortedRecords.last.value;
    final change = last - first;
    final changePercent = first != 0 ? (change / first) * 100 : 0;
    final isPositive = change >= 0;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingS,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: isPositive
                ? const Color(0xFF10B981).withValues(alpha: 0.2)
                : const Color(0xFFEF4444).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
              const SizedBox(width: 4),
              Text(
                '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppTheme.spacingS),
        Text(
          '${isPositive ? '+' : ''}${formatter.format(change)}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
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
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  Icons.add_circle_outline_rounded,
                  '添加记录',
                  const Color(0xFF6366F1),
                  () => _showAddRecordDialog(context),
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: _buildQuickActionButton(
                  Icons.edit_rounded,
                  '编辑资产',
                  const Color(0xFF10B981),
                  () {
                    showDialog(
                      context: context,
                      builder: (context) => AssetFormDialog(asset: widget.asset),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: _buildQuickActionButton(
                  Icons.delete_outline_rounded,
                  '删除资产',
                  const Color(0xFFEF4444),
                  () => _showDeleteConfirmation(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacingM,
          horizontal: AppTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
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
      child: Row(
        children: [
          _buildTabItem(0, '概览'),
          _buildTabItem(1, '价值走势'),
          _buildTabItem(2, '资金记录'),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label) {
    final isSelected = _selectedTabIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
            _tabController.animateTo(index);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(
    List<AssetRecord> records,
    Map<String, double> stats,
    NumberFormat formatter,
    DateFormat dateFormatter,
    Color typeColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: AppTheme.spacingM),
      child: Column(
        children: [
          _buildBasicInfoCard(formatter, dateFormatter, typeColor),
          const SizedBox(height: AppTheme.spacingM),
          _buildQuickStatsCard(stats, formatter),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard(
    NumberFormat formatter,
    DateFormat dateFormatter,
    Color typeColor,
  ) {
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
            '基本信息',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildInfoRow(Icons.label_rounded, '资产名称', widget.asset.name),
          const SizedBox(height: AppTheme.spacingS),
          _buildInfoRow(Icons.category_rounded, '资产类型', _getAssetTypeName(context.read<AssetTypeProvider>().assetTypes)),
          const SizedBox(height: AppTheme.spacingS),
          if (widget.asset.location != null) ...[
            _buildInfoRow(Icons.location_on_rounded, '位置', widget.asset.location!),
            const SizedBox(height: AppTheme.spacingS),
          ],
          _buildInfoRow(
            Icons.calendar_today_rounded,
            '创建时间',
            dateFormatter.format(DateTime.fromMillisecondsSinceEpoch(widget.asset.createdAt)),
          ),
          const SizedBox(height: AppTheme.spacingS),
          _buildInfoRow(
            Icons.update_rounded,
            '最后更新',
            dateFormatter.format(DateTime.fromMillisecondsSinceEpoch(widget.asset.updatedAt)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatsCard(Map<String, double> stats, NumberFormat formatter) {
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
            '快速统计',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('当前价值', formatter.format(stats['current'] ?? 0), const Color(0xFF6366F1)),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildStatItem('平均价值', formatter.format(stats['average'] ?? 0), const Color(0xFF10B981)),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('最高价值', formatter.format(stats['max'] ?? 0), const Color(0xFFF59E0B)),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildStatItem('最低价值', formatter.format(stats['min'] ?? 0), const Color(0xFFEF4444)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsTab(List<AssetRecord> records, NumberFormat formatter) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: AppTheme.spacingM),
      child: Column(
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: AppTheme.spacingM),
          _buildValueTrendCard(records, formatter),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
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
      child: Row(
        children: Period.values.map((period) {
          final isSelected = _selectedPeriod == period;
          final label = _getPeriodLabel(period);
          
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getPeriodLabel(Period period) {
    switch (period) {
      case Period.day:
        return '日';
      case Period.week:
        return '周';
      case Period.month:
        return '月';
      case Period.year:
        return '年';
    }
  }

  List<AssetRecord> _filterRecordsByPeriod(List<AssetRecord> records, DateTime now) {
    switch (_selectedPeriod) {
      case Period.day:
        final today = DateTime(now.year, now.month, now.day);
        return records.where((r) {
          final recordDate = DateTime.fromMillisecondsSinceEpoch(r.recordDate);
          return recordDate.year == today.year &&
              recordDate.month == today.month &&
              recordDate.day == today.day;
        }).toList();
      case Period.week:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return records.where((r) {
          final recordDate = DateTime.fromMillisecondsSinceEpoch(r.recordDate);
          return recordDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
              recordDate.isBefore(weekEnd.add(const Duration(days: 1)));
        }).toList();
      case Period.month:
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 0);
        return records.where((r) {
          final recordDate = DateTime.fromMillisecondsSinceEpoch(r.recordDate);
          return recordDate.isAfter(monthStart.subtract(const Duration(days: 1))) &&
              recordDate.isBefore(monthEnd.add(const Duration(days: 1)));
        }).toList();
      case Period.year:
        final yearStart = DateTime(now.year, 1, 1);
        final yearEnd = DateTime(now.year + 1, 1, 0);
        return records.where((r) {
          final recordDate = DateTime.fromMillisecondsSinceEpoch(r.recordDate);
          return recordDate.isAfter(yearStart.subtract(const Duration(days: 1))) &&
              recordDate.isBefore(yearEnd.add(const Duration(days: 1)));
        }).toList();
    }
  }

  Widget _buildValueTrendCard(List<AssetRecord> records, NumberFormat formatter) {
    final now = DateTime.now();
    final filteredRecords = _filterRecordsByPeriod(records, now);
    
    DateTime? minAxisDate;
    DateTime? maxAxisDate;
    String dateFormat = 'MM-dd';

    switch (_selectedPeriod) {
      case Period.day:
        minAxisDate = DateTime(now.year, now.month, now.day);
        maxAxisDate = minAxisDate.add(const Duration(days: 1));
        dateFormat = 'HH:mm';
        break;
      case Period.week:
        minAxisDate = now.subtract(Duration(days: now.weekday - 1));
        maxAxisDate = minAxisDate.add(const Duration(days: 7));
        dateFormat = 'MM-dd';
        break;
      case Period.month:
        minAxisDate = DateTime(now.year, now.month, 1);
        maxAxisDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        dateFormat = 'MM-dd';
        break;
      case Period.year:
        minAxisDate = DateTime(now.year, 1, 1);
        maxAxisDate = DateTime(now.year + 1, 1, 0, 23, 59, 59);
        dateFormat = 'yyyy-MM';
        break;
    }

    if (filteredRecords.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
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
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              '暂无数据',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final sortedRecords = List<AssetRecord>.from(filteredRecords)
      ..sort((a, b) => a.recordDate.compareTo(b.recordDate));
    
    double change = 0;
    double changePercent = 0;
    if (sortedRecords.length >= 2) {
      final first = sortedRecords.first.value;
      final last = sortedRecords.last.value;
      change = last - first;
      if (first != 0) {
        changePercent = (change / first) * 100;
      }
    }

    final isPositive = change >= 0;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    '价值趋势',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingS,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    ),
                    child: Text(
                      _getPeriodLabel(_selectedPeriod),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ),
                ],
              ),
              if (sortedRecords.length >= 2)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingS,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPositive 
                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                        : const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 14,
                        color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '变化金额',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${isPositive ? '+' : ''}${formatter.format(change)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '记录次数',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${filteredRecords.length} 次',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (sortedRecords.length > 1) ...[
            const SizedBox(height: AppTheme.spacingM),
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                margin: EdgeInsets.zero,
                primaryXAxis: DateTimeAxis(
                  minimum: minAxisDate,
                  maximum: maxAxisDate,
                  dateFormat: DateFormat(dateFormat),
                  majorGridLines: const MajorGridLines(width: 0),
                  labelStyle: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                primaryYAxis: NumericAxis(
                  numberFormat: NumberFormat.compact(),
                  labelStyle: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  axisLine: const AxisLine(width: 0),
                ),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <CartesianSeries>[
                  LineSeries<AssetRecord, DateTime>(
                    dataSource: sortedRecords,
                    xValueMapper: (AssetRecord r, _) => DateTime.fromMillisecondsSinceEpoch(r.recordDate),
                    yValueMapper: (AssetRecord r, _) => r.value,
                    color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    width: 2,
                    animationDuration: 0,
                    markerSettings: const MarkerSettings(isVisible: true, width: 4, height: 4),
                  )
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryTab(List<AssetRecord> records, NumberFormat formatter, DateFormat dateFormatter) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: AppTheme.spacingM),
      child: _buildRecordsSection(records, formatter, dateFormatter),
    );
  }

  Widget _buildRecordsSection(
    List<AssetRecord> records,
    NumberFormat formatter,
    DateFormat dateFormatter,
  ) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '资金记录',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingS,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                  child: Text(
                    '共 ${records.length} 条',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            if (records.isEmpty)
              _buildEmptyRecordsState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: records.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  color: Color(0xFFE8ECF4),
                ),
                itemBuilder: (context, index) {
                  final record = records[index];
                  return _buildRecordItem(record, formatter, dateFormatter);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRecordsState() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            '暂无记录',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordItem(
    AssetRecord record,
    NumberFormat formatter,
    DateFormat dateFormatter,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: Color(0xFF1E293B),
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                '${formatter.format(record.value)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateFormatter.format(
                    DateTime.fromMillisecondsSinceEpoch(record.recordDate),
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (record.note != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    record.note!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: Colors.grey[600],
                onPressed: () => _showEditRecordDialog(context, record),
                tooltip: '编辑',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: const Color(0xFFEF4444),
                onPressed: () => _showDeleteRecordConfirmation(context, record),
                tooltip: '删除',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddRecordDialog(BuildContext context) {
    final valueController = TextEditingController();
    final noteController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        title: const Text('添加记录'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: valueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '金额',
                prefixText: '¥ ',
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(valueController.text);
              if (value != null && widget.asset.id != null) {
                final record = AssetRecord(
                  assetId: widget.asset.id!,
                  value: value,
                  recordDate: DateTime.now().millisecondsSinceEpoch,
                  createdAt: DateTime.now().millisecondsSinceEpoch,
                  note: noteController.text.isEmpty ? null : noteController.text,
                );
                context.read<AssetRecordProvider>().addRecord(record);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('记录添加成功')),
                );
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showEditRecordDialog(BuildContext context, AssetRecord record) {
    final valueController = TextEditingController(text: record.value.toString());
    final noteController = TextEditingController(text: record.note ?? '');
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        title: const Text('编辑记录'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: valueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '金额',
                prefixText: '¥ ',
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(valueController.text);
              if (value != null && record.id != null) {
                final updatedRecord = AssetRecord(
                  id: record.id,
                  assetId: record.assetId,
                  value: value,
                  recordDate: record.recordDate,
                  createdAt: record.createdAt,
                  note: noteController.text.isEmpty ? null : noteController.text,
                );
                context.read<AssetRecordProvider>().updateRecord(updatedRecord);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('记录更新成功')),
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDeleteRecordConfirmation(BuildContext context, AssetRecord record) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        title: const Text('确认删除'),
        content: const Text('确定要删除这条记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (record.id != null) {
                context.read<AssetRecordProvider>().deleteRecord(record.id!, record.assetId);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('记录已删除')),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        title: const Text('确认删除'),
        content: Text('确定要删除资产 "${widget.asset.name}" 吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (widget.asset.id != null) {
                context.read<AssetProvider>().deleteAsset(widget.asset.id!);
                Navigator.pop(dialogContext);
                if (widget.onBack != null) {
                  widget.onBack!();
                } else {
                  Navigator.pop(context);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已删除资产 "${widget.asset.name}"')),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

