import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_item_model.dart';
import '../models/order_model.dart';
import '../models/raw_ingredient_model.dart';

class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculates how many portions of a food item can be made based on current ingredients stock.
  static int calculateRemainingPortions(FoodItemModel foodItem, List<RawIngredientModel> allIngredients) {
    if (foodItem.recipe.isEmpty) return 99; // Assume unlimited if no recipe defined

    int minPortions = 999;

    for (var recipeItem in foodItem.recipe) {
      final ingredient = allIngredients.firstWhere(
        (i) => i.id == recipeItem.ingredientId,
        orElse: () => RawIngredientModel(id: '', name: '', category: '', amount: 0, unit: ''),
      );

      if (ingredient.id.isEmpty) {
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
    
    // Calculate total amount to deduct for each raw ingredient
    final Map<String, double> deductions = {};

    for (var cartItem in cart) {
      for (var recipeItem in cartItem.foodItem.recipe) {
        final double amountToDeduct = recipeItem.quantityPerPortion * cartItem.quantity;
        deductions[recipeItem.ingredientId] = (deductions[recipeItem.ingredientId] ?? 0) + amountToDeduct;
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
