import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/translator.dart';
import '../../../auth/viewmodels/auth_viewmodel.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(Translator.translate('notif_settings_title', authVM.selectedLanguage), style: const TextStyle(fontWeight: FontWeight.bold)),
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
              Translator.translate('notif_manage_title', authVM.selectedLanguage),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 8),
            Text(
              Translator.translate('notif_manage_desc', authVM.selectedLanguage),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 32),

            _buildSettingCard(
              title: Translator.translate('notif_app_title', authVM.selectedLanguage),
              subtitle: Translator.translate('notif_app_desc', authVM.selectedLanguage),
              icon: Icons.notifications_active_outlined,
              value: authVM.appNotifications,
              onChanged: (val) => authVM.toggleNotifications('app'),
            ),
            const SizedBox(height: 16),
            _buildSettingCard(
              title: Translator.translate('notif_daily_report_title', authVM.selectedLanguage),
              subtitle: Translator.translate('notif_daily_report_desc', authVM.selectedLanguage),
              icon: Icons.analytics_outlined,
              value: authVM.emailAlerts,
              onChanged: (val) => authVM.toggleNotifications('email'),
            ),
            const SizedBox(height: 16),
            _buildSettingCard(
              title: Translator.translate('notif_system_update_title', authVM.selectedLanguage),
              subtitle: Translator.translate('notif_system_update_desc', authVM.selectedLanguage),
              icon: Icons.system_update_alt_rounded,
              value: authVM.specialOffers,
              onChanged: (val) => authVM.toggleNotifications('offers'),
            ),

            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFBE9E7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFBF360C)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      Translator.translate('notif_sync_desc', authVM.selectedLanguage),
                      style: TextStyle(color: Colors.brown.shade800, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF2E8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, height: 1.4)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
