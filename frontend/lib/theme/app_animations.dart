import 'package:flutter/material.dart';

/// Central animation timings, curves, and motion components for the Car Garage app.
///
/// Principles:
/// - Single shared easing curve: cubic-bezier(0.22, 1, 0.36, 1) (soft ease-out)
/// - Fast interactions (buttons, taps, toggles): 180ms (150-200ms)
/// - Standard transitions (cards, screens, banners): 350ms (300-400ms)
/// - Slow/ambient effects (progress fills, pulses): 700ms (600-900ms)
/// - Respects prefers-reduced-motion / accessibilitySettings.disableAnimations
class AppAnimations {
  // Cubic-bezier(0.22, 1, 0.36, 1) - soft, calm ease-out
  static const Curve ease = Cubic(0.22, 1.0, 0.36, 1.0);

  // Timing constants
  static const Duration durFast = Duration(milliseconds: 180);
  static const Duration durBase = Duration(milliseconds: 350);
  static const Duration durSlow = Duration(milliseconds: 700);
  static const Duration durPulseLoop = Duration(milliseconds: 2400);

  /// Check if the user has requested reduced motion.
  static bool isReducedMotion(BuildContext context) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  /// Get adjusted duration honoring reduced motion preferences.
  static Duration getDuration(BuildContext context, Duration normalDuration) {
    return isReducedMotion(context) ? Duration.zero : normalDuration;
  }
}

/// Custom Page Transitions Builder providing subtle 12px horizontal slide + fade.
///
/// Forward push: outgoing slides 12px left and fades, incoming slides in from 12px right and fades in.
/// Pop: reverse direction smoothly without flashing.
class CalmPageTransitionsBuilder extends PageTransitionsBuilder {
  const CalmPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppAnimations.isReducedMotion(context)) {
      return FadeTransition(opacity: animation, child: child);
    }

    final curvedPrimary = CurvedAnimation(
      parent: animation,
      curve: AppAnimations.ease,
      reverseCurve: AppAnimations.ease,
    );

    final curvedSecondary = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AppAnimations.ease,
      reverseCurve: AppAnimations.ease,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([curvedPrimary, curvedSecondary]),
      builder: (context, _) {
        // Entering from +12px right, exiting towards +12px right on pop
        final primaryOffset = (1.0 - curvedPrimary.value) * 12.0;
        final primaryOpacity = curvedPrimary.value.clamp(0.0, 1.0);

        // When a new route pushes on top of this route, slide -12px left
        final secondaryOffset = -curvedSecondary.value * 12.0;
        final secondaryOpacity = (1.0 - curvedSecondary.value * 0.6).clamp(0.0, 1.0);

        final totalOffset = primaryOffset + secondaryOffset;
        final totalOpacity = (primaryOpacity * secondaryOpacity).clamp(0.0, 1.0);

        return Transform.translate(
          offset: Offset(totalOffset, 0),
          child: Opacity(
            opacity: totalOpacity,
            child: child,
          ),
        );
      },
    );
  }
}

