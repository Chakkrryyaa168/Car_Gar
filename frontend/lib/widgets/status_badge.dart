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

    // Express status through navy vs. silver contrast and weight — NO bright colors (orange/green/red)
    Color bgColor;
    Color borderColor;
    Color textColor;
    FontWeight fontWeight;

    switch (upper) {
      case 'APPROVED_IN_PROGRESS':
      case 'INSPECTING':
      case 'INSPECTION_PENDING':
        bgColor = AppColors.primary; // Solid Navy #1A1D29
        borderColor = AppColors.primary;
        textColor = AppColors.background; // Cream #F9EBEA
        fontWeight = FontWeight.w600;
        break;
      case 'PENDING_CUSTOMER_APPROVAL':
        bgColor = AppColors.surfaceElevated; // #FDF6F5
        borderColor = AppColors.primary; // Strong navy border for urgency
        textColor = AppColors.primary; // Navy text
        fontWeight = FontWeight.w700;
        break;
      case 'WORK_COMPLETED':
      case 'READY_FOR_PICKUP':
      case 'PAID_AND_CLOSED':
        bgColor = AppColors.surface; // #FFFFFF
        borderColor = AppColors.border; // Soft warm gray
        textColor = AppColors.textBody; // Softened navy
        fontWeight = FontWeight.w600;
        break;
      case 'CHECKED_IN':
      default:
        bgColor = AppColors.surfaceElevated; // #FDF6F5
        borderColor = AppColors.border; // #E8DAD8
        textColor = AppColors.textSecondary; // Muted silver-gray #8A8B8F
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
