import 'dart:async';
import '../models/asset_record.dart';
import '../providers/asset_provider.dart';
import '../providers/asset_record_provider.dart';
import '../providers/asset_type_provider.dart';
import '../repositories/asset_record_repository.dart';
import '../utils/workday_utils.dart';
import 'fund_api_service.dart';
import 'fund_asset_mapper.dart';

class FundUpdateScheduler {
  static const Duration _defaultInterval = Duration(minutes: 60);
  static const Duration _minInterval = Duration(minutes: 5);

  final FundApiService _apiService;
  final AssetProvider _assetProvider;
  final AssetRecordProvider _recordProvider;
  final AssetTypeProvider _typeProvider;
  final AssetRecordRepository _repository = AssetRecordRepository();

  Timer? _timer;
  Duration _interval = _defaultInterval;
  bool _isRunning = false;
  DateTime? _lastUpdateTime;
  bool _isUpdating = false;

  FundUpdateScheduler({
    required FundApiService apiService,
    required AssetProvider assetProvider,
    required AssetRecordProvider recordProvider,
    required AssetTypeProvider typeProvider,
  })  : _apiService = apiService,
        _assetProvider = assetProvider,
        _recordProvider = recordProvider,
        _typeProvider = typeProvider;

  bool get isRunning => _isRunning;
  DateTime? get lastUpdateTime => _lastUpdateTime;
  Duration get interval => _interval;

  void start({Duration? interval}) {
    if (interval != null && interval >= _minInterval) {
      _interval = interval;
    }

    if (_isRunning) return;

    _isRunning = true;
    _timer = Timer.periodic(_interval, (_) => _doUpdate());
    _doUpdate();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  Future<void> runOnce({bool userTriggered = false}) async {
    if (_isUpdating) return;
    await _doUpdate(userTriggered: userTriggered);
  }

  Future<void> _doUpdate({bool userTriggered = false}) async {
    if (_isUpdating) return;

    _isUpdating = true;
    try {
      final fundTypeIds = _typeProvider.assetTypes
          .where((type) => type.name == '基金')
          .map((type) => type.id)
          .whereType<int>()
          .toList();

      if (fundTypeIds.isEmpty) return;

      final fundAssets = _assetProvider.assets
          .where((asset) => FundAssetMapper.isFundAsset(asset, fundTypeIds))
          .toList();

      if (fundAssets.isEmpty) return;

      final fundCodes = fundAssets
          .map((asset) => FundAssetMapper.extractFundData(asset)?.fundCode)
          .whereType<String>()
          .toList();

      if (fundCodes.isEmpty) return;

      final quotes = await _apiService.fetchQuotes(fundCodes);
      final quoteMap = {for (var q in quotes) q.fundCode: q};

      for (final asset in fundAssets) {
        final fundData = FundAssetMapper.extractFundData(asset);
        if (fundData == null) continue;

        final quote = quoteMap[fundData.fundCode];
        if (quote == null) continue;

        final oldPrice = fundData.currentPrice;
        final newPrice = quote.nav;
        final navDate = quote.navDate;

        if ((newPrice - oldPrice).abs() > 0.0001) {
          final updatedFundData = fundData.copyWith(
            fundName: quote.fundName,
            currentPrice: newPrice,
            lastUpdateAt: DateTime.now().millisecondsSinceEpoch,
            apiSource: '${quote.source} (${navDate.year}-${navDate.month.toString().padLeft(2, '0')}-${navDate.day.toString().padLeft(2, '0')})',
          );

          final updatedAsset = FundAssetMapper.updateFundData(asset, updatedFundData);
          await _assetProvider.updateAsset(updatedAsset);

          if (updatedAsset.id != null) {
            final record = AssetRecord(
              assetId: updatedAsset.id!,
              value: updatedFundData.currentValue,
              unitPrice: newPrice,
              quantity: updatedFundData.quantity,
              recordDate: DateTime.now().millisecondsSinceEpoch,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              note: '净值更新 (${navDate.year}-${navDate.month.toString().padLeft(2, '0')}-${navDate.day.toString().padLeft(2, '0')}): ${oldPrice.toStringAsFixed(4)} → ${newPrice.toStringAsFixed(4)}',
            );
            await _recordProvider.addRecord(record);
          }
        }
      }

      await _updateTransactionStatus();

      _lastUpdateTime = DateTime.now();
    } catch (e) {
      print('更新失败: $e');
    } finally {
      _isUpdating = false;
    }
  }

  Future<void> _updateTransactionStatus() async {
    try {
      final estimatedRecords = await _repository.getEstimatedRecords();
      final now = DateTime.now();
      
      final recordsToConfirm = <int>[];
      
      for (final record in estimatedRecords) {
        final transactionDate = DateTime.fromMillisecondsSinceEpoch(record.recordDate);
        
        if (WorkdayUtils.shouldConfirmTransaction(transactionDate, now)) {
          if (record.id != null) {
            recordsToConfirm.add(record.id!);
          }
        }
      }
      
      if (recordsToConfirm.isNotEmpty) {
        for (final id in recordsToConfirm) {
          final record = estimatedRecords.firstWhere((r) => r.id == id);
          final updatedRecord = record.copyWith(status: TransactionStatus.confirmed);
          await _repository.update(updatedRecord);
        }
      }
    } catch (e) {
      print('更新交易状态失败: $e');
    }
  }

  void dispose() {
    stop();
  }
}
