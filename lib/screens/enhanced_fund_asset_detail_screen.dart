import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/asset.dart';
import '../models/asset_record.dart';
import '../models/fund_portfolio.dart';
import '../models/stock_data.dart';
import '../providers/asset_provider.dart';
import '../providers/asset_record_provider.dart';
import '../providers/fund_sync_provider.dart';
import '../services/fund_asset_mapper.dart';
import '../services/akshare_api_service.dart';
import '../widgets/fund_form_dialog.dart';
import '../theme/app_theme.dart';

class EnhancedFundAssetDetailScreen extends StatefulWidget {
  final Asset asset;
  final VoidCallback? onBack;

  const EnhancedFundAssetDetailScreen({
    super.key,
    required this.asset,
    this.onBack,
  });

  @override
  State<EnhancedFundAssetDetailScreen> createState() => _EnhancedFundAssetDetailScreenState();
}

class _EnhancedFundAssetDetailScreenState extends State<EnhancedFundAssetDetailScreen> {
  final AkshareApiService _akshareApi = AkshareApiService();
  FundPortfolio? _portfolio;
  Map<String, StockData> _stockPrices = {};
  bool _isLoadingPortfolio = false;
  String _fundType = FundType.unknown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.asset.id != null) {
        context.read<AssetRecordProvider>().loadRecordsByAsset(widget.asset.id!);
      }
      _loadFundData();
    });
  }

  Future<void> _loadFundData() async {
    final fundData = FundAssetMapper.extractFundData(widget.asset);
    if (fundData == null) return;

    setState(() {
      _fundType = FundType.determineType(fundData.fundCode);
      _isLoadingPortfolio = true;
    });

    try {
      FundPortfolio? portfolio;
      
      if (_fundType == FundType.etf) {
        portfolio = await _akshareApi.getETFPortfolio(fundData.fundCode);
      } else {
        portfolio = await _akshareApi.getFundPortfolio(fundData.fundCode);
      }

      if (portfolio != null && mounted) {
        setState(() {
          _portfolio = portfolio;
        });

        await _loadStockPrices();
      }
    } catch (e) {
      print('加载基金数据失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPortfolio = false;
        });
      }
    }
  }

  Future<void> _loadStockPrices() async {
    if (_portfolio == null || _portfolio!.holdings.isEmpty) return;

    final stockCodes = _portfolio!.holdings
        .map((h) => h.stockCode)
        .toList();

    try {
      final stocks = await _akshareApi.getBatchStockRealtime(stockCodes);
      
      if (mounted) {
        setState(() {
          for (final stock in stocks) {
            _stockPrices[stock.stockCode] = stock;
          }
        });
      }
    } catch (e) {
      print('加载股票价格失败: $e');
    }
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
                      if (_fundType == FundType.etf)
                        _buildETFCalculator(fundData, formatter)
                      else
                        _buildPortfolioCard(formatter),
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
                            Row(
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
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _fundType == FundType.etf ? 'ETF' : '基金',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
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
                      fundSyncProvider.isRunning
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      fundSyncProvider.isRunning ? '停止' : '自动',
                      const Color(0xFF10B981),
                      () {
                        if (fundSyncProvider.isRunning) {
                          fundSyncProvider.stopAutoSync();
                        } else {
                          fundSyncProvider.startAutoSync();
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingS),
              Row(
                children: [
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

  Widget _buildETFCalculator(FundData? fundData, NumberFormat formatter) {
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
                  Icons.calculate_rounded,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'ETF实时净值计算',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          if (_isLoadingPortfolio)
            const Center(child: CircularProgressIndicator())
          else if (_portfolio != null)
            Column(
              children: [
                Text(
                  '基于持仓股票实时价格计算的ETF净值',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  '功能开发中...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            )
          else
            Center(
              child: Text(
                '暂无持仓数据',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPortfolioCard(NumberFormat formatter) {
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
                  Icons.account_tree_rounded,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '持仓股票',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          if (_isLoadingPortfolio)
            const Center(child: CircularProgressIndicator())
          else if (_portfolio != null && _portfolio!.holdings.isNotEmpty)
            Column(
              children: _portfolio!.holdings.take(10).map((holding) {
                final stockPrice = _stockPrices[holding.stockCode];
                return _buildHoldingItem(holding, stockPrice, formatter);
              }).toList(),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingXL),
                child: Column(
                  children: [
                    Icon(
                      Icons.pie_chart_outline_rounded,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Text(
                      '暂无持仓数据',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHoldingItem(StockHolding holding, StockData? stockPrice, NumberFormat formatter) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holding.stockName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  holding.stockCode,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                stockPrice != null 
                    ? formatter.format(stockPrice.currentPrice)
                    : '--',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                '${(holding.proportion * 100).toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
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
                  dateFormatter.format(DateTime.fromMillisecondsSinceEpoch(record.recordDate)),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (record.quantity != null) ...[
                      Text(
                        '${record.note}',
                        style: TextStyle(
                          fontSize: 12,
                          color: record.note == '买入' ? Colors.green[600] : Colors.red[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${record.quantity!.toStringAsFixed(2)}份',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      formatter.format(record.value),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF9800),
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
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '¥${record.unitPrice!.toStringAsFixed(4)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Text(
            formatter.format(record.value),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFF9800),
            ),
          ),
        ],
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
    final priceController = TextEditingController(
      text: fundData.currentPrice > 0 
          ? fundData.currentPrice.toStringAsFixed(4) 
          : '',
    );
    double calculatedQuantity = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('买入基金'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '基金: ${fundData.fundName}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
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
                    final price = double.tryParse(priceController.text) ?? 0;
                    setState(() {
                      calculatedQuantity = price > 0 ? amount / price : 0;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '买入净值',
                    hintText: '请输入买入净值',
                    suffixText: '元/份',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final amount = double.tryParse(amountController.text) ?? 0;
                    final price = double.tryParse(value) ?? 0;
                    setState(() {
                      calculatedQuantity = price > 0 ? amount / price : 0;
                    });
                  },
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text);
                  final price = double.tryParse(priceController.text);

                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请输入有效的买入金额')),
                    );
                    return;
                  }

                  if (price == null || price <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请输入有效的买入净值')),
                    );
                    return;
                  }

                  final quantity = amount / price;
                  _handleBuy(quantity, price, amount);
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
    final priceController = TextEditingController(
      text: fundData.currentPrice > 0 
          ? fundData.currentPrice.toStringAsFixed(4) 
          : '',
    );
    double calculatedAmount = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('卖出基金'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '基金: ${fundData.fundName}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '当前持有: ${fundData.quantity.toStringAsFixed(2)} 份',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
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
                    final price = double.tryParse(priceController.text) ?? 0;
                    setState(() {
                      calculatedAmount = quantity * price;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '卖出净值',
                    hintText: '请输入卖出净值',
                    suffixText: '元/份',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final quantity = double.tryParse(quantityController.text) ?? 0;
                    final price = double.tryParse(value) ?? 0;
                    setState(() {
                      calculatedAmount = quantity * price;
                    });
                  },
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
                          '卖出金额:',
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  final quantity = double.tryParse(quantityController.text);
                  final price = double.tryParse(priceController.text);

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

                  if (price == null || price <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请输入有效的卖出净值')),
                    );
                    return;
                  }

                  final amount = quantity * price;
                  _handleSell(quantity, price, amount);
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

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除基金 "${widget.asset.name}" 吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (widget.asset.id != null) {
                context.read<AssetProvider>().deleteAsset(widget.asset.id!);
                Navigator.pop(context);
                if (widget.onBack != null) {
                  widget.onBack!();
                } else {
                  Navigator.pop(context);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已删除基金 "${widget.asset.name}"')),
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
