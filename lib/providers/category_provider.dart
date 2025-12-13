import 'package:flutter/material.dart';
import 'package:moneytracker/models/category.dart';
import '../database/db_helper.dart';

class CategoryProvider with ChangeNotifier {
  List<Category> _categories = [];
  bool _isLoading = false;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();
    _categories = await DatabaseHelper.instance.getAllCategories();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCategory(String name, String type, String iconCode) async {
    final newCat = Category(name: name, type: type, iconCode: iconCode);
    await DatabaseHelper.instance.insertCategory(newCat);
    await loadCategories();
  }

  Future<void> updateCategory(Category cat) async {
    await DatabaseHelper.instance.updateCategory(cat);
    await loadCategories();
  }

  Future<void> deleteCategory(int id) async {
    await DatabaseHelper.instance.deleteCategory(id);
    await loadCategories();
  }
}