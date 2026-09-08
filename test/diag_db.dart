import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() {
  test('Diagnose Firestore Shop Status', () async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    
    final snapshot = await FirebaseFirestore.instance.collection('bahan').get();
    print('==============================');
    print('FIRESTORE BAHAN COUNT: ${snapshot.docs.length}');
    for (var d in snapshot.docs) {
      print('DOC ID: ${d.id} => ${d.data()}');
    }
    print('==============================');
  });
}
