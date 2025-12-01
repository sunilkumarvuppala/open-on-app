import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:openon_app/core/constants/app_constants.dart';
import '../theme/animation_theme.dart';

/// Individual sparkle particle data
class Sparkle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;
  double angle;
  double lifetime;
  final Color color;
  
  Sparkle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.angle,
    required this.lifetime,
    required this.color,
  });
}

/// High-performance sparkle particle painter
class SparklePainter extends CustomPainter {
  final List<Sparkle> sparkles;
  final double animationValue;
  final double canvasWidth;
  final double canvasHeight;
  
  // Reusable Paint objects to avoid allocation
  final Paint _sparklePaint = Paint()..style = PaintingStyle.fill;
  final Path _starPath = Path();
  
  SparklePainter({
    required this.sparkles,
    required this.animationValue,
    required this.canvasWidth,
    required this.canvasHeight,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    for (final sparkle in sparkles) {
      // Calculate fade curve for elegant appearance/disappearance
      final fadeCurve = _calculateFadeCurve(sparkle.lifetime);
      final currentOpacity = sparkle.opacity * fadeCurve;
      
      if (currentOpacity <= 0.01) continue;
      
      // Reuse paint object
      _sparklePaint
        ..color = sparkle.color.withOpacity(currentOpacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sparkle.size * 0.5);
      
      // Convert normalized coordinates to actual pixels
      final x = sparkle.x * canvasWidth;
      final y = sparkle.y * canvasHeight;
      
      // Draw star-shaped sparkle
      _drawStar(canvas, x, y, sparkle.size, _sparklePaint);
    }
  }
  
  /// Calculate elegant fade curve (fade in quick, fade out slow)
  double _calculateFadeCurve(double lifetime) {
    if (lifetime < 0.2) {
      // Fast fade in
      return lifetime / 0.2;
    } else if (lifetime > 0.8) {
      // Slow fade out
      return (1.0 - lifetime) / 0.2;
    }
    return 1.0;
  }
  
  /// Draw a 4-pointed star sparkle
  void _drawStar(Canvas canvas, double x, double y, double size, Paint paint) {
    _starPath.reset();
    
    // Create 4-pointed star
    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2);
      final outerX = x + math.cos(angle) * size;
      final outerY = y + math.sin(angle) * size;
      
      if (i == 0) {
        _starPath.moveTo(outerX, outerY);
      } else {
        _starPath.lineTo(outerX, outerY);
      }
      
      // Inner point (between outer points)
      final innerAngle = angle + (math.pi / 4);
      final innerX = x + math.cos(innerAngle) * (size * 0.3);
      final innerY = y + math.sin(innerAngle) * (size * 0.3);
      _starPath.lineTo(innerX, innerY);
    }
    
    _starPath.close();
    canvas.drawPath(_starPath, paint);
    
    // Add center glow
    final glowMask = MaskFilter.blur(BlurStyle.normal, size);
    canvas.drawCircle(
      Offset(x, y),
      size * 0.3,
      paint..maskFilter = glowMask,
    );
  }
  
  @override
  bool shouldRepaint(SparklePainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}

/// Reusable sparkle particle engine widget
class SparkleParticleEngine extends StatefulWidget {
  final Widget child;
  final int particleCount;
  final bool isActive;
  final SparkleMode mode;
  final Color? primaryColor;
  final Color? secondaryColor;
  
  const SparkleParticleEngine({
    super.key,
    required this.child,
    this.particleCount = AnimationTheme.sparkleCount,
    this.isActive = true,
    this.mode = SparkleMode.drift,
    this.primaryColor,
    this.secondaryColor,
  });
  
  @override
  State<SparkleParticleEngine> createState() => _SparkleParticleEngineState();
}

enum SparkleMode {
  drift,        // Gentle upward drift
  orbit,        // Circular orbit around center
  burst,        // Explosive burst outward
  rain,         // Falling sparkles
}

