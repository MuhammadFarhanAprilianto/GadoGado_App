import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() {
  test('Diagnose Firestore Shop Status', () async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    
    final doc = await FirebaseFirestore.instance.collection('settings').doc('shop_status').get();
    print('==============================');
    print('FIRESTORE SHOP STATUS DOCUMENT:');
    print(doc.data());
    print('==============================');
  });
}
