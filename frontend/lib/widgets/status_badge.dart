import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String? customLabel;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const StatusBadge({
    super.key,
    required this.status,
    this.customLabel,
    this.fontSize = 11.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
  });

  @override
  Widget build(BuildContext context) {
    final label = customLabel ?? AppColors.getStatusLabel(status);
    final upper = status.toUpperCase();

    // Express status through periwinkle vs. deep blue-charcoal vs. muted gray-blue — NO bright colors (orange/green/red)
    Color bgColor;
    Color borderColor;
    Color textColor;
    FontWeight fontWeight;

    switch (upper) {
      case 'APPROVED_IN_PROGRESS':
      case 'INSPECTING':
      case 'INSPECTION_PENDING':
      case 'WORK_COMPLETED':
        // Normal active/progress states: pale periwinkle tint (#E9EEF4) with periwinkle text (#5B7FA6)
        bgColor = const Color(0xFFE9EEF4);
        borderColor = const Color(0xFF5B7FA6).withValues(alpha: 0.35);
        textColor = const Color(0xFF5B7FA6);
        fontWeight = FontWeight.w600;
        break;
      case 'PENDING_CUSTOMER_APPROVAL':
      case 'READY_FOR_PICKUP':
        // Urgent / Action required: deep blue-charcoal contrast with pale periwinkle tint
        bgColor = const Color(0xFFE9EEF4);
        borderColor = AppColors.charcoal; // Strong #2E3A46 border for urgency
        textColor = AppColors.charcoal; // Deep blue-charcoal text
        fontWeight = FontWeight.w700;
        break;
      case 'PAID_AND_CLOSED':
      case 'CHECKED_IN':
      case 'CANCELLED':
      default:
        // Inactive / soft states: light gray background (#F1F3F6) with muted text (#8792A0)
        bgColor = AppColors.background; // #F1F3F6 (cloud gray)
        borderColor = AppColors.border; // #E1E5EA
        textColor = AppColors.textSecondary; // #8792A0 (soft gray-blue)
        fontWeight = FontWeight.w500;
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: textColor,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
