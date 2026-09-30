import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class MobileCustomerWebScreen extends StatefulWidget {
  const MobileCustomerWebScreen({super.key});

  @override
  State<MobileCustomerWebScreen> createState() => _MobileCustomerWebScreenState();
}

class _MobileCustomerWebScreenState extends State<MobileCustomerWebScreen> {
  // Decision state: item id -> null (undecided), true (approved), false (declined)
  final Map<int, bool?> _decisions = {
    1: null,
    2: null,
  };

  final Map<int, Map<String, dynamic>> _itemData = {
    1: {
      'name': 'Front Ceramic Brake Pads',
      'type': 'Part · Safety Critical',
      'price': 79.99,
      'desc': 'Brake pads are worn down to 2mm (safety limit is 3mm) and causing front vibration during deceleration.',
    },
    2: {
      'name': 'Brake Caliper Servicing & Labor',
      'type': 'Labor · 1.5 hrs',
      'price': 135.00,
      'desc': 'Disassembly, slide pin cleaning, synthetic caliper lubrication, and rotor runout check to ensure even brake wear.',
    },
  };

  int _selectedTabIndex = 0;
  static const double _baseService = 45.00;
  static const double _taxRate = 0.07;

  double get _subtotal {
    double sum = _baseService;
    _decisions.forEach((id, approved) {
      if (approved == true) {
        sum += (_itemData[id]!['price'] as double);
      }
    });
    return sum;
  }

  double get _tax => _subtotal * _taxRate;
  double get _total => _subtotal + _tax;

