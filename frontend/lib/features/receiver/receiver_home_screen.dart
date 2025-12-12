import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:openon_app/core/constants/app_constants.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/router/app_router.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/color_scheme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/widgets/common_widgets.dart';
import 'package:openon_app/core/widgets/magic_dust_background.dart';

class ReceiverHomeScreen extends ConsumerStatefulWidget {
  const ReceiverHomeScreen({super.key});

  @override
  ConsumerState<ReceiverHomeScreen> createState() => _ReceiverHomeScreenState();
}

class _ReceiverHomeScreenState extends ConsumerState<ReceiverHomeScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final softGradient = DynamicTheme.softGradient(colorScheme);

    return Scaffold(
      extendBody: true,
      body: MagicDustBackground(
        baseColor: colorScheme.primary1,
        child: Container(
          decoration: BoxDecoration(
            gradient: softGradient,
          ),
          child: SafeArea(
          child: Column(
            children: [
              // Header - Same structure as Sender Home
              Padding(
                padding: EdgeInsets.all(AppTheme.spacingLg),
                child: Row(
                  children: [
                    // User Avatar
                    GestureDetector(
                      onTap: () => context.push(Routes.profile),
                      child: userAsync.when(
                        data: (user) => UserAvatar(
                          name: user?.name ?? AppConstants.defaultUserName,
                          imageUrl: user?.avatarUrl,
                          imagePath: user?.localAvatarPath,
                          size: AppConstants.userAvatarSize,
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => const UserAvatar(
                          name: AppConstants.defaultUserName,
                          size: AppConstants.userAvatarSize,
                        ),
                      ),
                    ),
                    SizedBox(width: AppTheme.spacingMd),
                    
                    // Greeting
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          userAsync.when(
                            data: (user) => Text(
                              'Hi, ${user?.firstName ?? 'there'} 👋',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            loading: () => const Text('Hi 👋'),
                            error: (_, __) => const Text('Hi 👋'),
                          ),
                          Text(
                            'Your incoming letters',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    
                    // Notifications icon
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {
                        final colorScheme = ref.read(selectedColorSchemeProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Notifications coming soon!',
                              style: TextStyle(
                                color: DynamicTheme.getSnackBarTextColor(colorScheme),
                              ),
                            ),
                            backgroundColor: DynamicTheme.getSnackBarBackgroundColor(colorScheme),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // Subtle Header Separator
              Container(
                height: 1,
                margin: EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.white.withOpacity(0.0),
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              
              SizedBox(height: AppTheme.spacingLg),
              
              // Tabs - Same style as Sender Home
              Container(
                margin: EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                decoration: BoxDecoration(
                  color: colorScheme.isDarkTheme
                      ? Colors.white.withOpacity(AppTheme.opacityLow) // Semi-transparent white for dark theme
                      : Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: DynamicTheme.getTabContainerBorder(colorScheme),
                ),
                child: _AnimatedMagicalTabBar(
                  tabController: _tabController,
                  gradient: DynamicTheme.dreamyGradient(colorScheme),
                  colorScheme: colorScheme,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.lock_outline, size: 14),
                          SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              'Sealed',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.auto_awesome, size: 14),
                          SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              'Ready',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.favorite_outline, size: 14),
                          SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              'Opened',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: AppTheme.spacingMd),
              
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    _OpeningSoonTab(),
                    _LockedTab(),
                    _OpenedTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
          ),
        ),
    );
  }
}

/// Animated wrapper for TabBar with magical effects (shared with home screen)
class _AnimatedMagicalTabBar extends StatefulWidget {
  final TabController tabController;
  final Gradient gradient;
  final AppColorScheme colorScheme;
  final List<Widget> tabs;

  const _AnimatedMagicalTabBar({
    required this.tabController,
    required this.gradient,
    required this.colorScheme,
    required this.tabs,
  });

  @override
  State<_AnimatedMagicalTabBar> createState() => _AnimatedMagicalTabBarState();
}

class _AnimatedMagicalTabBarState extends State<_AnimatedMagicalTabBar>
    with TickerProviderStateMixin {
  late AnimationController _sparkleController;
  late AnimationController _breathingController;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    
    // Breathing glow animation - slow, gentle pulse
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // Slow breathing cycle
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_sparkleController, _breathingController]),
      builder: (context, child) {
        return TabBar(
          controller: widget.tabController,
          indicator: _MagicalTabIndicator(
            gradient: widget.gradient,
            colorScheme: widget.colorScheme,
            animationValue: _sparkleController.value * 2 * math.pi,
            breathingValue: _breathingController.value,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
            unselectedLabelColor: widget.colorScheme.isDarkTheme
                ? Colors.white.withOpacity(AppTheme.opacityVeryHigh) // Semi-transparent white for visibility
              : AppTheme.textGrey,
          dividerColor: Colors.transparent,
          isScrollable: false,
          tabAlignment: TabAlignment.fill,
          labelPadding: EdgeInsets.symmetric(horizontal: 4), // Reduced by 10-12px
          tabs: widget.tabs,
        );
      },
    );
  }
}

/// Custom tab indicator with magical effects: glow, sparkle animation, breathing glow, and glow ring
class _MagicalTabIndicator extends Decoration {
  final Gradient gradient;
  final AppColorScheme colorScheme;
  final double animationValue;
  final double breathingValue;

  const _MagicalTabIndicator({
    required this.gradient,
    required this.colorScheme,
    required this.animationValue,
    required this.breathingValue,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _MagicalTabIndicatorPainter(
      gradient: gradient,
      colorScheme: colorScheme,
      animationValue: animationValue,
      breathingValue: breathingValue,
      onChanged: onChanged,
    );
  }
}

class _MagicalTabIndicatorPainter extends BoxPainter {
  final Gradient gradient;
  final AppColorScheme colorScheme;
  final double animationValue;
  final double breathingValue;

  _MagicalTabIndicatorPainter({
    required this.gradient,
    required this.colorScheme,
    required this.animationValue,
    required this.breathingValue,
    VoidCallback? onChanged,
  }) : super(onChanged);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Rect rect = offset & configuration.size!;
    final double radius = AppTheme.radiusLg;

    // Main gradient background
    final Paint gradientPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      gradientPaint,
    );

    // Breathing glow effect - pulses in and out
    // Breathing value goes from 0 to 1, creating a smooth pulse
    final breathingOpacity = 0.15 + (breathingValue * 0.15); // 0.15 to 0.3 opacity
    final breathingBlur = 8 + (breathingValue * 8); // 8 to 16 blur radius
    
    final Paint breathingGlowPaint = Paint()
      ..color = colorScheme.primary1.withOpacity(breathingOpacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, breathingBlur)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      breathingGlowPaint,
    );

    // Glow ring effect
    final Paint glowPaint = Paint()
      ..color = colorScheme.primary1.withOpacity(AppTheme.opacityHigh)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(1), Radius.circular(radius)),
      glowPaint,
    );

    // Shadow/glow effect
    final Paint shadowPaint = Paint()
      ..color = colorScheme.primary1.withOpacity(AppTheme.opacityMediumHigh)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      shadowPaint,
    );

    // Sparkle micro-animation
    _drawSparkles(canvas, rect, animationValue);
  }

  void _drawSparkles(Canvas canvas, Rect rect, double time) {
    final int sparkleCount = 4; // Increased from 3 to 4
    final double centerX = rect.center.dx;
    final double centerY = rect.center.dy;
    final double maxRadius = math.min(rect.width, rect.height) * 0.35; // Increased from 0.3 to 0.35

    for (int i = 0; i < sparkleCount; i++) {
      final double angle = time + (i * 2 * math.pi / sparkleCount);
      final double radius = maxRadius * (0.3 + 0.7 * math.sin(time * 2 + i));
      final double x = centerX + math.cos(angle) * radius;
      final double y = centerY + math.sin(angle) * radius;
      final double opacity = (math.sin(time * 3 + i) + 1) / 2;
      final double size = 3 + math.sin(time * 4 + i) * 2.5; // Increased from 2 + 1.5 to 3 + 2.5

      // More visible sparkle with accent color tint
      final Paint sparklePaint = Paint()
        ..color = Colors.white.withOpacity(opacity * 0.6) // Decreased opacity for subtlety
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.8) // Reduced blur for sharper appearance
        ..style = PaintingStyle.fill;

      // Accent color glow for extra visibility
      final Paint accentGlowPaint = Paint()
        ..color = colorScheme.accent.withOpacity(opacity * 0.3) // Decreased opacity
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 1.5)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(x, y),
        size * 0.8,
        accentGlowPaint,
      );

      // Draw 4-pointed star sparkle
      final Path starPath = Path();
      for (int j = 0; j < 4; j++) {
        final double starAngle = angle + (j * math.pi / 2);
        final double outerX = x + math.cos(starAngle) * size;
        final double outerY = y + math.sin(starAngle) * size;
        if (j == 0) {
          starPath.moveTo(outerX, outerY);
        } else {
          starPath.lineTo(outerX, outerY);
        }
        final double innerAngle = starAngle + (math.pi / 4);
        final double innerX = x + math.cos(innerAngle) * (size * 0.4);
        final double innerY = y + math.sin(innerAngle) * (size * 0.4);
        starPath.lineTo(innerX, innerY);
      }
      starPath.close();
      canvas.drawPath(starPath, sparklePaint);

      // Enhanced center glow - more visible circles
      // Outer glow circle
      final Paint centerGlowPaint = Paint()
        ..color = Colors.white.withOpacity(opacity * 0.8) // Higher opacity
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 1.5) // Less blur for sharper appearance
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(x, y),
        size * 0.7, // Larger size for visibility
        centerGlowPaint,
      );
      
      // Inner solid circle for more definition
      final Paint innerCirclePaint = Paint()
        ..color = Colors.white.withOpacity(opacity * 0.9) // High opacity
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(x, y),
        size * 0.3, // Smaller inner circle
        innerCirclePaint,
      );
    }
  }
}

