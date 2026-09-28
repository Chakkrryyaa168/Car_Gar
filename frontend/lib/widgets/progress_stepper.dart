import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class ProgressStepper extends StatelessWidget {
  final String currentStatus;

  const ProgressStepper({super.key, required this.currentStatus});

  static const List<Map<String, String>> _steps = [
    {'status': 'CHECKED_IN', 'title': 'Check-In'},
    {'status': 'INSPECTING', 'title': 'Inspect'},
    {'status': 'PENDING_CUSTOMER_APPROVAL', 'title': 'Approval'},
    {'status': 'APPROVED_IN_PROGRESS', 'title': 'Repairs'},
    {'status': 'WORK_COMPLETED', 'title': 'Done'},
    {'status': 'READY_FOR_PICKUP', 'title': 'Pickup'},
    {'status': 'PAID_AND_CLOSED', 'title': 'Closed'},
  ];

  int get _currentIndex {
    switch (currentStatus.toUpperCase()) {
      case 'CHECKED_IN':
        return 0;
      case 'INSPECTION_PENDING':
      case 'INSPECTING':
        return 1;
      case 'PENDING_CUSTOMER_APPROVAL':
        return 2;
      case 'APPROVED_IN_PROGRESS':
        return 3;
      case 'WORK_COMPLETED':
        return 4;
      case 'READY_FOR_PICKUP':
        return 5;
      case 'PAID_AND_CLOSED':
        return 6;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _currentIndex;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface, // #FFFFFF
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border), // #E8DAD8
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1D29).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LIVE WORKFLOW PROGRESS',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated, // #FDF6F5
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Step ${activeIndex + 1} of ${_steps.length}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary, // #1A1D29
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_steps.length, (index) {
                    final step = _steps[index];
                    final isPassed = index < activeIndex;
                    final isCurrent = index == activeIndex;

                    // Active dot: solid navy (#1A1D29) and slightly larger (32px)
                    // Completed dot: navy at full opacity (#1A1D29, 26px) with cream check
                    // Pending dot: faint silver outline only (#E8DAD8, 26px)
                    final double dotSize = isCurrent ? 32.0 : 26.0;

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Circle Indicator
                        Column(
                          children: [
                            Container(
                              width: dotSize,
                              height: dotSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCurrent
                                    ? AppColors.primary // Solid navy #1A1D29
                                    : isPassed
                                        ? AppColors.primary // Navy at full opacity #1A1D29
                                        : Colors.transparent, // Faint silver outline only
                                border: Border.all(
                                  color: isCurrent
                                      ? AppColors.primary
                                      : isPassed
                                          ? AppColors.primary
                                          : AppColors.border, // #E8DAD8
                                  width: isCurrent ? 2 : 1.5,
                                ),
                              ),
                              child: Center(
                                child: isPassed
                                    ? const Icon(Icons.check, size: 14, color: AppColors.background) // Cream check
                                    : Text(
                                        '${index + 1}',
                                        style: GoogleFonts.inter(
                                          fontSize: isCurrent ? 12 : 10,
                                          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                                          color: isCurrent
                                              ? AppColors.background // Cream on navy
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 64,
                              child: Text(
                                step['title']!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: isCurrent ? FontWeight.w700 : (isPassed ? FontWeight.w600 : FontWeight.w400),
                                  color: isCurrent
                                      ? AppColors.primary
                                      : isPassed
                                          ? AppColors.textBody
                                          : AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        // Connecting line between steps
                        if (index < _steps.length - 1)
                          Container(
                            width: 24,
                            height: 2,
                            margin: const EdgeInsets.only(bottom: 24),
                            color: index < activeIndex
                                ? AppColors.primary // Solid navy line
                                : AppColors.border, // Faint soft warm divider #E8DAD8
                          ),
                      ],
                    );
                  }),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
