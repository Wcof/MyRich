import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/asset.dart';
import '../models/asset_type.dart';
import '../models/loan.dart';
import '../models/rental_income.dart';
import '../providers/asset_provider.dart';
import '../providers/asset_type_provider.dart';
import '../providers/loan_provider.dart';
import '../providers/rental_income_provider.dart';
import '../services/real_estate_asset_mapper.dart';

class RealEstateFormDialog extends StatefulWidget {
  final Asset? asset;

  const RealEstateFormDialog({
    super.key,
    this.asset,
  });

  @override
  State<RealEstateFormDialog> createState() => _RealEstateFormDialogState();
}

class _RealEstateFormDialogState extends State<RealEstateFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _areaController;
  late TextEditingController _roomTypeController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _renovationCostController;
  late TextEditingController _modificationCostController;
  
  DateTime _purchaseDate = DateTime.now();
  int? _realEstateTypeId;
  bool _hasLoan = false;
  bool _isRental = false;
  
  late TextEditingController _loanTypeController;
  late TextEditingController _loanAmountController;
  late TextEditingController _loanRateController;
  late TextEditingController _loanPeriodController;
  int _repaymentMethod = 0;
  
  late TextEditingController _monthlyRentController;
  late TextEditingController _tenantController;
  String _rentalStatus = '出租';

  @override
  void initState() {
    super.initState();
    
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _areaController = TextEditingController();
    _roomTypeController = TextEditingController();
    _purchasePriceController = TextEditingController();
    _renovationCostController = TextEditingController(text: '0');
    _modificationCostController = TextEditingController(text: '0');
    
    _loanTypeController = TextEditingController(text: '商业贷款');
    _loanAmountController = TextEditingController();
    _loanRateController = TextEditingController();
    _loanPeriodController = TextEditingController();
    
    _monthlyRentController = TextEditingController();
    _tenantController = TextEditingController();
    
    if (widget.asset != null) {
      final realEstateData = RealEstateAssetMapper.extractRealEstateData(widget.asset!);
      if (realEstateData != null) {
        _nameController.text = widget.asset!.name;
        _addressController.text = realEstateData.address ?? '';
        if (realEstateData.area != null) {
          _areaController.text = realEstateData.area.toString();
        }
        _roomTypeController.text = realEstateData.roomType ?? '';
        _purchasePriceController.text = realEstateData.purchasePrice.toString();
        _renovationCostController.text = realEstateData.renovationCost.toString();
        _modificationCostController.text = realEstateData.modificationCost.toString();
        _purchaseDate = DateTime.fromMillisecondsSinceEpoch(realEstateData.purchaseDate);
      }
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRealEstateTypeId();
    });
  }

  Future<void> _loadRealEstateTypeId() async {
    final assetTypeProvider = context.read<AssetTypeProvider>();
    await assetTypeProvider.loadAssetTypes();
    
    final realEstateType = assetTypeProvider.assetTypes.firstWhere(
      (type) => type.name == '房产',
      orElse: () => AssetType(
        id: 0,
        name: '房产',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    
    if (mounted) {
      setState(() {
        _realEstateTypeId = realEstateType.id;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _roomTypeController.dispose();
    _purchasePriceController.dispose();
    _renovationCostController.dispose();
    _modificationCostController.dispose();
    _loanTypeController.dispose();
    _loanAmountController.dispose();
    _loanRateController.dispose();
    _loanPeriodController.dispose();
    _monthlyRentController.dispose();
    _tenantController.dispose();
    super.dispose();
  }

  Future<void> _selectPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(1970),
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

    final now = DateTime.now();
    final realEstateData = RealEstateData(
      address: _addressController.text.isEmpty ? null : _addressController.text,
      area: _areaController.text.isEmpty ? null : double.tryParse(_areaController.text),
      roomType: _roomTypeController.text.isEmpty ? null : _roomTypeController.text,
      purchaseDate: _purchaseDate.millisecondsSinceEpoch,
      purchasePrice: double.parse(_purchasePriceController.text),
      renovationCost: double.tryParse(_renovationCostController.text) ?? 0,
      modificationCost: double.tryParse(_modificationCostController.text) ?? 0,
      lastUpdateAt: now.millisecondsSinceEpoch,
    );

    final asset = Asset(
      id: widget.asset?.id,
      typeId: _realEstateTypeId ?? 0,
      name: _nameController.text,
      location: _addressController.text.isEmpty ? null : _addressController.text,
      customData: json.encode(realEstateData.toJson()),
      createdAt: widget.asset?.createdAt ?? now.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
    );

    final assetProvider = context.read<AssetProvider>();
    
    int? assetId;
    if (widget.asset != null) {
      await assetProvider.updateAsset(asset);
      assetId = widget.asset!.id;
    } else {
      assetId = await assetProvider.addAsset(asset);
    }

    if (!mounted) return;

    if (assetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存房产失败')),
      );
      return;
    }

    if (_hasLoan && _loanAmountController.text.isNotEmpty) {
      final loanAmount = double.tryParse(_loanAmountController.text);
      final loanRate = double.tryParse(_loanRateController.text);
      final loanPeriod = int.tryParse(_loanPeriodController.text);
      
      if (loanAmount != null && loanRate != null && loanPeriod != null) {
        final rateFraction = loanRate / 100;
        final dueDate = _purchaseDate.add(Duration(days: loanPeriod * 365));
        final monthlyRate = rateFraction / 12;
        final totalMonths = loanPeriod * 12;
        double monthlyPayment;
        if (_repaymentMethod == 0) {
          // 等额本息
          final factor = math.pow(1 + monthlyRate, totalMonths);
          monthlyPayment = loanAmount * monthlyRate * factor / (factor - 1);
        } else {
          // 等额本金 (首月)
          monthlyPayment = loanAmount / totalMonths + loanAmount * monthlyRate;
        }

        final loan = Loan(
          assetId: assetId,
          loanType: _loanTypeController.text,
          loanAmount: loanAmount,
          loanRate: rateFraction,
          loanPeriod: loanPeriod,
          repaymentMethod: _repaymentMethod == 0 ? '等额本息' : '等额本金',
          loanDate: _purchaseDate.millisecondsSinceEpoch,
          dueDate: dueDate.millisecondsSinceEpoch,
          remainingAmount: loanAmount,
          monthlyPayment: monthlyPayment,
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        );

        if (mounted) {
          await context.read<LoanProvider>().addLoan(loan);
        }
      }
    }

    if (!mounted) return;

    if (_isRental && _monthlyRentController.text.isNotEmpty) {
      final monthlyRent = double.tryParse(_monthlyRentController.text);
      if (monthlyRent != null) {
        final rentalIncome = RentalIncome(
          assetId: assetId,
          rentalStatus: _rentalStatus,
          monthlyRent: monthlyRent,
          rentalStartDate: now.millisecondsSinceEpoch,
          tenantName: _tenantController.text.isEmpty ? null : _tenantController.text,
          annualIncome: monthlyRent * 12,
          createdAt: now.millisecondsSinceEpoch,
          updatedAt: now.millisecondsSinceEpoch,
        );

        await context.read<RentalIncomeProvider>().addRentalIncome(rentalIncome);
      }
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.asset != null ? '房产已更新' : '房产已添加')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('yyyy-MM-dd');
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF795548), Color(0xFF5D4037)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
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
                    Text(
                      widget.asset != null ? '编辑房产' : '添加房产',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
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
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '房产名称 *',
                          hintText: '如: 北京朝阳区公寓',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入房产名称';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: '详细地址',
                          hintText: '房产详细地址',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _areaController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: '建筑面积',
                                suffixText: '㎡',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _roomTypeController,
                              decoration: const InputDecoration(
                                labelText: '房型',
                                hintText: '如: 3室2厅',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _selectPurchaseDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: '购置日期',
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(dateFormatter.format(_purchaseDate)),
                              const Icon(Icons.calendar_today, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '价值信息',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _purchasePriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: '购置价格 *',
                          suffixText: '元',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入购置价格';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _renovationCostController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: '装修投入',
                                suffixText: '元',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _modificationCostController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: '改造投入',
                                suffixText: '元',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      CheckboxListTile(
                        title: const Text('有贷款'),
                        value: _hasLoan,
                        onChanged: (value) {
                          setState(() {
                            _hasLoan = value ?? false;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_hasLoan) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _loanTypeController,
                          decoration: const InputDecoration(
                            labelText: '贷款类型',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _loanAmountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: '贷款金额',
                                  suffixText: '元',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _loanRateController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: '年利率',
                                  suffixText: '%',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _loanPeriodController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: '贷款期限',
                                  suffixText: '年',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: _repaymentMethod,
                                decoration: const InputDecoration(
                                  labelText: '还款方式',
                                ),
                                items: const [
                                  DropdownMenuItem(value: 0, child: Text('等额本息')),
                                  DropdownMenuItem(value: 1, child: Text('等额本金')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _repaymentMethod = value ?? 0;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        title: const Text('已出租'),
                        value: _isRental,
                        onChanged: (value) {
                          setState(() {
                            _isRental = value ?? false;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_isRental) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _rentalStatus,
                          decoration: const InputDecoration(
                            labelText: '租赁状态',
                          ),
                          items: const [
                            DropdownMenuItem(value: '出租', child: Text('出租')),
                            DropdownMenuItem(value: '自住', child: Text('自住')),
                            DropdownMenuItem(value: '空置', child: Text('空置')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _rentalStatus = value ?? '出租';
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _monthlyRentController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: '月租金',
                            suffixText: '元',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _tenantController,
                          decoration: const InputDecoration(
                            labelText: '租户名称（可选）',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF795548),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(widget.asset != null ? '更新' : '添加'),
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
