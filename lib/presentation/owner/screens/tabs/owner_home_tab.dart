import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/order_model.dart';
import '../../viewmodels/owner_view_model.dart';
import '../../../auth/viewmodels/auth_viewmodel.dart';
import 'package:gado_gado_app/presentation/admin/viewmodels/admin_view_model.dart';
import 'package:gado_gado_app/presentation/admin/screens/restock_ingredient_screen.dart';
import 'package:gado_gado_app/presentation/admin/screens/admin_order_details_screen.dart';

class OwnerHomeTab extends StatelessWidget {
  const OwnerHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ownerVM = context.watch<OwnerViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final adminVM = context.watch<AdminViewModel>();
    final user = authVM.currentUser;

    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormatter = DateFormat('dd MMM yyyy');

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
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
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
              // Calculate filtered expenses for PnL
              (() {
                final double totalExpenses = adminVM.allExpenses.where((e) {
                  final t = e['timestamp'] as DateTime;
                  bool startMatch = true;
                  bool endMatch = true;
                  if (ownerVM.filterStartDate != null) {
                    startMatch = t.isAfter(ownerVM.filterStartDate!);
                  }
                  if (ownerVM.filterEndDate != null) {
                    endMatch = t.isBefore(ownerVM.filterEndDate!);
                  }
                  return startMatch && endMatch;
                }).fold<double>(0, (sum, e) => sum + e['cost']);
                final double netProfit = ownerVM.totalRevenue - totalExpenses;
                return _buildRevenueCard(ownerVM, currencyFormatter, totalExpenses, netProfit);
              })(),
              const SizedBox(height: 24),
              if (adminVM.lowStockCount > 0) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.red.shade200, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${adminVM.lowStockCount} Bahan Baku Kritis!',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.red),
                                ),
                                const Text(
                                  'Peringatan persediaan kritis. Beberapa bahan baku di bawah batas aman. Hubungi admin gudang atau belanja sekarang.',
                                  style: TextStyle(fontSize: 12, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: adminVM.lowStockIngredients.take(3).map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(
                                '${item.amount} ${item.unit} (Min: ${item.minStockThreshold} ${item.unit})',
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                      if (adminVM.lowStockIngredients.length > 3) ...[
                        const SizedBox(height: 4),
                        Text(
                          '+ ${adminVM.lowStockIngredients.length - 3} bahan baku lainnya...', 
                          style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 11, color: Colors.grey)
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (adminVM.lowStockIngredients.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (c) => RestockIngredientScreen(ingredient: adminVM.lowStockIngredients.first),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 18),
                          label: const Text('Restock Sekarang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              _buildFilterSection(context, ownerVM, dateFormatter),
              const SizedBox(height: 32),
              
              const Text('Transaksi Terbaru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              
              if (ownerVM.filteredOrders.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text('Tidak ada transaksi ditemukan pada periode ini', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ...ownerVM.filteredOrders.take(10).map((order) {
                  Color statusColor = AppColors.success;
                  if (order.status == OrderStatus.cancelled) statusColor = AppColors.error;
                  if (order.status == OrderStatus.pending) statusColor = AppColors.primary;

                  return _buildTransactionItem(
                    id: '#${order.id}', 
                    price: currencyFormatter.format(order.totalAmount), 
                    time: DateFormat('dd MMM, HH:mm').format(order.timestamp), 
                    status: '${order.paymentMethod.name.toUpperCase()} - ${order.status.name.toUpperCase()}', 
                    statusColor: statusColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => AdminOrderDetailsScreen(order: order),
                        ),
                      );
                    },
                  );
                }),
              
              const SizedBox(height: 16),
              const Center(child: Text('Lihat Riwayat Lebih Banyak', style: TextStyle(color: Colors.grey, fontSize: 12, decoration: TextDecoration.underline))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueCard(OwnerViewModel ownerVM, NumberFormat currencyFormatter, double totalExpenses, double netProfit) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Pendapatan & Profitabilitas', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                  Text(
                    'Periode Aktif: ${ownerVM.filterStartDate != null ? DateFormat('dd MMM yyyy').format(ownerVM.filterStartDate!) : '-'}', 
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
              const Icon(Icons.analytics_outlined, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 16),
          
          // Laba Bersih
          Text(
            netProfit >= 0 ? 'LABA BERSIH (NET PROFIT)' : 'RUGI BERSIH (NET LOSS)',
            style: TextStyle(
              color: netProfit >= 0 ? Colors.green.shade800 : Colors.red.shade800,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                currencyFormatter.format(netProfit),
                style: TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.bold,
                  color: netProfit >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: (ownerVM.revenueTrend.contains('+') ? AppColors.success : AppColors.error).withValues(alpha: 0.1), 
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ownerVM.revenueTrend.split(' ').first, 
                  style: TextStyle(
                    color: ownerVM.revenueTrend.contains('+') ? AppColors.success : AppColors.error, 
                    fontSize: 11, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          
          // Breakdown Omzet vs Biaya
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Omzet Kotor', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormatter.format(ownerVM.totalRevenue),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: Colors.grey.shade200),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Biaya Restock', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormatter.format(totalExpenses),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          
          Row(
            children: [
              _buildStatItem('Total Pesanan', '${ownerVM.totalOrders}'),
              const Spacer(),
              _buildStatItem('Rata-rata Transaksi', currencyFormatter.format(ownerVM.avgCheck)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context, OwnerViewModel ownerVM, DateFormat dateFormatter) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF9100), Color(0xFFFF6D00)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          const Text('RENTANG TANGGAL', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                ownerVM.setFilterDateRange(picked.start, picked.end);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ownerVM.filterStartDate != null && ownerVM.filterEndDate != null
                      ? '${dateFormatter.format(ownerVM.filterStartDate!)} - ${dateFormatter.format(ownerVM.filterEndDate!)}'
                      : 'Pilih Rentang Tanggal',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('STATUS', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              _statusChip('Semua', ownerVM.filterStatus == 'All', () => ownerVM.setFilterStatus('All')),
              const SizedBox(width: 8),
              _statusChip('Lunas', ownerVM.filterStatus == 'Paid', () => ownerVM.setFilterStatus('Paid')),
              const SizedBox(width: 8),
              _statusChip('Dibatalkan', ownerVM.filterStatus == 'Cancelled', () => ownerVM.setFilterStatus('Cancelled')),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ownerVM.applyFilters(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1A),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Terapkan Tampilan'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _statusChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? AppColors.primary : Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTransactionItem({
    required String id, 
    required String price, 
    required String time, 
    required String status, 
    required Color statusColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(16), 
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.cardPeach.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.receipt_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            id, 
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(time, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
