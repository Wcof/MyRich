import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/asset.dart';
import '../models/asset_record.dart';
import '../models/fund_plan.dart';
import '../providers/asset_provider.dart';
import '../providers/asset_record_provider.dart';
import '../providers/fund_plan_provider.dart';
import '../providers/fund_sync_provider.dart';
import '../services/fund_asset_mapper.dart';
import '../widgets/fund_form_dialog.dart';
import '../widgets/fund_plan_dialog.dart';
import '../widgets/fund_return_chart.dart';
import '../theme/app_theme.dart';

class FundAssetDetailScreen extends StatefulWidget {
  final Asset asset;
  final VoidCallback? onBack;

  const FundAssetDetailScreen({
    super.key,
    required this.asset,
    this.onBack,
  });

  @override
  State<FundAssetDetailScreen> createState() => _FundAssetDetailScreenState();
}

class _FundAssetDetailScreenState extends State<FundAssetDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.asset.id != null) {
        context.read<AssetRecordProvider>().loadRecordsByAsset(widget.asset.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Consumer2<AssetProvider, AssetRecordProvider>(
        builder: (context, assetProvider, recordProvider, child) {
          final currentAsset = widget.asset.id != null
              ? assetProvider.assets.firstWhere(
                  (a) => a.id == widget.asset.id,
                  orElse: () => widget.asset,
                )
              : widget.asset;
          final fundData = FundAssetMapper.extractFundData(currentAsset);
          final records = recordProvider.records;
          
          final formatter = NumberFormat.currency(
            locale: 'zh_CN',
            symbol: '¥',
            decimalDigits: 2,
          );
          final dateFormatter = DateFormat('yyyy-MM-dd');

          return CustomScrollView(
            slivers: [
              _buildHeader(fundData, formatter),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  child: Column(
                    children: [
                      _buildFundInfoCard(fundData, formatter, dateFormatter),
                      const SizedBox(height: AppTheme.spacingM),
                      _buildQuickActions(),
                      const SizedBox(height: AppTheme.spacingM),
                      _buildReturnCard(fundData, formatter),
                      const SizedBox(height: AppTheme.spacingM),
                      _buildTransactionRecordsCard(records, formatter, dateFormatter),
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

  Widget _buildHeader(FundData? fundData, NumberFormat formatter) {
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
                Color(0xFFFF9800),
                Color(0xFFF57C00),
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.pie_chart_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fundData?.fundName ?? widget.asset.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (fundData != null)
                              Text(
                                fundData.fundCode,
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
                    formatter.format(fundData?.currentValue ?? 0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
                  ),
                  if (fundData != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: fundData.returnAmount >= 0
                                ? Colors.white.withValues(alpha: 0.25)
                                : Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                fundData.returnAmount >= 0
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${fundData.returnAmount >= 0 ? '+' : ''}${(fundData.returnRate * 100).toStringAsFixed(2)}%',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${fundData.returnAmount >= 0 ? '+' : ''}${formatter.format(fundData.returnAmount)}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
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

  Widget _buildFundInfoCard(FundData? fundData, NumberFormat formatter, DateFormat dateFormatter) {
    if (fundData == null) {
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
        child: const Center(
          child: Text('暂无基金数据'),
        ),
      );
    }

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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFFF9800),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '基金信息',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildInfoRow('基金编码', fundData.fundCode),
          const Divider(height: 24),
          _buildInfoRow('基金名称', fundData.fundName),
          const Divider(height: 24),
          _buildInfoRow('持有份额', '${fundData.quantity.toStringAsFixed(2)} 份'),
          if (fundData.apiSource != null) ...[
            const Divider(height: 24),
            _buildInfoRow('数据来源', fundData.apiSource!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
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

  Widget _buildReturnCard(FundData? fundData, NumberFormat formatter) {
    if (fundData == null) return const SizedBox.shrink();

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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (fundData.returnAmount >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  fundData.returnAmount >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: fundData.returnAmount >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '收益分析',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildReturnItem(
                  '投入成本',
                  formatter.format(fundData.purchaseValue),
                  const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildReturnItem(
                  '当前价值',
                  formatter.format(fundData.currentValue),
                  const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildReturnItem(
                  '累计收益',
                  '${fundData.returnAmount >= 0 ? '+' : ''}${formatter.format(fundData.returnAmount)}',
                  fundData.returnAmount >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildReturnItem(
                  '收益率',
                  '${fundData.returnAmount >= 0 ? '+' : ''}${(fundData.returnRate * 100).toStringAsFixed(2)}%',
                  fundData.returnAmount >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          const Divider(height: 1),
          const SizedBox(height: AppTheme.spacingL),
          Consumer<AssetRecordProvider>(
            builder: (context, recordProvider, child) {
              return FundReturnChart(
                fundData: fundData,
                records: recordProvider.records,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReturnItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
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
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRecordsCard(List<AssetRecord> records, NumberFormat formatter, DateFormat dateFormatter) {
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '交易记录',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          if (records.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingXL),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Text(
                      '暂无交易记录',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: records.take(10).map((record) {
                return _buildTransactionItem(record, formatter, dateFormatter);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(AssetRecord record, NumberFormat formatter, DateFormat dateFormatter) {
    final isRevoked = record.isRevoked;
    final isEstimated = record.status == TransactionStatus.estimated;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRevoked ? Colors.grey[200] : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: isRevoked 
                  ? Colors.grey[400] 
                  : (isEstimated ? Colors.orange[400] : const Color(0xFFFF9800)),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      dateFormatter.format(DateTime.fromMillisecondsSinceEpoch(record.recordDate)),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isRevoked ? Colors.grey[500] : const Color(0xFF1E293B),
                        decoration: isRevoked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (isRevoked) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '已撤回',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ] else if (isEstimated) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange[400],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '预估',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (record.quantity != null) ...[
                      Text(
                        '${record.note}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isRevoked 
                              ? Colors.grey[500] 
                              : (record.note == '买入' ? Colors.green[600] : Colors.red[600]),
                          fontWeight: FontWeight.w500,
                          decoration: isRevoked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${record.quantity!.abs().toStringAsFixed(2)}份',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          decoration: isRevoked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      formatter.format(record.value.abs()),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isRevoked ? Colors.grey[500] : const Color(0xFFFF9800),
                        decoration: isRevoked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
                if (record.unitPrice != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '净值',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          decoration: isRevoked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '¥${record.unitPrice!.toStringAsFixed(4)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          decoration: isRevoked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (isEstimated && !isRevoked) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.schedule, size: 12, color: Colors.orange[600]),
                        const SizedBox(width: 4),
                        Text(
                          '待确认',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (!isRevoked)
            IconButton(
              icon: Icon(Icons.undo, size: 18, color: Colors.grey[600]),
              onPressed: () => _showRevokeConfirmation(record),
              tooltip: '撤回',
            ),
        ],
      ),
    );
  }

  void _showRevokeConfirmation(AssetRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认撤回'),
        content: Text('确定要撤回这笔${record.note ?? '交易'}记录吗？\n撤回后交易记录将保留但标记为已撤回。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              _handleRevoke(record);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('确认撤回'),
          ),
        ],
      ),
    );
  }

  void _handleRevoke(AssetRecord record) {
    final recordProvider = context.read<AssetRecordProvider>();
    final assetProvider = context.read<AssetProvider>();
    
    final updatedRecord = record.copyWith(isRevoked: true);
    recordProvider.updateRecord(updatedRecord);
    
    final currentAsset = widget.asset.id != null
        ? assetProvider.assets.firstWhere(
            (a) => a.id == widget.asset.id,
            orElse: () => widget.asset,
          )
        : widget.asset;
    
    final fundData = FundAssetMapper.extractFundData(currentAsset);
    if (fundData != null && currentAsset.id != null) {
      double newQuantity = fundData.quantity;
      double newPurchaseValue = fundData.purchaseValue;
      
      if (record.note == '买入') {
        newQuantity -= record.quantity?.abs() ?? 0;
        newPurchaseValue -= record.value.abs();
      } else if (record.note == '卖出') {
        newQuantity += record.quantity?.abs() ?? 0;
        newPurchaseValue += record.value.abs();
      }
      
      final newPurchasePrice = newQuantity > 0 ? newPurchaseValue / newQuantity : fundData.purchasePrice;
      
      final updatedFundData = fundData.copyWith(
        quantity: newQuantity,
        purchasePrice: newPurchasePrice,
        lastUpdateAt: DateTime.now().millisecondsSinceEpoch,
      );
      
      final updatedAsset = FundAssetMapper.updateFundData(currentAsset, updatedFundData);
      assetProvider.updateAsset(updatedAsset);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已撤回${record.note ?? "交易"}记录')),
    );
  }

  Widget _buildQuickActions() {
    return Consumer<FundSyncProvider>(
      builder: (context, fundSyncProvider, child) {
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.flash_on_rounded,
                      color: Color(0xFF8B5CF6),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '快速操作',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      Icons.refresh_rounded,
                      '更新净值',
                      const Color(0xFF6366F1),
                      fundSyncProvider.isSyncing
                          ? null
                          : () => fundSyncProvider.refreshNow(),
                      fundSyncProvider.isSyncing,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: _buildActionButton(
                      Icons.add_circle_outline_rounded,
                      '买入',
                      const Color(0xFF10B981),
                      () => _showBuyDialog(),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: _buildActionButton(
                      Icons.remove_circle_outline_rounded,
                      '卖出',
                      const Color(0xFFEF4444),
                      () => _showSellDialog(),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: _buildActionButton(
                      Icons.repeat_rounded,
                      '定投',
                      const Color(0xFF8B5CF6),
                      () => _showFundPlanDialog(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingS),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      Icons.edit_rounded,
                      '编辑',
                      const Color(0xFF6366F1),
                      () {
                        showDialog(
                          context: context,
                          builder: (context) => FundFormDialog(asset: widget.asset),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: _buildActionButton(
                      Icons.delete_outline_rounded,
                      '删除',
                      const Color(0xFFEF4444),
                      () => _showDeleteConfirmation(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback? onTap, [bool isLoading = false]) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                : Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBuyDialog() {
    final assetProvider = context.read<AssetProvider>();
    final currentAsset = widget.asset.id != null
        ? assetProvider.assets.firstWhere(
            (a) => a.id == widget.asset.id,
            orElse: () => widget.asset,
          )
        : widget.asset;
    
    final fundData = FundAssetMapper.extractFundData(currentAsset);
    if (fundData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法获取基金数据')),
      );
      return;
    }

    final amountController = TextEditingController();
    final currentPrice = fundData.currentPrice > 0 ? fundData.currentPrice : 1.0;
    double calculatedQuantity = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('买入基金'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '基金: ${fundData.fundName}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '当前净值: ¥${currentPrice.toStringAsFixed(4)}（前一工作日）',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: '买入金额',
                      hintText: '请输入买入金额',
                      suffixText: '元',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final amount = double.tryParse(value) ?? 0;
                      setState(() {
                        calculatedQuantity = currentPrice > 0 ? amount / currentPrice : 0;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [1000, 5000, 10000].map((amount) {
                      return InkWell(
                        onTap: () {
                          amountController.text = amount.toString();
                          setState(() {
                            calculatedQuantity = currentPrice > 0 ? amount / currentPrice : 0;
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            '¥$amount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (calculatedQuantity > 0) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF81C784)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '可购买份额:',
                            style: TextStyle(color: Colors.green[700]),
                          ),
                          Text(
                            '${calculatedQuantity.toStringAsFixed(2)} 份',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text);

                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请输入有效的买入金额')),
                    );
                    return;
                  }

                  final quantity = amount / currentPrice;
                  _handleBuy(quantity, currentPrice, amount);
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF10B981),
                ),
                child: const Text('确认买入'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSellDialog() {
    final assetProvider = context.read<AssetProvider>();
    final currentAsset = widget.asset.id != null
        ? assetProvider.assets.firstWhere(
            (a) => a.id == widget.asset.id,
            orElse: () => widget.asset,
          )
        : widget.asset;
    
    final fundData = FundAssetMapper.extractFundData(currentAsset);
    if (fundData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法获取基金数据')),
      );
      return;
    }

    final quantityController = TextEditingController();
    final currentPrice = fundData.currentPrice > 0 ? fundData.currentPrice : 1.0;
    double calculatedAmount = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('卖出基金'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '基金: ${fundData.fundName}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '当前持有: ${fundData.quantity.toStringAsFixed(2)} 份',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '当前净值: ¥${currentPrice.toStringAsFixed(4)}（前一工作日）',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '卖出份额',
                      hintText: '最多可卖出 ${fundData.quantity.toStringAsFixed(2)} 份',
                      suffixText: '份',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final quantity = double.tryParse(value) ?? 0;
                      setState(() {
                        calculatedAmount = quantity * currentPrice;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      {'label': '1/4', 'ratio': 0.25},
                      {'label': '1/3', 'ratio': 0.333},
                      {'label': '1/2', 'ratio': 0.5},
                      {'label': '全部', 'ratio': 1.0},
                    ].map((item) {
                      return InkWell(
                        onTap: () {
                          final qty = fundData.quantity * (item['ratio'] as double);
                          quantityController.text = qty.toStringAsFixed(2);
                          setState(() {
                            calculatedAmount = qty * currentPrice;
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF5576C).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            item['label'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (calculatedAmount > 0) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFEF5350)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '预估卖出金额:',
                            style: TextStyle(color: Colors.red[700]),
                          ),
                          Text(
                            '¥${calculatedAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.red[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  final quantity = double.tryParse(quantityController.text);

                  if (quantity == null || quantity <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请输入有效的卖出份额')),
                    );
                    return;
                  }

                  if (quantity > fundData.quantity) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('卖出份额不能超过持有份额')),
                    );
                    return;
                  }

                  final amount = quantity * currentPrice;
                  _handleSell(quantity, currentPrice, amount);
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                ),
                child: const Text('确认卖出'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleBuy(double quantity, double price, double amount) {
    final assetProvider = context.read<AssetProvider>();
    final recordProvider = context.read<AssetRecordProvider>();
    final currentAsset = widget.asset.id != null
        ? assetProvider.assets.firstWhere(
            (a) => a.id == widget.asset.id,
            orElse: () => widget.asset,
          )
        : widget.asset;
    
    final fundData = FundAssetMapper.extractFundData(currentAsset);
    if (fundData == null || currentAsset.id == null) return;

    final newQuantity = fundData.quantity + quantity;
    final newPurchaseValue = fundData.purchaseValue + amount;
    final newPurchasePrice = newPurchaseValue / newQuantity;

    final updatedFundData = fundData.copyWith(
      quantity: newQuantity,
      purchasePrice: newPurchasePrice,
      lastUpdateAt: DateTime.now().millisecondsSinceEpoch,
    );

    final updatedAsset = FundAssetMapper.updateFundData(currentAsset, updatedFundData);
    assetProvider.updateAsset(updatedAsset);

    final record = AssetRecord(
      assetId: currentAsset.id!,
      value: amount,
      quantity: quantity,
      unitPrice: price,
      note: '买入',
      recordDate: DateTime.now().millisecondsSinceEpoch,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    recordProvider.addRecord(record);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('成功买入 ${quantity.toStringAsFixed(2)} 份，投入金额 ¥${amount.toStringAsFixed(2)}，成本价 ¥${newPurchasePrice.toStringAsFixed(4)}')),
    );
  }

  void _handleSell(double quantity, double price, double amount) {
    final assetProvider = context.read<AssetProvider>();
    final recordProvider = context.read<AssetRecordProvider>();
    final currentAsset = widget.asset.id != null
        ? assetProvider.assets.firstWhere(
            (a) => a.id == widget.asset.id,
            orElse: () => widget.asset,
          )
        : widget.asset;
    
    final fundData = FundAssetMapper.extractFundData(currentAsset);
    if (fundData == null || currentAsset.id == null) return;

    final newQuantity = fundData.quantity - quantity;
    final ratio = quantity / fundData.quantity;
    final newPurchaseValue = fundData.purchaseValue * (1 - ratio);
    final newPurchasePrice = newQuantity > 0 ? newPurchaseValue / newQuantity : fundData.purchasePrice;

    final updatedFundData = fundData.copyWith(
      quantity: newQuantity,
      purchasePrice: newPurchasePrice,
      lastUpdateAt: DateTime.now().millisecondsSinceEpoch,
    );

    final updatedAsset = FundAssetMapper.updateFundData(currentAsset, updatedFundData);
    assetProvider.updateAsset(updatedAsset);

    final record = AssetRecord(
      assetId: currentAsset.id!,
      value: -amount,
      quantity: -quantity,
      unitPrice: price,
      note: '卖出',
      recordDate: DateTime.now().millisecondsSinceEpoch,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    recordProvider.addRecord(record);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('成功卖出 ${quantity.toStringAsFixed(2)} 份，获得金额 ¥${amount.toStringAsFixed(2)}')),
    );
  }

  void _showFundPlanDialog() {
    final fundData = FundAssetMapper.extractFundData(widget.asset);
    if (fundData == null || widget.asset.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法获取基金数据')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => FundPlanDialog(
        assetId: widget.asset.id!,
        fundCode: fundData.fundCode,
        fundName: fundData.fundName,
      ),
    ).then((plan) {
      if (plan != null) {
        final planProvider = context.read<FundPlanProvider>();
        planProvider.addPlan(plan);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('定投计划已创建')),
        );
      }
    });
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个基金资产吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              _deleteAsset();
              Navigator.pop(context);
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

  void _deleteAsset() {
    if (widget.asset.id != null) {
      context.read<AssetProvider>().deleteAsset(widget.asset.id!);
      if (widget.onBack != null) {
        widget.onBack!();
      } else {
        Navigator.pop(context);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已删除基金 "${widget.asset.name}"')),
      );
    }
  }
}
