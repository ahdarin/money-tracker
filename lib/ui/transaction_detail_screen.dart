import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moneytracker/models/transaction_model.dart';
import 'package:provider/provider.dart';
import '../../providers/mutation_provider.dart';
import 'add_transaction_screen.dart'; 

class TransactionDetailScreen extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('EEEE, d MMMM yyyy HH:mm', 'id_ID');

    // 1. LOGIKA TIPE (Transfer/Expense/Income)
    final isTransfer = transaction.type == 'transfer';
    final isExpense = transaction.type == 'expense';

    // 2. LOGIKA WARNA & ICON
    final color = isTransfer 
        ? Colors.blue 
        : (isExpense ? Colors.redAccent : Colors.green);
        
    final iconMain = isTransfer
        ? Icons.swap_horiz
        : (isExpense ? Icons.arrow_upward : Icons.arrow_downward);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Transaksi"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEdit(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER: Nominal Besar & Icon
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              color: color.withOpacity(0.1),
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 30,
                    child: Icon(iconMain, color: color, size: 30),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    transaction.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(transaction.amount),
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            ),

            // DETAIL LIST
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // A. TANGGAL (Selalu Muncul)
                  _buildDetailItem(Icons.calendar_today, "Tanggal", dateFormat.format(DateTime.parse(transaction.date))),
                  
                  // B. LOGIKA TAMPILAN BERDASARKAN TIPE
                  if (isTransfer) ...[
                    // TAMPILAN KHUSUS TRANSFER (Dari -> Ke)
                    _buildDetailItem(Icons.arrow_upward, "Dari Rekening", transaction.accountName ?? "-"),
                    _buildDetailItem(Icons.arrow_downward, "Ke Rekening", transaction.transferAccountName ?? "-"),
                  ] else ...[
                    // TAMPILAN BIASA (Kategori & Rekening)
                    _buildDetailItem(Icons.category, "Kategori", transaction.categoryName ?? "-"),
                    _buildDetailItem(Icons.account_balance_wallet, "Rekening", transaction.accountName ?? "-"),
                  ],

                  // C. CATATAN (Jika ada)
                  if (transaction.description != null && transaction.description!.isNotEmpty)
                    _buildDetailItem(Icons.notes, "Catatan", transaction.description!),
                  
                  if (!isTransfer) ...[
                    const Divider(height: 40),

                    const Text("Bukti / Nota:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    
                    if (transaction.imagePath != null && File(transaction.imagePath!).existsSync())
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullScreenImageViewer(imagePath: transaction.imagePath!),
                            ),
                          );
                        },
                        child: Hero(
                          tag: 'nota_image',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.file(
                                  File(transaction.imagePath!),
                                  width: double.infinity,
                                  height: 250,
                                  fit: BoxFit.cover,
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.zoom_in, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        height: 100,
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                        child: const Center(child: Text("Tidak ada foto", style: TextStyle(color: Colors.grey))),
                      ),
                  ],
                  
                  const SizedBox(height: 40),

                  // TOMBOL HAPUS
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () => _confirmDelete(context),
                      icon: const Icon(Icons.delete),
                      label: const Text("Hapus Transaksi"),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    // Note: Untuk Transfer, idealnya kita arahkan ke TransferScreen untuk edit.
    // Tapi jika menggunakan AddTransactionScreen, pastikan logic di sana support transfer (cukup kompleks).
    // Untuk tutorial ini, tombol edit akan membuka AddTransactionScreen biasa (mungkin terbatas).
    
    // Jika ingin sempurna, cek tipe dulu:
    if (transaction.type == 'transfer') {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur Edit Transfer belum tersedia, silakan hapus dan buat baru.")));
       return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          initialType: transaction.type,
          transactionToEdit: transaction,
        ),
      ),
    ).then((value) {
      if (value == true) Navigator.pop(context); 
    });
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Transaksi?"),
        content: const Text("Data yang dihapus tidak dapat dikembalikan dan saldo akan disesuaikan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<MutationProvider>(context, listen: false).deleteTrx(transaction.id!);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Transaksi berhasil dihapus")));
              }
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }
}

// FULL SCREEN IMAGE VIEWER (SAMA SEPERTI SEBELUMNYA)
class FullScreenImageViewer extends StatelessWidget {
  final String imagePath;
  const FullScreenImageViewer({super.key, required this.imagePath});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Lihat Nota", style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Hero(
          tag: 'nota_image',
          child: InteractiveViewer(
            panEnabled: true, 
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4,
            child: Image.file(File(imagePath), fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}