import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/ticket_provider.dart';
import '../../models/ticket_model.dart';
import '../../models/ticket_item_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/photo_gallery_modal.dart';
import '../../widgets/photo_view_dialog.dart';
import 'add_diagnosis_item_modal.dart';
import '../customer/live_tracker_screen.dart';

class MechanicScreen extends StatefulWidget {
  const MechanicScreen({super.key});

  @override
  State<MechanicScreen> createState() => _MechanicScreenState();
}

class _MechanicScreenState extends State<MechanicScreen> {
  String? _selectedTicketId;
  final bool _isSidebarOpen = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TicketProvider>(context, listen: false).fetchTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TicketProvider>(context);
    final tickets = provider.tickets;

    final activeTickets = tickets.where((t) => [
      'CHECKED_IN',
      'INSPECTING',
      'PENDING_CUSTOMER_APPROVAL',
      'APPROVED_IN_PROGRESS',
      'WORK_COMPLETED',
    ].contains(t.currentStatus)).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        final hasSelectedTicket = _selectedTicketId != null;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              if (hasSelectedTicket)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => setState(() => _selectedTicketId = null),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.border,
                              width: 1.0,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 13,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => setState(() => _selectedTicketId = null),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          'Back to Queue',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (provider.selectedTicket != null)
                        Expanded(
                          child: Text(
                            '${provider.selectedTicket!.vehicleInfo ?? "Vehicle"} • #${provider.selectedTicket!.ticketNumber}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: hasSelectedTicket
                    ? Row(
                        children: [
                          if (!isMobile && _isSidebarOpen)
                            SizedBox(
                              width: 320,
                              child: _buildQueueSidebar(context, activeTickets, provider, isDrawer: false),
                            ),
                          Expanded(
                            child: Consumer<TicketProvider>(
                              builder: (context, tp, child) {
                                final selected = tp.selectedTicket;
                                if (tp.isLoading && selected == null) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                if (selected == null) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text('Unable to load ticket details.'),
                                        const SizedBox(height: 12),
                                        ElevatedButton(
                                          onPressed: () => setState(() => _selectedTicketId = null),
                                          child: const Text('Back to Workshop Queue'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return _buildMechanicWorkspace(context, selected, tp, isMobile: isMobile);
                              },
                            ),
                          ),
                        ],
                      )
                    : _buildFullWorkshopQueue(context, activeTickets, provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFullWorkshopQueue(
    BuildContext context,
    List<TicketModel> activeTickets,
    TicketProvider provider,
  ) {
    if (provider.isLoading && activeTickets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (activeTickets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline, size: 56, color: AppColors.success),
              ),
              const SizedBox(height: 18),
              const Text(
                'Workshop Queue is Empty',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'All vehicles checked in have been serviced or picked up.\nPull down or tap refresh to check for new intake orders.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Queue'),
                onPressed: () => provider.fetchTickets(),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchTickets(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5B7FA6), Color(0xFF4D6F94)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E3A46).withValues(alpha: 0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.build_circle, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Workshop Repair Queue',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${activeTickets.length} active service order${activeTickets.length == 1 ? '' : 's'} assigned to bay. Tap any vehicle to view details & execute work.',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'ACTIVE VEHICLE TICKETS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),

          // List of Ticket Cards
          ...activeTickets.map((ticket) {
            final approvedCount = ticket.approvedItemsCount;
            final completedCount = ticket.completedItemsCount;
            final progress = approvedCount > 0 ? (completedCount / approvedCount).clamp(0.0, 1.0) : 0.0;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: ticket.isPendingApproval
                      ? AppColors.warning.withValues(alpha: 0.5)
                      : (ticket.isInProgress ? AppColors.accent.withValues(alpha: 0.3) : AppColors.border),
                  width: 1.2,
                ),
              ),
              child: InkWell(
                onTap: () {
                  setState(() => _selectedTicketId = ticket.id);
                  provider.fetchTicketDetail(ticket.id);
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.directions_car_filled, color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ticket.vehicleInfo ?? 'Vehicle #${ticket.ticketNumber}',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Ticket #${ticket.ticketNumber} • Customer: ${ticket.customerName ?? 'Walk-in'}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(status: ticket.currentStatus, fontSize: 11),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Mileage & Fuel metrics
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.speed, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text('${ticket.mileageIn} km', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.local_gas_station, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text('Fuel: ${ticket.fuelLevelPercent}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.checklist, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text('$completedCount/$approvedCount items done', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      if (approvedCount > 0) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress >= 1.0 ? AppColors.success : AppColors.accent,
                            ),
                          ),
                        ),
                      ],

                      // Customer notes snippet
                      if (ticket.notes.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Customer Concern: "${ticket.notes}"',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 10),

                      // Action prompt
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            ticket.createdAt != null
                                ? 'Opened: ${ticket.createdAt!.month}/${ticket.createdAt!.day} ${ticket.createdAt!.hour}:${ticket.createdAt!.minute.toString().padLeft(2, '0')}'
                                : 'Recent Ticket',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const Row(
                            children: [
                              Text(
                                'View Ticket Detail',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primary),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQueueSidebar(
    BuildContext context,
    List<TicketModel> activeTickets,
    TicketProvider provider, {
    required bool isDrawer,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: isDrawer ? null : const Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.assignment_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'WORKSHOP QUEUE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${activeTickets.length} active',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  const Spacer(),
                  if (isDrawer)
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Close Queue',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.pop(context),
                    ),
                ],
              ),
            ),
            Expanded(
              child: activeTickets.isEmpty
                  ? const Center(
                      child: Text('No active work orders.', style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : ListView.separated(
                      itemCount: activeTickets.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final ticket = activeTickets[index];
                        final isSelected = _selectedTicketId == ticket.id;

                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
                          title: Text(
                            ticket.vehicleInfo ?? 'Vehicle',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(
                                '${ticket.ticketNumber} • ${ticket.completedItemsCount}/${ticket.approvedItemsCount} done',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              StatusBadge(status: ticket.currentStatus, fontSize: 10),
                            ],
                          ),
                          onTap: () {
                            setState(() => _selectedTicketId = ticket.id);
                            provider.fetchTicketDetail(ticket.id);
                            if (isDrawer) {
                              Navigator.pop(context);
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMechanicWorkspace(
    BuildContext context,
    TicketModel ticket,
    TicketProvider provider, {
    bool isMobile = false,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => setState(() => _selectedTicketId = null),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.border,
                          width: 1.0,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => setState(() => _selectedTicketId = null),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'Back to Workshop Queue',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Vehicle Header & Status Action
          Card(
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
                              ticket.vehicleInfo ?? 'Vehicle',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Ticket #${ticket.ticketNumber} • Odometer: ${ticket.mileageIn} km • Fuel: ${ticket.fuelLevelPercent}%',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(status: ticket.currentStatus, fontSize: 14),
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
                      child: Text('Customer Request: "${ticket.notes}"'),
                    ),
                  ],
                  const Divider(height: 24),
                  // Mechanic Workflow Action Buttons
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      // If CHECKED_IN -> Move to INSPECTING
                      if (ticket.currentStatus == 'CHECKED_IN')
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusInspecting),
                          icon: const Icon(Icons.search, size: 16),
                          label: const Text('Begin Vehicle Inspection'),
                          onPressed: () {
                            provider.changeTicketStatus(ticket.id, 'INSPECTING', remarks: 'Mechanic commenced inspection.');
                          },
                        ),

                      // Add Diagnosis Item
                      if (ticket.currentStatus == 'INSPECTING' || ticket.currentStatus == 'CHECKED_IN')
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Part / Labor'),
                          onPressed: () => AddDiagnosisItemModal.show(context, ticket.id),
                        ),

                      // Add Evidence Photo from Device
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.textSecondary),
                        icon: const Icon(Icons.add_a_photo, size: 16),
                        label: const Text('Upload Image'),
                        onPressed: () => _promptUploadPhoto(context, ticket, provider),
                      ),

                      // If APPROVED_IN_PROGRESS -> Quality Sign-Off
                      if (ticket.currentStatus == 'APPROVED_IN_PROGRESS')
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                          icon: const Icon(Icons.verified, size: 16),
                          label: const Text('Quality Sign-Off (WORK_COMPLETED)'),
                          onPressed: () => _promptQualitySignOff(context, ticket, provider),
                        ),

                      // Open Photo Gallery
                      OutlinedButton.icon(
                        icon: const Icon(Icons.photo_library, size: 16),
                        label: Text('Photos (${ticket.photos.length})'),
                        onPressed: () => PhotoGalleryModal.show(
                          context,
                          ticket.photos,
                          onDeletePhoto: (photo) => provider.deletePhoto(photo.id, ticket.id),
                        ),
                      ),

                      // Open Live Tracker
                      OutlinedButton.icon(
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Customer View'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => LiveTrackerScreen(ticketId: ticket.id)),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Diagnosed Items Table / Task List
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Repair Tasks & Parts Management',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${ticket.completedItemsCount} of ${ticket.approvedItemsCount} completed',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      if (ticket.currentStatus == 'INSPECTING' || ticket.currentStatus == 'CHECKED_IN') ...[
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Add Part/Labor'),
                          onPressed: () => AddDiagnosisItemModal.show(context, ticket.id),
                        ),
                      ],
                    ],
                  ),
                  const Divider(),
                  if (ticket.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          'No diagnosis items added yet. Click "Add Part / Labor" above to list issues found.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ticket.items.length,
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = ticket.items[index];
                        final isApproved = item.isApproved;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            children: [
                              // Checkbox to complete task (enabled when approved)
                              Checkbox(
                                value: item.isCompleted,
                                activeColor: AppColors.success,
                                onChanged: (!item.isCompleted && isApproved)
                                    ? (val) async {
                                        await provider.completeItem(item.id, ticket.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Marked "${item.description}" as completed! Stock updated.'),
                                              backgroundColor: AppColors.success,
                                            ),
                                          );
                                        }
                                      }
                                    : null,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: item.type == 'PART'
                                                ? Colors.blue.withValues(alpha: 0.1)
                                                : Colors.purple.withValues(alpha: 0.1),
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
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (item.mechanicNotes.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          'Notes: ${item.mechanicNotes}',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${item.totalPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                  const SizedBox(height: 4),
                                  StatusBadge(status: item.approvalStatus, fontSize: 10),
                                ],
                              ),
                              const SizedBox(width: 6),
                              // Delete task/part button
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
                                tooltip: 'Delete Task/Part',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _confirmDeleteItem(context, item, ticket, provider),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Evidence & Inspection Photos Card
          _buildEvidencePhotosSection(context, ticket, provider),

          // Bottom Workflow Action Area (Submit for Approval / Status Next Action)
          _buildBottomWorkflowBar(context, ticket, provider, isMobile),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildEvidencePhotosSection(BuildContext context, TicketModel ticket, TicketProvider provider) {
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
                    const Icon(Icons.photo_library_outlined, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Evidence & Inspection Photos (${ticket.photos.length})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    if (ticket.photos.isNotEmpty)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                        icon: const Icon(Icons.fullscreen, size: 16),
                        label: const Text('View All'),
                        onPressed: () => PhotoGalleryModal.show(
                          context,
                          ticket.photos,
                          onDeletePhoto: (photo) => provider.deletePhoto(photo.id, ticket.id),
                        ),
                      ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.add_a_photo, size: 14),
                      label: const Text('Upload Image'),
                      onPressed: () => _promptUploadPhoto(context, ticket, provider),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            if (ticket.photos.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.add_photo_alternate_outlined, size: 42, color: AppColors.textSecondary),
                      const SizedBox(height: 8),
                      const Text(
                        'No inspection or fault photos attached yet.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.file_upload_outlined, size: 16),
                        label: const Text('Upload Image'),
                        onPressed: () => _promptUploadPhoto(context, ticket, provider),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: ticket.photos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final photo = ticket.photos[index];
                    return InkWell(
                      onTap: () {
                        PhotoViewDialog.show(
                          context,
                          photo: photo,
                          onDelete: () => provider.deletePhoto(photo.id, ticket.id),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 150,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
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
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  photo.stage == 'FAULT_EVIDENCE'
                                      ? 'Fault'
                                      : (photo.stage == 'REPAIR_COMPLETED' ? 'Done' : 'Check-in'),
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.zoom_in, color: Colors.white, size: 14),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                color: Colors.black.withValues(alpha: 0.65),
                                child: Text(
                                  photo.caption.isNotEmpty ? photo.caption : photo.stageTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 11),
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
        ),
      ),
    );
  }

  Widget _buildBottomWorkflowBar(
    BuildContext context,
    TicketModel ticket,
    TicketProvider provider,
    bool isMobile,
  ) {
    if (ticket.currentStatus == 'CHECKED_IN' || ticket.currentStatus == 'INSPECTING') {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.assignment_turned_in_outlined, color: AppColors.accent, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Submit Diagnosis to Customer',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${ticket.items.length} items • Est. \$${ticket.estimatedTotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text(
                      'Submit for Customer Approval',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _confirmSubmitForApproval(context, ticket, provider),
                  ),
                ],
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.assignment_turned_in_outlined, color: AppColors.accent, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ready to submit diagnosis to vehicle owner?',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${ticket.items.length} diagnosis items recorded • Total Repair Estimate: \$${ticket.estimatedTotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 20),
                    label: const Text(
                      'Submit for Customer Approval',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _confirmSubmitForApproval(context, ticket, provider),
                  ),
                ],
              ),
      );
    }

    if (ticket.currentStatus == 'PENDING_CUSTOMER_APPROVAL') {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.statusPendingApproval.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.statusPendingApproval.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.hourglass_top, color: AppColors.statusPendingApproval, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Awaiting Customer Authorization',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.statusPendingApproval),
                  ),
                  Text(
                    'Customer has received the \$${ticket.estimatedTotal.toStringAsFixed(2)} estimate and is reviewing item-by-item approvals.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('Customer View'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LiveTrackerScreen(ticketId: ticket.id)),
                );
              },
            ),
          ],
        ),
      );
    }

    if (ticket.currentStatus == 'APPROVED_IN_PROGRESS') {
      final isAllDone = ticket.isAllApprovedItemsCompleted;
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isAllDone ? AppColors.success : AppColors.primary.withValues(alpha: 0.4)),
        ),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(isAllDone ? Icons.verified : Icons.construction,
                          color: isAllDone ? AppColors.success : AppColors.primary, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        '${ticket.completedItemsCount} / ${ticket.approvedItemsCount} Tasks Completed',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAllDone ? AppColors.success : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.verified, size: 18),
                    label: const Text('Quality Sign-Off (WORK_COMPLETED)', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _promptQualitySignOff(context, ticket, provider),
                  ),
                ],
              )
            : Row(
                children: [
                  Icon(isAllDone ? Icons.verified : Icons.construction,
                      color: isAllDone ? AppColors.success : AppColors.primary, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAllDone
                              ? 'All approved tasks completed! Ready for quality verification.'
                              : 'Repairs in progress: ${ticket.completedItemsCount} of ${ticket.approvedItemsCount} done.',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Check off tasks as completed, then sign off quality to finalize the work order.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAllDone ? AppColors.success : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    icon: const Icon(Icons.verified, size: 18),
                    label: const Text('Quality Sign-Off (WORK_COMPLETED)', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _promptQualitySignOff(context, ticket, provider),
                  ),
                ],
              ),
      );
    }

    if (ticket.currentStatus == 'WORK_COMPLETED') {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.success, size: 28),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Work Completed & Quality Inspected',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.success),
                  ),
                  Text(
                    'This work order is closed. The vehicle is ready for customer pickup and billing settlement.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _confirmDeleteItem(BuildContext context, TicketItemModel item, TicketModel ticket, TicketProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: AppColors.danger),
            SizedBox(width: 8),
            Text('Delete Diagnosis Item?'),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${item.description}" from this ticket?\n\nThe repair estimate will be recalculated automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteDiagnosisItem(item.id, ticket.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed "${item.description}". Invoice recalculated.'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmSubmitForApproval(BuildContext context, TicketModel ticket, TicketProvider provider) {
    if (ticket.items.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('No Items Diagnosed'),
          content: const Text('Please add at least one diagnosed repair item or labor task before submitting to the customer for approval.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Item Now'),
              onPressed: () {
                Navigator.pop(ctx);
                AddDiagnosisItemModal.show(context, ticket.id);
              },
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.send_rounded, color: AppColors.accent),
            SizedBox(width: 8),
            Text('Submit for Customer Approval?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vehicle: ${ticket.vehicleInfo ?? 'Vehicle'}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Ticket: #${ticket.ticketNumber}', style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Text(
              'This will submit ${ticket.items.length} diagnosed items totaling \$${ticket.estimatedTotal.toStringAsFixed(2)} to the vehicle owner for authorization.',
            ),
            const SizedBox(height: 8),
            const Text(
              'The customer will be notified via their live tracker portal immediately.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Review Again'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Submit Now'),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.changeTicketStatus(
                ticket.id,
                'PENDING_CUSTOMER_APPROVAL',
                remarks: 'Inspection completed. Mechanic submitted diagnosis (${ticket.items.length} items, \$${ticket.estimatedTotal.toStringAsFixed(2)}) for customer approval.',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Submitted to customer for approval! Live status updated.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _promptUploadPhoto(BuildContext context, TicketModel ticket, TicketProvider provider) {
    Uint8List? pickedFileBytes;
    String? pickedFileName;
    int? pickedFileSize;
    bool isUploading = false;
    final captionController = TextEditingController(text: 'Diagnosed component wear evidence');
    final urlController = TextEditingController();
    String stage = ticket.currentStatus == 'APPROVED_IN_PROGRESS' || ticket.currentStatus == 'WORK_COMPLETED'
        ? 'REPAIR_COMPLETED'
        : 'FAULT_EVIDENCE';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final hasFile = pickedFileBytes != null && pickedFileBytes!.isNotEmpty;
          final hasUrl = urlController.text.trim().isNotEmpty;
          final canUpload = (hasFile || hasUrl) && !isUploading;

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Upload Image'),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: stage,
                      decoration: const InputDecoration(labelText: 'Inspection Stage'),
                      items: const [
                        DropdownMenuItem(value: 'FAULT_EVIDENCE', child: Text('Diagnosed Fault Evidence')),
                        DropdownMenuItem(value: 'CHECKIN_INSPECTION', child: Text('Check-in Inspection')),
                        DropdownMenuItem(value: 'REPAIR_COMPLETED', child: Text('Post-Repair Completed')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => stage = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Upload Image from Device', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: isUploading
                          ? null
                          : () async {
                              try {
                                final files = await FilePicker.pickFiles(
                                  type: FileType.image,
                                );
                                if (files.isNotEmpty) {
                                  final file = files.first;
                                  final bytes = await file.readAsBytes();
                                  setDialogState(() {
                                    pickedFileBytes = bytes;
                                    pickedFileName = file.name;
                                    pickedFileSize = file.lengthSync() ?? bytes.length;
                                  });
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to pick file: $e'), backgroundColor: AppColors.danger),
                                  );
                                }
                              }
                            },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: hasFile ? AppColors.primary.withValues(alpha: 0.05) : AppColors.background,
                          border: Border.all(
                            color: hasFile ? AppColors.primary : AppColors.border,
                            width: hasFile ? 1.5 : 1.0,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: hasFile
                            ? Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      pickedFileBytes!,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          pickedFileName ?? 'Selected photo',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (pickedFileSize != null) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          '(${(pickedFileSize! / 1024).toStringAsFixed(1)} KB)',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Tap to choose a different photo',
                                    style: TextStyle(fontSize: 11, color: AppColors.primary),
                                  ),
                                ],
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.drive_folder_upload, size: 40, color: AppColors.primary),
                                  SizedBox(height: 8),
                                  Text(
                                    'Upload Image',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Click here to select an image from your device',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: captionController,
                      decoration: const InputDecoration(
                        labelText: 'Caption / Finding Description',
                        hintText: 'e.g. Brake pad wear down to 2mm',
                        prefixIcon: Icon(Icons.comment_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text(
                          'Or paste image web URL (Optional)',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        children: [
                          TextField(
                            controller: urlController,
                            onChanged: (_) => setDialogState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Web Image URL',
                              hintText: 'https://...',
                              prefixIcon: Icon(Icons.link, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isUploading ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                icon: isUploading
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.upload, size: 16),
                label: Text(isUploading ? 'Uploading...' : 'Upload Image'),
                onPressed: !canUpload
                    ? null
                    : () async {
                        setDialogState(() => isUploading = true);
                        try {
                          if (hasFile) {
                            await provider.uploadPhotoFile(
                              ticketId: ticket.id,
                              stage: stage,
                              fileBytes: pickedFileBytes!,
                              fileName: pickedFileName ?? 'evidence.jpg',
                              caption: captionController.text.trim(),
                            );
                          } else if (hasUrl) {
                            await provider.uploadPhoto(
                              ticketId: ticket.id,
                              stage: stage,
                              url: urlController.text.trim(),
                              caption: captionController.text.trim(),
                            );
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Photo uploaded to ticket documentation!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => isUploading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.danger),
                            );
                          }
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  void _promptQualitySignOff(BuildContext context, TicketModel ticket, TicketProvider provider) {
    final notesController = TextEditingController(
      text: 'All approved repairs completed. Multi-point inspection passed. Road tested and ready for customer pickup.',
    );
    Uint8List? pickedFileBytes;
    String? pickedFileName;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.verified, color: AppColors.success),
              SizedBox(width: 8),
              Text('Quality Sign-Off (WORK_COMPLETED)'),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vehicle: ${ticket.vehicleInfo ?? 'Vehicle'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Ticket: #${ticket.ticketNumber}', style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 14),
                  const Text('Closing Quality & Technician Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Enter final testing and quality verification notes...'),
                  ),
                  const SizedBox(height: 14),
                  const Text('Completed Work "After" Photo (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final files = await FilePicker.pickFiles(type: FileType.image);
                      if (files.isNotEmpty) {
                        final bytes = await files.first.readAsBytes();
                        setDialogState(() {
                          pickedFileBytes = bytes;
                          pickedFileName = files.first.name;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(pickedFileBytes != null ? Icons.check_circle : Icons.add_a_photo_outlined,
                              color: pickedFileBytes != null ? AppColors.success : AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              pickedFileName ?? 'Upload QA Image from device',
                              style: TextStyle(fontSize: 12, color: pickedFileBytes != null ? Colors.black87 : AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (pickedFileBytes != null)
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () => setDialogState(() {
                                pickedFileBytes = null;
                                pickedFileName = null;
                              }),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: isSubmitting ? null : () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              icon: isSubmitting
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline, size: 16),
              label: Text(isSubmitting ? 'Signing off...' : 'Sign-Off & Complete Ticket'),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setDialogState(() => isSubmitting = true);
                      try {
                        if (pickedFileBytes != null) {
                          await provider.uploadPhotoFile(
                            ticketId: ticket.id,
                            stage: 'REPAIR_COMPLETED',
                            fileBytes: pickedFileBytes!,
                            fileName: pickedFileName ?? 'qa_completed.jpg',
                            caption: 'Completed repair work and final QA verification',
                          );
                        }
                        await provider.changeTicketStatus(
                          ticket.id,
                          'WORK_COMPLETED',
                          remarks: notesController.text,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Quality sign-off verified! Ticket status updated to WORK_COMPLETED.'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.danger),
                          );
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}
