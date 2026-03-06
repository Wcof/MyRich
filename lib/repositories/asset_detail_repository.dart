import '../database/database_helper.dart';
import '../models/asset_detail.dart';

class AssetDetailRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<AssetDetail>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('asset_details');
    return maps.map((map) => AssetDetail.fromMap(map)).toList();
  }

  Future<AssetDetail?> getById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'asset_details',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return AssetDetail.fromMap(maps.first);
  }

  Future<List<AssetDetail>> getByAssetId(int assetId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'asset_details',
      where: 'asset_id = ?',
      whereArgs: [assetId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => AssetDetail.fromMap(map)).toList();
  }

  Future<List<AssetDetail>> getByDetailType(int assetId, String detailType) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'asset_details',
      where: 'asset_id = ? AND detail_type = ?',
      whereArgs: [assetId, detailType],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => AssetDetail.fromMap(map)).toList();
  }

  Future<AssetDetail> create(AssetDetail detail) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final detailWithTime = detail.copyWith(
      createdAt: now,
      updatedAt: now,
      version: 1,
    );
    final id = await db.insert('asset_details', detailWithTime.toMap());
    return detailWithTime.copyWith(id: id);
  }

  Future<bool> update(AssetDetail detail) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final result = await db.update(
      'asset_details',
      detail.copyWith(
        updatedAt: now,
        version: (detail.version ?? 0) + 1,
      ).toMap(),
      where: 'id = ? AND version = ?',
      whereArgs: [detail.id, detail.version],
    );
    return result > 0;
  }

  Future<bool> delete(int id) async {
    final db = await _dbHelper.database;
    final result = await db.delete(
      'asset_details',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result > 0;
  }

  Future<bool> deleteByAssetId(int assetId) async {
    final db = await _dbHelper.database;
    final result = await db.delete(
      'asset_details',
      where: 'asset_id = ?',
      whereArgs: [assetId],
    );
    return result > 0;
  }
}
