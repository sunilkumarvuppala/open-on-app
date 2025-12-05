import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:openon_app/core/constants/app_constants.dart';

/// Magic dust background effect with soft glow speckles and animated sparkles
class MagicDustBackground extends StatefulWidget {
  final Widget child;
  final Color baseColor;

  const MagicDustBackground({
    super.key,
    required this.child,
    required this.baseColor,
  });

  @override
  State<MagicDustBackground> createState() => _MagicDustBackgroundState();
}

class _MagicDustBackgroundState extends State<MagicDustBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<_Particle> _particles = [];
  final List<_Sparkle> _sparkles = [];
  DateTime _startTime = DateTime.now();
  double _normalizedScrollPosition = 0.0; // Normalized scroll position (0-1) for parallax

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _animationController = AnimationController(
      vsync: this,
      duration: AppConstants.magicDustAnimationDuration,
    )..repeat();

    // Initialize particles (soft glow speckles)
    final random = math.Random();
    for (int i = 0; i < AppConstants.magicDustParticleCount; i++) {
      _particles.add(_Particle(
        x: random.nextDouble(),
        y: random.nextDouble() * AppConstants.magicDustHeaderAreaRatio,
        size: 2 + random.nextDouble() * 3,
        baseOpacity: AppConstants.magicDustMinOpacity +
            random.nextDouble() *
                (AppConstants.magicDustMaxOpacity -
                    AppConstants.magicDustMinOpacity),
        phase: random.nextDouble() * 2 * math.pi,
      ));
    }

    // Initialize sparkles (animated with slow movement) - distributed across entire screen
    final int sparkleCount = (AppConstants.magicDustSparkleCount * AppConstants.magicDustSparkleCountMultiplier).round();
    for (int i = 0; i < sparkleCount; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      _sparkles.add(_Sparkle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: AppConstants.sparkleSizeMin + random.nextDouble() * (AppConstants.sparkleSizeMax - AppConstants.sparkleSizeMin),
        phase: random.nextDouble() * 2 * math.pi,
        delay: random.nextDouble() * 2 * math.pi,
        velocityX: math.cos(angle) * AppConstants.sparkleBaseVelocity,
        velocityY: math.sin(angle) * AppConstants.sparkleBaseVelocity,
      ));
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Update normalized scroll position for parallax effect
          // This works across tab switches by normalizing to viewport height
          if (notification is ScrollUpdateNotification || 
              notification is ScrollMetricsNotification ||
              notification is ScrollStartNotification) {
            final metrics = notification.metrics;
            if (metrics.maxScrollExtent > 0) {
              // Normalize scroll position to 0-1 range based on scroll extent
              // This ensures parallax works consistently across different tab content
              setState(() {
                _normalizedScrollPosition = metrics.pixels / metrics.maxScrollExtent;
              });
            } else {
              // If no scrollable content, use pixels directly normalized by viewport
              setState(() {
                _normalizedScrollPosition = metrics.pixels / (metrics.viewportDimension * 2);
              });
            }
          }
          return false; // Allow notification to continue propagating
        },
        child: Stack(
          children: [
            widget.child,
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    // Calculate elapsed time for consistent movement speed
                    final elapsedSeconds = DateTime.now().difference(_startTime).inMilliseconds / AppConstants.millisecondsPerSecond;
                    return CustomPaint(
                      painter: _MagicDustPainter(
                        particles: _particles,
                        sparkles: _sparkles,
                        baseColor: widget.baseColor,
                        animationValue: _animationController.value,
                        elapsedTime: elapsedSeconds,
                        normalizedScrollPosition: _normalizedScrollPosition,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Particle data for soft glow speckles
class _Particle {
  final double x;
  final double y;
  final double size;
  final double baseOpacity;
  final double phase;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.baseOpacity,
    required this.phase,
  });
}

/// Sparkle data for animated sparkles with slow movement
class _Sparkle {
  final double x;
  final double y;
  final double size;
  final double phase;
  final double delay;
  final double velocityX;
  final double velocityY;

  _Sparkle({
    required this.x,
    required this.y,
    required this.size,
    required this.phase,
    required this.delay,
    required this.velocityX,
    required this.velocityY,
  });
  
  // Calculate current position based on elapsed time for consistent speed
  Offset getPosition(double elapsedTime, Size canvasSize) {
    // Use elapsed time instead of animation value for consistent movement speed
    // Wrap around screen edges for continuous movement
    double newX = (x + velocityX * elapsedTime * canvasSize.width) % 1.0;
    if (newX < 0) newX += 1.0;
    
    double newY = (y + velocityY * elapsedTime * canvasSize.height) % 1.0;
    if (newY < 0) newY += 1.0;
    
    return Offset(newX, newY);
  }
}

/// Custom painter for magic dust effect
class _MagicDustPainter extends CustomPainter {
  final List<_Particle> particles;
  final List<_Sparkle> sparkles;
  final Color baseColor;
  final double animationValue;
  final double elapsedTime;
  final double normalizedScrollPosition;

  _MagicDustPainter({
    required this.particles,
    required this.sparkles,
    required this.baseColor,
    required this.animationValue,
    required this.elapsedTime,
    this.normalizedScrollPosition = 0.0,
  });

  // Reusable Paint objects to avoid allocation
  final Paint _particlePaint = Paint()..style = PaintingStyle.fill;
  final Paint _glowPaint = Paint()..style = PaintingStyle.fill;
  final Paint _sparklePaint = Paint()..style = PaintingStyle.fill;
  final Paint _centerPaint = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw soft glow speckles (static particles with 4-6% opacity)
    for (final particle in particles) {
      final x = particle.x * size.width;
      final y = particle.y * size.height;
      
      _particlePaint
        ..color = Colors.white.withOpacity(particle.baseOpacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.size * 2);
      
      canvas.drawCircle(
        Offset(x, y),
        particle.size,
        _particlePaint,
      );
    }

    // Draw animated sparkles with slow movement (opacity animation 0 → 1)
    for (final sparkle in sparkles) {
      // Calculate current position with slow movement using elapsed time
      final position = sparkle.getPosition(elapsedTime, size);
      
      // Apply subtle parallax effect based on normalized scroll
      // Parallax moves in opposite direction of scroll for depth effect
      // Normalized position (0-1) scaled to create visible but subtle shift
      const maxParallaxShift = 8.0; // Maximum parallax shift in pixels (increased for visibility)
      final parallaxX = -normalizedScrollPosition * maxParallaxShift;
      final parallaxY = -normalizedScrollPosition * maxParallaxShift * 0.7; // Slightly less vertical parallax
      
      // Clamp to reasonable maximum shift
      final clampedParallaxX = parallaxX.clamp(-8.0, 8.0);
      final clampedParallaxY = parallaxY.clamp(-6.0, 6.0);
      
      final x = position.dx * size.width + clampedParallaxX;
      final y = position.dy * size.height + clampedParallaxY;
      
      // Slow opacity animation (0 → 1 → 0)
      final opacityCycle = (math.sin(animationValue * 2 * math.pi + sparkle.delay) + 1) / 2;
      final opacity = opacityCycle * AppConstants.sparkleMaxOpacity;
      
      if (opacity > AppConstants.sparkleMinVisibleOpacity) {
        // Outer glow
        _glowPaint
          ..color = Colors.white.withOpacity(opacity * AppConstants.sparkleGlowOpacityMultiplier)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, sparkle.size * AppConstants.sparkleBlurMultiplier);
        canvas.drawCircle(
          Offset(x, y),
          sparkle.size * AppConstants.sparkleGlowSizeMultiplier,
          _glowPaint,
        );

        // Main sparkle
        _sparklePaint
          ..color = Colors.white.withOpacity(opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, sparkle.size * AppConstants.sparkleMainBlurMultiplier);
        canvas.drawCircle(
          Offset(x, y),
          sparkle.size,
          _sparklePaint,
        );

        // Center bright point
        _centerPaint.color = Colors.white.withOpacity(opacity * AppConstants.sparkleCenterOpacityMultiplier);
        canvas.drawCircle(
          Offset(x, y),
          sparkle.size * AppConstants.sparkleCenterSizeMultiplier,
          _centerPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_MagicDustPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.elapsedTime != elapsedTime ||
        oldDelegate.baseColor != baseColor ||
        (oldDelegate.normalizedScrollPosition - normalizedScrollPosition).abs() > 0.01; // Repaint on significant scroll change (1% threshold)
  }
}

