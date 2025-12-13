// lib/core/database/db_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:moneytracker/models/account.dart';
import 'package:moneytracker/models/transaction_model.dart';
import 'package:moneytracker/models/category.dart';
import 'package:moneytracker/models/user.dart';
import 'package:flutter/material.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finance_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    // Tabel User
    await db.execute('''
      CREATE TABLE users (
        id $idType,
        name $textType,
        email $textType,
        password $textType,
        profile_photo_path TEXT
      )
    ''');

    // Tabel Categories
    await db.execute('''
      CREATE TABLE categories (
        id $idType,
        name $textType,
        type $textType,
        icon_code $textType
      )
    ''');

    // Tabel Accounts
    await db.execute('''
      CREATE TABLE accounts (
        id $idType,
        user_id $integerType,
        name $textType,
        type $textType,
        balance $realType,
        last_used $textType,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Tabel Transactions
    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        user_id $integerType,
        account_id $integerType,
        category_id $integerType,
        type $textType,
        amount $realType,
        date $textType,
        title $textType,
        description TEXT,
        image_path TEXT,
        transfer_account_id INTEGER,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (account_id) REFERENCES accounts (id),
        FOREIGN KEY (transfer_account_id) REFERENCES accounts (id), -- Relasi ke akun tujuan
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // INSERT DUMMY DATA LANGSUNG SAAT INSTALL PERTAMA
    await _seedData(db);
  }

  // Update Data User
  Future<int> updateUser(User user) async {
    final db = await instance.database;
    return await db.update(
      'users', 
      user.toMap(), 
      where: 'id = ?', 
      whereArgs: [user.id]
    );
  }

  Future<void> _seedData(Database db) async {
    // Gunakan .codePoint.toString() agar konsisten dengan input user
    await db.insert('categories', {'name': 'Makanan', 'type': 'expense', 'icon_code': Icons.fastfood.codePoint.toString()}); 
    await db.insert('categories', {'name': 'Gaji', 'type': 'income', 'icon_code': Icons.attach_money.codePoint.toString()});
    await db.insert('categories', {'name': 'Transport', 'type': 'expense', 'icon_code': Icons.directions_bus.codePoint.toString()});
    await db.insert('categories', {'name': 'Belanja', 'type': 'expense', 'icon_code': Icons.shopping_cart.codePoint.toString()});
    await db.insert('categories', {'name': 'Hiburan', 'type': 'expense', 'icon_code': Icons.movie.codePoint.toString()});
    await db.insert('categories', {'name': 'Kesehatan', 'type': 'expense', 'icon_code': Icons.medical_services.codePoint.toString()});
    await db.insert('categories', {'name': 'Pendidikan', 'type': 'expense', 'icon_code': Icons.school.codePoint.toString()});
    await db.insert('categories', {'name': 'Tagihan', 'type': 'expense', 'icon_code': Icons.receipt_long.codePoint.toString()});
  }
  
  // --- CRUD METHODS (Contoh Singkat) ---
  
  // Ambil Summary Bulanan
  Future<Map<String, double>> getMonthlySummary(int userId, int month, int year) async {
    final db = await instance.database;
    // Query manual dengan rawQuery untuk grouping
    // Sederhananya kita tarik semua dulu lalu filter di Dart (untuk demo ini)
    final result = await db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    double income = 0;
    double expense = 0;

    for (var map in result) {
      DateTime dt = DateTime.parse(map['date'] as String);
      if (dt.month == month && dt.year == year) {
        if (map['type'] == 'income') income += (map['amount'] as num).toDouble();
        if (map['type'] == 'expense') expense += (map['amount'] as num).toDouble();
      }
    }
    return {'income': income, 'expense': expense};
  }

  // Ambil 5 Transaksi Terakhir (Join Table)
  Future<List<TransactionModel>> getRecentTransactions(int userId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT t.*, 
             c.name as category_name, 
             c.type as category_type,
             c.icon_code as category_icon_code,
             a.name as account_name,
             ta.name as transfer_account_name
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      LEFT JOIN accounts a ON t.account_id = a.id
      LEFT JOIN accounts ta ON t.transfer_account_id = ta.id
      WHERE t.user_id = ?
      ORDER BY t.date DESC
      LIMIT 5
    ''', [userId]);

    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  // Ambil Semua Akun
  Future<List<Account>> getAccounts(int userId) async {
    final db = await instance.database;
    final result = await db.query('accounts', where: 'user_id = ?', whereArgs: [userId]);
    return result.map((json) => Account.fromMap(json)).toList();
  }

