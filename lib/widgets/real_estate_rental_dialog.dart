import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/rental_income.dart';
import '../providers/rental_income_provider.dart';
import '../theme/app_theme.dart';

class RealEstateRentalDialog extends StatefulWidget {
  final int assetId;
  final RentalIncome? existingRental;

  const RealEstateRentalDialog({
    super.key,
    required this.assetId,
    this.existingRental,
  });

  @override
  State<RealEstateRentalDialog> createState() => _RealEstateRentalDialogState();
}

class _RealEstateRentalDialogState extends State<RealEstateRentalDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _rentController;
  late TextEditingController _tenantController;
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _rentController = TextEditingController(
      text: widget.existingRental?.monthlyRent.toString() ?? '',
    );
    _tenantController = TextEditingController(
      text: widget.existingRental?.tenantName ?? '',
    );
    _selectedStatus = widget.existingRental?.rentalStatus ?? '出租';
  }

  @override
  void dispose() {
    _rentController.dispose();
    _tenantController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final rent = double.tryParse(_rentController.text) ?? 0.0;
      final now = DateTime.now().millisecondsSinceEpoch;

      final rental = RentalIncome(
        id: widget.existingRental?.id,
        assetId: widget.assetId,
        rentalStatus: _selectedStatus,
        monthlyRent: rent,
        rentalStartDate: widget.existingRental?.rentalStartDate ?? now,
        tenantName: _tenantController.text.isEmpty ? null : _tenantController.text,
        annualIncome: rent * 12,
        status: widget.existingRental?.status ?? 'active',
        createdAt: widget.existingRental?.createdAt ?? now,
        updatedAt: now,
      );

      final provider = context.read<RentalIncomeProvider>();
      if (widget.existingRental != null) {
        provider.updateRentalIncome(rental);
      } else {
        provider.addRentalIncome(rental);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingRental != null ? '编辑租赁' : '添加租赁'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusL)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: '租赁状态'),
                items: const [
                  DropdownMenuItem(value: '出租', child: Text('出租')),
                  DropdownMenuItem(value: '自住', child: Text('自住')),
                  DropdownMenuItem(value: '空置', child: Text('空置')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value ?? '出租';
                  });
                },
              ),
              if (_selectedStatus == '出租') ...[
                const SizedBox(height: AppTheme.spacingM),
                TextFormField(
                  controller: _rentController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '月租金',
                    suffixText: '元',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return '请输入月租金';
                    if (double.tryParse(value) == null) return '请输入有效数字';
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingM),
                TextFormField(
                  controller: _tenantController,
                  decoration: const InputDecoration(
                    labelText: '租户名称',
                    hintText: '可选',
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
        ElevatedButton(
          onPressed: _submit,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
