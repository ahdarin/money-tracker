import 'package:flutter/material.dart';
import 'package:moneytracker/models/account.dart';
import 'package:moneytracker/models/category.dart';
import 'package:moneytracker/models/transaction_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';

class DashboardProvider with ChangeNotifier {
  List<TransactionModel> _recentTransactions = [];
  List<Account> _accounts = [];
  Map<String, double> _summary = {'income': 0, 'expense': 0};
  
  // Getter
  List<TransactionModel> get recentTransactions => _recentTransactions;
  List<Account> get accounts => _accounts;
  Map<String, double> get summary => _summary;

  // --- 1. LOAD DATA (DYNAMIC USER ID) ---
  Future<void> loadDashboardData() async {
    final db = DatabaseHelper.instance;
    
    // AMBIL ID USER DARI SESI LOGIN
    final prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('user_id');

    // Jika belum login/error, stop.
    if (userId == null) return; 

    final now = DateTime.now();
    
    // Gunakan userId yang didapat dari Prefs
    _summary = await db.getMonthlySummary(userId, now.month, now.year);
    _accounts = await db.getAccounts(userId);
    _recentTransactions = await db.getRecentTransactions(userId);
    
    notifyListeners();
  }

  // --- 2. ADD TRANSACTION ---
  Future<void> addTransaction(TransactionModel trx) async {
    await DatabaseHelper.instance.createTransaction(trx);
    await loadDashboardData(); // Refresh data user terkait
  }

  // Helper Kategori
  Future<List<Category>> fetchCategories(String type) async {
    return await DatabaseHelper.instance.getCategories(type);
  }

  // Update
  Future<void> updateTransaction(TransactionModel trx) async {
    await DatabaseHelper.instance.updateTransaction(trx);
    await loadDashboardData(); // Refresh UI
  }
}