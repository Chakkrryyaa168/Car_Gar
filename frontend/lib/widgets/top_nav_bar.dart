import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_animations.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';

/// Role metadata container for top app bar titles and subtitles
class RoleBarMeta {
  final String title;
  final String subtitle;
  final String roleBadge;

  const RoleBarMeta({
    required this.title,
    required this.subtitle,
    required this.roleBadge,
  });
}

RoleBarMeta getRoleBarMeta(String? role) {
  switch (role?.toUpperCase()) {
    case 'RECEPTIONIST':
      return const RoleBarMeta(
        title: 'Receptionist Desk & Cashier',
        subtitle: 'Tickets, invoices and payments',
        roleBadge: 'Receptionist & Cashier',
      );
    case 'MECHANIC':
      return const RoleBarMeta(
        title: 'Workshop Station',
        subtitle: 'Work orders, diagnostics and repairs',
        roleBadge: 'Workshop Mechanic',
      );
    case 'ADMIN':
      return const RoleBarMeta(
        title: 'Admin Dashboard',
        subtitle: 'Staff management, analytics and audit logs',
        roleBadge: 'Garage Administrator',
      );
    case 'CUSTOMER':
    default:
      return const RoleBarMeta(
        title: 'Customer Garage Portal',
        subtitle: 'Live tracking, quotes and vehicles',
        roleBadge: 'Vehicle Owner',
      );
  }
}

/// A unified, sticky, responsive Top App Bar for all user roles.
/// Features a sage gradient background (#5F7F6B -> #4E6B59), rounded bottom corners (22px),
/// 38px interactive buttons, unread notifications indicator, profile pill chip with initials
/// and expanding name on >= 640px screens, rotating chevron, and a 236px dropdown menu.
class TopNavBar extends StatefulWidget {
  final Future<void> Function()? onRefresh;

  const TopNavBar({super.key, this.onRefresh});

  @override
  State<TopNavBar> createState() => _TopNavBarState();
}

