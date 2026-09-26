import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../screens/customer/customer_dashboard_screen.dart';
import '../screens/receptionist/receptionist_screen.dart';
import '../screens/mechanic/mechanic_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/auth/auth_screen.dart';

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
      body: Column(
        children: [
          // Authenticated User Top Navigation Bar
          _buildAuthenticatedHeader(context, auth),
          // Active Role Portal Screen
          Expanded(child: currentPortal),
        ],
      ),
    );
  }

  Widget _buildAuthenticatedHeader(BuildContext context, AuthProvider auth) {
    final user = auth.currentUser;
    final role = auth.currentRole;

    Color roleColor;
    IconData roleIcon;
    String roleLabel;

    switch (role) {
      case 'ADMIN':
        roleColor = const Color(0xFF6366F1); // Indigo
        roleIcon = Icons.admin_panel_settings_outlined;
        roleLabel = 'ADMINISTRATOR';
        break;
      case 'RECEPTIONIST':
        roleColor = const Color(0xFF3B82F6); // Blue
        roleIcon = Icons.desk_outlined;
        roleLabel = 'RECEPTION & CASHIER';
        break;
      case 'MECHANIC':
        roleColor = const Color(0xFFF97316); // Safety Orange
        roleIcon = Icons.build_outlined;
        roleLabel = 'WORKSHOP MECHANIC';
        break;
      case 'CUSTOMER':
      default:
        roleColor = const Color(0xFF14B8A6); // Teal
        roleIcon = Icons.person_outline;
        roleLabel = 'VEHICLE OWNER';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF1E3A5F), // Deep Steel Blue
        border: Border(bottom: BorderSide(color: Color(0xFF152A45), width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Garage Brand Emblem
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.directions_car_filled, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CAR GARAGE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  'Management Portal',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
            const Spacer(),

            // User Info & Role Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: roleColor,
                    child: Icon(roleIcon, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user?.fullName ?? user?.username ?? 'Logged In User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        roleLabel,
                        style: TextStyle(
                          color: roleColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Sign Out / Switch User Button
            InkWell(
              onTap: () {
                _confirmSignOut(context, auth);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Sign Out',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Sign Out'),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out of the Car Garage Management System?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              auth.logout();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
