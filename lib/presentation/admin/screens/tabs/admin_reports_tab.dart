import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/utils/translator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/order_model.dart';
import 'package:gado_gado_app/presentation/admin/viewmodels/admin_view_model.dart';
import '../../../auth/viewmodels/auth_viewmodel.dart';
import '../admin_order_details_screen.dart';
import '../../../widgets/warung_logo.dart';

class AdminReportsTab extends StatefulWidget {
  const AdminReportsTab({super.key});

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  String _selectedPeriod = 'day'; // 'day', 'week', 'month'

  List<Map<String, dynamic>> _getFilteredExpenses(List<Map<String, dynamic>> allExpenses) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (_selectedPeriod) {
      case 'week':
        final sevenDaysAgo = today.subtract(const Duration(days: 7));
        return allExpenses.where((e) => (e['timestamp'] as DateTime).isAfter(sevenDaysAgo)).toList();
      case 'month':
        return allExpenses.where((e) => (e['timestamp'] as DateTime).year == now.year && (e['timestamp'] as DateTime).month == now.month).toList();
      case 'day':
      default:
        return allExpenses.where((e) => 
          (e['timestamp'] as DateTime).year == now.year && 
          (e['timestamp'] as DateTime).month == now.month && 
          (e['timestamp'] as DateTime).day == now.day
        ).toList();
    }
  }

  List<OrderModel> _getFilteredOrders(List<OrderModel> allOrders) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (_selectedPeriod) {
      case 'week':
        final sevenDaysAgo = today.subtract(const Duration(days: 7));
        return allOrders.where((o) => o.timestamp.isAfter(sevenDaysAgo)).toList();
      case 'month':
        return allOrders.where((o) => o.timestamp.year == now.year && o.timestamp.month == now.month).toList();
      case 'day':
      default:
        return allOrders.where((o) => 
          o.timestamp.year == now.year && 
          o.timestamp.month == now.month && 
          o.timestamp.day == now.day
        ).toList();
    }
  }

  String _getPeriodLabel(String lang) {
    switch (_selectedPeriod) {
      case 'week': return Translator.translate('report_summary_weekly', lang);
      case 'month': return Translator.translate('report_summary_monthly', lang);
      default: return Translator.translate('report_summary_today', lang);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminVM = context.watch<AdminViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final user = authVM.currentUser;
    final orders = _getFilteredOrders(adminVM.allOrders);

    final confirmedOrders = orders.where((o) => o.status == OrderStatus.finished).toList();
    final totalRevenue = confirmedOrders.fold<double>(0, (sum, o) => sum + o.totalAmount);
    final totalOrders = confirmedOrders.length;

    final filteredExpenses = _getFilteredExpenses(adminVM.allExpenses);
    final totalExpenses = filteredExpenses.fold<double>(0, (sum, e) => sum + e['cost']);
    final netProfit = totalRevenue - totalExpenses;
    final completedOrders = orders.where((o) => o.status == OrderStatus.finished).length;
    final pendingOrders = orders.where((o) => o.status == OrderStatus.pending || o.status == OrderStatus.preparing || o.status == OrderStatus.ready || o.status == OrderStatus.completed).length;

    // Top selling items: count by name
    final Map<String, int> itemCounts = {};
    for (final order in orders) {
      for (final item in order.items) {
        itemCounts[item.foodItem.name] =
            (itemCounts[item.foodItem.name] ?? 0) + item.quantity;
      }
    }
    final sortedItems = itemCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Revenue per service type
    final Map<String, double> revenueByService = {};
    for (final order in orders) {
      final key = order.serviceType.name;
      revenueByService[key] = (revenueByService[key] ?? 0) + order.totalAmount;
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: WarungLogo(height: 40),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: user?.profileImageProvider,
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(Translator.translate('report_ops_overview', authVM.selectedLanguage), style: const TextStyle(color: Colors.grey, fontSize: 13)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(_getPeriodLabel(authVM.selectedLanguage), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _exportCSV(context, confirmedOrders, authVM.selectedLanguage),
                    icon: const Icon(Icons.download, size: 16, color: Colors.white),
                    label: const Text('Export Excel', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Period Selector
              Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildPeriodButton('day', Translator.translate('report_period_day', authVM.selectedLanguage)),
                    _buildPeriodButton('week', Translator.translate('report_period_week', authVM.selectedLanguage)),
                    _buildPeriodButton('month', Translator.translate('report_period_month', authVM.selectedLanguage)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Total Revenue / Net Profit Hero Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: netProfit >= 0 
                        ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)] 
                        : [const Color(0xFFB71C1C), const Color(0xFFD32F2F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: (netProfit >= 0 ? Colors.green : Colors.red).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      netProfit >= 0 ? 'LABA BERSIH (NET PROFIT)' : 'RUGI BERSIH (NET LOSS)', 
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(
                        locale: 'id',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(netProfit),
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Omzet Kotor', style: TextStyle(color: Colors.white70, fontSize: 10)),
                            Text(
                              NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(totalRevenue),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Biaya Belanja', style: TextStyle(color: Colors.white70, fontSize: 10)),
                            Text(
                              NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(totalExpenses),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Mini Stats Row
              Row(
                 children: [
                  _buildStatCard('$totalOrders', Translator.translate('report_orders_handled', authVM.selectedLanguage), Icons.receipt_long, Colors.green),
                  const SizedBox(width: 16),
                  _buildStatCard(Translator.translate('admin_service_speed', authVM.selectedLanguage), Translator.translate('report_avg_service', authVM.selectedLanguage), Icons.timer_outlined, Colors.orange),
                ],
              ),
              const SizedBox(height: 32),

              // Segmented Tab Switcher
              Container(
                height: 54,
                width: double.infinity,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey.shade600,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                   tabs: [
                    Tab(text: Translator.translate('report_tab_overview', authVM.selectedLanguage)),
                    Tab(text: Translator.translate('report_tab_items', authVM.selectedLanguage)),
                    Tab(text: Translator.translate('report_tab_services', authVM.selectedLanguage)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Content based on Tab
              SizedBox(
                height: 800, // Fixed height or auto? Better use a builder or keep it simple
                child: TabBarView(
                  children: [
                     _buildOverviewTab(context, orders, pendingOrders, completedOrders, totalOrders, authVM.selectedLanguage),
                    _buildTopItemsTab(sortedItems, authVM.selectedLanguage),
                    _buildServicesTab(revenueByService, totalRevenue, authVM.selectedLanguage),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, List<OrderModel> orders, int pending, int completed, int total, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(Translator.translate('report_order_status', lang), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF555555))),
        const SizedBox(height: 20),
        _buildStatusBar(Translator.translate('status_pending', lang), pending, total, Colors.orange),
        const SizedBox(height: 16),
        _buildStatusBar(Translator.translate('status_completed', lang), completed, total, AppColors.success),
        const SizedBox(height: 16),
        _buildStatusBar(Translator.translate('report_others', lang), total - pending - completed, total, Colors.blueGrey),
        const SizedBox(height: 40),
        Text(Translator.translate('report_last_transactions', lang), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        TextButton(
          onPressed: () => _showAllOrdersSheet(context, orders, lang),
          child: Text(Translator.translate('report_view_all', lang), style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold))
        ),
        const SizedBox(height: 16),
        if (orders.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(children: [
              Icon(Icons.bar_chart, size: 60, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(Translator.translate('report_no_data', lang), style: const TextStyle(color: Colors.grey)),
            ]),
          ))
        else
           ...orders.take(5).map((order) => InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => AdminOrderDetailsScreen(order: order))),
            child: _buildTransactionItem(order, lang),
          )),
        
        const SizedBox(height: 32),
        // Efficiency Tip
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F1F1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline, color: Colors.orange, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(Translator.translate('report_tip_title', lang), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      Translator.translate('report_tip_desc', lang),
                      style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildTopItemsTab(List<MapEntry<String, int>> sortedItems, String lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Translator.translate('report_most_ordered', lang), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          if (sortedItems.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(children: [
                Icon(Icons.fastfood, size: 60, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(Translator.translate('report_no_data_items', lang), style: const TextStyle(color: Colors.grey)),
              ]),
            ))
          else
            ...sortedItems.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final item = entry.value;
              final maxCount = sortedItems.first.value;
              final progress = item.value / maxCount;
              final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '$rank.';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(medal, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(item.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        Text('${item.value} ${Translator.translate('report_sold_count', lang)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade100,
                        color: rank == 1 ? Colors.amber : rank == 2 ? Colors.grey : rank == 3 ? Colors.brown.shade300 : AppColors.primary,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildServicesTab(Map<String, double> revenueByService, double totalRevenue, String lang) {
    const serviceColors = {
      'dineIn': Colors.blue,
      'takeAway': Colors.orange,
      'rsvp': Colors.purple,
      'delivery': Colors.green,
    };
    const serviceIcons = {
      'dineIn': Icons.storefront,
      'takeAway': Icons.shopping_bag_outlined,
      'rsvp': Icons.event_available,
      'delivery': Icons.delivery_dining,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Translator.translate('report_revenue_service', lang), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          if (revenueByService.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(children: [
                Icon(Icons.pie_chart_outline, size: 60, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(Translator.translate('report_no_data', lang), style: const TextStyle(color: Colors.grey)),
              ]),
            ))
          else ...[
            _buildServicesPieChart(revenueByService, lang),
            const SizedBox(height: 24),
            ...revenueByService.entries.map((entry) {
              final pct = totalRevenue > 0 ? (entry.value / totalRevenue) : 0.0;
              final color = serviceColors[entry.key] ?? AppColors.primary;
              final icon = serviceIcons[entry.key] ?? Icons.receipt;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(Translator.translate('status_${entry.key}', lang), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                        Text('Rp ${entry.value.toInt()}', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: Colors.grey.shade100,
                        color: color,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('${(pct * 100).toStringAsFixed(1)}% ${Translator.translate('report_rev_pct', lang)}', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(OrderModel order, String lang) {
    Color statusColor;
    String statusText;
    
    switch (order.status) {
      case OrderStatus.finished:
      case OrderStatus.completed:
        statusColor = const Color(0xFF2E7D32);
        statusText = Translator.translate('report_status_success', lang);
        break;
      case OrderStatus.cancelled:
        statusColor = const Color(0xFFC62828);
        statusText = Translator.translate('report_status_cancelled', lang);
        break;
      default:
        statusColor = Colors.orange.shade800;
        statusText = Translator.translate('status_${order.status.name}', lang);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A3A),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(12),
            child: const Icon(Icons.fastfood, color: Colors.orange, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order #${order.id}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('HH:mm').format(order.timestamp)} • ${order.items.length} ${Translator.translate('home_items', lang)}', 
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12)
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Rp ${_formatK(order.totalAmount.toInt())}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText, 
                  style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatK(int value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toString();
  }

  Widget _buildStatusBar(String label, int count, int total, Color color) {
    final frac = total > 0 ? (count / total) : 0.0;
    return Row(
      children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: frac,
              backgroundColor: const Color(0xFFF5F5F5),
              color: color,
              minHeight: 12,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text('$count', style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 18)),
      ],
    );
  }

  Widget _buildPeriodButton(String period, String label) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = period),
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
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  void _showAllOrdersSheet(BuildContext context, List<OrderModel> orders, String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(Translator.translate('report_all_transactions', lang), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Filter Tabs (All, Success, Cancelled)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        _buildFilterTab(setModalState, Translator.translate('report_filter_all', lang), _currentFilter == 'all', () => _currentFilter = 'all'),
                        _buildFilterTab(setModalState, Translator.translate('report_filter_success', lang), _currentFilter == 'success', () => _currentFilter = 'success'),
                        _buildFilterTab(setModalState, Translator.translate('report_filter_cancelled', lang), _currentFilter == 'cancelled', () => _currentFilter = 'cancelled'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _getOrdersByStatus(orders).length,
                    itemBuilder: (context, index) {
                      final order = _getOrdersByStatus(orders)[index];
                      return InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (ctx) => AdminOrderDetailsScreen(order: order)));
                        },
                        child: _buildTransactionItem(order, lang),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  String _currentFilter = 'all';

  Widget _buildFilterTab(StateSetter setModalState, String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setModalState(() {
            onTap();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppColors.primary : Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  List<OrderModel> _getOrdersByStatus(List<OrderModel> filteredOrders) {
    if (_currentFilter == 'success') {
      return filteredOrders.where((o) => o.status == OrderStatus.finished || o.status == OrderStatus.completed).toList();
    }
    return filteredOrders;
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(value,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(label,
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesPieChart(Map<String, double> revenueByService, String lang) {
    if (revenueByService.isEmpty) return const SizedBox();

    const serviceColors = {
      'dineIn': Colors.blue,
      'takeAway': Colors.orange,
      'rsvp': Colors.purple,
      'delivery': Colors.green,
    };

    final total = revenueByService.values.fold<double>(0, (sum, val) => sum + val);

    final sections = revenueByService.entries.map((entry) {
      final percentage = total > 0 ? (entry.value / total) : 0.0;
      final color = serviceColors[entry.key] ?? Colors.grey;
      
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: percentage > 0.05 ? '${(percentage * 100).toStringAsFixed(0)}%' : '',
        radius: 40,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: sections,
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  void _exportCSV(BuildContext context, List<OrderModel> orders, String lang) {
    final buffer = StringBuffer();
    buffer.writeln('ID Pesanan,Tanggal,Tipe Layanan,Total Pembayaran,Status');
    
    final df = DateFormat('yyyy-MM-dd HH:mm');
    for (final order in orders) {
      final id = order.id;
      final date = df.format(order.timestamp);
      final service = Translator.translate('status_${order.serviceType.name}', lang);
      final total = order.totalAmount.toInt();
      final status = Translator.translate('status_${order.status.name}', lang);
      
      buffer.writeln('"$id","$date","$service",$total,"$status"');
    }
    
    final csvContent = buffer.toString();
    Clipboard.setData(ClipboardData(text: csvContent));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(lang == 'id' ? 'Ekspor Berhasil' : 'Export Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang == 'id' 
                ? 'Data laporan penjualan telah berhasil diekspor ke CSV dan disalin ke Clipboard ponsel Anda. Anda dapat langsung menempelkannya (paste) ke Google Sheets, Excel, atau WhatsApp.'
                : 'Sales report data has been successfully exported to CSV and copied to your clipboard. You can paste it directly into Google Sheets, Excel, or WhatsApp.',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            Text(
              lang == 'id' ? 'Pratinjau Data CSV:' : 'CSV Data Preview:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Container(
              height: 150,
              width: double.maxFinite,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SingleChildScrollView(
                child: Text(
                  csvContent,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          ),
        ],
      ),
    );
  }
}
