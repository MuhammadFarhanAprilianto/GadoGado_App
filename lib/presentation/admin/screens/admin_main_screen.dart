import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/translator.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import 'tabs/admin_home_tab.dart';
import 'tabs/admin_stock_tab.dart';
import 'tabs/admin_profile_tab.dart';
import '../../widgets/responsive_layout.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final lang = authVM.selectedLanguage;

    final List<Widget> tabs = [
      const AdminHomeTab(),
      const AdminStockTab(),
      const AdminProfileTab(),
    ];

    return ResponsiveLayout(
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: tabs,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined), 
              label: Translator.translate('nav_home', lang)
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.inventory_2_outlined), 
              label: Translator.translate('nav_stock', lang)
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline), 
              label: Translator.translate('nav_profile', lang)
            ),
          ],
        ),
      ),
    );
  }
}

