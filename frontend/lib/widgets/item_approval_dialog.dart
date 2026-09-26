import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ticket_model.dart';
import '../providers/ticket_provider.dart';
import '../theme/app_colors.dart';

class ItemApprovalDialog extends StatefulWidget {
  final TicketModel ticket;

  const ItemApprovalDialog({super.key, required this.ticket});

  static Future<void> show(BuildContext context, TicketModel ticket) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ItemApprovalDialog(ticket: ticket),
    );
  }

  @override
  State<ItemApprovalDialog> createState() => _ItemApprovalDialogState();
}

class _ItemApprovalDialogState extends State<ItemApprovalDialog> {
  late Map<String, String> _decisions; // itemId -> 'APPROVED' | 'REJECTED'

  @override
  void initState() {
    super.initState();
    _decisions = {};
    for (var item in widget.ticket.items) {
      if (item.approvalStatus == 'PENDING') {
        _decisions[item.id] = 'APPROVED'; // default to recommended approve
      } else {
        _decisions[item.id] = item.approvalStatus;
      }
    }
  }

  double get _estimatedTotal {
    double total = 0.0;
    for (var item in widget.ticket.items) {
      if (_decisions[item.id] == 'APPROVED') {
        total += item.totalPrice;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.rate_review_outlined, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Review Diagnosed Repairs',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Ticket ${widget.ticket.ticketNumber} • ${widget.ticket.vehicleInfo}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Instruction Banner
            Container(
              color: AppColors.statusPendingApproval.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.statusPendingApproval, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please approve or reject each diagnosed repair item below before technicians begin work.',
                      style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),

            // Items List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: widget.ticket.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = widget.ticket.items[index];
                  final decision = _decisions[item.id] ?? 'PENDING';
                  final isApproved = decision == 'APPROVED';
                  final isRejected = decision == 'REJECTED';

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isApproved
                            ? AppColors.accent.withValues(alpha: 0.6)
                            : isRejected
                                ? AppColors.danger.withValues(alpha: 0.5)
                                : AppColors.border,
                        width: isApproved || isRejected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (item.type == 'PART' ? Colors.blue : Colors.purple)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.type,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: item.type == 'PART' ? Colors.blue.shade700 : Colors.purple.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              '\$${item.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        if (item.mechanicNotes.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Technician Note: ${item.mechanicNotes}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        // Approve & Reject Buttons with Exact Design System Colors:
                        // Approve: #F97316 (Safety Orange)
                        // Reject: #EF4444 (Rose Red)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isApproved ? AppColors.accent : Colors.white,
                                  foregroundColor: isApproved ? Colors.white : AppColors.accent,
                                  side: const BorderSide(color: AppColors.accent, width: 1.5),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                icon: Icon(
                                  isApproved ? Icons.check_circle : Icons.check_circle_outline,
                                  size: 16,
                                ),
                                label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  setState(() {
                                    _decisions[item.id] = 'APPROVED';
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isRejected ? AppColors.danger : Colors.white,
                                  foregroundColor: isRejected ? Colors.white : AppColors.danger,
                                  side: const BorderSide(color: AppColors.danger, width: 1.5),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                icon: Icon(
                                  isRejected ? Icons.cancel : Icons.cancel_outlined,
                                  size: 16,
                                ),
                                label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  setState(() {
                                    _decisions[item.id] = 'REJECTED';
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Footer with Total and Confirm Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total for Approved Items:',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '\$${_estimatedTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent, // #F97316
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final approvals = _decisions.entries
                            .map((e) => {'item_id': e.key, 'status': e.value})
                            .toList();

                        final provider = Provider.of<TicketProvider>(context, listen: false);
                        Navigator.pop(context);
                        await provider.batchApproveItems(widget.ticket.id, approvals);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Repair approvals submitted. Work is now in progress!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Confirm Decisions & Authorize Work',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
