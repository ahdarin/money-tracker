import 'package:flutter/material.dart';
import 'package:moneytracker/models/account.dart';
import 'package:moneytracker/models/transaction_model.dart';
import 'package:moneytracker/providers/auth_provider.dart';
import 'package:moneytracker/ui/mutation_screen.dart';
import 'package:moneytracker/ui/profile_screen.dart';
import 'package:moneytracker/ui/statistic_screen.dart';
import 'package:moneytracker/ui/transfer_screen.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../providers/dashboard_provider.dart';
import 'add_transaction_screen.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // 1. DAFTAR HALAMAN
  // Halaman-halaman yang akan muncul saat menu bawah diklik
  final List<Widget> _pages = [
    const DashboardContent(),        // Index 0: Dashboard (Widget di bawah)
    const StatScreen(),              // Index 1: Statistik
    const SizedBox(),                // Index 2: Placeholder (Tombol + pakai Modal)
    const MutationScreen(),          // Index 3: Mutasi Rekening 
    const ProfileScreen(),           // Index 4: Profil
  ];

  @override
  void initState() {
    super.initState();
    // Memanggil data database saat aplikasi dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).loadDashboardData();
    });
  }

  // 2. LOGIC TOMBOL TAMBAH (+)
  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 250,
          child: Column(
            children: [
              Container(width: 40, height: 4, color: Colors.grey[300], margin: const EdgeInsets.only(bottom: 20)),
              const Text("Tambah Catatan Baru", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildOptionBtn(Icons.arrow_downward, "Pemasukan", Colors.green, () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen(initialType: 'income')));
                  }),
                  _buildOptionBtn(Icons.arrow_upward, "Pengeluaran", Colors.redAccent, () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen(initialType: 'expense')));
                  }),
                  _buildOptionBtn(Icons.swap_horiz, "Transfer", Colors.blue, () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferScreen()));
                  }),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // Logic Navigasi
  void _onBottomNavTapped(int index) {
    if (index == 2) {
      _showAddOptions(); // Buka Modal jika tombol tengah
    } else {
      setState(() {
        _selectedIndex = index; // Pindah Halaman
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // BODY DINAMIS: Berubah sesuai index yang dipilih
      body: _pages[_selectedIndex], 

      // BOTTOM NAVIGATION BAR
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Statistik'),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.add, color: Colors.white),
            ),
            label: '',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Mutasi'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

// ==============================================================================
// WIDGET KONTEN DASHBOARD (DIPISAH AGAR RAPI)
// ==============================================================================

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {

    final authProvider = Provider.of<AuthProvider>(context);
    // Ambil nama, jika null (belum load) pakai "Pengguna"
    final String userName = authProvider.currentUser?.name ?? "Pengguna";
    
    // Formatter Lokal
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('d MMM yyyy', 'id_ID');

    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        
        // Hitung Data Summary
        final double income = provider.summary['income'] ?? 0;
        final double expense = provider.summary['expense'] ?? 0;

        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER USER
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Selamat Datang,", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    Text(userName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              // 2. BOX SUMMARY (Chart)
              _buildSummaryBox(context, income, expense, currencyFormat, dateFormat),

              const SizedBox(height: 20),

              // 3. CAROUSEL REKENING
              provider.accounts.isEmpty 
                  ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Belum ada rekening")))
                  : _buildAccountCarousel(provider.accounts, currencyFormat, dateFormat),

              const SizedBox(height: 20),

              // 4. HEADER TRANSAKSI
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Transaksi Terakhir", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              // 5. LIST TRANSAKSI (SCROLLABLE)
              Expanded(
                child: provider.recentTransactions.isEmpty
                    ? Center(child: Text("Belum ada transaksi", style: TextStyle(color: Colors.grey[400])))
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: provider.recentTransactions.length,
                        itemBuilder: (context, index) {
                          final trx = provider.recentTransactions[index];
                          return _buildTransactionItem(context, trx, currencyFormat, dateFormat);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- COMPONENT BUILDERS (MILIK DASHBOARD CONTENT) ---

  Widget _buildSummaryBox(BuildContext context, double income, double expense, NumberFormat fmt, DateFormat df) {
    bool isEmpty = income == 0 && expense == 0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(children: [Text(DateFormat('MMM yyyy', 'id_ID').format(DateTime.now()), style: TextStyle(fontWeight: FontWeight.w600))]),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                height: 100, width: 100,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 0, centerSpaceRadius: 20,
                    sections: isEmpty 
                      ? [PieChartSectionData(color: Colors.grey.shade300, value: 1, radius: 35, title: '')]
                      : [
                          if (expense > 0) PieChartSectionData(color: Colors.redAccent, value: expense, radius: 35, title: ''),
                          if (income > 0) PieChartSectionData(color: Colors.green, value: income, radius: 35, title: ''),
                        ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildLegendItem(Colors.green, "Pemasukan", income, fmt),
                    const SizedBox(height: 12),
                    _buildLegendItem(Colors.redAccent, "Pengeluaran", expense, fmt),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, double amount, NumberFormat fmt) {
    return Row(
      children: [
        CircleAvatar(backgroundColor: color, radius: 6),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(fmt.format(amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ])
      ],
    );
  }

  Widget _buildAccountCarousel(List<Account> accounts, NumberFormat fmt, DateFormat df) {
    return SizedBox(
      height: 110,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.85),
        padEnds: false,
        itemCount: accounts.length,
        itemBuilder: (context, index) {
          final acc = accounts[index];
          String lastUsedStr = "-";
          try {
             lastUsedStr = df.format(DateTime.parse(acc.lastUsed));
          } catch (_) {}

          return Container(
            margin: EdgeInsets.only(left: index == 0 ? 20 : 8, right: index == accounts.length - 1 ? 20 : 0, bottom: 5),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[800],
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.blue.shade600], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(acc.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)), child: Text(acc.type, style: const TextStyle(color: Colors.white, fontSize: 10)))
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(fmt.format(acc.balance), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("Terakhir: $lastUsedStr", style: TextStyle(color: Colors.blue[100], fontSize: 11)),
                ])
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, TransactionModel trx, NumberFormat fmt, DateFormat df) {
    // 1. LOGIKA TIPE TRANSAKSI
    final isTransfer = trx.type == 'transfer'; // Cek apakah transfer
    final isExpense = trx.type == 'expense';
    
    // 2. TENTUKAN WARNA
    // Transfer = Biru, Pengeluaran = Merah, Pemasukan = Hijau
    final color = isTransfer 
        ? Colors.blue 
        : (isExpense ? Colors.redAccent : Colors.green);
    
    // 3. TENTUKAN PREFIX SIGN (+ / -)
    // Transfer kita buat netral (tanpa tanda) atau bisa "-" jika dianggap uang keluar
    final sign = isTransfer ? "" : (isExpense ? "- " : "+ ");
    
    DateTime dateObj = DateTime.parse(trx.date);
    
    // 4. TENTUKAN ICON
    IconData icon;
    if (isTransfer) {
      icon = Icons.swap_horiz;
    } else {
      try {
        icon = IconData(int.parse(trx.categoryIconCode ?? '0'), fontFamily: 'MaterialIcons');
      } catch (_) {
        icon = isExpense ? Icons.shopping_bag_outlined : Icons.attach_money;
      }
    }
    
    // 5. TENTUKAN SUBTITLE (Info tambahan)
    String subtitle = "${trx.categoryName ?? 'Umum'} • ${trx.accountName ?? 'Rekening'}";
    if (isTransfer) {
      subtitle = "${trx.accountName ?? 'Asal'} > ${trx.transferAccountName ?? 'Tujuan'}";
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: Colors.grey.withOpacity(0.2))
      ),
      child: Row(
        children: [
          // ICON
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          
          // TEXT INFO
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                trx.title, 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle, // <-- Subtitle dinamis (menampilkan tujuan jika transfer)
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              if (trx.imagePath != null)
                 Padding(
                   padding: const EdgeInsets.only(top: 4),
                   child: Row(children: [
                     Icon(Icons.image, size: 12, color: Colors.blue[300]),
                     const SizedBox(width: 4),
                     Text("Ada Foto", style: TextStyle(fontSize: 10, color: Colors.blue[300]))
                   ]),
                 )
          ])),
          
          // NOMINAL & TANGGAL
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text("$sign${fmt.format(trx.amount)}", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(df.format(dateObj), style: TextStyle(color: Colors.grey[400], fontSize: 11)),
          ]),
          const SizedBox(width: 12),
          
          // GARIS WARNA SAMPING
          Container(width: 4, height: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        ],
      ),
    );
  }
}