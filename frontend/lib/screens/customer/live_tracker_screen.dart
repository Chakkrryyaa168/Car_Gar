import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ticket_model.dart';
import '../../providers/ticket_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/progress_stepper.dart';
import '../../widgets/photo_gallery_modal.dart';
import '../../widgets/photo_view_dialog.dart';
import '../../widgets/item_approval_dialog.dart';

class LiveTrackerScreen extends StatefulWidget {
  final String ticketId;

  const LiveTrackerScreen({super.key, required this.ticketId});

  @override
  State<LiveTrackerScreen> createState() => _LiveTrackerScreenState();
}

class _LiveTrackerScreenState extends State<LiveTrackerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TicketProvider>(context, listen: false);
      provider.fetchTicketDetail(widget.ticketId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TicketProvider>(
      builder: (context, provider, child) {
        final ticket = provider.selectedTicket;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              ticket != null ? 'Live Tracker • ${ticket.ticketNumber}' : 'Live Ticket Tracker',
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Ticket',
                onPressed: () => provider.fetchTicketDetail(widget.ticketId),
              ),
            ],
          ),
          body: provider.isLoading && ticket == null
              ? const Center(child: CircularProgressIndicator())
              : ticket == null
                  ? Center(
                      child: Text(
                        provider.errorMessage ?? 'Ticket not found.',
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => provider.fetchTicketDetail(widget.ticketId),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Vehicle & Current Status Banner
                            _buildVehicleHeaderCard(ticket),
                            const SizedBox(height: 16),

                            // 2. Multi-Step Visual Progress Stepper
                            ProgressStepper(currentStatus: ticket.currentStatus),
                            const SizedBox(height: 16),

                            // 3. Customer Action Alert Banner (if awaiting approval)
                            if (ticket.currentStatus == 'PENDING_CUSTOMER_APPROVAL')
                              _buildPendingApprovalBanner(ticket),

                            // 4. Live Repair Items Checklist
                            _buildRepairChecklist(ticket),
                            const SizedBox(height: 16),

                            // 5. Photos & Visual Evidence Section
                            _buildPhotoEvidenceCard(ticket),
                            const SizedBox(height: 16),

                            // 6. Dynamic Invoice Summary
                            if (ticket.invoice != null) ...[
                              _buildInvoiceCard(ticket),
                              const SizedBox(height: 16),
                            ],

                            // 7. Status Timeline & Audit Log
                            _buildTimelineCard(ticket),
                          ],
                        ),
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildVehicleHeaderCard(TicketModel ticket) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.vehicleInfo ?? 'Vehicle Information',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ticket #${ticket.ticketNumber}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: ticket.currentStatus, fontSize: 13),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoMetric(Icons.speed, 'Mileage In', '${ticket.mileageIn} mi'),
                _buildInfoMetric(Icons.local_gas_station, 'Fuel Level', '${ticket.fuelLevelPercent}%'),
                _buildInfoMetric(
                  Icons.person_pin,
                  'Lead Tech',
                  ticket.leadMechanicName ?? 'Pending Assignment',
                ),
              ],
            ),
            if (ticket.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Customer Concern: "${ticket.notes}"',
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoMetric(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildPendingApprovalBanner(TicketModel ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statusPendingApproval.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.statusPendingApproval),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notification_important, color: AppColors.statusPendingApproval),
              SizedBox(width: 8),
              Text(
                'Customer Action Required',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.statusPendingApproval,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Vehicle inspection has concluded. Please inspect diagnosed items and authorize or reject repairs individually.',
            style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent, // #F97316
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.touch_app, size: 18),
              label: const Text(
                'Review & Authorize Repairs',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => ItemApprovalDialog.show(context, ticket),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepairChecklist(TicketModel ticket) {
    final items = ticket.items;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.checklist, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Repair Tasks & Parts Checklist',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  '${ticket.completedItemsCount}/${ticket.approvedItemsCount} Done',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const Divider(),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  'No repair items listed yet.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isDone = item.isCompleted;

                  return Row(
                    children: [
                      // Completion Icon
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? AppColors.success
                              : item.isApproved
                                  ? AppColors.statusApprovedInProgress.withValues(alpha: 0.15)
                                  : Colors.grey.shade200,
                        ),
                        child: Center(
                          child: Icon(
                            isDone ? Icons.check : (item.isApproved ? Icons.timelapse : Icons.remove),
                            size: 16,
                            color: isDone
                                ? Colors.white
                                : item.isApproved
                                    ? AppColors.statusApprovedInProgress
                                    : Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.description,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                decoration: item.isRejected ? TextDecoration.lineThrough : null,
                                color: item.isRejected
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.type} • Qty: ${item.quantity}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            if (item.mechanicNotes.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.handyman_outlined, size: 12, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Tech note: ${item.mechanicNotes}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Price & Badge
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${item.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          StatusBadge(
                            status: item.approvalStatus,
                            fontSize: 10,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoEvidenceCard(TicketModel ticket) {
    final photoCount = ticket.photos.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Visual Photo Evidence',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$photoCount inspection photos attached by mechanic',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                if (ticket.photos.isNotEmpty)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.fullscreen, size: 16),
                    label: const Text('View All'),
                    onPressed: () => PhotoGalleryModal.show(context, ticket.photos),
                  ),
              ],
            ),
            if (ticket.photos.isNotEmpty) ...[
              const Divider(height: 20),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: ticket.photos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final photo = ticket.photos[index];
                    return InkWell(
                      onTap: () => PhotoViewDialog.show(context, photo: photo),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 130,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              photo.url,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.zoom_in, color: Colors.white, size: 12),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                color: Colors.black.withValues(alpha: 0.65),
                                child: Text(
                                  photo.caption.isNotEmpty ? photo.caption : photo.stageTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(TicketModel ticket) {
    final invoice = ticket.invoice;
    if (invoice == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Invoice • ${invoice.invoiceNumber}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                StatusBadge(status: invoice.status, fontSize: 12),
              ],
            ),
            const Divider(),
            _buildInvoiceRow('Subtotal (Approved Items)', '\$${invoice.subtotal.toStringAsFixed(2)}'),
            _buildInvoiceRow('Estimated Tax', '\$${invoice.taxAmount.toStringAsFixed(2)}'),
            if (invoice.discountAmount > 0)
              _buildInvoiceRow('Discount', '-\$${invoice.discountAmount.toStringAsFixed(2)}'),
            const Divider(),
            _buildInvoiceRow(
              'Total Amount',
              '\$${invoice.totalAmount.toStringAsFixed(2)}',
              isBold: true,
              fontSize: 16,
            ),
            if (invoice.amountPaid > 0)
              _buildInvoiceRow(
                'Amount Paid',
                '\$${invoice.amountPaid.toStringAsFixed(2)}',
                color: AppColors.success,
              ),
            _buildInvoiceRow(
              'Balance Due',
              '\$${invoice.balanceDue.toStringAsFixed(2)}',
              isBold: true,
              color: invoice.balanceDue > 0 ? AppColors.accent : AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(String label, String value, {bool isBold = false, double fontSize = 13, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? (isBold ? AppColors.primary : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(TicketModel ticket) {
    final logs = ticket.statusLogs;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Service Audit Timeline',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            if (logs.isEmpty)
              const Text('No status transitions recorded.', style: TextStyle(color: AppColors.textSecondary))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 6, right: 10),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${AppColors.getStatusLabel(log.fromStatus)} → ${AppColors.getStatusLabel(log.toStatus)}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              if (log.remarks.isNotEmpty)
                                Text(
                                  log.remarks,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
