import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/src/pigeon/mocks.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gado_gado_app/main.dart';
import 'package:gado_gado_app/presentation/auth/viewmodels/auth_viewmodel.dart';
import 'package:gado_gado_app/presentation/customer/viewmodels/customer_viewmodel.dart';
import 'package:gado_gado_app/presentation/admin/viewmodels/admin_view_model.dart';
import 'package:gado_gado_app/presentation/owner/viewmodels/owner_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Firebase.initializeApp();
    await Supabase.initialize(
      url: 'https://fnpejjeyvokekupjkzcj.supabase.co',
      anonKey: 'sb_publishable_mY0X_0uhuHf67qJtUqafPA_cGwpxOw5',
    );
  });

  testWidgets('App starts at login screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // In order for the app to build, we must provide the same ViewModels as in main()
    await tester.pumpWidget(
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

    // Verify that our app starts with the login screen by finding common text
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    
    // Check for a part of the slogan
    expect(find.textContaining('Authentic Indonesian heritage'), findsOneWidget);
  });
}
