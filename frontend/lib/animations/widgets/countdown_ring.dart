import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/animation_theme.dart';
import 'sparkle_particle_engine.dart';

/// Circular countdown ring with gradient and shimmer
class CountdownRing extends StatefulWidget {
  final Duration remaining;
  final Duration total;
  final double size;
  final double strokeWidth;
  final VoidCallback? onComplete;
  
  const CountdownRing({
    super.key,
    required this.remaining,
    required this.total,
    this.size = 120,
    this.strokeWidth = 8,
    this.onComplete,
  });
  
  @override
  State<CountdownRing> createState() => _CountdownRingState();
}

class _CountdownRingState extends State<CountdownRing>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  
  bool _showParticles = false;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkUrgency();
  }
  
  void _initializeAnimations() {
    // Shimmer rotation
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    
    _shimmerAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      _shimmerController,
    );
    
    // Pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Glow intensity
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  void _checkUrgency() {
    // Show particles when less than 7 days
    final daysLeft = widget.remaining.inDays;
    if (daysLeft <= 7 && !_showParticles) {
      setState(() => _showParticles = true);
    }
  }
  
  @override
  void didUpdateWidget(CountdownRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkUrgency();
    
    // Check if countdown completed
    if (widget.remaining.inSeconds <= 0 &&
        oldWidget.remaining.inSeconds > 0 &&
        widget.onComplete != null) {
      widget.onComplete!();
    }
  }
  
  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final progress = 1.0 -
        (widget.remaining.inSeconds / widget.total.inSeconds).clamp(0.0, 1.0);
    
    final daysLeft = widget.remaining.inDays;
    final hoursLeft = widget.remaining.inHours % 24;
    final minutesLeft = widget.remaining.inMinutes % 60;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _glowController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _showParticles ? _pulseAnimation.value : 1.0,
          child: child,
        );
      },
      child: SparkleParticleEngine(
        isActive: _showParticles,
        mode: SparkleMode.orbit,
        particleCount: 12,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AnimationTheme.goldLight.withOpacity(
                  _showParticles ? _glowAnimation.value * 0.6 : 0.3,
                ),
                blurRadius: _showParticles ? 25 : 15,
                spreadRadius: _showParticles ? 5 : 2,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Countdown ring
              AnimatedBuilder(
                animation: _shimmerAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: CountdownRingPainter(
                      progress: progress,
                      strokeWidth: widget.strokeWidth,
                      shimmerProgress: _shimmerAnimation.value,
                      glowIntensity: _showParticles ? _glowAnimation.value : 0.5,
                    ),
                  );
                },
              ),
              
              // Time display
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (daysLeft > 0)
                    _buildTimeText('$daysLeft', 'days')
                  else if (hoursLeft > 0)
                    _buildTimeText('$hoursLeft', 'hours')
                  else
                    _buildTimeText('$minutesLeft', 'min'),
                  
                  if (_showParticles) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Very Soon!',
                      style: TextStyle(
                        color: AnimationTheme.goldLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTimeText(String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: AnimationTheme.goldLight,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: AnimationTheme.goldLight.withOpacity(0.5),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            color: AnimationTheme.goldPremium,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Countdown ring painter with gradient and shimmer
class CountdownRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final double shimmerProgress;
  final double glowIntensity;
  
  CountdownRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.shimmerProgress,
    required this.glowIntensity,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // Background track
    final bgPaint = Paint()
      ..color = AnimationTheme.navyMedium.withOpacity(0.3)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, bgPaint);
    
    // Progress arc with gradient
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    final gradientPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          AnimationTheme.goldPremium,
          AnimationTheme.goldLight,
          AnimationTheme.goldShimmer,
          AnimationTheme.goldPremium,
        ],
        stops: const [0.0, 0.4, 0.6, 1.0],
        transform: GradientRotation(shimmerProgress),
      ).createShader(rect)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweepAngle,
      false,
      gradientPaint,
    );
    
    // Glow effect on progress
    if (glowIntensity > 0) {
      final glowPaint = Paint()
        ..color = AnimationTheme.goldLight.withOpacity(glowIntensity * 0.3)
        ..strokeWidth = strokeWidth + 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      
      canvas.drawArc(
        rect,
        -math.pi / 2,
        sweepAngle,
        false,
        glowPaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(CountdownRingPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        shimmerProgress != oldDelegate.shimmerProgress ||
        glowIntensity != oldDelegate.glowIntensity;
  }
}