class _LockedTab extends ConsumerWidget {
  const _LockedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final userId = userAsync.asData?.value?.id ?? '';
    final capsulesAsync = ref.watch(incomingReadyCapsulesProvider(userId));

    return capsulesAsync.when(
      data: (capsules) {
        if (capsules.isEmpty) {
          return const EmptyState(
            icon: Icons.auto_awesome,
            title: 'No ready capsules',
            message: 'Capsules that are ready to open will appear here ✨',
          );
        }

        return ListView.builder(
          key: const PageStorageKey('incoming_ready_capsules'),
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLg,
            vertical: AppTheme.spacingSm,
          ),
          itemCount: capsules.length,
          itemBuilder: (context, index) {
            final capsule = capsules[index];
            return Padding(
              key: ValueKey('incoming_ready_${capsule.id}'),
              padding: EdgeInsets.only(bottom: AppConstants.capsuleListItemSpacing),
              child: InkWell(
                onTap: () => context.push('/capsule/${capsule.id}', extra: capsule),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                child: _ReceiverCapsuleCard(capsule: capsule),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorDisplay(
        message: 'Failed to load capsules',
        onRetry: () => ref.invalidate(incomingReadyCapsulesProvider(userId)),
      ),
    );
  }
}

class _OpeningSoonTab extends ConsumerWidget {
  const _OpeningSoonTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final userId = userAsync.asData?.value?.id ?? '';
    final capsulesAsync = ref.watch(incomingOpeningSoonCapsulesProvider(userId));

    return capsulesAsync.when(
      data: (capsules) {
        if (capsules.isEmpty) {
          return const EmptyState(
            icon: Icons.schedule_outlined,
            title: 'Nothing opening soon',
            message: 'Capsules unlocking within 7 days will appear here',
          );
        }

        return ListView.builder(
          key: const PageStorageKey('incoming_opening_soon_capsules'),
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLg,
            vertical: AppTheme.spacingSm,
          ),
          itemCount: capsules.length,
          itemBuilder: (context, index) {
            final capsule = capsules[index];
            return Padding(
              key: ValueKey('incoming_opening_soon_${capsule.id}'),
              padding: EdgeInsets.only(bottom: AppConstants.capsuleListItemSpacing),
              child: InkWell(
                onTap: () => context.push('/capsule/${capsule.id}', extra: capsule),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                child: _ReceiverCapsuleCard(capsule: capsule),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorDisplay(
        message: 'Failed to load capsules',
        onRetry: () => ref.invalidate(incomingOpeningSoonCapsulesProvider(userId)),
      ),
    );
  }
}

class _OpenedTab extends ConsumerWidget {
  const _OpenedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final userId = userAsync.asData?.value?.id ?? '';
    final capsulesAsync = ref.watch(incomingOpenedCapsulesProvider(userId));

    return capsulesAsync.when(
      data: (capsules) {
        if (capsules.isEmpty) {
          return const EmptyState(
            icon: Icons.mark_email_read_outlined,
            title: 'No opened capsules yet',
            message: 'When you open incoming capsules, they\'ll appear here',
          );
        }

        return ListView.builder(
          key: const PageStorageKey('incoming_opened_capsules'),
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLg,
            vertical: AppTheme.spacingSm,
          ),
          itemCount: capsules.length,
          itemBuilder: (context, index) {
            final capsule = capsules[index];
            return Padding(
              key: ValueKey('incoming_opened_${capsule.id}'),
              padding: EdgeInsets.only(bottom: AppConstants.capsuleListItemSpacing),
              child: InkWell(
                onTap: () => context.push('/capsule/${capsule.id}/opened', extra: capsule),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                child: _ReceiverCapsuleCard(capsule: capsule),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorDisplay(
        message: 'Failed to load capsules',
        onRetry: () => ref.invalidate(incomingOpenedCapsulesProvider(userId)),
      ),
    );
  }
}

/// Receiver capsule card - clean reference-style layout with perfect visibility
class _ReceiverCapsuleCard extends ConsumerWidget {
  final Capsule capsule;

  const _ReceiverCapsuleCard({required this.capsule});

  // Cache DateFormat instances to avoid recreating on every build
  static final _dateFormat = DateFormat('MMM dd, yyyy');
  static final _timeFormat = DateFormat('h:mm a');

  /// Builds the sealed letter icon (animated or static) based on time until unlock
  /// 
  /// Returns animated lock icon if unlock time is less than threshold,
  /// otherwise returns static lock icon for better performance and visual clarity.
  /// 
  /// This method handles edge cases:
  /// - Capsules already unlocked (should not appear due to parent condition)
  /// - Negative durations (handled by Duration comparison - negative means already unlocked)
  /// - Zero duration (treated as not meeting threshold)
  Widget _buildSealedLetterIcon(Capsule capsule, AppColorScheme colorScheme) {
    final timeUntilUnlock = capsule.timeUntilUnlock;
    
    // Theme-aware lock icon color for better visibility
    final lockIconColor = DynamicTheme.getPrimaryIconColor(colorScheme);
    
    // Only animate if time until unlock is positive (future) and less than threshold
    // Using Duration comparison for precise time-based logic
    // Duration.zero or negative durations indicate already unlocked/ready capsules
    final shouldAnimate = timeUntilUnlock > Duration.zero && 
                          timeUntilUnlock < AppConstants.sealedLetterAnimationThreshold;
    
    if (shouldAnimate) {
      return SealedLetterAnimation(
        size: AppConstants.sealedLetterIconSize,
        color: lockIconColor,
        margin: EdgeInsets.zero, // No margin since we're positioning it manually
      );
    }
    
    // Static icon for capsules with unlock time >= threshold
    // Matches animated icon appearance exactly for visual consistency
    return Opacity(
      opacity: AppConstants.sealedLetterOpacity,
      child: Icon(
        Icons.lock_outline,
        size: AppConstants.sealedLetterIconSize,
        color: lockIconColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);

    return RepaintBoundary(
      child: Stack(
        children: [
          Container(
            margin: EdgeInsets.only(bottom: AppConstants.capsuleListItemSpacing),
            decoration: BoxDecoration(
              color: DynamicTheme.getCardBackgroundColor(colorScheme),
              borderRadius: BorderRadius.circular(AppConstants.capsuleCardBorderRadius),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.isDarkTheme
                      ? Colors.black.withOpacity(AppConstants.shadowOpacityDark)
                      : Colors.black.withOpacity(AppConstants.shadowOpacityLight),
                  blurRadius: AppConstants.capsuleCardShadowBlur,
                  spreadRadius: AppConstants.capsuleCardShadowSpread,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Sender profile avatar
            UserAvatar(
              imageUrl: capsule.receiverAvatar.isNotEmpty ? capsule.receiverAvatar : null,
              name: capsule.senderName,
              size: AppConstants.capsuleCardAvatarSize,
            ),
            SizedBox(width: AppTheme.spacingMd),
            // Middle: Text content - expanded to take most space
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top section: Sender name (bold) and Badge (top-right)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sender name - takes available space
                      Expanded(
                        child: Text(
                          capsule.senderName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: DynamicTheme.getPrimaryTextColor(colorScheme),
                                fontWeight: FontWeight.w700,
                                fontSize: AppConstants.capsuleCardTitleFontSize,
                                height: AppConstants.textLineHeightTight,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: AppTheme.spacingSm),
                      // Status badge - top-right corner with fixed width
                      SizedBox(
                        width: AppConstants.badgeFixedWidth,
                        child: AnimatedScale(
                          scale: 1,
                          duration: AppConstants.badgeAnimationDuration,
                          curve: Curves.easeInOut,
                          alignment: Alignment.topRight,
                          child: capsule.isOpened
                              ? StatusPill.opened(colorScheme)
                              : capsule.isUnlocked
                                  ? StatusPill.readyToOpen()
                                  : capsule.isUnlockingSoon
                                      ? AnimatedUnlockingSoonBadge(capsule: capsule)
                                      : StatusPill.lockedDynamic(colorScheme.primary1, colorScheme),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: AppConstants.capsuleCardTitleSpacing),
                  
                  // Subject (regular weight) - single line with ellipsis
                  Flexible(
                    child: Text(
                      capsule.label,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w400, // Regular weight
                            color: DynamicTheme.getPrimaryTextColor(colorScheme),
                            fontSize: AppConstants.capsuleCardLabelFontSize,
                            height: AppConstants.textLineHeightTight,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false, // Prevent wrapping
                    ),
                  ),
                  
                  SizedBox(height: AppConstants.capsuleCardLabelSpacing * 1.5),
                  
                  // Bottom left: Date
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        capsule.isOpened 
                            ? Icons.check_circle_outline 
                            : Icons.schedule_outlined,
                        size: AppConstants.capsuleCardDateIconSize,
                        color: DynamicTheme.getSecondaryTextColor(colorScheme),
                      ),
                      SizedBox(width: AppConstants.capsuleCardDateIconSpacing),
                      Flexible(
                        child: Text(
                          capsule.isOpened
                              ? 'Opened ${_dateFormat.format(capsule.openedAt!)}'
                              : '${_dateFormat.format(capsule.unlockTime)} ${_timeFormat.format(capsule.unlockTime)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: DynamicTheme.getSecondaryTextColor(colorScheme),
                                fontSize: AppConstants.capsuleCardDateFontSize,
                                fontWeight: FontWeight.w500, // Medium weight
                                height: AppConstants.textLineHeightTight,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
            ),
          // Heartbeat animation - only show on ready capsules (bottom right of card)
          if (capsule.isUnlocked && !capsule.isOpened)
            Positioned(
              bottom: AppConstants.heartbeatBottomMargin,
              right: AppConstants.heartbeatRightMargin,
              child: HeartbeatAnimation(
                size: AppConstants.heartbeatIconSize,
                margin: EdgeInsets.zero, // No margin since we're positioning it manually
              ),
            ),
          // Opened letter pulse animation - only show on opened capsules (bottom right of card)
          if (capsule.isOpened)
            Positioned(
              bottom: AppConstants.openedLetterPulseBottomMargin,
              right: AppConstants.openedLetterPulseRightMargin,
              child: OpenedLetterPulse(
                size: AppConstants.openedLetterPulseIconSize,
                margin: EdgeInsets.zero, // No margin since we're positioning it manually
              ),
            ),
          // Sealed letter animation - only show on locked capsules (bottom right of card)
          // Animate only if unlock time is less than threshold away, otherwise show static lock icon
          // This creates anticipation as the unlock time approaches
          if (!capsule.isUnlocked && !capsule.isOpened)
            Positioned(
              bottom: AppConstants.sealedLetterBottomMargin,
              right: AppConstants.sealedLetterRightMargin,
              child: _buildSealedLetterIcon(capsule, colorScheme),
            ),
        ],
      ),
    );
  }
}

