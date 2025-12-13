import 'package:flutter/material.dart';
import 'package:moneytracker/models/account.dart';
import 'package:moneytracker/models/category.dart';
import 'package:moneytracker/models/transaction_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/dashboard_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AddTransactionScreen extends StatefulWidget {
  final String initialType; // 'income' atau 'expense'
  final TransactionModel? transactionToEdit; // Untuk edit transaksi

  const AddTransactionScreen({super.key, required this.initialType, this.transactionToEdit});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controller
  late String _type;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  Account? _selectedAccount;
  
  List<Category> _categoryList = [];

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  bool _isEditMode = false;
  
  @override
  void initState() {
    super.initState();
    _type = widget.initialType;

    // CEK APAKAH MODE EDIT?
    if (widget.transactionToEdit != null) {
      _isEditMode = true;
      final trx = widget.transactionToEdit!;
      
      // Isi Controller dengan data lama
      _amountController.text = trx.amount.toStringAsFixed(0);
      _titleController.text = trx.title;
      _descController.text = trx.description ?? '';
      _selectedDate = DateTime.parse(trx.date);
      _dateController.text = DateFormat('dd MMM yyyy').format(_selectedDate);
      
      if (trx.imagePath != null) {
        _selectedImage = File(trx.imagePath!);
      }
      
      // Note: Mengisi _selectedAccount dan _selectedCategory agak tricky 
      // karena kita perlu objek Account/Category yang sama persis dengan yang di dropdown.
      // Kita akan handle di _loadData (lihat bawah)
    } else {
      _dateController.text = DateFormat('dd MMM yyyy').format(_selectedDate);
    }

    _loadData();
  }

  void _loadData() async {
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    final cats = await provider.fetchCategories(_type);
    
    // Perlu akses daftar akun juga untuk pre-select
    // Asumsi accounts sudah ada di provider (kalau belum load, panggil load)
    // Sebaiknya pastikan provider accounts terisi.
    
    setState(() {
      _categoryList = cats;
      
      // LOGIKA PRE-SELECT DROPDOWN SAAT EDIT
      if (_isEditMode) {
        final trx = widget.transactionToEdit!;
        
        // Cari object Category yang ID-nya sama
        try {
          _selectedCategory = _categoryList.firstWhere((c) => c.id == trx.categoryId);
        } catch (_) {}

        // Cari object Account yang ID-nya sama
        try {
          _selectedAccount = provider.accounts.firstWhere((a) => a.id == trx.accountId);
        } catch (_) {}
      }
    });
  }

  // Fungsi Ambil Foto
  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(source: source, imageQuality: 50);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil Foto (Kamera)'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi Simpan
  void _saveTransaction() async {
    if (_formKey.currentState!.validate() && _selectedCategory != null && _selectedAccount != null) {
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      final prefs = await SharedPreferences.getInstance();
      final int userId = prefs.getInt('user_id') ?? 0;
      
      final trx = TransactionModel(
        id: _isEditMode ? widget.transactionToEdit!.id : null, // ID wajib ada saat Update
        userId: userId,
        accountId: _selectedAccount!.id!,
        categoryId: _selectedCategory!.id!,
        type: _type,
        amount: double.parse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')),
        date: _selectedDate.toIso8601String(),
        title: _titleController.text,
        description: _descController.text,
        imagePath: _selectedImage?.path,
      );

      if (_isEditMode) {
        // PANGGIL FUNGSI UPDATE (Kita buat di step 3)
        await provider.updateTransaction(trx);
        if (mounted) Navigator.pop(context, true); // Return true agar refresh
      } else {
        await provider.addTransaction(trx);
        if (mounted) Navigator.pop(context);
      }
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mohon lengkapi data transaksi")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = Provider.of<DashboardProvider>(context, listen: false).accounts;

    return Scaffold(
      appBar: AppBar(
        title: Text(_type == 'income' ? "Tambah Pemasukan" : "Tambah Pengeluaran"),
        backgroundColor: _type == 'income' ? Colors.green : Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Input Nominal
              const Text("Nominal", style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 24, color: _type == 'income' ? Colors.green : Colors.red),
                decoration: const InputDecoration(
                  prefixText: "Rp ",
                  hintText: "0",
                  border: UnderlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 20),

              // 2. NAMA TRANSAKSI (Judul)
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Nama Transaksi",
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? "Nama transaksi wajib diisi" : null,
              ),
              const SizedBox(height: 16),

              // 3. Pilih Rekening (Dropdown) dan Kategrori (Dropdown)

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<Account>(
                      value: _selectedAccount,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: "Rekening", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15)),
                      items: accounts.map((acc) => DropdownMenuItem(value: acc, child: Text(acc.name, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) => setState(() => _selectedAccount = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<Category>(
                      value: _selectedCategory,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: "Kategori", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15)),
                      items: _categoryList.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Row(
                            children: [
                              Icon(
                                () {
                                  try {
                                    return IconData(int.parse(cat.iconCode), fontFamily: 'MaterialIcons');
                                  } catch (_) {
                                    return Icons.category;
                                  }
                                }(),
                                size: 16
                              ),
                              const SizedBox(width: 8),
                              Text(cat.name, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Tanggal
              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Tanggal Transaksi",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                      _dateController.text = DateFormat('dd MMM yyyy').format(picked);
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // 5. Keterangan (Opsional)
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: "Keterangan (Opsional)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              // 6. UPLOAD FOTO (Area Kotak)
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 40, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text("Tambah Foto / Nota (Opsional)", style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                ),
              ),
              
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _type == 'income' ? Colors.green : Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _saveTransaction,
                  child: Text(_isEditMode ? "Update" : "Simpan", style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}