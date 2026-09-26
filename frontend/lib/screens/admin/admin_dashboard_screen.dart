import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../providers/ticket_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_badge.dart';
import 'inventory_management_screen.dart';
import '../customer/live_tracker_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _stats = {};
  List<UserModel> _staffList = [];
  List<Map<String, dynamic>> _auditLogs = [];
  bool _isLoadingStaff = false;
  bool _isLoadingAudit = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    final invProvider = Provider.of<InventoryProvider>(context, listen: false);

    await Future.wait([
      ticketProvider.fetchTickets(),
      invProvider.fetchInventory(),
    ]);

    _loadStats();
    _loadStaff();
    _loadAuditLogs();
  }

  Future<void> _loadStats() async {
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    try {
      final s = await ticketProvider.apiService.fetchDashboardStats();
      if (mounted) setState(() => _stats = s);
    } catch (_) {}
  }

  Future<void> _loadStaff() async {
    setState(() => _isLoadingStaff = true);
    final api = Provider.of<TicketProvider>(context, listen: false).apiService;
    try {
      final staff = await api.fetchStaffUsers();
      if (mounted) setState(() => _staffList = staff);
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoadingStaff = false);
    }
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _isLoadingAudit = true);
    final api = Provider.of<TicketProvider>(context, listen: false).apiService;
    try {
      final logs = await api.fetchAuditLogs();
      if (mounted) setState(() => _auditLogs = logs);
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoadingAudit = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Operations & Financial Console'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.accent,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Business Analytics'),
            Tab(icon: Icon(Icons.people_alt_outlined), text: 'Staff & Roles'),
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Warehouse Parts'),
            Tab(icon: Icon(Icons.history_outlined), text: 'Audit & Accountability'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Console',
            onPressed: _loadAllData,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAnalyticsTab(),
          _buildStaffTab(),
          _buildInventoryTab(),
          _buildAuditTab(),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: BUSINESS ANALYTICS & REPORTING
  // -------------------------------------------------------------
  Widget _buildAnalyticsTab() {
    final ticketProvider = Provider.of<TicketProvider>(context);
    final tickets = ticketProvider.tickets;

    final totalRevenue = (_stats['total_revenue'] ?? 0.0) as num;
    final outstandingInvoices = (_stats['outstanding_invoices'] ?? 0.0) as num;
    final partsMargin = (_stats['parts_margin_percent'] ?? 32.8) as num;
    final lowStockCount = (_stats['low_stock_alerts'] ?? 0) as num;
    final productivity = (_stats['mechanic_productivity'] as List?) ?? [];

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Grid
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    'Gross Revenue',
                    '\$${totalRevenue.toStringAsFixed(2)}',
                    Icons.monetization_on_outlined,
                    AppColors.success,
                    subtitle: 'Collected to date',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    'Outstanding Invoices',
                    '\$${outstandingInvoices.toStringAsFixed(2)}',
                    Icons.receipt_long_outlined,
                    outstandingInvoices > 0 ? AppColors.accent : AppColors.success,
                    subtitle: 'Uncollected balances',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    'Parts Margin',
                    '${partsMargin.toStringAsFixed(1)}%',
                    Icons.trending_up,
                    AppColors.primary,
                    subtitle: 'Avg markup on inventory',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    'Active Tickets',
                    '${tickets.length}',
                    Icons.speed,
                    AppColors.statusApprovedInProgress,
                    subtitle: '$lowStockCount low stock alerts',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Mechanic Productivity Section
            const Text(
              'MECHANIC PRODUCTIVITY & WORKLOAD',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            if (productivity.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFF97316),
                        child: Icon(Icons.build, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Lead Mechanic: Mike Miller', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Assigned Tickets: Active on repair floor • High completion rate', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('100% On-Time', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: productivity.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final m = productivity[idx];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFF97316),
                        child: Icon(Icons.build, color: Colors.white, size: 18),
                      ),
                      title: Text(m['name'] ?? 'Mechanic', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        'Assigned: ${m['assigned_tickets']} orders | Completed: ${m['completed_tickets']} repairs',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${m['completed_tickets']} Done',
                          style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 24),

            // Live Tickets Overview
            const Text(
              'LIVE GARAGE REPAIR ORDERS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tickets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                return Card(
                  child: ListTile(
                    title: Row(
                      children: [
                        Text(ticket.ticketNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 8),
                        StatusBadge(status: ticket.currentStatus, fontSize: 11),
                      ],
                    ),
                    subtitle: Text(
                      '${ticket.vehicleInfo} • Customer: ${ticket.customerName ?? 'Customer'}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '\$${ticket.totalEstimatedAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 14),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => LiveTrackerScreen(ticketId: ticket.id)),
                            );
                          },
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
    );
  }

  // -------------------------------------------------------------
  // TAB 2: STAFF & ROLE ADMINISTRATION
  // -------------------------------------------------------------
  Widget _buildStaffTab() {
    return RefreshIndicator(
      onRefresh: _loadStaff,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Staff Header Banner
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(0xFF6366F1),
                      child: Icon(Icons.badge, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Staff & Permissions Administration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('Create staff accounts, assign roles, and activate or deactivate system access.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Add Staff'),
                      onPressed: _showAddStaffDialog,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_isLoadingStaff)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (_staffList.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No staff members found.')))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _staffList.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final staff = _staffList[index];
                  final isActive = staff.isActive;

                  Color roleBadgeColor;
                  switch (staff.role) {
                    case 'ADMIN':
                      roleBadgeColor = const Color(0xFF6366F1);
                      break;
                    case 'RECEPTIONIST':
                      roleBadgeColor = const Color(0xFF3B82F6);
                      break;
                    case 'MECHANIC':
                    default:
                      roleBadgeColor = const Color(0xFFF97316);
                      break;
                  }

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: roleBadgeColor.withValues(alpha: 0.15),
                            child: Icon(
                              staff.role == 'MECHANIC'
                                  ? Icons.build
                                  : staff.role == 'RECEPTIONIST'
                                      ? Icons.desk
                                      : Icons.admin_panel_settings,
                              color: roleBadgeColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      staff.fullName.isNotEmpty ? staff.fullName : staff.username,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: roleBadgeColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        staff.role,
                                        style: TextStyle(
                                          color: roleBadgeColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${staff.email} • Phone: ${staff.phoneNumber.isNotEmpty ? staff.phoneNumber : 'N/A'}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isActive ? AppColors.success : AppColors.danger,
                                    ),
                                  ),
                                  Switch(
                                    value: isActive,
                                    activeThumbColor: AppColors.success,
                                    onChanged: (val) async {
                                      final api = Provider.of<TicketProvider>(context, listen: false).apiService;
                                      await api.toggleStaffActive(staff.id);
                                      _loadStaff();
                                    },
                                  ),
                                ],
                              ),
                            ],
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
    );
  }

  // -------------------------------------------------------------
  // TAB 3: WAREHOUSE & INVENTORY MANAGEMENT
  // -------------------------------------------------------------
  Widget _buildInventoryTab() {
    final invProvider = Provider.of<InventoryProvider>(context);
    final items = invProvider.items;
    final lowStock = invProvider.lowStockItems;

    return RefreshIndicator(
      onRefresh: () => invProvider.fetchInventory(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.warehouse, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Warehouse Parts & Thresholds', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('${items.length} SKUs tracked • ${lowStock.length} below reorder threshold', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Full Inventory Console'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const InventoryManagementScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (lowStock.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Attention: ${lowStock.length} parts have fallen below their safety reorder threshold! Reorder stock to prevent workshop delays.',
                        style: const TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                final isLow = item.isLowStock;

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isLow ? AppColors.danger.withValues(alpha: 0.12) : AppColors.primary.withValues(alpha: 0.1),
                      child: Icon(Icons.settings, color: isLow ? AppColors.danger : AppColors.primary, size: 20),
                    ),
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'SKU: ${item.sku} • Cost: \$${item.costPrice.toStringAsFixed(2)} • Sell: \$${item.sellingPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item.quantityOnHand} in stock',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isLow ? AppColors.danger : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Min: ${item.reorderLevel}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
    );
  }

  // -------------------------------------------------------------
  // TAB 4: AUDIT TRAIL & ACCOUNTABILITY
  // -------------------------------------------------------------
  Widget _buildAuditTab() {
    return RefreshIndicator(
      onRefresh: _loadAuditLogs,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: const [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(0xFF1E3A5F),
                      child: Icon(Icons.manage_search, color: Colors.white),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Service Ticket Audit Trail', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('Immutable log of status changes, actor accountability, timestamps & delay reasons.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_isLoadingAudit)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (_auditLogs.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No audit logs recorded yet.')))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _auditLogs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final log = _auditLogs[index];
                  final timestamp = log['created_at'] != null
                      ? DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(log['created_at']))
                      : 'Just now';

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.history, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    log['changed_by_name'] ?? 'System / Staff',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              Text(timestamp, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            children: [
                              StatusBadge(status: log['old_status'] ?? 'NONE', fontSize: 10),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Icon(Icons.arrow_forward, size: 14, color: AppColors.textSecondary),
                              ),
                              StatusBadge(status: log['new_status'] ?? 'UNKNOWN', fontSize: 10),
                            ],
                          ),
                          if (log['remarks'] != null && (log['remarks'] as String).isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Remarks: "${log['remarks']}"',
                              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textPrimary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }

  void _showAddStaffDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: 'staff123');
    String selectedRole = 'MECHANIC';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => AlertDialog(
          title: const Text('Add Garage Staff Member'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
                const SizedBox(height: 10),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address')),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: selectedRole,
                  decoration: const InputDecoration(labelText: 'Staff Role'),
                  items: const [
                    DropdownMenuItem(value: 'MECHANIC', child: Text('Mechanic (Workshop Bay)')),
                    DropdownMenuItem(value: 'RECEPTIONIST', child: Text('Receptionist (Front Desk)')),
                    DropdownMenuItem(value: 'ADMIN', child: Text('Admin (Owner / Manager)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedRole = val);
                  },
                ),
                const SizedBox(height: 10),
                TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Temporary Password')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              onPressed: () async {
                final api = Provider.of<TicketProvider>(context, listen: false).apiService;
                try {
                  await api.createStaffUser(
                    email: emailCtrl.text.trim(),
                    fullName: nameCtrl.text.trim(),
                    role: selectedRole,
                    phoneNumber: phoneCtrl.text.trim(),
                    password: passCtrl.text.trim(),
                  );
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  _loadStaff();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Staff member created successfully!'), backgroundColor: AppColors.success),
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
              child: const Text('Save Staff'),
            ),
          ],
        ),
      ),
    );
  }
}
