class RentalIncome {
  final int? id;
  final int assetId;
  final String rentalStatus;
  final double monthlyRent;
  final int rentalStartDate;
  final int? rentalEndDate;
  final String? tenantName;
  final double annualIncome;
  final String status;
  final int createdAt;
  final int updatedAt;

  RentalIncome({
    this.id,
    required this.assetId,
    required this.rentalStatus,
    required this.monthlyRent,
    required this.rentalStartDate,
    this.rentalEndDate,
    this.tenantName,
    required this.annualIncome,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'asset_id': assetId,
      'rental_status': rentalStatus,
      'monthly_rent': monthlyRent,
      'rental_start_date': rentalStartDate,
      'rental_end_date': rentalEndDate,
      'tenant_name': tenantName,
      'annual_income': annualIncome,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory RentalIncome.fromMap(Map<String, dynamic> map) {
    return RentalIncome(
      id: map['id'] as int?,
      assetId: map['asset_id'] as int,
      rentalStatus: map['rental_status'] as String,
      monthlyRent: (map['monthly_rent'] as num).toDouble(),
      rentalStartDate: map['rental_start_date'] as int,
      rentalEndDate: map['rental_end_date'] as int?,
      tenantName: map['tenant_name'] as String?,
      annualIncome: (map['annual_income'] as num).toDouble(),
      status: map['status'] as String? ?? 'active',
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  RentalIncome copyWith({
    int? id,
    int? assetId,
    String? rentalStatus,
    double? monthlyRent,
    int? rentalStartDate,
    int? rentalEndDate,
    String? tenantName,
    double? annualIncome,
    String? status,
    int? createdAt,
    int? updatedAt,
  }) {
    return RentalIncome(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      rentalStatus: rentalStatus ?? this.rentalStatus,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      rentalStartDate: rentalStartDate ?? this.rentalStartDate,
      rentalEndDate: rentalEndDate ?? this.rentalEndDate,
      tenantName: tenantName ?? this.tenantName,
      annualIncome: annualIncome ?? this.annualIncome,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double calculateRentalYield(double marketValue) {
    if (marketValue <= 0) return 0;
    return annualIncome / marketValue * 100;
  }

  double calculateReturnOnInvestment(double purchasePrice) {
    if (purchasePrice <= 0) return 0;
    return annualIncome / purchasePrice * 100;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RentalIncome &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          assetId == other.assetId;

  @override
  int get hashCode => id.hashCode ^ assetId.hashCode;
}
