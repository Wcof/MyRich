import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/asset_type.dart';
import '../providers/asset_type_provider.dart';

class AssetTypeFormDialog extends StatefulWidget {
  const AssetTypeFormDialog({super.key});

  @override
  State<AssetTypeFormDialog> createState() => _AssetTypeFormDialogState();
}

class _AssetTypeFormDialogState extends State<AssetTypeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String _selectedColor = '#6366F1';

  final List<String> _colors = [
    '#6366F1', // Indigo
    '#10B981', // Emerald
    '#F59E0B', // Amber
    '#EF4444', // Red
    '#8B5CF6', // Purple
    '#06B6D4', // Cyan
    '#EC4899', // Pink
    '#1E40AF', // Blue
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) {
    var c = hex.replaceAll('#', '');
    if (c.length == 6) c = 'FF$c';
    return Color(int.parse(c, radix: 16));
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    final newType = AssetType(
      name: _nameController.text.trim(),
      color: _selectedColor,
      isSystem: false,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    
    await context.read<AssetTypeProvider>().addAssetType(newType);
    
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加自定义资产类型'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              maxLines: 1,
              decoration: const InputDecoration(
                labelText: '类型名称',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return '请输入类型名称';
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text('选择颜色', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((colorHex) {
                final color = _parseColor(colorHex);
                final isSelected = _selectedColor == colorHex;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = colorHex;
                    });
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.black45, width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          child: const Text('添加'),
        ),
      ],
    );
  }
}
