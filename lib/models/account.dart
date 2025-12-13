class Account {
  final int? id;
  final int userId;
  final String name;
  final String type; // e.g., Bank, E-Wallet, Cash
  final double balance;
  final String lastUsed; // ISO8601 String

  Account({this.id, required this.userId, required this.name, required this.type, required this.balance, required this.lastUsed});

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'type': type,
    'balance': balance,
    'last_used': lastUsed,
  };

  factory Account.fromMap(Map<String, dynamic> map) => Account(
    id: map['id'],
    userId: map['user_id'],
    name: map['name'],
    type: map['type'],
    balance: (map['balance'] as num).toDouble(),
    lastUsed: map['last_used'],
  );
}