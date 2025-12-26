import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/theme/color_scheme.dart';
import 'package:openon_app/core/widgets/common_widgets.dart';

/// Identity Reveal Animation
/// 
/// Soft, gentle transition from unknown to known.
/// Like fog lifting, not curtain opening.
class IdentityRevealAnimation extends StatefulWidget {
  final Capsule capsule;
  final AppColorScheme colorScheme;
  final VoidCallback? onComplete;
  
  const IdentityRevealAnimation({
    super.key,
    required this.capsule,
    required this.colorScheme,
    this.onComplete,
  });
  
  @override
  State<IdentityRevealAnimation> createState() => _IdentityRevealAnimationState();
}

class _IdentityRevealAnimationState extends State<IdentityRevealAnimation>
    with TickerProviderStateMixin {
  late AnimationController _blurController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _quietController;
  
  late Animation<double> _blurAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _quietAnimation;
  
  bool _showQuietMoment = false;
  
  @override
  void initState() {
    super.initState();
    
    // Blur reduction: 20 → 0
    _blurController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _blurAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _blurController,
        curve: Curves.easeOut,
      ),
    );
    
    // Soft pulse before reveal
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Name fade in
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeIn,
      ),
    );
    
    // Quiet moment fade in
    _quietController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _quietAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _quietController,
        curve: Curves.easeIn,
      ),
    );
    
    _startAnimation();
  }
  
  void _startAnimation() async {
    // Soft pulse first
    await _pulseController.forward();
    await _pulseController.reverse();
    
    // Then blur reduction and name fade in together
    _blurController.forward();
    _fadeController.forward();
    
    // Wait for animations to complete
    await Future.delayed(const Duration(milliseconds: 2500));
    
    // Show quiet moment
    if (mounted) {
      setState(() {
        _showQuietMoment = true;
      });
      _quietController.forward();
      
      // Call onComplete after quiet moment
      await Future.delayed(const Duration(milliseconds: 3000));
      widget.onComplete?.call();
    }
  }
  
  @override
  void dispose() {
    _blurController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _quietController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: Listenable.merge([
        _blurController,
        _fadeController,
        _pulseController,
        _quietController,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Blurred placeholder → Clear name
              ClipRect(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: _blurAnimation.value,
                    sigmaY: _blurAnimation.value,
                  ),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Avatar (appears last)
                        if (_fadeAnimation.value > 0.7)
                          Padding(
                            padding: EdgeInsets.only(bottom: AppTheme.spacingSm),
                            child: UserAvatar(
                              imageUrl: widget.capsule.displaySenderAvatar.isNotEmpty
                                  ? widget.capsule.displaySenderAvatar
                                  : null,
                              name: widget.capsule.displaySenderName,
                              size: 48,
                            ),
                          ),
                        // Name
                        Text(
                          widget.capsule.displaySenderName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: DynamicTheme.getPrimaryTextColor(widget.colorScheme),
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Quiet moment text
              if (_showQuietMoment)
                Opacity(
                  opacity: _quietAnimation.value,
                  child: Padding(
                    padding: EdgeInsets.only(top: AppTheme.spacingLg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Now you know.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: DynamicTheme.getSecondaryTextColor(widget.colorScheme)
                                .withOpacity(0.7),
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: AppTheme.spacingXs),
                        Text(
                          'It was them.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: DynamicTheme.getSecondaryTextColor(widget.colorScheme)
                                .withOpacity(0.6),
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

