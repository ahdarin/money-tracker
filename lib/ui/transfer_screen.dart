import 'package:flutter/material.dart';
import 'package:moneytracker/models/account.dart';
import 'package:moneytracker/models/transaction_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/dashboard_provider.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  Account? _sourceAccount;
  Account? _destAccount;
  
  // Kita butuh ID Kategori dummy untuk transfer (agar tidak error FK di database)
  // Nanti saat init kita cari kategori 'Lainnya' atau 'Transfer' jika ada, atau ambil sembarang.
  // Untuk tutorial ini kita ambil kategori pertama yang ada saja sebagai placeholder.
  int? _dummyCategoryId;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd MMM yyyy').format(_selectedDate);
    _loadInitialData();
  }

  void _loadInitialData() async {
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    // Pastikan kategori terload untuk ambil dummy ID
    final cats = await provider.fetchCategories('expense'); 
    if (cats.isNotEmpty) {
      _dummyCategoryId = cats.first.id; 
    }
  }

  void _saveTransfer() async {
    if (_formKey.currentState!.validate() && _sourceAccount != null && _destAccount != null) {
      
      // Validasi: Rekening asal dan tujuan tidak boleh sama
      if (_sourceAccount!.id == _destAccount!.id) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rekening asal dan tujuan tidak boleh sama")));
        return;
      }

      final provider = Provider.of<DashboardProvider>(context, listen: false);
      final prefs = await SharedPreferences.getInstance();
      final int userId = prefs.getInt('user_id') ?? 0;
      
      final trx = TransactionModel(
        userId: userId,
        accountId: _sourceAccount!.id!,
        transferAccountId: _destAccount!.id!, // ID Tujuan
        categoryId: _dummyCategoryId ?? 1, // ID Placeholder
        type: 'transfer', // TIPE TRANSFER
        amount: double.parse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')),
        date: _selectedDate.toIso8601String(),
        title: 'Transfer Dana', // Judul Otomatis
        description: _descController.text.isEmpty ? "Ke ${_destAccount!.name}" : _descController.text,
      );

      await provider.addTransaction(trx);
      if (mounted) Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mohon lengkapi data")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = Provider.of<DashboardProvider>(context).accounts;
    const color = Colors.blue; // Warna Utama Transfer

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pindah Rekening"),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. INPUT NOMINAL
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
                decoration: const InputDecoration(
                  prefixText: "Rp ",
                  hintText: "0",
                  border: InputBorder.none,
                ),
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),
              const Divider(thickness: 1),
              const SizedBox(height: 16),

              // 2. DARI REKENING (Source)
              DropdownButtonFormField<Account>(
                value: _sourceAccount,
                decoration: const InputDecoration(
                  labelText: "Dari Rekening (Sumber)", 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.arrow_upward, color: Colors.red),
                ),
                items: accounts.map((acc) => DropdownMenuItem(value: acc, child: Text("${acc.name} (${NumberFormat.compact().format(acc.balance)})"))).toList(),
                onChanged: (val) => setState(() => _sourceAccount = val),
              ),
              const SizedBox(height: 16),

              // 3. KE REKENING (Destination)
              DropdownButtonFormField<Account>(
                value: _destAccount,
                decoration: const InputDecoration(
                  labelText: "Ke Rekening (Tujuan)", 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.arrow_downward, color: Colors.green),
                ),
                items: accounts.map((acc) => DropdownMenuItem(value: acc, child: Text(acc.name))).toList(),
                onChanged: (val) => setState(() => _destAccount = val),
              ),
              const SizedBox(height: 16),

              // 4. TANGGAL
              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: const InputDecoration(labelText: "Tanggal", border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context, 
                    initialDate: _selectedDate, 
                    firstDate: DateTime(2020), 
                    lastDate: DateTime(2030)
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

              // 5. CATATAN
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: "Catatan (Opsional)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.note)),
              ),
              
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
                  onPressed: _saveTransfer,
                  child: const Text("TRANSFER SEKARANG", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}