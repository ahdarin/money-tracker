import 'package:flutter/material.dart';
import 'package:moneytracker/models/account.dart';
import 'package:provider/provider.dart';
import '../../providers/account_provider.dart';

class AddEditAccountScreen extends StatefulWidget {
  final Account? accountToEdit;

  const AddEditAccountScreen({super.key, this.accountToEdit});

  @override
  State<AddEditAccountScreen> createState() => _AddEditAccountScreenState();
}

class _AddEditAccountScreenState extends State<AddEditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _balanceCtrl;
  
  String _selectedType = 'Bank'; // Default
  final List<String> _types = ['Bank', 'Cash', 'E-Wallet', 'Kartu Kredit', 'Investasi'];

  @override
  void initState() {
    super.initState();
    if (widget.accountToEdit != null) {
      _nameCtrl = TextEditingController(text: widget.accountToEdit!.name);
      // Saldo ditampilkan tanpa format currency biar mudah diedit angka saja
      _balanceCtrl = TextEditingController(text: widget.accountToEdit!.balance.toStringAsFixed(0));
      _selectedType = widget.accountToEdit!.type;
    } else {
      _nameCtrl = TextEditingController();
      _balanceCtrl = TextEditingController();
    }
  }

  void _saveAccount() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<AccountProvider>(context, listen: false);
      final double balance = double.tryParse(_balanceCtrl.text.replaceAll(RegExp(r'[^0-9-]'), '')) ?? 0;

      if (widget.accountToEdit != null) {
        // UPDATE
        final updatedAcc = Account(
          id: widget.accountToEdit!.id,
          userId: widget.accountToEdit!.userId,
          name: _nameCtrl.text,
          type: _selectedType,
          balance: balance,
          lastUsed: widget.accountToEdit!.lastUsed,
        );
        await provider.updateAccount(updatedAcc);
      } else {
        // CREATE
        await provider.addAccount(_nameCtrl.text, _selectedType, balance);
      }

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.accountToEdit != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "Edit Rekening" : "Rekening Baru")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 1. Nama Rekening
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Nama Rekening",
                  hintText: "Cth: BCA, Dompet Utama",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance_wallet),
                ),
                validator: (val) => val!.isEmpty ? "Nama wajib diisi" : null,
              ),
              const SizedBox(height: 20),

              // 2. Tipe Rekening (Dropdown)
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: "Jenis Rekening", border: OutlineInputBorder(), prefixIcon: Icon(Icons.category)),
                items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
              const SizedBox(height: 20),

              // 3. Saldo Saat Ini
              TextFormField(
                controller: _balanceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Saldo Saat Ini",
                  prefixText: "Rp ",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (val) => val!.isEmpty ? "Saldo wajib diisi" : null,
              ),
              const SizedBox(height: 10),
              if (isEdit) 
                const Text(
                  "Perhatian: Mengubah saldo di sini tidak akan mencatat riwayat transaksi (Manual adjustment).",
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveAccount,
                  child: Text(isEdit ? "UPDATE REKENING" : "SIMPAN REKENING"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}