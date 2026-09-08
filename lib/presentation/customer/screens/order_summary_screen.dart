import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../viewmodels/customer_viewmodel.dart';
import '../../../../data/models/order_model.dart';
import '../../../../core/utils/translator.dart';
import 'location_picker_screen.dart';
import '../../widgets/responsive_layout.dart';

class OrderSummaryScreen extends StatelessWidget {
  const OrderSummaryScreen({super.key});

  void _handleConfirmPay(BuildContext context) async {
    final customerVM = context.read<CustomerViewModel>();
    final authVM = context.read<AuthViewModel>();
    
    // Validate non-cash payments have proof
    if (customerVM.paymentMethod != PaymentMethod.cash && customerVM.paymentProofPath == null) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(Translator.translate('summary_upload_proof', authVM.selectedLanguage))),
       );
       return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    // Place order
    final String? errorReason = await customerVM.placeOrder(
      authVM.currentUser?.id ?? 'guest',
      authVM.currentUser?.name ?? 'Customer',
      customerPhone: authVM.currentUser?.phone,
    );
    
    if (context.mounted) {
      Navigator.pop(context); // Close loading dialog
      
      if (errorReason == null) {
        _showSuccessDialog(
          context, 
          userName: authVM.currentUser?.name ?? 'Customer',
          orderTime: DateFormat('HH:mm').format(DateTime.now()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorReason),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(BuildContext context, {required String userName, required String orderTime}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.green, size: 40),
            ),
            const SizedBox(height: 24),
            const Text('Order Confirmed!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87)),
            const SizedBox(height: 8),
            const Text(
              'Your meal is being prepared with love and will be on its way shortly.', 
              textAlign: TextAlign.center, 
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            
            // Grey Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildSuccessRow(Translator.translate('summary_order_time_label', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage), orderTime),
                  const SizedBox(height: 12),
                  _buildSuccessRow(Translator.translate('summary_order_user_label', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage), userName),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Go to Home Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                ),
                child: Text(Translator.translate('summary_go_home', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            
            // Track My Order Link
            TextButton(
              onPressed: () {
                context.read<CustomerViewModel>().setTabIndex(1);
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: Text(Translator.translate('summary_track_order', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage), style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Future<void> _downloadQrisImage(BuildContext context) async {
    final authVM = context.read<AuthViewModel>();
    final lang = authVM.selectedLanguage;
    try {
      final ByteData bytes = await rootBundle.load('assets/images/pembayaran_qris.jpeg');
      final Uint8List list = bytes.buffer.asUint8List();

      await Printing.sharePdf(
        bytes: list,
        filename: 'QRIS_GadoGado_Mpo_Lemezz.jpeg',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang == 'en' ? 'QRIS image ready to save/download' : 'Gambar QRIS siap disimpan/didownload'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang == 'en' ? 'Failed to download QRIS: $e' : 'Gagal mendownload QRIS: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickPaymentProof(BuildContext context, CustomerViewModel vm) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        vm.setPaymentProof(image.path);
      }
    } catch (e) {
      if (context.mounted) {
        final authVM = context.read<AuthViewModel>();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${Translator.translate('fail_upload_proof', authVM.selectedLanguage)}: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final customerVM = context.watch<CustomerViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final user = authVM.currentUser;

    return ResponsiveLayout(
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: user?.profileImageProvider,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Translator.translate('summary_title', authVM.selectedLanguage), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(
                    Translator.translate('summary_subtitle', authVM.selectedLanguage),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Your Items Section
            _buildYourItems(context, customerVM),
            const SizedBox(height: 24),
            
            // Service Details Section
            _buildServiceDetails(context, customerVM),
            const SizedBox(height: 24),
            
            // Payment Method Section
            _buildPaymentMethodSection(context, customerVM),
            const SizedBox(height: 24),

            // Receipt Section
            _buildReceipt(context, customerVM),
            const SizedBox(height: 32),
            
            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildPrimaryBtn(Translator.translate('summary_confirm_pay', authVM.selectedLanguage), () => _handleConfirmPay(context)),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(Translator.translate('summary_add_more', authVM.selectedLanguage), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(Translator.translate('summary_secure_payment', authVM.selectedLanguage), style: TextStyle(fontSize: 9, color: Colors.grey.shade400, letterSpacing: 0.5)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildYourItems(BuildContext context, CustomerViewModel vm) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 40, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(Translator.translate('summary_your_items', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text('${vm.cartCount} ${Translator.translate('summary_items_count', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage)}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orange)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...vm.cart.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image(
                    image: item.foodItem.imageProvider, 
                    width: 60, 
                    height: 60, 
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(width: 60, height: 60, color: Colors.grey.shade100, child: const Icon(Icons.image, color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.foodItem.getName(Provider.of<AuthViewModel>(context, listen: false).selectedLanguage), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(Translator.translate('summary_customizations', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage), style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                      Text('${Translator.translate('summary_qty', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage)}: ${item.quantity}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                    ],
                  ),
                ),
                Text('Rp ${item.totalPrice.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildServiceDetails(BuildContext context, CustomerViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Translator.translate('summary_service_details', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildServiceCard(context, vm, ServiceType.dineIn, Icons.restaurant, Translator.translate('summary_dine_in', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage))),
              const SizedBox(width: 12),
              Expanded(child: _buildServiceCard(context, vm, ServiceType.takeAway, Icons.shopping_bag_outlined, Translator.translate('summary_take_away', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
               Expanded(child: _buildServiceCard(context, vm, ServiceType.rsvp, Icons.event_available, Translator.translate('summary_rsvp', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage))),
               const SizedBox(width: 12),
               Expanded(child: _buildServiceCard(context, vm, ServiceType.delivery, Icons.delivery_dining, Translator.translate('summary_delivery', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage))),
            ],
          ),
          
          if (vm.serviceType == ServiceType.rsvp) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50, 
                borderRadius: BorderRadius.circular(16), 
                border: Border.all(color: Colors.blue.shade100)
              ),
              child: Column(
                children: [
                  // Date Selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(Translator.translate('summary_rsvp_date', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(vm.rsvpDate != null ? DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(vm.rsvpDate!) : Translator.translate('summary_rsvp_not_selected', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage), 
                              style: TextStyle(color: vm.rsvpDate != null ? Colors.blue.shade800 : Colors.grey, fontSize: 12)),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (picked != null) vm.setRsvpDate(picked);
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(Translator.translate('summary_rsvp_select', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage), style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const Divider(),
                  // Time Selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(Translator.translate('summary_rsvp_time', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(vm.rsvpTime != null ? vm.rsvpTime!.format(context) : '${Translator.translate('summary_rsvp_not_selected', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage)} (10:00 - 17:00)', 
                              style: TextStyle(color: vm.rsvpTime != null ? Colors.blue.shade800 : Colors.grey, fontSize: 12)),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context, 
                            initialTime: const TimeOfDay(hour: 10, minute: 0),
                          );
                          if (picked != null) {
                            final bool isValid = vm.setRsvpTime(picked);
                            if (!isValid && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(Translator.translate('summary_rsvp_invalid_time', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage)),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.access_time, size: 16),
                        label: Text(Translator.translate('summary_rsvp_select', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage), style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (vm.serviceType == ServiceType.delivery) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const LocationPickerScreen())
              ),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50, 
                  borderRadius: BorderRadius.circular(16), 
                  border: Border.all(color: Colors.orange.shade100)
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.orange.shade800),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(Translator.translate('summary_delivery_location', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                           Text(vm.deliveryAddress, style: TextStyle(color: Colors.orange.shade800, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                           const SizedBox(height: 2),
                           Text('${Translator.translate('summary_distance', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage)}: ${vm.deliveryDistance.toStringAsFixed(1)}km | ${Translator.translate('summary_shipping', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage)}: Rp ${vm.deliveryFee.toInt()}', 
                            style: TextStyle(color: Colors.orange.shade900, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.orange.shade800),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, CustomerViewModel vm, ServiceType type, IconData icon, String label) {
    bool isSelected = vm.serviceType == type;
    return GestureDetector(
      onTap: () => vm.setServiceType(type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF3E0) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade100, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey.shade400, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? AppColors.primary : Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection(BuildContext context, CustomerViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Translator.translate('summary_payment_method', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildPaymentCard(context, vm, PaymentMethod.cash, Icons.money, Translator.translate('summary_pay_cash', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage))),
              const SizedBox(width: 12),
              Expanded(child: _buildPaymentCard(context, vm, PaymentMethod.qris, Icons.qr_code_2, Translator.translate('summary_pay_qris', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
               Expanded(child: _buildPaymentCard(context, vm, PaymentMethod.bankTransfer, Icons.account_balance, Translator.translate('summary_pay_bank', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage))),
               const SizedBox(width: 12),
               Expanded(child: _buildPaymentCard(context, vm, PaymentMethod.eWallet, Icons.account_balance_wallet, Translator.translate('summary_pay_ewallet', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage))),
            ],
          ),
          
          // Inline Payment Details
          if (vm.paymentMethod != PaymentMethod.cash) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (vm.paymentMethod == PaymentMethod.qris) ...[
                    const Text('Scan QRIS untuk Bayar', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset('assets/images/pembayaran_qris.jpeg', width: 220, height: 320, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: () => _downloadQrisImage(context),
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: Text(
                          Translator.translate('summary_download_qris', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary, width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Upload Bukti Pembayaran QRIS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _pickPaymentProof(context, vm),
                      child: Container(
                        width: double.infinity,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: vm.paymentProofPath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(File(vm.paymentProofPath!), fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cloud_upload_outlined, color: Colors.blue, size: 20),
                                SizedBox(height: 4),
                                Text('Upload bukti scan di sini', style: TextStyle(color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                      ),
                    ),
                  ],
                  if (vm.paymentMethod == PaymentMethod.bankTransfer || vm.paymentMethod == PaymentMethod.eWallet) ...[
                    Text(vm.paymentMethod == PaymentMethod.bankTransfer ? 'Transfer Bank BCA' : 'Transfer E-Wallet (Dana/Gopay)', 
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(vm.paymentMethod == PaymentMethod.bankTransfer ? '1650620034' : '082114255840', 
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary)),
                    const Text('a.n Maryono', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text('Upload Bukti Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _pickPaymentProof(context, vm),
                      child: Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                        ),
                        child: vm.paymentProofPath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(File(vm.paymentProofPath!), fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cloud_upload_outlined, color: Colors.blue),
                                SizedBox(height: 8),
                                Text('Tap untuk pilih gambar', style: TextStyle(color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, CustomerViewModel vm, PaymentMethod type, IconData icon, String label) {
    bool isSelected = vm.paymentMethod == type;
    return GestureDetector(
      onTap: () => vm.setPaymentMethod(type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF3E0) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade100, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey.shade400, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? AppColors.primary : Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildReceipt(BuildContext context, CustomerViewModel vm) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 40, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Text(Translator.translate('summary_receipt', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          Text('Order ID: #MPL-${DateTime.now().millisecondsSinceEpoch % 100000}', style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
          const SizedBox(height: 24),
          _buildReceiptRow(Translator.translate('cart_subtotal', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage), 'Rp ${vm.subtotal.toInt()}'),
          _buildReceiptRow(Translator.translate('cart_tax', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage), 'Rp ${vm.tax10.toInt()}'),
          _buildReceiptRow('Service Charge', 'Rp ${vm.serviceCharge.toInt()}'),
          if (vm.serviceType == ServiceType.delivery)
            _buildReceiptRow(Translator.translate('summary_shipping', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage), 'Rp ${vm.deliveryFee.toInt()}'),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(Translator.translate('summary_grand_total', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              Text('Rp ${vm.grandTotal.toInt()}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF757575), fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPrimaryBtn(String label, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
