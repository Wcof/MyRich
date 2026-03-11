import 'package:flutter/foundation.dart';
import '../models/rental_income.dart';
import '../repositories/rental_income_repository.dart';

class RentalIncomeProvider with ChangeNotifier {
  final RentalIncomeRepository _repository = RentalIncomeRepository();

  Map<int, List<RentalIncome>> _rentalIncomesByAsset = {};
  bool _isLoading = false;
  String? _error;

  List<RentalIncome> get rentalIncomes => _rentalIncomesByAsset.values.expand((e) => e).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadRentalIncomes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final incomes = await _repository.getAll();
      _rentalIncomesByAsset = {};
      for (var income in incomes) {
        if (!_rentalIncomesByAsset.containsKey(income.assetId)) {
          _rentalIncomesByAsset[income.assetId] = [];
        }
        _rentalIncomesByAsset[income.assetId]!.add(income);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRentalIncomeByAssetId(int assetId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final incomes = await _repository.getAllByAssetId(assetId);
      if (incomes.isNotEmpty) {
        _rentalIncomesByAsset[assetId] = incomes;
      } else {
        _rentalIncomesByAsset.remove(assetId);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllRentalIncomesByAssetId(int assetId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final incomes = await _repository.getAllByAssetId(assetId);
      _rentalIncomesByAsset[assetId] = incomes;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addRentalIncome(RentalIncome rentalIncome) async {
    try {
      await _repository.insert(rentalIncome);
      await loadRentalIncomeByAssetId(rentalIncome.assetId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRentalIncome(RentalIncome rentalIncome) async {
    try {
      await _repository.update(rentalIncome);
      if (_rentalIncomesByAsset.containsKey(rentalIncome.assetId)) {
        final index = _rentalIncomesByAsset[rentalIncome.assetId]!.indexWhere(
          (r) => r.id == rentalIncome.id,
        );
        if (index != -1) {
          _rentalIncomesByAsset[rentalIncome.assetId]![index] = rentalIncome;
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRentalIncome(int id, int assetId) async {
    try {
      await _repository.delete(id);
      if (_rentalIncomesByAsset.containsKey(assetId)) {
        _rentalIncomesByAsset[assetId]!.removeWhere((r) => r.id == id);
        if (_rentalIncomesByAsset[assetId]!.isEmpty) {
          _rentalIncomesByAsset.remove(assetId);
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  List<RentalIncome> getRentalIncomesByAssetId(int assetId) {
    return _rentalIncomesByAsset[assetId] ?? [];
  }

  RentalIncome? getFirstRentalIncomeByAssetId(int assetId) {
    final incomes = _rentalIncomesByAsset[assetId];
    if (incomes != null && incomes.isNotEmpty) {
      return incomes.first;
    }
    return null;
  }

  List<RentalIncome> getActiveRentalIncomesByAssetId(int assetId) {
    final incomes = _rentalIncomesByAsset[assetId];
    if (incomes != null) {
      return incomes.where((r) => r.status == 'active').toList();
    }
    return [];
  }
}