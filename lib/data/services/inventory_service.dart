import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_item_model.dart';
import '../models/order_model.dart';
import '../models/raw_ingredient_model.dart';

class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Robust helper to locate a raw ingredient by ID (exact or dummy prefix) or by name.
  static RawIngredientModel? findIngredientByIdOrName(String idOrName, List<RawIngredientModel> allIngredients) {
    if (idOrName.isEmpty) return null;

    // 1. Try exact ID match
    final exactMatch = allIngredients.firstWhere(
      (i) => i.id == idOrName,
      orElse: () => RawIngredientModel(id: '', name: '', category: '', amount: 0, unit: ''),
    );
    if (exactMatch.id.isNotEmpty) return exactMatch;

    // 2. Try normalized ID match (remove dummy_ prefix) or matching name
    final cleanId = idOrName.replaceAll('dummy_', '').toLowerCase();
    final fallbackMatch = allIngredients.firstWhere(
      (i) => i.name.toLowerCase() == cleanId || i.id.toLowerCase() == cleanId,
      orElse: () => RawIngredientModel(id: '', name: '', category: '', amount: 0, unit: ''),
    );
    if (fallbackMatch.id.isNotEmpty) return fallbackMatch;

    return null;
  }

  /// Robust helper to locate a raw ingredient matching a RecipeItemModel.
  static RawIngredientModel? findIngredient(RecipeItemModel recipeItem, List<RawIngredientModel> allIngredients) {
    // Try to resolve using ingredientId
    final byId = findIngredientByIdOrName(recipeItem.ingredientId, allIngredients);
    if (byId != null) return byId;

    // Try to resolve using ingredientName
    if (recipeItem.ingredientName.isNotEmpty) {
      final byName = findIngredientByIdOrName(recipeItem.ingredientName, allIngredients);
      if (byName != null) return byName;
    }

    return null;
  }

  /// Calculates how many portions of a food item can be made based on current ingredients stock.
  static int calculateRemainingPortions(FoodItemModel foodItem, List<RawIngredientModel> allIngredients) {
    if (foodItem.recipe.isEmpty) return 99; // Assume unlimited if no recipe defined

    int minPortions = 999;

    for (var recipeItem in foodItem.recipe) {
      final ingredient = findIngredient(recipeItem, allIngredients);

      if (ingredient == null) {
        return 0; // Required ingredient not found in stock
      }

      if (recipeItem.quantityPerPortion <= 0) continue;

      int portionsForThisIngredient = (ingredient.amount / recipeItem.quantityPerPortion).floor();
      if (portionsForThisIngredient < minPortions) {
        minPortions = portionsForThisIngredient;
      }
    }

    return minPortions == 999 ? 0 : minPortions;
  }

  /// Validates if all items in the cart have enough ingredients stock.
  static bool validateStockAvailability(List<CartItemModel> cart, List<RawIngredientModel> allIngredients) {
    // Group identical food items in cart to check total quantity needed
    final Map<String, int> totalQuantities = {};
    for (var item in cart) {
      totalQuantities[item.foodItem.id] = (totalQuantities[item.foodItem.id] ?? 0) + item.quantity;
    }

    // Check each unique food item
    for (var entry in totalQuantities.entries) {
      final foodItem = cart.firstWhere((item) => item.foodItem.id == entry.key).foodItem;
      int remaining = calculateRemainingPortions(foodItem, allIngredients);
      if (entry.value > remaining) {
        return false;
      }
    }

    return true;
  }

  /// Deducts ingredients from Firestore for the given cart items.
  /// Uses a WriteBatch for atomicity.
  Future<void> deductIngredients(List<CartItemModel> cart) async {
    final batch = _firestore.batch();
    
    // Fetch all current ingredients to accurately map recipe item targets to valid Firestore doc IDs
    final snapshot = await _firestore.collection('bahan').get();
    final List<RawIngredientModel> allIngredients = snapshot.docs.map((doc) {
      final data = doc.data();
      final stok = (data['stok'] ?? 0).toDouble();
      final threshold = (data['ambang_batas_stok'] ?? data['minStockThreshold'] ?? 5).toDouble();
      return RawIngredientModel(
        id: doc.id,
        name: data['nama_bahan'] ?? data['name'] ?? '',
        category: data['kategori'] ?? data['category'] ?? 'Umum',
        amount: stok,
        unit: data['satuan'] ?? data['unit'] ?? '',
        minStockThreshold: threshold,
        isLowStock: stok < threshold,
      );
    }).toList();

    // Calculate total amount to deduct for each raw ingredient
    final Map<String, double> deductions = {};

    for (var cartItem in cart) {
      for (var recipeItem in cartItem.foodItem.recipe) {
        final ingredient = findIngredient(recipeItem, allIngredients);
        if (ingredient != null) {
          final double amountToDeduct = recipeItem.quantityPerPortion * cartItem.quantity;
          deductions[ingredient.id] = (deductions[ingredient.id] ?? 0) + amountToDeduct;
        }
      }
    }

    // Apply deductions to Firestore
    for (var entry in deductions.entries) {
      final docRef = _firestore.collection('bahan').doc(entry.key);
      batch.update(docRef, {
        'stok': FieldValue.increment(-entry.value),
      });
    }

    await batch.commit();
  }
}
