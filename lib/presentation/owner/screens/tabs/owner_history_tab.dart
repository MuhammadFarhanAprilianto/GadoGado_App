import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/pdf_report_generator.dart';
import '../../providers/owner_navigation_provider.dart';
import '../../viewmodels/owner_view_model.dart';
import '../../../auth/viewmodels/auth_viewmodel.dart';
import '../../../admin/viewmodels/admin_view_model.dart';

class OwnerHistoryTab extends StatelessWidget {
  const OwnerHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ownerVM = context.watch<OwnerViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final adminVM = context.watch<AdminViewModel>();
    final user = authVM.currentUser;
    final double chartMaxY = ownerVM.maxWeeklySales > 0 ? ownerVM.maxWeeklySales * 1.2 : 100000;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Image.asset(
            'assets/images/WARUNG.png',
            height: 40,
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          // PDF Print Button
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Tooltip(
              message: 'Cetak Laporan PDF',
              child: IconButton(
                onPressed: () => _showPrintBottomSheet(context, ownerVM),
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 20),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 4.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: user?.profileImageProvider,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ownerVM.refreshDashboard(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ikhtisar Kinerja', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 8),
              _buildPeriodSelector(ownerVM),
              const SizedBox(height: 24),

              // Revenue Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1A1A1A), Color(0xFF424242)]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Pendapatan', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text(
                    'Rp ${(ownerVM.totalRevenue / 1000).toStringAsFixed(0)}k', 
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                       _SummarySmallCard('Total Pesanan', '${ownerVM.totalOrders}'),
                       const SizedBox(width: 12),
                       _SummarySmallCard('Rata-rata Transaksi', 'Rp ${(ownerVM.avgCheck / 1000).toStringAsFixed(1)}k'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tren Mingguan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Icon(Icons.show_chart, color: Colors.grey),
              ],
            ),
            Text(ownerVM.revenueTrend, style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            // Weekly Chart
            SizedBox(
              height: 200,
              child: ClipRect(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: chartMaxY,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AppColors.primary,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            'Rp ${(rod.toY / 1000).toStringAsFixed(0)}k',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                            const titles = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
                            if (value.toInt() < 0 || value.toInt() >= titles.length) return const SizedBox();
                            return Text(titles[value.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 10));
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(ownerVM.weeklySales.length, (index) {
                      return _buildBarGroup(index, ownerVM.weeklySales[index], chartMaxY);
                    }),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            const Text('Produk Terlaris', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            
              ...ownerVM.topItems.map((item) => _buildTopItem(
                item['title'], 
                item['subtitle'], 
                item['tag'], 
                item['tagColor'],
              )),
              
              const SizedBox(height: 32),
              _buildPulseSection(context, ownerVM, adminVM),
              const SizedBox(height: 32),
              const Text('Laporan Pendapatan Harian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              if (ownerVM.laporanList.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('Belum ada laporan pendapatan harian.', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ...ownerVM.laporanList.map((laporan) {
                  final DateTime tanggal = laporan['tanggal'] as DateTime;
                  final formatTanggal = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(tanggal);
                  final double totalPemasukan = laporan['total_pemasukan'] as double;
                  final int jumlahOrder = laporan['jumlah_order'] as int;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.01),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatTanggal,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$jumlahOrder pesanan selesai',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                        Text(
                          'Rp ${NumberFormat('#,###', 'id_ID').format(totalPemasukan)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(OwnerViewModel vm) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildPeriodButton(vm, 'day', 'Harian'),
          _buildPeriodButton(vm, 'week', 'Mingguan'),
          _buildPeriodButton(vm, 'month', 'Bulanan'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(OwnerViewModel vm, String period, String label) {
    final isSelected = vm.selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () => vm.setPeriod(period),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.primary : Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPulseSection(BuildContext context, OwnerViewModel ownerVM, AdminViewModel adminVM) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Aktivitas Hari Ini", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              _buildPulseItem(
                icon: Icons.inventory_2_outlined, 
                color: Colors.blue, 
                label: 'Stok Kritis', 
                value: '${adminVM.lowStockCount} Bahan Menipis',
                onTap: () => context.read<OwnerNavigationProvider>().setIndex(2),
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
              _buildPulseItem(
                icon: Icons.timer_outlined, 
                color: Colors.orange, 
                label: 'Rata-rata Waktu Masak', 
                value: '${ownerVM.avgPrepTime} menit',
                onTap: () => _showPrepTimeDetails(context, ownerVM),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPulseItem({
    required IconData icon, 
    required Color color, 
    required String label, 
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  void _showPrepTimeDetails(BuildContext context, OwnerViewModel vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.timer_outlined, color: Colors.orange),
            SizedBox(width: 12),
            Text('Detail Waktu Persiapan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Analisis Kinerja:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildDialogStat('Rata-rata Saat Ini', '${vm.avgPrepTime} menit'),
            _buildDialogStat('Target Rata-rata', '10 menit'),
            _buildDialogStat('Efisiensi', vm.avgPrepTime <= 10 ? 'SANGAT BAIK' : 'PERLU PENINGKATAN'),
            const SizedBox(height: 16),
            const Text(
              'Dihitung sejak pesanan dibuat hingga statusnya berubah menjadi "Siap disajikan" atau "Selesai".',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup', style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
  }

  Widget _buildDialogStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, double maxY) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AppColors.primary,
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true, 
            toY: maxY, 
            color: Colors.grey.shade100,
          ),
        ),
      ],
    );
  }

  Widget _buildTopItem(String title, String subtitle, String tag, Color tagColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
        child: Row(
          children: [
            Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.fastfood, color: AppColors.primary)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: tagColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(tag, style: TextStyle(color: tagColor, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ──────────────────────────────────────────────────────────
  // PDF PRINT BOTTOM SHEET
  // ──────────────────────────────────────────────────────────

  void _showPrintBottomSheet(BuildContext context, OwnerViewModel vm) {
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

    String _periodName(String p) {
      if (p == 'day') return 'Harian';
      if (p == 'week') return 'Mingguan';
      return 'Bulanan';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cetak Laporan PDF', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      Text('Generate laporan penjualan', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Divider(color: Colors.grey.shade100),
              const SizedBox(height: 16),

              // Period info
              _buildInfoRow(
                icon: Icons.calendar_today_rounded,
                label: 'Periode Laporan',
                value: _periodName(vm.selectedPeriod),
              ),
              const SizedBox(height: 10),
              _buildInfoRow(
                icon: Icons.date_range_rounded,
                label: 'Rentang Tanggal',
                value: (vm.filterStartDate != null && vm.filterEndDate != null)
                    ? '${dateFormat.format(vm.filterStartDate!)} – ${dateFormat.format(vm.filterEndDate!)}'
                    : 'Semua waktu',
              ),
              const SizedBox(height: 10),
              _buildInfoRow(
                icon: Icons.receipt_long_rounded,
                label: 'Jumlah Transaksi',
                value: '${vm.filteredOrders.length} pesanan',
              ),
              const SizedBox(height: 10),
              _buildInfoRow(
                icon: Icons.attach_money_rounded,
                label: 'Total Pendapatan',
                value: 'Rp ${NumberFormat("#,###", "id_ID").format(vm.totalRevenue)}',
                highlight: true,
              ),

              const SizedBox(height: 24),

              // Info tip
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.blue.shade400, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'PDF dapat langsung dibagikan via WhatsApp/Email atau disimpan ke perangkat.',
                        style: TextStyle(color: Colors.blue.shade700, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _generateAndPrintPdf(context, vm);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.print_rounded, size: 18),
                      label: const Text('Generate & Pratinjau PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: highlight ? AppColors.primary.withValues(alpha: 0.08) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: highlight ? AppColors.primary : Colors.grey.shade600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: highlight ? AppColors.primary : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _generateAndPrintPdf(BuildContext context, OwnerViewModel vm) async {
    // Show loading snackbar while generating
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Text('Membuat laporan PDF...'),
            ],
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    try {
      final doc = await PdfReportGenerator.generateSalesReport(
        filteredOrders: vm.filteredOrders,
        topItems: vm.topItems,
        period: vm.selectedPeriod,
        startDate: vm.filterStartDate,
        endDate: vm.filterEndDate,
        totalRevenue: vm.totalRevenue,
        totalOrders: vm.totalOrders,
        avgCheck: vm.avgCheck,
        avgRating: vm.avgRating,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        // Open native PDF preview (share/download/print)
        await Printing.layoutPdf(
          onLayout: (_) async => doc.save(),
          name: 'Laporan_Penjualan_${vm.selectedPeriod}_${DateFormat("yyyyMMdd").format(DateTime.now())}.pdf',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat PDF: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

}

class _SummarySmallCard extends StatelessWidget {
  final String label;
  final String value;
  const _SummarySmallCard(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
