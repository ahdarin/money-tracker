import 'package:flutter/material.dart';
import 'package:moneytracker/ui/add_account_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/account_provider.dart';
import '../../providers/dashboard_provider.dart'; 
class ManageAccountsScreen extends StatefulWidget {
  const ManageAccountsScreen({super.key});

  @override
  State<ManageAccountsScreen> createState() => _ManageAccountsScreenState();
}

class _ManageAccountsScreenState extends State<ManageAccountsScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AccountProvider>(context, listen: false).loadAccounts();
    });
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'bank': return Icons.account_balance;
      case 'cash': return Icons.wallet;
      case 'e-wallet': return Icons.smartphone;
      case 'kartu kredit': return Icons.credit_card;
      case 'investasi': return Icons.trending_up;
      default: return Icons.account_balance_wallet;
    }
  }

  void _deleteAccount(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Rekening?"),
        content: const Text("Semua riwayat transaksi dari rekening ini juga akan DIHAPUS permanen. Lanjutkan?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<AccountProvider>(context, listen: false).deleteAccount(id);
              if (mounted) {
                Provider.of<DashboardProvider>(context, listen: false).loadDashboardData();
              }
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kelola Rekening")),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditAccountScreen()))
              .then((_) {
                Provider.of<AccountProvider>(context, listen: false).loadAccounts();
                Provider.of<DashboardProvider>(context, listen: false).loadDashboardData();
              });
        },
        child: const Icon(Icons.add),
      ),

      body: Consumer<AccountProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          if (provider.accounts.isEmpty) return const Center(child: Text("Belum ada rekening"));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.accounts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final acc = provider.accounts[index];
              final isNegative = acc.balance < 0;

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 4), // Padding vertikal sedikit biar lega
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
                  ],
                ),
                child: ListTile(
                  // 1. Icon Kiri
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: Icon(_getIconForType(acc.type), color: Colors.blue),
                  ),
                  
                  // 2. Info Kiri (Nama & Tipe)
                  title: Text(acc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(acc.type, style: const TextStyle(fontSize: 12)),
                  
                  // 3. Info Kanan (Saldo & Tombol)
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end, // Rata Kanan
                    mainAxisSize: MainAxisSize.min, // Agar tidak makan tinggi berlebih
                    children: [
                      // A. Saldo
                      Text(
                        currencyFormat.format(acc.balance),
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: isNegative ? Colors.red : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                          fontSize: 14
                        ),
                      ),
                      
                      const SizedBox(height: 8), // Jarak vertikal antara saldo dan tombol

                      // B. Row Tombol Kecil
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Tombol Edit
                          InkWell(
                            onTap: () {
                               Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditAccountScreen(accountToEdit: acc)))
                                    .then((_) {
                                       provider.loadAccounts();
                                       Provider.of<DashboardProvider>(context, listen: false).loadDashboardData();
                                    });
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0), // Area sentuh aman
                              child: const Icon(Icons.edit, size: 18, color: Colors.blue),
                            ),
                          ),
                          
                          const SizedBox(width: 8),

                          // Tombol Hapus
                          InkWell(
                            onTap: () => _deleteAccount(acc.id!),
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0), // Area sentuh aman
                              child: const Icon(Icons.delete, size: 18, color: Colors.red),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}