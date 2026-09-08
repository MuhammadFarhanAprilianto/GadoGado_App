import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/viewmodels/auth_viewmodel.dart';
import '../../viewmodels/owner_view_model.dart';
import '../../../customer/screens/profile/edit_profile_screen.dart';
import '../../../admin/screens/profile/notification_settings_screen.dart';
import '../../../admin/screens/profile/change_password_screen.dart';
import 'package:gado_gado_app/presentation/admin/viewmodels/admin_view_model.dart';
import 'package:gado_gado_app/presentation/customer/viewmodels/customer_viewmodel.dart';
import '../../providers/owner_navigation_provider.dart';
import 'package:intl/intl.dart';
import '../../../widgets/warung_logo.dart';

class OwnerProfileTab extends StatefulWidget {
  const OwnerProfileTab({super.key});

  @override
  State<OwnerProfileTab> createState() => _OwnerProfileTabState();
}

class _OwnerProfileTabState extends State<OwnerProfileTab> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source, AuthViewModel authVM) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1000,
      );

      if (pickedFile != null && mounted) {
        final success = await authVM.saveProfilePersistently(
          imageFile: File(pickedFile.path),
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto profil berhasil diperbarui!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil gambar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showImageSourceActionSheet(BuildContext context, AuthViewModel authVM) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ganti Foto Profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Kamera',
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera, authVM);
                  },
                ),
                _buildSourceOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Galeri',
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery, authVM);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final ownerVM = context.watch<OwnerViewModel>();
    final customerVM = context.watch<CustomerViewModel>();
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
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
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
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: () => _showImageSourceActionSheet(context, authVM),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: user?.profileImageProvider,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _showImageSourceActionSheet(context, authVM),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                      child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 16),
                    ),
                  ),
                ),
                if (authVM.isLoading)
                  const Positioned.fill(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const EditProfileScreen())),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(user?.name ?? 'Owner', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
                ],
              ),
            ),
            const Text('Pendiri Utama sejak 2018', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBadge('PEMILIK', AppColors.success),
                const SizedBox(width: 8),
                _buildBadge('PAKET PREMIUM', const Color(0xFFFFB300)),
              ],
            ),
            const SizedBox(height: 32),
            
            // Performance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFE65100), Color(0xFFFF9100)]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Pendapatan (Bulanan)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(
                    NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(ownerVM.totalRevenue), 
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                  ),
                  Text(ownerVM.revenueTrend, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<OwnerNavigationProvider>().setIndex(1);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.2), foregroundColor: Colors.white),
                    child: const Text('Lihat Statistik Detail'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            _buildSectionHeader(Icons.business_center_outlined, 'Detail Bisnis', isCentered: true),
            const SizedBox(height: 16),
            _buildInfoRow('NAMA USAHA', 'Warung Mpo Lemez', isCentered: true),
            _buildInfoRow('KATEGORI BISNIS', 'Kuliner Tradisional Betawi', isCentered: true),
            _buildInfoRow('LOKASI UTAMA', customerVM.shopAddress, isCentered: true),
            _buildInfoRow('ID BISNIS', 'MLZ-JKT-13520-2018', isCentered: true),
            
            const SizedBox(height: 32),
            _buildSectionHeader(Icons.settings_outlined, 'Pengaturan Akun'),
            const SizedBox(height: 16),
            _buildSettingTile(
              Icons.notifications_none, 
              'Notifikasi', 
              'Kelola peringatan dan pembaruan pesanan',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const NotificationSettingsScreen())),
            ),
            _buildSettingTile(
              Icons.security_outlined, 
              'Keamanan', 
              'Autentikasi dua faktor dan kata sandi',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ChangePasswordScreen())),
            ),
            _buildSettingTile(
              Icons.location_on_outlined, 
              'Lokasi Warung', 
              'Perbarui koordinat fisik dan alamat warung',
              onTap: () => _showShopLocationDialog(context),
            ),
            
            const SizedBox(height: 40),
            OutlinedButton.icon(
              onPressed: () => authVM.logout(),
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text('Keluar', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                side: BorderSide(color: Colors.grey.shade200),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, {bool isCentered = false}) {
    return Row(
      mainAxisAlignment: isCentered ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.brown),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isCentered = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isCentered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            label, 
            style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
            textAlign: isCentered ? TextAlign.center : TextAlign.start,
          ),
          const SizedBox(height: 4),
          Text(
            value, 
            style: const TextStyle(fontWeight: FontWeight.w600),
            textAlign: isCentered ? TextAlign.center : TextAlign.start,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, String subtitle, {required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle), child: Icon(icon, color: AppColors.textMain, size: 20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      contentPadding: EdgeInsets.zero,
    );
  }
  void _showShopLocationDialog(BuildContext context) {
    final customerVM = context.read<CustomerViewModel>();
    final adminVM = context.read<AdminViewModel>();

    final latController = TextEditingController(text: customerVM.shopLatLng.latitude.toString());
    final lngController = TextEditingController(text: customerVM.shopLatLng.longitude.toString());
    final addressController = TextEditingController(text: customerVM.shopAddress);

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Lokasi Warung', style: TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Koordinat Latitude:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: latController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'Contoh: -6.274442',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Latitude tidak boleh kosong';
                    if (double.tryParse(val) == null) return 'Format angka tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text('Koordinat Longitude:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: lngController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'Contoh: 106.858739',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Longitude tidak boleh kosong';
                    if (double.tryParse(val) == null) return 'Format angka tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text('Alamat Warung:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: addressController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Masukkan alamat lengkap warung',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Alamat tidak boleh kosong';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final double lat = double.parse(latController.text.trim());
                final double lng = double.parse(lngController.text.trim());
                final String address = addressController.text.trim();

                try {
                  Navigator.pop(ctx);
                  await adminVM.updateShopLocation(lat, lng, address);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lokasi warung berhasil diperbarui!'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal memperbarui lokasi: $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
