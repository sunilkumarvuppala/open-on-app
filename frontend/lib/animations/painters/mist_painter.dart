import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/animation_theme.dart';

/// Magical golden mist effect using blur shader
class MistPainter extends CustomPainter {
  final double animationValue;
  final double intensity;
  final List<MistParticle> particles;
  
  MistPainter({
    required this.animationValue,
    this.intensity = 1.0,
    required this.particles,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final opacity = _calculateOpacity(particle);
      if (opacity <= 0.01) continue;
      
      final paint = Paint()
        ..color = particle.color.withOpacity(opacity * intensity)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          particle.size * 2,
        );
      
      // Draw soft circles for mist effect
      canvas.drawCircle(
        Offset(
          particle.x * size.width,
          particle.y * size.height,
        ),
        particle.size,
        paint,
      );
    }
  }
  
  double _calculateOpacity(MistParticle particle) {
    // Gentle fade in and out
    final lifecycle = particle.lifecycle;
    if (lifecycle < 0.2) {
      return lifecycle / 0.2 * particle.baseOpacity;
    } else if (lifecycle > 0.7) {
      return (1.0 - lifecycle) / 0.3 * particle.baseOpacity;
    }
    return particle.baseOpacity;
  }
  
  @override
  bool shouldRepaint(MistPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}

/// Individual mist particle data
class MistParticle {
  double x;
  double y;
  double size;
  double speed;
  double baseOpacity;
  double lifecycle;
  double angle;
  final Color color;
  
  MistParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.baseOpacity,
    required this.lifecycle,
    required this.angle,
    required this.color,
  });
}

/// Magical mist effect widget
class MagicalMist extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final int particleCount;
  final double intensity;
  
  const MagicalMist({
    super.key,
    required this.child,
    this.isActive = true,
    this.particleCount = 15,
    this.intensity = 1.0,
  });
  
  @override
  State<MagicalMist> createState() => _MagicalMistState();
}

class _MagicalMistState extends State<MagicalMist>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<MistParticle> _particles;
  final math.Random _random = math.Random();
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    
    _initializeParticles();
  }
  
  void _initializeParticles() {
    final mistColors = [
      AnimationTheme.goldShimmer.withOpacity(0.3),
      AnimationTheme.goldLight.withOpacity(0.2),
      AnimationTheme.purpleSoft.withOpacity(0.15),
    ];
    
    _particles = List.generate(widget.particleCount, (index) {
      return MistParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 20.0 + _random.nextDouble() * 40.0,
        speed: 0.3 + _random.nextDouble() * 0.7,
        baseOpacity: 0.1 + _random.nextDouble() * 0.2,
        lifecycle: _random.nextDouble(),
        angle: _random.nextDouble() * 2 * math.pi,
        color: mistColors[_random.nextInt(mistColors.length)],
      );
    });
  }
  
  void _updateParticles(double dt) {
    for (int i = 0; i < _particles.length; i++) {
      final particle = _particles[i];
      
      // Update lifecycle
      particle.lifecycle += dt * 0.15;
      if (particle.lifecycle >= 1.0) {
        // Reset particle
        particle.lifecycle = 0.0;
        particle.x = _random.nextDouble();
        particle.y = _random.nextDouble();
      }
      
      // Gentle swirling motion
      final swirl = math.sin(particle.lifecycle * math.pi * 2) * 0.002;
      particle.x += swirl + (math.cos(particle.angle) * particle.speed * dt * 0.05);
      particle.y -= particle.speed * dt * 0.1;
      
      // Wrap around
      if (particle.x < -0.2) particle.x = 1.2;
      if (particle.x > 1.2) particle.x = -0.2;
      if (particle.y < -0.2) particle.y = 1.2;
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (widget.isActive) {
          _updateParticles(1 / 60);
        }
        
        return CustomPaint(
          foregroundPainter: widget.isActive
              ? MistPainter(
                  animationValue: _controller.value,
                  intensity: widget.intensity,
                  particles: _particles,
                )
              : null,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

