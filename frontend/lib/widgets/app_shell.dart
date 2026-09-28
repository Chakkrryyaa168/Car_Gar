import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../screens/customer/customer_dashboard_screen.dart';
import '../screens/receptionist/receptionist_screen.dart';
import '../screens/mechanic/mechanic_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/profile/profile_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // If not authenticated, show Login & Registration screen directly
    if (!auth.isAuthenticated) {
      return const AuthScreen();
    }

    Widget currentPortal;
    switch (auth.currentRole) {
      case 'ADMIN':
        currentPortal = const AdminDashboardScreen();
        break;
      case 'RECEPTIONIST':
        currentPortal = const ReceptionistScreen();
        break;
      case 'MECHANIC':
        currentPortal = const MechanicScreen();
        break;
      case 'CUSTOMER':
      default:
        currentPortal = const CustomerDashboardScreen();
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Authenticated User Top Navigation Bar (Grounded Navy)
          _buildAuthenticatedHeader(context, auth),
          // Active Role Portal Screen (Soft, Airy Mediterranean Cream)
          Expanded(child: currentPortal),
        ],
      ),
    );
  }

  Widget _buildAuthenticatedHeader(BuildContext context, AuthProvider auth) {
    final user = auth.currentUser;
    final role = auth.currentRole;

    IconData roleIcon;
    String roleLabel;

    switch (role) {
      case 'ADMIN':
        roleIcon = Icons.admin_panel_settings_outlined;
        roleLabel = 'ADMINISTRATOR';
        break;
      case 'RECEPTIONIST':
        roleIcon = Icons.desk_outlined;
        roleLabel = 'RECEPTION & CASHIER';
        break;
      case 'MECHANIC':
        roleIcon = Icons.build_outlined;
        roleLabel = 'WORKSHOP MECHANIC';
        break;
      case 'CUSTOMER':
      default:
        roleIcon = Icons.person_outline;
        roleLabel = 'VEHICLE OWNER';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.topBarBackground, // #1A1D29 Grounded Navy
        border: Border(bottom: BorderSide(color: AppColors.topBarBorder, width: 1.0)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Garage Brand Emblem
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.topBarSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.topBarBorder),
              ),
              child: const Icon(Icons.directions_car_filled, color: AppColors.topBarText, size: 18),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CAR GARAGE',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.topBarText, // Cream #F9EBEA
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  'Management Portal',
                  style: GoogleFonts.inter(
                    color: AppColors.topBarMuted, // Silver #B1B2B5
                    fontSize: 9,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Spacer(),

            // User Info & Role Chip (Clickable to open profile)
            Flexible(
              child: Tooltip(
                message: 'View & Edit Profile',
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.topBarSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.topBarBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.topBarBorder,
                          backgroundImage: (user?.profile?.avatarUrl != null && user!.profile!.avatarUrl!.isNotEmpty)
                              ? NetworkImage(user.profile!.avatarUrl!)
                              : null,
                          child: (user?.profile?.avatarUrl == null || user!.profile!.avatarUrl!.isEmpty)
                              ? Icon(roleIcon, size: 13, color: AppColors.topBarText)
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                user?.fullName ?? user?.username ?? 'Logged In User',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: AppColors.topBarText, // Cream
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                roleLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: AppColors.topBarMuted, // Silver
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Sign Out Button
            Tooltip(
              message: 'Sign Out',
              child: InkWell(
                onTap: () {
                  _confirmSignOut(context, auth);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.topBarSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.topBarBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.logout, size: 14, color: AppColors.topBarMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Sign Out',
                        style: GoogleFonts.inter(
                          color: AppColors.topBarMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, AuthProvider auth) {
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
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              auth.logout();
            },
            child: Text(
              'Sign Out',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
