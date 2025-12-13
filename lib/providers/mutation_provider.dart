import 'package:flutter/material.dart';
import 'package:moneytracker/models/category.dart';
import 'package:moneytracker/models/transaction_model.dart';
import '../database/db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MutationProvider with ChangeNotifier {
  List<TransactionModel> _transactions = [];
  List<Category> _filterCategories = [];
  bool _isLoading = false;

  // State Filter
  String _filterType = 'all'; // all, income, expense
  DateTimeRange? _dateRange;
  String _searchQuery = '';
  int? _selectedCategory;

  List<TransactionModel> get transactions => _transactions;
  List<Category> get filterCategories => _filterCategories; // Getter Kategori
  bool get isLoading => _isLoading;
  String get filterType => _filterType;
  DateTimeRange? get dateRange => _dateRange;
  int? get selectedCategory => _selectedCategory; // Getter Selected Category

  // Load Data
  Future<void> loadMutations() async {
    _isLoading = true;
    notifyListeners();

    // AMBIL USER ID DARI SHARED PREFERENCES (FIXED)
    final prefs = await SharedPreferences.getInstance();
    final int userId = prefs.getInt('user_id') ?? 0;

    // Jika belum login/error, stop.
    if (userId == 0) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    final db = DatabaseHelper.instance;

    // Load Kategori untuk Filter (jika belum ada)
    if (_filterCategories.isEmpty) {
      _filterCategories = await db.getAllCategories();
    }

    // Load Transaksi dengan userId dinamis
    _transactions = await db.getTransactionsWithFilter(
      userId: userId, // <-- SUDAH DINAMIS
      query: _searchQuery,
      type: _filterType,
      startDate: _dateRange?.start,
      endDate: _dateRange?.end,
      categoryId: _selectedCategory,
    );

    _isLoading = false;
    notifyListeners();
  }

  // --- SETTERS UTK FILTER ---
  void setFilterType(String type) {
    _filterType = type;
    loadMutations();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadMutations();
  }

  void setDateRange(DateTimeRange? range) {
    _dateRange = range;
    loadMutations();
  }

  void setCategory(int? categoryId) {
    _selectedCategory = categoryId;
    loadMutations();
  }

  // --- ACTIONS ---
  Future<void> deleteTrx(int id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    await loadMutations(); // Reload list
  }
}