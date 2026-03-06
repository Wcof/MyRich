import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/asset_provider.dart';
import '../providers/asset_type_provider.dart';
import '../providers/asset_record_provider.dart';
import '../models/asset.dart';
import '../models/asset_type.dart';
import '../models/asset_record.dart';
import '../widgets/asset_form_dialog.dart';
import '../widgets/asset_type_form_dialog.dart';
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

  double _getAssetValue(Asset asset) {
    if (asset.customData != null) {
      try {
        final data = Map<String, dynamic>.from(
          asset.customData as Map,
        );
        return (data['value'] as num?)?.toDouble() ?? 0.0;
      } catch (_) {
        return 0.0;
      }
    }
    return 0.0;
  }

  String _getAssetTypeName(Asset asset, List<AssetType> assetTypes) {
    final assetType = assetTypes.firstWhere(
      (type) => type.id == asset.typeId,
      orElse: () => AssetType(
        id: asset.typeId,
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

  Color _getAssetTypeColor(Asset asset, List<AssetType> assetTypes) {
    final assetType = assetTypes.firstWhere(
      (type) => type.id == asset.typeId,
      orElse: () => AssetType(
        id: asset.typeId,
        name: '未知类型',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    
    if (assetType.color != null) {
      return _parseColor(assetType.color!);
    }
    return const Color(0xFF1E293B);
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
              child: Consumer2<AssetProvider, AssetTypeProvider>(
                builder: (context, assetProvider, assetTypeProvider, child) {
                  return _buildStatsSection(assetProvider, assetTypeProvider);
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
          Consumer3<AssetProvider, AssetTypeProvider, AssetRecordProvider>(
            builder: (context, assetProvider, assetTypeProvider, recordProvider, child) {
              final assets = _filterAssets(assetProvider.assets);
              final assetTypes = assetTypeProvider.assetTypes;
              final records = recordProvider.records;

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

              return SliverPadding(
                padding: const EdgeInsets.only(bottom: 100),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppTheme.spacingM,
                    crossAxisSpacing: AppTheme.spacingM,
                    childAspectRatio: 1.3,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final asset = assets[index];
                      return _buildAssetCard(asset, assetTypes, records);
                    },
                    childCount: assets.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AssetFormDialog(),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('添加资产'),
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

  Widget _buildStatsSection(AssetProvider assetProvider, AssetTypeProvider assetTypeProvider) {
    final assets = assetProvider.assets;
    final assetTypes = assetTypeProvider.assetTypes;
    
    double totalValue = 0;
    for (final asset in assets) {
      totalValue += _getAssetValue(asset);
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

  Widget _buildAssetCard(Asset asset, List<AssetType> assetTypes, List<AssetRecord> records) {
    final value = _getAssetValue(asset);
    final typeName = _getAssetTypeName(asset, assetTypes);
    final typeColor = _getAssetTypeColor(asset, assetTypes);
    final formatter = NumberFormat.currency(
      locale: 'zh_CN',
      symbol: '¥',
      decimalDigits: 2,
    );
    final dateFormatter = DateFormat('yyyy-MM-dd');
    
    final assetRecords = records.where((r) => r.assetId == asset.id).toList();
    double change = 0;
    double changePercent = 0;
    bool hasChange = false;
    
    if (assetRecords.length >= 2) {
      final sortedRecords = List<AssetRecord>.from(assetRecords)
        ..sort((a, b) => a.recordDate.compareTo(b.recordDate));
      final first = sortedRecords.first.value;
      final last = sortedRecords.last.value;
      change = last - first;
      if (first != 0) {
        changePercent = (change / first) * 100;
      }
      hasChange = true;
    }
    final isPositive = change >= 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: InkWell(
        onTap: () {
          if (widget.onAssetTap != null) {
            widget.onAssetTap!(asset);
          } else {
            Navigator.pushNamed(
              context,
              '/asset_detail',
              arguments: asset,
            );
          }
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(
              color: const Color(0xFFE8ECF4),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      typeColor.withValues(alpha: 0.1),
                      typeColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusL),
                    topRight: Radius.circular(AppTheme.radiusL),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: typeColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            asset.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            typeName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatter.format(value),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        if (hasChange)
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
                                  size: 12,
                                  color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (asset.location != null) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              SizedBox(
                                width: 100,
                                child: Text(
                                  asset.location!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingS,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B).withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          ),
                          child: Text(
                            dateFormatter.format(
                              DateTime.fromMillisecondsSinceEpoch(asset.createdAt),
                            ),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF1E293B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
