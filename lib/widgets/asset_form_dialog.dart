import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/asset.dart';
import '../providers/asset_provider.dart';
import '../providers/asset_type_provider.dart';
import '../widgets/asset_type_form_dialog.dart';

class AssetFormDialog extends StatefulWidget {
  final Asset? asset;

  const AssetFormDialog({
    super.key,
    this.asset,
  });

  @override
  State<AssetFormDialog> createState() => _AssetFormDialogState();
}

class _AssetFormDialogState extends State<AssetFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _valueController;
  late TextEditingController _locationController;
  late TextEditingController _noteController;
  int? _selectedTypeId;
  DateTime _selectedDate = DateTime.now();

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
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.asset?.name ?? '');
    _valueController = TextEditingController(
      text: widget.asset != null ? _getAssetValue().toString() : '',
    );
    _locationController = TextEditingController(text: widget.asset?.location ?? '');
    _noteController = TextEditingController(text: '');
    _selectedTypeId = widget.asset?.typeId;
    if (widget.asset != null) {
      _selectedDate = DateTime.fromMillisecondsSinceEpoch(widget.asset!.createdAt);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    _locationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double _getAssetValue() {
    if (widget.asset?.customData != null) {
      try {
        final data = Map<String, dynamic>.from(
          // ignore: avoid_dynamic_calls
          widget.asset!.customData as Map,
        );
        return (data['value'] as num?)?.toDouble() ?? 0.0;
      } catch (_) {
        return 0.0;
      }
    }
    return 0.0;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择资产类型')),
      );
      return;
    }

    final value = double.tryParse(_valueController.text);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的资产价值')),
      );
      return;
    }

    final now = DateTime.now();
    final customData = {
      'value': value,
      'note': _noteController.text.trim(),
    };

    final asset = Asset(
      id: widget.asset?.id,
      typeId: _selectedTypeId!,
      name: _nameController.text.trim(),
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      customData: jsonEncode(customData),
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
          SnackBar(
            content: Text(widget.asset?.id != null ? '资产已更新' : '资产已添加'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.asset?.id != null ? '编辑资产' : '添加资产'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '资产名称',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入资产名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Consumer<AssetTypeProvider>(
                builder: (context, assetTypeProvider, child) {
                  final assetTypes = assetTypeProvider.assetTypes;
                  
                  if (assetTypes.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('暂无资产类型，请先创建资产类型'),
                      ),
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedTypeId,
                          decoration: const InputDecoration(
                            labelText: '资产类型',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: assetTypes.map((type) {
                            return DropdownMenuItem<int>(
                              value: type.id,
                              child: Row(
                                children: [
                                  if (type.color != null)
                                    Container(
                                      width: 12,
                                      height: 12,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: _parseColor(type.color!),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  Text(type.name),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedTypeId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return '请选择资产类型';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add),
                          tooltip: '添加自定义类型',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => const AssetTypeFormDialog(),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(
                  labelText: '资产价值',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  suffixText: '¥',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入资产价值';
                  }
                  final numValue = double.tryParse(value);
                  if (numValue == null || numValue <= 0) {
                    return '请输入有效的资产价值';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: '位置 (可选)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '创建日期',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('yyyy-MM-dd').format(_selectedDate),
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
                maxLines: 3,
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
          onPressed: _submitForm,
          child: Text(widget.asset?.id != null ? '更新' : '添加'),
        ),
      ],
    );
  }
}
