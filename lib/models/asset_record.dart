enum TransactionStatus {
  estimated,
  confirmed,
}

class AssetRecord {
  final int? id;
  final int assetId;
  final double value;
  final double? quantity;
  final double? unitPrice;
  final String? note;
  final int recordDate;
  final int createdAt;
  final bool isRevoked;
  final TransactionStatus status;

  AssetRecord({
    this.id,
    required this.assetId,
    required this.value,
    this.quantity,
    this.unitPrice,
    this.note,
    required this.recordDate,
    required this.createdAt,
    this.isRevoked = false,
    this.status = TransactionStatus.estimated,
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
      'is_revoked': isRevoked ? 1 : 0,
      'status': status == TransactionStatus.confirmed ? 1 : 0,
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
      isRevoked: map['is_revoked'] == 1,
      status: map['status'] == 1 ? TransactionStatus.confirmed : TransactionStatus.estimated,
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
    bool? isRevoked,
    TransactionStatus? status,
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
      isRevoked: isRevoked ?? this.isRevoked,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetRecord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          assetId == other.assetId &&
          value == other.value &&
          quantity == other.quantity &&
          unitPrice == other.unitPrice &&
          note == other.note &&
          recordDate == other.recordDate &&
          createdAt == other.createdAt &&
          isRevoked == other.isRevoked &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      assetId.hashCode ^
      value.hashCode ^
      quantity.hashCode ^
      unitPrice.hashCode ^
      note.hashCode ^
      recordDate.hashCode ^
      createdAt.hashCode ^
      isRevoked.hashCode ^
      status.hashCode;
}
