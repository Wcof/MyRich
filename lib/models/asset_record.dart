class AssetRecord {
  final int? id;
  final int assetId;
  final double value;
  final double? quantity;
  final double? unitPrice;
  final String? note;
  final int recordDate;
  final int createdAt;

  AssetRecord({
    this.id,
    required this.assetId,
    required this.value,
    this.quantity,
    this.unitPrice,
    this.note,
    required this.recordDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'asset_id': assetId,
      'value': value,
      'quantity': quantity,
      'unit_price': unitPrice,
      'note': note,
      'record_date': recordDate,
      'created_at': createdAt,
    };
  }

  factory AssetRecord.fromMap(Map<String, dynamic> map) {
    return AssetRecord(
      id: map['id'] as int?,
      assetId: map['asset_id'] as int,
      value: map['value'] as double,
      quantity: map['quantity'] as double?,
      unitPrice: map['unit_price'] as double?,
      note: map['note'] as String?,
      recordDate: map['record_date'] as int,
      createdAt: map['created_at'] as int,
    );
  }

  AssetRecord copyWith({
    int? id,
    int? assetId,
    double? value,
    double? quantity,
    double? unitPrice,
    String? note,
    int? recordDate,
    int? createdAt,
  }) {
    return AssetRecord(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      value: value ?? this.value,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      note: note ?? this.note,
      recordDate: recordDate ?? this.recordDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
