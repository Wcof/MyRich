class DashboardConfig {
  final int? id;
  final String name;
  final String layout;
  final bool isDefault;
  final int createdAt;
  final int updatedAt;

  DashboardConfig({
    this.id,
    required this.name,
    required this.layout,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'layout': layout,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory DashboardConfig.fromMap(Map<String, dynamic> map) {
    return DashboardConfig(
      id: map['id'] as int?,
      name: map['name'] as String,
      layout: map['layout'] as String,
      isDefault: (map['is_default'] as int?) == 1,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  DashboardConfig copyWith({
    int? id,
    String? name,
    String? layout,
    bool? isDefault,
    int? createdAt,
    int? updatedAt,
  }) {
    return DashboardConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      layout: layout ?? this.layout,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
