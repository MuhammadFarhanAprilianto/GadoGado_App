import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'tabs/owner_home_tab.dart';
import 'tabs/owner_history_tab.dart';
import 'tabs/owner_stock_tab.dart';
import 'tabs/owner_profile_tab.dart';
import 'package:provider/provider.dart';
import '../providers/owner_navigation_provider.dart';

class OwnerMainScreen extends StatefulWidget {
  const OwnerMainScreen({super.key});

  @override
  State<OwnerMainScreen> createState() => _OwnerMainScreenState();
}

class _OwnerMainScreenState extends State<OwnerMainScreen> {

  final List<Widget> _tabs = [
    const OwnerHomeTab(),
    const OwnerHistoryTab(),
    const OwnerStockTab(),
    const OwnerProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OwnerNavigationProvider(),
      child: Consumer<OwnerNavigationProvider>(
        builder: (context, navProv, _) {
          return Scaffold(
            body: _tabs[navProv.currentIndex],
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: navProv.currentIndex,
              onTap: (index) => navProv.setIndex(index),
              selectedItemColor: AppColors.primary,
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Beranda'),
                BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
                BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Stok'),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
              ],
            ),
          );
        },
      ),
    );
  }
}
