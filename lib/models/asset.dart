class Asset {
  final int? id;
  final int typeId;
  final String name;
  final String? location;
  final String? customData;
  final int createdAt;
  final int updatedAt;

  Asset({
    this.id,
    required this.typeId,
    required this.name,
    this.location,
    this.customData,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type_id': typeId,
      'name': name,
      'location': location,
      'custom_data': customData,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'] as int?,
      typeId: map['type_id'] as int,
      name: map['name'] as String,
      location: map['location'] as String?,
      customData: map['custom_data'] as String?,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  Asset copyWith({
    int? id,
    int? typeId,
    String? name,
    String? location,
    String? customData,
    int? createdAt,
    int? updatedAt,
  }) {
    return Asset(
      id: id ?? this.id,
      typeId: typeId ?? this.typeId,
      name: name ?? this.name,
      location: location ?? this.location,
      customData: customData ?? this.customData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
