import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openon_app/core/constants/app_constants.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/router/app_router.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/utils/logger.dart';

class OpeningAnimationScreen extends ConsumerStatefulWidget {
  final Capsule capsule;
  
  const OpeningAnimationScreen({super.key, required this.capsule});
  
  @override
  ConsumerState<OpeningAnimationScreen> createState() => _OpeningAnimationScreenState();
}

class _OpeningAnimationScreenState extends ConsumerState<OpeningAnimationScreen> {
  bool _animationComplete = false;
  bool _isMarkingAsOpened = false;
  
  Future<void> _handleSkipAnimation() async {
    if (_isMarkingAsOpened) return;
    
    setState(() => _animationComplete = true);
    await _markCapsuleAsOpened();
    _navigateToOpenedLetter();
  }
  
  Future<void> _markCapsuleAsOpened() async {
    if (_isMarkingAsOpened) return;
    
    setState(() => _isMarkingAsOpened = true);
    
    try {
      final repo = ref.read(capsuleRepositoryProvider);
      await repo.markAsOpened(widget.capsule.id);
      
      // Invalidate all capsule providers to refresh the UI
      // This ensures the capsule moves from "Ready" tab to "Opened" tab
      ref.invalidate(capsulesProvider);
      ref.invalidate(incomingCapsulesProvider);
      ref.invalidate(incomingReadyCapsulesProvider);
      ref.invalidate(incomingOpeningSoonCapsulesProvider);
      ref.invalidate(incomingOpenedCapsulesProvider);
      ref.invalidate(incomingLockedCapsulesProvider);
      
      Logger.info('Capsule ${widget.capsule.id} marked as opened successfully');
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to mark capsule as opened',
        error: e,
        stackTrace: stackTrace,
      );
      
      if (mounted) {
        final colorScheme = ref.read(selectedColorSchemeProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to mark capsule as opened. Please try again.',
              style: TextStyle(
                color: DynamicTheme.getSnackBarTextColor(colorScheme),
              ),
            ),
            backgroundColor: DynamicTheme.getSnackBarBackgroundColor(colorScheme),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            action: SnackBarAction(
              label: 'Retry',
              textColor: DynamicTheme.getSnackBarTextColor(colorScheme),
              onPressed: () => _markCapsuleAsOpened(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isMarkingAsOpened = false);
      }
    }
  }
  
  void _navigateToOpenedLetter() {
    if (!mounted) return;
    
    context.push(
      '/capsule/${widget.capsule.id}/opened',
      extra: widget.capsule.copyWith(openedAt: DateTime.now()),
    );
  }
  
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
              top: AppConstants.openingAnimationSkipButtonTop,
              right: AppConstants.openingAnimationSkipButtonRight,
              child: TextButton(
                onPressed: () {
                  if (!_animationComplete && mounted) {
                    _handleSkipAnimation();
                  }
                },
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: DynamicTheme.getPrimaryTextColor(colorScheme),
                    fontSize: AppConstants.openingAnimationSkipButtonFontSize,
                  ),
                ),
              ),
            ),
            
            // Animation content
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: AppConstants.openingAnimationDuration,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: AppConstants.openingAnimationCardScaleBegin + 
                             (value * (AppConstants.openingAnimationCardScaleEnd - 
                                      AppConstants.openingAnimationCardScaleBegin)),
                      child: Container(
                        width: AppConstants.openingAnimationCardWidth,
                        height: AppConstants.openingAnimationCardHeight,
                        padding: EdgeInsets.all(AppTheme.spacingXl),
                        decoration: BoxDecoration(
                          color: DynamicTheme.getCardBackgroundColor(colorScheme),
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                AppConstants.openingAnimationShadowOpacity,
                              ),
                              blurRadius: AppConstants.openingAnimationShadowBlur,
                              offset: Offset(
                                0,
                                AppConstants.openingAnimationShadowOffsetY,
                              ),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite,
                              color: colorScheme.primary1,
                              size: AppConstants.openingAnimationIconSize,
                            ),
                            SizedBox(height: AppTheme.spacingLg),
                            Text(
                              widget.capsule.label,
                              style: TextStyle(
                                color: DynamicTheme.getPrimaryTextColor(colorScheme),
                                fontSize: AppConstants.openingAnimationTitleFontSize,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: AppTheme.spacingMd),
                            Text(
                              '${AppConstants.fromPrefix} ${widget.capsule.senderName}',
                              style: TextStyle(
                                color: DynamicTheme.getSecondaryTextColor(colorScheme),
                                fontSize: AppConstants.openingAnimationSubtitleFontSize,
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
                  if (!mounted || _animationComplete) return;
                  
                  setState(() => _animationComplete = true);
                  
                  // Mark capsule as opened and navigate
                  _markCapsuleAsOpened().then((_) {
                    if (mounted) {
                      Future.delayed(AppConstants.openingAnimationDelay, () {
                        if (mounted) {
                          _navigateToOpenedLetter();
                        }
                      });
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