class _SparkleParticleEngineState extends State<SparkleParticleEngine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Sparkle> _sparkles;
  final math.Random _random = math.Random();
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.sparkleAnimationDuration,
    )..repeat();
    
    _initializeSparkles();
  }
  
  void _initializeSparkles() {
    _sparkles = List.generate(widget.particleCount, (index) {
      return _createSparkle();
    });
  }
  
  Sparkle _createSparkle() {
    final colorPalette = [
      widget.primaryColor ?? AnimationTheme.goldLight,
      widget.secondaryColor ?? AnimationTheme.goldShimmer,
      AnimationTheme.whitePure,
    ];
    
    return Sparkle(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      size: AnimationTheme.sparkleMinSize +
          _random.nextDouble() *
              (AnimationTheme.sparkleMaxSize - AnimationTheme.sparkleMinSize),
      speed: 0.5 + _random.nextDouble() * 1.5,
      opacity: 0.4 + _random.nextDouble() * 0.6,
      angle: _random.nextDouble() * 2 * math.pi,
      lifetime: _random.nextDouble(),
      color: colorPalette[_random.nextInt(colorPalette.length)],
    );
  }
  
  void _updateSparkles(Size size) {
    // Use constant frame time for consistent animation speed
    final dt = AppConstants.frameTime;
    
    for (int i = 0; i < _sparkles.length; i++) {
      final sparkle = _sparkles[i];
      
      // Update lifetime
      sparkle.lifetime += dt * 0.3;
      if (sparkle.lifetime >= 1.0) {
        _sparkles[i] = _createSparkle();
        continue;
      }
      
      // Update position based on mode
      switch (widget.mode) {
        case SparkleMode.drift:
          _updateDriftMode(sparkle, size, dt);
          break;
        case SparkleMode.orbit:
          _updateOrbitMode(sparkle, size, dt);
          break;
        case SparkleMode.burst:
          _updateBurstMode(sparkle, size, dt);
          break;
        case SparkleMode.rain:
          _updateRainMode(sparkle, size, dt);
          break;
      }
    }
  }
  
  void _updateDriftMode(Sparkle sparkle, Size size, double dt) {
    // Gentle upward drift with slight horizontal sway
    sparkle.y -= (sparkle.speed * AnimationTheme.sparkleDriftSpeed * dt) / size.height;
    sparkle.x += math.sin(sparkle.lifetime * math.pi * 2) * 0.001;
    
    // Wrap around
    if (sparkle.y < -0.1) {
      sparkle.y = 1.1;
      sparkle.x = _random.nextDouble();
    }
  }
  
  void _updateOrbitMode(Sparkle sparkle, Size size, double dt) {
    // Circular orbit around center
    final centerX = 0.5;
    final centerY = 0.5;
    final radius = 0.3 + (sparkle.speed * 0.1);
    
    sparkle.angle += sparkle.speed * dt;
    sparkle.x = centerX + math.cos(sparkle.angle) * radius;
    sparkle.y = centerY + math.sin(sparkle.angle) * radius;
  }
  
  void _updateBurstMode(Sparkle sparkle, Size size, double dt) {
    // Explosive outward burst from center
    final centerX = 0.5;
    final centerY = 0.5;
    
    final dx = sparkle.x - centerX;
    final dy = sparkle.y - centerY;
    
    sparkle.x += dx * sparkle.speed * dt * 2;
    sparkle.y += dy * sparkle.speed * dt * 2;
  }
  
  void _updateRainMode(Sparkle sparkle, Size size, double dt) {
    // Falling sparkles
    sparkle.y += (sparkle.speed * AnimationTheme.sparkleDriftSpeed * dt) / size.height;
    sparkle.x += math.sin(sparkle.lifetime * math.pi * 4) * 0.001;
    
    if (sparkle.y > 1.1) {
      sparkle.y = -0.1;
      sparkle.x = _random.nextDouble();
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          if (!widget.isActive) {
            return child!;
          }
          
          return Stack(
            children: [
              child!,
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _updateSparkles(constraints.biggest);
                    
                    return CustomPaint(
                      painter: SparklePainter(
                        sparkles: _sparkles,
                        animationValue: _controller.value,
                        canvasWidth: constraints.maxWidth,
                        canvasHeight: constraints.maxHeight,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}

