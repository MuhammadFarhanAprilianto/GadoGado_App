import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../viewmodels/customer_viewmodel.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../../../data/models/order_model.dart';
import '../../../../core/utils/translator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class OrderDetailsScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailsScreen({super.key, required this.order});
 
   @override
   Widget build(BuildContext context) {
     final customerVM = context.watch<CustomerViewModel>();
     final authVM = context.watch<AuthViewModel>();
     // Find the live order from the VM to ensure we see updates
     final liveOrder = customerVM.orders.firstWhere((o) => o.id == order.id, orElse: () => order);

     return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(Translator.translate('details_title', authVM.selectedLanguage), style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildMainCard(context, authVM, liveOrder),
            const SizedBox(height: 24),
            _buildStatusTimeline(authVM, liveOrder),
            if (liveOrder.serviceType == ServiceType.delivery) ...[
              const SizedBox(height: 24),
              _buildLocationCard(authVM, liveOrder),
              const SizedBox(height: 16),
              _buildContactCard(authVM, liveOrder),
            ],
            const SizedBox(height: 32),
            if (liveOrder.status == OrderStatus.completed)
              _buildFinishButton(context, authVM, customerVM, liveOrder),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard(BuildContext context, AuthViewModel authVM, OrderModel currentOrder) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusBadge(authVM, currentOrder),
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
                Text(
                  '${Translator.translate('order_placed_today', authVM.selectedLanguage)} • ${Translator.translate('status_${order.serviceType.name}', authVM.selectedLanguage)}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Items Card (Nested)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image(
                        image: item.foodItem.imageProvider, 
                        width: 50, 
                        height: 50, 
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(width: 50, height: 50, color: Colors.grey.shade100, child: const Icon(Icons.image, size: 20, color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.foodItem.getName(authVM.selectedLanguage), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(item.notes ?? Translator.translate('order_standard_prep', authVM.selectedLanguage), style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                        ],
                      ),
                    ),
                    Text('x${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AuthViewModel authVM, OrderModel currentOrder) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (currentOrder.status) {
      case OrderStatus.pending:
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        icon = Icons.hourglass_top_rounded;
        label = Translator.translate('dt_pending', authVM.selectedLanguage);
        break;
      case OrderStatus.preparing:
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        icon = Icons.soup_kitchen_rounded;
        label = Translator.translate('dt_preparing', authVM.selectedLanguage);
        break;
      case OrderStatus.ready:
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        icon = currentOrder.serviceType == ServiceType.delivery ? Icons.delivery_dining : Icons.check_circle;
        label = currentOrder.serviceType == ServiceType.delivery
            ? Translator.translate('status_ready_delivery', authVM.selectedLanguage)
            : Translator.translate('details_ready_pickup', authVM.selectedLanguage);
        break;
      case OrderStatus.completed:
        bgColor = Colors.blueGrey.shade50;
        textColor = Colors.blueGrey.shade700;
        icon = Icons.verified_rounded;
        label = Translator.translate('dt_validating', authVM.selectedLanguage);
        break;
      case OrderStatus.finished:
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade800;
        icon = Icons.task_alt_rounded;
        label = Translator.translate('dt_finished', authVM.selectedLanguage);
        break;
      case OrderStatus.cancelled:
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        icon = Icons.cancel_rounded;
        label = 'Dibatalkan';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 15),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  /// Build a full vertical timeline showing all order stages.
  Widget _buildStatusTimeline(AuthViewModel authVM, OrderModel currentOrder) {
    final isDelivery = currentOrder.serviceType == ServiceType.delivery;
    final currentIndex = currentOrder.status.index;

    // Define the stage list
    final stages = <_TimelineStage>[
      _TimelineStage(
        icon: Icons.receipt_long_rounded,
        label: Translator.translate('dt_pending', authVM.selectedLanguage),
        sublabel: 'Pesanan masuk & dikonfirmasi',
        statusIndex: OrderStatus.pending.index,
      ),
      _TimelineStage(
        icon: Icons.soup_kitchen_rounded,
        label: Translator.translate('dt_preparing', authVM.selectedLanguage),
        sublabel: 'Dapur sedang menyiapkan pesanan',
        statusIndex: OrderStatus.preparing.index,
      ),
      _TimelineStage(
        icon: isDelivery ? Icons.delivery_dining_rounded : Icons.check_circle_rounded,
        label: isDelivery
            ? Translator.translate('dt_ready_delivery', authVM.selectedLanguage)
            : Translator.translate('dt_ready', authVM.selectedLanguage),
        sublabel: isDelivery
            ? 'Kurir sedang menuju lokasi Anda'
            : 'Silakan ambil di loket',
        statusIndex: OrderStatus.ready.index,
      ),
      _TimelineStage(
        icon: Icons.verified_rounded,
        label: Translator.translate('dt_validating', authVM.selectedLanguage),
        sublabel: 'Pesanan menunggu konfirmasi akhir',
        statusIndex: OrderStatus.completed.index,
      ),
      _TimelineStage(
        icon: Icons.task_alt_rounded,
        label: Translator.translate('dt_finished', authVM.selectedLanguage),
        sublabel: 'Selesai! Terima kasih 🎉',
        statusIndex: OrderStatus.finished.index,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline_rounded, color: Color(0xFF2E7D32), size: 20),
              const SizedBox(width: 8),
              Text(
                Translator.translate('details_status_log', authVM.selectedLanguage),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...stages.asMap().entries.map((entry) {
            final idx = entry.key;
            final stage = entry.value;
            final isLast = idx == stages.length - 1;
            final isDone = stage.statusIndex < currentIndex;
            final isCurrent = stage.statusIndex == currentIndex;
            final isFuture = stage.statusIndex > currentIndex;

            Color dotColor;
            Color lineColor;
            IconData dotIcon;

            if (isDone) {
              dotColor = const Color(0xFF4CAF50);
              lineColor = const Color(0xFF4CAF50);
              dotIcon = Icons.check;
            } else if (isCurrent) {
              dotColor = const Color(0xFFE65100);
              lineColor = Colors.grey.shade200;
              dotIcon = stage.icon;
            } else {
              dotColor = Colors.grey.shade300;
              lineColor = Colors.grey.shade200;
              dotIcon = stage.icon;
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: dot + connector line
                  SizedBox(
                    width: 40,
                    child: Column(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isFuture ? Colors.grey.shade100 : dotColor,
                            shape: BoxShape.circle,
                            border: isCurrent
                                ? Border.all(color: const Color(0xFFBF360C), width: 2.5)
                                : null,
                            boxShadow: isCurrent
                                ? [BoxShadow(color: const Color(0xFFE65100).withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 2)]
                                : null,
                          ),
                          child: Icon(
                            dotIcon,
                            size: 18,
                            color: isFuture ? Colors.grey.shade400 : Colors.white,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2.5,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: lineColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Right: labels
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 24, top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stage.label,
                            style: TextStyle(
                              fontWeight: isCurrent ? FontWeight.w900 : FontWeight.bold,
                              fontSize: isCurrent ? 14 : 13,
                              color: isFuture
                                  ? Colors.grey.shade400
                                  : isCurrent
                                      ? const Color(0xFFBF360C)
                                      : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            stage.sublabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: isFuture ? Colors.grey.shade300 : Colors.grey.shade500,
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBE9E7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Status Saat Ini',
                                style: TextStyle(fontSize: 10, color: Color(0xFFBF360C), fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Timestamp on the right for completed/current
                  if (!isFuture)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        _formatTime(currentOrder.timestamp),
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildFinishButton(BuildContext context, AuthViewModel authVM, CustomerViewModel vm, OrderModel currentOrder) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
          onPressed: () {
          // Validate and Finish
          vm.updateOrderStatus(currentOrder.id, OrderStatus.finished);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(Translator.translate('details_order_completed', authVM.selectedLanguage)),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF2E7D32),
            ),
          );
        },
        child: Text(
          Translator.translate('details_finish_btn', authVM.selectedLanguage),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
        ),
      ),
    );
  }

  Widget _buildLocationCard(AuthViewModel authVM, OrderModel currentOrder) {
    return _LocationCardContent(authVM: authVM, order: currentOrder);
  }

  Widget _buildContactCard(AuthViewModel authVM, OrderModel currentOrder) {
    // Store contact info — use a fixed admin/store WhatsApp number
    const String storeWhatsApp = '6281234567890'; // Replace with actual store number
    const String storeName = 'Warung Gado-Gado Mpo Lemez';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.support_agent_rounded, color: Color(0xFF2E7D32), size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Translator.translate('contact_card_title', authVM.selectedLanguage),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                  Text(
                    Translator.translate('contact_card_subtitle', authVM.selectedLanguage),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Divider(color: Colors.grey.shade100, height: 24),
          Text(storeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildContactButton(
                  icon: Icons.chat_rounded,
                  label: Translator.translate('contact_whatsapp', authVM.selectedLanguage),
                  color: const Color(0xFF25D366),
                  onTap: () async {
                    final url = Uri.parse('https://wa.me/$storeWhatsApp');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildContactButton(
                  icon: Icons.phone_rounded,
                  label: Translator.translate('contact_call', authVM.selectedLanguage),
                  color: const Color(0xFF2E7D32),
                  onTap: () async {
                    final url = Uri.parse('tel:+$storeWhatsApp');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _TimelineStage {
  final IconData icon;
  final String label;
  final String sublabel;
  final int statusIndex;

  const _TimelineStage({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.statusIndex,
  });
}

class _LocationCardContent extends StatefulWidget {
  final AuthViewModel authVM;
  final OrderModel order;
  const _LocationCardContent({required this.authVM, required this.order});

  @override
  State<_LocationCardContent> createState() => _LocationCardContentState();
}

class _LocationCardContentState extends State<_LocationCardContent> {
  String? _resolvedAddress;
  bool _isResolving = false;

  @override
  void initState() {
    super.initState();
    _checkAndResolveAddress();
  }

  Future<void> _checkAndResolveAddress() async {
    // If we already have the address, no need to do anything
    if (widget.order.deliveryAddress != null && widget.order.deliveryAddress!.isNotEmpty) {
      setState(() => _resolvedAddress = widget.order.deliveryAddress);
      return;
    }

    // If we have coordinates but no address, perform reverse geocoding
    if (widget.order.latitude != null && widget.order.longitude != null) {
      setState(() => _isResolving = true);
      try {
        final placemarks = await placemarkFromCoordinates(
          widget.order.latitude!,
          widget.order.longitude!,
        );
        if (placemarks.isNotEmpty && mounted) {
          final place = placemarks.first;
          setState(() {
            _resolvedAddress = "${place.street}, ${place.subLocality}, ${place.locality}";
            _isResolving = false;
          });
          return;
        }
      } catch (e) {
        debugPrint("Reverse geocoding failed: $e");
      }
    }

    if (mounted) {
      setState(() {
        _resolvedAddress = Translator.translate('details_no_address', widget.authVM.selectedLanguage);
        _isResolving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDelivery = widget.order.serviceType == ServiceType.delivery;
    final labelKey = isDelivery ? 'delivery_location' : 'pickup_location';
    final locationText = isDelivery 
        ? (_resolvedAddress ?? Translator.translate('details_no_address', widget.authVM.selectedLanguage))
        : 'Artisan Counter • SCBD Lot 8';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: _DeliveryMap(order: widget.order),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            Translator.translate(labelKey, widget.authVM.selectedLanguage), 
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFBF360C), letterSpacing: 1.0)
          ),
          const SizedBox(height: 4),
          if (_isResolving)
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Text(
              locationText, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)
            ),
        ],
      ),
    );
  }

}

class _DeliveryMap extends StatefulWidget {
  final OrderModel order;
  const _DeliveryMap({required this.order});

  @override
  State<_DeliveryMap> createState() => _DeliveryMapState();
}

class _DeliveryMapState extends State<_DeliveryMap> {
  LatLng? _targetLocation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _resolveLocation();
  }

  Future<void> _resolveLocation() async {
    // 1. Check if coordinates are already in the order
    if (widget.order.latitude != null && widget.order.longitude != null) {
      if (mounted) {
        setState(() {
          _targetLocation = LatLng(widget.order.latitude!, widget.order.longitude!);
          _isLoading = false;
        });
      }
      return;
    }

    // 2. Fallback: Geocode the address string
    if (widget.order.deliveryAddress != null && widget.order.deliveryAddress!.isNotEmpty) {
      try {
        final locations = await locationFromAddress(widget.order.deliveryAddress!);
        if (locations.isNotEmpty && mounted) {
          setState(() {
            _targetLocation = LatLng(locations.first.latitude, locations.first.longitude);
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        debugPrint("Geocoding failed: $e");
      }
    }

    // 3. Last Resort: Default to Shop location if delivery fails or it's a pickup
    if (mounted) {
      setState(() {
        _targetLocation = const LatLng(-6.2088, 106.8456); // Shop Location
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.grey.shade100,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _targetLocation!, zoom: 15),
      liteModeEnabled: true, // Use Lite Mode for better performance in list/scroll views
      mapToolbarEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      markers: {
        Marker(
          markerId: const MarkerId('delivery'),
          position: _targetLocation!,
        ),
      },
    );
  }
}
