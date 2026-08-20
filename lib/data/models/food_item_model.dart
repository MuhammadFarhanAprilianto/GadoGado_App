import 'dart:io';
import 'package:flutter/material.dart';

enum FoodCategory { gadoGado, drinks, snacks, sate }

class RecipeItemModel {
  final String ingredientId;
  final String ingredientName;
  final double quantityPerPortion;

  RecipeItemModel({
    required this.ingredientId,
    required this.ingredientName,
    required this.quantityPerPortion,
  });

  factory RecipeItemModel.fromMap(Map<String, dynamic> map) {
    final name = map['nama_bahan'] ?? map['ingredientName'] ?? '';
    double qty = (map['jumlah_per_porsi'] ?? map['quantityPerPortion'] ?? 0).toDouble();
    // If the ingredient is Telur and the quantity is set to 1 (piece),
    // convert it to 0.06 kg to match the database unit.
    if (name.toLowerCase() == 'telur' && (qty == 1.0 || qty == 1)) {
      qty = 0.06;
    }
    return RecipeItemModel(
      ingredientId: map['id_bahan'] ?? map['ingredientId'] ?? '',
      ingredientName: name,
      quantityPerPortion: qty,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_bahan': ingredientId,
      'nama_bahan': ingredientName,
      'jumlah_per_porsi': quantityPerPortion,
    };
  }
}

class FoodItemModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String image;
  final String category;
  final int stock;
  final bool isBestSeller;
  final bool isNew;
  final bool isAvailable;
  final List<RecipeItemModel> recipe;

  FoodItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.category,
    this.stock = 10,
    this.isBestSeller = false,
    this.isNew = false,
    this.isAvailable = true,
    this.recipe = const [],
  });

  String getName([String? lang]) {
    return name;
  }

  String getDescription([String? lang]) {
    return description;
  }

  ImageProvider get imageProvider {
    if (image.isEmpty) {
      return const AssetImage('assets/images/logo.jpg');
    }
    if (image.startsWith('assets/')) {
      return AssetImage(image);
    }
    if (image.startsWith('http') || image.startsWith('https')) {
      return NetworkImage(image);
    }
    return FileImage(File(image));
  }

  factory FoodItemModel.fromJson(Map<String, dynamic> json) {
    return FoodItemModel(
      id: json['id'] ?? json['id_menu'] ?? '',
      name: json['nama'] ?? json['name'] ?? '',
      description: json['deskr'] ?? json['description'] ?? '',
      price: (json['harga'] ?? json['price'] ?? 0).toDouble(),
      image: json['gambar'] ?? json['image'] ?? '',
      category: json['kategori'] ?? json['category'] ?? '',
      stock: json['stok'] ?? json['stock'] ?? 10,
      isBestSeller: json['terlaris'] ?? json['isBestSeller'] ?? false,
      isNew: json['baru'] ?? json['isNew'] ?? false,
      isAvailable: json['tersedia'] ?? json['isAvailable'] ?? true,
      recipe: (json['resep'] as List? ?? json['recipe'] as List? ?? [])
          .map((item) => RecipeItemModel.fromMap(item))
          .toList(),
    );
  }

  factory FoodItemModel.fromFirestore(Map<String, dynamic> data, String id) {
    return FoodItemModel(
      id: id,
      name: data['nama'] ?? data['name'] ?? '',
      description: data['deskr'] ?? data['description'] ?? '',
      price: (data['harga'] ?? data['price'] ?? 0).toDouble(),
      image: data['gambar'] ?? data['image'] ?? '',
      category: data['kategori'] ?? data['category'] ?? '',
      stock: data['stok'] ?? data['stock'] ?? 10,
      isBestSeller: data['terlaris'] ?? data['isBestSeller'] ?? false,
      isNew: data['baru'] ?? data['isNew'] ?? false,
      isAvailable: data['tersedia'] ?? data['isAvailable'] ?? true,
      recipe: (data['resep'] as List? ?? data['recipe'] as List? ?? [])
          .map((item) => RecipeItemModel.fromMap(item))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nama': name,
      'deskr': description,
      'harga': price,
      'gambar': image,
      'kategori': category,
      'stok': stock,
      'terlaris': isBestSeller,
      'baru': isNew,
      'tersedia': isAvailable,
      'resep': recipe.map((r) => r.toMap()).toList(),
    };
  }

  FoodItemModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? image,
    String? category,
    int? stock,
    bool? isBestSeller,
    bool? isNew,
    bool? isAvailable,
    List<RecipeItemModel>? recipe,
  }) {
    return FoodItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      image: image ?? this.image,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      isBestSeller: isBestSeller ?? this.isBestSeller,
      isNew: isNew ?? this.isNew,
      isAvailable: isAvailable ?? this.isAvailable,
      recipe: recipe ?? this.recipe,
    );
  }
}
