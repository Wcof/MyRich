import 'package:flutter/foundation.dart';
import '../models/asset_type.dart';
import '../repositories/asset_type_repository.dart';

class AssetTypeProvider with ChangeNotifier {
  final AssetTypeRepository _repository = AssetTypeRepository();
  List<AssetType> _assetTypes = [];
  bool _isLoading = false;
  String? _error;

  List<AssetType> get assetTypes => _assetTypes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAssetTypes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _assetTypes = await _repository.getAll();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAssetType(AssetType assetType) async {
    try {
      await _repository.insert(assetType);
      await loadAssetTypes();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateAssetType(AssetType assetType) async {
    try {
      await _repository.update(assetType);
      await loadAssetTypes();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteAssetType(int id) async {
    try {
      await _repository.delete(id);
      await loadAssetTypes();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  List<AssetType> get systemTypes =>
      _assetTypes.where((type) => type.isSystem).toList();

  List<AssetType> get customTypes =>
      _assetTypes.where((type) => !type.isSystem).toList();
}
