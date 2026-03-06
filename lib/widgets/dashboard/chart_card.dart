import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../theme/app_theme.dart';

class ChartCard extends StatelessWidget {
  final String title;
  final String chartType;
  final List<ChartData> data;
  final List<Color>? colors;
  final bool isEditMode;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const ChartCard({
    super.key,
    required this.title,
    required this.chartType,
    required this.data,
    this.colors,
    this.isEditMode = false,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                if (isEditMode) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: onEdit,
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingM,
                0,
                AppTheme.spacingM,
                AppTheme.spacingM,
              ),
              child: _buildChart(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final defaultColors = [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFFEF4444),
      const Color(0xFF14B8A6),
    ];
    final chartColors = colors ?? defaultColors;

    if (chartType == 'pie') {
      return SfCircularChart(
        series: <CircularSeries>[
          PieSeries<ChartData, String>(
            dataSource: data,
            xValueMapper: (ChartData data, _) => data.label,
            yValueMapper: (ChartData data, _) => data.value,
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              labelPosition: ChartDataLabelPosition.outside,
            ),
            pointColorMapper: (ChartData data, int index) => 
                chartColors[index % chartColors.length],
          ),
        ],
        legend: const Legend(
          isVisible: true,
          position: LegendPosition.bottom,
        ),
      );
    } else if (chartType == 'line') {
      return SfCartesianChart(
        series: <LineSeries<ChartData, String>>[
          LineSeries<ChartData, String>(
            dataSource: data,
            xValueMapper: (ChartData data, _) => data.label,
            yValueMapper: (ChartData data, _) => data.value,
            color: const Color(0xFF6366F1),
            width: 3,
            markerSettings: const MarkerSettings(
              isVisible: true,
              shape: DataMarkerType.circle,
              width: 6,
              height: 6,
            ),
          ),
        ],
        primaryXAxis: CategoryAxis(
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        primaryYAxis: NumericAxis(
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      );
    } else {
      return SfCartesianChart(
        series: <ColumnSeries<ChartData, String>>[
          ColumnSeries<ChartData, String>(
            dataSource: data,
            xValueMapper: (ChartData data, _) => data.label,
            yValueMapper: (ChartData data, _) => data.value,
            color: const Color(0xFF6366F1),
            width: 0.6,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
        primaryXAxis: CategoryAxis(
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        primaryYAxis: NumericAxis(
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      );
    }
  }
}

class ChartData {
  final String label;
  final double value;

  ChartData(this.label, this.value);
}
