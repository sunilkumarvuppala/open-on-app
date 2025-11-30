import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../theme/dynamic_theme.dart';
import '../theme/color_scheme.dart';

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
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary1.withOpacity(0.3),
            blurRadius: 8,
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
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

/// Animated unlocking soon badge that cycles through theme colors
/// to increase anticipation - changes color every 0.5 seconds
class AnimatedUnlockingSoonBadge extends ConsumerStatefulWidget {
  const AnimatedUnlockingSoonBadge({super.key});

  @override
  ConsumerState<AnimatedUnlockingSoonBadge> createState() =>
      _AnimatedUnlockingSoonBadgeState();
}

class _AnimatedUnlockingSoonBadgeState
    extends ConsumerState<AnimatedUnlockingSoonBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 1 second per color transition, 5 colors = 5 seconds total cycle
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getCurrentColor(AppColorScheme colorScheme, double animationValue) {
    // Cycle through 5 colors: primary1, primary2, secondary1, secondary2, accent
    final colors = [
      colorScheme.primary1,
      colorScheme.primary2,
      colorScheme.secondary1,
      colorScheme.secondary2,
      colorScheme.accent,
    ];

    // Map animation value (0-1) to cycle through all colors
    // Each color gets 0.2 of the animation (1.0 / 5 colors)
    final scaledValue = animationValue * colors.length;
    final colorIndex = scaledValue.floor() % colors.length;
    final nextColorIndex = (colorIndex + 1) % colors.length;
    
    // Get interpolation factor (0-1) for smooth transition between colors
    // Apply easeInOut curve for smoother, more gradual transitions
    final rawT = (scaledValue % 1.0);
    final t = Curves.easeInOut.transform(rawT);
    
    // Smooth interpolation between current and next color
    return Color.lerp(colors[colorIndex], colors[nextColorIndex], t)!;
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final currentColor = _getCurrentColor(colorScheme, _controller.value);
        final textColor = _getContrastingTextColor(currentColor);
        
        return StatusPill(
          text: 'Unlocking Soon',
          backgroundColor: currentColor,
          textColor: textColor,
        );
      },
    );
  }
}

