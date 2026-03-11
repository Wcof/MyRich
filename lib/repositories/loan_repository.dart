import '../database/database_helper.dart';
import '../models/loan.dart';

class LoanRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Loan>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'loans',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Loan.fromMap(map)).toList();
  }

  Future<Loan?> getById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'loans',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Loan.fromMap(maps.first);
  }

  Future<List<Loan>> getByAssetId(int assetId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'loans',
      where: 'asset_id = ?',
      whereArgs: [assetId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Loan.fromMap(map)).toList();
  }

  Future<List<Loan>> getActiveByAssetId(int assetId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'loans',
      where: 'asset_id = ? AND status = ?',
      whereArgs: [assetId, 'active'],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Loan.fromMap(map)).toList();
  }

  Future<int> insert(Loan loan) async {
    final db = await _dbHelper.database;
    return await db.insert('loans', loan.toMap());
  }

  Future<int> update(Loan loan) async {
    final db = await _dbHelper.database;
    return await db.update(
      'loans',
      loan.toMap(),
      where: 'id = ?',
      whereArgs: [loan.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'loans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteByAssetId(int assetId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'loans',
      where: 'asset_id = ?',
      whereArgs: [assetId],
    );
  }

  Future<double> getTotalRemainingAmount(int assetId) async {
    final loans = await getActiveByAssetId(assetId);
    return loans.fold<double>(0, (sum, loan) => sum + loan.remainingAmount);
  }

  Future<double> getTotalMonthlyPayment(int assetId) async {
    final loans = await getActiveByAssetId(assetId);
    return loans.fold<double>(0, (sum, loan) => sum + loan.monthlyPayment);
  }
}