/// Interactive button/pressable wrapper that adds:
/// - Scale down to 0.97 on press with quick return (180ms)
/// - 1px lift on hover on desktop with subtle brightness
class AppPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final BorderRadius? borderRadius;
  final double pressedScale;
  final double hoverLift;
  final HitTestBehavior behavior;

  const AppPressable({
    super.key,
    required this.child,
    this.onPressed,
    this.borderRadius,
    this.pressedScale = 0.97,
    this.hoverLift = 1.0,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.onPressed == null) {
      return widget.child;
    }

    final reducedMotion = AppAnimations.isReducedMotion(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!reducedMotion) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (!reducedMotion) setState(() => _isHovered = false);
      },
      child: GestureDetector(
        behavior: widget.behavior,
        onTap: widget.onPressed,
        onTapDown: (_) {
          if (!reducedMotion) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (!reducedMotion) setState(() => _isPressed = false);
        },
        onTapCancel: () {
          if (!reducedMotion) setState(() => _isPressed = false);
        },
        child: AnimatedScale(
          scale: _isPressed ? widget.pressedScale : 1.0,
          duration: AppAnimations.durFast,
          curve: AppAnimations.ease,
          child: AnimatedSlide(
            offset: Offset(0, (_isHovered && !_isPressed) ? -widget.hoverLift / 40.0 : 0.0),
            duration: AppAnimations.durFast,
            curve: AppAnimations.ease,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Staggered Entrance Animation for Page Load:
/// Fades in and slides translateY 16px to 0 with 60-80ms delay between consecutive items.
class StaggeredFadeSlide extends StatefulWidget {
  final int index;
  final Widget child;
  final double translateY;
  final Duration duration;
  final int stepDelayMs;

  const StaggeredFadeSlide({
    super.key,
    required this.index,
    required this.child,
    this.translateY = 16.0,
    this.duration = AppAnimations.durBase,
    this.stepDelayMs = 70,
  });

  @override
  State<StaggeredFadeSlide> createState() => _StaggeredFadeSlideState();
}

class _StaggeredFadeSlideState extends State<StaggeredFadeSlide> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: AppAnimations.ease);
    _slideAnimation = Tween<double>(begin: widget.translateY, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.ease),
    );

    // Stagger delay capped at 420ms so content is never delayed past 500ms
    final delay = Duration(milliseconds: (widget.index * widget.stepDelayMs).clamp(0, 420));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppAnimations.isReducedMotion(context)) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Smooth number counter for invoice total and line items.
/// Counts up to its value over ~700ms and re-animates smoothly when values update.
class CountingAmountText extends StatefulWidget {
  final double value;
  final TextStyle? style;
  final String prefix;
  final int decimalDigits;

  const CountingAmountText({
    super.key,
    required this.value,
    this.style,
    this.prefix = r'$',
    this.decimalDigits = 2,
  });

  @override
  State<CountingAmountText> createState() => _CountingAmountTextState();
}

class _CountingAmountTextState extends State<CountingAmountText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.durSlow,
    );
    _animation = Tween<double>(begin: 0.0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.ease),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(CountingAmountText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.value - widget.value).abs() > 0.001) {
      _animation = Tween<double>(begin: _animation.value, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: AppAnimations.ease),
      );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppAnimations.isReducedMotion(context)) {
      return Text(
        '${widget.prefix}${widget.value.toStringAsFixed(widget.decimalDigits)}',
        style: widget.style,
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Text(
          '${widget.prefix}${_animation.value.toStringAsFixed(widget.decimalDigits)}',
          style: widget.style,
        );
      },
    );
  }
}

/// Top bar subtle entrance animation: fades in and slides down (-10px to 0) on load.
class TopBarEntrance extends StatefulWidget {
  final Widget child;
  const TopBarEntrance({super.key, required this.child});

  @override
  State<TopBarEntrance> createState() => _TopBarEntranceState();
}

class _TopBarEntranceState extends State<TopBarEntrance> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppAnimations.durBase);
    _fade = CurvedAnimation(parent: _controller, curve: AppAnimations.ease);
    _slide = Tween<double>(begin: -10.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.ease),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppAnimations.isReducedMotion(context)) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fade.value,
          child: Transform.translate(
            offset: Offset(0, _slide.value),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Text field wrapper providing smooth border transition on focus with subtle 3px glow fading in.
class FocusGlowWrapper extends StatefulWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final Color glowColor;

  const FocusGlowWrapper({
    super.key,
    required this.child,
    this.borderRadius,
    this.glowColor = const Color(0x335F7F6B), // Soft sage glow
  });

  @override
  State<FocusGlowWrapper> createState() => _FocusGlowWrapperState();
}

