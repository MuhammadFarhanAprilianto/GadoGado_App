import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/translator.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../viewmodels/admin_view_model.dart';

class AddIngredientScreen extends StatefulWidget {
  const AddIngredientScreen({super.key});

  @override
  State<AddIngredientScreen> createState() => _AddIngredientScreenState();
}

class _AddIngredientScreenState extends State<AddIngredientScreen> {
  final _nameController = TextEditingController();
  final _minThresholdController = TextEditingController();
  String _selectedUnit = 'kg';
  String _selectedCategory = 'Sayuran';

  final List<String> _categories = [
    'Sayuran',
    'Protein / Pelengkap',
    'Pelengkap',
    'Bumbu',
    'Minuman / Cairan',
    'Buah',
    'Lainnya',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _minThresholdController.dispose();
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
        title: Row(
          children: [
            const Icon(Icons.restaurant_menu, color: AppColors.primary, size: 28),
            const SizedBox(width: 8),
            const Text(
              'Warung Mpo Lemez',
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
              Translator.translate('stock_add_title', authVM.selectedLanguage),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 8),
            Text(
              Translator.translate('stock_add_desc', authVM.selectedLanguage),
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),

            _buildLabel(Translator.translate('stock_label_name', authVM.selectedLanguage)),
            _buildTextField(_nameController, placeholder: Translator.translate('stock_hint_name', authVM.selectedLanguage)),
            
            const SizedBox(height: 24),
            _buildLabel(Translator.translate('stock_label_category', authVM.selectedLanguage)),
            _buildDropdown(_selectedCategory, _categories, (val) => setState(() => _selectedCategory = val!)),
            
            const SizedBox(height: 24),
            _buildLabel(Translator.translate('stock_label_unit', authVM.selectedLanguage)),
            _buildDropdown(_selectedUnit, ['kg', 'gram', 'pcs', 'liter', 'ml', 'Units'], (val) => setState(() => _selectedUnit = val!)),
            
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
                  if (_nameController.text.isNotEmpty) {
                    adminVM.addIngredient(
                      _nameController.text.trim(),
                      0.0, // Initial stock is now always 0
                      _selectedUnit,
                      category: _selectedCategory,
                      minThreshold: _minThresholdController.text.isNotEmpty ? double.parse(_minThresholdController.text) : null,
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  Translator.translate('stock_btn_save', authVM.selectedLanguage),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
               child: Text(Translator.translate('pw_cancel', authVM.selectedLanguage), style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey.shade700, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, {required String placeholder, TextInputType? keyboardType, Widget? suffixIcon}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
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

  Widget _buildDropdown(String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: const TextStyle(color: Colors.black, fontSize: 14),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProTip() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb, color: Color(0xFF2E7D32), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(
                  Translator.translate('stock_pro_tip', context.read<AuthViewModel>().selectedLanguage),
                  style: const TextStyle(color: Color(0xFF1B5E20), fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
