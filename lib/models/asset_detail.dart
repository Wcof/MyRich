import 'dart:convert';

class AssetDetail {
  final int? id;
  final int assetId;
  final String detailType;
  final String name;
  final String data;
  final int? version;
  final int createdAt;
  final int updatedAt;

  AssetDetail({
    this.id,
    required this.assetId,
    required this.detailType,
    required this.name,
    required this.data,
    this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'asset_id': assetId,
      'detail_type': detailType,
      'name': name,
      'data': data,
      'version': version ?? 1,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory AssetDetail.fromMap(Map<String, dynamic> map) {
    return AssetDetail(
      id: map['id'] as int?,
      assetId: map['asset_id'] as int,
      detailType: map['detail_type'] as String,
      name: map['name'] as String,
      data: map['data'] as String,
      version: map['version'] as int?,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  Map<String, dynamic> get parsedData {
    try {
      return jsonDecode(data);
    } catch (_) {
      return {};
    }
  }

  AssetDetail copyWith({
    int? id,
    int? assetId,
    String? detailType,
    String? name,
    String? data,
    int? version,
    int? createdAt,
    int? updatedAt,
  }) {
    return AssetDetail(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      detailType: detailType ?? this.detailType,
      name: name ?? this.name,
      data: data ?? this.data,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
