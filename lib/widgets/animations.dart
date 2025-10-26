import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

enum SlideDirection {
  left,
  right,
  up,
  down,
}

class AppAnimations {
  // Fade in animation
  static Widget fadeIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 500),
    Duration delay = Duration.zero,
  }) {
    return FadeIn(
      duration: duration,
      delay: delay,
      child: child,
    );
  }

  // Slide in animation
  static Widget slideIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 500),
    Duration delay = Duration.zero,
    SlideDirection direction = SlideDirection.right,
  }) {
    return FadeInLeft(
      duration: duration,
      delay: delay,
      child: child,
    );
  }

  // Scale animation
  static Widget scaleIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
    Duration delay = Duration.zero,
  }) {
    return FadeIn(
      duration: duration,
      delay: delay,
      child: child,
    );
  }

  // Bounce animation
  static Widget bounceIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 600),
    Duration delay = Duration.zero,
  }) {
    return BounceInDown(
      duration: duration,
      delay: delay,
      child: child,
    );
  }

  // Elastic animation
  static Widget elasticIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 800),
    Duration delay = Duration.zero,
  }) {
    return ElasticIn(
      duration: duration,
      delay: delay,
      child: child,
    );
  }

  // Staggered list animation
  static List<Widget> staggeredList({
    required List<Widget> children,
    Duration itemDelay = const Duration(milliseconds: 100),
    SlideDirection direction = SlideDirection.right,
  }) {
    return children.asMap().entries.map((entry) {
      final index = entry.key;
      final child = entry.value;

      return FadeIn(
        duration: const Duration(milliseconds: 500),
        delay: Duration(milliseconds: index * itemDelay.inMilliseconds),
        child: child,
      );
    }).toList();
  }

  // Button press animation
  static Widget animatedButton({
    required VoidCallback onPressed,
    required Widget child,
    Duration duration = const Duration(milliseconds: 150),
  }) {
    return GestureDetector(
      onTap: () async {
        // Add haptic feedback effect
        await Future.delayed(const Duration(milliseconds: 50));
        onPressed();
      },
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..scale(0.95),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 8,
            shadowColor: Colors.blue.withOpacity(0.3),
          ),
          child: child,
        ),
      ),
    );
  }
}

// Custom animated widgets for the restaurant POS
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final VoidCallback? onTap;

  const AnimatedCard({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.onTap,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

// Pulse animation for status indicators
class PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;

  const PulsingIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 24,
  });

  @override
  State<PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Icon(
            widget.icon,
            color: widget.color,
            size: widget.size,
          ),
        );
      },
    );
  }
}
