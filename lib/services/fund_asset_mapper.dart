import 'dart:convert';
import '../models/asset.dart';

class FundData {
  final String fundCode;
  final String fundName;
  final double quantity;
  final double purchasePrice;
  final double currentPrice;
  final int purchaseDate;
  final int lastUpdateAt;
  final String? apiSource;

  FundData({
    required this.fundCode,
    required this.fundName,
    required this.quantity,
    required this.purchasePrice,
    required this.currentPrice,
    required this.purchaseDate,
    required this.lastUpdateAt,
    this.apiSource,
  });

  double get currentValue => quantity * currentPrice;
  double get purchaseValue => quantity * purchasePrice;
  double get returnAmount => currentValue - purchaseValue;
  double get returnRate => purchaseValue != 0 ? returnAmount / purchaseValue : 0;

  Map<String, dynamic> toJson() {
    return {
      'fundCode': fundCode,
      'fundName': fundName,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'currentPrice': currentPrice,
      'purchaseDate': purchaseDate,
      'lastUpdateAt': lastUpdateAt,
      'apiSource': apiSource,
    };
  }

  factory FundData.fromJson(Map<String, dynamic> json) {
    return FundData(
      fundCode: json['fundCode'] as String,
      fundName: json['fundName'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      currentPrice: (json['currentPrice'] as num).toDouble(),
      purchaseDate: json['purchaseDate'] as int,
      lastUpdateAt: json['lastUpdateAt'] as int,
      apiSource: json['apiSource'] as String?,
    );
  }

  FundData copyWith({
    String? fundCode,
    String? fundName,
    double? quantity,
    double? purchasePrice,
    double? currentPrice,
    int? purchaseDate,
    int? lastUpdateAt,
    String? apiSource,
  }) {
    return FundData(
      fundCode: fundCode ?? this.fundCode,
      fundName: fundName ?? this.fundName,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      currentPrice: currentPrice ?? this.currentPrice,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      lastUpdateAt: lastUpdateAt ?? this.lastUpdateAt,
      apiSource: apiSource ?? this.apiSource,
    );
  }
}

  FundData copyWith({
    String? fundCode,
    String? fundName,
    double? quantity,
    double? purchasePrice,
    double? currentPrice,
    int? purchaseDate,
    int? lastUpdateAt,
    String? apiSource,
  }) {
    return FundData(
      fundCode: fundCode ?? this.fundCode,
      fundName: fundName ?? this.fundName,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      currentPrice: currentPrice ?? this.currentPrice,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      lastUpdateAt: lastUpdateAt ?? this.lastUpdateAt,
      apiSource: apiSource ?? this.apiSource,
    );
  }
}

class FundAssetMapper {
  static FundData? extractFundData(Asset asset) {
    if (asset.customData == null) return null;

    try {
      final data = json.decode(asset.customData!);
      if (data is Map<String, dynamic>) {
        if (!data.containsKey('fundCode')) return null;
        return FundData.fromJson(data);
      }
    } catch (_) {
    }

    return null;
  }

  static Asset updateFundData(Asset asset, FundData fundData) {
    final customData = json.encode(fundData.toJson());
    return asset.copyWith(
      customData: customData,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  static double getFundValue(Asset asset) {
    final fundData = extractFundData(asset);
    if (fundData != null) {
      return fundData.currentValue;
    }

    if (asset.customData != null) {
      try {
        final data = json.decode(asset.customData!);
        if (data is Map<String, dynamic>) {
          final value = data['value'] as num?;
          if (value != null) return value.toDouble();
        }
      } catch (_) {
      }
    }

    return 0.0;
  }

  static bool isFundAsset(Asset asset, List<int> fundTypeIds) {
    return fundTypeIds.contains(asset.typeId);
  }
}
