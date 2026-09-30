import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/preferences_service.dart';
import '../../theme/app_animations.dart';
import '../../theme/app_colors.dart';
import '../auth/auth_screen.dart';

/// Model representing a single onboarding slide.
class OnboardingSlideData {
  final String title;
  final String description;
  final Widget illustration;

  const OnboardingSlideData({
    required this.title,
    required this.description,
    required this.illustration,
  });
}

/// 3-slide Customer Onboarding Walkthrough on warm sand background (#F5F1E8).
///
/// Features:
/// - Horizontal swipeable slides with soft icon compositions (no photos)
/// - Staggered fade-up animation (60ms stagger between illustration and text)
/// - Active sage pill & inactive border dots page indicator
/// - 44px minimum tap targets with Semantics / accessibility labels
/// - "Skip" button on slides 1-2; "Next" transforming to "Get started" on slide 3
/// - Persistent `hasSeenOnboarding` flag saved on completion or skip
/// - Respects `prefers-reduced-motion`
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _isNextPressed = false;
  bool _isNavigating = false;

  // Staggered slide entrance controller
  late final AnimationController _slideAnimController;
  late final Animation<double> _illusFade;
  late final Animation<double> _illusSlide;
  late final Animation<double> _textFade;
  late final Animation<double> _textSlide;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // 400ms slide content entrance with 60ms stagger
    _slideAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Illustration: 0.0 -> 0.70
    _illusFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideAnimController,
        curve: const Interval(0.0, 0.70, curve: AppAnimations.ease),
      ),
    );
    _illusSlide = Tween<double>(begin: 14.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _slideAnimController,
        curve: const Interval(0.0, 0.70, curve: AppAnimations.ease),
      ),
    );

    // Text: 0.15 -> 1.0 (~60ms stagger)
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideAnimController,
        curve: const Interval(0.15, 1.0, curve: AppAnimations.ease),
      ),
    );
    _textSlide = Tween<double>(begin: 14.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _slideAnimController,
        curve: const Interval(0.15, 1.0, curve: AppAnimations.ease),
      ),
    );

    _slideAnimController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _slideAnimController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _slideAnimController.reset();
    _slideAnimController.forward();
  }

  Future<void> _completeOnboarding() async {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;

    // Save flag so onboarding won't be shown again on subsequent launches
    await PreferencesService.setHasSeenOnboarding(true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AuthScreen(),
        transitionDuration: AppAnimations.durBase,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: AppAnimations.ease),
            child: child,
          );
        },
      ),
    );
  }

  void _handleNext() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: AppAnimations.durBase,
        curve: AppAnimations.ease,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppAnimations.isReducedMotion(context);
    final slides = _buildSlides();

    return Scaffold(
      backgroundColor: AppColors.background, // Warm sand #F5F1E8
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar: Brand Header on left, Skip on right (slides 1 & 2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Subtle Brand Mark
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.directions_car_filled,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CAR GARAGE',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),

                  // Skip Button (Visible on slides 1-2, maintain layout on slide 3)
                  Visibility(
                    visible: _currentPage < 2,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: Semantics(
                      label: 'Skip onboarding',
                      button: true,
                      child: InkWell(
                        onTap: _completeOnboarding,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 48, minHeight: 44),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Text(
                            'Skip',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Middle: Horizontal Swipeable Walkthrough Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: slides.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final slide = slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        // Soft Illustration Area with Staggered Entrance
                        AnimatedBuilder(
                          animation: _slideAnimController,
                          builder: (context, child) {
                            final opacity = reduced ? 1.0 : _illusFade.value;
                            final translateY = reduced ? 0.0 : _illusSlide.value;
                            return Opacity(
                              opacity: opacity,
                              child: Transform.translate(
                                offset: Offset(0, translateY),
                                child: child,
                              ),
                            );
                          },
                          child: slide.illustration,
                        ),
                        const SizedBox(height: 38),

                        // Title & Description with 60ms Staggered Entrance
                        AnimatedBuilder(
                          animation: _slideAnimController,
                          builder: (context, child) {
                            final opacity = reduced ? 1.0 : _textFade.value;
                            final translateY = reduced ? 0.0 : _textSlide.value;
                            return Opacity(
                              opacity: opacity,
                              child: Transform.translate(
                                offset: Offset(0, translateY),
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Text(
                                slide.title,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 320),
                                child: Text(
                                  slide.description,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textSecondary,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
              ),
            ),

            // Bottom Area: Indicators & Action Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page Dots Indicator (Active dot stretches into sage pill)
                  Semantics(
                    label: 'Page ${_currentPage + 1} of 3',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final isActive = index == _currentPage;
                        return AnimatedContainer(
                          duration: reduced ? Duration.zero : AppAnimations.durFast,
                          curve: AppAnimations.ease,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 26 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.primary : AppColors.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Full-width Solid Sage "Next" / "Get started" Button
                  Semantics(
                    label: _currentPage == 2 ? 'Get started' : 'Next slide',
                    button: true,
                    child: GestureDetector(
                      onTapDown: (_) => setState(() => _isNextPressed = true),
                      onTapUp: (_) => setState(() => _isNextPressed = false),
                      onTapCancel: () => setState(() => _isNextPressed = false),
                      onTap: _handleNext,
                      child: AnimatedScale(
                        scale: (_isNextPressed && !reduced) ? 0.97 : 1.0,
                        duration: reduced ? Duration.zero : AppAnimations.durFast,
                        curve: AppAnimations.ease,
                        child: Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.primary, // Solid Sage #5F7F6B
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2E3A46).withValues(alpha: 0.10),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentPage == 2 ? 'Get started' : 'Next',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _currentPage == 2
                                      ? Icons.arrow_forward_rounded
                                      : Icons.chevron_right_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Subtle Staff Sign-in Link (allows staff to immediately jump to login)
                  const SizedBox(height: 10),
                  Semantics(
                    label: 'Staff Portal Sign in',
                    button: true,
                    child: InkWell(
                      onTap: _completeOnboarding,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 38),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Staff member? Sign in to workshop',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the 3 onboarding slides with pure icon compositions on soft sage circular tints.
  List<OnboardingSlideData> _buildSlides() {
    return [
      // Slide 1: Add your vehicle
      OnboardingSlideData(
        title: 'Add your vehicle',
        description: 'Register your car once and we\'ll verify it at your first visit.',
        illustration: _buildIllustrationArea(
          mainIcon: Icons.directions_car_rounded,
          chipIcon: Icons.verified_outlined,
          chipLabel: 'Verified Car Profile',
        ),
      ),

      // Slide 2: Review and approve
      OnboardingSlideData(
        title: 'Review and approve',
        description: 'See exactly what your mechanic found and choose what to fix, item by item.',
        illustration: _buildIllustrationArea(
          mainIcon: Icons.fact_check_outlined,
          chipIcon: Icons.check_circle_outline_rounded,
          chipLabel: 'Item-by-Item Approval',
        ),
      ),

      // Slide 3: Track and pay
      OnboardingSlideData(
        title: 'Track and pay',
        description: 'Follow repair progress live and pay when your car is ready.',
        illustration: _buildIllustrationArea(
          mainIcon: Icons.speed_rounded,
          chipIcon: Icons.receipt_long_outlined,
          chipLabel: 'Live Bay Tracker',
        ),
      ),
    ];
  }

  /// Clean, calm illustration container with concentric soft sage circles and a floating pill tag.
  Widget _buildIllustrationArea({
    required IconData mainIcon,
    required IconData chipIcon,
    required String chipLabel,
  }) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer subtle halo ring
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.06),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.12),
                width: 1.0,
              ),
            ),
          ),

          // Inner solid soft sage tint circle
          Container(
            width: 156,
            height: 156,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E3A46).withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                mainIcon,
                size: 68,
                color: AppColors.primary,
              ),
            ),
          ),

          // Floating white pill badge
          Positioned(
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface, // Clean white #FFFFFF
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border), // Light cloud gray #E1E5EA
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E3A46).withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(chipIcon, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    chipLabel,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
