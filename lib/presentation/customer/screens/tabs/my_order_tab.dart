import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/viewmodels/auth_viewmodel.dart';
import '../../viewmodels/customer_viewmodel.dart';
import '../../../../data/models/order_model.dart';
import '../../../../core/utils/translator.dart';
import '../order_details_screen.dart';

class MyOrderTab extends StatelessWidget {
  final VoidCallback? onProfileClick;
  const MyOrderTab({super.key, this.onProfileClick});

  @override
  Widget build(BuildContext context) {
    final customerVM = context.watch<CustomerViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final user = authVM.currentUser;

    final activeOrders = customerVM.orders.where((o) => 
      o.status == OrderStatus.pending || 
      o.status == OrderStatus.preparing || 
      o.status == OrderStatus.ready || 
      o.status == OrderStatus.completed
    ).toList();

    final historyOrders = customerVM.orders.where((o) => 
      o.status == OrderStatus.finished || 
      o.status == OrderStatus.cancelled
    ).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
          IconButton(
            icon: CircleAvatar(
              radius: 12,
              backgroundImage: user?.profileImageProvider,
            ),
            onPressed: onProfileClick,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: customerVM.orders.isEmpty 
        ? _buildEmptyState(context)
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Translator.translate('order_my_order', authVM.selectedLanguage),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Translator.translate('order_tracking_journey', authVM.selectedLanguage),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),

                // Active Orders (Only show if any exist)
                if (activeOrders.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => OrderDetailsScreen(order: activeOrders.first)),
                      ),
                      child: _buildCurrentOrder(context, authVM, activeOrders.first),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],

                // History Section
                if (historyOrders.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    Translator.translate('order_history', authVM.selectedLanguage),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                  ),
                ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: historyOrders.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = historyOrders[index];
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => OrderDetailsScreen(order: order)),
                        ),
                        child: _buildOrderItem(context, authVM, order),
                      );
                    },
                  ),
                ] else if (activeOrders.isEmpty)
                  _buildEmptyHistoryState(context),

                const SizedBox(height: 100), 
              ],
            ),
          ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            Translator.translate('order_no_orders', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage), 
            style: const TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold)
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentOrder(BuildContext context, AuthViewModel authVM, OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 40, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: order.status == OrderStatus.ready ? const Color(0xFFC8E6C9) : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      order.status == OrderStatus.ready ? Icons.check_circle : Icons.timer_outlined, 
                      color: order.status == OrderStatus.ready ? const Color(0xFF2E7D32) : Colors.orange.shade800, 
                      size: 16
                    ),
                    const SizedBox(width: 4),
                    Text(
                      order.status == OrderStatus.ready 
                        ? Translator.translate('order_status_ready', authVM.selectedLanguage) 
                        : (order.status == OrderStatus.completed 
                           ? Translator.translate('order_status_validating', authVM.selectedLanguage) 
                           : Translator.translate('order_status_preparing', authVM.selectedLanguage)), 
                      style: TextStyle(
                        color: order.status == OrderStatus.ready ? const Color(0xFF2E7D32) : Colors.orange.shade800, 
                        fontWeight: FontWeight.bold, fontSize: 10
                      )
                    ),
                  ],
                ),
              ),
              Text(
                'Rp ${order.totalAmount.toInt()}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFFBF360C)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${Translator.translate('summary_qty', authVM.selectedLanguage)} #${order.id}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 4),
                Text(Translator.translate('order_placed_today', authVM.selectedLanguage), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Order Items (Sample Thumbnails)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: order.items.take(2).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image(
                        image: item.foodItem.imageProvider, 
                        width: 40, 
                        height: 40, 
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(width: 40, height: 40, color: Colors.grey.shade100, child: const Icon(Icons.image, size: 16, color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.foodItem.getName(authVM.selectedLanguage), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(Translator.translate('order_standard_prep', authVM.selectedLanguage), style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                        ],
                      ),
                    ),
                    Text('x${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 20),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OrderDetailsScreen(order: order)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBF360C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(Translator.translate('order_check_status', authVM.selectedLanguage), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(BuildContext context, AuthViewModel authVM, OrderModel order) {
    final bool canFinish = order.status == OrderStatus.completed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.history_rounded, color: Color(0xFFBF360C)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${Translator.translate('order_detail_title', authVM.selectedLanguage)} ${order.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('${order.items.length} items • Rp ${order.totalAmount.toInt()}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: order.status == OrderStatus.cancelled ? Colors.red.shade50 : Colors.grey.shade100, 
                  borderRadius: BorderRadius.circular(12)
                ),
                child: Text(
                  order.status == OrderStatus.cancelled 
                    ? Translator.translate('order_cancelled', authVM.selectedLanguage) 
                    : (order.status == OrderStatus.completed 
                       ? 'Belum Selesai' 
                       : Translator.translate('order_completed', authVM.selectedLanguage)), 
                  style: TextStyle(
                    fontSize: 10, 
                    fontWeight: FontWeight.bold, 
                    color: order.status == OrderStatus.cancelled ? Colors.red : (order.status == OrderStatus.completed ? Colors.orange.shade800 : Colors.grey)
                  )
                ),
              ),
            ],
          ),
          if (canFinish) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final success = await context.read<CustomerViewModel>().finishOrder(order.id);
                  if (context.mounted && success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pesanan telah diselesaikan. Terima kasih!'), backgroundColor: Colors.green),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBF360C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Selesaikan Pesanan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildEmptyHistoryState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Icon(Icons.history, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(Translator.translate('order_no_history', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage), style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
