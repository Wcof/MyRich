class RealEstatePrice {
  final int? id;
  final int assetId;
  final double price;
  final String source;
  final int recordDate;
  final int createdAt;

  RealEstatePrice({
    this.id,
    required this.assetId,
    required this.price,
    required this.source,
    required this.recordDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'asset_id': assetId,
      'price': price,
      'source': source,
      'record_date': recordDate,
      'created_at': createdAt,
    };
  }

  factory RealEstatePrice.fromMap(Map<String, dynamic> map) {
    return RealEstatePrice(
      id: map['id'] as int?,
      assetId: map['asset_id'] as int,
      price: (map['price'] as num).toDouble(),
      source: map['source'] as String,
      recordDate: map['record_date'] as int,
      createdAt: map['created_at'] as int,
    );
  }

  RealEstatePrice copyWith({
    int? id,
    int? assetId,
    double? price,
    String? source,
    int? recordDate,
    int? createdAt,
  }) {
    return RealEstatePrice(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      price: price ?? this.price,
      source: source ?? this.source,
      recordDate: recordDate ?? this.recordDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RealEstatePrice &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
