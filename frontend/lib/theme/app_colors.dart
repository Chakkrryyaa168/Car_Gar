import 'package:flutter/material.dart';

class AppColors {
  // Brand & Foundation
  static const Color primary = Color(0xFF1E3A5F); // Deep Steel Blue
  static const Color accent = Color(0xFFF97316);  // Safety Orange
  static const Color background = Color(0xFFF8FAFC); // Near-white Gray
  static const Color surface = Color(0xFFFFFFFF);    // Pure White
  static const Color textPrimary = Color(0xFF1E293B); // Slate Dark
  static const Color textSecondary = Color(0xFF64748B); // Slate Muted
  static const Color border = Color(0xFFE2E8F0);

  // Status Badge Colors (Mapped to ticket_status)
  static const Color statusCheckedIn = Color(0xFF94A3B8);
  static const Color statusInspecting = Color(0xFF3B82F6);
  static const Color statusPendingApproval = Color(0xFFF59E0B);
  static const Color statusApprovedInProgress = Color(0xFF6366F1);
  static const Color statusWorkCompleted = Color(0xFF14B8A6);
  static const Color statusReadyForPickup = Color(0xFFF97316);
  static const Color statusPaidAndClosed = Color(0xFF22C55E);
  static const Color statusCancelled = Color(0xFFEF4444);

  // Semantic & Inventory Colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Inventory Out-of-Stock
  static const Color outOfStockBg = Color(0xFFFEE2E2);
  static const Color outOfStockText = Color(0xFFEF4444);

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
