class StockHolding {
  final String stockCode;
  final String stockName;
  final double proportion;
  final double? shares;
  final double? value;

  StockHolding({
    required this.stockCode,
    required this.stockName,
    required this.proportion,
    this.shares,
    this.value,
  });

  factory StockHolding.fromJson(Map<String, dynamic> json) {
    return StockHolding(
      stockCode: json['stock_code'] as String? ?? json['代码'] as String? ?? '',
      stockName: json['stock_name'] as String? ?? json['名称'] as String? ?? '',
      proportion: (json['proportion'] as num?)?.toDouble() ?? 
                  (json['占比'] as num?)?.toDouble() ?? 0.0,
      shares: (json['shares'] as num?)?.toDouble(),
      value: (json['value'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stock_code': stockCode,
      'stock_name': stockName,
      'proportion': proportion,
      'shares': shares,
      'value': value,
    };
  }
}

class FundPortfolio {
  final String fundCode;
  final String fundName;
  final List<StockHolding> holdings;
  final DateTime updateTime;

  FundPortfolio({
    required this.fundCode,
    required this.fundName,
    required this.holdings,
    required this.updateTime,
  });

  factory FundPortfolio.fromJson(Map<String, dynamic> json) {
    return FundPortfolio(
      fundCode: json['fund_code'] as String,
      fundName: json['fund_name'] as String,
      holdings: (json['holdings'] as List?)
          ?.map((e) => StockHolding.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      updateTime: DateTime.parse(json['update_time'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fund_code': fundCode,
      'fund_name': fundName,
      'holdings': holdings.map((e) => e.toJson()).toList(),
      'update_time': updateTime.toIso8601String(),
    };
  }
}

class FundType {
  static const String etf = 'ETF';
  static const String aggregate = 'aggregate';
  static const String unknown = 'unknown';

  static String determineType(String fundCode) {
    if (fundCode.startsWith('51') || 
        fundCode.startsWith('15') || 
        fundCode.startsWith('16') ||
        fundCode.startsWith('50') ||
        fundCode.startsWith('56') ||
        fundCode.startsWith('58')) {
      return etf;
    }
    return aggregate;
  }
}
