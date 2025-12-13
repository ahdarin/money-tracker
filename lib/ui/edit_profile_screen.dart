import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  final _passCtrl = TextEditingController(); // Untuk password baru

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  String? _currentPhotoPath;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser!;
    // Isi controller dengan data saat ini
    _nameCtrl = TextEditingController(text: user.name);
    _emailCtrl = TextEditingController(text: user.email);
    _currentPhotoPath = user.profilePhotoPath;
  }

  Future<void> _pickImage() async {
    // Ambil dari galeri saja untuk simpelnya
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.updateUserProfile(
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        newPassword: _passCtrl.text.isEmpty ? null : _passCtrl.text, // Kirim null jika kosong
        newPhotoPath: _selectedImage?.path, // Kirim path baru jika ada
      );

      if (success && mounted) {
        Navigator.pop(context); // Kembali ke halaman profil
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil berhasil diperbarui")));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal memperbarui profil")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profil")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 1. FOTO PROFIL DENGAN TOMBOL EDIT
              Center(
                child: Stack(
                  children: [
                    _buildProfileImage(),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 2. FORM INPUT
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: "Nama Lengkap", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                validator: (val) => val!.isEmpty ? "Nama wajib diisi" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                validator: (val) => val!.isEmpty ? "Email wajib diisi" : null,
              ),
              const SizedBox(height: 30),
              
              const Text("Ubah Password (Opsional)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password Baru", 
                  hintText: "Kosongkan jika tidak ingin mengubah",
                  border: OutlineInputBorder(), 
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _saveProfile,
                  child: authProvider.isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("SIMPAN PERUBAHAN"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget untuk menampilkan logika foto
  Widget _buildProfileImage() {
    ImageProvider? imageProvider;

    if (_selectedImage != null) {
      // 1. Prioritas: Foto yang baru dipilih dari galeri
      imageProvider = FileImage(_selectedImage!);
    } else if (_currentPhotoPath != null && File(_currentPhotoPath!).existsSync()) {
      // 2. Jika tidak ada foto baru, cek foto lama di database
      imageProvider = FileImage(File(_currentPhotoPath!));
    }

    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.grey[300],
      // Jika ada image provider, pakai itu. Jika tidak, null (agar child Icon muncul).
      backgroundImage: imageProvider, 
      child: imageProvider == null 
          ? Icon(Icons.person, size: 70, color: Colors.grey[600]) // Default Icon
          : null,
    );
  }
}