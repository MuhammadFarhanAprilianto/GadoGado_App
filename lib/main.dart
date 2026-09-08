import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'presentation/auth/viewmodels/auth_viewmodel.dart';
import 'presentation/auth/screens/login_screen.dart';
import 'presentation/customer/screens/customer_main_screen.dart';
import 'presentation/admin/screens/admin_main_screen.dart';
import 'presentation/owner/screens/owner_main_screen.dart';
import 'core/constants/app_constants.dart';

import 'presentation/customer/viewmodels/customer_viewmodel.dart';
import 'presentation/admin/viewmodels/admin_view_model.dart';
import 'presentation/owner/viewmodels/owner_view_model.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await Supabase.initialize(
    url: 'https://fnpejjeyvokekupjkzcj.supabase.co',
    anonKey: 'sb_publishable_mY0X_0uhuHf67qJtUqafPA_cGwpxOw5',
  );

  await initializeDateFormatting('id_ID', null);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => CustomerViewModel()),
        ChangeNotifierProvider(create: (_) => AdminViewModel()),
        ChangeNotifierProvider(create: (_) => OwnerViewModel()),
      ],
      child: const MpoLemezzApp(),
    ),
  );
}

class MpoLemezzApp extends StatelessWidget {
  const MpoLemezzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Warung Mpo Lemez',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      scrollBehavior: const NoStretchScrollBehavior(),
      home: Consumer<AuthViewModel>(
        builder: (context, auth, _) {
          // Tampilkan splash/loading saat sedang memeriksa sesi yang tersimpan
          if (auth.isInitializing) {
            return const _SplashScreen();
          }

          // Setelah inisialisasi selesai, arahkan berdasarkan status auth
          if (auth.isAuthenticated) {
            switch (auth.currentUser!.role) {
              case AppConstants.roleCustomer:
                return const CustomerMainScreen();
              case AppConstants.roleAdmin:
                return const AdminMainScreen();
              case AppConstants.roleOwner:
                return const OwnerMainScreen();
              default:
                return const LoginScreen();
            }
          }

          return const LoginScreen();
        },
      ),
    );
  }
}

/// Layar splash sederhana yang ditampilkan saat app memeriksa sesi login yang tersimpan.
/// Mencegah flicker ke LoginScreen sebelum auth state selesai dimuat.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo placeholder — ganti dengan logo asli jika ada
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                size: 56,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'MPO LEMEZZ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Point of Sale System',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Menghilangkan efek overscroll stretch (ketarik / membesar) di Android 12+
/// dan membuat scroll meluncur halus (tidak melompat atau terlalu cepat).
class NoStretchScrollBehavior extends MaterialScrollBehavior {
  const NoStretchScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const SmoothClampingScrollPhysics();
  }
}

class SmoothClampingScrollPhysics extends ClampingScrollPhysics {
  const SmoothClampingScrollPhysics({super.parent});

  @override
  SmoothClampingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SmoothClampingScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double get minFlingVelocity => 50.0;

  @override
  double get maxFlingVelocity => 6000.0;

  @override
  double get dragStartDistanceMotionThreshold => 3.5;
}