  int get _undecidedCount => _decisions.values.where((v) => v == null).length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor = AppColors.background; // #F1F3F6
    final Color surfaceColor = AppColors.surface; // #FFFFFF
    final Color textColor = AppColors.textPrimary; // #2E3A46
    final Color mutedColor = AppColors.textSecondary; // #8792A0
    final Color borderColor = AppColors.border; // #E1E5EA

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        top: false,
        bottom: true,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Stack(
              children: [
                // Scrollable Content Stream
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 90),
                  child: Column(
                    children: [
                      // 1. TOP BAR (Steel Blue Gradient with rounded bottom corners)
                      _buildTopBar(),

                      // 2. STATUS CARD (Floats over top bar with negative offset)
                      Transform.translate(
                        offset: const Offset(0, -28),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildStatusCard(surfaceColor, textColor, mutedColor, borderColor),
                        ),
                      ),

                      // Rest of Content Stream
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 3. ALERT BANNER
                            _buildAlertBanner(isDark),
                            const SizedBox(height: 16),

                            // 4. "WHAT WE FOUND" SECTION
                            _buildWhatWeFoundSection(surfaceColor, textColor, mutedColor, borderColor),
                            const SizedBox(height: 20),

                            // 5. "REPAIR PROGRESS" SECTION
                            _buildRepairProgressSection(surfaceColor, textColor, mutedColor, borderColor),
                            const SizedBox(height: 20),

                            // 6. "ESTIMATED INVOICE" CARD
                            _buildInvoiceCard(),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 7. FIXED BOTTOM NAVIGATION BAR
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildBottomNav(surfaceColor, mutedColor, borderColor, isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 1. TOP BAR
  Widget _buildTopBar() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5B7FA6), Color(0xFF4D6F94)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F2E3A46),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hi, Alex',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              InkWell(
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
                    child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 15),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // White pill monospace plate chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E3A46).withValues(alpha: 0.15),
                      blurRadius: 6,
                    )
                  ],
                ),
                child: const Text(
                  'ABC-1234',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.primary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '2022 Toyota Camry XSE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.access_time, size: 13, color: Colors.white70),
              SizedBox(width: 5),
              Text(
                'Checked in Today · 8:30 AM · Odometer 42,150 km',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. STATUS CARD
  Widget _buildStatusCard(Color surface, Color text, Color muted, Color border) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TICKET #TK-2026-0001',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: muted,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.charcoal),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 3,
                      backgroundColor: AppColors.charcoal,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Awaiting your approval',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // 5-step horizontal track
          _buildProgressTrack(muted, text),
        ],
      ),
    );
  }

  Widget _buildProgressTrack(Color muted, Color text) {
    final steps = [
      {'name': 'In', 'state': 'completed'},
      {'name': 'Inspect', 'state': 'completed'},
      {'name': 'Approve', 'state': 'active'},
      {'name': 'Repair', 'state': 'future'},
      {'name': 'Pickup', 'state': 'future'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isCompleted = step['state'] == 'completed';
        final isActive = step['state'] == 'active';

        return Column(
          children: [
            Container(
              width: isActive ? 26 : 20,
              height: isActive ? 26 : 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isCompleted || isActive)
                    ? AppColors.primary
                    : Colors.transparent,
                border: Border.all(
                  color: (isCompleted || isActive)
                      ? AppColors.primary
                      : AppColors.border,
                  width: isActive ? 2.5 : 1.5,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              step['name']!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? text : muted,
              ),
            ),
          ],
        );
      }),
    );
  }

  // 3. ALERT BANNER
  Widget _buildAlertBanner(bool isDark) {
    final count = _undecidedCount;
    final isDone = count == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDone ? AppColors.primary : AppColors.charcoal,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                isDone ? '✓' : '!',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDone
                      ? 'All recommendations decided!'
                      : '$count item${count > 1 ? 's' : ''} need your decision.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDone ? AppColors.primary : AppColors.charcoal,
                  ),
                ),
                Text(
                  isDone
                      ? 'Technicians authorized to commence repairs.'
                      : 'Technicians are paused until you review recommendations below.',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. "WHAT WE FOUND" SECTION
  Widget _buildWhatWeFoundSection(Color surface, Color text, Color muted, Color border) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'What we found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: text),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_undecidedCount pending',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Item 1
        _buildFindingCard(1, surface, text, muted, border),
        const SizedBox(height: 12),

        // Item 2
        _buildFindingCard(2, surface, text, muted, border),
      ],
    );
  }

  Widget _buildFindingCard(int id, Color surface, Color text, Color muted, Color border) {
    final item = _itemData[id]!;
    final decision = _decisions[id];
    final isDecided = decision != null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: isDecided ? 0.82 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] as String,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: text),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['type'] as String,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: muted),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${(item['price'] as double).toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: text),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item['desc'] as String,
              style: TextStyle(fontSize: 13, color: muted, height: 1.4),
            ),
            const SizedBox(height: 14),

            // Buttons or Decision Pill
            if (!isDecided)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () {
                        setState(() => _decisions[id] = true);
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, size: 16),
                          SizedBox(width: 4),
                          Text('Approve', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: border, width: 1.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () {
                        setState(() => _decisions[id] = false);
                      },
                      child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: decision == true
                          ? AppColors.surfaceWarm
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: decision == true
                            ? AppColors.primary.withValues(alpha: 0.4)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          decision == true ? '✓ You approved this' : '✕ You declined this',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: decision == true ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _decisions[id] = null);
                    },
                    child: Text('Change', style: TextStyle(fontSize: 11, color: muted)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // 5. "REPAIR PROGRESS" SECTION
  Widget _buildRepairProgressSection(Color surface, Color text, Color muted, Color border) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Repair progress',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: text),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              _buildProgressRow(
                title: 'Full Synthetic Oil & Filter Service',
                subtext: 'Completed · 10:40 AM',
                isCompleted: true,
                text: text,
                muted: muted,
              ),
              const Divider(height: 1),
              _buildProgressRow(
                title: 'Front Ceramic Brake Pads',
                subtext: _decisions[1] == true
                    ? 'Approved · Scheduled with Lead Tech'
                    : _decisions[1] == false
                        ? 'Declined by customer'
                        : 'Waiting on your approval',
                isCompleted: _decisions[1] == true,
                isDeclined: _decisions[1] == false,
                text: text,
                muted: muted,
              ),
              const Divider(height: 1),
              _buildProgressRow(
                title: 'Brake Caliper Servicing & Labor',
                subtext: _decisions[2] == true
                    ? 'Approved · Scheduled with Lead Tech'
                    : _decisions[2] == false
                        ? 'Declined by customer'
                        : 'Waiting on your approval',
                isCompleted: _decisions[2] == true,
                isDeclined: _decisions[2] == false,
                text: text,
                muted: muted,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressRow({
    required String title,
    required String subtext,
    bool isCompleted = false,
    bool isDeclined = false,
    required Color text,
    required Color muted,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? AppColors.surfaceWarm
                  : isDeclined
                      ? AppColors.background
                      : AppColors.background,
              border: Border.all(
                color: isCompleted
                    ? AppColors.primary
                    : isDeclined
                        ? AppColors.border
                        : AppColors.border,
              ),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 13, color: AppColors.primary)
                  : isDeclined
                      ? const Icon(Icons.close, size: 12, color: AppColors.textSecondary)
                      : const CircleAvatar(radius: 3, backgroundColor: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: text)),
                const SizedBox(height: 2),
                Text(subtext, style: TextStyle(fontSize: 11, color: muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 6. ESTIMATED INVOICE CARD
  Widget _buildInvoiceCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.invoiceBg, // #2E3A46 deep blue-charcoal
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.invoiceBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E3A46).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estimated invoice',
                style: TextStyle(
                  color: AppColors.invoiceText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF3D4C5A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Real-time estimate',
                  style: TextStyle(color: Color(0xFF8792A0), fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pre-authorized line
          _buildInvoiceLine('Synthetic Oil & Filter (Pre-authorized)', '\$45.00'),

          // Dynamic approved items
          if (_decisions[1] == true)
            _buildInvoiceLine('Front Ceramic Brake Pads', '\$79.99'),
          if (_decisions[2] == true)
            _buildInvoiceLine('Brake Caliper Servicing & Labor', '\$135.00'),

          const SizedBox(height: 6),
          _buildInvoiceLine('Estimated Sales Tax (7.0%)', '\$${_tax.toStringAsFixed(2)}', isMuted: true),

          const Divider(color: Color(0xFF3D4C5A), height: 24),

          // Total row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Balance',
                style: TextStyle(color: AppColors.invoiceText, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                '\$${_total.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppColors.invoiceText,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Full-width periwinkle pay button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, // #5B7FA6 soft periwinkle
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              icon: const Text('View & pay when ready', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              label: const Icon(Icons.arrow_forward, size: 16),
              onPressed: () {
                _showPaymentDialog();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceLine(String label, String amount, {bool isMuted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isMuted ? AppColors.invoiceMuted : AppColors.invoiceText.withValues(alpha: 0.9),
              fontSize: isMuted ? 12 : 13,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: isMuted ? AppColors.invoiceMuted : AppColors.invoiceText,
              fontSize: isMuted ? 12 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // 7. FIXED BOTTOM NAVIGATION BAR
  Widget _buildBottomNav(Color surface, Color muted, Color border, bool isDark) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavTab(0, Icons.receipt_long, 'Tickets', isDark),
          _buildNavTab(1, Icons.directions_car_outlined, 'Vehicles', isDark),
          _buildNavTab(2, Icons.notifications_none, 'Updates', isDark),
          _buildNavTab(3, Icons.person_outline, 'Account', isDark),
        ],
      ),
    );
  }

  Widget _buildNavTab(int index, IconData icon, String label, bool isDark) {
    final isActive = _selectedTabIndex == index;
    final activeColor = AppColors.primary; // Soft periwinkle blue #5B7FA6

    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: isActive ? activeColor : AppColors.textSecondary),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? activeColor : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Checkout & Payment Pre-Authorization',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Total approved balance will be collected upon vehicle completion and pickup.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Current Approved Balance:'),
                Text(
                  '\$${_total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment pre-authorized! We will notify you once repairs finish.'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                child: const Text('Confirm Pre-Authorization', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
