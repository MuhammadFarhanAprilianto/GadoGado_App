import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gado_gado_app/core/utils/menu_id_helper.dart';
import 'package:gado_gado_app/data/models/order_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MigrationApp());
}

class MigrationApp extends StatefulWidget {
  const MigrationApp({super.key});

  @override
  State<MigrationApp> createState() => _MigrationAppState();
}

class _MigrationAppState extends State<MigrationApp> {
  String _status = 'Ready to migrate...';
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runMigration();
    });
  }

  Future<void> _runMigration() async {
    setState(() {
      _isRunning = true;
      _status = 'Starting Menu ID Migration...';
    });
    print(_status);

    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Fetch all menu items
      setState(() => _status = 'Fetching menu items...');
      print(_status);
      final menuSnapshot = await firestore.collection('menu').get();
      
      final idMap = <String, String>{};
      final categoryIndexMax = <String, int>{};
      
      categoryIndexMax['Makanan Utama'] = 0;
      categoryIndexMax['Drinks'] = 0;
      categoryIndexMax['Snack'] = 0;
      categoryIndexMax['Others'] = 0;

      final formatRegex = RegExp(r'^#?([A-D])(\d+)0_.*$');
      for (var doc in menuSnapshot.docs) {
        final oldId = doc.id;
        final match = formatRegex.firstMatch(oldId);
        if (match != null) {
          final categoryLetter = match.group(1);
          final index = int.tryParse(match.group(2) ?? '0') ?? 0;
          
          String categoryName = 'Others';
          if (categoryLetter == 'A') categoryName = 'Makanan Utama';
          if (categoryLetter == 'B') categoryName = 'Drinks';
          if (categoryLetter == 'C') categoryName = 'Snack';
          
          if (index > (categoryIndexMax[categoryName] ?? 0)) {
            categoryIndexMax[categoryName] = index;
          }
          idMap[oldId] = oldId;
        }
      }

      for (var doc in menuSnapshot.docs) {
        final oldId = doc.id;
        if (idMap.containsKey(oldId)) continue;

        final data = doc.data();
        final category = data['kategori'] ?? data['category'] ?? 'Others';
        final name = data['nama'] ?? data['name'] ?? 'Unnamed';
        
        final letter = MenuIdHelper.getCategoryLetter(category);
        String cleanCategoryName = 'Others';
        if (letter == 'A') cleanCategoryName = 'Makanan Utama';
        if (letter == 'B') cleanCategoryName = 'Drinks';
        if (letter == 'C') cleanCategoryName = 'Snack';

        final nextIndex = (categoryIndexMax[cleanCategoryName] ?? 0) + 1;
        categoryIndexMax[cleanCategoryName] = nextIndex;

        final cleanName = MenuIdHelper.cleanMenuName(name);
        final newId = '#$letter${nextIndex}0_$cleanName';

        setState(() => _status = 'Migrating menu "$oldId" ➔ "$newId"');
        print(_status);
        await firestore.collection('menu').doc(newId).set(data);
        await firestore.collection('menu').doc(oldId).delete();

        idMap[oldId] = newId;
      }

      setState(() => _status = 'Migrating order details collection...');
      print(_status);
      final detailSnapshot = await firestore.collection('detail').get();
      final ordersSnapshot = await firestore.collection('orders').get();
      final ordersMap = {for (var doc in ordersSnapshot.docs) doc.id: doc.data()};

      int detailUpdatedCount = 0;
      for (var doc in detailSnapshot.docs) {
        final detailData = doc.data();
        final oldMenuId = detailData['id_menu'] ?? '';
        
        String normalizedOldMenuId = oldMenuId;
        final match = formatRegex.firstMatch(oldMenuId);
        if (match != null) {
          normalizedOldMenuId = MenuIdHelper.normalizeMenuId(oldMenuId);
        }

        if (idMap.containsKey(normalizedOldMenuId)) {
          final newBaseMenuId = idMap[normalizedOldMenuId]!;
          final orderId = detailData['id_order'] ?? '';
          final orderData = ordersMap[orderId];
          
          ServiceType serviceType = ServiceType.dineIn;
          if (orderData != null && orderData.containsKey('serviceType')) {
            final sTypeName = orderData['serviceType'] as String;
            serviceType = ServiceType.values.firstWhere(
              (e) => e.name == sTypeName,
              orElse: () => ServiceType.dineIn,
            );
          }

          final newMenuIdWithService = MenuIdHelper.applyServiceTypeToMenuId(newBaseMenuId, serviceType);

          if (newMenuIdWithService != oldMenuId) {
            setState(() => _status = 'Updating detail ${doc.id}\n"$oldMenuId" ➔ "$newMenuIdWithService"');
            print(_status);
            await firestore.collection('detail').doc(doc.id).update({
              'id_menu': newMenuIdWithService,
            });
            detailUpdatedCount++;
          }
        }
      }

      setState(() {
        _isRunning = false;
        _status = 'Success!\nMigrated ${idMap.length} menu items.\nUpdated $detailUpdatedCount detail documents.';
      });
      print(_status);
    } catch (e) {
      setState(() {
        _isRunning = false;
        _status = 'Error: $e';
      });
      print(_status);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Menu ID Migration Tool')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                if (_isRunning)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _runMigration,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                    child: const Text('Run Migration Now'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
