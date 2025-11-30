import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/animation_theme.dart';

/// Premium gold shimmer effect painter
class ShimmerPainter extends CustomPainter {
  final double progress;
  final Gradient gradient;
  final double angle;
  final double width;
  
  ShimmerPainter({
    required this.progress,
    Gradient? gradient,
    this.angle = -math.pi / 4, // Diagonal from top-left to bottom-right
    this.width = 100.0,
  }) : gradient = gradient ?? AnimationTheme.goldGradient;
  
  @override
  void paint(Canvas canvas, Size size) {
    // Calculate shimmer position
    final diagonal = math.sqrt(size.width * size.width + size.height * size.height);
    final shimmerStart = -width;
    final shimmerEnd = diagonal + width;
    final shimmerPosition = shimmerStart + (shimmerEnd - shimmerStart) * progress;
    
    // Create shimmer gradient
    final shimmerGradient = LinearGradient(
      colors: [
        Colors.transparent,
        AnimationTheme.goldShimmer.withOpacity(0.3),
        AnimationTheme.goldLight.withOpacity(0.6),
        AnimationTheme.goldShimmer.withOpacity(0.3),
        Colors.transparent,
      ],
      stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
      transform: GradientRotation(angle),
    );
    
    // Create shimmer rect
    final paint = Paint()
      ..shader = shimmerGradient.createShader(
        Rect.fromLTWH(
          shimmerPosition - width / 2,
          -size.height,
          width,
          size.height * 3,
        ),
      )
      ..blendMode = BlendMode.plus; // Additive blending for glow effect
    
    // Apply rotation and draw
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(angle);
    canvas.translate(-size.width / 2, -size.height / 2);
    
    canvas.drawRect(
      Rect.fromLTWH(
        shimmerPosition - width / 2,
        -size.height,
        width,
        size.height * 3,
      ),
      paint,
    );
    
    canvas.restore();
  }
  
  @override
  bool shouldRepaint(ShimmerPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

/// Shimmer effect widget with customizable animation
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final bool enabled;
  final Gradient? gradient;
  final double angle;
  final double width;
  
  const ShimmerEffect({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 2000),
    this.delay = Duration.zero,
    this.enabled = true,
    this.gradient,
    this.angle = -math.pi / 4,
    this.width = 80.0,
  });
  
  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    if (widget.enabled) {
      _startAnimation();
    }
  }
  
  void _startAnimation() async {
    await Future.delayed(widget.delay);
    if (mounted && widget.enabled) {
      _controller.repeat();
    }
  }
  
  @override
  void didUpdateWidget(ShimmerEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          foregroundPainter: ShimmerPainter(
            progress: Curves.easeInOut.transform(_controller.value),
            gradient: widget.gradient,
            angle: widget.angle,
            width: widget.width,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

