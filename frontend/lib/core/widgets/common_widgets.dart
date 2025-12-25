import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../theme/dynamic_theme.dart';
import '../theme/color_scheme.dart';
import '../constants/app_constants.dart';
import '../models/models.dart';
import '../router/app_router.dart';

/// Custom refresh indicator with simple rotating icon
class SimpleRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? color;

  const SimpleRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final indicatorColor = color ?? colorScheme.primary;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: indicatorColor,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      strokeWidth: 2.0,
      displacement: 40.0,
      child: child,
    );
  }
}

/// Custom gradient button with consistent styling
class GradientButton extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
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
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(DynamicTheme.getPrimaryIconColor(colorScheme)),
                ),
              )
            : Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: DynamicTheme.getPrimaryTextColor(colorScheme),
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

  /// Adds a cache-busting query parameter to the image URL
  /// This ensures that when the same URL is overwritten with new content,
  /// the image will be reloaded instead of using the cached version
  String _addCacheBuster(String url, int timestamp) {
    // Add a timestamp-based cache-busting parameter
    // This ensures the image reloads when the avatar is updated (even if URL stays the same)
    final uri = Uri.parse(url);
    final separator = uri.query.isEmpty ? '?' : '&';
    return '$url$separator' + '_t=$timestamp';
  }
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasImage = (imageUrl != null && imageUrl!.isNotEmpty) || 
                     (imagePath != null && imagePath!.isNotEmpty);
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final gradient = DynamicTheme.dreamyGradient(colorScheme);
    
    // Watch current user to detect when avatar changes
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.asData?.value;
    
    // Use the user's current avatar URL if available, otherwise use the prop
    // This ensures we always use the latest avatar URL from the provider
    final effectiveAvatarUrl = user?.avatarUrl ?? imageUrl;
    
    // Create a cache key that changes when the avatar URL or provider state changes
    // Include user ID and provider state hash to ensure uniqueness
    // The provider state hash changes when invalidated, forcing a new cache key
    final providerStateHash = userAsync.hashCode; // Changes when provider updates
    final cacheKey = user != null 
        ? '${user.id}_${effectiveAvatarUrl ?? ""}_$providerStateHash' 
        : '${effectiveAvatarUrl ?? ""}_$providerStateHash';
    
    // Use provider state hash as cache timestamp - this changes when provider updates
    // This ensures the image reloads when the provider is invalidated, even if URL stays the same
    final cacheTimestamp = providerStateHash;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        border: Border.all(
          color: colorScheme.accent.withOpacity(0.65), // Reduced from 0.8 (18.75% reduction) for softer appearance
          width: 1.0,
        ),
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
                              color: DynamicTheme.getPrimaryIconColor(colorScheme),
                              fontSize: size * 0.4,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    )
                  : effectiveAvatarUrl != null && effectiveAvatarUrl.isNotEmpty
                      ? Image.network(
                          // Use effective avatar URL (from provider if available) for cache-busting
                          // Add hash-based cache-busting parameter to ensure updated avatars are displayed
                          // This is especially important when the same URL is overwritten with new content
                          _addCacheBuster(effectiveAvatarUrl, cacheTimestamp),
                          key: ValueKey<String>(cacheKey), // Key changes when user or avatar URL changes
                          fit: BoxFit.cover,
                          cacheWidth: size.toInt(),
                          cacheHeight: size.toInt(),
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to initials if network image fails to load
                            return Center(
                              child: Text(
                                _getInitials(name),
                                style: TextStyle(
                                  color: DynamicTheme.getPrimaryIconColor(colorScheme),
                                  fontSize: size * 0.4,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Text(
                            _getInitials(name),
                            style: TextStyle(
                              color: DynamicTheme.getPrimaryIconColor(colorScheme),
                              fontSize: size * 0.4,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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

/// Profile avatar button for AppBar - navigates to profile screen
/// 
/// Security: Validates user authentication before navigation
/// Performance: Uses const constructor and memoized user data
class ProfileAvatarButton extends ConsumerWidget {
  final double size;

  const ProfileAvatarButton({
    super.key,
    this.size = AppConstants.profileAvatarButtonSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final colorScheme = ref.watch(selectedColorSchemeProvider);

    return Padding(
      padding: EdgeInsets.only(right: AppConstants.profileAvatarButtonPadding),
      child: GestureDetector(
        onTap: () {
          // Security: Only navigate if user is authenticated
          userAsync.whenData((user) {
            if (user != null && context.mounted) {
              context.push(Routes.profile);
            }
          });
        },
        child: userAsync.when(
          data: (user) => UserAvatar(
            name: user?.name ?? AppConstants.defaultUserName,
            imageUrl: user?.avatarUrl,
            imagePath: user?.localAvatarPath,
            size: size,
          ),
          loading: () => SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: AppConstants.profileAvatarButtonLoadingStrokeWidth,
              color: DynamicTheme.getPrimaryIconColor(colorScheme),
            ),
          ),
          error: (_, __) => UserAvatar(
            name: AppConstants.defaultUserName,
            size: size,
          ),
        ),
      ),
    );
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
  
  static StatusPill lockedDynamic(Color primaryColor, AppColorScheme colorScheme) {
    // Lighten the primary color using theme-aware background color
    final lightenColor = colorScheme.isDarkTheme 
        ? colorScheme.secondary2 
        : Colors.white;
    final lightenedColor = Color.lerp(
      primaryColor, 
      lightenColor, 
      AppConstants.badgeColorLightenFactor
    );
    return StatusPill(
      text: 'Locked',
      backgroundColor: lightenedColor ?? primaryColor,
    );
  }

  factory StatusPill.unlockingSoon() {
    return const StatusPill(
      text: 'Unlocking Soon',
      backgroundColor: AppTheme.pastelPink,
      textColor: AppTheme.textDark,
    );
  }


  static StatusPill opened(AppColorScheme colorScheme) {
    // Darker green for opened badge using theme-aware dark color
    final darkenColor = colorScheme.isDarkTheme 
        ? colorScheme.primary2 
        : Colors.black;
    final darkenedColor = Color.lerp(
      AppTheme.successGreen, 
      darkenColor, 
      AppConstants.badgeColorDarkenFactor
    );
    return StatusPill(
      text: 'Opened',
      backgroundColor: darkenedColor ?? AppTheme.successGreen,
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
      alignment: Alignment.center,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
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
/// Displays countdown time instead of "Unlocking Soon" text
class AnimatedUnlockingSoonBadge extends ConsumerStatefulWidget {
  final Capsule capsule;

  const AnimatedUnlockingSoonBadge({
    super.key,
    required this.capsule,
  });

  @override
  ConsumerState<AnimatedUnlockingSoonBadge> createState() =>
      _AnimatedUnlockingSoonBadgeState();
}

class _AnimatedUnlockingSoonBadgeState
    extends ConsumerState<AnimatedUnlockingSoonBadge>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _countdownController;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    
    // Shimmer animation: random intervals (2-5 seconds) for less distracting effect
    _shimmerController = AnimationController(
      vsync: this,
      duration: _getRandomShimmerDuration(),
    );
    _startShimmerAnimation();
    
    // Countdown update: trigger rebuild every second to update countdown text
    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  /// Generates a random duration between 2-5 seconds for shimmer animation
  Duration _getRandomShimmerDuration() {
    // Random duration between 2-5 seconds (2000-5000ms)
    final milliseconds = 2000 + _random.nextInt(3000);
    return Duration(milliseconds: milliseconds);
  }

  /// Starts shimmer animation with random duration, then schedules next random interval
  void _startShimmerAnimation() {
    _shimmerController.forward().then((_) {
      if (mounted) {
        _shimmerController.reset();
        // Set new random duration for next shimmer
        _shimmerController.duration = _getRandomShimmerDuration();
        // Schedule next shimmer with random delay (2-5 seconds)
        Future.delayed(_getRandomShimmerDuration(), () {
          if (mounted) {
            _startShimmerAnimation();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _countdownController.dispose();
    super.dispose();
  }

  /// Formats countdown duration for badge display (compact format)
  String _formatCountdownForBadge(Duration duration) {
    // If duration is negative or zero, it's ready to open
    if (duration.isNegative || duration.inSeconds <= 0) {
      return 'Opens now';
    }
    
    final totalSeconds = duration.inSeconds;
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    // Calculate minutes from total seconds (not using duration.inMinutes which can truncate)
    // This ensures 1 minute is shown when there's 60+ seconds remaining
    final totalMinutes = totalSeconds ~/ 60;
    final minutes = (days > 0 || hours > 0) ? totalMinutes.remainder(60) : totalMinutes;

    String timeText;
    if (days > 0) {
      timeText = '${days}d ${hours}h';
    } else if (hours > 0) {
      timeText = '${hours}h ${minutes}m';
    } else if (totalSeconds >= 60) {
      // At least 60 seconds remaining - show minutes
      timeText = '${minutes}m';
    } else {
      return 'Opens now';
    }
    
    return 'Opens in $timeText';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    // Use accent color for the badge (magical color)
    final badgeColor = colorScheme.accent;
    final textColor = _getContrastingTextColor(badgeColor);
    
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _shimmerController,
          _countdownController, // Include countdown controller to trigger rebuilds
        ]),
        builder: (context, child) {
          // Calculate shimmer progress
          final shimmerProgress = _shimmerController.value;
          
          // Recalculate countdown text on each rebuild (updates every second)
          final currentTimeUntilUnlock = widget.capsule.timeUntilUnlock;
          final currentCountdownText = _formatCountdownForBadge(currentTimeUntilUnlock);
          
          return ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Stack(
              children: [
                // Base badge with countdown text - using StatusPill like "Ready to Open"
                StatusPill(
                  text: currentCountdownText,
                  backgroundColor: badgeColor,
                  textColor: textColor,
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
    final shimmerWidth = AppConstants.badgeShimmerWidth;
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
    final angle = AppConstants.badgeShimmerAngle;
    
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
            child: Opacity(
              opacity: AppConstants.heartbeatOpacity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // White outline icon (slightly larger, behind)
                  Icon(
                    widget.icon == Icons.favorite 
                        ? Icons.favorite_outline 
                        : (widget.icon ?? Icons.favorite_outline),
                    size: iconSize + AppConstants.iconOutlineWidth,
                    color: Colors.white,
                  ),
                  // Filled icon (on top)
                  Icon(
                    widget.icon ?? Icons.favorite, // Heart icon for ready capsules
                    size: iconSize,
                    color: iconColor,
                  ),
                ],
              ),
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
            child: Opacity(
              opacity: AppConstants.openedLetterPulseOpacity,
              child: Icon(
                widget.icon ?? Icons.check_circle, // Checkmark circle for opened letters
                size: iconSize,
                color: iconColor,
              ),
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

/// Lock emoji with white outline widget - reusable component
/// Provides consistent lock emoji styling with white outline across the app
class LockEmojiWithOutline extends StatelessWidget {
  final double iconSize;
  final double opacity;

  const LockEmojiWithOutline({
    super.key,
    required this.iconSize,
    this.opacity = AppConstants.sealedLetterOpacity,
  });

  @override
  Widget build(BuildContext context) {
    final outlineSize = iconSize + (AppConstants.iconOutlineWidth * AppConstants.lockEmojiOutlineSizeMultiplier);
    
    return Opacity(
      opacity: opacity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // White outline emoji (slightly larger, behind)
          Text(
            '🔒',
            style: TextStyle(
              fontSize: outlineSize,
              height: 1.0,
              color: Colors.white,
            ),
          ),
          // Lock emoji (on top)
          Text(
            '🔒',
            style: TextStyle(
              fontSize: iconSize,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sealed letter animation widget - rapid rotation for locked/sealed letters
/// Creates a rapid left-right rotation effect, then pauses and repeats
/// Uses lock emoji to indicate sealed state
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
            child: LockEmojiWithOutline(
              iconSize: iconSize,
              opacity: AppConstants.sealedLetterOpacity,
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

