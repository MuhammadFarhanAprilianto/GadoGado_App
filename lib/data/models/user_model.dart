import 'dart:io';
import 'package:flutter/material.dart';

class UserModel {
  final String id;       // Doc ID di Firestore (User_01, User_02, ...)
  final String uid;      // Firebase Auth UID — untuk fast lookup
  final String name;
  final String email;
  final String role;
  final String? profilePic;
  final String? phone;

  UserModel({
    required this.id,
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.profilePic,
    this.phone,
  });

  ImageProvider get profileImageProvider {
    if (profilePic == null || profilePic!.isEmpty) {
      return const NetworkImage(
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=150&auto=format&fit=crop');
    }
    if (profilePic!.startsWith('http') || profilePic!.startsWith('https')) {
      return NetworkImage(profilePic!);
    }
    return FileImage(File(profilePic!));
  }

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      uid: data['uid'] as String? ?? '',   // Akun lama mungkin tidak punya field ini
      name: data['nama'] ?? data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'pelanggan',
      profilePic: data['avatar_url'] ?? data['profilePic'],
      phone: data['hp'] ?? data['phone'],
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      uid: json['uid'] as String? ?? '',
      name: json['nama'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'pelanggan',
      profilePic: json['avatar_url'] ?? json['profilePic'],
      phone: (json['hp'] ?? json['phone']) as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,        // Simpan UID untuk fast lookup
      'nama': name,
      'email': email,
      'role': role,
      'avatar_url': profilePic,
      'hp': phone,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'nama': name,
      'email': email,
      'role': role,
      'avatar_url': profilePic,
      'hp': phone,
    };
  }
}