class _TopNavBarState extends State<TopNavBar> with SingleTickerProviderStateMixin {
  final GlobalKey _profileChipKey = GlobalKey();
  OverlayEntry? _dropdownOverlay;
  late AnimationController _menuAnimController;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _menuAnimController = AnimationController(
      vsync: this,
      duration: AppAnimations.durBase,
    );
  }

  @override
  void dispose() {
    _removeDropdown(immediate: true);
    _menuAnimController.dispose();
    super.dispose();
  }

  void _toggleMenu(BuildContext context, AuthProvider auth, RoleBarMeta meta) {
    if (_isMenuOpen) {
      _closeMenu();
    } else {
      _openMenu(context, auth, meta);
    }
  }

  void _openMenu(BuildContext context, AuthProvider auth, RoleBarMeta meta) {
    final renderBox = _profileChipKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _dropdownOverlay = _createOverlayEntry(context, offset, size, auth, meta);
    Overlay.of(context).insert(_dropdownOverlay!);

    setState(() => _isMenuOpen = true);
    final reduced = AppAnimations.isReducedMotion(context);
    if (reduced) {
      _menuAnimController.value = 1.0;
    } else {
      _menuAnimController.forward(from: 0.0);
    }
  }

  void _closeMenu() {
    if (!_isMenuOpen) return;
    setState(() => _isMenuOpen = false);

    final reduced = AppAnimations.isReducedMotion(context);
    if (reduced) {
      _removeDropdown(immediate: true);
    } else {
      _menuAnimController.reverse().then((_) {
        _removeDropdown(immediate: true);
      });
    }
  }

  void _removeDropdown({bool immediate = false}) {
    _dropdownOverlay?.remove();
    _dropdownOverlay = null;
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  OverlayEntry _createOverlayEntry(
    BuildContext context,
    Offset chipOffset,
    Size chipSize,
    AuthProvider auth,
    RoleBarMeta meta,
  ) {
    final screenSize = MediaQuery.of(context).size;
    final rightPadding = (screenSize.width - (chipOffset.dx + chipSize.width)).clamp(12.0, screenSize.width);
    final topOffset = chipOffset.dy + chipSize.height + 6.0;

    return OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            // Barrier: full screen tap outside to dismiss
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _closeMenu,
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
            // Floating 236px dropdown menu
            Positioned(
              top: topOffset,
              right: rightPadding,
              child: AnimatedBuilder(
                animation: _menuAnimController,
                builder: (context, child) {
                  final val = _menuAnimController.value;
                  final reduced = AppAnimations.isReducedMotion(context);
                  return Opacity(
                    opacity: reduced ? 1.0 : val.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, reduced ? 0.0 : 6.0 * (val - 1.0)),
                      child: Transform.scale(
                        scale: reduced ? 1.0 : (0.98 + 0.02 * val),
                        alignment: Alignment.topRight,
                        child: child,
                      ),
                    ),
                  );
                },
                child: _buildDropdownCard(context, auth, meta),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDropdownCard(BuildContext context, AuthProvider auth, RoleBarMeta meta) {
    final user = auth.currentUser;
    final displayName = user?.fullName ?? user?.username ?? 'Logged In User';
    final initials = _getInitials(displayName);
    final avatarUrl = user?.profile?.avatarUrl;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 236, // Exactly 236px wide per requirement
        decoration: BoxDecoration(
          color: AppColors.surface, // #FFFFFF
          borderRadius: BorderRadius.circular(16), // 16px radius
          border: Border.all(color: AppColors.border), // #E4DED0
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2B2F2C).withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with larger avatar, full name and full role
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.background, // Warm sand #F5F1E8
                    backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: (avatarUrl == null || avatarUrl.isEmpty)
                        ? Text(
                            initials,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary, // Sage green #5F7F6B
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary, // Charcoal #2B2F2C
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          meta.roleBadge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary, // Muted text #7C837E
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.border),

            // Dropdown menu items
            _buildDropdownItem(
              icon: Icons.person_outline_rounded,
              label: 'My profile',
              onTap: () {
                _closeMenu();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            _buildDropdownItem(
              icon: Icons.tune_rounded,
              label: 'Settings',
              onTap: () {
                _closeMenu();
                _showSettingsDialog(context, auth, meta);
              },
            ),
            _buildDropdownItem(
              icon: Icons.auto_stories_outlined,
              label: 'App walkthrough',
              onTap: () {
                _closeMenu();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                );
              },
            ),
            const Divider(height: 1, color: AppColors.border),
            _buildDropdownItem(
              icon: Icons.logout_rounded,
              label: 'Sign out',
              isBoldSage: true,
              onTap: () {
                _closeMenu();
                _confirmSignOut(context, auth);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isBoldSage = false,
  }) {
    return _DropdownItemRow(
      icon: icon,
      label: label,
      isBoldSage: isBoldSage,
      onTap: onTap,
    );
  }

  void _showSettingsDialog(BuildContext context, AuthProvider auth, RoleBarMeta meta) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.tune_rounded, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Text(
              'Portal Settings',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingRow('Current Role', meta.roleBadge),
            const SizedBox(height: 10),
            _buildSettingRow('Palette Theme', 'Earthy Sage & Sand (#5F7F6B)'),
            const SizedBox(height: 10),
            _buildSettingRow('Motion Easing', 'Soft Ease-Out (cubic-bezier)'),
            const SizedBox(height: 10),
            _buildSettingRow('Portal Version', 'Car Garage v2.4 (Live Web)'),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Close', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  void _showNotificationsSheet(BuildContext context, TicketProvider ticketProvider) {
    final tickets = ticketProvider.tickets;
    final pendingCount = tickets.where((t) => t.isPendingApproval).length;
    final readyCount = tickets.where((t) => t.isReadyForPickup).length;
    final inProgressCount = tickets.where((t) => t.isInProgress).length;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active_outlined, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Garage Activity & Alerts',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(sheetCtx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (pendingCount > 0)
                _buildAlertTile(
                  icon: Icons.pending_actions_rounded,
                  title: '$pendingCount Ticket${pendingCount > 1 ? 's' : ''} Pending Customer Approval',
                  subtitle: 'Action needed before mechanics can proceed with repairs.',
                  isUrgent: true,
                ),
              if (readyCount > 0)
                _buildAlertTile(
                  icon: Icons.check_circle_outline_rounded,
                  title: '$readyCount Vehicle${readyCount > 1 ? 's' : ''} Ready for Pickup',
                  subtitle: 'Work complete. Customer notified for vehicle collection.',
                  isUrgent: false,
                ),
              if (inProgressCount > 0)
                _buildAlertTile(
                  icon: Icons.build_circle_outlined,
                  title: '$inProgressCount Active Repair${inProgressCount > 1 ? 's' : ''} in Progress',
                  subtitle: 'Technicians currently servicing vehicles in workshop bays.',
                  isUrgent: false,
                ),
              if (pendingCount == 0 && readyCount == 0 && inProgressCount == 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'All clear — No active alerts or urgent approvals needed.',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isUrgent,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface, // #FFFFFF
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Row(
          children: [
            const Icon(Icons.logout, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Sign Out',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out of the Car Garage Management System?',
          style: GoogleFonts.inter(
            color: AppColors.textBody,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              auth.logout();
            },
            child: Text(
              'Sign Out',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final ticketProvider = Provider.of<TicketProvider>(context);
    final user = auth.currentUser;
    final meta = getRoleBarMeta(auth.currentRole);

    final hasUnreadAlerts = ticketProvider.tickets.any((t) => t.isPendingApproval || t.isReadyForPickup);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 640;

    final displayName = user?.fullName ?? user?.username ?? 'Logged In User';
    final initials = _getInitials(displayName);
    final avatarUrl = user?.profile?.avatarUrl;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF5F7F6B), // Sage green #5F7F6B
            Color(0xFF4E6B59), // Subtle deeper sage #4E6B59
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)), // 22px bottom corners
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B2F2C).withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ==========================================
              // TOP ROW: Brand (Left) + Bell & Profile Chip (Right)
              // (Positioned on top of the Refresh button)
              // ==========================================
              Row(
                children: [
                  // Left: 38px Rounded-square tile + CAR GARAGE Brand Text
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.20),
                              width: 1.0,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.directions_car_filled,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'CAR GARAGE',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              Text(
                                'Management Portal',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Right: Notifications Bell (38px) + Profile Chip (Pill) - on top of Refresh Button
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Notifications Bell button
                      TopBarIconButton(
                        tooltip: 'Notifications & Alerts',
                        semanticsLabel: 'Notifications, ${hasUnreadAlerts ? "unread alerts available" : "no unread alerts"}',
                        hasBadge: hasUnreadAlerts,
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                        onTap: () => _showNotificationsSheet(context, ticketProvider),
                      ),
                      const SizedBox(width: 8),

                      // Profile Chip
                      _ProfileChip(
                        key: _profileChipKey,
                        initials: initials,
                        avatarUrl: avatarUrl,
                        fullName: displayName,
                        isWide: isWide,
                        isMenuOpen: _isMenuOpen,
                        onTap: () => _toggleMenu(context, auth, meta),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ==========================================
              // SECOND ROW: Page Title & Subtitle + Refresh Button
              // ==========================================
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            meta.title,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 21, // 20-22px bold
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          meta.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.76),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Refresh icon button with full 360-degree rotation animation on tap (right-aligned beneath profile chip)
                  TopBarRefreshButton(
                    onRefresh: () async {
                      if (widget.onRefresh != null) {
                        await widget.onRefresh!();
                      } else {
                        final authP = Provider.of<AuthProvider>(context, listen: false);
                        final ticketP = Provider.of<TicketProvider>(context, listen: false);
                        final invP = Provider.of<InventoryProvider>(context, listen: false);

                        if (authP.currentRole == 'ADMIN') {
                          await Future.wait([
                            ticketP.fetchTickets(),
                            invP.fetchInventory(),
                          ]);
                        } else {
                          await ticketP.fetchTickets();
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Profile Chip widget with hover brightening, press scale, initials avatar,
/// expanding full name on >= 640px, and rotating chevron.
class _ProfileChip extends StatefulWidget {
  final String initials;
  final String? avatarUrl;
  final String fullName;
  final bool isWide;
  final bool isMenuOpen;
  final VoidCallback onTap;

  const _ProfileChip({
    super.key,
    required this.initials,
    this.avatarUrl,
    required this.fullName,
    required this.isWide,
    required this.isMenuOpen,
    required this.onTap,
  });

  @override
  State<_ProfileChip> createState() => _ProfileChipState();
}

class _ProfileChipState extends State<_ProfileChip> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final reduced = AppAnimations.isReducedMotion(context);
    final scale = (_isPressed && !reduced) ? 0.95 : 1.0;

    return Semantics(
      label: 'User profile menu for ${widget.fullName}',
      button: true,
      expanded: widget.isMenuOpen,
      child: Tooltip(
        message: 'Account & Settings',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: scale,
              duration: reduced ? Duration.zero : AppAnimations.durFast,
              curve: AppAnimations.ease,
              child: AnimatedContainer(
                duration: reduced ? Duration.zero : AppAnimations.durFast,
                curve: AppAnimations.ease,
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: _isHovered
                      ? Colors.white.withValues(alpha: 0.22)
                      : Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20), // Pill-shaped
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Circular avatar with initials: sand background, sage text
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: AppColors.background, // Warm sand #F5F1E8
                      backgroundImage: (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty)
                          ? NetworkImage(widget.avatarUrl!)
                          : null,
                      child: (widget.avatarUrl == null || widget.avatarUrl!.isEmpty)
                          ? Text(
                              widget.initials,
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary, // Sage green #5F7F6B
                              ),
                            )
                          : null,
                    ),

                    // On screens 640px and wider, also show the first and last name.
                    // Never truncate text inside the chip.
                    if (widget.isWide) ...[
                      const SizedBox(width: 7),
                      Text(
                        widget.fullName,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],

                    const SizedBox(width: 4),

                    // Small chevron that rotates when open
                    AnimatedRotation(
                      turns: widget.isMenuOpen ? 0.5 : 0.0,
                      duration: reduced ? Duration.zero : AppAnimations.durFast,
                      curve: AppAnimations.ease,
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 17,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 38px Top Bar Icon Button with hover brightening, press scale, and accessibility
class TopBarIconButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback onTap;
  final String tooltip;
  final String semanticsLabel;
  final bool hasBadge;
  final double size;

  const TopBarIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    required this.semanticsLabel,
    this.hasBadge = false,
    this.size = 38.0,
  });

  @override
  State<TopBarIconButton> createState() => _TopBarIconButtonState();
}

class _TopBarIconButtonState extends State<TopBarIconButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final reduced = AppAnimations.isReducedMotion(context);
    final scale = (_isPressed && !reduced) ? 0.95 : 1.0;

    return Semantics(
      label: widget.semanticsLabel,
      button: true,
      child: Tooltip(
        message: widget.tooltip,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: scale,
              duration: reduced ? Duration.zero : AppAnimations.durFast,
              curve: AppAnimations.ease,
              child: AnimatedContainer(
                duration: reduced ? Duration.zero : AppAnimations.durFast,
                curve: AppAnimations.ease,
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: _isHovered
                      ? Colors.white.withValues(alpha: 0.22)
                      : Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20),
                    width: 1.0,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    widget.icon,
                    if (widget.hasBadge)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Refresh button performing a full 360-degree rotation on tap
class TopBarRefreshButton extends StatefulWidget {
  final Future<void> Function() onRefresh;

  const TopBarRefreshButton({super.key, required this.onRefresh});

  @override
  State<TopBarRefreshButton> createState() => _TopBarRefreshButtonState();
}

class _TopBarRefreshButtonState extends State<TopBarRefreshButton> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    final reduced = AppAnimations.isReducedMotion(context);
    if (!reduced) {
      _animController.forward(from: 0.0);
    }
    setState(() => _isRefreshing = true);
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppAnimations.isReducedMotion(context);
    final scale = (_isPressed && !reduced) ? 0.95 : 1.0;

    return Semantics(
      label: 'Refresh portal data',
      button: true,
      child: Tooltip(
        message: 'Refresh data',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: _isRefreshing ? null : _handleTap,
            child: AnimatedScale(
              scale: scale,
              duration: reduced ? Duration.zero : AppAnimations.durFast,
              curve: AppAnimations.ease,
              child: AnimatedContainer(
                duration: reduced ? Duration.zero : AppAnimations.durFast,
                curve: AppAnimations.ease,
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _isHovered
                      ? Colors.white.withValues(alpha: 0.22)
                      : Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20),
                    width: 1.0,
                  ),
                ),
                child: Center(
                  child: RotationTransition(
                    turns: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(parent: _animController, curve: AppAnimations.ease),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownItemRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isBoldSage;
  final VoidCallback onTap;

  const _DropdownItemRow({
    required this.icon,
    required this.label,
    required this.isBoldSage,
    required this.onTap,
  });

  @override
  State<_DropdownItemRow> createState() => _DropdownItemRowState();
}

class _DropdownItemRowState extends State<_DropdownItemRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          color: _isHovered ? AppColors.surfaceElevated : Colors.transparent,
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.isBoldSage ? AppColors.primary : AppColors.textPrimary,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: widget.isBoldSage ? FontWeight.w700 : FontWeight.w500,
                  color: widget.isBoldSage ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
