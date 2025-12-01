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

  @override
  void initState() {
    super.initState();
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

    // Initialize sparkles (animated)
    for (int i = 0; i < AppConstants.magicDustSparkleCount; i++) {
      _sparkles.add(_Sparkle(
        x: random.nextDouble(),
        y: random.nextDouble() * AppConstants.magicDustHeaderAreaRatio,
        size: 1.5 + random.nextDouble() * 2,
        phase: random.nextDouble() * 2 * math.pi,
        delay: random.nextDouble() * 2 * math.pi,
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
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _MagicDustPainter(
                      particles: _particles,
                      sparkles: _sparkles,
                      baseColor: widget.baseColor,
                      animationValue: _animationController.value,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
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

/// Sparkle data for animated sparkles
class _Sparkle {
  final double x;
  final double y;
  final double size;
  final double phase;
  final double delay;

  _Sparkle({
    required this.x,
    required this.y,
    required this.size,
    required this.phase,
    required this.delay,
  });
}

/// Custom painter for magic dust effect
class _MagicDustPainter extends CustomPainter {
  final List<_Particle> particles;
  final List<_Sparkle> sparkles;
  final Color baseColor;
  final double animationValue;

  _MagicDustPainter({
    required this.particles,
    required this.sparkles,
    required this.baseColor,
    required this.animationValue,
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

    // Draw animated sparkles (opacity animation 0 → 1)
    for (final sparkle in sparkles) {
      final x = sparkle.x * size.width;
      final y = sparkle.y * size.height;
      
      // Slow opacity animation (0 → 1 → 0)
      final opacityCycle = (math.sin(animationValue * 2 * math.pi + sparkle.delay) + 1) / 2;
      final opacity = opacityCycle * AppConstants.sparkleMaxOpacity;
      
      if (opacity > AppConstants.sparkleMinVisibleOpacity) {
        // Outer glow
        _glowPaint
          ..color = Colors.white.withOpacity(opacity * 0.3)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, sparkle.size * 3);
        canvas.drawCircle(
          Offset(x, y),
          sparkle.size * 1.5,
          _glowPaint,
        );

        // Main sparkle
        _sparklePaint
          ..color = Colors.white.withOpacity(opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, sparkle.size * 0.5);
        canvas.drawCircle(
          Offset(x, y),
          sparkle.size,
          _sparklePaint,
        );

        // Center bright point
        _centerPaint.color = Colors.white.withOpacity(opacity * 1.2);
        canvas.drawCircle(
          Offset(x, y),
          sparkle.size * 0.3,
          _centerPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_MagicDustPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.baseColor != baseColor;
  }
}

