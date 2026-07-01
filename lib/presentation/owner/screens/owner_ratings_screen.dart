import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/owner_view_model.dart';

class OwnerRatingsScreen extends StatelessWidget {
  const OwnerRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ownerVM = context.watch<OwnerViewModel>();
    final ratedOrders = ownerVM.filteredOrders
        .where((o) => o.rating != null)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Customer Feedback', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ratedOrders.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.star_outline_rounded, size: 64, color: Colors.grey),
                   SizedBox(height: 16),
                   Text('No feedback received yet', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: ratedOrders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final order = ratedOrders[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Order #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(DateFormat('dd MMM, HH:mm').format(order.timestamp), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < (order.rating ?? 0).floor() ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: Colors.green,
                            size: 20,
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        order.ratingNote ?? 'No comment provided.',
                        style: TextStyle(
                          color: order.ratingNote != null ? Colors.black87 : Colors.grey.shade500, 
                          fontSize: 13, 
                          fontStyle: order.ratingNote != null ? FontStyle.normal : FontStyle.italic
                        ),
                      ),
                      const Divider(height: 24),
                      Text(
                        'Items: ${order.items.map((i) => "${i.quantity}x ${i.foodItem.name}").join(", ")}',
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
