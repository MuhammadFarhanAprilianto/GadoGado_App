import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/food_item_model.dart';
import '../../../../data/models/shop_settings_model.dart';
import '../../../../core/utils/translator.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../viewmodels/customer_viewmodel.dart';
import 'food_detail_sheet.dart';

class FoodItemCard extends StatelessWidget {
  final FoodItemModel item;

  const FoodItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final customerVM = context.watch<CustomerViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final bool isShopClosed = customerVM.shopStatus == ShopStatus.closed;
    final int portionsRemaining = customerVM.getRemainingPortions(item);
    final bool canAddToCart = item.isAvailable && !isShopClosed && portionsRemaining > 0;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => FoodDetailSheet(item: item),
        );
      },
      child: Container(
        width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image(
                  image: item.imageProvider,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 220,
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
                ),
              ),
              // Tags Section
              if (item.isBestSeller || item.isNew)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                    ),
                    child: Text(
                      item.isBestSeller ? Translator.translate('tag_best_seller', authVM.selectedLanguage) : Translator.translate('tag_new', authVM.selectedLanguage),
                      style: TextStyle(
                        color: item.isBestSeller ? const Color(0xFF2E7D32) : AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              // Habis Badge (Localized to Image)
              if (!item.isAvailable || isShopClosed)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isShopClosed ? Colors.grey.shade800 : const Color(0xFFC62828),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isShopClosed ? Icons.lock_clock : Icons.block, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          isShopClosed ? Translator.translate('status_closed', authVM.selectedLanguage).toUpperCase() : Translator.translate('tag_out_of_stock', authVM.selectedLanguage),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          
          // Content Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.getName(authVM.selectedLanguage),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1A1A1A)),
                      ),
                    ),
                    if (!item.isAvailable || isShopClosed)
                      Text(
                        isShopClosed ? Translator.translate('status_closed', authVM.selectedLanguage) : Translator.translate('tag_out_of_stock_desc', authVM.selectedLanguage),
                        style: TextStyle(color: isShopClosed ? Colors.grey : const Color(0xFFC62828), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.getDescription(authVM.selectedLanguage),
                  style: const TextStyle(color: Color(0xFF757575), fontSize: 12, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rp ${item.price.toInt()}',
                          style: TextStyle(
                            color: canAddToCart && portionsRemaining > 0 ? const Color(0xFFBF360C) : Colors.grey,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            decoration: canAddToCart && portionsRemaining > 0 ? null : TextDecoration.lineThrough,
                          ),
                        ),
                        if (item.isAvailable && !isShopClosed && portionsRemaining <= 10)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              portionsRemaining == 0 
                                ? (authVM.selectedLanguage == 'id' ? 'Stok Habis' : 'Out of Stock')
                                : (authVM.selectedLanguage == 'id' ? 'Sisa $portionsRemaining porsi' : '$portionsRemaining portions left'),
                              style: TextStyle(
                                color: portionsRemaining == 0 ? Colors.red : Colors.orange.shade800,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    GestureDetector(
                      onTap: (canAddToCart && portionsRemaining > 0) ? () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => FoodDetailSheet(item: item),
                        );
                      } : null,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (canAddToCart && portionsRemaining > 0) ? AppColors.primary : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: (canAddToCart && portionsRemaining > 0) ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ] : null,
                        ),
                        child: Icon(
                          Icons.add, 
                          color: (canAddToCart && portionsRemaining > 0) ? Colors.white : Colors.grey.shade400, 
                          size: 24
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),);
  }
}
