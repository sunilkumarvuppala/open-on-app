import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/router/app_router.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/utils/logger.dart';

/// Linear interval curve for truly constant speed
class LinearIntervalCurve extends Curve {
  const LinearIntervalCurve();
  
  @override
  double transformInternal(double t) {
    return t; // Linear: no transformation, constant speed
  }
}

/// Emoji particle for floating animation
class _EmojiParticle {
  final Animation<double> animation;
  final double startX; // Starting X position (0.0 to 1.0)
  final double startY; // Starting Y position (0.0 to 1.0)
  final double moveX; // Horizontal movement distance (-0.15 to 0.15)
  final double moveY; // Vertical movement distance (-0.2 to 0.2)
  final double size; // Size multiplier
  
  _EmojiParticle({
    required this.animation,
    required this.startX,
    required this.startY,
    required this.moveX,
    required this.moveY,
    required this.size,
  });
}

/// Emotional Reply Reveal Screen
/// 
/// Fullscreen animation that plays when:
/// - Receiver sends a reply (immediately after sending)
/// - Sender views a reply (first time only)
/// 
/// Animation sequence:
/// 1. Emoji Shower (~1.8s) - emojis fall from top in a shower effect
/// 2. Stillness (~400ms) - pause
/// 3. Text Reveal (~800ms) - text fades in centered
/// 
/// Features:
/// - Skippable by tap
/// - Respects "Reduce Motion" accessibility setting
/// - Plays only once per user per letter
class EmotionalReplyRevealScreen extends ConsumerStatefulWidget {
  final LetterReply reply;
  final bool isReceiver; // true if receiver viewing, false if sender viewing
  final VoidCallback? onComplete;
  
  const EmotionalReplyRevealScreen({
    super.key,
    required this.reply,
    required this.isReceiver,
    this.onComplete,
  });
  
  @override
  ConsumerState<EmotionalReplyRevealScreen> createState() => _EmotionalReplyRevealScreenState();
}

