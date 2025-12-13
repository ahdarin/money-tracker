import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/statistics_provider.dart';

class StatScreen extends StatefulWidget {
  const StatScreen({super.key});

  @override
  State<StatScreen> createState() => _StatScreenState();
}

class _StatScreenState extends State<StatScreen> {
  final currencyFormat = NumberFormat.compactSimpleCurrency(locale: 'id_ID'); // Format singkat (1jt, 500rb)

  @override
  void initState() {
    super.initState();
    // Load data saat masuk halaman
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StatisticsProvider>(context, listen: false).loadStatsData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Statistik Keuangan"), centerTitle: true),
      body: Consumer<StatisticsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. TOP SPENDING GRID
                const Text("Pengeluaran Terbanyak", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildSpendingGrid(provider.topCategories),

                const SizedBox(height: 30),

                // 2. WEEKLY BAR CHART
                const Text("Statistik Mingguan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildWeeklyChart(provider.weeklyData),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpendingGrid(List<Map<String, dynamic>> categories) {
    if (categories.isEmpty) return const Text("Belum ada pengeluaran minggu ini.");

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 kolom sesuai desain
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final item = categories[index];
        final amount = (item['total'] as num).toDouble();
        final iconCode = item['icon_code'];
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            // border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                currencyFormat.format(amount),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent),
              ),
              const SizedBox(height: 8),
              Icon(
                () {
                  try {
                    return iconCode != null 
                      ? IconData(int.parse(iconCode), fontFamily: 'MaterialIcons') 
                      : Icons.category;
                  } catch (_) {
                    return Icons.category; // Fallback aman
                  }
                }(),
                color: Colors.grey,
              ),
              const SizedBox(height: 4),
              Text(item['name'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeeklyChart(List<DailySummary> data) {
    if (data.every((e) => e.income == 0 && e.expense == 0)) {
       return const SizedBox(
         height: 200, 
         child: Center(child: Text("Belum ada data 7 hari terakhir"))
       );
    }
  
    // Cari nilai maksimum untuk skala Y chart
    double maxY = 0;
    for (var d in data) {
      if (d.income > maxY) maxY = d.income;
      if (d.expense > maxY) maxY = d.expense;
    }
    // Tambah buffer sedikit di atas
    maxY = maxY * 1.2;

    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                 return BarTooltipItem(
                   currencyFormat.format(rod.toY),
                   const TextStyle(color: Colors.white),
                 );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < data.length) {
                    // Tampilkan Hari (Sen, Sel, Rab)
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat.E('id_ID').format(data[index].date), // Butuh inisialisasi date locale di main.dart
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Sembunyikan angka kiri
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: data.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                // Batang Pengeluaran (Merah)
                BarChartRodData(
                  toY: item.expense,
                  color: Colors.redAccent,
                  width: 10,
                  borderRadius: BorderRadius.circular(4),
                ),
                // Batang Pemasukan (Hijau)
                BarChartRodData(
                  toY: item.income,
                  color: Colors.green,
                  width: 10,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}