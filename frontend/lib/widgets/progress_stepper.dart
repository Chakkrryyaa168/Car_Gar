import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_animations.dart';

class ProgressStepper extends StatefulWidget {
  final String currentStatus;

  const ProgressStepper({super.key, required this.currentStatus});

  @override
  State<ProgressStepper> createState() => _ProgressStepperState();
}

class _ProgressStepperState extends State<ProgressStepper> with TickerProviderStateMixin {
  late AnimationController _lineController;
  late Animation<double> _lineAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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
    switch (widget.currentStatus.toUpperCase()) {
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
  void initState() {
    super.initState();
    // Smooth left-to-right line fill over 700ms on mount
    _lineController = AnimationController(
      vsync: this,
      duration: AppAnimations.durSlow,
    );
    _lineAnimation = CurvedAnimation(
      parent: _lineController,
      curve: AppAnimations.ease,
    );
    _lineController.forward();

    // Soft 2.4s calm pulsing halo for active step dot
    _pulseController = AnimationController(
      vsync: this,
      duration: AppAnimations.durPulseLoop,
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(ProgressStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStatus != widget.currentStatus) {
      _lineController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _lineController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _currentIndex;
    final reducedMotion = AppAnimations.isReducedMotion(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface, // #FFFFFF
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border), // #E4DED0
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B2F2C).withValues(alpha: 0.03),
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
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Step ${activeIndex + 1} of ${_steps.length}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
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

                    // Completed = solid sage (26px) with white check
                    // Active = slightly larger sage (32px) with soft sage halo
                    // Pending = faint outline in the border color (#E4DED0, 26px)
                    final double dotSize = isCurrent ? 32.0 : 26.0;

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Circle Indicator
                        Column(
                          children: [
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                final haloSpread = (reducedMotion || !isCurrent)
                                    ? 3.0
                                    : (2.0 + (_pulseAnimation.value * 2.5));
                                final haloBlur = (reducedMotion || !isCurrent)
                                    ? 8.0
                                    : (6.0 + (_pulseAnimation.value * 4.0));
                                final haloAlpha = (reducedMotion || !isCurrent)
                                    ? 0.35
                                    : (0.18 + (_pulseAnimation.value * 0.22));

                                return Container(
                                  width: dotSize,
                                  height: dotSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: (isCurrent || isPassed)
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: (isCurrent || isPassed)
                                          ? AppColors.primary
                                          : AppColors.border,
                                      width: isCurrent ? 2 : 1.5,
                                    ),
                                    boxShadow: isCurrent
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary.withValues(alpha: haloAlpha),
                                              blurRadius: haloBlur,
                                              spreadRadius: haloSpread,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: child,
                                );
                              },
                              child: Center(
                                child: isPassed
                                    ? _buildCheckIcon(reducedMotion)
                                    : Text(
                                        '${index + 1}',
                                        style: GoogleFonts.inter(
                                          fontSize: isCurrent ? 12 : 10,
                                          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                                          color: isCurrent
                                              ? Colors.white
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
                                  fontWeight: isCurrent
                                      ? FontWeight.w700
                                      : (isPassed ? FontWeight.w600 : FontWeight.w400),
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
                        // Connecting line between steps: fills left to right
                        if (index < _steps.length - 1)
                          _buildConnectingLine(index, activeIndex, reducedMotion),
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

  Widget _buildCheckIcon(bool reducedMotion) {
    if (reducedMotion) {
      return const Icon(Icons.check, size: 14, color: Colors.white);
    }
    return AnimatedBuilder(
      animation: _lineAnimation,
      builder: (context, _) {
        final scale = 0.75 + (0.25 * _lineAnimation.value);
        return Transform.scale(
          scale: scale,
          child: const Icon(Icons.check, size: 14, color: Colors.white),
        );
      },
    );
  }

  Widget _buildConnectingLine(int index, int activeIndex, bool reducedMotion) {
    final bool isLineCompleted = index < activeIndex;
    if (!isLineCompleted) {
      return Container(
        width: 24,
        height: 2,
        margin: const EdgeInsets.only(bottom: 24),
        color: AppColors.border,
      );
    }

    if (reducedMotion || activeIndex == 0) {
      return Container(
        width: 24,
        height: 2,
        margin: const EdgeInsets.only(bottom: 24),
        color: AppColors.primary,
      );
    }

    // Segment interval based on activeIndex
    final double startInterval = (index / activeIndex).clamp(0.0, 1.0);
    final double endInterval = ((index + 1) / activeIndex).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _lineAnimation,
      builder: (context, _) {
        final animVal = _lineAnimation.value;
        final double fraction = (endInterval > startInterval)
            ? ((animVal - startInterval) / (endInterval - startInterval)).clamp(0.0, 1.0)
            : 1.0;

        return Container(
          width: 24,
          height: 2,
          margin: const EdgeInsets.only(bottom: 24),
          color: AppColors.border,
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: fraction,
            child: Container(
              color: AppColors.primary,
            ),
          ),
        );
      },
    );
  }
}
