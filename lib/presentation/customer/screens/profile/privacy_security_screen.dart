import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/viewmodels/auth_viewmodel.dart';
import '../../../../core/utils/translator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/responsive_layout.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _twoFactorAuth = false;

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(Translator.translate('priv_change_pw', context.read<AuthViewModel>().selectedLanguage), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPasswordField(Translator.translate('pw_current', context.read<AuthViewModel>().selectedLanguage)),
            const SizedBox(height: 16),
            _buildPasswordField(Translator.translate('pw_new', context.read<AuthViewModel>().selectedLanguage)),
            const SizedBox(height: 16),
            _buildPasswordField(Translator.translate('pw_confirm', context.read<AuthViewModel>().selectedLanguage)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(Translator.translate('pw_cancel', context.read<AuthViewModel>().selectedLanguage))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(Translator.translate('pw_success', context.read<AuthViewModel>().selectedLanguage)), backgroundColor: Colors.green),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(Translator.translate('pw_update', context.read<AuthViewModel>().selectedLanguage)),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(String label) {
    return TextField(
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    return ResponsiveLayout(
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(Translator.translate('profile_privacy', authVM.selectedLanguage), style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Translator.translate('priv_mgmt', authVM.selectedLanguage),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              Translator.translate('priv_desc', authVM.selectedLanguage),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 32),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 40, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                   _buildSecurityLink(
                    Icons.lock_reset_rounded,
                    Translator.translate('priv_change_pw', authVM.selectedLanguage),
                    Translator.translate('priv_change_pw_desc', authVM.selectedLanguage),
                    _showChangePasswordDialog,
                  ),
                  _buildDivider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.phonelink_lock_rounded, color: AppColors.primary, size: 22),
                      ),
                      title: Text(Translator.translate('priv_2fa', authVM.selectedLanguage), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: Text(Translator.translate('priv_2fa_desc', authVM.selectedLanguage), style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                      trailing: Switch(
                        value: _twoFactorAuth,
                        onChanged: (val) => setState(() => _twoFactorAuth = val),
                        activeThumbColor: AppColors.primary,
                        activeTrackColor: const Color(0xFFFFF3E0),
                      ),
                    ),
                  ),
                  _buildDivider(),
                   _buildSecurityLink(
                    Icons.privacy_tip_outlined,
                    Translator.translate('priv_policy', authVM.selectedLanguage),
                    Translator.translate('priv_policy_desc', authVM.selectedLanguage),
                    () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildSecurityLink(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.grey.shade50, height: 1, indent: 72);
  }
}
