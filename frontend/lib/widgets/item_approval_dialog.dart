import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/ticket_model.dart';
import '../providers/ticket_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_animations.dart';

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
      backgroundColor: AppColors.surface, // #FFFFFF
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border), // #E8DAD8
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surfaceElevated, // #FDF6F5
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.rate_review_outlined, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Review Diagnosed Repairs',
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Ticket ${widget.ticket.ticketNumber} • ${widget.ticket.vehicleInfo}',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Instruction Banner
            Container(
              color: AppColors.surfaceElevated,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please approve or decline each diagnosed repair item below before technicians begin work.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
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

                  return AnimatedContainer(
                    duration: AppAnimations.durFast,
                    curve: AppAnimations.ease,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isApproved
                          ? AppColors.surfaceWarm
                          : (isRejected ? AppColors.background : AppColors.surface),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isApproved
                            ? AppColors.primary
                            : (isRejected ? AppColors.border.withValues(alpha: 0.6) : AppColors.border),
                        width: isApproved ? 1.5 : 1.0,
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
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                item.type,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.description,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  decoration: isRejected ? TextDecoration.lineThrough : null,
                                  color: isRejected ? AppColors.textSecondary : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              '\$${item.totalPrice.toStringAsFixed(2)}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        if (item.mechanicNotes.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Technician Note: ${item.mechanicNotes}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: AppPressable(
                                onPressed: () {
                                  setState(() {
                                    _decisions[item.id] = 'APPROVED';
                                  });
                                },
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isApproved ? AppColors.primary : AppColors.surface,
                                    foregroundColor: isApproved ? Colors.white : AppColors.textSecondary,
                                    side: BorderSide(
                                      color: isApproved ? AppColors.primary : AppColors.border,
                                      width: isApproved ? 1.5 : 1.0,
                                    ),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  icon: Icon(
                                    isApproved ? Icons.check_circle : Icons.check_circle_outline,
                                    size: 16,
                                    color: isApproved ? Colors.white : AppColors.textSecondary,
                                  ),
                                  label: Text(
                                    'Approve',
                                    style: GoogleFonts.inter(
                                      fontWeight: isApproved ? FontWeight.w700 : FontWeight.w600,
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _decisions[item.id] = 'APPROVED';
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: AppPressable(
                                onPressed: () {
                                  setState(() {
                                    _decisions[item.id] = 'REJECTED';
                                  });
                                },
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: isRejected ? AppColors.surfaceElevated : Colors.transparent,
                                    foregroundColor: isRejected ? AppColors.charcoal : AppColors.textSecondary,
                                    side: BorderSide(
                                      color: AppColors.border, // #E4DED0
                                      width: isRejected ? 1.5 : 1.0,
                                    ),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  icon: Icon(
                                    isRejected ? Icons.cancel : Icons.cancel_outlined,
                                    size: 16,
                                    color: isRejected ? AppColors.charcoal : AppColors.textSecondary,
                                  ),
                                  label: Text(
                                    'Decline',
                                    style: GoogleFonts.inter(
                                      fontWeight: isRejected ? FontWeight.w700 : FontWeight.w600,
                                      color: isRejected ? AppColors.charcoal : AppColors.textSecondary,
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _decisions[item.id] = 'REJECTED';
                                    });
                                  },
                                ),
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
                color: AppColors.surfaceElevated, // #FDF6F5
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total for Approved Items:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      CountingAmountText(
                        value: _estimatedTotal,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppPressable(
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary, // Solid Sage #5F7F6B
                          foregroundColor: Colors.white, // White text
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                              SnackBar(
                                content: Text(
                                  'Repair approvals submitted. Work is now in progress!',
                                  style: GoogleFonts.inter(color: Colors.white),
                                ),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                        },
                        child: Text(
                          'Confirm Decisions & Authorize Work',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
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
