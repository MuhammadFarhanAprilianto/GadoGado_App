import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/order_model.dart';
import '../viewmodels/customer_viewmodel.dart';
import '../../widgets/responsive_layout.dart';

class DigitalReceiptScreen extends StatelessWidget {
  final OrderModel order;

  const DigitalReceiptScreen({super.key, required this.order});

  String _getPaymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Tunai';
      case PaymentMethod.qris:
        return 'Digital QRIS';
      case PaymentMethod.bankTransfer:
        return 'Transfer Bank';
      case PaymentMethod.eWallet:
        return 'Digital QRIS';
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerVM = Provider.of<CustomerViewModel>(context, listen: false);
    final shopAddress = customerVM.shopAddress;
    final formattedDate = DateFormat('dd-MM-yyyy HH:mm').format(order.timestamp);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Calculate tax percentage
    final int taxPercent = order.subtotal > 0 ? ((order.tax / order.subtotal) * 100).round() : 0;

    return ResponsiveLayout(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Nota Penjualan Digital'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            // Receipt Paper Container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Receipt Top Border Decoration (Dashes)
                  const _DashedBorderRow(),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Store Header
                        const Center(
                          child: Text(
                            'WARUNG MPO LEMEZ',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: Text(
                            shopAddress,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        const _ReceiptDashedDivider(),
                        const SizedBox(height: 16),

                        // Meta details
                        _buildReceiptTextRow('Nota ID', ': TX-${order.id.split('_').last.toUpperCase()}'),
                        _buildReceiptTextRow('Tanggal', ': $formattedDate'),
                        _buildReceiptTextRow('Kasir', ': Staf Ahmad'),
                        
                        const SizedBox(height: 16),
                        const _ReceiptDashedDivider(),
                        const SizedBox(height: 16),

                        // Items list
                        ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.quantity}x ${item.foodItem.name}',
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    currencyFormat.format(item.totalPrice),
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              if (item.notes != null && item.notes!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 18.0, top: 2.0),
                                  child: Text(
                                    item.notes!,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 10,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )),

                        const SizedBox(height: 16),
                        const _ReceiptDashedDivider(),
                        const SizedBox(height: 16),

                        // Subtotal and charges
                        _buildSummaryRow('SUBTOTAL:', currencyFormat.format(order.subtotal)),
                        _buildSummaryRow('Pajak ($taxPercent%):', currencyFormat.format(order.tax)),
                        
                        if (order.serviceCharge > 0)
                          _buildSummaryRow('Biaya Layanan:', currencyFormat.format(order.serviceCharge)),
                        
                        if (order.deliveryFee != null && order.deliveryFee! > 0)
                          _buildSummaryRow('Ongkos Kirim:', currencyFormat.format(order.deliveryFee!)),

                        const SizedBox(height: 16),
                        const _ReceiptDashedDivider(),
                        const SizedBox(height: 16),

                        // Grand Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL PEMBAYARAN:',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              currencyFormat.format(order.totalAmount),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Status: LUNAS (${_getPaymentMethodLabel(order.paymentMethod)})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        const _ReceiptDashedDivider(),
                        const SizedBox(height: 24),

                        // Footer Message
                        const Center(
                          child: Text(
                            '*** TERIMA KASIH ***',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Center(
                          child: Text(
                            'Silakan Berikan Rating Ulasan Anda',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Receipt Bottom Border Decoration (Dashes)
                  const _DashedBorderRow(),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildReceiptTextRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptDashedDivider extends StatelessWidget {
  const _ReceiptDashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashGap = 3.0;
        final dashCount = (boxWidth / (dashWidth + dashGap)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black38),
              ),
            );
          }),
        );
      },
    );
  }
}

class _DashedBorderRow extends StatelessWidget {
  const _DashedBorderRow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 8.0;
        const dashGap = 4.0;
        final dashCount = (boxWidth / (dashWidth + dashGap)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFE0E0E0)),
              ),
            );
          }),
        );
      },
    );
  }
}
