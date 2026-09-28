import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_animations.dart';
import '../screens/customer/customer_dashboard_screen.dart';
import '../screens/receptionist/receptionist_screen.dart';
import '../screens/mechanic/mechanic_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/auth/auth_screen.dart';
import 'top_nav_bar.dart';

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
          // Sticky Redesigned Top Navigation Bar with slide-down entrance
          const TopBarEntrance(child: TopNavBar()),
          // Active Role Portal Screen
          Expanded(child: currentPortal),
        ],
      ),
    );
  }
}
