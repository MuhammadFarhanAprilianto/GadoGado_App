import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/translator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/order_model.dart';
import 'package:gado_gado_app/data/models/shop_settings_model.dart';
import 'package:gado_gado_app/presentation/admin/viewmodels/admin_view_model.dart';
import 'package:gado_gado_app/data/models/topping_model.dart';
import 'package:gado_gado_app/data/models/raw_ingredient_model.dart';
import '../../../auth/viewmodels/auth_viewmodel.dart';
import '../admin_order_details_screen.dart';
import '../add_menu_screen.dart';
import '../edit_menu_screen.dart';
import '../restock_ingredient_screen.dart';

class AdminHomeTab extends StatelessWidget {
  const AdminHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final adminVM = context.watch<AdminViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final user = authVM.currentUser;

    return Scaffold(
      appBar: AppBar(
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
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
                onPressed: () => _showLowStockAlerts(context, adminVM),
              ),
              if (adminVM.lowStockCount > 0)
                Positioned(
                  right: 8,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${adminVM.lowStockCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: user?.profileImageProvider,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddMenuScreen()),
          );
        },
        backgroundColor: const Color(0xFFE65100),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Translator.translate('admin_welcome', authVM.selectedLanguage),
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            Text(
              Translator.translate(
                'admin_live_availability',
                authVM.selectedLanguage,
              ),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Status Card (Dynamic)
            InkWell(
              onTap: () => _showStatusPicker(context, adminVM),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getStatusColor(adminVM.shopStatus).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _getStatusColor(adminVM.shopStatus).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getStatusColor(adminVM.shopStatus),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getStatusIcon(adminVM.shopStatus),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusTitle(
                              adminVM.shopStatus,
                              authVM.selectedLanguage,
                            ),
                            style: TextStyle(
                              color: _getStatusColor(
                                adminVM.shopStatus,
                              ).darken(),
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _getStatusSubtitle(
                              adminVM.shopStatus,
                              adminVM,
                              authVM.selectedLanguage,
                            ),
                            style: TextStyle(
                              color: _getStatusColor(
                                adminVM.shopStatus,
                              ).darken(),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.edit_outlined,
                      color: _getStatusColor(adminVM.shopStatus).darken(),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (adminVM.lowStockCount > 0) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.red.shade200, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${adminVM.lowStockCount} Bahan Baku Kritis!',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.red),
                              ),
                              const Text(
                                'Stok bahan baku di bawah batas aman harian. Segera lakukan restock untuk mencegah pesanan tertolak.',
                                style: TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: adminVM.lowStockIngredients.take(3).map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(
                              '${item.amount} ${item.unit} (Min: ${item.minStockThreshold} ${item.unit})',
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                    if (adminVM.lowStockIngredients.length > 3) ...[
                      const SizedBox(height: 4),
                      Text(
                        '+ ${adminVM.lowStockIngredients.length - 3} bahan baku lainnya...', 
                        style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 11, color: Colors.grey)
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (adminVM.lowStockIngredients.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (c) => RestockIngredientScreen(ingredient: adminVM.lowStockIngredients.first),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 18),
                        label: const Text('Restock Bahan Baku Sekarang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              Translator.translate(
                'report_summary_today',
                authVM.selectedLanguage,
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),

            // Revenue Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Translator.translate(
                      'report_revenue',
                      authVM.selectedLanguage,
                    ),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    NumberFormat.currency(
                      locale: 'id',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(adminVM.todayRevenue),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mini Stats
            Row(
              children: [
                _buildMiniStat(
                  '${adminVM.todayOrderCount}',
                  Translator.translate(
                    'report_orders_handled',
                    authVM.selectedLanguage,
                  ),
                  Icons.receipt_long,
                ),
                const SizedBox(width: 16),
                _buildMiniStat(
                  Translator.translate(
                    'admin_service_speed',
                    authVM.selectedLanguage,
                  ),
                  Translator.translate(
                    'report_avg_service',
                    authVM.selectedLanguage,
                  ),
                  Icons.timer_outlined,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // --- Live Incoming Orders Block ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Translator.translate(
                    'admin_incoming_orders',
                    authVM.selectedLanguage,
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${adminVM.incomingOrders.length} ${Translator.translate('home_active', authVM.selectedLanguage)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (adminVM.incomingOrders.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.inbox_outlined,
                      color: Colors.grey,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      Translator.translate(
                        'admin_no_orders',
                        authVM.selectedLanguage,
                      ),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: adminVM.incomingOrders.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final order = adminVM.incomingOrders[index];
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AdminOrderDetailsScreen(order: order),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '#${order.id}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              _buildStaticBadge(order, authVM.selectedLanguage),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                order.serviceType == ServiceType.delivery
                                    ? Icons.delivery_dining
                                    : (order.serviceType == ServiceType.rsvp
                                          ? Icons.event_available
                                          : Icons.storefront),
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                Translator.translate(
                                  order.serviceType == ServiceType.dineIn
                                      ? 'status_dine_in'
                                      : order.serviceType ==
                                            ServiceType.takeAway
                                      ? 'status_take_away'
                                      : 'status_${order.serviceType.name}',
                                  authVM.selectedLanguage,
                                ),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${order.items.length} ${Translator.translate('home_items', authVM.selectedLanguage)}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Rp ${order.totalAmount.toInt()}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          if (order.specialInstructions != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${Translator.translate('cart_special_instructions', authVM.selectedLanguage)}: ${order.specialInstructions}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade800,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 32),

            // --- Toppings Management Section ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kelola Tambahan Topping',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAddEditToppingSheet(context, adminVM, null),
                  icon: const Icon(Icons.add, size: 16, color: Colors.brown),
                  label: const Text(
                    'Tambah',
                    style: TextStyle(
                      color: Colors.brown,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (adminVM.toppings.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Center(
                  child: Text(
                    'Belum ada topping tambahan dikonfigurasi.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: adminVM.toppings.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final topping = adminVM.toppings[index];
                    final ingredient = adminVM.ingredients.firstWhere(
                      (i) => i.id == topping.ingredientId,
                      orElse: () => RawIngredientModel(id: '', name: 'Tidak tertaut', category: '', amount: 0, unit: ''),
                    );
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
                        child: const Icon(Icons.lunch_dining_outlined, color: AppColors.primaryDark, size: 20),
                      ),
                      title: Text(
                        topping.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        'Harga: Rp ${topping.price.toInt()} | Link Stok: ${ingredient.name} (${ingredient.amount} ${ingredient.unit})',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_note, color: Colors.blue),
                            onPressed: () => _showAddEditToppingSheet(context, adminVM, topping),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _showDeleteToppingConfirmDialog(context, adminVM, topping),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 32),

            // --- End Live Orders Block ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Translator.translate(
                    'report_tab_items',
                    authVM.selectedLanguage,
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                TextButton(
                  onPressed: () => _showAllMenuItemsSheet(
                    context,
                    adminVM,
                    authVM.selectedLanguage,
                  ),
                  child: Text(
                    Translator.translate(
                      'report_view_all',
                      authVM.selectedLanguage,
                    ),
                    style: const TextStyle(
                      color: Colors.brown,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Menu Items (New Design)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: adminVM.menuItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = adminVM.menuItems[index];
                return _buildPopularItemRow(
                  context,
                  item,
                  adminVM,
                  authVM.selectedLanguage,
                );
              },
            ),

            const SizedBox(height: 24),
            // Bottom Stats row
            Row(
              children: [
                _buildSquareStat(
                  Translator.translate(
                    'home_active_orders',
                    authVM.selectedLanguage,
                  ),
                  '${adminVM.incomingOrders.length}',
                  const Color(0xFFF1F1F1),
                ),
                const SizedBox(width: 16),
                _buildSquareStat(
                  Translator.translate(
                    'home_ready_status',
                    authVM.selectedLanguage,
                  ),
                  '${adminVM.menuReadinessPercentage}%',
                  const Color(0xFFFAF2E8),
                ),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSquareStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF5D4037),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularItemRow(
    BuildContext context,
    dynamic item,
    AdminViewModel adminVM,
    String lang,
  ) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (ctx) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.getName(lang), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
                  title: const Text('Edit Menu', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (c) => EditMenuScreen(foodItem: item)));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Hapus Menu', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showDeleteItemDialog(context, item, adminVM, lang);
                  },
                ),
              ],
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image(
                    image: item.imageProvider,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.fastfood_outlined,
                        color: Color(0xFF5D4037),
                        size: 30,
                      ),
                    ),
                  ),
                ),
                if (item.isAvailable)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 8,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.getName(lang),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    item.getDescription(lang),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: item.isAvailable
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.isAvailable
                          ? Translator.translate('home_status_ready', lang)
                          : Translator.translate('home_status_sold_out', lang),
                      style: TextStyle(
                        color: item.isAvailable
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFC62828),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: item.isAvailable,
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFF2E7D32),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey.shade300,
                onChanged: (val) {
                  adminVM.toggleItemAvailability(item.id, val);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteItemDialog(
    BuildContext context,
    dynamic item,
    AdminViewModel adminVM,
    String lang,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          Translator.translate('ing_delete_confirm_title', lang),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '${Translator.translate('ing_delete_confirm_content', lang)} "${item.getName(lang)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              Translator.translate('pw_cancel', lang),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              try {
                await adminVM.deleteFoodItem(item.id, imageUrl: item.image);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${item.getName(lang)} ${Translator.translate('menu_delete_success', lang)}',
                      ), // I should add this key
                      backgroundColor: Colors.red.shade800,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${Translator.translate('profile_edit_fail', lang)}: $e',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              Translator.translate('ing_btn_delete', lang),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAllMenuItemsSheet(
    BuildContext context,
    AdminViewModel adminVM,
    String lang,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Translator.translate('admin_live_availability', lang),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: adminVM.menuItems.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final item = adminVM.menuItems[index];
                  return _buildPopularItemRow(context, item, adminVM, lang);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primaryLight, size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ShopStatus status) {
    switch (status) {
      case ShopStatus.open:
        return const Color(0xFF2E7D32);
      case ShopStatus.ishoma:
        return const Color(0xFFFBC02D);
      case ShopStatus.closed:
        return const Color(0xFFC62828);
    }
  }

  IconData _getStatusIcon(ShopStatus status) {
    switch (status) {
      case ShopStatus.open:
        return Icons.check;
      case ShopStatus.ishoma:
        return Icons.timer_outlined;
      case ShopStatus.closed:
        return Icons.lock_outline;
    }
  }

  String _getStatusTitle(ShopStatus status, String lang) {
    switch (status) {
      case ShopStatus.open:
        return Translator.translate('home_status_open_title', lang);
      case ShopStatus.ishoma:
        return Translator.translate('home_status_ishoma_title', lang);
      case ShopStatus.closed:
        return Translator.translate('home_status_closed_title', lang);
    }
  }

  String _getStatusSubtitle(
    ShopStatus status,
    AdminViewModel adminVM,
    String lang,
  ) {
    switch (status) {
      case ShopStatus.open:
        return '${Translator.translate('home_status_open_sub', lang)} ${adminVM.incomingOrders.length + 5} ${Translator.translate('home_tables', lang)}';
      case ShopStatus.ishoma:
        return Translator.translate('home_status_ishoma_sub', lang);
      case ShopStatus.closed:
        return Translator.translate('home_status_closed_sub', lang);
    }
  }

  void _showStatusPicker(BuildContext context, AdminViewModel adminVM) {
    final lang = context.read<AuthViewModel>().selectedLanguage;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Translator.translate('update_status', lang),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              Translator.translate('stock_manage_desc', lang),
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ), // Close enough
            const SizedBox(height: 24),
            _buildStatusOption(
              context,
              adminVM,
              ShopStatus.open,
              Translator.translate('status_open', lang),
              Translator.translate('home_status_open_sub', lang),
              Icons.check_circle_outline,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildStatusOption(
              context,
              adminVM,
              ShopStatus.ishoma,
              Translator.translate('status_ishoma', lang),
              Translator.translate('home_status_ishoma_sub', lang),
              Icons.timer_outlined,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildStatusOption(
              context,
              adminVM,
              ShopStatus.closed,
              Translator.translate('status_closed', lang),
              Translator.translate('home_status_closed_sub', lang),
              Icons.lock_outline,
              Colors.red,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(
    BuildContext context,
    AdminViewModel adminVM,
    ShopStatus status,
    String title,
    String sub,
    IconData icon,
    Color color,
  ) {
    bool isSelected = adminVM.shopStatus == status;
    return InkWell(
      onTap: () {
        adminVM.updateShopStatus(status, isManual: true);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${Translator.translate('admin_status_updated', context.read<AuthViewModel>().selectedLanguage)} $title',
            ),
            backgroundColor: color,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                  Text(
                    sub,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }

  void _showLowStockAlerts(BuildContext context, AdminViewModel adminVM) {
    final lang = context.read<AuthViewModel>().selectedLanguage;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => Material(
        // Added Material for explicit surface
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Let it size naturally
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    Translator.translate('home_low_inventory', lang),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                Translator.translate('home_low_inventory_desc', lang),
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        Translator.translate('home_report_sent', lang),
                      ),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.send_rounded, size: 14),
                label: Text(
                  Translator.translate('home_notify_owner', lang),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: adminVM.lowStockIngredients.isEmpty
                    ? Center(
                        child: Text(
                          Translator.translate('home_safe_stock', lang),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: adminVM.lowStockIngredients.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = adminVM.lowStockIngredients[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${Translator.translate('tag_out_of_stock', lang)}: ${item.amount} ${item.unit} (${item.category})',
                              style: const TextStyle(
                                color: Color(0xFFC62828),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 24),
              // Main secondary button at bottom too
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          Translator.translate('home_notif_sent', lang),
                        ),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.notifications_active_outlined,
                    color: Colors.white,
                  ),
                  label: Text(
                    Translator.translate('home_send_notif_owner', lang),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaticBadge(OrderModel order, String lang) {
    Color badgeColor;
    switch (order.status) {
      case OrderStatus.pending:
        badgeColor = Colors.orange;
        break;
      case OrderStatus.preparing:
        badgeColor = Colors.blue;
        break;
      case OrderStatus.ready:
        badgeColor = Colors.green;
        break;
      case OrderStatus.completed:
        badgeColor = Colors.blueGrey;
        break;
      case OrderStatus.finished:
        badgeColor = const Color(0xFF2E7D32);
        break;
      case OrderStatus.cancelled:
        badgeColor = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        Translator.translate('status_${order.status.name}', lang),
        style: TextStyle(
          color: badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showAddEditToppingSheet(BuildContext context, AdminViewModel adminVM, ToppingModel? topping) {
    final bool isEdit = topping != null;
    final nameController = TextEditingController(text: isEdit ? topping.name : '');
    final priceController = TextEditingController(text: isEdit ? topping.price.toInt().toString() : '');
    String? selectedIngredientId = isEdit ? topping.ingredientId : null;
    if (selectedIngredientId != null && !adminVM.ingredients.any((ing) => ing.id == selectedIngredientId)) {
      final nameToMatch = selectedIngredientId.replaceAll('dummy_', '').toLowerCase();
      final matchedIng = adminVM.ingredients.firstWhere(
        (ing) => ing.name.toLowerCase() == nameToMatch || 
                 ing.name.toLowerCase().contains(nameToMatch) || 
                 nameToMatch.contains(ing.name.toLowerCase()),
        orElse: () => RawIngredientModel(id: '', name: '', category: '', amount: 0, unit: ''),
      );
      if (matchedIng.id.isNotEmpty) {
        selectedIngredientId = matchedIng.id;
      } else {
        selectedIngredientId = adminVM.ingredients.isNotEmpty ? adminVM.ingredients.first.id : null;
      }
    }
    selectedIngredientId ??= adminVM.ingredients.isNotEmpty ? adminVM.ingredients.first.id : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).padding.bottom + MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isEdit ? 'Edit Tambahan Topping' : 'Tambah Topping Baru',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Topping',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Harga (Rp)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Tautkan ke Stok Bahan Baku:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 8),
                if (adminVM.ingredients.isEmpty)
                  const Text('Tidak ada bahan baku yang tersedia. Daftarkan bahan baku terlebih dahulu.', style: TextStyle(color: Colors.red, fontSize: 12))
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedIngredientId,
                        isExpanded: true,
                        items: adminVM.ingredients.map((ing) {
                          return DropdownMenuItem<String>(
                            value: ing.id,
                            child: Text('${ing.name} (${ing.amount} ${ing.unit})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            selectedIngredientId = val;
                          });
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                      
                      if (name.isEmpty || price <= 0 || selectedIngredientId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Harap lengkapi semua kolom dengan benar!')),
                        );
                        return;
                      }

                      if (isEdit) {
                        final updated = topping.copyWith(
                          name: name,
                          price: price,
                          ingredientId: selectedIngredientId,
                        );
                        await adminVM.updateTopping(updated);
                      } else {
                        await adminVM.addTopping(name, price, selectedIngredientId!);
                      }

                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(isEdit ? 'Topping berhasil diperbarui!' : 'Topping baru berhasil ditambahkan!')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      isEdit ? 'Simpan Perubahan' : 'Tambah Topping',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteToppingConfirmDialog(BuildContext context, AdminViewModel adminVM, ToppingModel topping) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Topping?'),
        content: Text('Apakah Anda yakin ingin menghapus topping "${topping.name}"? Pelanggan tidak akan dapat memesan topping ini lagi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await adminVM.deleteTopping(topping.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Topping berhasil dihapus!'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
