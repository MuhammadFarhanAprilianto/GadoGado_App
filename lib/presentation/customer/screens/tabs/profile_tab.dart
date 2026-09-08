import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/viewmodels/auth_viewmodel.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/notification_settings_screen.dart';
import '../profile/privacy_security_screen.dart';
import '../../../../core/utils/translator.dart';
import '../../../widgets/warung_logo.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final user = authVM.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            
            // Interactive Avatar
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => _showImageSourceActionSheet(context, authVM),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
                      ),
                      child: CircleAvatar(
                        radius: 54,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: user?.profileImageProvider,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _showImageSourceActionSheet(context, authVM),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            Text(
              user?.name ?? 'Elena Rodriguez',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            Text(
              user?.email ?? 'elena.rod@example.com',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 32),
            
            // Settings List
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 40, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  _buildSettingItem(
                    context,
                    Icons.person_outline_rounded,
                    Translator.translate('profile_personal_info', authVM.selectedLanguage),
                    const EditProfileScreen(),
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    context,
                    Icons.notifications_none_rounded,
                    Translator.translate('profile_notifications', authVM.selectedLanguage),
                    const NotificationSettingsScreen(),
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    context,
                    Icons.security_rounded,
                    Translator.translate('profile_privacy', authVM.selectedLanguage),
                    const PrivacySecurityScreen(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            
            TextButton.icon(
              onPressed: () => authVM.logout(),
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFD84315), size: 18),
              label: Text(
                Translator.translate('profile_sign_out', authVM.selectedLanguage),
                style: const TextStyle(color: Color(0xFFD84315), fontWeight: FontWeight.w900, fontSize: 15),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: const Color(0xFFFBE9E7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.grey.shade50, height: 1, indent: 64);
  }

  Widget _buildSettingItem(BuildContext context, IconData icon, String title, Widget? destination, {VoidCallback? onTapOverride}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A1A)),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
      onTap: onTapOverride ?? () {
        if (destination != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
        }
      },
    );
  }

  Future<void> _pickImage(BuildContext context, AuthViewModel vm, ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      
      if (image != null) {
        // Show loading indicator
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(Translator.translate('profile_uploading', vm.selectedLanguage)), duration: const Duration(seconds: 2)),
          );
        }
        
        // Persist immediately to cloud
        await vm.saveProfilePersistently(imageFile: File(image.path));
        
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(Translator.translate('profile_upload_success', vm.selectedLanguage)), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${Translator.translate('profile_upload_fail', vm.selectedLanguage)}: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showImageSourceActionSheet(BuildContext context, AuthViewModel vm) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(Translator.translate('profile_change_pic', vm.selectedLanguage), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(Icons.camera_alt_rounded, Translator.translate('profile_camera', vm.selectedLanguage), () => _pickImage(context, vm, ImageSource.camera)),
                _buildSourceOption(Icons.photo_library_rounded, Translator.translate('profile_gallery', vm.selectedLanguage), () => _pickImage(context, vm, ImageSource.gallery)),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Color(0xFFFFF3E0), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}


