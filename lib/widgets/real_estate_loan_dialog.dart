import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/loan.dart';
import '../models/asset.dart';
import '../models/asset_detail.dart';
import '../models/asset_type.dart';
import '../providers/loan_provider.dart';
import '../providers/asset_provider.dart';
import '../providers/asset_type_provider.dart';
import '../providers/asset_detail_provider.dart';
import '../theme/app_theme.dart';

class RealEstateLoanDialog extends StatefulWidget {
  final int assetId;
  final String? assetName;
  final Loan? existingLoan;

  const RealEstateLoanDialog({
    super.key,
    required this.assetId,
    this.assetName,
    this.existingLoan,
  });

  @override
  State<RealEstateLoanDialog> createState() => _RealEstateLoanDialogState();
}

class _RealEstateLoanDialogState extends State<RealEstateLoanDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedLoanType;
  final _customLoanTypeController = TextEditingController();
  final _amountController = TextEditingController();
  final _rateController = TextEditingController();
  final _periodController = TextEditingController();
  late int _selectedRepaymentMethod;
  int? _selectedReceivingBankAccountId;
  int? _selectedPaymentBankAccountId;
  List<AssetDetail> _bankAccounts = [];

  @override
  void initState() {
    super.initState();
    _selectedLoanType = widget.existingLoan?.loanType ?? Loan.presetLoanTypes.first;
    _customLoanTypeController.text = widget.existingLoan?.customLoanType ?? '';
    _amountController.text = widget.existingLoan?.loanAmount.toString() ?? '';
    _rateController.text = widget.existingLoan == null ? '' : (widget.existingLoan!.loanRate * 100).toString();
    _periodController.text = widget.existingLoan?.loanPeriod.toString() ?? '';
    _selectedRepaymentMethod = widget.existingLoan?.repaymentMethod == '等额本金' ? 1 : 0;
    _selectedReceivingBankAccountId = widget.existingLoan?.receivingBankAccountId;
    _selectedPaymentBankAccountId = widget.existingLoan?.paymentBankAccountId;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBankAccounts();
    });
  }

  void _loadBankAccounts() async {
    final provider = context.read<AssetDetailProvider>();
    await provider.loadDetailsByType(widget.assetId, 'bank_account');
    final accounts = provider.details.where((d) => d.detailType == 'bank_account').toList();
    setState(() {
      _bankAccounts = accounts;
    });
  }

  @override
  void dispose() {
    _customLoanTypeController.dispose();
    _amountController.dispose();
    _rateController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final rate = (double.tryParse(_rateController.text) ?? 0.0) / 100;
      final period = int.tryParse(_periodController.text) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final dueDate = DateTime.now().add(Duration(days: period * 365)).millisecondsSinceEpoch;

      final loan = Loan(
        id: widget.existingLoan?.id,
        assetId: widget.assetId,
        loanType: _selectedLoanType,
        customLoanType: _selectedLoanType == '其他' ? _customLoanTypeController.text : null,
        loanAmount: amount,
        loanRate: rate,
        loanPeriod: period,
        loanDate: widget.existingLoan?.loanDate ?? now,
        dueDate: widget.existingLoan?.dueDate ?? dueDate,
        repaymentMethod: _selectedRepaymentMethod == 0 ? '等额本息' : '等额本金',
        monthlyPayment: _calculateMonthlyPayment(amount, rate, period, _selectedRepaymentMethod),
        remainingAmount: widget.existingLoan?.remainingAmount ?? amount,
        status: widget.existingLoan?.status ?? 'active',
        receivingBankAccountId: _selectedReceivingBankAccountId,
        paymentBankAccountId: _selectedPaymentBankAccountId,
        relatedAssetId: widget.assetId,
        createdAt: widget.existingLoan?.createdAt ?? now,
        updatedAt: now,
      );

      final provider = context.read<LoanProvider>();
      if (widget.existingLoan != null) {
        provider.updateLoan(loan);
      } else {
        provider.addLoan(loan);
      }

      Navigator.pop(context);
    }
  }

  Future<void> _createLoanAsset(Loan loan) async {
    try {
      final assetProvider = context.read<AssetProvider>();
      final assetTypeProvider = context.read<AssetTypeProvider>();
      
      final loanAssetType = assetTypeProvider.assetTypes.firstWhere(
        (type) => type.name == '贷款',
        orElse: () => throw Exception('贷款类型不存在'),
      );

      final loanAssetName = '${loan.displayLoanType} - ${_amountController.text}元';
      
      final customData = jsonEncode({
        'loan_id': loan.id,
        'loan_type': loan.loanType,
        'custom_loan_type': loan.customLoanType,
        'loan_amount': loan.loanAmount,
        'loan_rate': loan.loanRate,
        'loan_period': loan.loanPeriod,
        'remaining_amount': loan.remainingAmount,
        'monthly_payment': loan.monthlyPayment,
        'receiving_bank_account_id': loan.receivingBankAccountId,
        'payment_bank_account_id': loan.paymentBankAccountId,
        'related_asset_id': widget.assetId,
      });

      final loanAsset = Asset(
        typeId: loanAssetType.id!,
        name: loanAssetName,
        customData: customData,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await assetProvider.addAsset(loanAsset);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('贷款资产已自动创建')),
        );
      }
    } catch (e) {
      print('创建贷款资产失败: $e');
    }
  }

  double _calculateMonthlyPayment(double principal, double annualRate, int years, int method) {
    if (principal <= 0 || annualRate <= 0 || years <= 0) return 0;
    final monthlyRate = annualRate / 12;
    final months = years * 12;
    
    if (method == 0) {
      return (principal * monthlyRate * (1 + monthlyRate).toDouble().pow(months)) / 
             ((1 + monthlyRate).toDouble().pow(months) - 1);
    } else {
      return (principal / months) + (principal * monthlyRate);
    }
  }

  String _getBankAccountName(AssetDetail detail) {
    try {
      final data = detail.parsedData;
      final bankName = data['bank_name'] ?? '';
      final cardNumber = data['card_number'] ?? '';
      final maskedNumber = cardNumber.length > 4 ? '****${cardNumber.substring(cardNumber.length - 4)}' : cardNumber;
      return '$bankName ($maskedNumber)';
    } catch (e) {
      return detail.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingLoan != null ? '编辑贷款' : '添加贷款'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusL)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedLoanType,
                decoration: const InputDecoration(
                  labelText: '贷款类型',
                  border: OutlineInputBorder(),
                ),
                items: Loan.presetLoanTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLoanType = value ?? Loan.presetLoanTypes.first;
                  });
                },
              ),
              if (_selectedLoanType == '其他') ...[
                const SizedBox(height: AppTheme.spacingM),
                TextFormField(
                  controller: _customLoanTypeController,
                  decoration: const InputDecoration(
                    labelText: '自定义贷款类型',
                    hintText: '请输入贷款类型',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_selectedLoanType == '其他' && (value == null || value.isEmpty)) {
                      return '请输入贷款类型';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: AppTheme.spacingM),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '贷款金额',
                  suffixText: '元',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? '请输入金额' : null,
              ),
              const SizedBox(height: AppTheme.spacingM),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _rateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: '年利率',
                        suffixText: '%',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty ? '请输入利率' : null,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: TextFormField(
                      controller: _periodController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '期限',
                        suffixText: '年',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty ? '请输入期限' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              DropdownButtonFormField<int>(
                value: _selectedRepaymentMethod,
                decoration: const InputDecoration(
                  labelText: '还款方式',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('等额本息')),
                  DropdownMenuItem(value: 1, child: Text('等额本金')),
                ],
                onChanged: (value) => setState(() => _selectedRepaymentMethod = value ?? 0),
              ),
              const SizedBox(height: AppTheme.spacingL),
              const Text(
                '银行卡关联（可选）',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              DropdownButtonFormField<int?>(
                value: _selectedReceivingBankAccountId,
                decoration: const InputDecoration(
                  labelText: '收款银行卡',
                  border: OutlineInputBorder(),
                  helperText: '贷款放款的银行卡',
                ),
                hint: const Text('不关联'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('不关联'),
                  ),
                  ..._bankAccounts.map((account) {
                    return DropdownMenuItem<int?>(
                      value: account.id,
                      child: Text(_getBankAccountName(account)),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedReceivingBankAccountId = value;
                  });
                },
              ),
              const SizedBox(height: AppTheme.spacingM),
              DropdownButtonFormField<int?>(
                value: _selectedPaymentBankAccountId,
                decoration: const InputDecoration(
                  labelText: '还款银行卡',
                  border: OutlineInputBorder(),
                  helperText: '每月扣款的银行卡',
                ),
                hint: const Text('不关联'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('不关联'),
                  ),
                  ..._bankAccounts.map((account) {
                    return DropdownMenuItem<int?>(
                      value: account.id,
                      child: Text(_getBankAccountName(account)),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentBankAccountId = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('保存'),
        ),
      ],
    );
  }
}

extension on double {
  double pow(int n) {
    double result = 1.0;
    for (int i = 0; i < n; i++) {
      result *= this;
    }
    return result;
  }
}
