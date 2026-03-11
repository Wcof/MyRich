class StockData {
  final String stockCode;
  final String stockName;
  final double currentPrice;
  final double changeAmount;
  final double changeRate;
  final double openPrice;
  final double closePrice;
  final double highPrice;
  final double lowPrice;
  final double volume;
  final double turnover;
  final DateTime updateTime;

  StockData({
    required this.stockCode,
    required this.stockName,
    required this.currentPrice,
    required this.changeAmount,
    required this.changeRate,
    required this.openPrice,
    required this.closePrice,
    required this.highPrice,
    required this.lowPrice,
    required this.volume,
    required this.turnover,
    required this.updateTime,
  });

  factory StockData.fromJson(Map<String, dynamic> json) {
    return StockData(
      stockCode: json['stock_code'] as String? ?? json['代码'] as String? ?? '',
      stockName: json['stock_name'] as String? ?? json['名称'] as String? ?? '',
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 
                    (json['最新价'] as num?)?.toDouble() ?? 0.0,
      changeAmount: (json['change_amount'] as num?)?.toDouble() ?? 
                    (json['涨跌额'] as num?)?.toDouble() ?? 0.0,
      changeRate: (json['change_rate'] as num?)?.toDouble() ?? 
                  (json['涨跌幅'] as num?)?.toDouble() ?? 0.0,
      openPrice: (json['open_price'] as num?)?.toDouble() ?? 
                 (json['今开'] as num?)?.toDouble() ?? 0.0,
      closePrice: (json['close_price'] as num?)?.toDouble() ?? 
                  (json['昨收'] as num?)?.toDouble() ?? 0.0,
      highPrice: (json['high_price'] as num?)?.toDouble() ?? 
                 (json['最高'] as num?)?.toDouble() ?? 0.0,
      lowPrice: (json['low_price'] as num?)?.toDouble() ?? 
                (json['最低'] as num?)?.toDouble() ?? 0.0,
      volume: (json['volume'] as num?)?.toDouble() ?? 
              (json['成交量'] as num?)?.toDouble() ?? 0.0,
      turnover: (json['turnover'] as num?)?.toDouble() ?? 
                (json['成交额'] as num?)?.toDouble() ?? 0.0,
      updateTime: DateTime.parse(json['update_time'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stock_code': stockCode,
      'stock_name': stockName,
      'current_price': currentPrice,
      'change_amount': changeAmount,
      'change_rate': changeRate,
      'open_price': openPrice,
      'close_price': closePrice,
      'high_price': highPrice,
      'low_price': lowPrice,
      'volume': volume,
      'turnover': turnover,
      'update_time': updateTime.toIso8601String(),
    };
  }
}

class StockKLine {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final double turnover;

  StockKLine({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.turnover,
  });

  factory StockKLine.fromJson(Map<String, dynamic> json) {
    return StockKLine(
      time: DateTime.parse(json['time'] as String),
      open: (json['open'] as num?)?.toDouble() ?? 0.0,
      high: (json['high'] as num?)?.toDouble() ?? 0.0,
      low: (json['low'] as num?)?.toDouble() ?? 0.0,
      close: (json['close'] as num?)?.toDouble() ?? 0.0,
      volume: (json['volume'] as num?)?.toDouble() ?? 0.0,
      turnover: (json['turnover'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time.toIso8601String(),
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'volume': volume,
      'turnover': turnover,
    };
  }
}

enum KLinePeriod {
  minute1('1m', '1分钟'),
  minute5('5m', '5分钟'),
  minute15('15m', '15分钟'),
  minute30('30m', '30分钟'),
  minute60('60m', '60分钟'),
  day('D', '日线'),
  week('W', '周线'),
  month('M', '月线');

  final String code;
  final String label;

  const KLinePeriod(this.code, this.label);
}
