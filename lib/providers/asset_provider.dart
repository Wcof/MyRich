import 'package:flutter/foundation.dart';
import '../models/asset.dart';
import '../repositories/asset_repository.dart';

class AssetProvider with ChangeNotifier {
  final AssetRepository _repository = AssetRepository();
  List<Asset> _assets = [];
  bool _isLoading = false;
  String? _error;

  List<Asset> get assets => _assets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAssets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _assets = await _repository.getAll();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAssetsByType(int typeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _assets = await _repository.getByTypeId(typeId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int?> addAsset(Asset asset) async {
    try {
      final id = await _repository.insert(asset);
      await loadAssets();
      return id;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> updateAsset(Asset asset) async {
    try {
      await _repository.update(asset);
      await loadAssets();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteAsset(int id) async {
    try {
      await _repository.delete(id);
      await loadAssets();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  List<Asset> getAssetsByType(int typeId) {
    return _assets.where((asset) => asset.typeId == typeId).toList();
  }
}
