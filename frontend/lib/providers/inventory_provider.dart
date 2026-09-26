import 'package:flutter/material.dart';
import '../models/inventory_model.dart';
import '../services/api_service.dart';

class InventoryProvider extends ChangeNotifier {
  final ApiService apiService;
  List<InventoryModel> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  InventoryProvider({required this.apiService});

  List<InventoryModel> get items => _items;
  List<InventoryModel> get lowStockItems => _items.where((i) => i.isLowStock).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchInventory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await apiService.fetchInventory();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> restock(String itemId, int quantity) async {
    try {
      await apiService.restockInventory(itemId, quantity);
      await fetchInventory();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
