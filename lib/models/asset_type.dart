class AssetType {
  final int? id;
  final String name;
  final String? icon;
  final String? color;
  final String? fieldsSchema;
  final bool isSystem;
  final int createdAt;
  final int updatedAt;

  AssetType({
    this.id,
    required this.name,
    this.icon,
    this.color,
    this.fieldsSchema,
    this.isSystem = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'is_system': isSystem ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory AssetType.fromMap(Map<String, dynamic> map) {
    return AssetType(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      fieldsSchema: map['fields_schema'] as String?,
      isSystem: (map['is_system'] as int?) == 1,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  AssetType copyWith({
    int? id,
    String? name,
    String? icon,
    String? color,
    String? fieldsSchema,
    bool? isSystem,
    int? createdAt,
    int? updatedAt,
  }) {
    return AssetType(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      fieldsSchema: fieldsSchema ?? this.fieldsSchema,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
