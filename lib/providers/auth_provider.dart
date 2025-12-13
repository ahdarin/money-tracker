import 'package:flutter/material.dart';
import 'package:moneytracker/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  // Cek sesi saat aplikasi dibuka
  Future<void> checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId != null) {
      // Ambil data user dari DB
      final user = await DatabaseHelper.instance.getUserById(userId);
      if (user != null) {
        _currentUser = user;
      }
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Cek Database
    final user = await DatabaseHelper.instance.loginUser(email, password);

    if (user != null) {
      _currentUser = user;
      // Simpan Sesi
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', user.id!);
      
      _isLoading = false;
      notifyListeners();
      return true; // Sukses
    } else {
      _isLoading = false;
      notifyListeners();
      return false; // Gagal
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newUser = User(name: name, email: email, password: password);
      await DatabaseHelper.instance.registerUser(newUser);
      
      // Auto login setelah register? Atau suruh login manual?
      // Kita buat auto login saja biar UX bagus
      return login(email, password);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Hapus sesi
    _currentUser = null;
    notifyListeners();
  }

  // Update profil
  Future<bool> updateUserProfile({
    required String name,
    required String email,
    String? newPassword, // Opsional (kosong berarti tidak ubah password)
    String? newPhotoPath, // Opsional (kosong berarti tidak ubah foto)
  }) async {
    _isLoading = true;
    notifyListeners();

    if (_currentUser == null) return false;

    try {
      // 1. Tentukan Password & Foto final
      // Jika newPassword diisi, pakai itu. Jika kosong, pakai password lama.
      String finalPassword = (newPassword != null && newPassword.isNotEmpty) 
          ? newPassword 
          : _currentUser!.password;
      
      // Jika ada foto baru, pakai itu. Jika tidak, pakai path lama.
      String? finalPhotoPath = newPhotoPath ?? _currentUser!.profilePhotoPath;

      // 2. Buat objek User baru
      final updatedUser = User(
        id: _currentUser!.id,
        name: name,
        email: email,
        password: finalPassword,
        profilePhotoPath: finalPhotoPath
      );

      // 3. Update ke Database
      await DatabaseHelper.instance.updateUser(updatedUser);

      // 4. Update State Lokal (agar UI langsung berubah)
      _currentUser = updatedUser;

      _isLoading = false;
      notifyListeners();
      return true; // Sukses
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false; // Gagal
    }
  }
}