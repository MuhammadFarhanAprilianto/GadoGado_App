import 'package:flutter_test/flutter_test.dart';
import 'package:gado_gado_app/data/models/user_model.dart';
import 'package:gado_gado_app/core/constants/app_constants.dart';

void main() {
  group('UserModel Tests', () {
    test('should correctly instantiate UserModel', () {
      final user = UserModel(
        id: 'User_01',
        uid: 'firebase_uid_123',
        name: 'Farhan Aprilianto',
        email: 'farhan@example.com',
        role: AppConstants.roleAdmin,
        phone: '081234567890',
        profilePic: 'https://example.com/avatar.jpg',
      );

      expect(user.id, 'User_01');
      expect(user.uid, 'firebase_uid_123');
      expect(user.name, 'Farhan Aprilianto');
      expect(user.email, 'farhan@example.com');
      expect(user.role, AppConstants.roleAdmin);
      expect(user.phone, '081234567890');
      expect(user.profilePic, 'https://example.com/avatar.jpg');
    });

    test('should parse from Firestore map with id', () {
      final firestoreData = {
        'uid': 'auth_uid_456',
        'nama': 'Mpo Lemez',
        'email': 'owner@mpolemez.com',
        'role': 'owner',
        'hp': '08987654321',
        'avatar_url': 'https://example.com/owner.png',
      };

      final user = UserModel.fromFirestore(firestoreData, 'User_Owner_01');

      expect(user.id, 'User_Owner_01');
      expect(user.uid, 'auth_uid_456');
      expect(user.name, 'Mpo Lemez');
      expect(user.email, 'owner@mpolemez.com');
      expect(user.role, 'owner');
      expect(user.phone, '08987654321');
      expect(user.profilePic, 'https://example.com/owner.png');
    });

    test('should correctly serialize to Firestore map', () {
      final user = UserModel(
        id: 'User_02',
        uid: 'uid_cust_789',
        name: 'Budi Santoso',
        email: 'budi@gmail.com',
        role: AppConstants.roleCustomer,
        phone: '08111222333',
      );

      final map = user.toFirestore();

      expect(map['uid'], 'uid_cust_789');
      expect(map['nama'], 'Budi Santoso');
      expect(map['email'], 'budi@gmail.com');
      expect(map['role'], AppConstants.roleCustomer);
      expect(map['hp'], '08111222333');
    });

    test('should serialize and deserialize JSON correctly', () {
      final user = UserModel(
        id: 'User_03',
        uid: 'uid_333',
        name: 'Siti Aminah',
        email: 'siti@example.com',
        role: AppConstants.roleCustomer,
        phone: '082233445566',
        profilePic: 'https://example.com/siti.jpg',
      );

      final json = user.toJson();
      final parsedUser = UserModel.fromJson(json);

      expect(parsedUser.id, 'User_03');
      expect(parsedUser.name, 'Siti Aminah');
      expect(parsedUser.role, AppConstants.roleCustomer);
      expect(parsedUser.email, 'siti@example.com');
      expect(parsedUser.phone, '082233445566');
      expect(parsedUser.profilePic, 'https://example.com/siti.jpg');
    });
  });
}
