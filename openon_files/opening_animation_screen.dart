import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/app_theme.dart';

class OpeningAnimationScreen extends ConsumerStatefulWidget {
  final Capsule capsule;
  
  const OpeningAnimationScreen({super.key, required this.capsule});
  
  @override
  ConsumerState<OpeningAnimationScreen> createState() => _OpeningAnimationScreenState();
}

class _OpeningAnimationScreenState extends ConsumerState<OpeningAnimationScreen>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _riseController;
  
  late Animation<double> _shakeAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _riseAnimation;
  
  bool _animationComplete = false;
  
  @override
  void initState() {
    super.initState();
    
    // Shake animation (envelope shaking)
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
    
    // Fade animation (seal disappearing)
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
    // Scale animation (envelope opening)
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    
    // Rise animation (letter rising)
    _riseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _riseAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _riseController, curve: Curves.easeOut),
    );
    
    _startAnimation();
  }
  
  Future<void> _startAnimation() async {
    // Wait a moment
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Shake the envelope
    await _shakeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Fade out the seal
    await _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Scale and open envelope
    await _scaleController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Rise the letter
    await _riseController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Mark capsule as opened
    try {
      final repo = ref.read(capsuleRepositoryProvider);
      await repo.markAsOpened(widget.capsule.id);
      ref.invalidate(capsulesProvider);
    } catch (e) {
      // Continue even if marking fails
      debugPrint('Failed to mark as opened: $e');
    }
    
    setState(() => _animationComplete = true);
    
    // Navigate to opened letter screen
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (mounted) {
      context.go(
        '/capsule/${widget.capsule.id}/opened',
        extra: widget.capsule.copyWith(openedAt: DateTime.now()),
      );
    }
  }
  
  @override
  void dispose() {
    _shakeController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _riseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepPurple,
      body: SafeArea(
        child: Stack(
          children: [
            // Skip button (accessibility)
            Positioned(
              top: 16,
              right: 16,
              child: TextButton(
                onPressed: () {
                  if (!_animationComplete) {
                    _shakeController.stop();
                    _fadeController.stop();
                    _scaleController.stop();
                    _riseController.stop();
                    
                    context.go(
                      '/capsule/${widget.capsule.id}/opened',
                      extra: widget.capsule.copyWith(openedAt: DateTime.now()),
                    );
                  }
                },
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            
            // Animation content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Envelope animation
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _shakeAnimation,
                      _scaleAnimation,
                    ]),
                    builder: (context, child) {
                      final shake = _shakeAnimation.value;
                      final rotation = (shake * 0.1 * 3.14159) * 
                          (shake < 0.5 ? 1 : -1);
                      
                      return Transform.rotate(
                        angle: rotation,
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Envelope
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.mail_outline,
                            size: 90,
                            color: AppColors.white,
                          ),
                        ),
                        
                        // Seal (fades out)
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              color: AppColors.softGold,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite,
                              color: AppColors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 64),
                  
                  // Letter rising
                  SlideTransition(
                    position: _riseAnimation,
                    child: FadeTransition(
                      opacity: _riseController,
                      child: Container(
                        width: 200,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.favorite,
                                  color: AppColors.deepPurple,
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.capsule.label,
                                  style: const TextStyle(
                                    color: AppColors.deepPurple,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
