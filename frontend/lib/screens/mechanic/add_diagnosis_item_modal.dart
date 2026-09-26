import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/inventory_model.dart';
import '../../providers/ticket_provider.dart';
import '../../theme/app_colors.dart';

class AddDiagnosisItemModal extends StatefulWidget {
  final String ticketId;

  const AddDiagnosisItemModal({super.key, required this.ticketId});

  static Future<void> show(BuildContext context, String ticketId) {
    return showDialog(
      context: context,
      builder: (_) => AddDiagnosisItemModal(ticketId: ticketId),
    );
  }

  @override
  State<AddDiagnosisItemModal> createState() => _AddDiagnosisItemModalState();
}

class _AddDiagnosisItemModalState extends State<AddDiagnosisItemModal> {
  final _formKey = GlobalKey<FormState>();
  String _itemType = 'PART'; // PART or LABOR
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _qtyController = TextEditingController(text: '1.0');
  final _notesController = TextEditingController();

  List<InventoryModel> _inventoryItems = [];
  String? _selectedInventoryId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    final api = Provider.of<TicketProvider>(context, listen: false).apiService;
    try {
      final items = await api.fetchInventory();
      setState(() {
        _inventoryItems = items;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.build, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            'Add Diagnosis / Repair Item',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  // Type Segment
                  const Text('Category Type', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Spare Part')),
                          selected: _itemType == 'PART',
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          onSelected: (_) => setState(() => _itemType = 'PART'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Labor / Service')),
                          selected: _itemType == 'LABOR',
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          onSelected: (_) => setState(() => _itemType = 'LABOR'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Quick Inventory Picker (for PART)
                  if (_itemType == 'PART' && _inventoryItems.isNotEmpty) ...[
                    const Text('Select from Garage Parts Catalog (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedInventoryId,
                      decoration: const InputDecoration(hintText: 'Choose from inventory warehouse...'),
                      items: _inventoryItems.map((item) {
                        return DropdownMenuItem(
                          value: item.id,
                          child: Text(
                            '${item.name} (\$${item.sellingPrice}) [Stock: ${item.quantityOnHand}]',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedInventoryId = val;
                          if (val != null) {
                            final chosen = _inventoryItems.firstWhere((i) => i.id == val);
                            _descController.text = chosen.name;
                            _priceController.text = chosen.sellingPrice.toStringAsFixed(2);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Description
                  const Text('Item Description / Service Name', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(hintText: 'e.g. Front Ceramic Brake Pads'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter description' : null,
                  ),
                  const SizedBox(height: 14),

                  // Price and Qty
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Unit Price (\$)', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _priceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(prefixText: '\$ '),
                              validator: (v) => (v == null || v.isEmpty) ? 'Enter price' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Quantity / Hours', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _qtyController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(),
                              validator: (v) => (v == null || v.isEmpty) ? 'Enter qty' : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Technician Notes
                  const Text('Mechanic Findings / Technical Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Measured 2mm thickness remaining; rotor warped.',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      onPressed: _isLoading ? null : _submitItem,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Add to Diagnosis Checklist',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final provider = Provider.of<TicketProvider>(context, listen: false);

    try {
      await provider.addDiagnosisItem(
        ticketId: widget.ticketId,
        type: _itemType,
        description: _descController.text,
        unitPrice: double.tryParse(_priceController.text) ?? 0.0,
        quantity: double.tryParse(_qtyController.text) ?? 1.0,
        inventoryItemId: _selectedInventoryId,
        mechanicNotes: _notesController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item added to diagnosis successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add item: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
