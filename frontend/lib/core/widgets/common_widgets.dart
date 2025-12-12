import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../theme/dynamic_theme.dart';
import '../theme/color_scheme.dart';
import '../constants/app_constants.dart';

/// Custom gradient button with consistent styling
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Gradient? gradient;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: gradient ?? AppTheme.dreamyGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

/// Avatar widget with fallback to initials
class UserAvatar extends ConsumerWidget {
  final String? imageUrl;
  final String? imagePath;
  final String name;
  final double size;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.imagePath,
    required this.name,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasImage = (imageUrl != null && imageUrl!.isNotEmpty) || 
                     (imagePath != null && imagePath!.isNotEmpty);
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final gradient = DynamicTheme.dreamyGradient(colorScheme);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        border: Border.all(
          color: colorScheme.accent.withOpacity(0.8),
          width: 1.0,
        ),
        boxShadow: [
          // Reduced glow
          BoxShadow(
            color: colorScheme.accent.withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 1,
          ),
          // Subtle shadow
          BoxShadow(
            color: colorScheme.primary1.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: hasImage
          ? ClipOval(
              child: imagePath != null && imagePath!.isNotEmpty
                  ? Image.asset(
                      imagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to initials if asset fails to load
                        return Center(
                          child: Text(
                            _getInitials(name),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: size * 0.4,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    )
                  : Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to initials if network image fails to load
                        return Center(
                          child: Text(
                            _getInitials(name),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: size * 0.4,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
            )
          : Center(
              child: Text(
                _getInitials(name),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

/// Status pill widget for capsule states
class StatusPill extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;

  const StatusPill({
    super.key,
    required this.text,
    required this.backgroundColor,
    this.textColor = Colors.white,
  });

  factory StatusPill.locked() {
    // This will use theme primary color, but we'll make it dynamic
    return StatusPill(
      text: 'Locked',
      backgroundColor: AppTheme.deepPurple,
    );
  }
  
  static StatusPill lockedDynamic(Color primaryColor) {
    return StatusPill(
      text: 'Locked',
      backgroundColor: primaryColor,
    );
  }

  factory StatusPill.unlockingSoon() {
    return const StatusPill(
      text: 'Unlocking Soon',
      backgroundColor: AppTheme.pastelPink,
      textColor: AppTheme.textDark,
    );
  }


  factory StatusPill.opened() {
    return const StatusPill(
      text: 'Opened',
      backgroundColor: AppTheme.successGreen,
    );
  }

  factory StatusPill.readyToOpen() {
    return const StatusPill(
      text: 'Ready to Open',
      backgroundColor: AppTheme.softGold,
      textColor: AppTheme.textDark,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppConstants.badgeAnimationDuration,
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Empty state widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppTheme.lavender,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppTheme.spacingLg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Error widget
class ErrorDisplay extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorDisplay({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorRed,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'Oops!',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppTheme.spacingLg),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Countdown display widget
class CountdownDisplay extends StatelessWidget {
  final Duration duration;
  final TextStyle? style;

  const CountdownDisplay({
    super.key,
    required this.duration,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);

    String text;
    if (days > 0) {
      text = '$days day${days == 1 ? '' : 's'} ${hours}h';
    } else if (hours > 0) {
      text = '$hours hour${hours == 1 ? '' : 's'} ${minutes}m';
    } else if (minutes > 0) {
      text = '$minutes minute${minutes == 1 ? '' : 's'}';
    } else {
      text = 'Opening now...';
    }

    return Text(
      text,
      style: style ?? Theme.of(context).textTheme.bodyMedium,
    );
  }
}

/// Animated unlocking soon badge with lightweight sparkle twinkle animation
class AnimatedUnlockingSoonBadge extends ConsumerStatefulWidget {
  const AnimatedUnlockingSoonBadge({super.key});

  @override
  ConsumerState<AnimatedUnlockingSoonBadge> createState() =>
      _AnimatedUnlockingSoonBadgeState();
}

class _AnimatedUnlockingSoonBadgeState
    extends ConsumerState<AnimatedUnlockingSoonBadge>
    with TickerProviderStateMixin {
  late AnimationController _sparkleController;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    // Sparkle animation: 3 seconds for twinkle effect (same as tabs)
    _sparkleController = AnimationController(
      vsync: this,
      duration: AppConstants.sparkleAnimationDuration,
    )..repeat();
    
    // Shimmer animation: 3 seconds for shimmer pass
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    // Use accent color for the badge (magical color)
    final badgeColor = colorScheme.accent;
    final textColor = _getContrastingTextColor(badgeColor);
    
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_sparkleController, _shimmerController]),
        builder: (context, child) {
          // Calculate animation value inside builder (same as tabs)
          final animationValue = _sparkleController.value * 2 * math.pi;
          final shimmerProgress = _shimmerController.value;
          
          return ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Stack(
              children: [
                // Base badge with fixed color - using StatusPill like "Ready to Open"
                StatusPill(
                  text: 'Unlocking Soon',
                  backgroundColor: badgeColor,
                  textColor: textColor,
                ),
                // Sparkle overlay
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BadgeSparklePainter(
                      animationValue: animationValue,
                      colorScheme: colorScheme,
                    ),
                  ),
                ),
                // Shimmer overlay
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BadgeShimmerPainter(
                      progress: shimmerProgress,
                      colorScheme: colorScheme,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Calculates contrasting text color based on background color luminance
  /// Returns white for dark backgrounds, dark for light backgrounds
  Color _getContrastingTextColor(Color backgroundColor) {
    // Calculate relative luminance (0-1, where 0 is black and 1 is white)
    final luminance = backgroundColor.computeLuminance();
    
    // Use white text for dark backgrounds (luminance < 0.5)
    // Use dark text for light backgrounds (luminance >= 0.5)
    return luminance < 0.5 ? Colors.white : AppTheme.textDark;
  }
}

/// Sparkle painter for badge - horizontal sweep animation (left to right)
class _BadgeSparklePainter extends CustomPainter {
  final double animationValue;
  final AppColorScheme colorScheme;
  
  // Reusable Paint objects to avoid allocation
  final Paint _sparklePaint = Paint()..style = PaintingStyle.fill;
  final Paint _accentGlowPaint = Paint()..style = PaintingStyle.fill;
  final Paint _centerGlowPaint = Paint()..style = PaintingStyle.fill;
  final Paint _innerCirclePaint = Paint()..style = PaintingStyle.fill;
  
  _BadgeSparklePainter({
    required this.animationValue,
    required this.colorScheme,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Use 2 sparkles for horizontal sweep
    const int sparkleCount = 2;
    final double centerY = rect.center.dy;
    
    // Convert animation value (0 to 2π) to progress (0 to 1)
    final double progress = (animationValue % (2 * math.pi)) / (2 * math.pi);
    
    for (int i = 0; i < sparkleCount; i++) {
      // Calculate horizontal position (left to right sweep)
      // Offset each sparkle slightly for staggered effect
      final double sparkleProgress = (progress + i * 0.3) % 1.0;
      final double x = rect.left + sparkleProgress * rect.width;
      
      // Vertical position with slight variation
      final double yVariation = math.sin(animationValue * 2 + i) * 3;
      final double y = centerY + yVariation;
      
      // Enhanced opacity - minimum 0.4 for better visibility, brighter in center
      final double centerDistance = (sparkleProgress - 0.5).abs() * 2; // 0 at center, 1 at edges
      final double baseOpacity = 0.4 + (1.0 - centerDistance * 0.4) * 0.6; // 0.4 to 1.0
      final double twinkleOpacity = (math.sin(animationValue * 3 + i) + 1) / 2;
      final double opacity = baseOpacity * (0.7 + twinkleOpacity * 0.3); // Enhanced visibility
      
      // Larger sparkle size for better visibility
      final double sparkleSize = 3.5 + math.sin(animationValue * 4 + i) * 2.0; // 3.5-5.5
      
      // Accent glow - more visible
      _accentGlowPaint
        ..color = colorScheme.accent.withOpacity(opacity * 0.5) // Increased from 0.25
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sparkleSize * 1.5); // Increased blur
      canvas.drawCircle(
        Offset(x, y),
        sparkleSize * 0.8, // Increased from 0.7
        _accentGlowPaint,
      );
      
      // Main sparkle (white circle) - much more visible
      _sparklePaint
        ..color = Colors.white.withOpacity(opacity * 0.9) // Increased from 0.5
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sparkleSize * 0.8); // Increased blur
      canvas.drawCircle(
        Offset(x, y),
        sparkleSize,
        _sparklePaint,
      );
      
      // Center glow - more visible
      _centerGlowPaint
        ..color = Colors.white.withOpacity(opacity * 1.0) // Increased from 0.7
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sparkleSize * 1.5); // Increased blur
      canvas.drawCircle(
        Offset(x, y),
        sparkleSize * 0.7, // Increased from 0.6
        _centerGlowPaint,
      );
      
      // Inner circle - very visible
      _innerCirclePaint.color = Colors.white.withOpacity(opacity * 1.0); // Increased from 0.8
      canvas.drawCircle(
        Offset(x, y),
        sparkleSize * 0.3, // Increased from 0.25
        _innerCirclePaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(_BadgeSparklePainter oldDelegate) {
    return animationValue != oldDelegate.animationValue || colorScheme != oldDelegate.colorScheme;
  }
}

/// Shimmer painter for badge - diagonal shimmer pass
class _BadgeShimmerPainter extends CustomPainter {
  final double progress;
  final AppColorScheme colorScheme;
  
  _BadgeShimmerPainter({
    required this.progress,
    required this.colorScheme,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Calculate shimmer position (diagonal from top-right to bottom-left)
    final diagonal = math.sqrt(size.width * size.width + size.height * size.height);
    const shimmerWidth = 40.0;
    final shimmerStart = -shimmerWidth;
    final shimmerEnd = diagonal + shimmerWidth;
    final shimmerPosition = shimmerStart + (shimmerEnd - shimmerStart) * progress;
    
    // Create shimmer gradient (white to transparent) - reduced brightness
    final shimmerGradient = LinearGradient(
      colors: [
        Colors.transparent,
        Colors.white.withOpacity(AppConstants.shimmerEdgeOpacity),
        Colors.white.withOpacity(AppConstants.shimmerCenterOpacity),
        Colors.white.withOpacity(AppConstants.shimmerEdgeOpacity),
        Colors.transparent,
      ],
      stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
    );
    
    // Angle for diagonal shimmer (from top-right to bottom-left)
    const angle = -math.pi / 4;
    
    // Create paint with gradient shader
    final paint = Paint()
      ..shader = shimmerGradient.createShader(
        Rect.fromLTWH(
          shimmerPosition - shimmerWidth / 2,
          -size.height,
          shimmerWidth,
          size.height * 3,
        ),
      )
      ..blendMode = BlendMode.plus; // Additive blending for glow effect
    
    // Apply rotation and draw
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(angle);
    canvas.translate(-size.width / 2, -size.height / 2);
    
    canvas.drawRect(
      Rect.fromLTWH(
        shimmerPosition - shimmerWidth / 2,
        -size.height,
        shimmerWidth,
        size.height * 3,
      ),
      paint,
    );
    
    canvas.restore();
  }
  
  @override
  bool shouldRepaint(_BadgeShimmerPainter oldDelegate) {
    return progress != oldDelegate.progress || colorScheme != oldDelegate.colorScheme;
  }
}

/// Heartbeat animation widget - animated heart icon in bottom right
/// Mimics a realistic heartbeat pattern: small beat (lub), pause, big beat (dub), longer pause
/// Uses heart icon to indicate excitement/readiness
class HeartbeatAnimation extends StatefulWidget {
  final Color? color;
  final double? size;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final IconData? icon;

  const HeartbeatAnimation({
    super.key,
    this.color,
    this.size,
    this.margin,
    this.onTap,
    this.icon,
  });

  @override
  State<HeartbeatAnimation> createState() => _HeartbeatAnimationState();
}

class _HeartbeatAnimationState extends State<HeartbeatAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: AppConstants.heartbeatCycleDuration,
      vsync: this,
    )..repeat();

    // Create realistic heartbeat pattern: small beat (lub), pause, big beat (dub), longer pause
    // Pattern: 0.0-0.167 (small beat up), 0.167-0.333 (small beat down), 
    // 0.333-0.417 (pause), 0.417-0.667 (big beat up), 0.667-0.833 (big beat down), 
    // 0.833-1.0 (longer pause)
    _scaleAnimation = TweenSequence<double>([
      // First small beat (lub) - scale up to small size
      TweenSequenceItem(
        tween: Tween<double>(
          begin: AppConstants.heartbeatIconSizeMin / AppConstants.heartbeatIconSize,
          end: AppConstants.heartbeatIconSizeSmall / AppConstants.heartbeatIconSize,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 8.33, // 0.0 - 0.0833 (small beat up - 100ms of 1200ms)
      ),
      // First small beat (lub) - scale down
      TweenSequenceItem(
        tween: Tween<double>(
          begin: AppConstants.heartbeatIconSizeSmall / AppConstants.heartbeatIconSize,
          end: AppConstants.heartbeatIconSizeMin / AppConstants.heartbeatIconSize,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 8.33, // 0.0833 - 0.1667 (small beat down - 100ms)
      ),
      // Short pause after small beat
      TweenSequenceItem(
        tween: Tween<double>(
          begin: AppConstants.heartbeatIconSizeMin / AppConstants.heartbeatIconSize,
          end: AppConstants.heartbeatIconSizeMin / AppConstants.heartbeatIconSize,
        ),
        weight: 8.33, // 0.1667 - 0.25 (pause - 100ms)
      ),
      // Second big beat (dub) - scale up to big size
      TweenSequenceItem(
        tween: Tween<double>(
          begin: AppConstants.heartbeatIconSizeMin / AppConstants.heartbeatIconSize,
          end: AppConstants.heartbeatIconSizeBig / AppConstants.heartbeatIconSize,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 12.5, // 0.25 - 0.375 (big beat up - 150ms)
      ),
      // Second big beat (dub) - scale down
      TweenSequenceItem(
        tween: Tween<double>(
          begin: AppConstants.heartbeatIconSizeBig / AppConstants.heartbeatIconSize,
          end: AppConstants.heartbeatIconSizeMin / AppConstants.heartbeatIconSize,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 12.5, // 0.375 - 0.5 (big beat down - 150ms)
      ),
      // Longer pause after big beat
      TweenSequenceItem(
        tween: Tween<double>(
          begin: AppConstants.heartbeatIconSizeMin / AppConstants.heartbeatIconSize,
          end: AppConstants.heartbeatIconSizeMin / AppConstants.heartbeatIconSize,
        ),
        weight: 50.0, // 0.5 - 1.0 (longer pause - 600ms)
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.size ?? AppConstants.heartbeatIconSize;
    final iconColor = widget.color ?? Color(AppConstants.heartbeatColorValue);
    final margin = widget.margin;

    // If margin is null, wrap in Positioned for standalone use
    // If margin is provided (including EdgeInsets.zero), use as-is for embedded use
    final child = GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            alignment: Alignment.center,
            child: Icon(
              widget.icon ?? Icons.favorite, // Heart icon for ready capsules
              size: iconSize,
              color: iconColor,
            ),
          );
        },
      ),
    );

    // If no margin specified, wrap in Positioned for standalone use
    if (margin == null) {
      return Positioned(
        bottom: AppConstants.heartbeatBottomMargin,
        right: AppConstants.heartbeatRightMargin,
        child: child,
      );
    }

    // If margin is provided (even if zero), return child directly for embedded use
    return child;
  }
}

/// Opened letter pulse animation widget - gentle breathing pulse for opened letters
/// Creates a calm, gentle pulsing effect to indicate the letter has been opened
/// Uses checkmark circle icon to indicate completion
class OpenedLetterPulse extends StatefulWidget {
  final Color? color;
  final double? size;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final IconData? icon;

  const OpenedLetterPulse({
    super.key,
    this.color,
    this.size,
    this.margin,
    this.onTap,
    this.icon,
  });

  @override
  State<OpenedLetterPulse> createState() => _OpenedLetterPulseState();
}

class _OpenedLetterPulseState extends State<OpenedLetterPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: AppConstants.openedLetterPulseCycleDuration,
      vsync: this,
    )..repeat(reverse: true); // Reverse creates smooth breathing effect

    // Create gentle breathing pulse: slow, smooth expansion and contraction
    _scaleAnimation = Tween<double>(
      begin: AppConstants.openedLetterPulseIconSizeMin / AppConstants.openedLetterPulseIconSize,
      end: AppConstants.openedLetterPulseIconSizeMax / AppConstants.openedLetterPulseIconSize,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut, // Smooth, gentle curve for breathing effect
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.size ?? AppConstants.openedLetterPulseIconSize;
    final iconColor = widget.color ?? Color(AppConstants.openedLetterPulseColorValue);
    final margin = widget.margin;

    // If margin is null, wrap in Positioned for standalone use
    // If margin is provided (including EdgeInsets.zero), use as-is for embedded use
    final child = GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            alignment: Alignment.center,
            child: Icon(
              widget.icon ?? Icons.check_circle, // Checkmark circle for opened letters
              size: iconSize,
              color: iconColor,
            ),
          );
        },
      ),
    );

    // If no margin specified, wrap in Positioned for standalone use
    if (margin == null) {
      return Positioned(
        bottom: AppConstants.openedLetterPulseBottomMargin,
        right: AppConstants.openedLetterPulseRightMargin,
        child: child,
      );
    }

    // If margin is provided (even if zero), return child directly for embedded use
    return child;
  }
}

/// Sealed letter animation widget - rapid rotation for locked/sealed letters
/// Creates a rapid left-right rotation effect, then pauses and repeats
/// Uses lock icon to indicate sealed state
class SealedLetterAnimation extends StatefulWidget {
  final Color? color;
  final double? size;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final IconData? icon;

  const SealedLetterAnimation({
    super.key,
    this.color,
    this.size,
    this.margin,
    this.onTap,
    this.icon,
  });

  @override
  State<SealedLetterAnimation> createState() => _SealedLetterAnimationState();
}

class _SealedLetterAnimationState extends State<SealedLetterAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: AppConstants.sealedLetterCycleDuration,
      vsync: this,
    )..repeat(); // Continuous rotation animation

    // Create rapid left-right rotation pattern: rotate left-right-left-right, then pause
    // Pattern: 4 rapid rotations (left-right-left-right) then pause at center
    // Calculate weights based on actual durations for precise timing
    // Total shake duration: 4 rotations * shakeDuration
    // Total cycle: shake duration + pause duration
    final totalShakeMs = AppConstants.sealedLetterShakeDuration.inMilliseconds * 4;
    final pauseMs = AppConstants.sealedLetterPauseDuration.inMilliseconds;
    final totalCycleMs = totalShakeMs + pauseMs;
    
    // Calculate weights as percentages of total cycle duration
    // Each shake segment gets equal weight (shakeDuration / totalCycle)
    final shakeWeight = (AppConstants.sealedLetterShakeDuration.inMilliseconds / totalCycleMs) * 100.0;
    final pauseWeight = (pauseMs / totalCycleMs) * 100.0;
    
    _rotation = TweenSequence<double>([
      // Rotate left
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: shakeWeight,
      ),
      // Rotate right
      TweenSequenceItem(
        tween: Tween<double>(begin: -1.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: shakeWeight,
      ),
      // Rotate left again
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: -1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: shakeWeight,
      ),
      // Rotate right again
      TweenSequenceItem(
        tween: Tween<double>(begin: -1.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: shakeWeight,
      ),
      // Return to center and pause
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: pauseWeight,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.size ?? AppConstants.sealedLetterIconSize;
    final iconColor = widget.color ?? Color(AppConstants.sealedLetterColorValue);
    final margin = widget.margin;

    // If margin is null, wrap in Positioned for standalone use
    // If margin is provided (including EdgeInsets.zero), use as-is for embedded use
    final child = GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _rotation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotation.value * AppConstants.sealedLetterRotationAngle,
            child: Icon(
              widget.icon ?? Icons.lock_outline, // Lock icon for sealed/locked letters
              size: iconSize,
              color: iconColor,
            ),
          );
        },
      ),
    );

    // If no margin specified, wrap in Positioned for standalone use
    if (margin == null) {
      return Positioned(
        bottom: AppConstants.sealedLetterBottomMargin,
        right: AppConstants.sealedLetterRightMargin,
        child: child,
      );
    }

    // If margin is provided (even if zero), return child directly for embedded use
    return child;
  }
}

