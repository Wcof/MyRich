import '../models/asset_record.dart';
import '../database/database_helper.dart';

class AssetRecordRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<AssetRecord>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('asset_records');
    return maps.map((map) => AssetRecord.fromMap(map)).toList();
  }

  Future<List<AssetRecord>> getByAssetId(int assetId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'asset_records',
      where: 'asset_id = ?',
      whereArgs: [assetId],
      orderBy: 'record_date DESC',
    );
    return maps.map((map) => AssetRecord.fromMap(map)).toList();
  }

  Future<AssetRecord?> getById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'asset_records',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return AssetRecord.fromMap(maps.first);
  }

  Future<AssetRecord?> getLatestByAssetId(int assetId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'asset_records',
      where: 'asset_id = ?',
      whereArgs: [assetId],
      orderBy: 'record_date DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return AssetRecord.fromMap(maps.first);
  }

  Future<List<AssetRecord>> getByDateRange(
    int assetId,
    int startDate,
    int endDate,
  ) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'asset_records',
      where: 'asset_id = ? AND record_date >= ? AND record_date <= ?',
      whereArgs: [assetId, startDate, endDate],
      orderBy: 'record_date ASC',
    );
    return maps.map((map) => AssetRecord.fromMap(map)).toList();
  }

  Future<int> insert(AssetRecord record) async {
    final db = await _dbHelper.database;
    return await db.insert('asset_records', record.toMap());
  }

  Future<int> update(AssetRecord record) async {
    final db = await _dbHelper.database;
    return await db.update(
      'asset_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'asset_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteByAssetId(int assetId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'asset_records',
      where: 'asset_id = ?',
      whereArgs: [assetId],
    );
  }
}
