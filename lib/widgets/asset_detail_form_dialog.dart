import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../models/asset_detail.dart';
import '../theme/app_theme.dart';

class AssetDetailFormDialog extends StatefulWidget {
  final Asset asset;
  final AssetDetail? detail;
  final Function(AssetDetail) onSave;

  const AssetDetailFormDialog({
    super.key,
    required this.asset,
    this.detail,
    required this.onSave,
  });

  @override
  State<AssetDetailFormDialog> createState() => _AssetDetailFormDialogState();
}

class _AssetDetailFormDialogState extends State<AssetDetailFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedDetailType;
  final _nameController = TextEditingController();
  final Map<String, TextEditingController> _fieldControllers = {};
  final List<String> _detailTypes = [
    'wallet',
    'bank_account',
    'stock_position',
    'fund_position',
    'bond_position',
    'property',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.detail != null) {
      _selectedDetailType = widget.detail!.detailType;
      _nameController.text = widget.detail!.name;
      _loadDetailData(widget.detail!.data);
    } else {
      _selectedDetailType = _detailTypes.first;
    }
  }

  void _loadDetailData(String dataJson) {
    try {
      final data = jsonDecode(dataJson);
      final fields = _getFieldsForType(_selectedDetailType);
      for (var field in fields) {
        final key = field['key'] as String;
        if (data.containsKey(key)) {
          _fieldControllers[key] = TextEditingController(
            text: data[key].toString(),
          );
        }
      }
    } catch (e) {
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var controller in _fieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _getDetailTypeLabel(String type) {
    switch (type) {
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
        return '未知';
    }
  }

  List<Map<String, dynamic>> _getFieldsForType(String type) {
    switch (type) {
      case 'wallet':
        return [
          {'key': 'wallet_name', 'label': '钱包名称', 'type': 'text', 'required': true},
          {'key': 'currency', 'label': '币种', 'type': 'select', 'required': true, 'options': ['CNY', 'USD', 'EUR']},
          {'key': 'amount', 'label': '金额', 'type': 'number', 'required': true},
          {'key': 'description', 'label': '描述', 'type': 'text', 'required': false},
        ];
      case 'bank_account':
        return [
          {'key': 'bank_name', 'label': '银行名称', 'type': 'text', 'required': true},
          {'key': 'card_number', 'label': '卡号', 'type': 'text', 'required': true},
          {'key': 'account_type', 'label': '账户类型', 'type': 'select', 'required': true, 'options': ['储蓄卡', '信用卡', '借记卡']},
          {'key': 'balance', 'label': '余额', 'type': 'number', 'required': true},
          {'key': 'currency', 'label': '币种', 'type': 'select', 'required': true, 'options': ['CNY', 'USD', 'EUR']},
          {'key': 'description', 'label': '描述', 'type': 'text', 'required': false},
        ];
      case 'stock_position':
        return [
          {'key': 'account_name', 'label': '账户名称', 'type': 'text', 'required': true},
          {'key': 'stock_code', 'label': '股票代码', 'type': 'text', 'required': true},
          {'key': 'stock_name', 'label': '股票名称', 'type': 'text', 'required': true},
          {'key': 'quantity', 'label': '持仓数量', 'type': 'number', 'required': true},
          {'key': 'purchase_price', 'label': '购买价格', 'type': 'number', 'required': true},
          {'key': 'current_price', 'label': '当前价格', 'type': 'number', 'required': true},
          {'key': 'market', 'label': '市场', 'type': 'select', 'required': false, 'options': ['NASDAQ', 'NYSE', 'SH', 'SZ', 'HK']},
          {'key': 'description', 'label': '描述', 'type': 'text', 'required': false},
        ];
      case 'fund_position':
        return [
          {'key': 'account_name', 'label': '账户名称', 'type': 'text', 'required': true},
          {'key': 'fund_code', 'label': '基金代码', 'type': 'text', 'required': true},
          {'key': 'fund_name', 'label': '基金名称', 'type': 'text', 'required': true},
          {'key': 'shares', 'label': '持仓份额', 'type': 'number', 'required': true},
          {'key': 'purchase_price', 'label': '购买价格', 'type': 'number', 'required': true},
          {'key': 'current_nav', 'label': '当前净值', 'type': 'number', 'required': true},
          {'key': 'description', 'label': '描述', 'type': 'text', 'required': false},
        ];
      case 'bond_position':
        return [
          {'key': 'bond_name', 'label': '债券名称', 'type': 'text', 'required': true},
          {'key': 'bond_code', 'label': '债券代码', 'type': 'text', 'required': true},
          {'key': 'bond_type', 'label': '债券类型', 'type': 'select', 'required': true, 'options': ['国债', '企业债', '可转债']},
          {'key': 'quantity', 'label': '持仓数量', 'type': 'number', 'required': true},
          {'key': 'face_value', 'label': '面值', 'type': 'number', 'required': true},
          {'key': 'purchase_price', 'label': '购买价格', 'type': 'number', 'required': true},
          {'key': 'current_price', 'label': '当前价格', 'type': 'number', 'required': true},
          {'key': 'maturity_date', 'label': '到期日期', 'type': 'date', 'required': false},
          {'key': 'coupon_rate', 'label': '票面利率(%)', 'type': 'number', 'required': false},
          {'key': 'description', 'label': '描述', 'type': 'text', 'required': false},
        ];
      case 'property':
        return [
          {'key': 'property_name', 'label': '房产名称', 'type': 'text', 'required': true},
          {'key': 'address', 'label': '地址', 'type': 'text', 'required': true},
          {'key': 'property_type', 'label': '房产类型', 'type': 'select', 'required': true, 'options': ['住宅', '商业', '工业']},
          {'key': 'area', 'label': '面积(m²)', 'type': 'number', 'required': true},
          {'key': 'purchase_price', 'label': '购买价格', 'type': 'number', 'required': true},
          {'key': 'current_value', 'label': '当前价值', 'type': 'number', 'required': true},
          {'key': 'purchase_date', 'label': '购买日期', 'type': 'date', 'required': false},
          {'key': 'description', 'label': '描述', 'type': 'text', 'required': false},
        ];
      default:
        return [];
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final data = <String, dynamic>{};
      final fields = _getFieldsForType(_selectedDetailType);
      for (var field in fields) {
        final key = field['key'] as String;
        final type = field['type'] as String;
        final controller = _fieldControllers[key];
        if (controller != null && controller.text.isNotEmpty) {
          if (type == 'number') {
            data[key] = num.tryParse(controller.text) ?? 0;
          } else {
            data[key] = controller.text;
          }
        }
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final detail = AssetDetail(
        id: widget.detail?.id,
        assetId: widget.asset.id!,
        detailType: _selectedDetailType,
        name: _nameController.text,
        data: jsonEncode(data),
        version: widget.detail?.version ?? 1,
        createdAt: widget.detail?.createdAt ?? now,
        updatedAt: now,
      );

      widget.onSave(detail);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingXL,
      ),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.detail != null ? '编辑资产明细' : '添加资产明细',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedDetailType,
                        decoration: const InputDecoration(
                          labelText: '明细类型',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingM,
                            vertical: AppTheme.spacingS,
                          ),
                        ),
                        items: _detailTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(_getDetailTypeLabel(type)),
                          );
                        }).toList(),
                        onChanged: widget.detail != null
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedDetailType = value!;
                                  _fieldControllers.clear();
                                });
                              },
                      ),
                      const SizedBox(height: AppTheme.spacingL),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '明细名称',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingM,
                            vertical: AppTheme.spacingS,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入明细名称';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.spacingL),
                      ..._buildFields(),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                      ),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                      ),
                      child: Text(widget.detail != null ? '保存' : '添加'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFields() {
    final fields = _getFieldsForType(_selectedDetailType);
    return fields.map((field) {
      final key = field['key'] as String;
      final label = field['label'] as String;
      final type = field['type'] as String;
      final required = field['required'] as bool;

      if (!_fieldControllers.containsKey(key)) {
        _fieldControllers[key] = TextEditingController();
      }

      Widget fieldWidget;

      if (type == 'select') {
        final options = field['options'] as List<String>;
        fieldWidget = DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS,
            ),
          ),
          value: _fieldControllers[key]?.text.isNotEmpty == true
              ? _fieldControllers[key]!.text
              : null,
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: (value) {
            _fieldControllers[key]?.text = value ?? '';
          },
          validator: required
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return '请选择$label';
                  }
                  return null;
                }
              : null,
        );
      } else if (type == 'date') {
        fieldWidget = TextFormField(
          controller: _fieldControllers[key],
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS,
            ),
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          readOnly: true,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              _fieldControllers[key]?.text =
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            }
          },
        );
      } else if (type == 'number') {
        fieldWidget = TextFormField(
          controller: _fieldControllers[key],
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS,
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: required
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入$label';
                  }
                  if (num.tryParse(value) == null) {
                    return '请输入有效的数字';
                  }
                  return null;
                }
              : null,
        );
      } else {
        fieldWidget = TextFormField(
          controller: _fieldControllers[key],
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS,
            ),
          ),
          maxLines: type == 'textarea' ? 3 : 1,
          validator: required
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入$label';
                  }
                  return null;
                }
              : null,
        );
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacingL),
        child: fieldWidget,
      );
    }).toList();
  }
}
