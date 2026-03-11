import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/asset.dart';
import '../models/asset_type.dart';
import '../providers/asset_provider.dart';
import '../providers/asset_type_provider.dart';
import '../services/fund_api_service.dart';
import '../services/fund_asset_mapper.dart';

class FundFormDialog extends StatefulWidget {
  final Asset? asset;

  const FundFormDialog({
    super.key,
    this.asset,
  });

  @override
  State<FundFormDialog> createState() => _FundFormDialogState();
}

class _FundFormDialogState extends State<FundFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fundCodeController;
  late TextEditingController _fundNameController;
  late TextEditingController _noteController;
  
  DateTime _purchaseDate = DateTime.now();
  bool _isLoading = false;
  bool _isAutoFilled = false;
  int? _fundTypeId;

  @override
  void initState() {
    super.initState();
    
    _fundCodeController = TextEditingController();
    _fundNameController = TextEditingController();
    _noteController = TextEditingController();
    
    if (widget.asset != null) {
      final fundData = FundAssetMapper.extractFundData(widget.asset!);
      if (fundData != null) {
        _fundCodeController.text = fundData.fundCode;
        _fundNameController.text = fundData.fundName;
        _isAutoFilled = true;
      }
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFundTypeId();
    });
  }

  Future<void> _loadFundTypeId() async {
    final assetTypeProvider = context.read<AssetTypeProvider>();
    await assetTypeProvider.loadAssetTypes();
    
    final fundType = assetTypeProvider.assetTypes.firstWhere(
      (type) => type.name == '基金',
      orElse: () => AssetType(
        id: 0,
        name: '基金',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    
    if (mounted) {
      setState(() {
        _fundTypeId = fundType.id;
      });
    }
  }

  @override
  void dispose() {
    _fundCodeController.dispose();
    _fundNameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchFundInfo() async {
    final fundCode = _fundCodeController.text.trim();
    if (fundCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入基金代码')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = context.read<FundApiService>();
      final quote = await apiService.fetchQuote(fundCode);
      
      if (mounted) {
        if (quote != null) {
          setState(() {
            _fundNameController.text = quote.fundName;
            _isAutoFilled = true;
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已获取基金信息: ${quote.fundName}')),
          );
        } else {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('未找到该基金信息，请检查基金代码是否正确')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取基金信息失败: $e')),
        );
      }
    }
  }

  Future<void> _selectPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _purchaseDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_fundTypeId == null || _fundTypeId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未找到基金类型，请先在系统中添加"基金"资产类型')),
      );
      return;
    }

    final fundCode = _fundCodeController.text.trim();
    final fundName = _fundNameController.text.trim();

    final now = DateTime.now();
    final fundData = FundData(
      fundCode: fundCode,
      fundName: fundName.isEmpty ? '基金 $fundCode' : fundName,
      quantity: 0,
      purchasePrice: 0,
      currentPrice: 0,
      purchaseDate: now.millisecondsSinceEpoch,
      lastUpdateAt: now.millisecondsSinceEpoch,
    );

    final asset = Asset(
      id: widget.asset?.id,
      typeId: _fundTypeId!,
      name: fundData.fundName,
      location: null,
      customData: jsonEncode(fundData.toJson()),
      createdAt: widget.asset?.createdAt ?? now.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
    );

    try {
      if (widget.asset?.id != null) {
        await context.read<AssetProvider>().updateAsset(asset);
      } else {
        await context.read<AssetProvider>().addAsset(asset);
      }
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.asset?.id != null ? '基金已更新' : '基金已添加，请在详情页点击"买入"进行首次买入')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.pie_chart_rounded,
              color: Color(0xFFFF9800),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(widget.asset?.id != null ? '编辑基金' : '添加基金'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFE0B2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '输入基金代码后点击查询，系统将自动获取基金名称和最新净值',
                        style: TextStyle(fontSize: 12, color: Colors.orange[900]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _fundCodeController,
                      maxLines: 1,
                      decoration: const InputDecoration(
                        labelText: '基金代码 *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.code),
                        hintText: '如: 000001',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入基金代码';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _fetchFundInfo,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      label: Text(_isLoading ? '查询中' : '查询'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9800),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fundNameController,
                maxLines: 1,
                decoration: InputDecoration(
                  labelText: '基金名称',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.label),
                  suffixIcon: _isAutoFilled
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                ),
                enabled: false,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectPurchaseDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '买入日期',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('yyyy-MM-dd').format(_purchaseDate),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: '备注 (可选)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
              if (_fundCodeController.text.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFE0B2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '添加基金后，请在详情页点击"买入"按钮进行首次买入操作',
                          style: TextStyle(fontSize: 12, color: Colors.orange[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton.icon(
          onPressed: _submitForm,
          icon: const Icon(Icons.save),
          label: Text(widget.asset?.id != null ? '更新' : '添加'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF9800),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
