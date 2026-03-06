import 'package:flutter/material.dart';
import '../../models/dashboard_model.dart';
import '../../theme/app_theme.dart';

class WidgetConfigDialog extends StatefulWidget {
  final DashboardWidget widget;
  final Function(DashboardWidget) onSave;

  const WidgetConfigDialog({
    super.key,
    required this.widget,
    required this.onSave,
  });

  @override
  State<WidgetConfigDialog> createState() => _WidgetConfigDialogState();
}

class _WidgetConfigDialogState extends State<WidgetConfigDialog> {
  late TextEditingController _titleController;
  late WidgetType _selectedType;
  late String _chartType;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.widget.title);
    _selectedType = widget.widget.type;
    _chartType = widget.widget.config['chartType'] as String? ?? 'pie';
  }

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
                  '组件配置',
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
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '组件标题',
                hintText: '请输入组件标题',
              ),
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
              children: WidgetType.values.map((type) {
                final isSelected = _selectedType == type;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = type;
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
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIconForType(type),
                          size: 18,
                          color: isSelected ? Colors.white : const Color(0xFF1E293B),
                        ),
                        const SizedBox(width: AppTheme.spacingXS),
                        Text(
                          _getNameForType(type),
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
            if (_selectedType == WidgetType.chart) ...[
              const SizedBox(height: AppTheme.spacingL),
              const Text(
                '图表类型',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Row(
                children: [
                  _buildChartTypeOption('pie', '饼图'),
                  const SizedBox(width: AppTheme.spacingS),
                  _buildChartTypeOption('line', '折线图'),
                  const SizedBox(width: AppTheme.spacingS),
                  _buildChartTypeOption('bar', '柱状图'),
                ],
              ),
            ],
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
                  onPressed: _onSave,
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartTypeOption(String type, String label) {
    final isSelected = _chartType == type;
    return GestureDetector(
      onTap: () => setState(() => _chartType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(WidgetType type) {
    switch (type) {
      case WidgetType.stat:
        return Icons.analytics;
      case WidgetType.chart:
        return Icons.pie_chart;
      case WidgetType.table:
        return Icons.table_chart;
      case WidgetType.gauge:
        return Icons.speed;
      case WidgetType.progress:
        return Icons.show_chart;
      case WidgetType.kpi:
        return Icons.trending_up;
      case WidgetType.timeline:
        return Icons.timeline;
      case WidgetType.heatmap:
        return Icons.grid_view;
      case WidgetType.calendar:
        return Icons.calendar_today;
      case WidgetType.note:
        return Icons.note;
    }
  }

  String _getNameForType(WidgetType type) {
    switch (type) {
      case WidgetType.stat:
        return '统计';
      case WidgetType.chart:
        return '图表';
      case WidgetType.table:
        return '表格';
      case WidgetType.gauge:
        return '仪表';
      case WidgetType.progress:
        return '进度条';
      case WidgetType.kpi:
        return 'KPI';
      case WidgetType.timeline:
        return '时间线';
      case WidgetType.heatmap:
        return '热力图';
      case WidgetType.calendar:
        return '日历';
      case WidgetType.note:
        return '便签';
    }
  }

  void _onSave() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入组件标题')),
      );
      return;
    }

    final updatedWidget = widget.widget.copyWith(
      title: title,
      type: _selectedType,
      config: _selectedType == WidgetType.chart 
          ? {'chartType': _chartType} 
          : widget.widget.config,
    );

    widget.onSave(updatedWidget);
    Navigator.pop(context);
  }
}
