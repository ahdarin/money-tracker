import 'package:flutter/material.dart';
import 'package:moneytracker/models/account.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';

class AccountProvider with ChangeNotifier {
  List<Account> _accounts = [];
  bool _isLoading = false;

  List<Account> get accounts => _accounts;
  bool get isLoading => _isLoading;

  // Load Accounts by User ID
  Future<void> loadAccounts() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final int userId = prefs.getInt('user_id') ?? 0;

    if (userId != 0) {
      _accounts = await DatabaseHelper.instance.getAccounts(userId);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addAccount(String name, String type, double balance) async {
    final prefs = await SharedPreferences.getInstance();
    final int userId = prefs.getInt('user_id') ?? 0;

    final newAcc = Account(
      userId: userId,
      name: name,
      type: type,
      balance: balance,
      lastUsed: DateTime.now().toIso8601String(),
    );

    await DatabaseHelper.instance.insertAccount(newAcc);
    await loadAccounts();
  }

  Future<void> updateAccount(Account account) async {
    await DatabaseHelper.instance.updateAccount(account);
    await loadAccounts();
  }

  Future<void> deleteAccount(int id) async {
    await DatabaseHelper.instance.deleteAccount(id);
    await loadAccounts();
  }
}