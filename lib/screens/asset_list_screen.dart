import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/asset_provider.dart';
import '../providers/asset_type_provider.dart';
import '../providers/asset_record_provider.dart';
import '../providers/real_estate_price_provider.dart';
import '../services/fund_asset_mapper.dart';
import '../services/real_estate_asset_mapper.dart';
import '../models/asset.dart';
import '../models/asset_type.dart';
import '../widgets/asset_form_dialog.dart';
import '../widgets/fund_form_dialog.dart';
import '../widgets/real_estate_form_dialog.dart';
import '../theme/app_theme.dart';

class AssetListScreen extends StatefulWidget {
  final Function(Asset)? onAssetTap;

  const AssetListScreen({super.key, this.onAssetTap});

  @override
  State<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends State<AssetListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final FocusNode _typeFocusNode = FocusNode();
  int? _selectedTypeId;
  String _searchQuery = '';
  bool _isEditTypeMode = false;
  bool _isAddingType = false;

  @override
  void dispose() {
    _searchController.dispose();
    _typeController.dispose();
    _typeFocusNode.dispose();
    super.dispose();
  }

  List<Asset> _filterAssets(List<Asset> assets) {
    List<Asset> filtered = assets;

    if (_selectedTypeId != null) {
      filtered = filtered.where((asset) => asset.typeId == _selectedTypeId).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((asset) => 
        asset.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (asset.location?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }

    return filtered;
  }

  double _getAssetValue(Asset asset, [RealEstatePriceProvider? priceProvider]) {
    final fundData = FundAssetMapper.extractFundData(asset);
    if (fundData != null) {
      return fundData.currentValue;
    }
    
    final realEstateData = RealEstateAssetMapper.extractRealEstateData(asset);
    if (realEstateData != null) {
      if (priceProvider != null && asset.id != null) {
        final prices = priceProvider.getPricesByAssetId(asset.id!);
        if (prices.isNotEmpty) {
          return prices.first.price;
        }
      }
      return realEstateData.purchasePrice;
    }
    
    return FundAssetMapper.getFundValue(asset);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Consumer3<AssetProvider, AssetTypeProvider, RealEstatePriceProvider>(
                builder: (context, assetProvider, assetTypeProvider, priceProvider, child) {
                  return _buildStatsSection(assetProvider, assetTypeProvider, priceProvider);
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
              child: _buildSearchBar(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: _buildFilterChips(),
            ),
          ),
          Consumer4<AssetProvider, AssetTypeProvider, AssetRecordProvider, RealEstatePriceProvider>(
            builder: (context, assetProvider, assetTypeProvider, recordProvider, priceProvider, child) {
              final assets = _filterAssets(assetProvider.assets);
              final assetTypes = assetTypeProvider.assetTypes;

              if (assetProvider.isLoading) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (assets.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyState(),
                );
              }

              final groupedAssets = _groupAssetsByType(assets, assetTypes);
              
              return SliverPadding(
                padding: const EdgeInsets.only(bottom: 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = groupedAssets.entries.elementAt(index);
                      return _buildAssetTypeGroup(
                        entry.key,
                        entry.value,
                        assetTypes,
                        recordProvider.records,
                        priceProvider,
                      );
                    },
                    childCount: groupedAssets.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAssetDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('添加资产'),
      ),
    );
  }

  void _showAddAssetDialog() async {
    final assetTypeProvider = context.read<AssetTypeProvider>();
    await assetTypeProvider.loadAssetTypes();
    
    if (!mounted) return;
    
    final assetTypes = assetTypeProvider.assetTypes;
    
    if (assetTypes.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => const AssetFormDialog(),
      );
      return;
    }
    
    final selectedType = await showDialog<AssetType>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                      Icons.add_circle_outline_rounded,
                      color: Color(0xFF6366F1),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '选择资产类型',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '请选择要添加的资产类型',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: assetTypes.length,
                  itemBuilder: (context, index) {
                    final type = assetTypes[index];
                    Color typeColor = const Color(0xFF1E293B);
                    if (type.color != null) {
                      try {
                        String color = type.color!;
                        if (color.startsWith('#')) {
                          color = color.substring(1);
                          if (color.length == 6) {
                            color = 'FF$color';
                          }
                        }
                        typeColor = Color(int.parse(color, radix: 16));
                      } catch (_) {}
                    }
                    
                    return InkWell(
                      onTap: () => Navigator.pop(context, type),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: typeColor.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getTypeIcon(type.name),
                              color: typeColor,
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              type.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: typeColor,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      '取消',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    
    if (selectedType != null && mounted) {
      if (selectedType.name == '基金') {
        showDialog(
          context: context,
          builder: (context) => const FundFormDialog(),
        );
      } else if (selectedType.name == '房产') {
        showDialog(
          context: context,
          builder: (context) => const RealEstateFormDialog(),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AssetFormDialog(
            initialTypeId: selectedType.id,
          ),
        );
      }
    }
  }

  IconData _getTypeIcon(String typeName) {
    switch (typeName) {
      case '现金':
        return Icons.payments_rounded;
      case '银行存款':
        return Icons.account_balance_rounded;
      case '股票':
        return Icons.trending_up_rounded;
      case '基金':
        return Icons.pie_chart_rounded;
      case '债券':
        return Icons.receipt_long_rounded;
      case '房产':
        return Icons.home_rounded;
      case '加密货币':
        return Icons.currency_bitcoin_rounded;
      case '期货':
        return Icons.show_chart_rounded;
      case '借款':
        return Icons.arrow_upward_rounded;
      case '贷款':
        return Icons.arrow_downward_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  Map<String, List<Asset>> _groupAssetsByType(List<Asset> assets, List<AssetType> assetTypes) {
    final Map<String, List<Asset>> grouped = {};
    
    for (final asset in assets) {
      final assetType = assetTypes.firstWhere(
        (type) => type.id == asset.typeId,
        orElse: () => AssetType(
          id: asset.typeId,
          name: '未知类型',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      
      final typeName = assetType.name;
      if (!grouped.containsKey(typeName)) {
        grouped[typeName] = [];
      }
      grouped[typeName]!.add(asset);
    }
    
    return grouped;
  }

  Widget _buildAssetTypeGroup(
    String typeName,
    List<Asset> assets,
    List<AssetType> assetTypes,
    List<dynamic> records,
    RealEstatePriceProvider priceProvider,
  ) {
    final assetType = assetTypes.firstWhere(
      (type) => type.name == typeName,
      orElse: () => AssetType(
        id: 0,
        name: typeName,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    
    Color typeColor = const Color(0xFF1E293B);
    if (assetType.color != null) {
      try {
        String color = assetType.color!;
        if (color.startsWith('#')) {
          color = color.substring(1);
          if (color.length == 6) {
            color = 'FF$color';
          }
        }
        typeColor = Color(int.parse(color, radix: 16));
      } catch (_) {}
    }
    
    double totalValue = 0;
    for (final asset in assets) {
      totalValue += _getAssetValue(asset, priceProvider);
    }
    
    final formatter = NumberFormat.currency(
      locale: 'zh_CN',
      symbol: '¥',
      decimalDigits: 2,
    );

    return Container(
      margin: const EdgeInsets.only(
        left: AppTheme.spacingM,
        right: AppTheme.spacingM,
        bottom: AppTheme.spacingM,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: typeColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusXL),
                topRight: Radius.circular(AppTheme.radiusXL),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTypeIcon(typeName),
                    color: typeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        typeName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: typeColor,
                        ),
                      ),
                      Text(
                        '${assets.length} 个资产',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatter.format(totalValue),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: typeColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                int crossAxisCount;
                
                if (screenWidth < 600) {
                  crossAxisCount = 2;
                } else if (screenWidth < 900) {
                  crossAxisCount = 3;
                } else if (screenWidth < 1200) {
                  crossAxisCount = 4;
                } else {
                  crossAxisCount = 5;
                }
                
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: assets.length,
                  itemBuilder: (context, index) {
                    final asset = assets[index];
                    return _buildAssetMiniCard(asset, typeColor, formatter, priceProvider);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetMiniCard(Asset asset, Color typeColor, NumberFormat formatter, RealEstatePriceProvider priceProvider) {
    final value = _getAssetValue(asset, priceProvider);
    final fundData = FundAssetMapper.extractFundData(asset);
    
    return GestureDetector(
      onTap: () {
        if (widget.onAssetTap != null) {
          widget.onAssetTap!(asset);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: typeColor.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: typeColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    asset.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (fundData != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      fundData.fundCode,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: typeColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  formatter.format(value),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: typeColor,
                  ),
                ),
                if (fundData != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '${fundData.quantity.toStringAsFixed(2)}份',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索资产名称或位置',
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF6B7280),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingS,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildStatsSection(AssetProvider assetProvider, AssetTypeProvider assetTypeProvider, RealEstatePriceProvider priceProvider) {
    final assets = assetProvider.assets;
    final assetTypes = assetTypeProvider.assetTypes;
    
    double totalValue = 0;
    for (final asset in assets) {
      totalValue += _getAssetValue(asset, priceProvider);
    }
    
    final formatter = NumberFormat.currency(
      locale: 'zh_CN',
      symbol: '¥',
      decimalDigits: 2,
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '总资产',
                formatter.format(totalValue),
                Icons.account_balance_wallet_rounded,
                const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: _buildStatCard(
                '资产数量',
                '${assets.length}',
                Icons.inventory_2_rounded,
                const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '资产类型',
                '${assetTypes.length}',
                Icons.category_rounded,
                const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: _buildStatCard(
                '平均价值',
                assets.isEmpty ? '¥0.00' : formatter.format(totalValue / assets.length),
                Icons.trending_up_rounded,
                const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingS),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Consumer<AssetTypeProvider>(
      builder: (context, assetTypeProvider, child) {
        final assetTypes = assetTypeProvider.assetTypes;
        
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                '全部',
                _selectedTypeId == null,
                () => setState(() => _selectedTypeId = null),
                const Color(0xFF6366F1),
              ),
              const SizedBox(width: AppTheme.spacingS),
              ...assetTypes.map((type) {
                Color chipColor = const Color(0xFF1E293B);
                if (type.color != null) {
                  chipColor = _parseColor(type.color!);
                }
                return Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spacingS),
                  child: _buildFilterChip(
                    type.name,
                    _selectedTypeId == type.id,
                    () {
                      if (_isEditTypeMode && !type.isSystem) {
                        _showDeleteTypeConfirmDialog(type);
                      } else {
                        setState(() => _selectedTypeId = type.id);
                      }
                    },
                    chipColor,
                    showDelete: _isEditTypeMode && !type.isSystem,
                  ),
                );
              }),
              if (!_isEditTypeMode)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: _buildActionButton('编辑分类', Icons.edit_rounded, () {
                    setState(() {
                      _isEditTypeMode = true;
                    });
                  }),
                )
              else ...[
                if (_isAddingType)
                  Container(
                    width: 130,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      border: Border.all(color: const Color(0xFF6366F1), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: TextField(
                        controller: _typeController,
                        focusNode: _typeFocusNode,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isCollapsed: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                          hintText: '输入名称 + 回车',
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submitNewType(),
                      ),
                    ),
                  )
                else
                  _buildActionButton('添加新分类', Icons.add_rounded, () {
                    setState(() {
                      _isAddingType = true;
                    });
                    _typeFocusNode.requestFocus();
                  }, isPrimary: true),
                const SizedBox(width: AppTheme.spacingS),
                _buildActionButton('完成', Icons.check_rounded, () {
                  setState(() {
                    _isEditTypeMode = false;
                    _isAddingType = false;
                    _typeController.clear();
                  });
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, Color color, {bool showDelete = false}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.animationFast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE8ECF4),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
            if (showDelete) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFEF4444).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 12,
                  color: isSelected ? Colors.white : const Color(0xFFEF4444),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap, {bool isPrimary = false, bool isDestructive = false}) {
    Color foregroundColor = isDestructive 
        ? const Color(0xFFEF4444) 
        : (isPrimary ? const Color(0xFF6366F1) : const Color(0xFF64748B));
    Color backgroundColor = isDestructive 
        ? const Color(0xFFEF4444).withValues(alpha: 0.1) 
        : (isPrimary ? const Color(0xFF6366F1).withValues(alpha: 0.1) : const Color(0xFFF1F5F9));
    Color borderColor = isDestructive 
        ? const Color(0xFFEF4444).withValues(alpha: 0.2) 
        : (isPrimary ? const Color(0xFF6366F1).withValues(alpha: 0.2) : const Color(0xFFE2E8F0));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: foregroundColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: foregroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitNewType() async {
    final text = _typeController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _isAddingType = false;
      });
      return;
    }
    
    final newType = AssetType(
      name: text,
      color: '#6366F1',
      isSystem: false,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    
    await context.read<AssetTypeProvider>().addAssetType(newType);
    
    if (mounted) {
      setState(() {
        _typeController.clear();
        _isAddingType = false;
      });
    }
  }

  void _showDeleteTypeConfirmDialog(AssetType type) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除资产分类 "${type.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              if (type.id != null) {
                await context.read<AssetTypeProvider>().deleteAssetType(type.id!);
                if (mounted && _selectedTypeId == type.id) {
                  setState(() => _selectedTypeId = null);
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.inbox_rounded,
                size: 64,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              _searchQuery.isNotEmpty || _selectedTypeId != null
                  ? '没有找到匹配的资产'
                  : '暂无资产',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              '点击右下角按钮添加新资产',
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
}
