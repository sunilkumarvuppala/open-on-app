import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';

class OpeningAnimationScreen extends ConsumerStatefulWidget {
  final Capsule capsule;
  
  const OpeningAnimationScreen({super.key, required this.capsule});
  
  @override
  ConsumerState<OpeningAnimationScreen> createState() => _OpeningAnimationScreenState();
}

class _OpeningAnimationScreenState extends ConsumerState<OpeningAnimationScreen> {
  bool _animationComplete = false;
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final gradient = DynamicTheme.dreamyGradient(colorScheme);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: gradient,
        ),
        child: SafeArea(
        child: Stack(
          children: [
            // Skip button (accessibility)
            Positioned(
              top: 16,
              right: 16,
              child: TextButton(
                onPressed: () {
                  if (!_animationComplete) {
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
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1500),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: 0.8 + (value * 0.2),
                      child: Container(
                        width: 300,
                        height: 400,
                        padding: EdgeInsets.all(AppTheme.spacingXl),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite,
                              color: colorScheme.primary1,
                              size: 60,
                            ),
                            SizedBox(height: AppTheme.spacingLg),
                            Text(
                              widget.capsule.label,
                              style: TextStyle(
                                color: colorScheme.primary1,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: AppTheme.spacingMd),
                            Text(
                              'From ${widget.capsule.senderName}',
                              style: TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                onEnd: () {
                  // Mark capsule as opened
                  try {
                    final repo = ref.read(capsuleRepositoryProvider);
                    repo.markAsOpened(widget.capsule.id);
                    ref.invalidate(capsulesProvider);
                  } catch (e) {
                    debugPrint('Failed to mark as opened: $e');
                  }
                  
                  setState(() => _animationComplete = true);
                  
                  // Navigate to opened letter screen
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) {
                      context.go(
                        '/capsule/${widget.capsule.id}/opened',
                        extra: widget.capsule.copyWith(openedAt: DateTime.now()),
                      );
                    }
                  });
                },
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
