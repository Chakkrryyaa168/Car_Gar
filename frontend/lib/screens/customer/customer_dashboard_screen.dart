import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vehicle_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_badge.dart';
import 'live_tracker_screen.dart';

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
      appBar: AppBar(
        title: const Text('Customer Garage Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Tickets',
            onPressed: _loadData,
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
              // Welcome Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A5F), Color(0xFF2C5282)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A5F).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
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
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Track repair progress live, inspect mechanic photos, and authorize itemized costs in real time.',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.directions_car, color: Colors.white, size: 28),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white60),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('+ Add Vehicle', style: TextStyle(fontSize: 13)),
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
                      AppColors.statusPendingApproval,
                      Icons.warning_amber_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      'In Repairs',
                      '$inProgressCount',
                      AppColors.statusApprovedInProgress,
                      Icons.build_circle_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      'Ready Pickup',
                      '$readyCount',
                      AppColors.statusReadyForPickup,
                      Icons.car_rental,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Registered Vehicles Card
              Card(
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
                              Icon(Icons.garage_outlined, color: Color(0xFF1E3A5F), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'MY REGISTERED VEHICLES',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add_circle_outline, size: 16),
                            label: const Text('Add Vehicle', style: TextStyle(fontSize: 12)),
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
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'No vehicles registered yet. Tap "+ Add Vehicle" to link your car.',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                                color: const Color(0xFF1E3A5F).withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF1E3A5F).withValues(alpha: 0.15)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.directions_car_filled, size: 18, color: Color(0xFF1E3A5F)),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${v.make} ${v.model} (${v.year})',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      Text(
                                        'Plate: ${v.licensePlate} • VIN: ${v.vin.isNotEmpty ? v.vin : 'N/A'}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
              const Text(
                'YOUR SERVICE ORDERS & LIVE PROGRESS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
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
                  child: const Column(
                    children: [
                      Icon(Icons.directions_car_filled_outlined, size: 48, color: AppColors.textSecondary),
                      SizedBox(height: 12),
                      Text(
                        'No service tickets found for your account.',
                        style: TextStyle(color: AppColors.textSecondary),
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
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'Ticket #${ticket.ticketNumber} • Lead Tech: ${ticket.leadMechanicName ?? 'Assigned Workshop'}',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Initial Complaint: "${ticket.notes}"',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                              // Highlight Action Banner if Pending Approval
                              if (ticket.isPendingApproval) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF97316).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.notification_important, color: Color(0xFFF97316)),
                                      const SizedBox(width: 10),
                                      const Expanded(
                                        child: Text(
                                          'Technician diagnosis completed! Review itemized repairs and photo evidence to approve.',
                                          style: TextStyle(fontSize: 12, color: Color(0xFFF97316), fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFF97316),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => LiveTrackerScreen(ticketId: ticket.id)),
                                          );
                                        },
                                        child: const Text('Review', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                                    color: AppColors.success.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_outline, color: AppColors.success),
                                      const SizedBox(width: 10),
                                      const Expanded(
                                        child: Text(
                                          'All repairs complete & quality tested! Your vehicle is ready for pickup.',
                                          style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.success,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => LiveTrackerScreen(ticketId: ticket.id)),
                                          );
                                        },
                                        child: const Text('View Bill', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.task_alt, size: 16, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${ticket.completedItemsCount}/${ticket.approvedItemsCount} tasks completed',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'Total: \$${ticket.totalEstimatedAmount.toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
                                      ),
                                      const SizedBox(width: 10),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1E3A5F),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        ),
                                        icon: const Icon(Icons.visibility, size: 14),
                                        label: const Text('Live Tracker', style: TextStyle(fontSize: 12)),
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
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'Click card to see mechanic findings & detail',
                                    style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward, size: 12, color: AppColors.primary),
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

  Widget _buildMetricTile(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
        title: const Row(
          children: [
            Icon(Icons.directions_car, color: Color(0xFF1E3A5F)),
            SizedBox(width: 8),
            Text('Register Customer Vehicle'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: plateCtrl, decoration: const InputDecoration(labelText: 'License Plate')),
              const SizedBox(height: 10),
              TextField(controller: makeCtrl, decoration: const InputDecoration(labelText: 'Make (e.g. Honda)')),
              const SizedBox(height: 10),
              TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: 'Model (e.g. CR-V)')),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: yearCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Year'))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: colorCtrl, decoration: const InputDecoration(labelText: 'Color'))),
                ],
              ),
              const SizedBox(height: 10),
              TextField(controller: vinCtrl, decoration: const InputDecoration(labelText: 'VIN Number (17 chars)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A5F)),
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
                    const SnackBar(
                      content: Text('Vehicle successfully registered to your account!'),
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
              }
            },
            child: const Text('Save Vehicle'),
          ),
        ],
      ),
    );
  }
}
