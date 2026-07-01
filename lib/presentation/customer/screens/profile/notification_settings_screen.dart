import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/viewmodels/auth_viewmodel.dart';
import '../../../../core/utils/translator.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(Translator.translate('profile_notifications', authVM.selectedLanguage), style: const TextStyle(fontWeight: FontWeight.bold)),
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
              Translator.translate('notif_pref', authVM.selectedLanguage),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              Translator.translate('notif_desc', authVM.selectedLanguage),
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
                  _buildToggleItem(
                    context,
                    Icons.notifications_active_outlined,
                    Translator.translate('notif_push', authVM.selectedLanguage),
                    Translator.translate('notif_push_desc', authVM.selectedLanguage),
                    authVM.appNotifications,
                    () => authVM.toggleNotifications('app'),
                  ),
                  _buildDivider(),
                  _buildToggleItem(
                    context,
                    Icons.email_outlined,
                    Translator.translate('notif_email', authVM.selectedLanguage),
                    Translator.translate('notif_email_desc', authVM.selectedLanguage),
                    authVM.emailAlerts,
                    () => authVM.toggleNotifications('email'),
                  ),
                  _buildDivider(),
                  _buildToggleItem(
                    context,
                    Icons.local_offer_outlined,
                    Translator.translate('notif_offers', authVM.selectedLanguage),
                    Translator.translate('notif_offers_desc', authVM.selectedLanguage),
                    authVM.specialOffers,
                    () => authVM.toggleNotifications('offers'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem(BuildContext context, IconData icon, String title, String subtitle, bool value, VoidCallback onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFFBF360C), size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        trailing: Switch(
          value: value,
          onChanged: (_) => onChanged(),
          activeThumbColor: const Color(0xFFBF360C),
          activeTrackColor: const Color(0xFFFBE9E7),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.grey.shade50, height: 1, indent: 72);
  }
}
