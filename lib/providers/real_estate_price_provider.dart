import 'package:flutter/foundation.dart';
import '../models/real_estate_price.dart';
import '../repositories/real_estate_price_repository.dart';

class RealEstatePriceProvider with ChangeNotifier {
  final RealEstatePriceRepository _repository = RealEstatePriceRepository();

  Map<int, List<RealEstatePrice>> _pricesByAsset = {};
  bool _isLoading = false;
  String? _error;

  List<RealEstatePrice> get allPrices =>
      _pricesByAsset.values.expand((prices) => prices).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPricesByAssetId(int assetId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prices = await _repository.getByAssetId(assetId);
      _pricesByAsset[assetId] = prices;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLatestPricesByAssetId(int assetId, {int limit = 10}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prices = await _repository.getLatestByAssetId(assetId, limit: limit);
      _pricesByAsset[assetId] = prices;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPrice(RealEstatePrice price) async {
    try {
      await _repository.insert(price);
      // Reload from DB to get records with auto-generated ids
      await loadPricesByAssetId(price.assetId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePrice(RealEstatePrice price) async {
    try {
      await _repository.update(price);
      final prices = _pricesByAsset[price.assetId];
      if (prices != null) {
        final index = prices.indexWhere((p) => p.id == price.id);
        if (index != -1) {
          prices[index] = price;
          notifyListeners();
        }
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePrice(int id, int assetId) async {
    try {
      await _repository.delete(id);
      _pricesByAsset[assetId]?.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  List<RealEstatePrice> getPricesByAssetId(int assetId) {
    return _pricesByAsset[assetId] ?? [];
  }

  double getAveragePrice(int assetId) {
    final prices = getPricesByAssetId(assetId);
    if (prices.isEmpty) return 0;
    final total = prices.fold<double>(0, (sum, p) => sum + p.price);
    return total / prices.length;
  }

  double getLatestAveragePrice(int assetId, {int limit = 5}) {
    final prices = getPricesByAssetId(assetId);
    if (prices.isEmpty) return 0;
    final latestPrices = prices.take(limit).toList();
    final total = latestPrices.fold<double>(0, (sum, p) => sum + p.price);
    return total / latestPrices.length;
  }

  Map<String, double> getPricesBySource(int assetId) {
    final prices = getPricesByAssetId(assetId);
    final Map<String, List<double>> pricesBySource = {};
    
    for (var price in prices) {
      pricesBySource.putIfAbsent(price.source, () => []);
      pricesBySource[price.source]!.add(price.price);
    }
    
    return pricesBySource.map((source, priceList) {
      final avg = priceList.reduce((a, b) => a + b) / priceList.length;
      return MapEntry(source, avg);
    });
  }
}
