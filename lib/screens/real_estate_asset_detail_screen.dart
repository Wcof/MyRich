import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/asset.dart';
import '../models/loan.dart';
import '../models/rental_income.dart';
import '../models/real_estate_price.dart';
import '../providers/asset_provider.dart';
import '../providers/loan_provider.dart';
import '../providers/rental_income_provider.dart';
import '../providers/real_estate_price_provider.dart';
import '../services/real_estate_asset_mapper.dart';
import '../theme/app_theme.dart';
import '../widgets/real_estate_form_dialog.dart';
import '../widgets/real_estate_loan_dialog.dart';
import '../widgets/real_estate_rental_dialog.dart';
import '../widgets/real_estate_price_history_dialog.dart';
import '../widgets/real_estate_price_trend_chart.dart';

class RealEstateAssetDetailScreen extends StatefulWidget {
  final Asset asset;
  final VoidCallback? onBack;

  const RealEstateAssetDetailScreen({
    super.key,
    required this.asset,
    this.onBack,
  });

  @override
  State<RealEstateAssetDetailScreen> createState() => _RealEstateAssetDetailScreenState();
}

class _RealEstateAssetDetailScreenState extends State<RealEstateAssetDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    if (widget.asset.id != null) {
      final assetId = widget.asset.id!;
      context.read<LoanProvider>().loadLoansByAssetId(assetId);
      context.read<RentalIncomeProvider>().loadRentalIncomeByAssetId(assetId);
      context.read<RealEstatePriceProvider>().loadLatestPricesByAssetId(assetId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Consumer4<AssetProvider, LoanProvider, RentalIncomeProvider, RealEstatePriceProvider>(
        builder: (context, assetProvider, loanProvider, rentalProvider, priceProvider, child) {
          final currentAsset = widget.asset.id != null
              ? assetProvider.assets.firstWhere(
                  (a) => a.id == widget.asset.id,
                  orElse: () => widget.asset,
                )
              : widget.asset;
          
          final realEstateData = RealEstateAssetMapper.extractRealEstateData(currentAsset);
          final loans = loanProvider.getLoansByAssetId(widget.asset.id ?? 0);
          final rentalIncomes = rentalProvider.getRentalIncomesByAssetId(widget.asset.id ?? 0);
          final prices = priceProvider.getPricesByAssetId(widget.asset.id ?? 0);
          
          final formatter = NumberFormat.currency(
            locale: 'zh_CN',
            symbol: '¥',
            decimalDigits: 2,
          );
          final dateFormatter = DateFormat('yyyy-MM-dd');

          final analysis = RealEstateAssetMapper.analyze(
            prices: prices,
            totalInvestment: realEstateData?.totalInvestment ?? 0,
            loans: loans,
            rentalIncomes: rentalIncomes,
          );

          return CustomScrollView(
            slivers: [
              _buildHeader(realEstateData, analysis, formatter),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  child: Column(
                    children: [
                      _buildBasicInfoCard(realEstateData, formatter, dateFormatter),
                      const SizedBox(height: AppTheme.spacingM),
                      _buildQuickActions(),
                      const SizedBox(height: AppTheme.spacingM),
                      _buildAnalysisCard(analysis, formatter),
                      const SizedBox(height: AppTheme.spacingM),
                      _buildLoanCard(loans, formatter, dateFormatter),
                      const SizedBox(height: AppTheme.spacingM),
                      _buildRentalCard(rentalIncomes, analysis, formatter, dateFormatter),
                      const SizedBox(height: AppTheme.spacingM),
                      _buildPriceHistoryCard(prices, formatter, dateFormatter),
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

  Widget _buildHeader(RealEstateData? data, RealEstateAnalysis analysis, NumberFormat formatter) {
    return SliverAppBar(
      expandedHeight: 240,
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
                Color(0xFF795548),
                Color(0xFF5D4037),
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
                          Icons.home_rounded,
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
                              widget.asset.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (data?.address != null)
                              Text(
                                data!.address!,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    formatter.format(analysis.marketValue),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: analysis.appreciation >= 0
                              ? Colors.white.withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              analysis.appreciation >= 0
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${analysis.appreciation >= 0 ? '+' : ''}${formatter.format(analysis.appreciation)}',
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
                        '增值 ${analysis.appreciationRate.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard(RealEstateData? data, NumberFormat formatter, DateFormat dateFormatter) {
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
                  color: const Color(0xFF795548).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF795548),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '房产信息',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          if (data != null) ...[
            _buildInfoRow('购置日期', dateFormatter.format(DateTime.fromMillisecondsSinceEpoch(data.purchaseDate))),
            const Divider(height: 24),
            _buildInfoRow('购置价格', formatter.format(data.purchasePrice)),
            if (data.renovationCost > 0) ...[
              const Divider(height: 24),
              _buildInfoRow('装修投入', formatter.format(data.renovationCost)),
            ],
            if (data.modificationCost > 0) ...[
              const Divider(height: 24),
              _buildInfoRow('改造投入', formatter.format(data.modificationCost)),
            ],
            const Divider(height: 24),
            _buildInfoRow('总投入成本', formatter.format(data.totalInvestment)),
            if (data.area != null) ...[
              const Divider(height: 24),
              _buildInfoRow('建筑面积', '${data.area!.toStringAsFixed(2)} 平方米'),
            ],
            if (data.roomType != null) ...[
              const Divider(height: 24),
              _buildInfoRow('房型', data.roomType!),
            ],
          ] else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacingL),
                child: Text('暂无房产数据'),
              ),
            ),
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

  Widget _buildAnalysisCard(RealEstateAnalysis analysis, NumberFormat formatter) {
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
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '资产分析',
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
                child: _buildAnalysisItem(
                  '市场价值',
                  formatter.format(analysis.marketValue),
                  const Color(0xFF795548),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildAnalysisItem(
                  '净资产',
                  formatter.format(analysis.netAssetValue),
                  const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildAnalysisItem(
                  '总投入',
                  formatter.format(analysis.totalInvestment),
                  const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildAnalysisItem(
                  '贷款余额',
                  formatter.format(analysis.totalLoanAmount),
                  const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildAnalysisItem(
                  '杠杆率',
                  '${analysis.leverageRatio.toStringAsFixed(2)}%',
                  analysis.leverageRatio > 70 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildAnalysisItem(
                  '增值率',
                  '${analysis.appreciationRate.toStringAsFixed(2)}%',
                  analysis.appreciationRate >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem(String label, String value, Color color) {
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final isLargeScreen = screenWidth >= 800;
          
          return Column(
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
              if (isLargeScreen) ...[
                _buildActionButtonsRow(),
              ] else ...[
                _buildActionButtonsColumn(),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButtonsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            Icons.add_business_rounded,
            '添加贷款',
            const Color(0xFF6366F1),
            () => _showAddLoanDialog(),
          ),
        ),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(
          child: _buildActionButton(
            Icons.attach_money_rounded,
            '租赁设置',
            const Color(0xFF10B981),
            () => _showRentalDialog(),
          ),
        ),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(
          child: _buildActionButton(
            Icons.price_change_rounded,
            '更新估价',
            const Color(0xFFFF9800),
            () => _showAddPriceDialog(),
          ),
        ),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(
          child: _buildActionButton(
            Icons.edit_rounded,
            '编辑',
            const Color(0xFF6366F1),
            () => _showEditDialog(),
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
    );
  }

  Widget _buildActionButtonsColumn() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                Icons.add_business_rounded,
                '添加贷款',
                const Color(0xFF6366F1),
                () => _showAddLoanDialog(),
              ),
            ),
            const SizedBox(width: AppTheme.spacingS),
            Expanded(
              child: _buildActionButton(
                Icons.attach_money_rounded,
                '租赁设置',
                const Color(0xFF10B981),
                () => _showRentalDialog(),
              ),
            ),
            const SizedBox(width: AppTheme.spacingS),
            Expanded(
              child: _buildActionButton(
                Icons.price_change_rounded,
                '更新估价',
                const Color(0xFFFF9800),
                () => _showAddPriceDialog(),
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
                () => _showEditDialog(),
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
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanCard(List<Loan> loans, NumberFormat formatter, DateFormat dateFormatter) {
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
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '贷款信息',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          if (loans.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingXL),
                child: Column(
                  children: [
                    Icon(
                      Icons.account_balance_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Text(
                      '暂无贷款信息',
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
              children: loans.map((loan) => _buildLoanItem(loan, formatter, dateFormatter)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildLoanItem(Loan loan, NumberFormat formatter, DateFormat dateFormatter) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: loan.status == 'active' 
                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  loan.displayLoanType,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: loan.status == 'active' ? const Color(0xFF10B981) : Colors.grey,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    formatter.format(loan.remainingAmount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditLoanDialog(loan);
                      } else if (value == 'delete') {
                        _showDeleteLoanConfirmation(loan);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('编辑'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('删除', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '月还款: ${formatter.format(loan.monthlyPayment)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '利率: ${(loan.loanRate * 100).toStringAsFixed(2)}%',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '期限: ${loan.loanPeriod}年',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '还款进度: ${(loan.progressRatio * 100).toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: loan.progressRatio,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalCard(List<RentalIncome> rentals, RealEstateAnalysis analysis, NumberFormat formatter, DateFormat dateFormatter) {
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
                  Icons.attach_money_rounded,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '租赁收益',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_outlined, size: 20),
                onPressed: () => _showRentalDialog(),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          if (rentals.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingXL),
                child: Column(
                  children: [
                    Icon(
                      Icons.home_work_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Text(
                      '暂无租赁信息',
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
            ...rentals.map((rental) => Container(
              margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          rental.rentalStatus,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      if (rental.tenantName != null)
                        Text(
                          rental.tenantName!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        key: ValueKey('edit_rental_${rental.id}'),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        onPressed: () => _showEditRentalDialog(rental),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        key: ValueKey('delete_rental_${rental.id}'),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        onPressed: () => _deleteRental(rental.id!),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  if (rental.rentalStatus == '出租') ...[
                    const SizedBox(height: AppTheme.spacingS),
                    Row(
                      children: [
                        Expanded(
                          child: _buildAnalysisItem(
                            '月租金',
                            formatter.format(rental.monthlyRent),
                            const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: _buildAnalysisItem(
                            '年租金',
                            formatter.format(rental.annualIncome),
                            const Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            )).toList(),
          if (rentals.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingM),
            Row(
              children: [
                Expanded(
                  child: _buildAnalysisItem(
                    '总租金收益率',
                    '${analysis.rentalYield.toStringAsFixed(2)}%',
                    const Color(0xFFFF9800),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: _buildAnalysisItem(
                    '总投资回报率',
                    '${analysis.roi.toStringAsFixed(2)}%',
                    const Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceHistoryCard(List<RealEstatePrice> prices, NumberFormat formatter, DateFormat dateFormatter) {
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
                  Icons.trending_up_rounded,
                  color: Color(0xFFFF9800),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '估价记录',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          if (prices.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingXL),
                child: Column(
                  children: [
                    Icon(
                      Icons.price_check_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Text(
                      '暂无估价记录',
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
              children: [
                RealEstatePriceTrendChart(prices: prices),
                const SizedBox(height: AppTheme.spacingM),
                ...prices.take(10).map((price) {
                return Container(
                  margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              price.source,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateFormatter.format(DateTime.fromMillisecondsSinceEpoch(price.recordDate)),
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz, size: 18, color: Colors.grey),
                        onSelected: (value) {
                          if (value == 'delete') {
                            _deletePrice(price.id!);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Text('删除', style: TextStyle(color: Colors.red, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        formatter.format(price.price),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              ],
            ),
        ],
      ),
    );
  }

  void _showAddLoanDialog() {
    if (widget.asset.id == null) return;
    showDialog(
      context: context,
      builder: (context) => RealEstateLoanDialog(
        assetId: widget.asset.id!,
        assetName: widget.asset.name,
      ),
    );
  }

  void _showEditLoanDialog(Loan loan) {
    if (widget.asset.id == null) return;
    showDialog(
      context: context,
      builder: (context) => RealEstateLoanDialog(
        assetId: widget.asset.id!,
        assetName: widget.asset.name,
        existingLoan: loan,
      ),
    );
  }

  void _showRentalDialog({RentalIncome? existingRental}) {
    if (widget.asset.id == null) return;
    showDialog(
      context: context,
      builder: (context) => RealEstateRentalDialog(
        assetId: widget.asset.id!,
        existingRental: existingRental,
      ),
    );
  }

  void _showEditRentalDialog(RentalIncome rental) {
    _showRentalDialog(existingRental: rental);
  }

  void _showAddPriceDialog() {
    if (widget.asset.id == null) return;
    showDialog(
      context: context,
      builder: (context) => RealEstatePriceHistoryDialog(assetId: widget.asset.id!),
    );
  }

  void _deleteRental(int id) {
    context.read<RentalIncomeProvider>().deleteRentalIncome(id, widget.asset.id!);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('租赁信息已删除')),
    );
  }

  void _deletePrice(int id) {
    context.read<RealEstatePriceProvider>().deletePrice(id, widget.asset.id!);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('估价记录已删除')));
    Navigator.pop(context);
  }

  void _showDeleteLoanConfirmation(Loan loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除贷款 "${loan.displayLoanType}" 吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              context.read<LoanProvider>().deleteLoan(loan.id!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('贷款已删除')));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) => RealEstateFormDialog(asset: widget.asset),
    ).then((_) {
      // Refresh data after editing
      if (mounted) {
        _loadData();
      }
    });
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个房产资产吗？关联的贷款、租赁和估价记录也将被删除。'),
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
        SnackBar(content: Text('已删除房产 "${widget.asset.name}"')),
      );
    }
  }
}
