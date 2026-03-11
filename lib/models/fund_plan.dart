enum FundPlanPeriod {
  daily,
  weekly,
  biweekly,
  monthly,
}

enum FundPlanStatus {
  active,
  paused,
  completed,
  cancelled,
}

class FundPlan {
  final int? id;
  final int assetId;
  final String fundCode;
  final String fundName;
  final double amount;
  final FundPlanPeriod period;
  final int? weekDay; // 周几 (1-7)
  final int? monthDay; // 几号 (1-31)
  final DateTime startDate;
  final DateTime? endDate;
  final FundPlanStatus status;
  final int createdAt;
  final int? lastExecutedAt;
  final int? nextExecuteAt;

  FundPlan({
    this.id,
    required this.assetId,
    required this.fundCode,
    required this.fundName,
    required this.amount,
    required this.period,
    this.weekDay,
    this.monthDay,
    required this.startDate,
    this.endDate,
    this.status = FundPlanStatus.active,
    required this.createdAt,
    this.lastExecutedAt,
    this.nextExecuteAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'asset_id': assetId,
      'fund_code': fundCode,
      'fund_name': fundName,
      'amount': amount,
      'period': period.index,
      'week_day': weekDay,
      'month_day': monthDay,
      'start_date': startDate.millisecondsSinceEpoch,
      'end_date': endDate?.millisecondsSinceEpoch,
      'status': status.index,
      'created_at': createdAt,
      'last_executed_at': lastExecutedAt,
      'next_execute_at': nextExecuteAt,
    };
  }

  factory FundPlan.fromMap(Map<String, dynamic> map) {
    return FundPlan(
      id: map['id'] as int?,
      assetId: map['asset_id'] as int,
      fundCode: map['fund_code'] as String,
      fundName: map['fund_name'] as String,
      amount: map['amount'] as double,
      period: FundPlanPeriod.values[map['period'] as int],
      weekDay: map['week_day'] as int?,
      monthDay: map['month_day'] as int?,
      startDate: DateTime.fromMillisecondsSinceEpoch(map['start_date'] as int),
      endDate: map['end_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['end_date'] as int) 
          : null,
      status: FundPlanStatus.values[map['status'] as int],
      createdAt: map['created_at'] as int,
      lastExecutedAt: map['last_executed_at'] as int?,
      nextExecuteAt: map['next_execute_at'] as int?,
    );
  }

  FundPlan copyWith({
    int? id,
    int? assetId,
    String? fundCode,
    String? fundName,
    double? amount,
    FundPlanPeriod? period,
    int? weekDay,
    int? monthDay,
    DateTime? startDate,
    DateTime? endDate,
    FundPlanStatus? status,
    int? createdAt,
    int? lastExecutedAt,
    int? nextExecuteAt,
  }) {
    return FundPlan(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      fundCode: fundCode ?? this.fundCode,
      fundName: fundName ?? this.fundName,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      weekDay: weekDay ?? this.weekDay,
      monthDay: monthDay ?? this.monthDay,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastExecutedAt: lastExecutedAt ?? this.lastExecutedAt,
      nextExecuteAt: nextExecuteAt ?? this.nextExecuteAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FundPlan &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          assetId == other.assetId &&
          fundCode == other.fundCode &&
          fundName == other.fundName &&
          amount == other.amount &&
          period == other.period &&
          weekDay == other.weekDay &&
          monthDay == other.monthDay &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          status == other.status &&
          createdAt == other.createdAt &&
          lastExecutedAt == other.lastExecutedAt &&
          nextExecuteAt == other.nextExecuteAt;

  @override
  int get hashCode =>
      id.hashCode ^
      assetId.hashCode ^
      fundCode.hashCode ^
      fundName.hashCode ^
      amount.hashCode ^
      period.hashCode ^
      weekDay.hashCode ^
      monthDay.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      status.hashCode ^
      createdAt.hashCode ^
      lastExecutedAt.hashCode ^
      nextExecuteAt.hashCode;
}
