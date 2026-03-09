import 'package:flutter/material.dart';
import '../../models/dashboard_model.dart';
import '../../models/data_source/data_source_config.dart';
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
  WidgetType? _selectedType;
  late String _chartType;
  DataSourceType? _selectedDataSourceType;

  final List<Map<String, dynamic>> _dataSources = [
    {
      'type': DataSourceType.singleAsset,
      'name': '单个资产',
      'icon': Icons.account_balance_wallet,
      'description': '显示单个资产的详细信息',
    },
    {
      'type': DataSourceType.assetTypeAggregation,
      'name': '资产类型聚合',
      'icon': Icons.category,
      'description': '按资产类型聚合统计',
    },
    {
      'type': DataSourceType.multipleAssets,
      'name': '多个资产',
      'icon': Icons.list,
      'description': '显示多个资产的对比信息',
    },
    {
      'type': DataSourceType.assetRecordTimeSeries,
      'name': '时间序列',
      'icon': Icons.timeline,
      'description': '显示资产的历史趋势',
    },
    {
      'type': DataSourceType.customMetric,
      'name': '自定义指标',
      'icon': Icons.calculate,
      'description': '自定义计算指标',
    },
  ];

  List<Map<String, dynamic>> _getAvailableWidgetTypes() {
    if (_selectedDataSourceType == null) {
      return [];
    }

    switch (_selectedDataSourceType!) {
      case DataSourceType.singleAsset:
        return [
          {'type': WidgetType.stat, 'name': '统计卡片', 'icon': Icons.analytics},
          {'type': WidgetType.gauge, 'name': '仪表盘', 'icon': Icons.speed},
          {'type': WidgetType.kpi, 'name': 'KPI指标', 'icon': Icons.trending_up},
        ];
      case DataSourceType.assetTypeAggregation:
        return [
          {'type': WidgetType.chart, 'name': '图表', 'icon': Icons.pie_chart},
          {'type': WidgetType.stat, 'name': '统计卡片', 'icon': Icons.analytics},
          {'type': WidgetType.table, 'name': '表格', 'icon': Icons.table_chart},
        ];
      case DataSourceType.multipleAssets:
        return [
          {'type': WidgetType.table, 'name': '表格', 'icon': Icons.table_chart},
          {'type': WidgetType.chart, 'name': '图表', 'icon': Icons.pie_chart},
          {'type': WidgetType.heatmap, 'name': '热力图', 'icon': Icons.grid_view},
        ];
      case DataSourceType.assetRecordTimeSeries:
        return [
          {'type': WidgetType.chart, 'name': '图表', 'icon': Icons.pie_chart},
          {'type': WidgetType.timeline, 'name': '时间线', 'icon': Icons.timeline},
          {'type': WidgetType.stat, 'name': '统计卡片', 'icon': Icons.analytics},
        ];
      case DataSourceType.customMetric:
        return [
          {'type': WidgetType.kpi, 'name': 'KPI指标', 'icon': Icons.trending_up},
          {'type': WidgetType.progress, 'name': '进度条', 'icon': Icons.show_chart},
          {'type': WidgetType.gauge, 'name': '仪表盘', 'icon': Icons.speed},
        ];
    }
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.widget.title);
    _selectedType = widget.widget.type;
    _chartType = widget.widget.config['chartType'] as String? ?? 'pie';
    _selectedDataSourceType = widget.widget.dataSource?.type;
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
        width: 480,
        constraints: const BoxConstraints(maxHeight: 600),
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
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDataSourceSection(),
                    if (_selectedDataSourceType != null) ...[
                      const SizedBox(height: AppTheme.spacingL),
                      _buildWidgetTypeSection(),
                    ],
                    if (_selectedType != null) ...[
                      const SizedBox(height: AppTheme.spacingL),
                      _buildTitleSection(),
                      if (_selectedType == WidgetType.chart) ...[
                        const SizedBox(height: AppTheme.spacingL),
                        _buildChartTypeSection(),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSourceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '数据源',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        ..._dataSources.map((source) {
          final isSelected = _selectedDataSourceType == source['type'];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDataSourceType = source['type'] as DataSourceType;
                  _selectedType = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6366F1).withValues(alpha: 0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF6366F1)
                        : const Color(0xFFE5E7EB),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      source['icon'] as IconData,
                      size: 24,
                      color: isSelected
                          ? const Color(0xFF6366F1)
                          : const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            source['name'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? const Color(0xFF6366F1)
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            source['description'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF6366F1),
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildWidgetTypeSection() {
    final availableTypes = _getAvailableWidgetTypes();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          children: availableTypes.map((item) {
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
      ],
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '组件标题',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: '请输入组件标题',
            hintText: '例如：总资产、基金占比等',
          ),
        ),
      ],
    );
  }

  Widget _buildChartTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        const SizedBox(width: AppTheme.spacingS),
        ElevatedButton(
          onPressed: _selectedType != null ? _onSave : null,
          child: const Text('保存'),
        ),
      ],
    );
  }

  void _onSave() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入组件标题')),
      );
      return;
    }

    DataSourceConfig? dataSource;
    if (_selectedDataSourceType != null) {
      dataSource = DataSourceConfig(
        id: widget.widget.dataSource?.id ?? 
            DateTime.now().millisecondsSinceEpoch.toString(),
        type: _selectedDataSourceType!,
        params: widget.widget.dataSource?.params ?? {},
        label: _dataSources
            .firstWhere((s) => s['type'] == _selectedDataSourceType)['name'] as String,
      );
    }

    final updatedWidget = widget.widget.copyWith(
      title: title,
      type: _selectedType,
      config: _selectedType == WidgetType.chart 
          ? {'chartType': _chartType} 
          : widget.widget.config,
      dataSource: dataSource,
    );

    widget.onSave(updatedWidget);
    Navigator.pop(context);
  }
}
