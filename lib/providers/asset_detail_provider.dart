import 'package:flutter/foundation.dart';
import '../models/asset_detail.dart';
import '../repositories/asset_detail_repository.dart';

class AssetDetailProvider with ChangeNotifier {
  final AssetDetailRepository _repository = AssetDetailRepository();
  List<AssetDetail> _details = [];
  bool _isLoading = false;
  String? _error;

  List<AssetDetail> get details => _details;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDetails(int assetId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _details = await _repository.getByAssetId(assetId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDetailsByType(int assetId, String detailType) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _details = await _repository.getByDetailType(assetId, detailType);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addDetail(AssetDetail detail) async {
    try {
      final newDetail = await _repository.create(detail);
      _details.add(newDetail);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDetail(AssetDetail detail) async {
    try {
      final success = await _repository.update(detail);
      if (success) {
        final index = _details.indexWhere((d) => d.id == detail.id);
        if (index >= 0) {
          _details[index] = detail;
          notifyListeners();
        }
      } else {
        _error = '版本冲突，请刷新后重试';
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDetail(int id) async {
    try {
      final success = await _repository.delete(id);
      if (success) {
        _details.removeWhere((d) => d.id == id);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDetailsByAssetId(int assetId) async {
    try {
      await _repository.deleteByAssetId(assetId);
      _details = _details.where((d) => d.assetId != assetId).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
