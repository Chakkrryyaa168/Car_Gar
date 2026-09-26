import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/inventory_model.dart';
import '../../theme/app_colors.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false).fetchInventory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final invProvider = Provider.of<InventoryProvider>(context);
    final items = invProvider.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Warehouse & Stock Control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => invProvider.fetchInventory(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => invProvider.fetchInventory(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Low stock alert banner
              if (invProvider.lowStockItems.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.outOfStockBg, // #FEE2E2
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.danger),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.outOfStockText),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${invProvider.lowStockItems.length} inventory items are below reorder thresholds or out-of-stock!',
                          style: const TextStyle(
                            color: AppColors.outOfStockText, // #EF4444
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Inventory Table
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Parts Catalog & Real-time Stock',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Total Items: ${items.length}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const Divider(),
                      if (invProvider.isLoading && items.isEmpty)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ))
                      else if (items.isEmpty)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('No inventory items found.'),
                        ))
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const Divider(),
                          itemBuilder: (context, index) {
                            final item = items[index];

                            return Row(
                              children: [
                                // Stock Indicator Badge
                                _buildStockBadge(item),
                                const SizedBox(width: 14),
                                // Item Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'SKU: ${item.sku} • Cost: \$${item.costPrice.toStringAsFixed(2)} • Sell: \$${item.sellingPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                // Quantities & Restock CTA
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${item.quantityOnHand} in stock',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: item.isOutOfStock
                                            ? AppColors.outOfStockText
                                            : item.isLowStock
                                                ? AppColors.warning
                                                : AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Reorder: ${item.reorderLevel}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  onPressed: () => _promptRestock(context, item, invProvider),
                                  child: const Text('Restock', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockBadge(InventoryModel item) {
    if (item.isOutOfStock) {
      // Out-of-Stock Indicator (Inventory): Background tint #FEE2E2 with text #EF4444
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.outOfStockBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.outOfStockText),
        ),
        child: const Text(
          'OUT OF STOCK',
          style: TextStyle(
            color: AppColors.outOfStockText,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (item.isLowStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.warning),
        ),
        child: const Text(
          'LOW STOCK',
          style: TextStyle(
            color: AppColors.warning,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'IN STOCK',
          style: TextStyle(
            color: AppColors.success,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  void _promptRestock(BuildContext context, InventoryModel item, InventoryProvider provider) {
    final qtyController = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Restock ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Stock: ${item.quantityOnHand} (Reorder level: ${item.reorderLevel})'),
            const SizedBox(height: 12),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity to Add'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final qty = int.tryParse(qtyController.text) ?? 0;
              if (qty > 0) {
                Navigator.pop(context);
                await provider.restock(item.id, qty);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added $qty units to ${item.name}.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm Restock'),
          ),
        ],
      ),
    );
  }
}
