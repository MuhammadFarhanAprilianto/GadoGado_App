import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/translator.dart';
import 'package:gado_gado_app/data/models/raw_ingredient_model.dart';
import 'package:gado_gado_app/presentation/auth/viewmodels/auth_viewmodel.dart';
import 'package:gado_gado_app/presentation/admin/viewmodels/admin_view_model.dart';

class RestockIngredientScreen extends StatefulWidget {
  final RawIngredientModel ingredient;

  const RestockIngredientScreen({super.key, required this.ingredient});

  @override
  State<RestockIngredientScreen> createState() => _RestockIngredientScreenState();
}

class _RestockIngredientScreenState extends State<RestockIngredientScreen> {
  late TextEditingController _nameController;
  late TextEditingController _minThresholdController;
  late TextEditingController _amountController;
  late TextEditingController _costController;
  late String _selectedUnit;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.ingredient.name);
    _minThresholdController = TextEditingController(
      text: widget.ingredient.minStockThreshold?.toString() ?? '',
    );
    _amountController = TextEditingController(
      text: widget.ingredient.amount.toString(),
    );
    _costController = TextEditingController(text: '0');
    _selectedUnit = widget.ingredient.unit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minThresholdController.dispose();
    _amountController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminVM = context.read<AdminViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final user = authVM.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.restaurant_menu, color: AppColors.primary, size: 28),
            SizedBox(width: 8),
            Text(
              'Mpo Lemezz',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 24),
            ),
          ],
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Translator.translate('stock_update_title', authVM.selectedLanguage),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 8),
            Text(
              Translator.translate('stock_update_desc', authVM.selectedLanguage),
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),

            _buildLabel(Translator.translate('stock_label_name', authVM.selectedLanguage)),
            _buildTextField(_nameController, placeholder: Translator.translate('stock_hint_name', authVM.selectedLanguage), enabled: false),
            
            const SizedBox(height: 24),
            _buildLabel(Translator.translate('stock_label_unit', authVM.selectedLanguage)),
            _buildTextField(TextEditingController(text: _selectedUnit), placeholder: Translator.translate('stock_hint_unit', authVM.selectedLanguage), enabled: false),
            
            const SizedBox(height: 24),
            _buildLabel('Current Amount (Stok Saat Ini)'),
            _buildTextField(
              _amountController, 
              placeholder: 'Enter current amount', 
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 24),
            _buildLabel('Biaya Restock / Harga Beli (Rp)'),
            _buildTextField(
              _costController, 
              placeholder: 'Masukkan total biaya restock', 
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 24),
            _buildLabel(Translator.translate('stock_label_min_threshold', authVM.selectedLanguage)),
            _buildTextField(
              _minThresholdController, 
              placeholder: Translator.translate('stock_hint_min_threshold', authVM.selectedLanguage), 
              keyboardType: TextInputType.number,
              suffixIcon: const Icon(Icons.notifications_none, color: Color(0xFF9E4E09), size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              Translator.translate('stock_threshold_desc', authVM.selectedLanguage),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final double newAmount = double.tryParse(_amountController.text) ?? widget.ingredient.amount;
                  final double addedAmount = newAmount - widget.ingredient.amount;
                  final double cost = double.tryParse(_costController.text) ?? 0.0;

                  if (_amountController.text.isNotEmpty) {
                    adminVM.updateIngredientAmount(
                      widget.ingredient.id,
                      newAmount,
                    );
                  }
                  adminVM.updateIngredientThreshold(
                    widget.ingredient.id,
                    _minThresholdController.text.isNotEmpty ? double.parse(_minThresholdController.text) : null,
                  );

                  if (addedAmount > 0 && cost > 0) {
                    adminVM.recordExpense(
                      widget.ingredient.id,
                      widget.ingredient.name,
                      addedAmount,
                      cost,
                      userId: user?.id,
                    );
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${widget.ingredient.name} stok diperbarui'), backgroundColor: Colors.green),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  Translator.translate('ing_btn_save', authVM.selectedLanguage),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _confirmDelete(context, adminVM),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  side: BorderSide(color: Colors.red.shade100),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  Translator.translate('ing_btn_delete', authVM.selectedLanguage),
                  style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            _buildProTip(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AdminViewModel adminVM) {
    final lang = context.read<AuthViewModel>().selectedLanguage;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(Translator.translate('ing_delete_confirm_title', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text('${Translator.translate('ing_delete_confirm_content', lang)} ${widget.ingredient.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(Translator.translate('pw_cancel', lang))),
          TextButton(
            onPressed: () {
              adminVM.deleteIngredient(widget.ingredient.id);
              Navigator.pop(ctx); // Pop dialog
              Navigator.pop(context); // Pop screen
            },
            child: Text(Translator.translate('ing_btn_delete', lang), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey.shade700, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, {required String placeholder, TextInputType? keyboardType, Widget? suffixIcon, bool enabled = true}) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFF1F1F1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: enabled ? null : Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        style: TextStyle(color: enabled ? Colors.black : Colors.grey.shade500),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildProTip() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.grey, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Translator.translate('stock_tip_desc', context.read<AuthViewModel>().selectedLanguage),
                  style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
