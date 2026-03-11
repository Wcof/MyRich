import '../models/fund_plan.dart';
import '../database/database_helper.dart';

class FundPlanRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<FundPlan>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('fund_plans');
    return maps.map((map) => FundPlan.fromMap(map)).toList();
  }

  Future<List<FundPlan>> getByAssetId(int assetId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'fund_plans',
      where: 'asset_id = ?',
      whereArgs: [assetId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => FundPlan.fromMap(map)).toList();
  }

  Future<FundPlan?> getById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'fund_plans',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return FundPlan.fromMap(maps.first);
  }

  Future<List<FundPlan>> getActivePlans() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'fund_plans',
      where: 'status = ?',
      whereArgs: [0],
      orderBy: 'next_execute_at ASC',
    );
    return maps.map((map) => FundPlan.fromMap(map)).toList();
  }

  Future<List<FundPlan>> getPlansToExecute(int currentTime) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'fund_plans',
      where: 'status = ? AND next_execute_at <= ?',
      whereArgs: [0, currentTime],
    );
    return maps.map((map) => FundPlan.fromMap(map)).toList();
  }

  Future<int> insert(FundPlan plan) async {
    final db = await _dbHelper.database;
    return await db.insert('fund_plans', plan.toMap());
  }

  Future<int> update(FundPlan plan) async {
    final db = await _dbHelper.database;
    return await db.update(
      'fund_plans',
      plan.toMap(),
      where: 'id = ?',
      whereArgs: [plan.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'fund_plans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteByAssetId(int assetId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'fund_plans',
      where: 'asset_id = ?',
      whereArgs: [assetId],
    );
  }
}
