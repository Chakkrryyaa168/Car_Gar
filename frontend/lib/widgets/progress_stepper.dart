import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ProgressStepper extends StatelessWidget {
  final String currentStatus;

  const ProgressStepper({super.key, required this.currentStatus});

  static const List<Map<String, dynamic>> _steps = [
    {'status': 'CHECKED_IN', 'title': 'Check-In', 'color': AppColors.statusCheckedIn},
    {'status': 'INSPECTING', 'title': 'Inspect', 'color': AppColors.statusInspecting},
    {'status': 'PENDING_CUSTOMER_APPROVAL', 'title': 'Approval', 'color': AppColors.statusPendingApproval},
    {'status': 'APPROVED_IN_PROGRESS', 'title': 'Repairs', 'color': AppColors.statusApprovedInProgress},
    {'status': 'WORK_COMPLETED', 'title': 'Done', 'color': AppColors.statusWorkCompleted},
    {'status': 'READY_FOR_PICKUP', 'title': 'Pickup', 'color': AppColors.statusReadyForPickup},
    {'status': 'PAID_AND_CLOSED', 'title': 'Closed', 'color': AppColors.statusPaidAndClosed},
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LIVE WORKFLOW PROGRESS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.getStatusColor(currentStatus).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Step ${activeIndex + 1} of ${_steps.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getStatusColor(currentStatus),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_steps.length, (index) {
                    final step = _steps[index];
                    final isPassed = index < activeIndex;
                    final isCurrent = index == activeIndex;
                    final Color stepColor = step['color'] as Color;

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Circle Indicator
                        Column(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCurrent
                                    ? stepColor
                                    : isPassed
                                        ? AppColors.success
                                        : Colors.white,
                                border: Border.all(
                                  color: isCurrent
                                      ? stepColor
                                      : isPassed
                                          ? AppColors.success
                                          : AppColors.border,
                                  width: 2,
                                ),
                                boxShadow: isCurrent
                                    ? [
                                        BoxShadow(
                                          color: stepColor.withValues(alpha: 0.35),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        )
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: isPassed
                                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                                    : Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isCurrent ? Colors.white : AppColors.textSecondary,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 64,
                              child: Text(
                                step['title'],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                  color: isCurrent ? AppColors.textPrimary : AppColors.textSecondary,
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
                            height: 3,
                            margin: const EdgeInsets.only(bottom: 22),
                            color: index < activeIndex
                                ? AppColors.success
                                : AppColors.border,
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
