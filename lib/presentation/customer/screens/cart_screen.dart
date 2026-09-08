import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/shop_settings_model.dart';
import '../../../../core/utils/translator.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../viewmodels/customer_viewmodel.dart';
import '../../widgets/responsive_layout.dart';
import 'order_summary_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final customerVM = context.watch<CustomerViewModel>();
    final authVM = context.watch<AuthViewModel>();

    return ResponsiveLayout(
      child: Scaffold(
        backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.black),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: customerVM.cart.isEmpty
          ? _buildEmptyState(context)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Translator.translate('cart_your_order', authVM.selectedLanguage),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Translator.translate('cart_review_fresh', authVM.selectedLanguage),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Items List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: customerVM.cart.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = customerVM.cart[index];
                      return _buildCartItem(context, authVM, customerVM, item);
                    },
                  ),
                ),
                
                // Bottom Section
                _buildBottomSummary(context, customerVM),
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
            Translator.translate('cart_empty', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(Translator.translate('cart_go_shopping', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, AuthViewModel authVM, CustomerViewModel customerVM, dynamic item) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image(
              image: item.foodItem.imageProvider,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 80, height: 80, color: Colors.grey.shade100, child: const Icon(Icons.image, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.foodItem.getName(authVM.selectedLanguage),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  item.notes ?? Translator.translate('cart_no_substitutions', authVM.selectedLanguage),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rp ${item.foodItem.price.toInt()}',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ],
            ),
          ),
          
          // Quantity Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildQtyBtn(Icons.remove, () => customerVM.updateQuantity(item.foodItem.id, item.notes, -1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    item.quantity.toString().padLeft(2, '0'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                _buildQtyBtn(Icons.add, () => customerVM.updateQuantity(item.foodItem.id, item.notes, 1), isPrimary: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap, {bool isPrimary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isPrimary ? [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))
          ] : null,
        ),
        child: Icon(icon, size: 16, color: isPrimary ? Colors.white : Colors.grey.shade600),
      ),
    );
  }

  Widget _buildBottomSummary(BuildContext context, CustomerViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            TextField(
              onChanged: vm.setSpecialInstructions,
              decoration: InputDecoration(
                hintText: Translator.translate('cart_special_instructions', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage),
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(Icons.edit_note, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(Translator.translate('cart_subtotal', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage), style: const TextStyle(color: Color(0xFF757575))),
                Text('Rp ${vm.subtotal.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(Translator.translate('cart_tax', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage), style: const TextStyle(color: Color(0xFF757575))),
                Text('Rp ${vm.tax10.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(Translator.translate('cart_total', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                Text(
                  'Rp ${(vm.subtotal + vm.tax10).toInt()}', 
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent, 
                  shadowColor: Colors.transparent,
                  disabledForegroundColor: Colors.white,
                ),
                onPressed: vm.shopStatus == ShopStatus.closed 
                  ? null 
                  : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const OrderSummaryScreen()),
                    );
                  },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      vm.shopStatus == ShopStatus.closed 
                        ? Translator.translate('cart_shop_closed', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage) 
                        : Translator.translate('cart_review_order', Provider.of<AuthViewModel>(context, listen: false).selectedLanguage),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    if (vm.shopStatus != ShopStatus.closed) const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
