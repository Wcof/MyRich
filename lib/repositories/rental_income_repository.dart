import '../database/database_helper.dart';
import '../models/rental_income.dart';

class RentalIncomeRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<RentalIncome>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'rental_incomes',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => RentalIncome.fromMap(map)).toList();
  }

  Future<RentalIncome?> getById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'rental_incomes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return RentalIncome.fromMap(maps.first);
  }

  Future<RentalIncome?> getByAssetId(int assetId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'rental_incomes',
      where: 'asset_id = ?',
      whereArgs: [assetId],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return RentalIncome.fromMap(maps.first);
  }

  Future<List<RentalIncome>> getAllByAssetId(int assetId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'rental_incomes',
      where: 'asset_id = ?',
      whereArgs: [assetId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => RentalIncome.fromMap(map)).toList();
  }

  Future<RentalIncome?> getActiveByAssetId(int assetId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'rental_incomes',
      where: 'asset_id = ? AND status = ?',
      whereArgs: [assetId, 'active'],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return RentalIncome.fromMap(maps.first);
  }

  Future<int> insert(RentalIncome rentalIncome) async {
    final db = await _dbHelper.database;
    return await db.insert('rental_incomes', rentalIncome.toMap());
  }

  Future<int> update(RentalIncome rentalIncome) async {
    final db = await _dbHelper.database;
    return await db.update(
      'rental_incomes',
      rentalIncome.toMap(),
      where: 'id = ?',
      whereArgs: [rentalIncome.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'rental_incomes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteByAssetId(int assetId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'rental_incomes',
      where: 'asset_id = ?',
      whereArgs: [assetId],
    );
  }
}
