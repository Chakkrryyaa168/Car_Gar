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

    // Express status through sage vs. charcoal vs. muted gray — NO bright colors (orange/green/red)
    Color bgColor;
    Color borderColor;
    Color textColor;
    FontWeight fontWeight;

    switch (upper) {
      case 'APPROVED_IN_PROGRESS':
      case 'INSPECTING':
      case 'INSPECTION_PENDING':
        bgColor = AppColors.primary; // Solid Sage #5F7F6B
        borderColor = AppColors.primary;
        textColor = Colors.white;
        fontWeight = FontWeight.w600;
        break;
      case 'PENDING_CUSTOMER_APPROVAL':
        bgColor = AppColors.surfaceElevated; // #FBF9F4
        borderColor = AppColors.charcoal; // Strong charcoal border for urgency
        textColor = AppColors.charcoal; // Deep charcoal text
        fontWeight = FontWeight.w700;
        break;
      case 'WORK_COMPLETED':
      case 'READY_FOR_PICKUP':
        bgColor = AppColors.sageLight; // Soft sage wash
        borderColor = AppColors.sage;
        textColor = AppColors.sageDark;
        fontWeight = FontWeight.w600;
        break;
      case 'PAID_AND_CLOSED':
      case 'CHECKED_IN':
      default:
        bgColor = AppColors.surfaceElevated; // #FBF9F4
        borderColor = AppColors.border; // Warm light gray #E4DED0
        textColor = AppColors.textSecondary; // Soft gray-green #7C837E
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
