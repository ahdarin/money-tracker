import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moneytracker/models/category.dart';
import '../../providers/category_provider.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).loadCategories();
    });
  }

  // Helper Ikon: Mengubah String angka menjadi IconData
  IconData _getIcon(String code) {
    try {
      return IconData(int.parse(code), fontFamily: 'MaterialIcons');
    } catch (_) {
      return Icons.category;
    }
  }

  // Dialog Form (Tambah/Edit)
  void _showFormDialog({Category? category}) {
    final isEdit = category != null;
    final nameController = TextEditingController(text: isEdit ? category.name : '');
    String selectedType = isEdit ? category.type : 'expense';
    
    // LOGIKA PERBAIKAN: Gunakan codePoint string
    String selectedIconCode = isEdit ? category.iconCode : Icons.fastfood.codePoint.toString();

    // Daftar Ikon Pilihan
    final List<IconData> iconOptions = [
      Icons.fastfood,
      Icons.directions_bus,
      Icons.shopping_cart,
      Icons.attach_money,
      Icons.movie,
      Icons.medical_services,
      Icons.school,
      Icons.flight,
      Icons.sports_esports,
      Icons.build,
      Icons.pets,
      Icons.home,
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setStateSB) {
          return AlertDialog(
            title: Text(isEdit ? "Edit Kategori" : "Kategori Baru"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Nama Kategori"),
                  ),
                  const SizedBox(height: 16),
                  
                  // Pilihan Tipe (Radio Button)
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile(
                          title: const Text("Keluar", style: TextStyle(fontSize: 12)),
                          value: 'expense',
                          groupValue: selectedType,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) => setStateSB(() => selectedType = val.toString()),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile(
                          title: const Text("Masuk", style: TextStyle(fontSize: 12)),
                          value: 'income',
                          groupValue: selectedType,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) => setStateSB(() => selectedType = val.toString()),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 10),
                  const Text("Pilih Ikon:"),
                  const SizedBox(height: 8),
                  
                  // Grid Ikon
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: iconOptions.map((iconData) {
                      // Bandingkan codePoint string-nya
                      final isSelected = selectedIconCode == iconData.codePoint.toString();
                      
                      return GestureDetector(
                        onTap: () => setStateSB(() => selectedIconCode = iconData.codePoint.toString()),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey[100],
                            shape: BoxShape.circle,
                            border: isSelected ? Border.all(color: Colors.blue) : null,
                          ),
                          child: Icon(iconData, color: isSelected ? Colors.blue : Colors.grey),
                        ),
                      );
                    }).toList(),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    // Gunakan 'this.context' atau context parent untuk Provider
                    final provider = Provider.of<CategoryProvider>(this.context, listen: false);
                    
                    if (isEdit) {
                      provider.updateCategory(Category(
                        id: category.id,
                        name: nameController.text,
                        type: selectedType,
                        iconCode: selectedIconCode, // Simpan angka string
                      ));
                    } else {
                      provider.addCategory(nameController.text, selectedType, selectedIconCode);
                    }
                    Navigator.pop(context);
                  }
                },
                child: const Text("Simpan"),
              )
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kelola Kategori")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        child: const Icon(Icons.add),
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.categories.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final cat = provider.categories[index];
              final isExpense = cat.type == 'expense';
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isExpense ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                  // Render icon dari string angka
                  child: Icon(_getIcon(cat.iconCode), color: isExpense ? Colors.red : Colors.green),
                ),
                title: Text(cat.name),
                subtitle: Text(isExpense ? "Pengeluaran" : "Pemasukan"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showFormDialog(category: cat),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.grey),
                      onPressed: () {
                        provider.deleteCategory(cat.id!);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}