import 'package:flutter/material.dart';
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
    this.fontSize = 12.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getStatusColor(status);
    final label = customLabel ?? AppColors.getStatusLabel(status);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14), // 12-15% opacity fill
        borderRadius: BorderRadius.circular(20), // Pill-shaped
        border: Border.all(
          color: color, // 100% full-strength border
          width: 1.0,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color, // 100% full-strength text
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
