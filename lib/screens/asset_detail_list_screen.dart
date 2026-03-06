import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/asset.dart';
import '../models/asset_detail.dart';
import '../providers/asset_detail_provider.dart';
import '../providers/asset_type_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/asset_detail_form_dialog.dart';

class AssetDetailListScreen extends StatefulWidget {
  final Asset asset;
  final VoidCallback? onBack;

  const AssetDetailListScreen({
    super.key,
    required this.asset,
    this.onBack,
  });

  @override
  State<AssetDetailListScreen> createState() => _AssetDetailListScreenState();
}

class _AssetDetailListScreenState extends State<AssetDetailListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssetDetailProvider>().loadDetails(widget.asset.id!);
    });
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

  void _showAddDetailDialog() {
    showDialog(
      context: context,
      builder: (context) => AssetDetailFormDialog(
        asset: widget.asset,
        onSave: (detail) async {
          final success = await context.read<AssetDetailProvider>().addDetail(detail);
          if (success && mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('添加成功')),
            );
          }
        },
      ),
    );
  }

  void _showEditDetailDialog(AssetDetail detail) {
    showDialog(
      context: context,
      builder: (context) => AssetDetailFormDialog(
        asset: widget.asset,
        detail: detail,
        onSave: (updatedDetail) async {
          final success = await context.read<AssetDetailProvider>().updateDetail(updatedDetail);
          if (success && mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('更新成功')),
            );
          }
        },
      ),
    );
  }

  void _showDeleteConfirmDialog(AssetDetail detail) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${detail.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final success = await context.read<AssetDetailProvider>().deleteDetail(detail.id!);
              if (mounted) {
                Navigator.of(context).pop();
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('删除成功')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assetTypeProvider = context.watch<AssetTypeProvider>();
    final assetType = assetTypeProvider.assetTypes.firstWhere(
      (type) => type.id == widget.asset.typeId,
      orElse: () => assetTypeProvider.assetTypes.first,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            leading: widget.onBack != null
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: widget.onBack,
                  )
                : null,
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.asset.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _parseColor(assetType.color ?? '#1E293B'),
                      _parseColor(assetType.color ?? '#1E293B').withOpacity(0.7),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 72, top: 40),
                  child: Row(
                    children: [
                      Icon(
                        _getAssetTypeIcon(assetType.icon ?? 'account_balance_wallet'),
                        color: Colors.white,
                        size: 32,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                onPressed: _showAddDetailDialog,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Consumer<AssetDetailProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (provider.error != null) {
                  return Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '加载失败',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        ElevatedButton(
                          onPressed: () => provider.loadDetails(widget.asset.id!),
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.details.isEmpty) {
                  return SizedBox(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          Text(
                            '还没有资产明细',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingS),
                          Text(
                            '点击右上角 + 按钮添加',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.details.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spacingM),
                  itemBuilder: (context, index) {
                    final detail = provider.details[index];
                    return _buildDetailCard(detail);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(AssetDetail detail) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () {
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Icon(
                  _getDetailIcon(detail.detailType),
                  color: const Color(0xFF1E293B),
                  size: 28,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getDetailTypeLabel(detail.detailType),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(detail.updatedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF1E293B)),
                onPressed: () => _showEditDetailDialog(detail),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _showDeleteConfirmDialog(detail),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAssetTypeIcon(String iconName) {
    switch (iconName) {
      case 'cash':
        return Icons.attach_money;
      case 'bank':
        return Icons.account_balance;
      case 'trending_up':
        return Icons.trending_up;
      case 'pie_chart':
        return Icons.pie_chart;
      case 'receipt':
        return Icons.receipt;
      case 'home':
        return Icons.home;
      case 'currency_bitcoin':
        return Icons.currency_bitcoin;
      case 'show_chart':
        return Icons.show_chart;
      case 'arrow_upward':
        return Icons.arrow_upward;
      case 'arrow_downward':
        return Icons.arrow_downward;
      default:
        return Icons.account_balance_wallet;
    }
  }

  IconData _getDetailIcon(String detailType) {
    switch (detailType) {
      case 'wallet':
        return Icons.wallet;
      case 'bank_account':
        return Icons.credit_card;
      case 'stock_position':
        return Icons.trending_up;
      case 'fund_position':
        return Icons.pie_chart;
      case 'bond_position':
        return Icons.receipt;
      case 'property':
        return Icons.home;
      default:
        return Icons.inventory;
    }
  }

  String _getDetailTypeLabel(String detailType) {
    switch (detailType) {
      case 'wallet':
        return '钱包';
      case 'bank_account':
        return '银行卡';
      case 'stock_position':
        return '股票持仓';
      case 'fund_position':
        return '基金持仓';
      case 'bond_position':
        return '债券持仓';
      case 'property':
        return '房产';
      default:
        return '未知类型';
    }
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
