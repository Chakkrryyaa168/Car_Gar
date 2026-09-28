import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/vehicle_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_badge.dart';
import 'live_tracker_screen.dart';
import '../profile/profile_screen.dart';

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() => _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  List<VehicleModel> _myVehicles = [];
  bool _isLoadingVehicles = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    await ticketProvider.fetchTickets();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoadingVehicles = true);
    final api = Provider.of<TicketProvider>(context, listen: false).apiService;
    try {
      final vehicles = await api.fetchVehicles();
      if (mounted) setState(() => _myVehicles = vehicles);
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoadingVehicles = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final ticketProvider = Provider.of<TicketProvider>(context);

    final tickets = ticketProvider.tickets;
    final pendingCount = tickets.where((t) => t.isPendingApproval).length;
    final inProgressCount = tickets.where((t) => t.isInProgress).length;
    final readyCount = tickets.where((t) => t.isReadyForPickup).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Customer Garage Portal',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            tooltip: 'Refresh Tickets',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: AppColors.primary),
            tooltip: 'My Profile & Preferences',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card (Floats subtly on Mediterranean cream)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface, // #FFFFFF
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border), // #E8DAD8
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A1D29).withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
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
                                'Hi, ${auth.currentUser?.fullName ?? 'Vehicle Owner'}',
                                style: GoogleFonts.spaceGrotesk(
                                  color: AppColors.textPrimary, // #1A1D29
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Track repair progress live, inspect mechanic photos, and authorize itemized costs in real time.',
                                style: GoogleFonts.inter(color: AppColors.textBody, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated, // #FDF6F5
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(Icons.directions_car, color: AppColors.primary, size: 28),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Unique Customer ID Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated, // #FDF6F5
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Icon(Icons.badge_outlined, color: AppColors.primary, size: 16),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'MY CUSTOMER ID',
                                    style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                      letterSpacing: 0.8,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    auth.currentUser?.customerCode ?? 'CG-1001',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () {
                              final code = auth.currentUser?.customerCode ?? '';
                              if (code.isNotEmpty) {
                                Clipboard.setData(ClipboardData(text: code));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Customer ID $code copied to clipboard!', style: GoogleFonts.inter(color: AppColors.background)),
                                    backgroundColor: AppColors.primary,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.copy, color: AppColors.primary, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Copy ID',
                                    style: GoogleFonts.inter(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'State this ID to the receptionist when you arrive for instant check-in.',
                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary, // Solid navy #1A1D29
                            foregroundColor: AppColors.background, // Cream #F9EBEA
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.add, size: 16, color: AppColors.background),
                          label: Text('+ Add Vehicle', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                          onPressed: _showAddVehicleDialog,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // KPI Metric Cards
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      'Action Needed',
                      '$pendingCount',
                      Icons.warning_amber_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      'In Repairs',
                      '$inProgressCount',
                      Icons.build_circle_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      'Ready Pickup',
                      '$readyCount',
                      Icons.car_rental,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Registered Vehicles Card
              Card(
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
                              const Icon(Icons.garage_outlined, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'MY REGISTERED VEHICLES',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                            icon: const Icon(Icons.add_circle_outline, size: 16),
                            label: Text('Add Vehicle', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                            onPressed: _showAddVehicleDialog,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_isLoadingVehicles)
                        const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                      else if (_myVehicles.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'No vehicles registered yet. Tap "+ Add Vehicle" to link your car.',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: _myVehicles.map((v) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated, // #FDF6F5
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border), // #E8DAD8
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.directions_car_filled, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${v.make} ${v.model} (${v.year})',
                                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                                      ),
                                      Text(
                                        'Plate: ${v.licensePlate} • VIN: ${v.vin.isNotEmpty ? v.vin : 'N/A'}',
                                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Service Tickets Section
              Text(
                'YOUR SERVICE ORDERS & LIVE PROGRESS',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              if (ticketProvider.isLoading && tickets.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ))
              else if (tickets.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(Icons.directions_car_filled_outlined, size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      Text(
                        'No service tickets found for your account.',
                        style: GoogleFonts.inter(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tickets.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final ticket = tickets[index];

                    return Card(
                      color: AppColors.surface, // #FFFFFF
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => LiveTrackerScreen(ticketId: ticket.id)),
                          );
                        },
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
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'Ticket #${ticket.ticketNumber} • Lead Tech: ${ticket.leadMechanicName ?? 'Assigned Workshop'}',
                                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  StatusBadge(status: ticket.currentStatus),
                                ],
                              ),
                              if (ticket.notes.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    'Initial Complaint: "${ticket.notes}"',
                                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textBody),
                                  ),
                                ),
                              ],
                              // Action Banner if Pending Approval
                              if (ticket.isPendingApproval) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.primary, width: 1.2),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.notification_important_outlined, color: AppColors.primary),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Technician diagnosis completed! Review itemized repairs and photo evidence to approve.',
                                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: AppColors.background,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          elevation: 0,
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => LiveTrackerScreen(ticketId: ticket.id)),
                                          );
                                        },
                                        child: Text('Review', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // Ready for pickup banner
                              if (ticket.isReadyForPickup) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_outline, color: AppColors.primary),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'All repairs complete & quality tested! Your vehicle is ready for pickup.',
                                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: AppColors.background,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          elevation: 0,
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => LiveTrackerScreen(ticketId: ticket.id)),
                                          );
                                        },
                                        child: Text('View Bill', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const Divider(height: 20, color: AppColors.border),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.task_alt, size: 16, color: AppColors.textSecondary),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${ticket.completedItemsCount}/${ticket.approvedItemsCount} tasks completed',
                                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'Total: \$${ticket.totalEstimatedAmount.toStringAsFixed(2)}',
                                        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 14),
                                      ),
                                      const SizedBox(width: 10),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: AppColors.background,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          elevation: 0,
                                        ),
                                        icon: const Icon(Icons.visibility, size: 14, color: AppColors.background),
                                        label: Text('Live Tracker', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
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
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'Click card to see mechanic findings & detail',
                                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward, size: 12, color: AppColors.textSecondary),
                                ],
                              ),
                            ],
                          ),
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

  Widget _buildMetricTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface, // #FFFFFF
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border), // #E8DAD8
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1D29).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddVehicleDialog() {
    final makeCtrl = TextEditingController(text: 'Honda');
    final modelCtrl = TextEditingController(text: 'CR-V');
    final plateCtrl = TextEditingController(text: 'XYZ-7890');
    final yearCtrl = TextEditingController(text: '2023');
    final colorCtrl = TextEditingController(text: 'Modern Steel');
    final vinCtrl = TextEditingController(text: '2HKRW2H87NH${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface, // #FFFFFF
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Row(
          children: [
            const Icon(Icons.directions_car, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Register Customer Vehicle',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: plateCtrl,
                decoration: const InputDecoration(labelText: 'License Plate'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: makeCtrl,
                decoration: const InputDecoration(labelText: 'Make (e.g. Honda)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: modelCtrl,
                decoration: const InputDecoration(labelText: 'Model (e.g. CR-V)'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: yearCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Year'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: colorCtrl,
                      decoration: const InputDecoration(labelText: 'Color'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: vinCtrl,
                decoration: const InputDecoration(labelText: 'VIN Number (17 chars)'),
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.accent),
              foregroundColor: AppColors.textBody,
            ),
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
            ),
            onPressed: () async {
              final api = Provider.of<TicketProvider>(context, listen: false).apiService;
              final auth = Provider.of<AuthProvider>(context, listen: false);
              try {
                await api.createVehicle(
                  licensePlate: plateCtrl.text.trim(),
                  vin: vinCtrl.text.trim(),
                  make: makeCtrl.text.trim(),
                  model: modelCtrl.text.trim(),
                  year: int.tryParse(yearCtrl.text) ?? 2023,
                  color: colorCtrl.text.trim(),
                  ownerId: auth.currentUser?.id,
                );
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                _loadVehicles();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Vehicle successfully registered to your account!', style: GoogleFonts.inter(color: AppColors.background)),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e', style: GoogleFonts.inter(color: AppColors.background)),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              }
            },
            child: Text('Save Vehicle', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
