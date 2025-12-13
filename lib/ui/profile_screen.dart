import 'dart:io'; // Import untuk File
import 'package:flutter/material.dart';
import 'package:moneytracker/ui/manage_account_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import 'manage_categories_screen.dart';
import 'edit_profile_screen.dart'; // Import halaman edit


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ambil data user terbaru dari provider
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    // Cek apakah user punya path foto dan filenya ada di HP
    final hasPhoto = user?.profilePhotoPath != null && File(user!.profilePhotoPath!).existsSync();

    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),
              // 1. FOTO & INFO USER
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                // Logika: Jika punya foto, load dari File. Jika tidak, null.
                backgroundImage: hasPhoto ? FileImage(File(user.profilePhotoPath!)) : null,
                // Jika backgroundImage null, tampilkan Icon default di dalamnya.
                child: !hasPhoto 
                  ? Icon(Icons.person, size: 60, color: Colors.grey[600]) 
                  : null,
              ),
              const SizedBox(height: 16),
              Text(
                user?.name ?? "Pengguna",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                user?.email ?? "-",
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 30),

              // 2. LIST MENU
              _buildSectionHeader("Pengaturan Umum"),
              _buildMenuTile(
                context,
                icon: Icons.person_outline, 
                title: "Edit Profil", 
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                }
              ),
              _buildMenuTile(
                context,
                icon: Icons.category_outlined, 
                title: "Kelola Kategori", 
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageCategoriesScreen()));
                }
              ),
              _buildMenuTile(
                context,
                icon: Icons.account_balance_wallet_outlined, 
                title: "Kelola Rekening", 
                onTap: () { 
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageAccountsScreen()));
                }
              ),
               _buildMenuTile(
                context,
                icon: Icons.dark_mode_outlined,
                title: "Mode Gelap",
                // Gunakan Switch yang terhubung ke provider
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (val) {
                    themeProvider.toggleTheme(val);
                  },
                ),
                onTap: () {
                  themeProvider.toggleTheme(!themeProvider.isDarkMode);
                },
              ),

              const SizedBox(height: 20),
              _buildSectionHeader("Akun"),
              _buildMenuTile(
                context,
                icon: Icons.logout, 
                title: "Keluar", 
                color: Colors.red,
                onTap: () {
                   Provider.of<AuthProvider>(context, listen: false).logout();
                }
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, {required IconData icon, required String title, VoidCallback? onTap, Color? color, Widget? trailing}) {
    // 1. Tentukan Warna Teks/Icon
    // Jika color dikirim (misal Merah untuk logout), pakai itu.
    // Jika null, pakai warna teks default tema (Putih di Dark, Hitam di Light).
    final effectiveColor = color ?? Theme.of(context).textTheme.bodyMedium?.color;

    // 2. Tentukan Warna Background Icon
    // Abu gelap untuk Dark Mode, Abu terang untuk Light Mode
    final iconBgColor = Theme.of(context).brightness == Brightness.dark 
        ? Colors.grey[800] 
        : Colors.grey[100];

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: effectiveColor),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: color)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}