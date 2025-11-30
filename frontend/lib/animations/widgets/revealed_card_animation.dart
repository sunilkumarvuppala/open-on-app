import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/animation_theme.dart';
import '../effects/confetti_burst.dart';
import '../effects/glow_effect.dart';
import 'sparkle_particle_engine.dart';

/// Epic revealed card animation with burst, glow, confetti
class RevealedCardAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onRevealComplete;
  final bool autoReveal;
  
  const RevealedCardAnimation({
    super.key,
    required this.child,
    this.onRevealComplete,
    this.autoReveal = false,
  });
  
  @override
  State<RevealedCardAnimation> createState() => _RevealedCardAnimationState();
}

class _RevealedCardAnimationState extends State<RevealedCardAnimation>
    with TickerProviderStateMixin {
  late AnimationController _masterController;
  late AnimationController _envelopeController;
  late AnimationController _contentController;
  late AnimationController _backgroundController;
  
  late Animation<double> _envelopeOpenAnimation;
  late Animation<double> _envelopeRotateAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<double> _contentSlideAnimation;
  late Animation<double> _backgroundExpandAnimation;
  
  bool _showConfetti = false;
  bool _showFlash = false;
  bool _isRevealing = false;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    
    if (widget.autoReveal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerReveal();
      });
    }
  }
  
  void _initializeAnimations() {
    // Master controller for sequencing
    _masterController = AnimationController(
      vsync: this,
      duration: AnimationTheme.epicAnimation,
    );
    
    // Envelope opening (hinged animation)
    _envelopeController = AnimationController(
      vsync: this,
      duration: AnimationTheme.cinematicAnimation,
    );
    
    _envelopeOpenAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _envelopeController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );
    
    _envelopeRotateAnimation = Tween<double>(begin: 0.0, end: -0.3).animate(
      CurvedAnimation(
        parent: _envelopeController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    // Content fade in
    _contentController = AnimationController(
      vsync: this,
      duration: AnimationTheme.standardAnimation,
    );
    
    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: Curves.easeIn,
      ),
    );
    
    _contentSlideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    // Background gradient expand
    _backgroundController = AnimationController(
      vsync: this,
      duration: AnimationTheme.slowAnimation,
    );
    
    _backgroundExpandAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: Curves.easeOut,
      ),
    );
  }
  
  Future<void> _triggerReveal() async {
    if (_isRevealing) return;
    
    setState(() {
      _isRevealing = true;
    });
    
    // Sequence of animations for maximum impact
    // 1. Flash glow
    setState(() => _showFlash = true);
    HapticFeedback.mediumImpact();
    
    await Future.delayed(const Duration(milliseconds: 50));
    
    // 2. Confetti burst
    setState(() => _showConfetti = true);
    HapticFeedback.lightImpact();
    
    // 3. Envelope opens
    _envelopeController.forward();
    
    await Future.delayed(const Duration(milliseconds: 200));
    
    // 4. Background expands
    _backgroundController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    
    // 5. Content fades in
    _contentController.forward();
    
    await Future.delayed(const Duration(milliseconds: 400));
    
    // Success haptic
    HapticFeedback.heavyImpact();
    
    // Notify completion
    if (widget.onRevealComplete != null) {
      widget.onRevealComplete!();
    }
  }
  
  @override
  void dispose() {
    _masterController.dispose();
    _envelopeController.dispose();
    _contentController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.autoReveal ? null : _triggerReveal,
        child: Stack(
        children: [
          // Background radial gradient
          AnimatedBuilder(
            animation: _backgroundExpandAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0 * _backgroundExpandAnimation.value,
                    colors: [
                      AnimationTheme.purpleSoft.withOpacity(
                        0.2 * _backgroundExpandAnimation.value,
                      ),
                      AnimationTheme.navyMedium.withOpacity(
                        0.1 * _backgroundExpandAnimation.value,
                      ),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              );
            },
          ),
          
          // Sparkle background
          RepaintBoundary(
            child: SparkleParticleEngine(
              isActive: _isRevealing,
              mode: SparkleMode.burst,
              particleCount: 30, // Reduced from 40 for better performance
              child: FlashGlow(
              trigger: _showFlash,
              child: GlowEffect(
                isActive: _isRevealing,
                color: AnimationTheme.goldLight,
                duration: AnimationTheme.cinematicAnimation,
                child: AnimatedBuilder(
                  animation: _envelopeController,
                  builder: (context, child) {
                    return _buildEnvelopeAnimation(child!);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AnimationTheme.goldLight.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 3,
                        ),
                        BoxShadow(
                          color: AnimationTheme.navyDeep.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: AnimatedBuilder(
                        animation: _contentController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _contentFadeAnimation.value,
                            child: Transform.translate(
                              offset: Offset(0, _contentSlideAnimation.value),
                              child: child,
                            ),
                          );
                        },
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          ),
          
          // Confetti layer (on top)
          if (_showConfetti)
            Positioned.fill(
              child: IgnorePointer(
                child: ConfettiBurst(
                  isActive: _showConfetti,
                  particleCount: 60,
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }
  
  Widget _buildEnvelopeAnimation(Widget child) {
    // Envelope opening with hinged rotation
    return Stack(
      children: [
        // Main card
        child,
        
        // Envelope flap
        ClipPath(
          clipper: EnvelopeTopFlapClipper(
            openAmount: _envelopeOpenAnimation.value,
          ),
          child: Transform(
            alignment: Alignment.topCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspective
              ..rotateX(_envelopeRotateAnimation.value),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AnimationTheme.goldPremium.withOpacity(
                      0.8 * (1 - _envelopeOpenAnimation.value),
                    ),
                    AnimationTheme.goldLight.withOpacity(
                      0.4 * (1 - _envelopeOpenAnimation.value),
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Clipper for envelope top flap
class EnvelopeTopFlapClipper extends CustomClipper<Path> {
  final double openAmount;
  
  EnvelopeTopFlapClipper({required this.openAmount});
  
  @override
  Path getClip(Size size) {
    final path = Path();
    final flapHeight = size.height * 0.3 * (1 - openAmount);
    
    // Create triangular flap
    path.moveTo(0, flapHeight);
    path.lineTo(size.width / 2, 0);
    path.lineTo(size.width, flapHeight);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    return path;
  }
  
  @override
  bool shouldReclip(EnvelopeTopFlapClipper oldClipper) {
    return openAmount != oldClipper.openAmount;
  }
}

