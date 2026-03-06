import 'dart:convert';
import 'data_source/data_source_config.dart';

enum WidgetType {
  stat,
  chart,
  table,
  gauge,
  progress,
  kpi,
  timeline,
  heatmap,
  calendar,
  note,
}

class DashboardWidget {
  final String id;
  final String title;
  final WidgetType type;
  final int x;
  final int y;
  final int w;
  final int h;
  final Map<String, dynamic> config;
  final DataSourceConfig? dataSource;
  final List<FieldMapping>? fieldMappings;

  DashboardWidget({
    required this.id,
    required this.title,
    required this.type,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.config = const {},
    this.dataSource,
    this.fieldMappings,
  });

  DashboardWidget copyWith({
    String? id,
    String? title,
    WidgetType? type,
    int? x,
    int? y,
    int? w,
    int? h,
    Map<String, dynamic>? config,
    DataSourceConfig? dataSource,
    List<FieldMapping>? fieldMappings,
  }) {
    return DashboardWidget(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      w: w ?? this.w,
      h: h ?? this.h,
      config: config ?? this.config,
      dataSource: dataSource ?? this.dataSource,
      fieldMappings: fieldMappings ?? this.fieldMappings,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'x': x,
      'y': y,
      'w': w,
      'h': h,
      'config': jsonEncode(config),
      'dataSource': dataSource != null ? jsonEncode(dataSource!.toJson()) : null,
      'fieldMappings': fieldMappings != null
          ? jsonEncode(fieldMappings!.map((e) => e.toJson()).toList())
          : null,
    };
  }

  factory DashboardWidget.fromMap(Map<String, dynamic> map) {
    return DashboardWidget(
      id: map['id'] as String,
      title: map['title'] as String,
      type: WidgetType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => WidgetType.stat,
      ),
      x: map['x'] as int,
      y: map['y'] as int,
      w: map['w'] as int,
      h: map['h'] as int,
      config: map['config'] != null
          ? jsonDecode(map['config'] as String) as Map<String, dynamic>
          : {},
      dataSource: map['dataSource'] != null
          ? DataSourceConfig.fromJson(
              jsonDecode(map['dataSource'] as String) as Map<String, dynamic>,
            )
          : null,
      fieldMappings: map['fieldMappings'] != null
          ? (jsonDecode(map['fieldMappings'] as String) as List<dynamic>)
              .map((e) => FieldMapping.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}

class Dashboard {
  final String id;
  final String name;
  final List<DashboardWidget> widgets;
  final DateTime createdAt;
  final DateTime updatedAt;

  Dashboard({
    required this.id,
    required this.name,
    this.widgets = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Dashboard copyWith({
    String? id,
    String? name,
    List<DashboardWidget>? widgets,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Dashboard(
      id: id ?? this.id,
      name: name ?? this.name,
      widgets: widgets ?? this.widgets,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Dashboard.fromMap(Map<String, dynamic> map, List<DashboardWidget> widgets) {
    return Dashboard(
      id: map['id'] as String,
      name: map['name'] as String,
      widgets: widgets,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
