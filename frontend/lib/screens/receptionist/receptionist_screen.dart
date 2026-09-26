import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ticket_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_badge.dart';
import '../customer/live_tracker_screen.dart';
import 'checkin_modal.dart';
import 'payment_modal.dart';

class ReceptionistScreen extends StatefulWidget {
  const ReceptionistScreen({super.key});

  @override
  State<ReceptionistScreen> createState() => _ReceptionistScreenState();
}

class _ReceptionistScreenState extends State<ReceptionistScreen> {
  String _filter = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TicketProvider>(context, listen: false).fetchTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ticketProvider = Provider.of<TicketProvider>(context);
    final allTickets = ticketProvider.tickets;

    final filteredTickets = _filter == 'ALL'
        ? allTickets
        : allTickets.where((t) => t.currentStatus == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receptionist Desk & Cashier'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ticketProvider.fetchTickets(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ticketProvider.fetchTickets(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reception Banner & Check-in CTA
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.primary,
                        radius: 24,
                        child: Icon(Icons.front_hand, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reception & Service Counter',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Manage intake, check-in inspections, customer billing & payments.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent, // #F97316
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New Check-In'),
                        onPressed: () => CheckInModal.show(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'All Tickets (${allTickets.length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip('CHECKED_IN', 'Checked In'),
                    const SizedBox(width: 8),
                    _buildFilterChip('WORK_COMPLETED', 'Work Done (Needs Invoice)'),
                    const SizedBox(width: 8),
                    _buildFilterChip('READY_FOR_PICKUP', 'Ready For Pickup'),
                    const SizedBox(width: 8),
                    _buildFilterChip('PAID_AND_CLOSED', 'Paid & Closed'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tickets List
              if (ticketProvider.isLoading && allTickets.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ))
              else if (filteredTickets.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: const Text('No tickets found matching current filter.'),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredTickets.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final ticket = filteredTickets[index];

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
                                        ticket.vehicleInfo ?? 'Vehicle',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Customer: ${ticket.customerName ?? 'Unknown'} (${ticket.customerPhone ?? 'No phone'})',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusBadge(status: ticket.currentStatus),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Ticket #${ticket.ticketNumber}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Estimated: \$${ticket.totalEstimatedAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Quick Status Action Buttons for Receptionist
                            Align(
                              alignment: Alignment.centerRight,
                              child: Wrap(
                                alignment: WrapAlignment.end,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.phone_in_talk, size: 14, color: AppColors.primary),
                                    label: const Text('Contact Customer'),
                                    onPressed: () => _showCustomerCoordination(context, ticket),
                                  ),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.open_in_new, size: 14),
                                    label: const Text('Live Tracker'),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => LiveTrackerScreen(ticketId: ticket.id),
                                        ),
                                      );
                                    },
                                  ),

                                  // Transition WORK_COMPLETED -> READY_FOR_PICKUP
                                  if (ticket.currentStatus == 'WORK_COMPLETED')
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                                      icon: const Icon(Icons.send_rounded, size: 14),
                                      label: const Text('Issue Invoice & Notify'),
                                      onPressed: () async {
                                        await ticketProvider.changeTicketStatus(
                                          ticket.id,
                                          'READY_FOR_PICKUP',
                                          remarks: 'Invoice issued by front desk. Customer notified for pickup.',
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Vehicle marked READY_FOR_PICKUP. Customer notified!'),
                                              backgroundColor: AppColors.success,
                                            ),
                                          );
                                        }
                                      },
                                    ),

                                  // Collect Payment if READY_FOR_PICKUP
                                  if (ticket.currentStatus == 'READY_FOR_PICKUP')
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                                      icon: const Icon(Icons.payments, size: 14),
                                      label: const Text('Collect Payment'),
                                      onPressed: () async {
                                        await ticketProvider.fetchTicketDetail(ticket.id);
                                        if (context.mounted && ticketProvider.selectedTicket != null) {
                                          PaymentModal.show(context, ticketProvider.selectedTicket!);
                                        }
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
      onSelected: (_) => setState(() => _filter = value),
    );
  }

  void _showCustomerCoordination(BuildContext context, dynamic ticket) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.support_agent, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Contact ${ticket.customerName ?? 'Customer'}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vehicle: ${ticket.vehicleInfo ?? 'Vehicle'}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Phone: ${ticket.customerPhone ?? 'Not on file'}', style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Fast Notification Actions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 10),
            ListTile(
              dense: true,
              leading: const Icon(Icons.notifications_active, color: AppColors.accent),
              title: const Text('Send Approval Reminder Alert'),
              subtitle: const Text('Notify customer that technician diagnosis is awaiting approval.'),
              onTap: () {
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Approval reminder notification dispatched to customer device!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.car_rental, color: AppColors.success),
              title: const Text('Send Ready for Pickup Alert'),
              subtitle: const Text('Notify customer that all repairs are finished and car is ready.'),
              onTap: () {
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vehicle ready alert sent to customer!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Close')),
        ],
      ),
    );
  }
}
