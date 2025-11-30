import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/animation_theme.dart';
import '../painters/shimmer_painter.dart';

/// Sealed (locked) card state with premium animations
class SealedCardAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isLocked;
  
  const SealedCardAnimation({
    super.key,
    required this.child,
    this.onTap,
    this.isLocked = true,
  });
  
  @override
  State<SealedCardAnimation> createState() => _SealedCardAnimationState();
}

class _SealedCardAnimationState extends State<SealedCardAnimation>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _breatheController;
  late AnimationController _glowController;
  late AnimationController _shakeController;
  
  late Animation<double> _floatAnimation;
  late Animation<double> _breatheAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _shakeAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }
  
  void _initializeAnimations() {
    // Floating animation - gentle up and down
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _floatAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOutSine,
      ),
    );
    
    // Breathing animation - subtle scale pulse
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _breatheAnimation = Tween<double>(begin: 0.98, end: 1.0).animate(
      CurvedAnimation(
        parent: _breatheController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Glow animation - locked icon pulse
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Shake animation - for locked tap feedback
    _shakeController = AnimationController(
      vsync: this,
      duration: AnimationTheme.quickAnimation,
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticOut,
    ));
  }
  
  void _startAnimations() {
    _floatController.repeat(reverse: true);
    _breatheController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
  }
  
  void _handleTap() {
    if (widget.isLocked) {
      // Locked feedback - shake and haptic
      HapticFeedback.mediumImpact();
      _shakeController.forward(from: 0);
    } else if (widget.onTap != null) {
      widget.onTap!();
    }
  }
  
  @override
  void dispose() {
    _floatController.dispose();
    _breatheController.dispose();
    _glowController.dispose();
    _shakeController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _floatController,
          _breatheController,
          _shakeController,
        ]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              _shakeAnimation.value,
              -_floatAnimation.value,
            ),
            child: Transform.scale(
              scale: _breatheAnimation.value,
              child: child,
            ),
          );
        },
        child: ShimmerEffect(
          duration: const Duration(milliseconds: 2500),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                // Soft shadow for depth
                BoxShadow(
                  color: AnimationTheme.navyDeep.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Main card content
                  widget.child,
                  
                  // Paper texture overlay
                  Positioned.fill(
                    child: AnimatedOpacity(
                      opacity: widget.isLocked ? 0.03 : 0.0,
                      duration: AnimationTheme.standardAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.05),
                              Colors.transparent,
                              Colors.white.withOpacity(0.02),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Locked icon with glow
                  if (widget.isLocked)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: AnimatedBuilder(
                        animation: _glowController,
                        builder: (context, child) {
                          return Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AnimationTheme.goldLight
                                      .withOpacity(_glowAnimation.value * 0.6),
                                  blurRadius: 16,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.lock_rounded,
                              color: AnimationTheme.goldLight
                                  .withOpacity(_glowAnimation.value),
                              size: 24,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

