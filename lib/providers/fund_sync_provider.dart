import 'package:flutter/foundation.dart';
import '../services/fund_api_service.dart';
import '../services/fund_update_scheduler.dart';
import 'asset_provider.dart';
import 'asset_record_provider.dart';
import 'asset_type_provider.dart';

class FundSyncProvider with ChangeNotifier {
  final FundUpdateScheduler _scheduler;
  bool _isSyncing = false;
  String? _lastError;

  FundSyncProvider({
    required FundApiService apiService,
    required AssetProvider assetProvider,
    required AssetRecordProvider recordProvider,
    required AssetTypeProvider typeProvider,
  }) : _scheduler = FundUpdateScheduler(
          apiService: apiService,
          assetProvider: assetProvider,
          recordProvider: recordProvider,
          typeProvider: typeProvider,
        );

  bool get isSyncing => _isSyncing;
  bool get isRunning => _scheduler.isRunning;
  DateTime? get lastUpdateTime => _scheduler.lastUpdateTime;
  String? get lastError => _lastError;

  Future<void> startAutoSync() async {
    _scheduler.start();
    notifyListeners();
  }

  void stopAutoSync() {
    _scheduler.stop();
    notifyListeners();
  }

  Future<void> refreshNow() async {
    if (_isSyncing) return;

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      await _scheduler.runOnce(userTriggered: true);
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _scheduler.dispose();
    super.dispose();
  }
}
