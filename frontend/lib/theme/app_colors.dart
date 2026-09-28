import 'package:flutter/material.dart';

class AppColors {
  // Soft, Calm, Earthy Palette (Warm Sand + Sage Green + Deep Charcoal)
  static const Color background = Color(0xFFF5F1E8); // Warm sand (main app background)
  static const Color surface = Color(0xFFFFFFFF); // Clean white card
  static const Color surfaceElevated = Color(0xFFFBF9F4); // Barely lifted off the sand background
  static const Color surfaceWarm = Color(0xFFEFE9DC); // Slightly deeper warm sand for chips

  // Primary & Accents (Sage Green)
  static const Color primary = Color(0xFF5F7F6B); // Sage green (top bar, primary buttons, active states)
  static const Color sage = Color(0xFF5F7F6B); // Sage green
  static const Color sageLight = Color(0xFFE9EFEA); // Soft sage wash
  static const Color sageHalo = Color(0x335F7F6B); // 20% alpha sage halo
  static const Color sageDark = Color(0xFF4C6656); // Deeper sage

  // Typography & Dark Emphasis (Deep Charcoal)
  static const Color charcoal = Color(0xFF2B2F2C); // Deep charcoal
  static const Color textPrimary = Color(0xFF2B2F2C); // Headings and primary text
  static const Color textBody = Color(0xFF2B2F2C); // Body text
  static const Color textSecondary = Color(0xFF7C837E); // Soft gray-green muted text
  static const Color textMuted = Color(0xFF7C837E); // Muted text

  // Secondary / Accent
  static const Color accent = Color(0xFF7C837E); // Soft gray-green
  static const Color secondary = Color(0xFF7C837E); // Soft gray-green

  // Borders & Dividers (Warm light gray)
  static const Color border = Color(0xFFE4DED0); // Warm light gray border
  static const Color borderFaint = Color(0xFFEFE9DD); // Barely visible border

  // Grounded Sage Top Bar
  static const Color topBarBackground = Color(0xFF5F7F6B); // Sage green
  static const Color topBarSurface = Color(0xFF526E5C); // Slightly deeper sage for chips
  static const Color topBarText = Color(0xFFFFFFFF); // White text on top bar
  static const Color topBarMuted = Color(0xFFD6DFD8); // Soft sage-white for secondary labels
  static const Color topBarBorder = Color(0xFF6B8B77); // Soft sage border

  // Invoice Card Specifics (Deep charcoal with sand text)
  static const Color invoiceBg = Color(0xFF2B2F2C); // Deep charcoal
  static const Color invoiceText = Color(0xFFF5F1E8); // Sand-colored text
  static const Color invoiceMuted = Color(0xFFA5ACA7); // Soft light gray-green on dark
  static const Color invoiceBorder = Color(0xFF3F4541); // Subtle divider on charcoal

  // Tonal Sage vs. Charcoal vs. Muted Gray Scale for States (NO orange, red, amber, bright green)
  static const Color statusCheckedIn = Color(0xFF7C837E);
  static const Color statusInspecting = Color(0xFF5F7F6B);
  static const Color statusPendingApproval = Color(0xFF2B2F2C);
  static const Color statusApprovedInProgress = Color(0xFF5F7F6B);
  static const Color statusWorkCompleted = Color(0xFF5F7F6B);
  static const Color statusReadyForPickup = Color(0xFF2B2F2C);
  static const Color statusPaidAndClosed = Color(0xFF7C837E);
  static const Color statusCancelled = Color(0xFF7C837E);

  // Semantic mappings (Restrained, calm, desaturated)
  static const Color success = Color(0xFF5F7F6B);
  static const Color warning = Color(0xFF2B2F2C);
  static const Color danger = Color(0xFF7C837E);
  static const Color info = Color(0xFF5F7F6B);

  // Inventory semantic tags
  static const Color outOfStockBg = Color(0xFFFBF9F4);
  static const Color outOfStockText = Color(0xFF7C837E);

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
