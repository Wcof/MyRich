import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/real_estate_price.dart';
import '../providers/real_estate_price_provider.dart';
import '../theme/app_theme.dart';

class RealEstatePriceHistoryDialog extends StatefulWidget {
  final int assetId;

  const RealEstatePriceHistoryDialog({
    super.key,
    required this.assetId,
  });

  @override
  State<RealEstatePriceHistoryDialog> createState() => _RealEstatePriceHistoryDialogState();
}

class _RealEstatePriceHistoryDialogState extends State<RealEstatePriceHistoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _priceController;
  late TextEditingController _sourceController;
  String _selectedSource = '链家';

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController();
    _sourceController = TextEditingController();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final price = double.tryParse(_priceController.text) ?? 0.0;
      final now = DateTime.now().millisecondsSinceEpoch;

      final realEstatePrice = RealEstatePrice(
        assetId: widget.assetId,
        price: price,
        source: _selectedSource == '自定义'
            ? (_sourceController.text.isEmpty ? '自定义' : _sourceController.text)
            : _selectedSource,
        recordDate: now,
        createdAt: now,
      );

      context.read<RealEstatePriceProvider>().addPrice(realEstatePrice);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('更新估价'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusL)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedSource,
                decoration: const InputDecoration(labelText: '估价来源'),
                items: const [
                  DropdownMenuItem(value: '链家', child: Text('链家')),
                  DropdownMenuItem(value: '贝壳', child: Text('贝壳')),
                  DropdownMenuItem(value: '安居客', child: Text('安居客')),
                  DropdownMenuItem(value: '专业评估', child: Text('专业评估')),
                  DropdownMenuItem(value: '自定义', child: Text('自定义')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSource = value ?? '链家';
                  });
                },
              ),
              if (_selectedSource == '自定义') ...[
                const SizedBox(height: AppTheme.spacingM),
                TextFormField(
                  controller: _sourceController,
                  decoration: const InputDecoration(labelText: '来源名称'),
                  validator: (value) => value == null || value.isEmpty ? '请输入来源名称' : null,
                ),
              ],
              const SizedBox(height: AppTheme.spacingM),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '估价金额',
                  suffixText: '元',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return '请输入金额';
                  if (double.tryParse(value) == null) return '请输入有效数字';
                  return null;
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
