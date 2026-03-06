import '../models/data_source/data_source_config.dart';
import '../models/asset.dart';
import '../providers/asset_provider.dart';

class DataSourceService {
  final AssetProvider assetProvider;
  
  DataSourceService(this.assetProvider);

  Future<dynamic> fetchData(DataSourceConfig config) async {
    switch (config.type) {
      case DataSourceType.singleAsset:
        return await _fetchSingleAssetData(config.params);
      case DataSourceType.assetTypeAggregation:
        return await _fetchAssetTypeAggregation(config.params);
      case DataSourceType.multipleAssets:
        return await _fetchMultipleAssetsData(config.params);
      case DataSourceType.assetRecordTimeSeries:
        return await _fetchAssetRecordTimeSeries(config.params);
      case DataSourceType.customMetric:
        return await _fetchCustomMetric(config.params);
    }
  }

  Future<Map<String, dynamic>> _fetchSingleAssetData(
    Map<String, dynamic> params,
  ) async {
    final assetId = params['assetId'] as int?;
    if (assetId == null) return {};

    final assets = assetProvider.assets;
    final asset = assets.firstWhere(
      (a) => a.id == assetId,
      // Fallback asset for missing id in data source preview/query.
      orElse: () => Asset(
        id: assetId,
        typeId: 0,
        name: '未知资产',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    final displayFields = params['displayFields'] as List<String>? ?? ['value'];
    
    return {
      'asset': asset.toMap(),
      'data': _extractAssetFields(asset, displayFields),
    };
  }

  Future<Map<String, dynamic>> _fetchAssetTypeAggregation(
    Map<String, dynamic> params,
  ) async {
    final assetTypeId = params['assetTypeId'] as int?;
    final aggregation = params['aggregation'] as String? ?? 'sum';
    final displayField = params['displayField'] as String? ?? 'value';

    final assets = assetProvider.assets;
    final typeAssets = assets.where((a) => a.typeId == assetTypeId).toList();

    double result = 0.0;
    
    switch (aggregation) {
      case 'sum':
        for (final asset in typeAssets) {
          result += _getAssetValue(asset, displayField);
        }
        break;
      case 'average':
        if (typeAssets.isNotEmpty) {
          for (final asset in typeAssets) {
            result += _getAssetValue(asset, displayField);
          }
          result /= typeAssets.length;
        }
        break;
      case 'max':
        for (final asset in typeAssets) {
          final value = _getAssetValue(asset, displayField);
          if (value > result) result = value;
        }
        break;
      case 'min':
        if (typeAssets.isNotEmpty) {
          result = _getAssetValue(typeAssets.first, displayField);
          for (final asset in typeAssets.skip(1)) {
            final value = _getAssetValue(asset, displayField);
            if (value < result) result = value;
          }
        }
        break;
    }

    return {
      'value': result,
      'aggregation': aggregation,
      'assetCount': typeAssets.length,
    };
  }

  Future<List<Map<String, dynamic>>> _fetchMultipleAssetsData(
    Map<String, dynamic> params,
  ) async {
    final assetTypeIds = params['assetTypeIds'] as List<int>? ?? [];
    final groupBy = params['groupBy'] as String?;
    final sortBy = params['sortBy'] as String?;
    final sortOrder = params['sortOrder'] as String? ?? 'desc';
    final limit = params['limit'] as int? ?? 10;

    List<Asset> assets;
    if (assetTypeIds.isNotEmpty) {
      assets = assetProvider.assets
          .where((a) => assetTypeIds.contains(a.typeId))
          .toList();
    } else {
      assets = assetProvider.assets;
    }

    final List<Map<String, dynamic>> result = [];
    for (final asset in assets) {
      result.add({
        'asset': asset.toMap(),
        'value': _getAssetValue(asset, 'value'),
      });
    }

    if (sortBy == 'value') {
      result.sort((a, b) {
        final valueA = a['value'] as double;
        final valueB = b['value'] as double;
        return sortOrder == 'desc' 
            ? valueB.compareTo(valueA)
            : valueA.compareTo(valueB);
      });
    }

    if (result.length > limit) {
      return result.sublist(0, limit);
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> _fetchAssetRecordTimeSeries(
    Map<String, dynamic> params,
  ) async {
    final assetId = params['assetId'] as int?;
    final period = params['period'] as String? ?? 'month';
    final aggregation = params['aggregation'] as String? ?? 'average';

    return [
      {'date': '2024-01', 'value': 10000.0},
      {'date': '2024-02', 'value': 10500.0},
      {'date': '2024-03', 'value': 11000.0},
      {'date': '2024-04', 'value': 10800.0},
    ];
  }

  Future<Map<String, dynamic>> _fetchCustomMetric(
    Map<String, dynamic> params,
  ) async {
    return {
      'value': 0.0,
      'metric': params['metric'],
    };
  }

  Map<String, dynamic> _extractAssetFields(
    Asset asset,
    List<String> displayFields,
  ) {
    final result = <String, dynamic>{};
    for (final field in displayFields) {
      result[field] = _getAssetValue(asset, field);
    }
    return result;
  }

  double _getAssetValue(Asset asset, String field) {
    if (asset.customData != null) {
      try {
        final data = Map<String, dynamic>.from(asset.customData as Map);
        return (data[field] as num?)?.toDouble() ?? 0.0;
      } catch (_) {}
    }
    return 0.0;
  }
}
