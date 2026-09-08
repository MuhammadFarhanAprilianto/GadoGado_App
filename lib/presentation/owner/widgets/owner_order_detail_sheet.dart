import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/order_model.dart';

class OwnerOrderDetailSheet extends StatelessWidget {
  final OrderModel order;

  const OwnerOrderDetailSheet({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                    ),
                    Text(
                      dateFormatter.format(order.timestamp),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                _buildStatusBadge(order.status),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            const Text(
              'CUSTOMER ORDER',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey, letterSpacing: 1.2),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items.length,
              itemBuilder: (context, index) {
                final item = order.items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${item.quantity}x',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.foodItem.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            if (item.notes != null && item.notes!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Note: ${item.notes}',
                                  style: const TextStyle(color: Colors.orange, fontSize: 12, fontStyle: FontStyle.italic),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        currencyFormatter.format(item.totalPrice),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            if (order.specialInstructions != null && order.specialInstructions!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.message_outlined, size: 14, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('SPECIAL INSTRUCTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(order.specialInstructions!, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            const Divider(),
            const SizedBox(height: 16),
            _buildSummaryRow('Subtotal', currencyFormatter.format(order.subtotal)),
            _buildSummaryRow('Tax (10%)', currencyFormatter.format(order.tax)),
            _buildSummaryRow('Service Charge', currencyFormatter.format(order.serviceCharge)),
            if (order.deliveryFee != null && order.deliveryFee! > 0)
              _buildSummaryRow('Delivery Fee', currencyFormatter.format(order.deliveryFee!)),
            _buildSummaryRow('Payment Method', order.paymentMethod.name.toUpperCase()),
            
            if (order.paymentMethod != PaymentMethod.cash) ...[
              const SizedBox(height: 16),
              const Text(
                'PAYMENT PROOF',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey, letterSpacing: 1.2),
              ),
              const SizedBox(height: 8),
              if (order.paymentProofUrl != null && order.paymentProofUrl!.isNotEmpty)
                GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: const EdgeInsets.all(16),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          InteractiveViewer(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(order.paymentProofUrl!, fit: BoxFit.contain),
                            ),
                          ),
                          CircleAvatar(
                            backgroundColor: Colors.black.withValues(alpha: 0.5),
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      order.paymentProofUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 120,
                          color: Colors.black12,
                          child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 80,
                        color: Colors.grey.shade100,
                        child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Bukti bayar tidak ditemukan!', 
                          style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (order.serviceType == ServiceType.delivery) ...[
              const SizedBox(height: 16),
              const Text(
                'DELIVERY DETAILS',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey, letterSpacing: 1.2),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.deliveryAddress ?? 'Alamat tidak tersedia',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    if (order.latitude != null && order.longitude != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Koordinat: ${order.latitude}, ${order.longitude}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${order.latitude},${order.longitude}');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.map, size: 16, color: Colors.white),
                        label: const Text('Buka di Peta', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                Text(
                  currencyFormatter.format(order.totalAmount),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Close Details', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color color;
    switch (status) {
      case OrderStatus.pending: color = Colors.orange; break;
      case OrderStatus.preparing: color = Colors.blue; break;
      case OrderStatus.ready: color = Colors.green; break;
      case OrderStatus.completed: color = Colors.blueGrey; break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
