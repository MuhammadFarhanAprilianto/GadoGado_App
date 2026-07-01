class ToppingModel {
  final String id;
  final String name;
  final double price;
  final String ingredientId; // Linked ingredient ID in 'bahan' collection

  ToppingModel({
    required this.id,
    required this.name,
    required this.price,
    required this.ingredientId,
  });

  factory ToppingModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ToppingModel(
      id: id,
      name: data['nama'] ?? data['name'] ?? '',
      price: (data['harga'] ?? data['price'] ?? 0).toDouble(),
      ingredientId: data['id_bahan'] ?? data['ingredientId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nama': name,
      'harga': price,
      'id_bahan': ingredientId,
    };
  }

  ToppingModel copyWith({
    String? id,
    String? name,
    double? price,
    String? ingredientId,
  }) {
    return ToppingModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      ingredientId: ingredientId ?? this.ingredientId,
    );
  }
}
