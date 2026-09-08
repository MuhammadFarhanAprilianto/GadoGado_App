import 'package:flutter_test/flutter_test.dart';
import 'package:gado_gado_app/data/models/food_item_model.dart';

void main() {
  group('FoodItemModel Tests', () {
    test('should correctly instantiate FoodItemModel with recipes', () {
      final recipeItem = RecipeItemModel(
        ingredientId: 'ing_01',
        ingredientName: 'Kacang Tanah',
        quantityPerPortion: 0.05,
      );

      final food = FoodItemModel(
        id: 'menu_01',
        name: 'Gado-Gado Spesial',
        description: 'Gado-gado dengan bumbu kacang gurih mantap',
        price: 18000,
        image: 'assets/images/gado_gado.jpg',
        category: 'Gado-Gado',
        stock: 25,
        isBestSeller: true,
        recipe: [recipeItem],
      );

      expect(food.id, 'menu_01');
      expect(food.name, 'Gado-Gado Spesial');
      expect(food.price, 18000);
      expect(food.isBestSeller, isTrue);
      expect(food.recipe.length, 1);
      expect(food.recipe.first.ingredientName, 'Kacang Tanah');
    });

    test('should parse correctly from Firestore Map', () {
      final firestoreData = {
        'nama': 'Ketoprak Telur',
        'deskr': 'Ketoprak renyah dengan telur dadar',
        'harga': 17000,
        'gambar': 'assets/images/ketoprak.jpg',
        'kategori': 'Ketoprak',
        'stok': 15,
        'terlaris': false,
        'baru': true,
        'tersedia': true,
        'resep': [
          {
            'id_bahan': 'ing_tahu',
            'nama_bahan': 'Tahu',
            'jumlah_per_porsi': 1.0,
          },
          {
            'id_bahan': 'ing_telur',
            'nama_bahan': 'Telur',
            'jumlah_per_porsi': 1.0, // Should convert to 0.06 kg per logic
          }
        ],
      };

      final food = FoodItemModel.fromFirestore(firestoreData, 'menu_ketoprak_01');

      expect(food.id, 'menu_ketoprak_01');
      expect(food.name, 'Ketoprak Telur');
      expect(food.price, 17000);
      expect(food.isNew, isTrue);
      expect(food.recipe.length, 2);
      expect(food.recipe[1].quantityPerPortion, 0.06);
    });

    test('should serialize to Firestore map correctly', () {
      final food = FoodItemModel(
        id: 'menu_02',
        name: 'Es Jeruk',
        description: 'Es jeruk segar peras asli',
        price: 6000,
        image: 'assets/images/es_jeruk.jpg',
        category: 'Minuman',
        stock: 50,
      );

      final map = food.toFirestore();

      expect(map['nama'], 'Es Jeruk');
      expect(map['harga'], 6000);
      expect(map['kategori'], 'Minuman');
      expect(map['stok'], 50);
      expect(map['tersedia'], isTrue);
    });
  });
}
