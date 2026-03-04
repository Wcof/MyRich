import '../models/asset.dart';
import '../database/database_helper.dart';

class AssetRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Asset>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('assets');
    return maps.map((map) => Asset.fromMap(map)).toList();
  }

  Future<List<Asset>> getByTypeId(int typeId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'assets',
      where: 'type_id = ?',
      whereArgs: [typeId],
    );
    return maps.map((map) => Asset.fromMap(map)).toList();
  }

  Future<Asset?> getById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'assets',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Asset.fromMap(maps.first);
  }

  Future<int> insert(Asset asset) async {
    final db = await _dbHelper.database;
    return await db.insert('assets', asset.toMap());
  }

  Future<int> update(Asset asset) async {
    final db = await _dbHelper.database;
    return await db.update(
      'assets',
      asset.toMap(),
      where: 'id = ?',
      whereArgs: [asset.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'assets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
