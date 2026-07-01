import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/translator.dart';
import '../../../../data/models/food_item_model.dart';
import '../../../../data/models/shop_settings_model.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../viewmodels/customer_viewmodel.dart';

class FoodDetailSheet extends StatefulWidget {
  final FoodItemModel item;

  const FoodDetailSheet({super.key, required this.item});

  @override
  State<FoodDetailSheet> createState() => _FoodDetailSheetState();
}

class _FoodDetailSheetState extends State<FoodDetailSheet> {
  bool _isSaved = false;
  final Set<String> _selectedToppingIds = {};
  int _selectedSpicyLevel = 0;

  @override
  Widget build(BuildContext context) {
    final customerVM = context.watch<CustomerViewModel>();
    final authVM = context.watch<AuthViewModel>();
    final isShopClosed = customerVM.shopStatus == ShopStatus.closed;
    final int portionsRemaining = customerVM.getRemainingPortions(widget.item);
    final bool canAddToCart = widget.item.isAvailable && !isShopClosed && portionsRemaining > 0;
    
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final double basePrice = widget.item.price;
    double toppingPrice = 0;
    List<String> selectedToppingNames = [];
    for (var topping in customerVM.toppings) {
      if (_selectedToppingIds.contains(topping.id)) {
        toppingPrice += topping.price;
        selectedToppingNames.add(topping.name);
      }
    }
    final double spicyPrice = _selectedSpicyLevel >= 5 ? 2000 : 0;
    final double totalPrice = basePrice + toppingPrice + spicyPrice;

    List<String> notesParts = [];
    notesParts.add('Level $_selectedSpicyLevel');
    if (selectedToppingNames.isNotEmpty) {
      notesParts.add('Topping: ${selectedToppingNames.join(', ')}');
    }
    final String notesText = notesParts.join(' | ');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Image Section with Mock Badges matching User Request screenshot
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 320,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.red.shade100.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image(
                      image: widget.item.imageProvider,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 48),
                      ),
                    ),
                  ),
                ),

                // Top Left Brand / Promo Badge
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBF360C),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Text(
                      'Mpo Lemez',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                // Halal Indonesia Logo (Top Right)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF673AB7), width: 1.5),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, color: Color(0xFF673AB7), size: 12),
                        SizedBox(width: 4),
                        Text(
                          'HALAL',
                          style: TextStyle(
                            color: Color(0xFF673AB7),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // "30 MENIT LANGSUNG JADI" Center Top Banner
                Positioned(
                  top: 70,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '100% HIGIENIS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            'LANGSUNG JADI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom Left "15 min" Preparation Time Badge
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE040FB), // Magenta/Purple from request image
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.rocket_launch, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          '15 min',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Right Social/Promo Indicators
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.language, color: Colors.white70, size: 10),
                        SizedBox(width: 4),
                        Text(
                          'mpolemez.id',
                          style: TextStyle(color: Colors.white70, fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Name
            Text(
              widget.item.getName(authVM.selectedLanguage),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 24,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              widget.item.getDescription(authVM.selectedLanguage),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // Price & Remaining Stock Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currencyFormatter.format(totalPrice),
                  style: TextStyle(
                    color: canAddToCart ? const Color(0xFFBF360C) : Colors.grey,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    decoration: canAddToCart ? null : TextDecoration.lineThrough,
                  ),
                ),
                if (widget.item.isAvailable && !isShopClosed)
                  Text(
                    portionsRemaining == 0 
                      ? (authVM.selectedLanguage == 'id' ? 'Stok Habis' : 'Out of Stock')
                      : (authVM.selectedLanguage == 'id' ? 'Sisa $portionsRemaining porsi' : '$portionsRemaining portions left'),
                    style: TextStyle(
                      color: portionsRemaining == 0 ? Colors.red : Colors.orange.shade800,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Toppings Section
            if (customerVM.toppings.isNotEmpty) ...[
              const Text(
                'Tambahan Topping',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: customerVM.toppings.map((topping) {
                  final bool isSelected = _selectedToppingIds.contains(topping.id);
                  final bool isAvailable = customerVM.isToppingAvailable(topping);
                  return GestureDetector(
                    onTap: isAvailable ? () {
                      setState(() {
                        if (isSelected) {
                          _selectedToppingIds.remove(topping.id);
                        } else {
                          _selectedToppingIds.add(topping.id);
                        }
                      });
                    } : null,
                    child: Container(
                      width: (MediaQuery.of(context).size.width - 52) / 2, // 2 items per row
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: !isAvailable 
                            ? Colors.grey.shade50 
                            : (isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: !isAvailable
                              ? Colors.grey.shade200
                              : (isSelected ? AppColors.primary : Colors.grey.shade300),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  !isAvailable 
                                      ? Icons.block 
                                      : (isSelected ? Icons.check_circle : Icons.circle_outlined),
                                  color: !isAvailable 
                                      ? Colors.grey 
                                      : (isSelected ? AppColors.primary : Colors.grey),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    topping.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isAvailable ? Colors.black87 : Colors.grey,
                                      decoration: isAvailable ? null : TextDecoration.lineThrough,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            isAvailable 
                                ? '+Rp ${topping.price.toInt()}'
                                : (authVM.selectedLanguage == 'id' ? 'Habis' : 'Out'),
                            style: TextStyle(
                              color: !isAvailable 
                                  ? Colors.red 
                                  : (isSelected ? AppColors.primary : Colors.grey.shade600),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

            // Spicy Level Section
            const Text(
              'Tingkat Kepedasan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(9, (index) {
                final bool isSelected = _selectedSpicyLevel == index;
                final bool isExtraCharge = index >= 5;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSpicyLevel = index;
                    });
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : (isExtraCharge ? Colors.orange.shade50 : Colors.grey.shade50),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : (isExtraCharge ? Colors.orange.shade200 : Colors.grey.shade300),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Lvl $index',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          if (isExtraCharge)
                            Text(
                              '+2k',
                              style: TextStyle(
                                color: isSelected ? Colors.white70 : Colors.orange.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            
            // Spicy Level Note Box (Only visible if Level 5-8 is selected)
            if (_selectedSpicyLevel >= 5) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade900, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ada tambahan biaya Rp 2.000 untuk Level 5-8',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Row of Buttons: Simpan, Lapor, Bagikan
            Row(
              children: [
                // Simpan Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isSaved = !_isSaved;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _isSaved
                                ? (authVM.selectedLanguage == 'id' ? 'Berhasil disimpan ke favorit!' : 'Saved to favorites!')
                                : (authVM.selectedLanguage == 'id' ? 'Dihapus dari favorit.' : 'Removed from favorites.'),
                          ),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: Icon(
                      _isSaved ? Icons.favorite : Icons.favorite_border,
                      color: _isSaved ? Colors.red : Colors.grey.shade700,
                      size: 16,
                    ),
                    label: Text(
                      _isSaved 
                        ? (authVM.selectedLanguage == 'id' ? 'Disimpan' : 'Saved')
                        : (authVM.selectedLanguage == 'id' ? 'Simpan' : 'Save'),
                      style: TextStyle(
                        color: _isSaved ? Colors.red : Colors.grey.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _isSaved ? Colors.red.shade200 : Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Lapor Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showReportDialog(context, authVM.selectedLanguage);
                    },
                    icon: Icon(Icons.report_problem_outlined, color: Colors.grey.shade700, size: 16),
                    label: Text(
                      authVM.selectedLanguage == 'id' ? 'Lapor' : 'Report',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Bagikan Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final shareText = 'Yuk cobain ${widget.item.getName(authVM.selectedLanguage)} di aplikasi Warung Mpo Lemez! Cuma ${currencyFormatter.format(widget.item.price)}.';
                      final messenger = ScaffoldMessenger.of(context);
                      final successMsg = authVM.selectedLanguage == 'id' ? 'Link menu berhasil disalin!' : 'Menu link copied to clipboard!';
                      Clipboard.setData(ClipboardData(text: shareText)).then((_) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(successMsg),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      });
                    },
                    icon: Icon(Icons.share_outlined, color: Colors.grey.shade700, size: 16),
                    label: Text(
                      authVM.selectedLanguage == 'id' ? 'Bagikan' : 'Share',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Large green/primary color button: Tambah pembelian
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: canAddToCart ? () {
                  customerVM.addToCart(
                    widget.item,
                    notes: notesText,
                    customPrice: totalPrice,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${widget.item.getName(authVM.selectedLanguage)} ${Translator.translate('toast_added_to_cart', authVM.selectedLanguage)}'),
                      duration: const Duration(milliseconds: 1500),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.primary,
                    ),
                  );
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAddToCart ? Colors.green.shade800 : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  !widget.item.isAvailable
                      ? (authVM.selectedLanguage == 'id' ? 'Stok Habis' : 'Out of Stock')
                      : isShopClosed
                          ? (authVM.selectedLanguage == 'id' ? 'Warung Tutup' : 'Shop Closed')
                          : portionsRemaining <= 0
                              ? (authVM.selectedLanguage == 'id' ? 'Stok Bahan Habis' : 'No Ingredient Stock')
                              : (authVM.selectedLanguage == 'id' ? 'Tambah pembelian' : 'Add to purchase'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context, String lang) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(lang == 'id' ? 'Laporkan Menu' : 'Report Menu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(lang == 'id' ? 'Gambar tidak sesuai' : 'Image is incorrect'),
                onTap: () => _submitReport(context, lang),
              ),
              ListTile(
                title: Text(lang == 'id' ? 'Deskripsi salah atau tidak pantas' : 'Description is wrong or inappropriate'),
                onTap: () => _submitReport(context, lang),
              ),
              ListTile(
                title: Text(lang == 'id' ? 'Harga tidak sesuai' : 'Price is incorrect'),
                onTap: () => _submitReport(context, lang),
              ),
            ],
          ),
        );
      },
    );
  }

  void _submitReport(BuildContext context, String lang) {
    Navigator.pop(context); // Close dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          lang == 'id' 
            ? 'Laporan berhasil dikirim. Terima kasih atas masukan Anda!' 
            : 'Report submitted successfully. Thank you for your feedback!',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