// Buka lib/core/database/db_helper.dart
// Tambahkan method-method ini di dalam class DatabaseHelper

  // 1. Tambah Transaksi Baru
  Future<int> createTransaction(TransactionModel trx) async {
    final db = await instance.database;
    final id = await db.insert('transactions', trx.toMap());
    
    // Update Saldo
    if (trx.type == 'transfer' && trx.transferAccountId != null) {
      // Logic Transfer:
      // Rekening Asal (account_id) -> KURANG (Expense)
      await _updateAccountBalance(trx.accountId, trx.amount, 'expense');
      // Rekening Tujuan (transfer_account_id) -> TAMBAH (Income)
      await _updateAccountBalance(trx.transferAccountId!, trx.amount, 'income');
    } else {
      // Logic Biasa
      await _updateAccountBalance(trx.accountId, trx.amount, trx.type);
    }
    
    return id;
  }

  // 2. Update Saldo Rekening (Private)
  Future<void> _updateAccountBalance(int accountId, double amount, String type) async {
    final db = await instance.database;
    
    // Ambil saldo sekarang
    final result = await db.query('accounts', where: 'id = ?', whereArgs: [accountId]);
    if (result.isNotEmpty) {
      double currentBalance = (result.first['balance'] as num).toDouble();
      double newBalance = currentBalance;

      if (type == 'income') {
        newBalance += amount;
      } else if (type == 'expense') {
        newBalance -= amount;
      } 
      // Note: Logic 'transfer' nanti kita handle khusus di Provider/UI agar lebih aman
      
      // Update ke DB
      await db.update(
        'accounts',
        {'balance': newBalance, 'last_used': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [accountId],
      );
    }
  }

  // 3. Ambil List Kategori (Untuk Dropdown di Form)
  Future<List<Category>> getCategories(String type) async {
    final db = await instance.database;
    final result = await db.query('categories', where: 'type = ?', whereArgs: [type]);
    return result.map((json) => Category.fromMap(json)).toList();
  }

  // 4. Ambil Total Pengeluaran per Kategori (Untuk Top Spending)
  Future<List<Map<String, dynamic>>> getTopSpendingCategories(int userId) async {
    final db = await instance.database;
    // Query join untuk ambil nama kategori dan total uangnya
    return await db.rawQuery('''
      SELECT c.name, c.icon_code, SUM(t.amount) as total
      FROM transactions t
      JOIN categories c ON t.category_id = c.id
      WHERE t.user_id = ? AND t.type = 'expense'
      GROUP BY t.category_id
      ORDER BY total DESC
    ''', [userId]);
  }

  // 5. Ambil Transaksi 7 Hari Terakhir (Untuk Bar Chart)
  Future<List<TransactionModel>> getTransactionsForDateRange(int userId, DateTime start, DateTime end) async {
    final db = await instance.database;
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    final result = await db.rawQuery('''
      SELECT * FROM transactions 
      WHERE user_id = ? AND date >= ? AND date <= ?
    ''', [userId, startStr, endStr]);

    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  // 6. Ambil Transaksi dengan Filter Lengkap
  Future<List<TransactionModel>> getTransactionsWithFilter({
    required int userId,
    String? query,
    String? type, // 'all', 'income', 'expense'
    DateTime? startDate,
    DateTime? endDate,
    int? categoryId,
  }) async {
    final db = await instance.database;
    
    // Base Query
    String sql = '''
      SELECT t.*, c.name as category_name, 
             a.name as account_name,
             ta.name as transfer_account_name  -- Ambil nama rekening tujuan
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      LEFT JOIN accounts a ON t.account_id = a.id
      LEFT JOIN accounts ta ON t.transfer_account_id = ta.id -- Join tabel accounts lagi sbg 'ta'
      WHERE t.user_id = ?
    ''';
    
    List<dynamic> args = [userId];

    // Filter Type
    if (type != null && type != 'all') {
      sql += ' AND t.type = ?';
      args.add(type);
    }

    // Filter Tanggal
    if (startDate != null && endDate != null) {
      sql += ' AND t.date BETWEEN ? AND ?';
      args.add(startDate.toIso8601String());
      args.add(endDate.toIso8601String());
    }

    // Filter Kategori
    if (categoryId != null) {
      sql += ' AND t.category_id = ?';
      args.add(categoryId);
    }

    // Filter Search (Keyword)
    if (query != null && query.isNotEmpty) {
      sql += ' AND (t.title LIKE ? OR t.description LIKE ?)';
      args.add('%$query%');
      args.add('%$query%');
    }

    sql += ' ORDER BY t.date DESC';

    final result = await db.rawQuery(sql, args);
    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  // 7. Hapus Transaksi & Balikin Saldo
  Future<void> deleteTransaction(int id) async {
    final db = await instance.database;
    final result = await db.query('transactions', where: 'id = ?', whereArgs: [id]);
    
    if (result.isNotEmpty) {
      final trx = TransactionModel.fromMap(result.first);
      
      if (trx.type == 'transfer' && trx.transferAccountId != null) {
        // Balikin Saldo Transfer:
        // Asal -> DITAMBAH BALIK (Income)
        await _updateAccountBalance(trx.accountId, trx.amount, 'income');
        // Tujuan -> DIKURANGI BALIK (Expense)
        await _updateAccountBalance(trx.transferAccountId!, trx.amount, 'expense');
      } else {
        // Logic Biasa
        await _updateAccountBalance(trx.accountId, trx.amount, trx.type == 'income' ? 'expense' : 'income');
      }

      await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    }
  }

  // 8. CRUD KATEGORI
  Future<int> insertCategory(Category cat) async {
    final db = await instance.database;
    return await db.insert('categories', cat.toMap());
  }

  Future<int> updateCategory(Category cat) async {
    final db = await instance.database;
    return await db.update('categories', cat.toMap(), where: 'id = ?', whereArgs: [cat.id]);
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    // Cek dulu apakah kategori ini dipakai di transaksi?
    // Idealnya: Jangan hapus jika dipakai, atau ubah transaksi terkait ke 'Lainnya'.
    // Untuk simpelnya tutorial ini: Kita hapus saja.
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
  
  // Ambil semua kategori (untuk manajemen)
  Future<List<Category>> getAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories', orderBy: 'type, name'); // Sort by type lalu nama
    return result.map((json) => Category.fromMap(json)).toList();
  }

  // 9. AUTENTIKASI
  // Login: Cari user berdasarkan email & password
  Future<User?> loginUser(String email, String password) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    } else {
      return null; // Gagal login
    }
  }

  // Register: Buat user baru + Rekening Default
  Future<int> registerUser(User user) async {
    final db = await instance.database;
    
    // 1. Insert User
    int userId = await db.insert('users', user.toMap());

    // 2. Insert Rekening Default (Dompet) untuk User ini
    await db.insert('accounts', {
      'user_id': userId,
      'name': 'Dompet Tunai',
      'type': 'Cash',
      'balance': 0.0, // Saldo awal 0
      'last_used': DateTime.now().toIso8601String()
    });

    return userId;
  }

  // Ambil data user by ID (untuk profil)
  Future<User?> getUserById(int id) async {
    final db = await instance.database;
    final result = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) return User.fromMap(result.first);
    return null;
  }

  // Update Transaksi Aman (Jaga Saldo)
  Future<void> updateTransaction(TransactionModel newTrx) async {
    final db = await instance.database;

    // 1. Ambil Data Lama
    final oldData = await db.query('transactions', where: 'id = ?', whereArgs: [newTrx.id]);
    if (oldData.isNotEmpty) {
      final oldTrx = TransactionModel.fromMap(oldData.first);

      // 2. KEMBALIKAN SALDO LAMA (Reverse)
      // Jika dulu Expense, sekarang Saldo kita Tambah balik.
      // Jika dulu Income, sekarang Saldo kita Kurang balik.
      await _updateAccountBalance(
        oldTrx.accountId, 
        oldTrx.amount, 
        oldTrx.type == 'income' ? 'expense' : 'income' // Logic reverse
      );

      // 3. UPDATE DATA TRANSAKSI
      await db.update('transactions', newTrx.toMap(), where: 'id = ?', whereArgs: [newTrx.id]);

      // 4. TERAPKAN SALDO BARU
      await _updateAccountBalance(newTrx.accountId, newTrx.amount, newTrx.type);
    }
  }

  // 10. CRUD REKENING (MANAGE ACCOUNTS)
  
  // Tambah Rekening
  Future<int> insertAccount(Account account) async {
    final db = await instance.database;
    return await db.insert('accounts', account.toMap());
  }

  // Update Rekening (Nama, Tipe, Saldo)
  Future<int> updateAccount(Account account) async {
    final db = await instance.database;
    return await db.update(
      'accounts', 
      account.toMap(), 
      where: 'id = ?', 
      whereArgs: [account.id]
    );
  }

  // Hapus Rekening
  Future<int> deleteAccount(int id) async {
    final db = await instance.database;
    // PENTING: Jika rekening dihapus, transaksi terkait harusnya ikut terhapus atau error.
    // Di sini kita hapus transaksinya dulu agar bersih (Cascade manual)
    await db.delete('transactions', where: 'account_id = ?', whereArgs: [id]);
    
    return await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }
}