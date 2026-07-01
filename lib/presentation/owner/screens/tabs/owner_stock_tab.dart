import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../../../auth/viewmodels/auth_viewmodel.dart';
import '../../../admin/viewmodels/admin_view_model.dart';
import '../../../admin/screens/add_ingredient_screen.dart';
import '../../../admin/screens/restock_ingredient_screen.dart';

class OwnerStockTab extends StatelessWidget {
  const OwnerStockTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final adminVM = context.watch<AdminViewModel>();
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
      body: RefreshIndicator(
        onRefresh: () => adminVM.refreshIngredients(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const Text('Manajemen Stok', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('Kelola bahan baku dan bahan sediaan Anda.', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 24),
            
            Row(
              children: [
                _buildActionButton(
                  context, 
                  'Tambah Bahan', 
                  Icons.add_box_outlined,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AddIngredientScreen())),
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  context, 
                  'Restock Massal', 
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
            
            // Priority Alert
            if (adminVM.lowStockCount > 0) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: AppColors.error),
                        const SizedBox(width: 8),
                        const Text('PERINGATAN UTAMA', style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('${adminVM.lowStockCount} Bahan Menipis', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Text('Persediaan penting di bawah batas aman. Lakukan restock sekarang untuk mencegah gangguan operasional.', style: TextStyle(color: AppColors.textMain, fontSize: 13)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                         if (adminVM.lowStockIngredients.isNotEmpty) {
                            Navigator.push(context, MaterialPageRoute(builder: (c) => RestockIngredientScreen(ingredient: adminVM.lowStockIngredients.first)));
                         }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B0000), minimumSize: const Size(double.infinity, 48)),
                      child: const Text('Selesaikan Sekarang'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Stock Levels
            const Text('Tingkat Persediaan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            ...adminVM.ingredients.map((item) {
              // Simple percentage logic based on threshold for UI
              double percent = item.amount / (item.minStockThreshold! > 0 ? item.minStockThreshold! * 2 : 10);
              if (percent > 1.0) percent = 1.0;
              
              return _buildStockLevelCard(
                context,
                item,
                percent, 
                Icons.inventory_2_outlined, 
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => RestockIngredientScreen(ingredient: item))),
                onQuickRestock: () => _showQuickRestockModal(context, item, adminVM),
              );
            }),
          ],
        ),
      ),
    ),
  );
}

  void _showQuickRestockModal(BuildContext context, dynamic ingredient, AdminViewModel adminVM) {
    final String unit = ingredient.unit.toLowerCase();
    List<double> increments = [];
    
    if (unit == 'kg') {
      increments = [0.5, 1.0, 5.0, 10.0];
    } else if (unit == 'gram' || unit == 'g') {
      increments = [100, 250, 500, 1000];
    } else if (unit == 'liter' || unit == 'l') {
      increments = [1.0, 2.0, 5.0, 10.0];
    } else if (unit == 'ml') {
      increments = [100, 250, 500, 1000];
    } else {
      // pcs, units, etc.
      increments = [10, 50, 100, 500];
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt, color: Colors.amber),
                const SizedBox(width: 8),
                Text('Quick Restock: ${ingredient.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Pilih jumlah untuk ditambahkan ke stok saat ini (${ingredient.amount} ${ingredient.unit})', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: increments.map((value) => ElevatedButton(
                onPressed: () {
                  adminVM.updateIngredientAmount(ingredient.id, ingredient.amount + value);
                  adminVM.recordExpense(
                    ingredient.id,
                    ingredient.name,
                    value,
                    value * 15000.0, // Mock price of 15,000 per unit (kg/pcs/l)
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Berhasil menambah $value ${ingredient.unit} ke ${ingredient.name}'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('+$value ${ingredient.unit}', style: const TextStyle(fontWeight: FontWeight.bold)),
              )).toList(),
            ),
            const SizedBox(height: 24),
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

  Widget _buildStockLevelCard(BuildContext context, dynamic item, double percent, IconData icon, {required VoidCallback onTap, required VoidCallback onQuickRestock}) {
    final bool isCritical = item.isLowStock;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: Colors.grey.shade100)
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10), 
                    decoration: BoxDecoration(
                      color: isCritical ? AppColors.cardGreen.withValues(alpha: 0.5) : AppColors.cardPeach, 
                      borderRadius: BorderRadius.circular(12)
                    ), 
                    child: Icon(icon, color: isCritical ? Colors.green : AppColors.primary)
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         if (isCritical) const Text('STOK KRITIS', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                         Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                         const Text('Bahan baku penting untuk operasional harian.', style: TextStyle(color: Colors.grey, fontSize: 10)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('STOK SAAT INI', style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)),
                      Text('${item.amount} ${item.unit}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      onQuickRestock();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bolt, color: Colors.amber, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TINGKAT STOK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  Text('${(percent * 100).toInt()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: percent,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(isCritical ? Colors.red : AppColors.primary),
                borderRadius: BorderRadius.circular(10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
