import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';

class OpeningAnimationScreen extends ConsumerStatefulWidget {
  final String capsuleId;

  const OpeningAnimationScreen({
    super.key,
    required this.capsuleId,
  });

  @override
  ConsumerState<OpeningAnimationScreen> createState() => _OpeningAnimationScreenState();
}

class _OpeningAnimationScreenState extends ConsumerState<OpeningAnimationScreen>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late AnimationController _openController;
  late AnimationController _revealController;
  
  late Animation<double> _shakeAnimation;
  late Animation<double> _sealAnimation;
  late Animation<double> _envelopeOpenAnimation;
  late Animation<double> _letterRiseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimation();
  }

  void _initAnimations() {
    // Shake animation (0-1s)
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // Open animation (1-3s)
    _openController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _sealAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _openController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
    
    _envelopeOpenAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _openController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeInOut),
      ),
    );

    // Reveal animation (3-4s)
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _letterRiseAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.easeOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.easeIn),
    );
  }

  Future<void> _startAnimation() async {
    // Mark as opened
    try {
      final repo = ref.read(capsuleRepositoryProvider);
      await repo.markAsOpened(widget.capsuleId);
      ref.invalidate(capsuleProvider(widget.capsuleId));
      ref.invalidate(sentCapsulesProvider);
    } catch (e) {
      // Continue with animation even if marking fails
      debugPrint('Failed to mark as opened: $e');
    }

    // Play animations in sequence
    await _shakeController.forward();
    await _openController.forward();
    await _revealController.forward();
    
    // Navigate to opened letter after delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      context.go('/capsule/${widget.capsuleId}/opened');
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _openController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.dreamyGradient,
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _shakeController,
                _openController,
                _revealController,
              ]),
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    _shakeAnimation.value * 10 * (1 - _shakeAnimation.value),
                    0,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Envelope
                      Transform.rotate(
                        angle: _envelopeOpenAnimation.value * 0.3,
                        child: Opacity(
                          opacity: 1 - (_letterRiseAnimation.value * 0.5),
                          child: Icon(
                            Icons.mail,
                            size: 200,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                      
                      // Seal (disappears first)
                      if (_sealAnimation.value > 0)
                        Positioned(
                          top: 80,
                          child: Opacity(
                            opacity: _sealAnimation.value,
                            child: Transform.scale(
                              scale: _sealAnimation.value,
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.softGold.withOpacity(0.8),
                                ),
                                child: const Icon(
                                  Icons.favorite,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ),
                      
                      // Letter rising
                      if (_letterRiseAnimation.value > 0)
                        Transform.translate(
                          offset: Offset(
                            0,
                            -_letterRiseAnimation.value * 100,
                          ),
                          child: Opacity(
                            opacity: _fadeAnimation.value,
                            child: Transform.scale(
                              scale: 0.5 + (_letterRiseAnimation.value * 0.5),
                              child: Container(
                                width: 200,
                                height: 260,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.favorite,
                                  size: 80,
                                  color: AppTheme.pastelPink,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