class _EmotionalReplyRevealScreenState extends ConsumerState<EmotionalReplyRevealScreen>
    with TickerProviderStateMixin {
  late AnimationController _emojiController;
  late AnimationController _textController;
  late List<_EmojiParticle> _emojiParticles;
  bool _isSkipped = false;
  bool _isComplete = false;
  bool _reduceMotion = false;
  bool _hasStartedAnimation = false;
  bool _hasCalledDidChangeDependencies = false; // Track if didChangeDependencies was called
  final math.Random _random = math.Random();
  
  // Check if reduce motion is enabled (can only be called after widget is built)
  bool _checkReduceMotion() {
    return MediaQuery.of(context).accessibleNavigation ||
           MediaQuery.of(context).disableAnimations;
  }
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers first
    _emojiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500), // 3.5 seconds for emoji animation
    );
    
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // Quick fade-in for text
    );
    
    // Create emoji particles for shower effect (fewer for more spacing)
    final emojiCount = _random.nextInt(10) + 30; // 30-40 emojis for increased spacing
    
    // Create floating emojis with varied motion patterns
    _emojiParticles = List.generate(emojiCount, (index) {
      // Random starting positions across entire screen
      final startX = _random.nextDouble(); // 0.0 to 1.0 - random X start
      final startY = _random.nextDouble(); // 0.0 to 1.0 - random Y start
      
      // Random movement direction and distance (floating effect)
      final moveX = (_random.nextDouble() - 0.5) * 0.3; // -0.15 to 0.15 horizontal movement
      final moveY = (_random.nextDouble() - 0.5) * 0.4; // -0.2 to 0.2 vertical movement (can go up or down)
      
      // Random animation duration for varied speeds
      final duration = 0.6 + _random.nextDouble() * 0.3; // 0.6 to 0.9 duration
      final startDelay = _random.nextDouble() * 0.3; // Random start time (0 to 0.3)
      final endTime = (startDelay + duration).clamp(0.0, 1.0);
      
      // Constant emoji size (same for all emojis)
      final size = 1.0; // Constant size
      
      // Create smooth floating animation
      final clampedStart = startDelay.clamp(0.0, 1.0);
      final clampedEnd = endTime.clamp(0.0, 1.0);
      
      return _EmojiParticle(
        animation: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: _emojiController,
            curve: Interval(
              clampedStart,
              clampedEnd,
              curve: Curves.easeInOut, // Smooth floating motion
            ),
          ),
        ),
        startX: startX,
        startY: startY,
        moveX: moveX,
        moveY: moveY,
        size: size,
      );
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Only run once - didChangeDependencies can be called multiple times
    if (_hasCalledDidChangeDependencies) {
      return;
    }
    _hasCalledDidChangeDependencies = true;
    
    // Check reduce motion now that context is available
    // Only start animation once - guard against multiple calls
    if (!_hasStartedAnimation && !_isComplete) {
      _reduceMotion = _checkReduceMotion();
      _hasStartedAnimation = true;
      
      // Start animation sequence only once
      if (_reduceMotion) {
        // Skip animation, show text directly
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isComplete) {
            _showTextDirectly();
          }
        });
      } else {
        // Use postFrameCallback to ensure widget is fully built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isComplete && !_emojiController.isAnimating && !_emojiController.isCompleted) {
            _startAnimation();
          }
        });
      }
    }
  }
  
  void _startAnimation() {
    // Ensure animation only starts once
    if (_hasStartedAnimation && (_emojiController.isAnimating || _emojiController.isCompleted)) {
      return;
    }
    
    // Reset controllers to ensure clean start
    _emojiController.reset();
    _textController.reset();
    
    // Step 1: Emoji floating animation (3.5 seconds)
    _emojiController.forward().then((_) {
      if (!_isSkipped && mounted && !_isComplete) {
        // Step 2: Fade out emojis and fade in text simultaneously
        _textController.forward().then((_) {
          if (mounted && !_isComplete) {
            // Keep text visible for a moment, then complete
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                _complete();
              }
            });
          }
        });
      }
    });
  }
  
  void _showTextDirectly() {
    // For reduce motion, show text immediately
    setState(() {
      _isComplete = true;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _complete();
      }
    });
  }
  
  void _complete() {
    if (_isComplete) return;
    setState(() {
      _isComplete = true;
    });
    
    // Mark animation as seen
    _markAnimationSeen();
    
    // Don't call onComplete immediately - keep the screen showing the reply
    // The user can navigate back using the back button when ready
  }
  
  Future<void> _markAnimationSeen() async {
    try {
      final repo = ref.read(letterReplyRepositoryProvider);
      if (widget.isReceiver) {
        // Check if already marked
        if (!widget.reply.hasReceiverSeenAnimation) {
          await repo.markReceiverAnimationSeen(widget.reply.letterId);
        }
      } else {
        // Check if already marked
        if (!widget.reply.hasSenderSeenAnimation) {
          await repo.markSenderAnimationSeen(widget.reply.letterId);
        }
      }
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to mark animation as seen',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't show error to user - this is a background operation
    }
  }
  
  void _handleSkip() {
    if (_isSkipped || _isComplete) return;
    
    setState(() {
      _isSkipped = true;
    });
    
    // Stop all animations and prevent restart
    if (_emojiController.isAnimating) {
      _emojiController.stop();
    }
    if (_textController.isAnimating) {
      _textController.stop();
    }
    
    // Complete text animation immediately if not already complete
    if (!_textController.isCompleted) {
      _textController.value = 1.0;
    }
    
    // Show text immediately
    _showTextDirectly();
  }
  
  @override
  void dispose() {
    _emojiController.dispose();
    _textController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final theme = Theme.of(context);
    // Use theme-based background color (same as scaffold background)
    final backgroundColor = colorScheme.secondary2;
    
    return GestureDetector(
      // Only allow tap to skip during animation, not after completion
      onTap: _isComplete ? null : _handleSkip,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          color: backgroundColor,
          child: Stack(
            children: [
              // Full screen emoji animation (fade out when text appears)
              AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  // Fade out emojis as text fades in
                  final emojiOpacity = 1.0 - _textController.value;
                  if (_reduceMotion || _isSkipped || _isComplete || emojiOpacity <= 0.0) {
                    return const SizedBox.shrink();
                  }
                  return Opacity(
                    opacity: emojiOpacity,
                    child: _buildAnimatedContent(theme, colorScheme),
                  );
                },
              ),
              // Text content centered (fade in after emoji animation)
              Center(
                child: _reduceMotion || _isSkipped || _isComplete
                    ? _buildTextContent(theme, colorScheme)
                    : AnimatedBuilder(
                        animation: Listenable.merge([_emojiController, _textController]),
                        builder: (context, child) {
                          // Show text when emoji animation is done
                          if (!_emojiController.isCompleted && _textController.value == 0.0) {
                            return const SizedBox.shrink();
                          }
                          // Fade in text (opacity goes from 0 to 1)
                          return Opacity(
                            opacity: _textController.value.clamp(0.0, 1.0),
                            child: _buildTextContent(theme, colorScheme),
                          );
                        },
                      ),
              ),
              // Back button in top-left corner
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacingMd),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back),
                    color: DynamicTheme.getPrimaryIconColor(colorScheme),
                    onPressed: () {
                      // Call completion callback when user explicitly navigates back
                      widget.onComplete?.call();
                      // Navigate back to the opened letter screen
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        // Fallback to home if we can't pop
                        context.go(Routes.receiverHome);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAnimatedContent(ThemeData theme, dynamic colorScheme) {
    final screenSize = MediaQuery.of(context).size;
    
    // Full screen dimensions (including status bar area)
    final fullHeight = screenSize.height;
    final fullWidth = screenSize.width;
    
    return SizedBox(
      width: fullWidth,
      height: fullHeight,
      child: Stack(
        children: [
          // Emoji shower - emojis falling from top to bottom (full screen)
          ..._emojiParticles.map((particle) {
            return AnimatedBuilder(
              animation: particle.animation,
              builder: (context, child) {
              // Get animation value
              final animationValue = particle.animation.value;
              
              // Only show if animation is active and valid
              if (animationValue.isNaN || animationValue.isInfinite || animationValue <= 0.0 || animationValue >= 1.0) {
                return const SizedBox.shrink();
              }
              
              // Calculate position: floating motion from random start position
              // Emojis float in various directions (up, down, left, right, diagonal)
              final baseX = fullWidth * particle.startX; // Starting X position
              final baseY = fullHeight * particle.startY; // Starting Y position
              
              // Add floating movement based on animation value
              final x = baseX + (fullWidth * particle.moveX * animationValue); // Float horizontally
              final y = baseY + (fullHeight * particle.moveY * animationValue); // Float vertically (can go up or down)
                
                // Opacity: fade in at start, fade out at end
                final opacity = _calculateOpacity(animationValue);
              
              // Calculate emoji size - increased size for better visibility
              final baseFontSize = math.min(
                screenSize.width * 0.08, // 8% of screen width (increased)
                screenSize.height * 0.08, // 8% of screen height (increased)
              ).clamp(50.0, 100.0); // Min 50, max 100 (increased size)
              
              final emojiSize = baseFontSize; // Constant size (no variation)
              final emojiOffset = emojiSize / 2; // Center the emoji
              
              return Positioned(
                left: x - emojiOffset,
                top: y - emojiOffset,
                child: Opacity(
                  opacity: opacity,
                  child: Text(
                    widget.reply.replyEmoji,
                    style: TextStyle(
                      fontSize: emojiSize,
                      shadows: [
                        Shadow(
                          blurRadius: emojiSize * 0.2,
                          color: Colors.black.withOpacity(0.2),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
            }).toList(),
        ],
      ),
    );
  }
  
  // Calculate opacity: fade in quickly, stay fully visible until reaching bottom
  double _calculateOpacity(double value) {
    // Ensure value is valid
    if (value.isNaN || value.isInfinite) {
      return 0.0;
    }
    
    if (value < 0.05) {
      // Fade in very quickly
      return (value / 0.05).clamp(0.0, 1.0);
    } else if (value > 0.98) {
      // Only fade out in the last 2% of animation (when actually off screen)
      return ((1.0 - value) / 0.02).clamp(0.0, 1.0);
    } else {
      // Stay fully visible until reaching bottom
      return 1.0;
    }
  }
  
  Widget _buildTextContent(ThemeData theme, dynamic colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reply text in a card
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppTheme.spacingXl),
            decoration: BoxDecoration(
              color: DynamicTheme.getCardBackgroundColor(colorScheme),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reply emoji (larger, centered)
                Text(
                  widget.reply.replyEmoji,
                  style: TextStyle(
                    fontSize: 48,
                  ),
                ),
                SizedBox(height: AppTheme.spacingLg),
                // Reply text
                Text(
                  widget.reply.replyText,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: DynamicTheme.getPrimaryTextColor(colorScheme),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

