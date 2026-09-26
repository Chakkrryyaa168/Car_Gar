import 'json_helpers.dart';

class InventoryModel {
  final String id;
  final String name;
  final String sku;
  final double costPrice;
  final double sellingPrice;
  final int quantityOnHand;
  final int reorderLevel;
  final bool isLowStock;
  final bool isOutOfStock;

  InventoryModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.costPrice,
    required this.sellingPrice,
    required this.quantityOnHand,
    required this.reorderLevel,
    required this.isLowStock,
    required this.isOutOfStock,
  });

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    final qty = parseInt(json['quantity_on_hand'], 0);
    final reorder = parseInt(json['reorder_level'], 5);
    return InventoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      sku: json['sku'] ?? '',
      costPrice: parseDouble(json['cost_price']),
      sellingPrice: parseDouble(json['selling_price']),
      quantityOnHand: qty,
      reorderLevel: reorder,
      isLowStock: json['is_low_stock'] ?? (qty <= reorder),
      isOutOfStock: json['is_out_of_stock'] ?? (qty <= 0),
    );
  }
}
