import 'dart:async';
import '../models/fund_plan.dart';
import '../models/asset_record.dart';
import '../repositories/fund_plan_repository.dart';
import '../services/fund_api_service.dart';
import '../providers/asset_provider.dart';
import '../providers/asset_record_provider.dart';
import '../services/fund_asset_mapper.dart';

class FundPlanExecutor {
  static const Duration _checkInterval = Duration(minutes: 30);
  static const int _executeHour = 9;
  static const int _executeMinute = 0;

  final FundPlanRepository _planRepository = FundPlanRepository();
  final FundApiService _apiService = FundApiService();
  final AssetProvider _assetProvider;
  final AssetRecordProvider _recordProvider;

  Timer? _timer;
  bool _isRunning = false;

  FundPlanExecutor({
    required AssetProvider assetProvider,
    required AssetRecordProvider recordProvider,
  })  : _assetProvider = assetProvider,
        _recordProvider = recordProvider;

  void start() {
    if (_isRunning) return;
    
    _isRunning = true;
    _scheduleNextCheck();
  }

  void stop() {
    _timer?.cancel();
    _isRunning = false;
  }

  void _scheduleNextCheck() {
    if (!_isRunning) return;

    final now = DateTime.now();
    final nextCheck = now.add(_checkInterval);
    
    _timer = Timer(nextCheck.difference(now), _checkPlans);
  }

  Future<void> _checkPlans() async {
    try {
      final now = DateTime.now();
      
      if (now.hour < _executeHour || (now.hour == _executeHour && now.minute < _executeMinute)) {
        _scheduleNextCheck();
        return;
      }

      final plans = await _planRepository.getPlansToExecute(now.millisecondsSinceEpoch);
      
      for (final plan in plans) {
        await _executePlan(plan);
      }
    } catch (e) {
      print('检查定投计划失败: $e');
    } finally {
      _scheduleNextCheck();
    }
  }

  Future<void> _executePlan(FundPlan plan) async {
    try {
      final quote = await _apiService.fetchQuote(plan.fundCode);
      if (quote == null) {
        print('获取基金 $plan.fundCode 报价失败');
        return;
      }

      final asset = _assetProvider.assets.firstWhere(
        (a) => a.id == plan.assetId,
        orElse: () => throw Exception('资产不存在'),
      );

      final fundData = FundAssetMapper.extractFundData(asset);
      if (fundData == null) {
        print('获取基金数据失败');
        return;
      }

      final quantity = plan.amount / quote.nav;
      final currentValue = fundData.currentValue + plan.amount;
      final newQuantity = fundData.quantity + quantity;
      final newPurchaseValue = fundData.purchaseValue + plan.amount;
      final newPurchasePrice = newPurchaseValue / newQuantity;

      final updatedFundData = fundData.copyWith(
        quantity: newQuantity,
        purchasePrice: newPurchasePrice,
        lastUpdateAt: DateTime.now().millisecondsSinceEpoch,
      );

      final updatedAsset = FundAssetMapper.updateFundData(asset, updatedFundData);
      await _assetProvider.updateAsset(updatedAsset);

      final record = AssetRecord(
        assetId: plan.assetId,
        value: plan.amount,
        quantity: quantity,
        unitPrice: quote.nav,
        note: '定投买入',
        recordDate: DateTime.now().millisecondsSinceEpoch,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        status: TransactionStatus.estimated,
      );
      await _recordProvider.addRecord(record);

      final nextExecuteAt = _calculateNextExecuteTime(plan);
      final updatedPlan = plan.copyWith(
        lastExecutedAt: DateTime.now().millisecondsSinceEpoch,
        nextExecuteAt: nextExecuteAt,
      );
      await _planRepository.update(updatedPlan);

      print('执行定投计划成功: ${plan.fundName} - ¥${plan.amount}');
    } catch (e) {
      print('执行定投计划失败: $e');
    }
  }

  int _calculateNextExecuteTime(FundPlan plan) {
    DateTime next = DateTime.now();
    
    switch (plan.period) {
      case FundPlanPeriod.daily:
        next = next.add(const Duration(days: 1));
        break;
      case FundPlanPeriod.weekly:
        next = next.add(const Duration(days: 7));
        while (next.weekday != plan.weekDay) {
          next = next.add(const Duration(days: 1));
        }
        break;
      case FundPlanPeriod.biweekly:
        next = next.add(const Duration(days: 14));
        while (next.weekday != plan.weekDay) {
          next = next.add(const Duration(days: 1));
        }
        break;
      case FundPlanPeriod.monthly:
        next = DateTime(next.year, next.month + 1, plan.monthDay!);
        break;
    }
    
    return next.millisecondsSinceEpoch;
  }

  void dispose() {
    stop();
  }
}