class _FocusGlowWrapperState extends State<FocusGlowWrapper> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final reduced = AppAnimations.isReducedMotion(context);
    final radius = widget.borderRadius ?? BorderRadius.circular(8);

    return Focus(
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
      },
      child: AnimatedContainer(
        duration: reduced ? Duration.zero : AppAnimations.durFast,
        curve: AppAnimations.ease,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: _isFocused && !reduced
              ? [
                  BoxShadow(
                    color: widget.glowColor,
                    blurRadius: 6,
                    spreadRadius: 3,
                  ),
                ]
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Decision Button that morphs smoothly into confirmed state with scale pop (0.9 -> 1.0).
class MorphingDecisionButton extends StatelessWidget {
  final bool isApproved;
  final VoidCallback onTap;

  const MorphingDecisionButton({
    super.key,
    required this.isApproved,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final reduced = AppAnimations.isReducedMotion(context);

    return AppPressable(
      onPressed: onTap,
      child: AnimatedContainer(
        duration: reduced ? Duration.zero : AppAnimations.durFast,
        curve: AppAnimations.ease,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isApproved ? const Color(0xFF5F7F6B) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isApproved ? const Color(0xFF5F7F6B) : const Color(0xFFE4DED0),
            width: 1,
          ),
        ),
        child: AnimatedSwitcher(
          duration: reduced ? Duration.zero : AppAnimations.durFast,
          switchInCurve: AppAnimations.ease,
          switchOutCurve: AppAnimations.ease,
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: Row(
            key: ValueKey<bool>(isApproved),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isApproved ? Icons.check : Icons.close,
                size: 12,
                color: isApproved ? Colors.white : const Color(0xFF2B2F2C),
              ),
              const SizedBox(width: 4),
              Text(
                isApproved ? 'APPROVE' : 'DECLINE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isApproved ? FontWeight.w700 : FontWeight.w600,
                  color: isApproved ? Colors.white : const Color(0xFF2B2F2C),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sliding Segmented Tab: the active pill slides smoothly between options without snapping.
class SlidingSegmentedTab extends StatelessWidget {
  final int selectedIndex;
  final List<String> labels;
  final ValueChanged<int> onTabSelected;

  const SlidingSegmentedTab({
    super.key,
    required this.selectedIndex,
    required this.labels,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final reduced = AppAnimations.isReducedMotion(context);
    final count = labels.length;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF9F4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4DED0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = (constraints.maxWidth) / count;

          return Stack(
            children: [
              // Sliding Active Pill
              AnimatedPositioned(
                duration: reduced ? Duration.zero : AppAnimations.durBase,
                curve: AppAnimations.ease,
                left: selectedIndex * tabWidth,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF5F7F6B),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2B2F2C).withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              // Tab labels
              Row(
                children: List.generate(count, (index) {
                  final isSelected = index == selectedIndex;
                  return Expanded(
                    child: InkWell(
                      onTap: () => onTabSelected(index),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: AnimatedDefaultTextStyle(
                          duration: reduced ? Duration.zero : AppAnimations.durFast,
                          curve: AppAnimations.ease,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF7C837E),
                          ),
                          textAlign: TextAlign.center,
                          child: Text(labels[index]),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ScreenSlideFadeSwitcher: outgoing screen fades out and slides 12px left, incoming fades in and slides 12px right.
class ScreenSlideFadeSwitcher extends StatelessWidget {
  final Widget child;
  final bool isForward;

  const ScreenSlideFadeSwitcher({
    super.key,
    required this.child,
    this.isForward = true,
  });

  @override
  Widget build(BuildContext context) {
    if (AppAnimations.isReducedMotion(context)) {
      return AnimatedSwitcher(
        duration: AppAnimations.durFast,
        child: child,
      );
    }

    return AnimatedSwitcher(
      duration: AppAnimations.durBase,
      switchInCurve: AppAnimations.ease,
      switchOutCurve: AppAnimations.ease,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        final isIncoming = child.key == this.child.key;
        final beginOffset = isIncoming
            ? (isForward ? const Offset(12.0, 0.0) : const Offset(-12.0, 0.0))
            : Offset.zero;
        final endOffset = isIncoming
            ? Offset.zero
            : (isForward ? const Offset(-12.0, 0.0) : const Offset(12.0, 0.0));

        final slideTween = Tween<Offset>(begin: beginOffset, end: endOffset);

        return AnimatedBuilder(
          animation: animation,
          builder: (context, c) {
            final progress = animation.value;
            final offset = Offset.lerp(slideTween.begin, slideTween.end, progress)!;
            final opacity = progress.clamp(0.0, 1.0);
            return Transform.translate(
              offset: offset,
              child: Opacity(
                opacity: opacity,
                child: c,
              ),
            );
          },
          child: child,
        );
      },
      child: child,
    );
  }
}
