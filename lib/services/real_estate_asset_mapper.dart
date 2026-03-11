import 'dart:convert';
import '../models/asset.dart';
import '../models/loan.dart';
import '../models/rental_income.dart';
import '../models/real_estate_price.dart';

class RealEstateData {
  final String? address;
  final double? area;
  final String? roomType;
  final int purchaseDate;
  final double purchasePrice;
  final double renovationCost;
  final double modificationCost;
  final int lastUpdateAt;

  RealEstateData({
    this.address,
    this.area,
    this.roomType,
    required this.purchaseDate,
    required this.purchasePrice,
    this.renovationCost = 0,
    this.modificationCost = 0,
    required this.lastUpdateAt,
  });

  double get totalInvestment =>
      purchasePrice + renovationCost + modificationCost;

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'area': area,
      'roomType': roomType,
      'purchaseDate': purchaseDate,
      'purchasePrice': purchasePrice,
      'renovationCost': renovationCost,
      'modificationCost': modificationCost,
      'lastUpdateAt': lastUpdateAt,
    };
  }

  factory RealEstateData.fromJson(Map<String, dynamic> json) {
    return RealEstateData(
      address: json['address'] as String?,
      area: (json['area'] as num?)?.toDouble(),
      roomType: json['roomType'] as String?,
      purchaseDate: json['purchaseDate'] as int,
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      renovationCost: (json['renovationCost'] as num?)?.toDouble() ?? 0,
      modificationCost: (json['modificationCost'] as num?)?.toDouble() ?? 0,
      lastUpdateAt: json['lastUpdateAt'] as int,
    );
  }

  RealEstateData copyWith({
    String? address,
    double? area,
    String? roomType,
    int? purchaseDate,
    double? purchasePrice,
    double? renovationCost,
    double? modificationCost,
    int? lastUpdateAt,
  }) {
    return RealEstateData(
      address: address ?? this.address,
      area: area ?? this.area,
      roomType: roomType ?? this.roomType,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      renovationCost: renovationCost ?? this.renovationCost,
      modificationCost: modificationCost ?? this.modificationCost,
      lastUpdateAt: lastUpdateAt ?? this.lastUpdateAt,
    );
  }
}

class RealEstateAnalysis {
  final double marketValue;
  final double totalInvestment;
  final double totalLoanAmount;
  final double annualRentalIncome;

  RealEstateAnalysis({
    required this.marketValue,
    required this.totalInvestment,
    required this.totalLoanAmount,
    required this.annualRentalIncome,
  });

  double get netAssetValue => marketValue - totalLoanAmount;

  double get appreciation => marketValue - totalInvestment;

  double get appreciationRate =>
      totalInvestment > 0 ? (appreciation / totalInvestment) * 100 : 0;

  double get leverageRatio =>
      marketValue > 0 ? (totalLoanAmount / marketValue) * 100 : 0;

  double get rentalYield =>
      marketValue > 0 ? (annualRentalIncome / marketValue) * 100 : 0;

  double get roi =>
      totalInvestment > 0 ? (annualRentalIncome / totalInvestment) * 100 : 0;
}

class RealEstateAssetMapper {
  static RealEstateData? extractRealEstateData(Asset asset) {
    if (asset.customData == null) return null;

    try {
      final data = json.decode(asset.customData!);
      if (data is Map<String, dynamic>) {
        if (!data.containsKey('purchasePrice')) return null;
        return RealEstateData.fromJson(data);
      }
    } catch (_) {}

    return null;
  }

  static Asset updateRealEstateData(Asset asset, RealEstateData realEstateData) {
    final customData = json.encode(realEstateData.toJson());
    return asset.copyWith(
      customData: customData,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  static double calculateMarketValue(List<RealEstatePrice> prices) {
    if (prices.isEmpty) return 0;
    final total = prices.fold<double>(0, (sum, p) => sum + p.price);
    return total / prices.length;
  }

  static double calculateTotalLoanAmount(List<Loan> loans) {
    return loans
        .where((l) => l.status == 'active')
        .fold<double>(0, (sum, l) => sum + l.remainingAmount);
  }

  static double calculateMonthlyPayment(List<Loan> loans) {
    return loans
        .where((l) => l.status == 'active')
        .fold<double>(0, (sum, l) => sum + l.monthlyPayment);
  }

  static RealEstateAnalysis analyze({
    required List<RealEstatePrice> prices,
    required double totalInvestment,
    required List<Loan> loans,
    required List<RentalIncome> rentalIncomes,
  }) {
    final marketValue = calculateMarketValue(prices);
    final totalLoanAmount = calculateTotalLoanAmount(loans);
    final annualRentalIncome = rentalIncomes
        .where((r) => r.status == 'active')
        .fold<double>(0, (sum, r) => sum + r.annualIncome);

    return RealEstateAnalysis(
      marketValue: marketValue,
      totalInvestment: totalInvestment,
      totalLoanAmount: totalLoanAmount,
      annualRentalIncome: annualRentalIncome,
    );
  }

  static bool isRealEstateAsset(Asset asset, int realEstateTypeId) {
    return asset.typeId == realEstateTypeId;
  }
}
