import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/translator.dart';
import '../../../../data/models/order_model.dart';
import 'package:gado_gado_app/presentation/admin/viewmodels/admin_view_model.dart';
import 'package:gado_gado_app/presentation/auth/viewmodels/auth_viewmodel.dart';
import '../../widgets/responsive_layout.dart';

class AdminOrderDetailsScreen extends StatelessWidget {
  final OrderModel order;

  const AdminOrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final adminVM = context.watch<AdminViewModel>();
    final lang = authVM.selectedLanguage;
    
    // Find up-to-date order status from VM instead of stale passed instance
    final upToDateOrder = adminVM.allOrders.firstWhere((o) => o.id == order.id, orElse: () => order);

    return ResponsiveLayout(
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('${Translator.translate('order_detail_title', lang)} ${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Update Panel
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Translator.translate('order_detail_update_status', lang), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 16),
                  _buildStatusActionButtons(context, upToDateOrder, adminVM, lang),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Order Recap
            Container(
               width: double.infinity,
               padding: const EdgeInsets.all(24),
               decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(24),
                 border: Border.all(color: Colors.grey.shade100),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text(order.serviceType == ServiceType.dineIn 
                            ? Translator.translate('status_dine_in', lang).toUpperCase()
                            : order.serviceType == ServiceType.takeAway
                                ? Translator.translate('status_take_away', lang).toUpperCase()
                                : order.serviceType == ServiceType.rsvp
                                    ? Translator.translate('status_rsvp', lang).toUpperCase()
                                    : Translator.translate('status_delivery', lang).toUpperCase(), 
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                       if (order.rsvpTime != null)
                         Text('${Translator.translate('order_detail_arrival', lang)} ${order.rsvpTime}', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                     ],
                   ),
                   const Divider(height: 32),
                   ...order.items.map((item) => Padding(
                     padding: const EdgeInsets.only(bottom: 12),
                     child: Row(
                       children: [
                         Expanded(child: Text('${item.quantity}x ${item.foodItem.name}', style: const TextStyle(fontWeight: FontWeight.bold))),
                         Text('Rp ${item.totalPrice.toInt()}', style: TextStyle(color: Colors.grey.shade600)),
                       ],
                     ),
                   )),
                   
                   if (order.specialInstructions != null) ...[
                     const SizedBox(height: 16),
                     Container(
                       width: double.infinity,
                       padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(Translator.translate('summary_special_req', lang).toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                           const SizedBox(height: 4),
                           Text(order.specialInstructions!, style: TextStyle(fontSize: 13, color: Colors.orange.shade900)),
                         ],
                       ),
                     )
                   ],
                   
                   const Divider(height: 32),
                   _buildReceiptRow(Translator.translate('cart_subtotal', lang), order.subtotal),
                   _buildReceiptRow('${Translator.translate('cart_tax', lang)} (10%)', order.tax),
                   _buildReceiptRow(Translator.translate('summary_service_details', lang), order.serviceCharge),
                   if (order.deliveryFee != null && order.deliveryFee! > 0)
                     _buildReceiptRow(Translator.translate('summary_delivery', lang), order.deliveryFee!),
                   const SizedBox(height: 16),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text(Translator.translate('summary_grand_total', lang), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                       Text('Rp ${order.totalAmount.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.primary)),
                     ],
                   ),
                 ],
               ),
            ),
             if (upToDateOrder.serviceType == ServiceType.delivery) ...[
               const SizedBox(height: 24),
               Container(
                 width: double.infinity,
                 padding: const EdgeInsets.all(24),
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(24),
                   boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
                 ),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Text('Detail Pengiriman', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                     const Divider(height: 24),
                     Row(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         const Icon(Icons.location_on, color: AppColors.primary, size: 24),
                         const SizedBox(width: 12),
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               const Text('Alamat Tujuan:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                               const SizedBox(height: 4),
                               Text(
                                 upToDateOrder.deliveryAddress ?? 'Alamat tidak tersedia',
                                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                               ),
                               if (upToDateOrder.latitude != null && upToDateOrder.longitude != null) ...[
                                 const SizedBox(height: 8),
                                 Text(
                                   'Koordinat: ${upToDateOrder.latitude}, ${upToDateOrder.longitude}',
                                   style: TextStyle(color: Colors.grey.shade600, fontSize: 12)
                                 ),
                               ]
                             ],
                           ),
                         ),
                       ],
                     ),
                     if (upToDateOrder.latitude != null && upToDateOrder.longitude != null) ...[
                       const SizedBox(height: 20),
                       SizedBox(
                         width: double.infinity,
                         child: ElevatedButton.icon(
                           onPressed: () async {
                             final lat = upToDateOrder.latitude;
                             final lng = upToDateOrder.longitude;
                             final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                             if (await canLaunchUrl(url)) {
                               await launchUrl(url, mode: LaunchMode.externalApplication);
                             } else {
                               if (context.mounted) {
                                 ScaffoldMessenger.of(context).showSnackBar(
                                   const SnackBar(content: Text('Tidak dapat membuka Google Maps'))
                                 );
                               }
                             }
                           },
                           icon: const Icon(Icons.map, color: Colors.white),
                           label: const Text('Buka di Peta (Google Maps)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                           style: ElevatedButton.styleFrom(
                             backgroundColor: AppColors.primary,
                             padding: const EdgeInsets.symmetric(vertical: 16),
                             shape: RoundedRectangleBorder(
                               borderRadius: BorderRadius.circular(16),
                             ),
                           ),
                         ),
                       ),
                     ],
                   ],
                 ),
               ),
             ],
             // Customer Contact Card (Delivery only)
             if (upToDateOrder.serviceType == ServiceType.delivery) ...[
               const SizedBox(height: 16),
               _buildCustomerContactCard(context, upToDateOrder, lang),
             ],
             const SizedBox(height: 24),
             
             // Payment Verification Panel
             Container(
               width: double.infinity,
               padding: const EdgeInsets.all(24),
               decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(24),
                 boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Text('Detail Pembayaran', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                   const Divider(height: 24),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       const Text('Metode Pembayaran', style: TextStyle(color: Colors.grey, fontSize: 14)),
                       Text(
                         upToDateOrder.paymentMethod.name.toUpperCase(), 
                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)
                       ),
                     ],
                   ),
                   if (upToDateOrder.paymentMethod != PaymentMethod.cash) ...[
                     const SizedBox(height: 20),
                     const Text('Bukti Transfer / Pembayaran:', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 12),
                     if (upToDateOrder.paymentProofUrl != null && upToDateOrder.paymentProofUrl!.isNotEmpty)
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
                                     child: Image.network(upToDateOrder.paymentProofUrl!, fit: BoxFit.contain),
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
                           borderRadius: BorderRadius.circular(16),
                           child: Image.network(
                             upToDateOrder.paymentProofUrl!,
                             width: double.infinity,
                             height: 220,
                             fit: BoxFit.cover,
                             loadingBuilder: (context, child, loadingProgress) {
                               if (loadingProgress == null) return child;
                               return Container(
                                 height: 220,
                                 color: Colors.black12,
                                 child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                               );
                             },
                             errorBuilder: (context, error, stackTrace) => Container(
                               height: 150,
                               color: Colors.grey.shade100,
                               child: const Center(
                                 child: Column(
                                   mainAxisAlignment: MainAxisAlignment.center,
                                   children: [
                                     Icon(Icons.broken_image, color: Colors.grey, size: 36),
                                     SizedBox(height: 8),
                                     Text('Gagal memuat bukti pembayaran.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                   ],
                                 ),
                               ),
                             ),
                           ),
                         ),
                       )
                     else
                       Container(
                         width: double.infinity,
                         padding: const EdgeInsets.all(16),
                         decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                         child: const Row(
                           children: [
                             Icon(Icons.warning_amber_rounded, color: Colors.red),
                             SizedBox(width: 12),
                             Expanded(child: Text('Bukti transfer belum diunggah!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))),
                           ],
                         ),
                       ),
                   ],
                 ],
               ),
              ),
           ],
         ),
       ),
     ),
   );
 }
  
  Widget _buildReceiptRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text('Rp ${amount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatusActionButtons(BuildContext context, OrderModel order, AdminViewModel adminVM, String lang) {
    return Wrap(
      spacing: 8,
      runSpacing: 12,
      children: OrderStatus.values.map((status) {
        final isSelected = order.status == status;
        Color baseColor = Colors.grey;
        switch (status) {
           case OrderStatus.pending: baseColor = Colors.orange; break;
           case OrderStatus.preparing: baseColor = Colors.blue; break;
           case OrderStatus.ready: baseColor = Colors.green; break;
           case OrderStatus.completed: baseColor = Colors.blueGrey; break;
           case OrderStatus.finished: baseColor = const Color(0xFF455A64); break;
           case OrderStatus.cancelled: baseColor = Colors.red; break;
        }

        return InkWell(
          onTap: () async {
            await adminVM.updateOrderStatus(order.id, status);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? baseColor : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? baseColor : Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) const Icon(Icons.check, size: 16, color: Colors.white) else Icon(Icons.circle_outlined, size: 16, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                Text(
                  Translator.translate(
                    (status == OrderStatus.ready && order.serviceType == ServiceType.delivery)
                        ? 'status_ready_delivery'
                        : 'status_${status.name}', 
                    lang
                  ).toUpperCase(), 
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade600, 
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCustomerContactCard(BuildContext context, OrderModel order, String lang) {
    final customerName = order.customerName ?? 'Pelanggan';
    final customerPhone = order.customerPhone;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.person_pin_rounded, color: Colors.orange.shade700, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Translator.translate('contact_customer_title', lang),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                  Text(
                    Translator.translate('contact_customer_subtitle', lang),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
          Divider(color: Colors.grey.shade100, height: 24),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.orange.shade100,
                child: Text(
                  customerName.isNotEmpty ? customerName[0].toUpperCase() : '?',
                  style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(
                      customerPhone ?? Translator.translate('contact_no_phone', lang),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (customerPhone != null && customerPhone.isNotEmpty) ...[  
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildAdminContactBtn(
                    context: context,
                    icon: Icons.chat_rounded,
                    label: Translator.translate('contact_whatsapp', lang),
                    color: const Color(0xFF25D366),
                    onTap: () async {
                      // Normalize phone: remove leading 0, add 62 prefix
                      final normalized = customerPhone.startsWith('0')
                          ? '62${customerPhone.substring(1)}'
                          : customerPhone.replaceAll('+', '');
                      final url = Uri.parse('https://wa.me/$normalized');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildAdminContactBtn(
                    context: context,
                    icon: Icons.phone_rounded,
                    label: Translator.translate('contact_call', lang),
                    color: AppColors.primary,
                    onTap: () async {
                      final url = Uri.parse('tel:$customerPhone');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdminContactBtn({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

