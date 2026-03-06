import 'package:flutter/material.dart';
import '../../models/dashboard_model.dart';
import '../../theme/app_theme.dart';

class AddWidgetDialog extends StatefulWidget {
  final Function(DashboardWidget) onAdd;

  const AddWidgetDialog({super.key, required this.onAdd});

  @override
  State<AddWidgetDialog> createState() => _AddWidgetDialogState();
}

class _AddWidgetDialogState extends State<AddWidgetDialog> {
  final _titleController = TextEditingController();
  WidgetType _selectedType = WidgetType.stat;

  final List<Map<String, dynamic>> _widgetTypes = [
    {'type': WidgetType.stat, 'name': '统计卡片', 'icon': Icons.analytics},
    {'type': WidgetType.chart, 'name': '图表', 'icon': Icons.pie_chart},
    {'type': WidgetType.table, 'name': '表格', 'icon': Icons.table_chart},
    {'type': WidgetType.gauge, 'name': '仪表盘', 'icon': Icons.speed},
    {'type': WidgetType.progress, 'name': '进度条', 'icon': Icons.show_chart},
    {'type': WidgetType.kpi, 'name': 'KPI指标', 'icon': Icons.trending_up},
    {'type': WidgetType.timeline, 'name': '时间线', 'icon': Icons.timeline},
    {'type': WidgetType.heatmap, 'name': '热力图', 'icon': Icons.grid_view},
    {'type': WidgetType.calendar, 'name': '日历', 'icon': Icons.calendar_today},
    {'type': WidgetType.note, 'name': '便签', 'icon': Icons.note},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXXL),
      ),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '添加组件',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingL),
            const Text(
              '组件类型',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Wrap(
              spacing: AppTheme.spacingS,
              runSpacing: AppTheme.spacingS,
              children: _widgetTypes.map((item) {
                final isSelected = _selectedType == item['type'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = item['type'] as WidgetType;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingM,
                      vertical: AppTheme.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFF6366F1) 
                          : const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(
                        color: isSelected 
                            ? const Color(0xFF6366F1) 
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 18,
                          color: isSelected ? Colors.white : const Color(0xFF1E293B),
                        ),
                        const SizedBox(width: AppTheme.spacingXS),
                        Text(
                          item['name'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppTheme.spacingL),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '组件标题',
                hintText: '请输入组件标题',
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                const SizedBox(width: AppTheme.spacingS),
                ElevatedButton(
                  onPressed: _onSubmit,
                  child: const Text('添加'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onSubmit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入组件标题')),
      );
      return;
    }

    int defaultW = 16;
    int defaultH = 10;
    if (_selectedType == WidgetType.chart) {
      defaultW = 24;
      defaultH = 18;
    } else if (_selectedType == WidgetType.table) {
      defaultW = 36;
      defaultH = 20;
    } else if (_selectedType == WidgetType.gauge) {
      defaultW = 12;
      defaultH = 12;
    } else if (_selectedType == WidgetType.progress) {
      defaultW = 20;
      defaultH = 8;
    } else if (_selectedType == WidgetType.kpi) {
      defaultW = 12;
      defaultH = 8;
    } else if (_selectedType == WidgetType.timeline) {
      defaultW = 24;
      defaultH = 16;
    } else if (_selectedType == WidgetType.heatmap) {
      defaultW = 20;
      defaultH = 16;
    } else if (_selectedType == WidgetType.calendar) {
      defaultW = 20;
      defaultH = 24;
    } else if (_selectedType == WidgetType.note) {
      defaultW = 16;
      defaultH = 12;
    }

    final newWidget = DashboardWidget(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      type: _selectedType,
      x: 0,
      y: 0,
      w: defaultW,
      h: defaultH,
      config: _selectedType == WidgetType.chart ? {'chartType': 'pie'} : {},
    );

    widget.onAdd(newWidget);
    Navigator.pop(context);
  }
}
