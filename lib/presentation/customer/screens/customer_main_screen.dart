import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'tabs/home_tab.dart';
import 'tabs/my_order_tab.dart';
import 'tabs/profile_tab.dart';
import '../viewmodels/customer_viewmodel.dart';
import 'package:gado_gado_app/presentation/auth/viewmodels/auth_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../../core/utils/translator.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  // Navigation handled by CustomerViewModel
  
  void _navigateToProfile(BuildContext context) {
    context.read<CustomerViewModel>().setTabIndex(2);
  }

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    // Start listening to orders for this user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthViewModel>().currentUser?.id;
      if (userId != null) {
        context.read<CustomerViewModel>().listenToOrders(userId);
      }
    });

    _tabs = [
      HomeTab(onProfileClick: () => _navigateToProfile(context)),
      MyOrderTab(onProfileClick: () => _navigateToProfile(context)),
      const ProfileTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthViewModel, CustomerViewModel>(
      builder: (context, authVM, vm, child) {
        return Scaffold(
          body: IndexedStack(
            index: vm.currentTabIndex,
            children: _tabs,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: vm.currentTabIndex,
              onTap: (index) => vm.setTabIndex(index),
              selectedItemColor: AppColors.primary,
              unselectedItemColor: Colors.grey,
              showSelectedLabels: true,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_outlined),
                  activeIcon: const Icon(Icons.home),
                  label: Translator.translate('nav_home', authVM.selectedLanguage),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.shopping_bag_outlined),
                  activeIcon: const Icon(Icons.shopping_bag),
                  label: Translator.translate('nav_order', authVM.selectedLanguage),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outline),
                  activeIcon: const Icon(Icons.person),
                  label: Translator.translate('nav_profile', authVM.selectedLanguage),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
