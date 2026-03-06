enum DataSourceType {
  singleAsset,
  assetTypeAggregation,
  multipleAssets,
  assetRecordTimeSeries,
  customMetric,
}

class DataSourceConfig {
  final String id;
  final DataSourceType type;
  final Map<String, dynamic> params;
  final String? label;

  DataSourceConfig({
    required this.id,
    required this.type,
    required this.params,
    this.label,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'params': params,
      'label': label,
    };
  }

  factory DataSourceConfig.fromJson(Map<String, dynamic> json) {
    return DataSourceConfig(
      id: json['id'] as String,
      type: DataSourceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DataSourceType.singleAsset,
      ),
      params: json['params'] as Map<String, dynamic>,
      label: json['label'] as String?,
    );
  }

  DataSourceConfig copyWith({
    String? id,
    DataSourceType? type,
    Map<String, dynamic>? params,
    String? label,
  }) {
    return DataSourceConfig(
      id: id ?? this.id,
      type: type ?? this.type,
      params: params ?? this.params,
      label: label ?? this.label,
    );
  }
}

class FieldMapping {
  final String sourceField;
  final String displayField;
  final String? format;
  final String? unit;

  FieldMapping({
    required this.sourceField,
    required this.displayField,
    this.format,
    this.unit,
  });

  Map<String, dynamic> toJson() {
    return {
      'sourceField': sourceField,
      'displayField': displayField,
      'format': format,
      'unit': unit,
    };
  }

  factory FieldMapping.fromJson(Map<String, dynamic> json) {
    return FieldMapping(
      sourceField: json['sourceField'] as String,
      displayField: json['displayField'] as String,
      format: json['format'] as String?,
      unit: json['unit'] as String?,
    );
  }

  FieldMapping copyWith({
    String? sourceField,
    String? displayField,
    String? format,
    String? unit,
  }) {
    return FieldMapping(
      sourceField: sourceField ?? this.sourceField,
      displayField: displayField ?? this.displayField,
      format: format ?? this.format,
      unit: unit ?? this.unit,
    );
  }
}
