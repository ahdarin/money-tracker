import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 1. Tambah Import ini
import '../database/db_helper.dart';
import '../models/transaction_model.dart'; // Sesuaikan path jika perlu

class StatisticsProvider with ChangeNotifier {
  List<Map<String, dynamic>> _topCategories = [];
  List<DailySummary> _weeklyData = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get topCategories => _topCategories;
  List<DailySummary> get weeklyData => _weeklyData;
  bool get isLoading => _isLoading;

  // HAPUS BARIS INI: final int currentUserId = 1; 

  Future<void> loadStatsData() async {
    _isLoading = true;
    notifyListeners();

    // 2. AMBIL USER ID DARI SESI LOGIN
    final prefs = await SharedPreferences.getInstance();
    final int userId = prefs.getInt('user_id') ?? 0;

    // Jika userId 0 (belum login/error), hentikan proses
    if (userId == 0) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    final db = DatabaseHelper.instance;

    // A. PROSES TOP SPENDING (Gunakan userId dinamis)
    final rawCats = await db.getTopSpendingCategories(userId);
    _processTopCategories(rawCats);

    // B. PROSES WEEKLY CHART
    final now = DateTime.now();
    // 7 Hari ke belakang (termasuk hari ini)
    final start = now.subtract(const Duration(days: 6)); 
    
    // Set jam ke 00:00:00 dan 23:59:59 agar range pas
    final startOfDay = DateTime(start.year, start.month, start.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // Gunakan userId dinamis
    final trxs = await db.getTransactionsForDateRange(userId, startOfDay, endOfDay);
    _processWeeklyData(trxs, startOfDay);

    _isLoading = false;
    notifyListeners();
  }

  // Logika: Ambil 3 teratas, sisanya gabung jadi "Lainnya"
  void _processTopCategories(List<Map<String, dynamic>> raw) {
    if (raw.isEmpty) {
      _topCategories = [];
      return;
    }

    List<Map<String, dynamic>> processed = [];
    double totalOthers = 0;

    for (int i = 0; i < raw.length; i++) {
      if (i < 3) {
        processed.add(raw[i]);
      } else {
        totalOthers += (raw[i]['total'] as num).toDouble();
      }
    }

    if (totalOthers > 0) {
      processed.add({
        'name': 'Lainnya',
        'icon_code': null, 
        'total': totalOthers
      });
    }
    _topCategories = processed;
  }

  // Logika: Mapping transaksi ke 7 hari
  void _processWeeklyData(List<TransactionModel> trxs, DateTime start) {
    _weeklyData = List.generate(7, (index) {
      final date = start.add(Duration(days: index));
      return DailySummary(date: date, income: 0, expense: 0);
    });

    for (var trx in trxs) {
      final trxDate = DateTime.parse(trx.date);
      // Cari index hari yang cocok (0-6)
      final diff = trxDate.difference(start).inDays;
      if (diff >= 0 && diff < 7) {
        if (trx.type == 'income') {
          _weeklyData[diff].income += trx.amount;
        } else {
          _weeklyData[diff].expense += trx.amount;
        }
      }
    }
  }
}

// Helper Class untuk Chart
class DailySummary {
  final DateTime date;
  double income;
  double expense;
  DailySummary({required this.date, required this.income, required this.expense});
}