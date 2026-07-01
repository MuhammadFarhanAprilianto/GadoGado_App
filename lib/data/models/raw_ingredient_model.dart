class RawIngredientModel {
  final String id;
  final String name;
  final String category;
  final double amount;
  final String unit;
  final bool isLowStock;

  final double? minStockThreshold;

  RawIngredientModel({
    required this.id,
    required this.name,
    required this.category,
    required this.amount,
    required this.unit,
    this.isLowStock = false,
    this.minStockThreshold,
  });
}
