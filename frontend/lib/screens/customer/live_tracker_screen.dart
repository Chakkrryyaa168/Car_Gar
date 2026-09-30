import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/ticket_model.dart';
import '../../models/ticket_item_model.dart';
import '../../providers/ticket_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_animations.dart';
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
  final Map<String, String> _itemDecisions = {}; // itemId -> 'APPROVED' | 'REJECTED'
  bool _isSubmitting = false;

  void _syncDecisions(List<TicketItemModel> items) {
    for (var item in items) {
      if (item.isPending && !_itemDecisions.containsKey(item.id)) {
        _itemDecisions[item.id] = 'APPROVED';
      }
    }
  }

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
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF5B7FA6), Color(0xFF4D6F94)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1F2E3A46),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () => Navigator.maybePop(context),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.20),
                      width: 1.0,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            title: Text(
              ticket != null ? 'Live Tracker • ${ticket.ticketNumber}' : 'Live Ticket Tracker',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: InkWell(
                  onTap: () => provider.fetchTicketDetail(widget.ticketId),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20),
                        width: 1.0,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: provider.isLoading && ticket == null
              ? const Center(child: CircularProgressIndicator())
              : ticket == null
                  ? Center(
                      child: Text(
                        provider.errorMessage ?? 'Ticket not found.',
                        style: GoogleFonts.inter(color: AppColors.textSecondary),
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
                            StaggeredFadeSlide(
                              index: 0,
                              child: _buildVehicleHeaderCard(ticket),
                            ),
                            const SizedBox(height: 16),

                            // 2. Multi-Step Visual Progress Stepper
                            StaggeredFadeSlide(
                              index: 1,
                              child: ProgressStepper(currentStatus: ticket.currentStatus),
                            ),
                            const SizedBox(height: 16),

                            // 3. Customer Action Alert Banner (if awaiting approval)
                            if (ticket.currentStatus == 'PENDING_CUSTOMER_APPROVAL') ...[
                              StaggeredFadeSlide(
                                index: 2,
                                child: _buildPendingApprovalBanner(ticket),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // 4. Live Repair Items Checklist
                            StaggeredFadeSlide(
                              index: 3,
                              child: _buildRepairChecklist(ticket),
                            ),
                            const SizedBox(height: 16),

                            // 5. Photos & Visual Evidence Section
                            StaggeredFadeSlide(
                              index: 4,
                              child: _buildPhotoEvidenceCard(ticket),
                            ),
                            const SizedBox(height: 16),

                            // 6. Dynamic Invoice Summary
                            if (ticket.invoice != null) ...[
                              StaggeredFadeSlide(
                                index: 5,
                                child: _buildInvoiceCard(ticket),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // 7. Status Timeline & Audit Log
                            StaggeredFadeSlide(
                              index: 6,
                              child: _buildTimelineCard(ticket),
                            ),
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
      color: AppColors.surface, // #FFFFFF
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.vehicleInfo ?? 'Vehicle Information',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Ticket #${ticket.ticketNumber}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (ticket.customerCode != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                'Customer ID: ${ticket.customerCode}',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: ticket.currentStatus, fontSize: 13),
              ],
            ),
            const Divider(color: AppColors.border),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoMetric(Icons.speed, 'Odometer In', '${ticket.mileageIn} km'),
                _buildInfoMetric(Icons.local_gas_station, 'Fuel Level', '${ticket.fuelLevelPercent}%'),
                _buildInfoMetric(
                  Icons.event_available,
                  'Opened',
                  ticket.createdAt != null
                      ? '${ticket.createdAt!.month}/${ticket.createdAt!.day}/${ticket.createdAt!.year}'
                      : 'Today',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildAssignedMechanicCard(ticket),
            if (ticket.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Customer Concern: "${ticket.notes}"',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textBody,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAssignedMechanicCard(TicketModel ticket) {
    final mechanicName = ticket.leadMechanicName;
    final specialization = ticket.leadMechanicSpecialization ?? ticket.leadMechanic?.profile?.specialization;
    final avatarUrl = ticket.leadMechanicAvatar ?? ticket.leadMechanic?.profile?.avatarUrl;
    final bio = ticket.leadMechanic?.profile?.bio;
    final hasMechanic = mechanicName != null && mechanicName.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated, // #FDF6F5
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.surface,
            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? NetworkImage(avatarUrl)
                : null,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? Icon(
                    hasMechanic ? Icons.engineering : Icons.person_search,
                    color: AppColors.primary,
                    size: 24,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      hasMechanic ? 'Assigned Mechanic' : 'Technician Allocation',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (hasMechanic) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified, size: 10, color: AppColors.primary),
                            const SizedBox(width: 3),
                            Text(
                              'Verified Pro',
                              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  hasMechanic ? mechanicName : 'Pending Assignment',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (hasMechanic && specialization != null && specialization.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      specialization,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textBody,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else if (!hasMechanic)
                  Text(
                    'Our workshop supervisor is assigning a specialist technician.',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                  ),
                if (bio != null && bio.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      bio,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
        ],
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
          style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildPendingApprovalBanner(TicketModel ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated, // #FDF6F5
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 1.2), // Navy emphasis
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notification_important_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Customer Action Required',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Vehicle inspection has concluded. Please inspect diagnosed items and authorize or decline repairs individually.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textBody),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: AppPressable(
              onPressed: () => ItemApprovalDialog.show(context, ticket),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, // Solid Sage #5F7F6B
                  foregroundColor: Colors.white, // White text
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                icon: const Icon(Icons.touch_app, size: 18, color: Colors.white),
                label: Text(
                  'Review & Authorize Repairs',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                onPressed: () => ItemApprovalDialog.show(context, ticket),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepairChecklist(TicketModel ticket) {
    final items = ticket.items;
    _syncDecisions(items);

    final pendingItems = items.where((i) => i.isPending).toList();
    final hasPending = pendingItems.isNotEmpty;

    int approvedPendingCount = 0;
    double approvedPendingTotal = 0.0;
    for (var item in pendingItems) {
      if ((_itemDecisions[item.id] ?? 'APPROVED') == 'APPROVED') {
        approvedPendingCount++;
        approvedPendingTotal += item.totalPrice;
      }
    }
    final allSelected = hasPending && approvedPendingCount == pendingItems.length;

    return Card(
      color: AppColors.surface, // #FFFFFF
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
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
                    const Icon(Icons.checklist_rtl_rounded, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'DIAGNOSED REPAIRS & ESTIMATES',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${items.length} item(s)',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasPending) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Items awaiting your decision before work starts:',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        setState(() {
                          final newStatus = allSelected ? 'REJECTED' : 'APPROVED';
                          for (var pi in pendingItems) {
                            _itemDecisions[pi.id] = newStatus;
                          }
                        });
                      },
                      child: Text(
                        allSelected ? 'Uncheck All' : 'Select All',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  'No repair items listed yet.',
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 16, color: AppColors.border),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isDone = item.isCompleted;
                  final isPending = item.isPending;
                  final isApprovedDecision = (_itemDecisions[item.id] ?? (isPending ? 'APPROVED' : item.approvalStatus)) == 'APPROVED';

                  return AnimatedContainer(
                    duration: AppAnimations.durFast,
                    curve: AppAnimations.ease,
                    decoration: BoxDecoration(
                      color: isPending
                          ? (isApprovedDecision
                              ? AppColors.surfaceWarm
                              : AppColors.background)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isPending
                            ? (isApprovedDecision ? AppColors.primary : AppColors.border.withValues(alpha: 0.6))
                            : AppColors.border,
                        width: isPending && isApprovedDecision ? 1.2 : 1.0,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _showItemDetailModal(context, item, ticket),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left: Checkbox (if pending) or Status Circle (if decided/completed)
                            if (isPending)
                              Padding(
                                padding: const EdgeInsets.only(right: 8, top: 2),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: isApprovedDecision,
                                    activeColor: AppColors.primary,
                                    checkColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    onChanged: (bool? checked) {
                                      setState(() {
                                        _itemDecisions[item.id] = (checked == true) ? 'APPROVED' : 'REJECTED';
                                      });
                                    },
                                  ),
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.only(right: 10, top: 4),
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDone
                                        ? AppColors.primary
                                        : item.isApproved
                                            ? AppColors.surfaceElevated
                                            : AppColors.surface,
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      isDone ? Icons.check : (item.isApproved ? Icons.timelapse : Icons.remove),
                                      size: 16,
                                      color: isDone
                                          ? Colors.white
                                          : item.isApproved
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            // Description & Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceElevated,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        child: Text(
                                          item.type,
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          item.description,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            decoration: (!isPending && item.isRejected) ? TextDecoration.lineThrough : null,
                                            color: (!isPending && item.isRejected)
                                                ? AppColors.textSecondary
                                                : AppColors.textPrimary,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Text(
                                        'Qty: ${item.quantity} • Unit: \$${item.unitPrice.toStringAsFixed(2)}',
                                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('•', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'See details >',
                                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  if (item.mechanicNotes.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceElevated,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.only(top: 1.5),
                                            child: Icon(Icons.handyman_outlined, size: 12, color: AppColors.primary),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Tech note: ${item.mechanicNotes}',
                                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textBody, fontStyle: FontStyle.italic),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Price & Badge / Choice Action
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${item.totalPrice.toStringAsFixed(2)}',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (isPending)
                                  MorphingDecisionButton(
                                    isApproved: isApprovedDecision,
                                    onTap: () {
                                      setState(() {
                                        _itemDecisions[item.id] = isApprovedDecision ? 'REJECTED' : 'APPROVED';
                                      });
                                    },
                                  )
                                else
                                  StatusBadge(
                                    status: item.approvalStatus,
                                    fontSize: 10,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            if (hasPending) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated, // #FDF6F5
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Authorize Selected Repairs',
                              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                            ),
                            Text(
                              '$approvedPendingCount of ${pendingItems.length} repair(s) marked for approval',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Selected Total', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                            CountingAmountText(
                              value: approvedPendingTotal,
                              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppPressable(
                      onPressed: _isSubmitting ? null : () => _sendChoicesToTechnician(ticket),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary, // Solid Sage #5F7F6B
                          foregroundColor: Colors.white, // White text
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                        label: Text(
                          _isSubmitting
                              ? 'Sending to Technician...'
                              : (approvedPendingCount > 0
                                  ? 'Send Choices to Technician & Start Work'
                                  : 'Send Decisions (Decline Selected)'),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        onPressed: _isSubmitting ? null : () => _sendChoicesToTechnician(ticket),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _sendChoicesToTechnician(TicketModel ticket) async {
    final pendingItems = ticket.items.where((i) => i.isPending).toList();
    if (pendingItems.isEmpty) return;

    final approvals = pendingItems.map((item) {
      final status = _itemDecisions[item.id] ?? 'APPROVED';
      return {'item_id': item.id, 'status': status};
    }).toList();

    final approvedList = approvals.where((a) => a['status'] == 'APPROVED').toList();
    final rejectedList = approvals.where((a) => a['status'] == 'REJECTED').toList();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Row(
          children: [
            const Icon(Icons.send_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Send Authorization',
              style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Submit repair decisions for Ticket #${ticket.ticketNumber}?',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            if (approvedList.isNotEmpty)
              Text(
                '✓ ${approvedList.length} repair item(s) approved to start work',
                style: GoogleFonts.inter(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            if (rejectedList.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '✕ ${rejectedList.length} repair item(s) declined',
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'The technician will be notified immediately to proceed with approved work.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textBody),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Back', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Confirm & Send', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    setState(() => _isSubmitting = true);
    try {
      final provider = Provider.of<TicketProvider>(context, listen: false);
      await provider.batchApproveItems(ticket.id, approvals);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approvedList.isNotEmpty
                  ? 'Your authorization was sent to the technician! Repairs are now in progress.'
                  : 'Your repair decisions have been submitted to the workshop.',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $e', style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showItemDetailModal(BuildContext context, TicketItemModel item, TicketModel ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isPending = item.isPending;
          final currentDecision = _itemDecisions[item.id] ?? (isPending ? 'APPROVED' : item.approvalStatus);
          final isApproved = currentDecision == 'APPROVED';

          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                top: BorderSide(color: AppColors.border),
                left: BorderSide(color: AppColors.border),
                right: BorderSide(color: AppColors.border),
              ),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Title and Type
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(
                        item.type == 'PART' ? Icons.extension_outlined : Icons.engineering_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.description,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.type} • Ticket #${ticket.ticketNumber}',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(modalCtx),
                    ),
                  ],
                ),
                const Divider(height: 24, color: AppColors.border),
                // Pricing Breakdown
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Unit Price:', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
                          Text('\$${item.unitPrice.toStringAsFixed(2)}', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Quantity:', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
                          Text('${item.quantity}', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                        ],
                      ),
                      const Divider(height: 16, color: AppColors.border),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Estimated Cost:', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                          Text(
                            '\$${item.totalPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Diagnostic Findings
                Text('Technician Diagnostic Findings', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.handyman_outlined, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.mechanicNotes.isNotEmpty
                              ? item.mechanicNotes
                              : 'No specific findings logged for this repair item.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: item.mechanicNotes.isNotEmpty ? AppColors.textBody : AppColors.textSecondary,
                            fontStyle: item.mechanicNotes.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (ticket.photos.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      side: const BorderSide(color: AppColors.accent),
                      foregroundColor: AppColors.primary,
                    ),
                    icon: const Icon(Icons.photo_library_outlined, size: 16, color: AppColors.primary),
                    label: Text('View Inspection Photos (${ticket.photos.length})', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                    onPressed: () {
                      Navigator.pop(modalCtx);
                      PhotoGalleryModal.show(context, ticket.photos);
                    },
                  ),
                ],
                const SizedBox(height: 16),
                // Decision Section
                if (isPending) ...[
                  Text('Your Authorization Choice', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setModalState(() {});
                            setState(() {
                              _itemDecisions[item.id] = 'APPROVED';
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isApproved ? AppColors.surfaceElevated : AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isApproved ? AppColors.primary : AppColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isApproved ? Icons.check_circle : Icons.radio_button_unchecked,
                                      color: isApproved ? AppColors.primary : AppColors.textSecondary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Approve',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        color: isApproved ? AppColors.primary : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Authorize repair for \$${item.totalPrice.toStringAsFixed(2)}',
                                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setModalState(() {});
                            setState(() {
                              _itemDecisions[item.id] = 'REJECTED';
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: !isApproved ? AppColors.surfaceElevated : AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: !isApproved ? AppColors.accent : AppColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      !isApproved ? Icons.cancel : Icons.radio_button_unchecked,
                                      color: !isApproved ? AppColors.primary : AppColors.textSecondary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Decline',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        color: !isApproved ? AppColors.primary : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Do not perform this repair now',
                                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            foregroundColor: AppColors.textPrimary,
                          ),
                          onPressed: () => Navigator.pop(modalCtx),
                          child: Text('Save Choice', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                          label: Text('Send to Tech', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          onPressed: () {
                            Navigator.pop(modalCtx);
                            _sendChoicesToTechnician(ticket);
                          },
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Item already determined
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.isApproved ? Icons.check_circle : Icons.cancel,
                          color: item.isApproved ? AppColors.primary : AppColors.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.isApproved
                                ? 'This repair has been authorized. Status: ${item.isCompleted ? 'Completed' : 'In Progress'}.'
                                : 'This repair was declined by customer.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textBody,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(modalCtx),
                      child: Text('Close', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotoEvidenceCard(TicketModel ticket) {
    final photoCount = ticket.photos.length;

    return Card(
      color: AppColors.surface, // #FFFFFF
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
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
                        Text(
                          'Visual Photo Evidence',
                          style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        Text(
                          '$photoCount inspection photos attached by mechanic',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                if (ticket.photos.isNotEmpty)
                  AppPressable(
                    onPressed: () => PhotoGalleryModal.show(context, ticket.photos),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.accent),
                        foregroundColor: AppColors.primary,
                      ),
                      icon: const Icon(Icons.fullscreen, size: 16, color: AppColors.primary),
                      label: Text('View All', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                      onPressed: () => PhotoGalleryModal.show(context, ticket.photos),
                    ),
                  ),
              ],
            ),
            if (ticket.photos.isNotEmpty) ...[
              const Divider(height: 20, color: AppColors.border),
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
                                color: AppColors.surfaceElevated,
                                child: const Icon(Icons.broken_image, color: AppColors.textSecondary),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: AppColors.surface.withValues(alpha: 0.85),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.zoom_in, color: AppColors.primary, size: 12),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                color: AppColors.charcoal.withValues(alpha: 0.85),
                                child: Text(
                                  photo.caption.isNotEmpty ? photo.caption : photo.stageTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(color: AppColors.background, fontSize: 10),
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
      color: AppColors.invoiceBg, // #2B2F2C Deep charcoal
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.invoiceBorder), // #3F4541
      ),
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
                    const Icon(Icons.receipt_long, color: AppColors.sage),
                    const SizedBox(width: 8),
                    Text(
                      'Invoice • ${invoice.invoiceNumber}',
                      style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.invoiceText),
                    ),
                  ],
                ),
                StatusBadge(status: invoice.status, fontSize: 12),
              ],
            ),
            const Divider(color: AppColors.invoiceBorder),
            _buildInvoiceRow('Subtotal (Approved Items)', '\$${invoice.subtotal.toStringAsFixed(2)}', numericVal: invoice.subtotal),
            _buildInvoiceRow('Estimated Tax', '\$${invoice.taxAmount.toStringAsFixed(2)}', numericVal: invoice.taxAmount),
            if (invoice.discountAmount > 0)
              _buildInvoiceRow('Discount', '-\$${invoice.discountAmount.toStringAsFixed(2)}'),
            const Divider(color: AppColors.invoiceBorder),
            _buildInvoiceRow(
              'Total Amount',
              '\$${invoice.totalAmount.toStringAsFixed(2)}',
              isBold: true,
              fontSize: 16,
              color: AppColors.invoiceText,
              numericVal: invoice.totalAmount,
            ),
            if (invoice.amountPaid > 0)
              _buildInvoiceRow(
                'Amount Paid',
                '\$${invoice.amountPaid.toStringAsFixed(2)}',
                color: AppColors.invoiceMuted,
                numericVal: invoice.amountPaid,
              ),
            _buildInvoiceRow(
              'Balance Due',
              '\$${invoice.balanceDue.toStringAsFixed(2)}',
              isBold: true,
              color: AppColors.invoiceText,
              numericVal: invoice.balanceDue,
            ),
            const SizedBox(height: 14),
            // Sage pay button with white text
            SizedBox(
              width: double.infinity,
              child: AppPressable(
                onPressed: invoice.balanceDue > 0
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Payment simulated for invoice ${invoice.invoiceNumber}!', style: GoogleFonts.inter(color: Colors.white)),
                            backgroundColor: AppColors.sage,
                          ),
                        );
                      }
                    : null,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sage, // #5F7F6B
                    foregroundColor: Colors.white, // white text
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.payment, size: 16, color: Colors.white),
                  label: Text(
                    invoice.balanceDue > 0
                        ? 'Pay Balance Due (\$${invoice.balanceDue.toStringAsFixed(2)})'
                        : 'Invoice Paid in Full',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  onPressed: invoice.balanceDue > 0
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Payment simulated for invoice ${invoice.invoiceNumber}!', style: GoogleFonts.inter(color: Colors.white)),
                              backgroundColor: AppColors.sage,
                            ),
                          );
                        }
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(String label, String value, {bool isBold = false, double fontSize = 13, Color? color, double? numericVal}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
              color: isBold ? AppColors.invoiceText : AppColors.invoiceMuted,
            ),
          ),
          numericVal != null
              ? CountingAmountText(
                  value: numericVal,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: fontSize,
                    fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                    color: color ?? AppColors.invoiceText,
                  ),
                )
              : Text(
                  value,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: fontSize,
                    fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                    color: color ?? AppColors.invoiceText,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(TicketModel ticket) {
    final logs = ticket.statusLogs;

    return Card(
      color: AppColors.surface, // #FFFFFF
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Service Audit Timeline',
                  style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ],
            ),
            const Divider(color: AppColors.border),
            if (logs.isEmpty)
              Text('No status transitions recorded.', style: GoogleFonts.inter(color: AppColors.textSecondary))
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
                                style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              ),
                              if (log.remarks.isNotEmpty)
                                Text(
                                  log.remarks,
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
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
