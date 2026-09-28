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
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _lookupResults = [];
  bool _isSearchingCustomer = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TicketProvider>(context, listen: false).fetchTickets();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged(String query) async {
    final trimmed = query.trim();
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);

    // Filter tickets in list in real time
    ticketProvider.fetchTickets(
      status: _filter == 'ALL' ? null : _filter,
      search: trimmed.isNotEmpty ? trimmed : null,
      showLoading: false,
    );

    if (trimmed.isEmpty) {
      if (mounted) {
        setState(() {
          _lookupResults = [];
          _isSearchingCustomer = false;
        });
      }
      return;
    }

    setState(() => _isSearchingCustomer = true);
    try {
      final results = await ticketProvider.apiService.lookupCustomer(trimmed);
      if (mounted) {
        setState(() {
          _lookupResults = results;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isSearchingCustomer = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketProvider = Provider.of<TicketProvider>(context);
    final allTickets = ticketProvider.tickets;

    final filteredTickets = _filter == 'ALL'
        ? allTickets
        : allTickets.where((t) => t.currentStatus == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
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

              // Returning Customer Intake & ID Search Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.badge_outlined, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Returning Customer Intake & Fast Search',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  'Ask customer for their unique ID (e.g. CG-1042), phone, or plate.',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Enter Customer ID (e.g. CG-1042 or 1042), phone, or plate...',
                          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: AppColors.background,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: _onSearchChanged,
                        onSubmitted: _onSearchChanged,
                      ),
                      if (_isSearchingCustomer) ...[
                        const SizedBox(height: 10),
                        const LinearProgressIndicator(minHeight: 2),
                      ],
                      if (_lookupResults.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Identified Returning Customer:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                        ..._lookupResults.map((c) => _buildCustomerLookupCard(c)),
                      ],
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
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (ticket.customerCode != null) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              margin: const EdgeInsets.only(right: 6),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                              ),
                                              child: Text(
                                                ticket.customerCode!,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                          Expanded(
                                            child: Text(
                                              'Customer: ${ticket.customerName ?? 'Unknown'} (${ticket.customerPhone ?? 'No phone'})',
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
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

  Widget _buildCustomerLookupCard(Map<String, dynamic> c) {
    final customerCode = c['customer_code'] ?? 'CG-XXXX';
    final fullName = c['full_name'] ?? 'Customer';
    final phone = c['phone_number'] ?? 'No phone';
    final email = c['email'] ?? '';
    final vehicles = (c['vehicles'] as List?) ?? [];
    final activeTickets = c['active_tickets_count'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.badge, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      customerCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '$phone • $email',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (activeTickets > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$activeTickets Active Ticket${activeTickets > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),
          const Text(
            'Registered Vehicles (Tap to Check In):',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          if (vehicles.isEmpty) ...[
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'No vehicles registered yet for this customer.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  icon: const Icon(Icons.add, size: 14, color: Colors.white),
                  label: const Text('Check In New Vehicle', style: TextStyle(fontSize: 11, color: Colors.white)),
                  onPressed: () => CheckInModal.show(context, initialOwnerId: c['id']),
                ),
              ],
            ),
          ] else ...[
            ...vehicles.map((v) {
              final vId = v['id'];
              final vDisplay = '${v['year']} ${v['make']} ${v['model']} (${v['license_plate']})';
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        vDisplay,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.login, size: 12, color: Colors.white),
                      label: const Text('Check In', style: TextStyle(fontSize: 11, color: Colors.white)),
                      onPressed: () => CheckInModal.show(
                        context,
                        initialVehicleId: vId,
                        initialOwnerId: c['id'],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
