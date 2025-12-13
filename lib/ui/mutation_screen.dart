import 'package:flutter/material.dart';
import 'package:moneytracker/models/transaction_model.dart';
import 'package:moneytracker/ui/transaction_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/mutation_provider.dart';

class MutationScreen extends StatefulWidget {
  const MutationScreen({super.key});

  @override
  State<MutationScreen> createState() => _MutationScreenState();
}

class _MutationScreenState extends State<MutationScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    // Load data awal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MutationProvider>(context, listen: false).loadMutations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mutasi Rekening"),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. FILTER SECTION (Search & Chips)
          _buildFilterSection(),
          
          const Divider(height: 1),

          // 2. LIST TRANSAKSI
          Expanded(
            child: Consumer<MutationProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) return const Center(child: CircularProgressIndicator());
                if (provider.transactions.isEmpty) {
                  return const Center(child: Text("Tidak ada transaksi ditemukan"));
                }

                // Logic Grouping per Hari
                return ListView.builder(
                  itemCount: provider.transactions.length,
                  itemBuilder: (context, index) {
                    final trx = provider.transactions[index];
                    final date = DateTime.parse(trx.date);
                    
                    // Cek apakah perlu menampilkan Header Tanggal?
                    bool showHeader = true;
                    if (index > 0) {
                      final prevTrx = provider.transactions[index - 1];
                      final prevDate = DateTime.parse(prevTrx.date);
                      // Jika tanggal sama dengan item sebelumnya, sembunyikan header
                      if (date.year == prevDate.year && date.month == prevDate.month && date.day == prevDate.day) {
                        showHeader = false;
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showHeader) _buildDateHeader(date),
                        _buildTransactionTile(trx, provider),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final provider = Provider.of<MutationProvider>(context);
    
    // Helper untuk cari nama kategori berdasarkan ID (untuk hint dropdown jika null)
    // Atau dropdown otomatis handle value.

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. SEARCH BAR (Nama Transaksi)
          TextField(
            decoration: InputDecoration(
              hintText: "Cari nama transaksi...",
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[50],
            ),
            onChanged: (val) => provider.setSearchQuery(val),
          ),
          
          const SizedBox(height: 12),

          // 2. BARIS KEDUA: TANGGAL & KATEGORI
          Row(
            children: [
              // A. DATE PICKER (Expanded)
              Expanded(
                flex: 4,
                child: InkWell(
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      initialDateRange: provider.dateRange,
                    );
                    if (picked != null) provider.setDateRange(picked);
                  },
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            provider.dateRange == null 
                              ? "Pilih Tanggal" 
                              : "${dateFormat.format(provider.dateRange!.start)} - ${dateFormat.format(provider.dateRange!.end)}",
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 10),

              // B. CATEGORY DROPDOWN (Expanded)
              Expanded(
                flex: 3,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: provider.selectedCategory,
                      hint: const Text("Kategori", style: TextStyle(fontSize: 12)),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      items: [
                        // Opsi Reset/Semua
                        const DropdownMenuItem(
                          value: null,
                          child: Text("Semua", style: TextStyle(fontSize: 12)),
                        ),
                        // List Kategori dari Provider
                        ...provider.filterCategories.map((cat) {
                           // Helper Icon
                           IconData icon;
                           try { icon = IconData(int.parse(cat.iconCode), fontFamily: 'MaterialIcons'); } 
                           catch (_) { icon = Icons.category; }
                           
                           final isExpense = cat.type == 'expense';
                           
                           return DropdownMenuItem(
                             value: cat.id,
                             child: Row(
                               children: [
                                 Icon(icon, 
                                   size: 16, 
                                   color: isExpense ? Colors.redAccent : Colors.green
                                 ),
                                 const SizedBox(width: 8),
                                 Expanded(
                                   child: Text(
                                     cat.name, 
                                     style: const TextStyle(fontSize: 12), 
                                     overflow: TextOverflow.ellipsis
                                   )
                                 ),
                               ],
                             ),
                           );
                        }),
                      ],
                      onChanged: (val) => provider.setCategory(val),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 3. BARIS KETIGA: CHIP TIPE (Scrollable Horizontal jika layar kecil)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip("Semua", "all", provider),
                const SizedBox(width: 8),
                _buildFilterChip("Pemasukan", "income", provider),
                const SizedBox(width: 8),
                _buildFilterChip("Pengeluaran", "expense", provider),
                const SizedBox(width: 8),
                _buildFilterChip("Transfer", "transfer", provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, MutationProvider provider) {
    final isSelected = provider.filterType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      onSelected: (selected) {
        if (selected) provider.setFilterType(value);
      },
      selectedColor: Colors.blue.shade100,
      labelStyle: TextStyle(color: isSelected ? Colors.blue.shade900 : Theme.of(context).textTheme.bodyMedium?.color),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      // color: Colors.grey[100],
      child: Text(
        dateFormat.format(date),
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
      ),
    );
  }

  Widget _buildTransactionTile(TransactionModel trx, MutationProvider provider) {
    // TENTUKAN WARNA & LOGIC
    final isTransfer = trx.type == 'transfer';
    final isExpense = trx.type == 'expense';
    
    // Warna: Transfer = Biru, Expense = Merah, Income = Hijau
    final color = isTransfer 
        ? Colors.blue 
        : (isExpense ? Colors.redAccent : Colors.green);
    
    // Icon: Transfer = Swap, Expense = Panah Atas, Income = Panah Bawah
    final icon = isTransfer 
        ? Icons.swap_horiz 
        : (isExpense ? Icons.arrow_upward : Icons.arrow_downward);

    // Subtitle Text: Jika transfer, tampilkan "Ke: [Nama Rekening Tujuan]"
    String subtitleText = "${trx.categoryName} • ${trx.accountName}";
    if (isTransfer) {
       subtitleText = "Ke: ${trx.transferAccountName ?? 'Rekening Tujuan'}";
    }
    
    return ListTile(
      onTap: () {
        // NAVIGASI KE DETAIL
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionDetailScreen(transaction: trx),
          ),
        ).then((_) {
          // Refresh list saat kembali (kali aja ada yang dihapus/diedit)
          provider.loadMutations();
        });
      },
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(trx.title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitleText, maxLines: 1),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currencyFormat.format(trx.amount),
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        ],
      ),
    );
  }
}