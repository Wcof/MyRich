import 'package:flutter/foundation.dart';
import '../models/loan.dart';
import '../repositories/loan_repository.dart';

class LoanProvider with ChangeNotifier {
  final LoanRepository _repository = LoanRepository();

  List<Loan> _loans = [];
  bool _isLoading = false;
  String? _error;

  List<Loan> get loans => _loans;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadLoans() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _loans = await _repository.getAll();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLoansByAssetId(int assetId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _loans = await _repository.getByAssetId(assetId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addLoan(Loan loan) async {
    try {
      await _repository.insert(loan);
      await loadLoansByAssetId(loan.assetId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateLoan(Loan loan) async {
    try {
      await _repository.update(loan);
      final index = _loans.indexWhere((l) => l.id == loan.id);
      if (index != -1) {
        _loans[index] = loan;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteLoan(int id) async {
    try {
      await _repository.delete(id);
      _loans.removeWhere((l) => l.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  List<Loan> getLoansByAssetId(int assetId) {
    return _loans.where((loan) => loan.assetId == assetId).toList();
  }

  List<Loan> getActiveLoansByAssetId(int assetId) {
    return _loans
        .where((loan) => loan.assetId == assetId && loan.status == 'active')
        .toList();
  }

  double getTotalRemainingAmount(int assetId) {
    final activeLoans = getActiveLoansByAssetId(assetId);
    return activeLoans.fold<double>(0, (sum, loan) => sum + loan.remainingAmount);
  }

  double getTotalMonthlyPayment(int assetId) {
    final activeLoans = getActiveLoansByAssetId(assetId);
    return activeLoans.fold<double>(0, (sum, loan) => sum + loan.monthlyPayment);
  }
}
