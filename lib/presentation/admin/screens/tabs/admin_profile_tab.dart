import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/viewmodels/auth_viewmodel.dart';
import '../../../customer/screens/profile/edit_profile_screen.dart';
import '../profile/notification_settings_screen.dart';
import '../profile/change_password_screen.dart';
import '../../../../core/utils/translator.dart';

class AdminProfileTab extends StatelessWidget {
  const AdminProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final user = authVM.currentUser;

    return Scaffold(
      backgroundColor: Colors.white, // Changed from grey.shade50 to match reference
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
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Hero Profile Section
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primary, width: 2),
                            shape: BoxShape.circle,
                          ),
                          child: InkWell(
                            onTap: () => _showImageSourceActionSheet(context, authVM),
                            customBorder: const CircleShape(),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: user?.profileImageProvider,
                              child: user?.profilePic == null 
                                  ? const Icon(Icons.person, size: 60, color: Colors.grey)
                                  : null,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 8, bottom: 8,
                          child: Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFF9BED9B),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      user?.name ?? Translator.translate('role_admin', authVM.selectedLanguage),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${Translator.translate('admin_employee_id', authVM.selectedLanguage)}: #${user?.id.substring(user.id.length > 8 ? user.id.length - 8 : 0).toUpperCase() ?? "UNKNOWN"}',
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA5F0A5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline, color: Color(0xFF1B5E20), size: 18),
                          const SizedBox(width: 8),
                          Text(Translator.translate('admin_shift_active', authVM.selectedLanguage), style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Current Work Shift Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(Translator.translate('admin_current_shift', authVM.selectedLanguage), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                        Icon(Icons.access_time, color: Colors.brown.shade400, size: 24),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(Translator.translate('admin_shift_time', authVM.selectedLanguage), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${Translator.translate('admin_shift_morning', authVM.selectedLanguage)} • ${Translator.translate('admin_shift_counter', authVM.selectedLanguage)}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),

              const SizedBox(height: 20),

               // Stats Row
              Row(
                children: [
                  _buildStatCard(Translator.translate('report_avg_service', authVM.selectedLanguage), '3m 12s', Icons.timer_outlined, const Color(0xFFF2FBF6)),
                ],
              ),

              const SizedBox(height: 40),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(Translator.translate('profile_account_settings', authVM.selectedLanguage), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),

              // Settings List
              _buildSettingsTile(Icons.person_outline, Translator.translate('profile_personal_info', authVM.selectedLanguage), null, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
              }),
              _buildSettingsTile(Icons.notifications_none, Translator.translate('profile_notifications', authVM.selectedLanguage), null, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()));
              }),
              _buildSettingsTile(Icons.lock_outline, Translator.translate('priv_change_pw', authVM.selectedLanguage), null, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()));
              }),

              const SizedBox(height: 16),

              // Logout Button
              GestureDetector(
                onTap: () => _confirmLogout(context, authVM),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.logout, color: Color(0xFFC62828)),
                      const SizedBox(width: 16),
                      Text(Translator.translate('profile_sign_out', authVM.selectedLanguage), style: const TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
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
             Icon(icon, color: AppColors.primary, size: 24),
             const SizedBox(height: 12),
             Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
             Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String? trailingText, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade50),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF2E8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              if (trailingText != null) 
                Text(trailingText, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }


  void _confirmLogout(BuildContext context, AuthViewModel authVM) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(Translator.translate('admin_logout_confirm_title', authVM.selectedLanguage), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(Translator.translate('admin_logout_confirm_content', authVM.selectedLanguage)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(Translator.translate('pw_cancel', authVM.selectedLanguage))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              authVM.logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(Translator.translate('admin_logout_confirm_title', authVM.selectedLanguage)),
          ),
        ],
      ),
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(Translator.translate('profile_uploading', vm.selectedLanguage)), duration: const Duration(seconds: 2)),
          );
        }
        
        await vm.saveProfilePersistently(imageFile: File(image.path));
        
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(Translator.translate('profile_updated', vm.selectedLanguage)), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${Translator.translate('error_generic', vm.selectedLanguage)}: $e'), backgroundColor: Colors.red),
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
            Text(Translator.translate('admin_change_pic_title', vm.selectedLanguage), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(context, Icons.camera_alt_rounded, Translator.translate('profile_camera', vm.selectedLanguage), () => _pickImage(context, vm, ImageSource.camera)),
                _buildSourceOption(context, Icons.photo_library_rounded, Translator.translate('profile_gallery', vm.selectedLanguage), () => _pickImage(context, vm, ImageSource.gallery)),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption(BuildContext context, IconData icon, String label, VoidCallback onTap) {
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

class CircleShape extends ShapeBorder {
  const CircleShape();
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path()..addOval(rect);
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => Path()..addOval(rect);
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}
  @override
  ShapeBorder scale(double t) => this;
}
