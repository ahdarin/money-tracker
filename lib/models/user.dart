class User {
  final int? id;
  final String name;
  final String email;
  final String password;
  final String? profilePhotoPath; // <-- FIELD BARU (Nullable)

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.profilePhotoPath, // <-- Tambahkan di constructor
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'password': password,
    'profile_photo_path': profilePhotoPath, // <-- Masukkan ke Map DB
  };

  factory User.fromMap(Map<String, dynamic> map) => User(
    id: map['id'],
    name: map['name'],
    email: map['email'],
    password: map['password'],
    profilePhotoPath: map['profile_photo_path'], // <-- Ambil dari Map DB
  );
}