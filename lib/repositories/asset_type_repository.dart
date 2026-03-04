import '../models/asset_type.dart';
import '../database/database_helper.dart';

class AssetTypeRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<AssetType>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('asset_types');
    return maps.map((map) => AssetType.fromMap(map)).toList();
  }

  Future<AssetType?> getById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'asset_types',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return AssetType.fromMap(maps.first);
  }

  Future<int> insert(AssetType assetType) async {
    final db = await _dbHelper.database;
    return await db.insert('asset_types', assetType.toMap());
  }

  Future<int> update(AssetType assetType) async {
    final db = await _dbHelper.database;
    return await db.update(
      'asset_types',
      assetType.toMap(),
      where: 'id = ?',
      whereArgs: [assetType.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'asset_types',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<AssetType>> getSystemTypes() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'asset_types',
      where: 'is_system = ?',
      whereArgs: [1],
    );
    return maps.map((map) => AssetType.fromMap(map)).toList();
  }

  Future<List<AssetType>> getCustomTypes() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'asset_types',
      where: 'is_system = ?',
      whereArgs: [0],
    );
    return maps.map((map) => AssetType.fromMap(map)).toList();
  }
}
