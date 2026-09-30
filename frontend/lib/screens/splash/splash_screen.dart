import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/preferences_service.dart';
import '../../theme/app_animations.dart';
import '../../widgets/app_shell.dart';
import '../auth/auth_screen.dart';
import '../onboarding/onboarding_screen.dart';

/// Full-screen Splash Screen with sage gradient and animated brand logo tile.
///
/// Lasts 1.5 - 2.0 seconds and then transitions into:
/// - AppShell (if already authenticated)
/// - AuthScreen (if staff role or already seen onboarding)
/// - OnboardingScreen (first launch for customer)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _animController;
  late final AnimationController _pulseController;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<double> _textSlide;

  Timer? _navTimer;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    // Main entrance animation (logo scale/fade + text fade/slide)
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.65, curve: AppAnimations.ease),
      ),
    );

    _logoScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.65, curve: AppAnimations.ease),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.35, 1.0, curve: AppAnimations.ease),
      ),
    );

    _textSlide = Tween<double>(begin: 12.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.35, 1.0, curve: AppAnimations.ease),
      ),
    );

    // Bottom soft pulsing dots animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _animController.forward();

    // Start navigation timer: 8 seconds per user request
    _navTimer = Timer(const Duration(seconds: 8), _handleNavigation);
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _animController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleNavigation() async {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;
    _pulseController.stop();

    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Check if user is already logged in
    if (auth.isAuthenticated) {
      _navigateTo(const AppShell());
      return;
    }

    // Check onboarding status and last role from storage
    final hasSeenOnboarding = await PreferencesService.hasSeenOnboarding();
    final lastRole = await PreferencesService.getLastRole();

    // Staff roles (receptionist, mechanic, admin) skip onboarding straight to login
    final isStaff = lastRole != null &&
        (lastRole == 'ADMIN' || lastRole == 'RECEPTIONIST' || lastRole == 'MECHANIC');

    if (isStaff || hasSeenOnboarding) {
      _navigateTo(const AuthScreen());
    } else {
      _navigateTo(const OnboardingScreen());
    }
  }

  void _navigateTo(Widget destination) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
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

  @override
  Widget build(BuildContext context) {
    final reduced = AppAnimations.isReducedMotion(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5B7FA6), Color(0xFF4D6F94)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Center Logo Tile & Text
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo Tile: Translucent white fill, 1px white border at 22% opacity
                    AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        final opacity = reduced ? 1.0 : _logoFade.value;
                        final scale = reduced ? 1.0 : _logoScale.value;
                        return Opacity(
                          opacity: opacity,
                          child: Transform.scale(
                            scale: scale,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2E3A46).withValues(alpha: 0.16),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.directions_car_filled,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Brand Typography: "CAR GARAGE" & Tagline
                    AnimatedBuilder(
                      animation: _animController,
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'CAR GARAGE',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Repairs, made clear',
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Pulsing Dots Indicator
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Center(
                  child: Semantics(
                    label: 'Loading application',
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final val = _pulseController.value;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(3, (index) {
                            // Phase shift for each dot to create wave pulse
                            final delay = index * 0.33;
                            final dotProgress = ((val + delay) % 1.0);
                            final dotAlpha = 0.35 + (0.50 * dotProgress);
                            final dotScale = reduced ? 1.0 : 0.85 + (0.30 * dotProgress);

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Transform.scale(
                                scale: dotScale,
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: dotAlpha),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
