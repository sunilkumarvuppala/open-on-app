import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/animation_theme.dart';
import '../painters/mist_painter.dart';
import 'sparkle_particle_engine.dart';

/// Epic unfolding (coming soon) card animation
/// Features: envelope opening, sparkles, mist, vortex, orbit particles
class UnfoldingCardAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isUnfolding;
  
  const UnfoldingCardAnimation({
    super.key,
    required this.child,
    this.onTap,
    this.isUnfolding = true,
  });
  
  @override
  State<UnfoldingCardAnimation> createState() => _UnfoldingCardAnimationState();
}

class _UnfoldingCardAnimationState extends State<UnfoldingCardAnimation>
    with TickerProviderStateMixin {
  late AnimationController _bobController;
  late AnimationController _envelopeController;
  late AnimationController _vortexController;
  late AnimationController _pulseController;
  
  late Animation<double> _bobAnimation;
  late Animation<double> _envelopeAnimation;
  late Animation<double> _vortexAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }
  
  void _initializeAnimations() {
    // Gentle vertical bobbing
    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _bobAnimation = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(
        parent: _bobController,
        curve: Curves.easeInOutSine,
      ),
    );
    
    // Envelope opening illusion
    _envelopeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _envelopeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _envelopeController,
        curve: Curves.easeInOutCubic,
      ),
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.08).animate(
      CurvedAnimation(
        parent: _envelopeController,
        curve: Curves.easeInOutSine,
      ),
    );
    
    // Magical vortex swirl
    _vortexController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _vortexAnimation = Tween<double>(begin: 0, end: 1).animate(
      _vortexController,
    );
    
    // Pulsing glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  void _startAnimations() {
    _bobController.repeat(reverse: true);
    _envelopeController.repeat(reverse: true);
    _vortexController.repeat();
    _pulseController.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _bobController.dispose();
    _envelopeController.dispose();
    _vortexController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _bobController,
          _envelopeController,
          _pulseController,
        ]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -_bobAnimation.value),
            child: child,
          );
        },
        child: Stack(
          children: [
            // Vortex swirl background
            AnimatedBuilder(
              animation: _vortexController,
              builder: (context, child) {
                return CustomPaint(
                  painter: VortexPainter(
                    progress: _vortexAnimation.value,
                    intensity: 0.4,
                  ),
                  child: child,
                );
              },
              child: const SizedBox.expand(),
            ),
            
            // Golden mist layer
            MagicalMist(
              isActive: widget.isUnfolding,
              intensity: 0.7,
              child: SparkleParticleEngine(
                isActive: widget.isUnfolding,
                mode: SparkleMode.drift,
                particleCount: 30,
                child: AnimatedBuilder(
                  animation: _envelopeController,
                  builder: (context, child) {
                    // Envelope opening perspective effect
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001) // Perspective
                        ..rotateX(_rotationAnimation.value * math.pi),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            // Magical glow shadow
                            BoxShadow(
                              color: AnimationTheme.goldLight
                                  .withOpacity(_pulseAnimation.value * 0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                            // Depth shadow
                            BoxShadow(
                              color: AnimationTheme.navyDeep.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            children: [
                              // Main card content
                              widget.child,
                              
                              // Envelope flap overlay
                              _buildEnvelopeFlap(),
                              
                              // Orbit particles
                              _buildOrbitParticles(),
                              
                              // "Coming Soon" badge with glow
                              Positioned(
                                top: 16,
                                right: 16,
                                child: _buildComingSoonBadge(),
                              ),
                            ],
                          ),
                        ),
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
  
  Widget _buildEnvelopeFlap() {
    return AnimatedBuilder(
      animation: _envelopeAnimation,
      builder: (context, child) {
        final flapOpen = _envelopeAnimation.value;
        
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ClipPath(
            clipper: EnvelopeFlapClipper(openAmount: flapOpen),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AnimationTheme.goldPremium.withOpacity(0.2 * (1 - flapOpen)),
                    AnimationTheme.goldShimmer.withOpacity(0.1 * (1 - flapOpen)),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildOrbitParticles() {
    return SparkleParticleEngine(
      isActive: widget.isUnfolding,
      mode: SparkleMode.orbit,
      particleCount: 8,
      child: const SizedBox.expand(),
    );
  }
  
  Widget _buildComingSoonBadge() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AnimationTheme.goldLight.withOpacity(_pulseAnimation.value),
                AnimationTheme.goldPremium.withOpacity(_pulseAnimation.value * 0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AnimationTheme.goldLight
                    .withOpacity(_pulseAnimation.value * 0.5),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: AnimationTheme.navyDeep
                    .withOpacity(_pulseAnimation.value),
              ),
              const SizedBox(width: 6),
              Text(
                'Coming Soon',
                style: TextStyle(
                  color: AnimationTheme.navyDeep
                      .withOpacity(_pulseAnimation.value),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom clipper for envelope flap effect
class EnvelopeFlapClipper extends CustomClipper<Path> {
  final double openAmount;
  
  EnvelopeFlapClipper({required this.openAmount});
  
  @override
  Path getClip(Size size) {
    final path = Path();
    
    // Create triangular flap that opens upward
    final flapHeight = size.height * (1 - openAmount);
    
    path.moveTo(0, flapHeight);
    path.lineTo(size.width / 2, 0);
    path.lineTo(size.width, flapHeight);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    return path;
  }
  
  @override
  bool shouldReclip(EnvelopeFlapClipper oldClipper) {
    return openAmount != oldClipper.openAmount;
  }
}

/// Magical vortex swirl painter
class VortexPainter extends CustomPainter {
  final double progress;
  final double intensity;
  
  VortexPainter({
    required this.progress,
    this.intensity = 1.0,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height) / 2;
    
    // Draw multiple swirl rings
    for (int ring = 0; ring < 5; ring++) {
      final ringProgress = (progress + ring * 0.2) % 1.0;
      final radius = maxRadius * ringProgress;
      
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..shader = SweepGradient(
          colors: [
            AnimationTheme.goldLight.withOpacity(0.0),
            AnimationTheme.goldLight.withOpacity(intensity * 0.3 * (1 - ringProgress)),
            AnimationTheme.goldShimmer.withOpacity(intensity * 0.2 * (1 - ringProgress)),
            AnimationTheme.goldLight.withOpacity(0.0),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
          transform: GradientRotation(progress * math.pi * 2),
        ).createShader(Rect.fromCircle(
          center: Offset(centerX, centerY),
          radius: radius,
        ));
      
      canvas.drawCircle(
        Offset(centerX, centerY),
        radius,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(VortexPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

