import 'package:flutter/foundation.dart';
import '../models/fund_plan.dart';
import '../repositories/fund_plan_repository.dart';

class FundPlanProvider with ChangeNotifier {
  final FundPlanRepository _repository = FundPlanRepository();
  List<FundPlan> _plans = [];
  bool _isLoading = false;
  String? _error;

  List<FundPlan> get plans => _plans;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPlans() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _plans = await _repository.getAll();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPlansByAsset(int assetId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _plans = await _repository.getByAssetId(assetId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPlan(FundPlan plan) async {
    try {
      await _repository.insert(plan);
      await loadPlansByAsset(plan.assetId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updatePlan(FundPlan plan) async {
    try {
      await _repository.update(plan);
      await loadPlansByAsset(plan.assetId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deletePlan(int id, int assetId) async {
    try {
      await _repository.delete(id);
      await loadPlansByAsset(assetId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> pausePlan(int id) async {
    try {
      final plan = _plans.firstWhere((p) => p.id == id);
      final updatedPlan = plan.copyWith(status: FundPlanStatus.paused);
      await _repository.update(updatedPlan);
      await loadPlansByAsset(updatedPlan.assetId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> resumePlan(int id) async {
    try {
      final plan = _plans.firstWhere((p) => p.id == id);
      final updatedPlan = plan.copyWith(status: FundPlanStatus.active);
      await _repository.update(updatedPlan);
      await loadPlansByAsset(updatedPlan.assetId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  List<FundPlan> getActivePlans() {
    return _plans.where((plan) => plan.status == FundPlanStatus.active).toList();
  }

  List<FundPlan> getPlansByAsset(int assetId) {
    return _plans.where((plan) => plan.assetId == assetId).toList();
  }
}
