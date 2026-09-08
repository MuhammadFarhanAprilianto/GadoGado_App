import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tabs/home_tab.dart';
import 'tabs/my_order_tab.dart';
import 'tabs/profile_tab.dart';
import '../viewmodels/customer_viewmodel.dart';
import 'package:gado_gado_app/presentation/auth/viewmodels/auth_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../../core/utils/translator.dart';
import '../../widgets/responsive_layout.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
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
        final lang = authVM.selectedLanguage;

        final navItems = [
          _NavItemData(
            icon: HugeIcons.strokeRoundedHome01,
            label: Translator.translate('nav_home', lang),
          ),
          _NavItemData(
            icon: HugeIcons.strokeRoundedShoppingBag01,
            label: Translator.translate('nav_order', lang),
          ),
          _NavItemData(
            icon: HugeIcons.strokeRoundedUser,
            label: Translator.translate('nav_profile', lang),
          ),
        ];

        return ResponsiveLayout(
          child: Scaffold(
            extendBody: true,
            body: IndexedStack(
              index: vm.currentTabIndex,
              children: _tabs,
            ),
            bottomNavigationBar: SafeArea(
              top: false,
              bottom: true,
              minimum: const EdgeInsets.only(bottom: 2),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.grey.shade200, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = constraints.maxWidth / navItems.length;

                      return Stack(
                        children: [
                          // 🟠 Smooth Sliding Orange Indicator Pill
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 380),
                            curve: Curves.fastOutSlowIn,
                            left: vm.currentTabIndex * itemWidth,
                            top: 0,
                            bottom: 0,
                            width: itemWidth,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 📱 Clickable Items (Icons & Text)
                          Row(
                            children: List.generate(navItems.length, (index) {
                              final item = navItems[index];
                              final isSelected = vm.currentTabIndex == index;

                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => vm.setTabIndex(index),
                                  behavior: HitTestBehavior.opaque,
                                  child: SizedBox(
                                    height: double.infinity,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        HugeIcon(
                                          icon: item.icon,
                                          color: isSelected ? Colors.white : Colors.grey.shade700,
                                          size: 20.0,
                                        ),
                                        const SizedBox(width: 6),
                                        AnimatedDefaultTextStyle(
                                          duration: const Duration(milliseconds: 300),
                                          style: GoogleFonts.questrial(
                                            fontSize: 13.5,
                                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                            color: isSelected ? Colors.white : Colors.grey.shade700,
                                            letterSpacing: 0.2,
                                          ),
                                          child: Text(
                                            item.label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItemData {
  final dynamic icon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.label,
  });
}
