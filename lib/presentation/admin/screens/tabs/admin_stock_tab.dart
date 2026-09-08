import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/translator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatter.dart';
import 'package:gado_gado_app/data/models/raw_ingredient_model.dart';
import 'package:gado_gado_app/presentation/auth/viewmodels/auth_viewmodel.dart';
import 'package:gado_gado_app/presentation/admin/viewmodels/admin_view_model.dart';
import '../add_ingredient_screen.dart';
import '../restock_ingredient_screen.dart';
import '../../../widgets/warung_logo.dart';

class AdminStockTab extends StatelessWidget {
  const AdminStockTab({super.key});

  @override
  Widget build(BuildContext context) {
    final adminVM = context.watch<AdminViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final user = authVM.currentUser;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: WarungLogo(height: 40),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: user?.profileImageProvider,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(Translator.translate('stock_ops', authVM.selectedLanguage), style: const TextStyle(color: Color(0xFF9E4E09), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            Text(Translator.translate('stock_core_ingredients', authVM.selectedLanguage), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            Text(Translator.translate('stock_manage_desc', authVM.selectedLanguage), style: const TextStyle(color: Colors.grey, fontSize: 13)),
            if (adminVM.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(adminVM.errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12))),
                  ],
                ),
              ),
            ],
             const SizedBox(height: 24),
             Row(
               children: [
                 _buildActionButton(
                   context, 
                   'Add Ingredient', 
                   Icons.add_box_outlined,
                   onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AddIngredientScreen())),
                 ),
                 const SizedBox(width: 16),
                 _buildActionButton(
                   context, 
                   'Bulk Restock', 
                   Icons.local_shipping_outlined, 
                   isPrimary: true,
                   onTap: () {
                     if (adminVM.lowStockIngredients.isNotEmpty) {
                        Navigator.push(context, MaterialPageRoute(builder: (c) => RestockIngredientScreen(ingredient: adminVM.lowStockIngredients.first)));
                     }
                   },
                 ),
               ],
             ),
             const SizedBox(height: 24),
             
             // Stock Grid
            Row(
              children: [
                 _buildStockSummaryCard(
                  adminVM.inStockCount.toString().padLeft(2, '0'), 
                  Translator.translate('stock_in_stock', authVM.selectedLanguage), 
                  const Color(0xFF9BED9B), 
                  Icons.check_circle_outline
                ),
                const SizedBox(width: 16),
                _buildStockSummaryCard(
                  adminVM.outOfStockCount.toString().padLeft(2, '0'), 
                  Translator.translate('stock_out_of_stock', authVM.selectedLanguage), 
                  const Color(0xFFFFD1D1), 
                  Icons.warning_amber_rounded
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Categorized Sections
            if (adminVM.ingredients.isEmpty)
              _buildEmptyInitState(context, adminVM, authVM)
            else
              ..._buildCategorizedList(context, adminVM),
            
            const SizedBox(height: 32),
            const SizedBox(height: 32),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStockSummaryCard(String count, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.black.withValues(alpha: 0.6), size: 28),
            const SizedBox(height: 16),
            Text(count, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20))),
            Text(label, style: const TextStyle(color: Color(0xFF1B5E20), fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, {bool isPrimary = false, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isPrimary ? AppColors.primaryDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: isPrimary ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10)] : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: isPrimary ? Colors.white : AppColors.primary),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: isPrimary ? Colors.white : AppColors.textMain, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIngredientItem(BuildContext context, AdminViewModel adminVM, RawIngredientModel ingredient) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
          child: Icon(
            ingredient.category == 'Sayuran' ? Icons.eco_outlined : 
            (ingredient.category == 'Bumbu' ? Icons.grass : 
            (ingredient.category == 'Minuman / Cairan' ? Icons.local_drink_outlined : Icons.inventory_2_outlined)),
            color: const Color(0xFF5D4037),
            size: 20,
          ),
        ),
        title: Text(ingredient.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${ingredient.amount.toCleanString()} ${ingredient.unit}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9E4E09), fontWeight: FontWeight.bold),
                ),
                if (ingredient.isLowStock) ...[
                  const SizedBox(width: 8),
                  Text(
                    Translator.translate('stock_low_stock', context.read<AuthViewModel>().selectedLanguage),
                    style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ]
              ],
            ),
            const SizedBox(height: 8),
            _buildSegmentedIndicator(ingredient),
          ],
        ),
        trailing: const Icon(Icons.edit_note, color: AppColors.primary),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestockIngredientScreen(ingredient: ingredient),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedIndicator(RawIngredientModel ingredient) {
    double percent = ingredient.amount / (ingredient.minStockThreshold != null && ingredient.minStockThreshold! > 0 ? ingredient.minStockThreshold! * 2 : 10);
    if (percent > 1.0) percent = 1.0;
    if (percent < 0.0) percent = 0.0;

    int activeBars = (percent * 5).round();
    if (activeBars < 1 && percent > 0) activeBars = 1;
    if (activeBars > 5) activeBars = 5;
    if (percent <= 0) activeBars = 0;

    Color color;
    if (activeBars >= 5) {
      color = const Color(0xFF00C853); // Bright Green
    } else if (activeBars >= 2) {
      color = const Color(0xFFFBC02D); // Yellow/Amber
    } else {
      color = const Color(0xFFD32F2F); // Red
    }

    return SizedBox(
      width: 140,
      child: Row(
        children: List.generate(5, (index) {
          bool isActive = index < activeBars;
          return Expanded(
            child: Container(
              height: 5,
              margin: EdgeInsets.only(
                left: index == 0 ? 0 : 3,
                right: index == 4 ? 0 : 3,
              ),
              decoration: BoxDecoration(
                color: isActive ? color : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          );
        }),
      ),
    );
  }

  List<Widget> _buildCategorizedList(BuildContext context, AdminViewModel adminVM) {
    final Map<String, List<RawIngredientModel>> groups = {};
    for (var i in adminVM.ingredients) {
      groups.putIfAbsent(i.category, () => []).add(i);
    }

    return groups.entries.map((entry) {
      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    Translator.categoryTranslate(entry.key, context.read<AuthViewModel>().selectedLanguage).toUpperCase(),
                    style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ),
                const Spacer(),
                Text('${entry.value.length} ${Translator.translate('stock_items_count', context.read<AuthViewModel>().selectedLanguage)}', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 16),
            ...entry.value.map((ing) => _buildIngredientItem(context, adminVM, ing)),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildEmptyInitState(BuildContext context, AdminViewModel adminVM, AuthViewModel authVM) {
    return Center(
      child: Column(
        children: [
           const SizedBox(height: 60),
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 24),
          Text(Translator.translate('stock_empty_title', authVM.selectedLanguage), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(Translator.translate('stock_empty_desc', authVM.selectedLanguage), style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: adminVM.isLoading ? null : () => _confirmBulkInit(context, adminVM),
              icon: adminVM.isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.flash_on, color: Colors.white),
               label: Text(
                adminVM.isLoading 
                  ? Translator.translate('stock_init_processing', authVM.selectedLanguage).toUpperCase() 
                  : Translator.translate('stock_init_btn', authVM.selectedLanguage), 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  void _confirmBulkInit(BuildContext context, AdminViewModel adminVM) {
    final lang = context.read<AuthViewModel>().selectedLanguage;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(Translator.translate('stock_init_dialog_title', lang)),
        content: Text(Translator.translate('stock_init_dialog_content', lang)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(Translator.translate('pw_cancel', lang))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Translator.translate('stock_init_processing', lang))));
              await adminVM.seedInitialIngredients();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(Translator.translate('stock_init_success', lang)), 
                  backgroundColor: Colors.green
                ));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: Text(Translator.translate('summary_confirm_pay', lang)), // Use confirm or similar
          ),
        ],
      ),
    );
  }
}
