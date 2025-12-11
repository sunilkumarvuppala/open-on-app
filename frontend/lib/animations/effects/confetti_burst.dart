import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/animation_theme.dart';

/// Individual confetti particle
class ConfettiParticle {
  double x;
  double y;
  double velocityX;
  double velocityY;
  double rotation;
  double rotationSpeed;
  double size;
  final Color color;
  final ConfettiShape shape;
  
  ConfettiParticle({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
    required this.color,
    required this.shape,
  });
}

enum ConfettiShape {
  circle,
  square,
  triangle,
  star,
}

/// Elegant confetti burst painter
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;
  
  ConfettiPainter({
    required this.particles,
    required this.progress,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final opacity = _calculateOpacity(progress);
      if (opacity <= 0.01) continue;
      
      final paint = Paint()
        ..color = particle.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      
      canvas.save();
      canvas.translate(particle.x, particle.y);
      canvas.rotate(particle.rotation);
      
      switch (particle.shape) {
        case ConfettiShape.circle:
          canvas.drawCircle(Offset.zero, particle.size, paint);
          break;
        case ConfettiShape.square:
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size * 2,
              height: particle.size * 2,
            ),
            paint,
          );
          break;
        case ConfettiShape.triangle:
          _drawTriangle(canvas, particle.size, paint);
          break;
        case ConfettiShape.star:
          _drawStar(canvas, particle.size, paint);
          break;
      }
      
      canvas.restore();
    }
  }
  
  void _drawTriangle(Canvas canvas, double size, Paint paint) {
    final path = Path()
      ..moveTo(0, -size)
      ..lineTo(size, size)
      ..lineTo(-size, size)
      ..close();
    canvas.drawPath(path, paint);
  }
  
  void _drawStar(Canvas canvas, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5) - math.pi / 2;
      final outerX = math.cos(angle) * size;
      final outerY = math.sin(angle) * size;
      
      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      
      final innerAngle = angle + math.pi / 5;
      final innerX = math.cos(innerAngle) * (size * 0.4);
      final innerY = math.sin(innerAngle) * (size * 0.4);
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }
  
  double _calculateOpacity(double progress) {
    if (progress < 0.1) {
      return progress / 0.1;
    } else if (progress > 0.7) {
      return (1.0 - progress) / 0.3;
    }
    return 1.0;
  }
  
  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

/// Elegant confetti burst effect widget
class ConfettiBurst extends StatefulWidget {
  final bool isActive;
  final int particleCount;
  final VoidCallback? onComplete;
  
  const ConfettiBurst({
    super.key,
    this.isActive = false,
    this.particleCount = 50,
    this.onComplete,
  });
  
  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<ConfettiParticle> _particles;
  final math.Random _random = math.Random();
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.onComplete != null) {
        widget.onComplete!();
      }
    });
    
    _initializeParticles();
    
    // Start animation if active
    if (widget.isActive) {
      _controller.forward();
    }
  }
  
  @override
  void didUpdateWidget(ConfettiBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _initializeParticles();
      _controller.forward(from: 0);
    }
  }
  
  void _initializeParticles() {
    final elegantColors = [
      AnimationTheme.goldLight,
      AnimationTheme.goldPremium,
      AnimationTheme.goldShimmer,
      AnimationTheme.purpleSoft.withOpacity(0.8),
      AnimationTheme.whitePure.withOpacity(0.9),
    ];
    
    final shapes = ConfettiShape.values;
    
    _particles = List.generate(widget.particleCount, (index) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = 200.0 + _random.nextDouble() * 300.0;
      
      return ConfettiParticle(
        x: 0,
        y: 0,
        velocityX: math.cos(angle) * speed,
        velocityY: math.sin(angle) * speed - 100, // Bias upward
        rotation: _random.nextDouble() * 2 * math.pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 10,
        size: 4.0 + _random.nextDouble() * 6.0,
        color: elegantColors[_random.nextInt(elegantColors.length)],
        shape: shapes[_random.nextInt(shapes.length)],
      );
    });
  }
  
  void _updateParticles(Size size, double dt) {
    final gravity = 500.0;
    
    for (final particle in _particles) {
      // Apply physics
      particle.velocityY += gravity * dt;
      particle.x += particle.velocityX * dt;
      particle.y += particle.velocityY * dt;
      particle.rotation += particle.rotationSpeed * dt;
      
      // Add air resistance
      particle.velocityX *= 0.98;
      particle.velocityY *= 0.98;
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Start animation when widget becomes active
    if (widget.isActive && _controller.status == AnimationStatus.dismissed) {
      _controller.forward();
    }
    
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              _updateParticles(constraints.biggest, 1 / 60);
              
              // Translate particles to center of screen
              final centerX = constraints.maxWidth / 2;
              final centerY = constraints.maxHeight / 2;
              
              final translatedParticles = _particles.map((p) {
                return ConfettiParticle(
                  x: centerX + p.x,
                  y: centerY + p.y,
                  velocityX: p.velocityX,
                  velocityY: p.velocityY,
                  rotation: p.rotation,
                  rotationSpeed: p.rotationSpeed,
                  size: p.size,
                  color: p.color,
                  shape: p.shape,
                );
              }).toList();
              
              return CustomPaint(
                size: constraints.biggest,
                painter: ConfettiPainter(
                  particles: translatedParticles,
                  progress: _controller.value,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

