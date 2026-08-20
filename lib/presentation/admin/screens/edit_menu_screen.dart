import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/translator.dart';
import '../../../../data/models/food_item_model.dart';
import '../../../../core/constants/app_constants.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../viewmodels/admin_view_model.dart';

class EditMenuScreen extends StatefulWidget {
  final FoodItemModel foodItem;

  const EditMenuScreen({super.key, required this.foodItem});

  @override
  State<EditMenuScreen> createState() => _EditMenuScreenState();
}

class _EditMenuScreenState extends State<EditMenuScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late String _selectedCategory;
  String? _selectedImage;
  File? _imageFile;
  bool _isSaving = false;
  String _loadingText = '';

  final Map<String, double> _recipeQuantities = {};
  final Map<String, bool> _recipeSelected = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.foodItem.name);
    _descController = TextEditingController(text: widget.foodItem.description);
    _priceController = TextEditingController(text: widget.foodItem.price.toInt().toString());
    _selectedCategory = widget.foodItem.category;
    _selectedImage = widget.foodItem.image;

    for (var r in widget.foodItem.recipe) {
      _recipeSelected[r.ingredientId] = true;
      _recipeQuantities[r.ingredientId] = r.quantityPerPortion;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
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
            const Text(
              'Edit Menu',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 8),
            Text(
              'Ubah data menu dan resep penyusun.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),

            _buildLabel(Translator.translate('menu_label_name', authVM.selectedLanguage)),
            _buildTextField(_nameController, placeholder: Translator.translate('menu_hint_name', authVM.selectedLanguage)),
            
            const SizedBox(height: 24),
            _buildLabel(Translator.translate('menu_label_desc', authVM.selectedLanguage)),
            _buildTextField(_descController, placeholder: Translator.translate('menu_hint_desc', authVM.selectedLanguage)),
            
            const SizedBox(height: 24),
            _buildLabel(Translator.translate('menu_label_price', authVM.selectedLanguage)),
            _buildTextField(_priceController, placeholder: '0', keyboardType: TextInputType.number),
            
            const SizedBox(height: 24),
            _buildLabel(Translator.translate('menu_label_category', authVM.selectedLanguage)),
            _buildDropdown(),
            
            const SizedBox(height: 32),
            _buildLabel('Penyusunan Resep (Bahan Baku per Porsi)'),
            const SizedBox(height: 12),
            if (adminVM.ingredients.isEmpty)
              const Text('Tidak ada bahan baku tersedia.', style: TextStyle(color: Colors.grey, fontSize: 13))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: adminVM.ingredients.length,
                itemBuilder: (context, index) {
                  final ing = adminVM.ingredients[index];
                  final isSelected = _recipeSelected[ing.id] ?? false;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? AppColors.primary.withValues(alpha: 0.3) : Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isSelected,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() {
                              _recipeSelected[ing.id] = val ?? false;
                              if (val == true) {
                                _recipeQuantities[ing.id] ??= 1.0;
                              }
                            });
                          },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ing.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('Kategori: ${ing.category}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                        ),
                        if (isSelected)
                          SizedBox(
                            width: 120,
                            child: TextFormField(
                              initialValue: _recipeQuantities[ing.id]?.toString() ?? '1.0',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                suffixText: ing.unit,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                isDense: true,
                              ),
                              onChanged: (val) {
                                final parsed = double.tryParse(val);
                                if (parsed != null && parsed > 0) {
                                  _recipeQuantities[ing.id] = parsed;
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 32),
            _buildLabel(Translator.translate('menu_label_image', authVM.selectedLanguage)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showImageSourceSheet(context),
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  image: _imageFile != null
                      ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                      : (_selectedImage != null && _selectedImage!.isNotEmpty
                          ? DecorationImage(image: widget.foodItem.imageProvider, fit: BoxFit.cover)
                          : null),
                ),
                child: _imageFile == null && (_selectedImage == null || _selectedImage!.isEmpty)
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_enhance_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            Translator.translate('menu_hint_image', authVM.selectedLanguage),
                            style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                          ),
                        ],
                      )
                    : null,
              ),
            ),

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () async {
                        if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(Translator.translate('menu_err_name_price', authVM.selectedLanguage)))
                          );
                          return;
                        }

                        setState(() {
                          _isSaving = true;
                          _loadingText = 'Menyimpan...';
                        });

                        try {
                          String imageUrl = _selectedImage ?? '';
                          
                          if (_imageFile != null) {
                            setState(() => _loadingText = Translator.translate('menu_status_upload', authVM.selectedLanguage));
                            imageUrl = await adminVM.uploadImage(_imageFile!, 'menu_images');
                          }

                          final List<RecipeItemModel> recipeList = [];
                          _recipeSelected.forEach((ingId, selected) {
                            if (selected) {
                              final ing = adminVM.ingredients.firstWhere((i) => i.id == ingId);
                              recipeList.add(RecipeItemModel(
                                ingredientId: ing.id,
                                ingredientName: ing.name,
                                quantityPerPortion: _recipeQuantities[ing.id] ?? 1.0,
                              ));
                            }
                          });

                          setState(() => _loadingText = 'Memperbarui database...');
                          final nameVal = _nameController.text.trim();
                          final descVal = _descController.text.trim();

                          final updatedItem = FoodItemModel(
                            id: widget.foodItem.id, 
                            name: nameVal,
                            description: descVal,
                            price: double.tryParse(_priceController.text) ?? 0,
                            image: imageUrl,
                            category: _selectedCategory,
                            isAvailable: widget.foodItem.isAvailable,
                            isNew: widget.foodItem.isNew,
                            isBestSeller: widget.foodItem.isBestSeller,
                            recipe: recipeList,
                          );

                          await adminVM.updateFoodItem(updatedItem);
                          
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${updatedItem.name} berhasil diperbarui'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal: ${e.toString()}'), 
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              )
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isSaving = false;
                              _loadingText = '';
                            });
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: Colors.grey.shade400,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                          const SizedBox(width: 12),
                          Text(_loadingText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      )
                     : const Text(
                        'Simpan Perubahan',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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

  Widget _buildTextField(TextEditingController controller, {required String placeholder, TextInputType? keyboardType}) {
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
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          style: const TextStyle(color: Colors.black, fontSize: 14),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedCategory = newValue;
              });
            }
          },
          items: AppConstants.categories.where((c) => c != 'All').map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showImageSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(Translator.translate('menu_image_source', context.read<AuthViewModel>().selectedLanguage), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(Icons.camera_alt_rounded, Translator.translate('menu_source_camera', context.read<AuthViewModel>().selectedLanguage), () => _pickImage(ImageSource.camera)),
                _buildSourceOption(Icons.photo_library_rounded, Translator.translate('menu_source_gallery', context.read<AuthViewModel>().selectedLanguage), () => _pickImage(ImageSource.gallery)),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _selectedImage = image.path;
        });
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil gambar: $e')),
        );
      }
    }
  }

  Widget _buildSourceOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Color(0xFFFBE9E7), shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFFBF360C)),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
