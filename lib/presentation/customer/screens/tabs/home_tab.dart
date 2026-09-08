import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/viewmodels/auth_viewmodel.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/translator.dart';
import '../../../../data/models/shop_settings_model.dart';
import '../../viewmodels/customer_viewmodel.dart';
import '../../../widgets/warung_logo.dart';
import '../../../../core/theme/app_colors.dart';
import '../../widgets/food_item_card.dart';
import '../cart_screen.dart';

class HomeTab extends StatelessWidget {
  final VoidCallback? onProfileClick;
  const HomeTab({super.key, this.onProfileClick});

  @override
  Widget build(BuildContext context) {
    final customerVM = context.watch<CustomerViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final user = authVM.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        centerTitle: false,
        title: const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: WarungLogo(height: 40),
        ),
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: user?.profileImageProvider,
            ),
            onPressed: onProfileClick,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => customerVM.refreshMenu(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customerVM.shopStatus != ShopStatus.open)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: customerVM.shopStatus == ShopStatus.ishoma ? Colors.amber.shade100 : Colors.red.shade100,
                child: Row(
                  children: [
                    Icon(
                      customerVM.shopStatus == ShopStatus.ishoma ? Icons.timer_outlined : Icons.lock_clock_outlined,
                      color: customerVM.shopStatus == ShopStatus.ishoma ? Colors.amber.shade900 : Colors.red.shade900,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        customerVM.shopStatus == ShopStatus.ishoma
                            ? Translator.translate('home_shop_ishoma', authVM.selectedLanguage)
                            : Translator.translate('home_shop_closed', authVM.selectedLanguage),
                        style: TextStyle(
                          color: customerVM.shopStatus == ShopStatus.ishoma ? Colors.amber.shade900 : Colors.red.shade900,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Promo Banner
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/home_gado.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.bottomRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        Translator.translate('home_authentic_flavor', authVM.selectedLanguage),
                        style: TextStyle(
                          color: Colors.orange.shade300,
                          letterSpacing: 1.5,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Translator.translate('home_heritage_recipes', authVM.selectedLanguage),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Categories
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: AppConstants.categories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final category = AppConstants.categories[index];
                    bool isSelected = customerVM.selectedCategory == category;
                    return GestureDetector(
                      onTap: () => customerVM.setCategory(category),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          Translator.categoryTranslate(category, authVM.selectedLanguage),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF757575),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Menu Items List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Stack(
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: customerVM.menuItems.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = customerVM.menuItems[index];
                      return FoodItemCard(item: item);
                    },
                  ),
                  if (customerVM.shopStatus == ShopStatus.closed)
                    Positioned.fill(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                Translator.translate('home_closed_title', authVM.selectedLanguage),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              Text(
                                Translator.translate('home_order_disabled', authVM.selectedLanguage),
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 140), // Reserve space for floating navbar & cart FAB
          ],
        ),
      )),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 78, right: 8),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            );
          },
          backgroundColor: AppColors.primary,
          elevation: 8,
          child: Stack(
            children: [
              const Icon(Icons.shopping_basket_rounded, color: Colors.white),
              if (customerVM.cartCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${customerVM.cartCount}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
