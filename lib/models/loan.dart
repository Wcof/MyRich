class Loan {
  final int? id;
  final int assetId;
  final String loanType;
  final String? customLoanType;
  final double loanAmount;
  final double loanRate;
  final int loanPeriod;
  final String repaymentMethod;
  final int loanDate;
  final int dueDate;
  final double paidAmount;
  final double remainingAmount;
  final double monthlyPayment;
  final String status;
  final int? receivingBankAccountId;
  final int? paymentBankAccountId;
  final int? relatedAssetId;
  final int createdAt;
  final int updatedAt;

  static const List<String> presetLoanTypes = [
    '商业贷款',
    '公积金贷款',
    '组合贷款',
    '个人贷款',
    '公司贷款',
    '其他',
  ];

  Loan({
    this.id,
    required this.assetId,
    required this.loanType,
    this.customLoanType,
    required this.loanAmount,
    required this.loanRate,
    required this.loanPeriod,
    required this.repaymentMethod,
    required this.loanDate,
    required this.dueDate,
    this.paidAmount = 0,
    required this.remainingAmount,
    required this.monthlyPayment,
    this.status = 'active',
    this.receivingBankAccountId,
    this.paymentBankAccountId,
    this.relatedAssetId,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayLoanType => loanType == '其他' ? (customLoanType ?? '其他') : loanType;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'asset_id': assetId,
      'loan_type': loanType,
      'custom_loan_type': customLoanType,
      'loan_amount': loanAmount,
      'loan_rate': loanRate,
      'loan_period': loanPeriod,
      'repayment_method': repaymentMethod,
      'loan_date': loanDate,
      'due_date': dueDate,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'monthly_payment': monthlyPayment,
      'status': status,
      'receiving_bank_account_id': receivingBankAccountId,
      'payment_bank_account_id': paymentBankAccountId,
      'related_asset_id': relatedAssetId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      id: map['id'] as int?,
      assetId: map['asset_id'] as int,
      loanType: map['loan_type'] as String,
      customLoanType: map['custom_loan_type'] as String?,
      loanAmount: (map['loan_amount'] as num).toDouble(),
      loanRate: (map['loan_rate'] as num).toDouble(),
      loanPeriod: map['loan_period'] as int,
      repaymentMethod: map['repayment_method'] as String,
      loanDate: map['loan_date'] as int,
      dueDate: map['due_date'] as int,
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0,
      remainingAmount: (map['remaining_amount'] as num).toDouble(),
      monthlyPayment: (map['monthly_payment'] as num).toDouble(),
      status: map['status'] as String? ?? 'active',
      receivingBankAccountId: map['receiving_bank_account_id'] as int?,
      paymentBankAccountId: map['payment_bank_account_id'] as int?,
      relatedAssetId: map['related_asset_id'] as int?,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  Loan copyWith({
    int? id,
    int? assetId,
    String? loanType,
    String? customLoanType,
    double? loanAmount,
    double? loanRate,
    int? loanPeriod,
    String? repaymentMethod,
    int? loanDate,
    int? dueDate,
    double? paidAmount,
    double? remainingAmount,
    double? monthlyPayment,
    String? status,
    int? receivingBankAccountId,
    int? paymentBankAccountId,
    int? relatedAssetId,
    int? createdAt,
    int? updatedAt,
  }) {
    return Loan(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      loanType: loanType ?? this.loanType,
      customLoanType: customLoanType ?? this.customLoanType,
      loanAmount: loanAmount ?? this.loanAmount,
      loanRate: loanRate ?? this.loanRate,
      loanPeriod: loanPeriod ?? this.loanPeriod,
      repaymentMethod: repaymentMethod ?? this.repaymentMethod,
      loanDate: loanDate ?? this.loanDate,
      dueDate: dueDate ?? this.dueDate,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      monthlyPayment: monthlyPayment ?? this.monthlyPayment,
      status: status ?? this.status,
      receivingBankAccountId: receivingBankAccountId ?? this.receivingBankAccountId,
      paymentBankAccountId: paymentBankAccountId ?? this.paymentBankAccountId,
      relatedAssetId: relatedAssetId ?? this.relatedAssetId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get progressRatio => loanAmount > 0 ? paidAmount / loanAmount : 0;

  int get remainingMonths {
    final now = DateTime.now();
    final due = DateTime.fromMillisecondsSinceEpoch(dueDate);
    return due.difference(now).inDays ~/ 30;
  }

  double get totalInterest {
    return (monthlyPayment * loanPeriod * 12) - loanAmount;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Loan &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          assetId == other.assetId;

  @override
  int get hashCode => id.hashCode ^ assetId.hashCode;
}
