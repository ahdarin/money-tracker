class Category {
  final int? id;
  final String name;
  final String type; // 'income' atau 'expense'
  final String iconCode; // Simpan code point IconData

  Category({this.id, required this.name, required this.type, required this.iconCode});

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type,
    'icon_code': iconCode,
  };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
    id: map['id'],
    name: map['name'],
    type: map['type'],
    iconCode: map['icon_code'],
  );
}