import 'package:flutter/foundation.dart';
import '../models/asset_record.dart';
import '../repositories/asset_record_repository.dart';

class AssetRecordProvider with ChangeNotifier {
  final AssetRecordRepository _repository = AssetRecordRepository();
  List<AssetRecord> _records = [];
  bool _isLoading = false;
  String? _error;

  List<AssetRecord> get records => _records;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadRecords() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _records = await _repository.getAll();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRecordsByAsset(int assetId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _records = await _repository.getByAssetId(assetId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addRecord(AssetRecord record) async {
    try {
      await _repository.insert(record);
      await loadRecordsByAsset(record.assetId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateRecord(AssetRecord record) async {
    try {
      await _repository.update(record);
      await loadRecordsByAsset(record.assetId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteRecord(int id, int assetId) async {
    try {
      await _repository.delete(id);
      await loadRecordsByAsset(assetId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  List<AssetRecord> getRecordsByAsset(int assetId) {
    return _records.where((record) => record.assetId == assetId).toList();
  }

  Future<AssetRecord?> getLatestRecord(int assetId) async {
    return await _repository.getLatestByAssetId(assetId);
  }
}
