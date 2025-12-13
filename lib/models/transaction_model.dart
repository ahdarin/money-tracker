class TransactionModel {
  final int? id;
  final int userId;
  final int accountId;
  final int categoryId;
  final String type;
  final double amount;
  final String date;
  
  // FIELD BARU
  final String title;      // Nama Transaksi (Wajib)
  final String? description; // Deskripsi (Opsional)
  final String? imagePath;   // Path Foto (Opsional)

  // Join fields (untuk UI)
  final String? categoryName;
  final String? accountName;

  // Transfer fields
  final int? transferAccountId;   // Transfer
  final String? transferAccountName; // Transfer

  final String? categoryIconCode;

  TransactionModel({
    this.id,
    required this.userId,
    required this.accountId,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.date,
    required this.title, // Baru
    this.description,
    this.imagePath,      // Baru
    this.categoryName,
    this.accountName,
    this.transferAccountId,
    this.transferAccountName,
    this.categoryIconCode,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'account_id': accountId,
    'category_id': categoryId,
    'type': type,
    'amount': amount,
    'date': date,
    'title': title,
    'description': description,
    'image_path': imagePath,
    'transfer_account_id': transferAccountId,
  };

  factory TransactionModel.fromMap(Map<String, dynamic> map) => TransactionModel(
    id: map['id'],
    userId: map['user_id'],
    accountId: map['account_id'],
    categoryId: map['category_id'],
    type: map['type'],
    amount: (map['amount'] as num).toDouble(),
    date: map['date'],
    title: map['title'] ?? 'Transaksi Tanpa Nama', // Default jika null
    description: map['description'],
    imagePath: map['image_path'],
    categoryName: map['category_name'],
    accountName: map['account_name'],
    transferAccountId: map['transfer_account_id'],
    transferAccountName: map['transfer_account_name'],
    categoryIconCode: map['category_icon_code'],
  );
}