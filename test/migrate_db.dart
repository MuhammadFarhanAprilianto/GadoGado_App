import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() {
  test('Migrate Firestore Database to Indonesian Schema', () async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    final firestore = FirebaseFirestore.instance;
    print('Starting Firestore Migration...');

    final uidMap = <String, String>{};

    // 1. Migrate Collection: users to User_XX format
    print('Migrating users to User_XX format...');
    final usersSnapshot = await firestore.collection('users').get();
    final regex = RegExp(r'^User_\d+$');
    
    int maxNumber = 0;
    // First, find the max User_XX number among existing correctly formatted docs
    for (var doc in usersSnapshot.docs) {
      final match = RegExp(r'^User_(\d+)$').firstMatch(doc.id);
      if (match != null) {
        final numVal = int.tryParse(match.group(1) ?? '0') ?? 0;
        if (numVal > maxNumber) {
          maxNumber = numVal;
        }
      }
    }

    for (var doc in usersSnapshot.docs) {
      final data = doc.data();
      final updates = <String, dynamic>{};

      if (data.containsKey('name')) updates['nama'] = data['name'];
      if (data.containsKey('phone')) updates['hp'] = data['phone'];
      
      if (data.containsKey('role')) {
        final role = data['role'].toString().toLowerCase();
        if (role == 'customer') {
          updates['role'] = 'pelanggan';
        } else {
          updates['role'] = role;
        }
      }

      if (data.containsKey('profilePic')) updates['avatar_url'] = data['profilePic'];

      // Merge other fields
      data.forEach((key, value) {
        if (key != 'name' && key != 'phone' && key != 'role' && key != 'profilePic' &&
            key != 'nama' && key != 'hp' && key != 'avatar_url') {
          updates[key] = value;
        } else if (key == 'nama' || key == 'hp' || key == 'avatar_url' || key == 'role') {
          updates[key] = updates[key] ?? value;
        }
      });

      if (regex.hasMatch(doc.id)) {
        // Already formatted, just update fields if needed
        if (updates.isNotEmpty) {
          await firestore.collection('users').doc(doc.id).update(updates);
        }
        uidMap[doc.id] = doc.id;
      } else {
        // Needs rename to User_XX
        maxNumber++;
        final nextDocId = 'User_${maxNumber.toString().padLeft(2, '0')}';
        
        await firestore.collection('users').doc(nextDocId).set(updates);
        await firestore.collection('users').doc(doc.id).delete();
        uidMap[doc.id] = nextDocId;
        print('Migrated user document from ${doc.id} to $nextDocId');
      }
    }

    // 2. Migrate Collection: menu
    print('Migrating menu...');
    final menuSnapshot = await firestore.collection('menu').get();
    for (var doc in menuSnapshot.docs) {
      final data = doc.data();
      final updates = <String, dynamic>{};

      if (data.containsKey('name')) updates['nama'] = data['name'];
      if (data.containsKey('price')) updates['harga'] = data['price'];
      if (data.containsKey('description')) updates['deskr'] = data['description'];
      if (data.containsKey('image')) updates['gambar'] = data['image'];
      if (data.containsKey('category')) updates['kategori'] = data['category'];
      if (data.containsKey('isAvailable')) updates['tersedia'] = data['isAvailable'];
      if (data.containsKey('isBestSeller')) updates['terlaris'] = data['isBestSeller'];
      if (data.containsKey('isNew')) updates['baru'] = data['isNew'];

      if (data.containsKey('recipe')) {
        final List recipeList = data['recipe'] as List;
        updates['resep'] = recipeList.map((item) {
          final map = item as Map<String, dynamic>;
          return {
            'id_bahan': map['ingredientId'] ?? map['id_bahan'] ?? '',
            'nama_bahan': map['ingredientName'] ?? map['nama_bahan'] ?? '',
            'jumlah_per_porsi': map['quantityPerPortion'] ?? map['jumlah_per_porsi'] ?? 0,
          };
        }).toList();
      }

      if (updates.isNotEmpty) {
        await firestore.collection('menu').doc(doc.id).update(updates);
        await firestore.collection('menu').doc(doc.id).update({
          'name': FieldValue.delete(),
          'price': FieldValue.delete(),
          'description': FieldValue.delete(),
          'image': FieldValue.delete(),
          'category': FieldValue.delete(),
          'isAvailable': FieldValue.delete(),
          'isBestSeller': FieldValue.delete(),
          'isNew': FieldValue.delete(),
          'recipe': FieldValue.delete(),
        });
        print('Migrated menu item: ${doc.id}');
      }
    }

    // 3. Migrate Collection: ingredients -> bahan
    print('Migrating ingredients to bahan...');
    final ingredientsSnapshot = await firestore.collection('ingredients').get();
    for (var doc in ingredientsSnapshot.docs) {
      final data = doc.data();
      final newBahan = {
        'nama_bahan': data['name'] ?? '',
        'stok': data['amount'] ?? 0,
        'satuan': data['unit'] ?? '',
        'kategori': data['category'] ?? 'Umum',
        'ambang_batas_stok': data['minStockThreshold'] ?? 5,
        'timestamp': data['timestamp'] ?? FieldValue.serverTimestamp(),
      };

      await firestore.collection('bahan').doc(doc.id).set(newBahan);
      await firestore.collection('ingredients').doc(doc.id).delete();
      print('Migrated ingredient to bahan: ${doc.id}');
    }

    // 4. Migrate Collection: expenses -> restock
    print('Migrating expenses to restock...');
    final expensesSnapshot = await firestore.collection('expenses').get();
    for (var doc in expensesSnapshot.docs) {
      final data = doc.data();
      final oldUserId = data['userId'] ?? 'system_migration';
      final mappedUserId = uidMap[oldUserId] ?? oldUserId;
      final newRestock = {
        'id_bahan': data['ingredientId'] ?? '',
        'id_user': mappedUserId,
        'jumlah': data['amount'] ?? 0,
        'biaya': data['cost'] ?? 0,
        'tanggal': data['timestamp'] ?? FieldValue.serverTimestamp(),
        'keterangan': 'Migrated expense for ${data['ingredientName'] ?? 'Bahan'}',
      };

      await firestore.collection('restock').doc(doc.id).set(newRestock);
      await firestore.collection('expenses').doc(doc.id).delete();
      print('Migrated expense to restock: ${doc.id}');
    }

    // Sync any existing restock references
    final restockSnapshot = await firestore.collection('restock').get();
    for (var doc in restockSnapshot.docs) {
      final data = doc.data();
      final oldUserId = data['id_user'];
      if (oldUserId != null && uidMap.containsKey(oldUserId)) {
        await firestore.collection('restock').doc(doc.id).update({
          'id_user': uidMap[oldUserId],
        });
      }
    }

    // 5. Migrate Collection: orders & detail
    print('Migrating orders & creating details...');
    final ordersSnapshot = await firestore.collection('orders').get();
    for (var doc in ordersSnapshot.docs) {
      final data = doc.data();
      final updates = <String, dynamic>{};

      if (data.containsKey('userId')) {
        final oldUserId = data['userId'];
        updates['id_user'] = uidMap[oldUserId] ?? oldUserId;
      }
      if (data.containsKey('id_user')) {
        final oldUserId = data['id_user'];
        if (uidMap.containsKey(oldUserId)) {
          updates['id_user'] = uidMap[oldUserId];
        }
      }
      
      if (data.containsKey('totalAmount')) updates['total'] = data['totalAmount'];
      if (data.containsKey('tax')) updates['pajak'] = data['tax'];
      if (data.containsKey('serviceCharge')) updates['biaya_layanan'] = data['serviceCharge'];
      if (data.containsKey('serviceType')) updates['tipe_layanan'] = data['serviceType'];
      if (data.containsKey('paymentMethod')) updates['metode_pembayaran'] = data['paymentMethod'];
      if (data.containsKey('timestamp')) updates['waktu_pesan'] = data['timestamp'];
      if (data.containsKey('completedAt')) updates['waktu_selesai'] = data['completedAt'];

      // Extract nested items and write to detail collection
      if (data.containsKey('items')) {
        final List items = data['items'] as List;
        for (var item in items) {
          final itemMap = item as Map<String, dynamic>;
          final foodItem = itemMap['foodItem'] as Map<String, dynamic>? ?? {};
          
          await firestore.collection('detail').add({
            'id_order': doc.id,
            'id_menu': foodItem['id'] ?? foodItem['id_menu'] ?? '',
            'jml': itemMap['quantity'] ?? 1,
            'harga': foodItem['harga'] ?? foodItem['price'] ?? 0,
            'catatan': itemMap['notes'],
          });
        }
      }

      if (updates.isNotEmpty || data.containsKey('items')) {
        if (updates.isNotEmpty) {
          await firestore.collection('orders').doc(doc.id).update(updates);
        }
        await firestore.collection('orders').doc(doc.id).update({
          'userId': FieldValue.delete(),
          'totalAmount': FieldValue.delete(),
          'tax': FieldValue.delete(),
          'serviceCharge': FieldValue.delete(),
          'serviceType': FieldValue.delete(),
          'paymentMethod': FieldValue.delete(),
          'timestamp': FieldValue.delete(),
          'completedAt': FieldValue.delete(),
          'items': FieldValue.delete(),
        });
        print('Migrated order document: ${doc.id}');
      }
    }

    print('Firestore migration successfully completed!');
  });
}
