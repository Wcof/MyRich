class AllocationItem {
  final String name;
  final double value;
  final double allocation;

  AllocationItem({
    required this.name,
    required this.value,
    required this.allocation,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'allocation': allocation,
    };
  }

  factory AllocationItem.fromJson(Map<String, dynamic> json) {
    return AllocationItem(
      name: json['name'] as String,
      value: (json['value'] as num).toDouble(),
      allocation: (json['allocation'] as num).toDouble(),
    );
  }
}

class TrendPoint {
  final DateTime date;
  final double value;

  TrendPoint({
    required this.date,
    required this.value,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.millisecondsSinceEpoch,
      'value': value,
    };
  }

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
      value: (json['value'] as num).toDouble(),
    );
  }
}

class PortfolioMetrics {
  final double totalCurrentValue;
  final double totalCostValue;
  final double totalProfit;
  final double totalReturnRate;
  final List<AllocationItem> allocationItems;
  final List<TrendPoint> trendSeries;

  PortfolioMetrics({
    required this.totalCurrentValue,
    required this.totalCostValue,
    required this.totalProfit,
    required this.totalReturnRate,
    required this.allocationItems,
    required this.trendSeries,
  });

  PortfolioMetrics.empty()
      : totalCurrentValue = 0,
        totalCostValue = 0,
        totalProfit = 0,
        totalReturnRate = 0,
        allocationItems = [],
        trendSeries = [];

  Map<String, dynamic> toJson() {
    return {
      'totalCurrentValue': totalCurrentValue,
      'totalCostValue': totalCostValue,
      'totalProfit': totalProfit,
      'totalReturnRate': totalReturnRate,
      'allocationItems': allocationItems.map((item) => item.toJson()).toList(),
      'trendSeries': trendSeries.map((point) => point.toJson()).toList(),
    };
  }

  factory PortfolioMetrics.fromJson(Map<String, dynamic> json) {
    return PortfolioMetrics(
      totalCurrentValue: (json['totalCurrentValue'] as num).toDouble(),
      totalCostValue: (json['totalCostValue'] as num).toDouble(),
      totalProfit: (json['totalProfit'] as num).toDouble(),
      totalReturnRate: (json['totalReturnRate'] as num).toDouble(),
      allocationItems: (json['allocationItems'] as List<dynamic>)
          .map((item) => AllocationItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      trendSeries: (json['trendSeries'] as List<dynamic>)
          .map((point) => TrendPoint.fromJson(point as Map<String, dynamic>))
          .toList(),
    );
  }
}
