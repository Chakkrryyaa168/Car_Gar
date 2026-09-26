import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ticket_model.dart';
import '../../providers/ticket_provider.dart';
import '../../theme/app_colors.dart';

class PaymentModal extends StatefulWidget {
  final TicketModel ticket;

  const PaymentModal({super.key, required this.ticket});

  static Future<void> show(BuildContext context, TicketModel ticket) {
    return showDialog(
      context: context,
      builder: (_) => PaymentModal(ticket: ticket),
    );
  }

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  final _amountController = TextEditingController();
  final _refController = TextEditingController(text: 'TXN-');
  String _selectedMethod = 'CREDIT_CARD';
  bool _keysReturned = true;
  bool _isLoading = false;

  final List<Map<String, String>> _methods = [
    {'code': 'CREDIT_CARD', 'name': 'Credit / Debit Card'},
    {'code': 'CASH', 'name': 'Cash Payment'},
    {'code': 'BANK_TRANSFER', 'name': 'Bank Transfer (Wire / ACH)'},
    {'code': 'SPLIT_PAYMENT', 'name': 'Split Payment (Card + Cash)'},
  ];

  @override
  void initState() {
    super.initState();
    final balance = widget.ticket.invoice?.balanceDue ?? widget.ticket.totalEstimatedAmount;
    _amountController.text = balance.toStringAsFixed(2);
    _refController.text = 'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  @override
  Widget build(BuildContext context) {
    final invoice = widget.ticket.invoice;
    final total = invoice?.totalAmount ?? widget.ticket.totalEstimatedAmount;
    final balance = invoice?.balanceDue ?? total;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.point_of_sale, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Collect Checkout Payment',
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
              // Invoice Summary Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Ticket / Invoice:', style: TextStyle(color: AppColors.textSecondary)),
                        Text(
                          '${widget.ticket.ticketNumber} (${invoice?.invoiceNumber ?? 'Draft'})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Invoice Amount:', style: TextStyle(color: AppColors.textSecondary)),
                        Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Remaining Balance Due:', style: TextStyle(color: AppColors.textSecondary)),
                        Text(
                          '\$${balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Payment Method
              const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _selectedMethod,
                decoration: const InputDecoration(),
                items: _methods.map((m) {
                  return DropdownMenuItem(value: m['code'], child: Text(m['name']!));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedMethod = val);
                },
              ),
              const SizedBox(height: 14),

              // Amount to pay
              const Text('Amount to Charge (\$)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(prefixText: '\$ '),
              ),
              const SizedBox(height: 14),

              // Transaction reference
              const Text('Transaction Reference / Note', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _refController,
                decoration: const InputDecoration(hintText: 'e.g. Card Auth Code / Receipt #'),
              ),
              // Key Return Confirmation
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                ),
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text(
                    'Vehicle keys verified & returned to customer',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: const Text(
                    'Marks ticket status as PAID_AND_CLOSED and finishes checkout.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  value: _keysReturned,
                  activeColor: AppColors.success,
                  onChanged: (val) => setState(() => _keysReturned = val ?? true),
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success, // #22C55E for payment
                  ),
                  onPressed: _isLoading ? null : _submitPayment,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Confirm & Record Payment',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitPayment() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return;

    final invoice = widget.ticket.invoice;
    if (invoice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice is not generated for this ticket yet.'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isLoading = true);
    final provider = Provider.of<TicketProvider>(context, listen: false);

    try {
      await provider.recordPayment(
        invoiceId: invoice.id,
        ticketId: widget.ticket.id,
        amount: amount,
        method: _selectedMethod,
        reference: _refController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment registered! Invoice and ticket marked PAID & CLOSED.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
