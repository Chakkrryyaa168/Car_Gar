import 'package:flutter/material.dart';

class AppColors {
  // Soft, Calm Light Palette (Mediterranean Cream + Moody Navy + Silver-Gray)
  static const Color background = Color(0xFFF9EBEA); // Warm mediterranean cream (main app background)
  static const Color surface = Color(0xFFFFFFFF); // Pure white cards sitting on cream
  static const Color surfaceElevated = Color(0xFFFDF6F5); // Barely lifted off cream
  static const Color surfaceMuted = Color(0xFFF5E4E2); // Subtly deeper cream for badges/chips

  // Primary & Text Emphasis (Moody Navy-Black)
  static const Color primary = Color(0xFF1A1D29); // Moody navy-black for headings, primary buttons, active states, icons
  static const Color textPrimary = Color(0xFF1A1D29); // Headings, titles, active emphasis
  static const Color textBody = Color(0xFF2E313D); // Softened navy, not pure black (body text)
  static const Color textSecondary = Color(0xFF8A8B8F); // Muted text for readability on cream
  static const Color textMuted = Color(0xFF8A8B8F); // Muted silver-gray

  // Secondary / Accent (Silver-gray)
  static const Color accent = Color(0xFFB1B2B5); // Silver-gray (borders, inactive icons, dividers)
  static const Color secondary = Color(0xFFB1B2B5); // Silver-gray

  // Borders & Dividers
  static const Color border = Color(0xFFE8DAD8); // Soft warm gray, blends with the cream background
  static const Color borderFaint = Color(0xFFF0E5E3); // Barely visible border

  // Grounded Top Bar (Navy + Cream)
  static const Color topBarBackground = Color(0xFF1A1D29); // Grounded navy background
  static const Color topBarSurface = Color(0xFF252A3A); // Slightly lifted navy on top bar
  static const Color topBarText = Color(0xFFF9EBEA); // Cream / near-white on top bar
  static const Color topBarMuted = Color(0xFFB1B2B5); // Silver text on top bar
  static const Color topBarBorder = Color(0xFF2E3242); // Navy divider on top bar

  // Tonal Navy vs. Silver Scale for States (NO orange, green, red, amber)
  // Contrast, weight, and opacity indicate status
  static const Color statusCheckedIn = Color(0xFF8A8B8F);
  static const Color statusInspecting = Color(0xFF2E313D);
  static const Color statusPendingApproval = Color(0xFF1A1D29);
  static const Color statusApprovedInProgress = Color(0xFF1A1D29);
  static const Color statusWorkCompleted = Color(0xFF2E313D);
  static const Color statusReadyForPickup = Color(0xFF1A1D29);
  static const Color statusPaidAndClosed = Color(0xFF8A8B8F);
  static const Color statusCancelled = Color(0xFFB1B2B5);

  // Semantic mappings (Restrained, calm, desaturated)
  static const Color success = Color(0xFF1A1D29);
  static const Color warning = Color(0xFF2E313D);
  static const Color danger = Color(0xFF8A8B8F);
  static const Color info = Color(0xFF1A1D29);

  // Inventory semantic tags
  static const Color outOfStockBg = Color(0xFFFDF6F5);
  static const Color outOfStockText = Color(0xFF8A8B8F);

  // Helper method to retrieve color for any ticket status string
  static Color getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'CHECKED_IN':
        return statusCheckedIn;
      case 'INSPECTION_PENDING':
      case 'INSPECTING':
        return statusInspecting;
      case 'PENDING_CUSTOMER_APPROVAL':
        return statusPendingApproval;
      case 'APPROVED_IN_PROGRESS':
        return statusApprovedInProgress;
      case 'WORK_COMPLETED':
        return statusWorkCompleted;
      case 'READY_FOR_PICKUP':
        return statusReadyForPickup;
      case 'PAID_AND_CLOSED':
        return statusPaidAndClosed;
      case 'CANCELLED':
        return statusCancelled;
      default:
        return textSecondary;
    }
  }

  // Readable label for statuses
  static String getStatusLabel(String? status) {
    switch (status?.toUpperCase()) {
      case 'CHECKED_IN':
        return 'Checked In';
      case 'INSPECTION_PENDING':
        return 'Inspection Pending';
      case 'INSPECTING':
        return 'Inspecting';
      case 'PENDING_CUSTOMER_APPROVAL':
        return 'Pending Approval';
      case 'APPROVED_IN_PROGRESS':
        return 'In Progress';
      case 'WORK_COMPLETED':
        return 'Work Completed';
      case 'READY_FOR_PICKUP':
        return 'Ready For Pickup';
      case 'PAID_AND_CLOSED':
        return 'Paid & Closed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status ?? 'Unknown';
    }
  }
}
