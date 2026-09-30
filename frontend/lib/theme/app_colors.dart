import 'package:flutter/material.dart';

class AppColors {
  // Soft, Modern Blue Palette (Fintech / Calm Productivity)
  static const Color background = Color(0xFFF1F3F6); // Cloud gray (main app background)
  static const Color surface = Color(0xFFFFFFFF); // Clean white card
  static const Color surfaceElevated = Color(0xFFFFFFFF); // Barely lifted off cloud gray
  static const Color surfaceWarm = Color(0xFFE9EEF4); // Pale periwinkle tint / highlight

  // Primary & Accents (Soft Periwinkle Blue)
  static const Color primary = Color(0xFF5B7FA6); // Soft periwinkle blue (top bar, primary buttons, active states)
  static const Color periwinkle = Color(0xFF5B7FA6);
  static const Color periwinkleLight = Color(0xFFE9EEF4); // Pale periwinkle tint
  static const Color periwinkleHalo = Color(0x335B7FA6); // 20% alpha periwinkle halo
  static const Color periwinkleDark = Color(0xFF4D6F94); // Deeper periwinkle

  // Backward compatibility aliases
  static const Color sage = Color(0xFF5B7FA6);
  static const Color sageLight = Color(0xFFE9EEF4);
  static const Color sageHalo = Color(0x335B7FA6);
  static const Color sageDark = Color(0xFF4D6F94);

  // Typography & Dark Emphasis (Deep Blue-Charcoal)
  static const Color charcoal = Color(0xFF2E3A46); // Deep blue-charcoal
  static const Color textPrimary = Color(0xFF2E3A46); // Headings and primary text
  static const Color textBody = Color(0xFF2E3A46); // Body text
  static const Color textSecondary = Color(0xFF8792A0); // Soft gray-blue muted text
  static const Color textMuted = Color(0xFF8792A0); // Muted text

  // Secondary / Accent
  static const Color accent = Color(0xFF5B7FA6); // Soft periwinkle blue
  static const Color secondary = Color(0xFF8792A0); // Soft gray-blue

  // Borders & Dividers (Light cloud gray)
  static const Color border = Color(0xFFE1E5EA); // Light cloud gray border
  static const Color borderFaint = Color(0xFFE9EEF4); // Pale periwinkle faint border

  // Grounded Periwinkle Top Bar
  static const Color topBarBackground = Color(0xFF5B7FA6); // Soft periwinkle blue
  static const Color topBarSurface = Color(0xFF4D6F94); // Slightly deeper periwinkle for chips
  static const Color topBarText = Color(0xFFFFFFFF); // White text on top bar
  static const Color topBarMuted = Color(0xFFDCE5EE); // Soft white-periwinkle for secondary labels
  static const Color topBarBorder = Color(0xFF7293B8); // Soft periwinkle border

  // Invoice Card Specifics (Deep blue-charcoal with cloud gray text)
  static const Color invoiceBg = Color(0xFF2E3A46); // Deep blue-charcoal
  static const Color invoiceText = Color(0xFFF1F3F6); // Cloud gray text
  static const Color invoiceMuted = Color(0xFF8792A0); // Soft gray-blue on dark
  static const Color invoiceBorder = Color(0xFF3D4C5A); // Subtle divider on blue-charcoal

  // Tonal Periwinkle vs. Charcoal vs. Muted Gray Scale for States (NO orange, red, amber, green)
  static const Color statusCheckedIn = Color(0xFF8792A0);
  static const Color statusInspecting = Color(0xFF5B7FA6);
  static const Color statusPendingApproval = Color(0xFF2E3A46);
  static const Color statusApprovedInProgress = Color(0xFF5B7FA6);
  static const Color statusWorkCompleted = Color(0xFF5B7FA6);
  static const Color statusReadyForPickup = Color(0xFF2E3A46);
  static const Color statusPaidAndClosed = Color(0xFF8792A0);
  static const Color statusCancelled = Color(0xFF8792A0);

  // Semantic mappings (Restrained, periwinkle vs blue-charcoal vs gray-blue)
  static const Color success = Color(0xFF5B7FA6);
  static const Color warning = Color(0xFF2E3A46);
  static const Color danger = Color(0xFF8792A0);
  static const Color info = Color(0xFF5B7FA6);

  // Inventory semantic tags
  static const Color outOfStockBg = Color(0xFFE9EEF4);
  static const Color outOfStockText = Color(0xFF2E3A46);

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
