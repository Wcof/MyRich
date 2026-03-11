import '../database/database_helper.dart';
import '../models/real_estate_price.dart';

class RealEstatePriceRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<RealEstatePrice>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'real_estate_prices',
      orderBy: 'record_date DESC',
    );
    return maps.map((map) => RealEstatePrice.fromMap(map)).toList();
  }

  Future<RealEstatePrice?> getById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'real_estate_prices',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return RealEstatePrice.fromMap(maps.first);
  }

  Future<List<RealEstatePrice>> getByAssetId(int assetId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'real_estate_prices',
      where: 'asset_id = ?',
      whereArgs: [assetId],
      orderBy: 'record_date DESC',
    );
    return maps.map((map) => RealEstatePrice.fromMap(map)).toList();
  }

  Future<List<RealEstatePrice>> getLatestByAssetId(int assetId, {int limit = 10}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'real_estate_prices',
      where: 'asset_id = ?',
      whereArgs: [assetId],
      orderBy: 'record_date DESC',
      limit: limit,
    );
    return maps.map((map) => RealEstatePrice.fromMap(map)).toList();
  }

  Future<RealEstatePrice?> getLatestPriceBySource(int assetId, String source) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'real_estate_prices',
      where: 'asset_id = ? AND source = ?',
      whereArgs: [assetId, source],
      orderBy: 'record_date DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return RealEstatePrice.fromMap(maps.first);
  }

  Future<int> insert(RealEstatePrice price) async {
    final db = await _dbHelper.database;
    return await db.insert('real_estate_prices', price.toMap());
  }

  Future<int> update(RealEstatePrice price) async {
    final db = await _dbHelper.database;
    return await db.update(
      'real_estate_prices',
      price.toMap(),
      where: 'id = ?',
      whereArgs: [price.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'real_estate_prices',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteByAssetId(int assetId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'real_estate_prices',
      where: 'asset_id = ?',
      whereArgs: [assetId],
    );
  }

  Future<double> getAveragePrice(int assetId) async {
    final prices = await getByAssetId(assetId);
    if (prices.isEmpty) return 0;
    final total = prices.fold<double>(0, (sum, p) => sum + p.price);
    return total / prices.length;
  }

  Future<double> getLatestAveragePrice(int assetId, {int limit = 5}) async {
    final prices = await getLatestByAssetId(assetId, limit: limit);
    if (prices.isEmpty) return 0;
    final total = prices.fold<double>(0, (sum, p) => sum + p.price);
    return total / prices.length;
  }
}
