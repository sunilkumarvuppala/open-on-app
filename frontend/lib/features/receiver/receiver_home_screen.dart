import 'dart:async';
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
                padding: EdgeInsets.only(
                  left: AppTheme.spacingLg,
                  right: AppTheme.spacingLg,
                  bottom: AppTheme.spacingLg,
                ),
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
                    Semantics(
                      label: 'Notifications',
                      button: true,
                      child: IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        tooltip: 'Notifications',
                        onPressed: () {
                          // Safety check - ensure widget is still mounted
                          if (!mounted) return;
                          
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
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              // Subtle Header Separator
              Container(
                height: AppConstants.headerSeparatorHeight,
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
              
              SizedBox(height: AppTheme.spacingXs),
              
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
      duration: AppConstants.sparkleAnimationDuration,
    )..repeat();
    
    // Breathing glow animation - slow, gentle pulse
    _breathingController = AnimationController(
      vsync: this,
      duration: AppConstants.tabIndicatorBreathingAnimationDuration,
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

  // Reusable Paint objects to avoid allocation
  final Paint _gradientPaint = Paint()..style = PaintingStyle.fill;
  final Paint _sparklePaint = Paint()..style = PaintingStyle.fill;
  final Paint _accentGlowPaint = Paint()..style = PaintingStyle.fill;
  final Paint _centerGlowPaint = Paint()..style = PaintingStyle.fill;
  final Paint _innerCirclePaint = Paint()..style = PaintingStyle.fill;

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
    _gradientPaint.shader = gradient.createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      _gradientPaint,
    );

    // Sparkle micro-animation
    _drawSparkles(canvas, rect, animationValue);
  }

  void _drawSparkles(Canvas canvas, Rect rect, double time) {
    final int sparkleCount = AppConstants.tabIndicatorSparkleCount;
    final Offset center = rect.center;
    final double maxRadius = math.min(rect.width, rect.height) * 
        AppConstants.tabIndicatorMaxRadiusMultiplier;

    for (int i = 0; i < sparkleCount; i++) {
      // Calculate angle: evenly spaced around circle
      final double angle = time + (i * 2 * math.pi / sparkleCount);
      
      // Dynamic radius: pulses between min and max based on animation
      final double radiusVariation = AppConstants.tabIndicatorRadiusMinMultiplier + 
          (AppConstants.tabIndicatorRadiusRangeMultiplier * 
           math.sin(time * AppConstants.tabIndicatorAnimationSpeedRadius + i));
      final double radius = maxRadius * radiusVariation;
      
      // Convert polar coordinates to cartesian
      final double x = center.dx + math.cos(angle) * radius;
      final double y = center.dy + math.sin(angle) * radius;
      
      // Opacity: oscillates between 0 and 1
      final double opacity = (math.sin(time * AppConstants.tabIndicatorAnimationSpeedOpacity + i) + 1) / 2;
      
      // Size: oscillates between base and base + range
      final double size = AppConstants.tabIndicatorSparkleSizeBase + 
          (math.sin(time * AppConstants.tabIndicatorAnimationSpeedSize + i) * 
           AppConstants.tabIndicatorSparkleSizeRange);

      // Layer 1: Accent glow (outermost, colored)
      _accentGlowPaint
        ..color = colorScheme.accent.withOpacity(
            opacity * AppConstants.tabIndicatorAccentGlowOpacityMultiplier)
        ..maskFilter = MaskFilter.blur(
            BlurStyle.normal, size * AppConstants.tabIndicatorAccentGlowBlurMultiplier);
      canvas.drawCircle(
        Offset(x, y),
        size * AppConstants.tabIndicatorAccentGlowSizeMultiplier,
        _accentGlowPaint,
      );

      // Layer 2: Main sparkle (white circle)
      _sparklePaint
        ..color = Colors.white.withOpacity(
            opacity * AppConstants.tabIndicatorMainSparkleOpacityMultiplier)
        ..maskFilter = MaskFilter.blur(
            BlurStyle.normal, size * AppConstants.tabIndicatorMainSparkleBlurMultiplier);
      canvas.drawCircle(
        Offset(x, y),
        size,
        _sparklePaint,
      );

      // Layer 3: Center glow (white, larger blur)
      _centerGlowPaint
        ..color = Colors.white.withOpacity(
            opacity * AppConstants.tabIndicatorCenterGlowOpacityMultiplier)
        ..maskFilter = MaskFilter.blur(
            BlurStyle.normal, size * AppConstants.tabIndicatorCenterGlowBlurMultiplier);
      canvas.drawCircle(
        Offset(x, y),
        size * AppConstants.tabIndicatorCenterGlowSizeMultiplier,
        _centerGlowPaint,
      );

      // Layer 4: Inner circle (brightest, smallest)
      _innerCirclePaint.color = Colors.white.withOpacity(
          opacity * AppConstants.tabIndicatorInnerCircleOpacityMultiplier);
      canvas.drawCircle(
        Offset(x, y),
        size * AppConstants.tabIndicatorInnerCircleSizeMultiplier,
        _innerCirclePaint,
      );
    }
  }
}

class _LockedTab extends ConsumerWidget {
  const _LockedTab();

  Future<void> _onRefresh(WidgetRef ref, String userId) async {
    ref.invalidate(incomingReadyCapsulesProvider(userId));
    ref.invalidate(incomingCapsulesProvider(userId));
    // Wait a bit for the provider to refresh
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final userId = userAsync.asData?.value?.id ?? '';
    final capsulesAsync = ref.watch(incomingReadyCapsulesProvider(userId));
    final colorScheme = ref.watch(selectedColorSchemeProvider);

    return RefreshIndicator(
      onRefresh: () => _onRefresh(ref, userId),
      color: colorScheme.accent,
      backgroundColor: colorScheme.isDarkTheme 
          ? Colors.white.withOpacity(0.1)
          : Colors.black.withOpacity(0.05),
      strokeWidth: 3.0,
      displacement: 40.0,
      child: capsulesAsync.when(
        data: (capsules) {
          if (capsules.isEmpty) {
            return const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: EmptyState(
                icon: Icons.auto_awesome,
                title: 'No ready Letters',
                message: 'Letters that are ready to open will appear here ✨',
              ),
            );
          }

          return ListView.builder(
            key: const PageStorageKey('incoming_ready_capsules'),
            padding: EdgeInsets.only(
              left: AppTheme.spacingLg,
              right: AppTheme.spacingLg,
              top: AppTheme.spacingXs,
              bottom: AppTheme.spacingSm,
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
        error: (error, stack) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ErrorDisplay(
            message: 'Failed to load capsules',
            onRetry: () => ref.invalidate(incomingReadyCapsulesProvider(userId)),
          ),
        ),
      ),
    );
  }
}

class _OpeningSoonTab extends ConsumerWidget {
  const _OpeningSoonTab();

  Future<void> _onRefresh(WidgetRef ref, String userId) async {
    ref.invalidate(incomingOpeningSoonCapsulesProvider(userId));
    ref.invalidate(incomingCapsulesProvider(userId));
    // Wait a bit for the provider to refresh
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final userId = userAsync.asData?.value?.id ?? '';
    final capsulesAsync = ref.watch(incomingOpeningSoonCapsulesProvider(userId));
    final colorScheme = ref.watch(selectedColorSchemeProvider);

    return RefreshIndicator(
      onRefresh: () => _onRefresh(ref, userId),
      color: colorScheme.accent,
      backgroundColor: colorScheme.isDarkTheme 
          ? Colors.white.withOpacity(0.1)
          : Colors.black.withOpacity(0.05),
      strokeWidth: 3.0,
      displacement: 40.0,
      child: capsulesAsync.when(
        data: (capsules) {
          if (capsules.isEmpty) {
            return const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: EmptyState(
                icon: Icons.schedule_outlined,
                title: 'Nothing opening soon',
                message: 'Letters unlocking soon will appear here',
              ),
            );
          }

          return ListView.builder(
            key: const PageStorageKey('incoming_opening_soon_capsules'),
            padding: EdgeInsets.only(
              left: AppTheme.spacingLg,
              right: AppTheme.spacingLg,
              top: AppTheme.spacingXs,
              bottom: AppTheme.spacingSm,
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
        error: (error, stack) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ErrorDisplay(
            message: 'Failed to load capsules',
            onRetry: () => ref.invalidate(incomingOpeningSoonCapsulesProvider(userId)),
          ),
        ),
      ),
    );
  }
}

class _OpenedTab extends ConsumerWidget {
  const _OpenedTab();

  Future<void> _onRefresh(WidgetRef ref, String userId) async {
    ref.invalidate(incomingOpenedCapsulesProvider(userId));
    ref.invalidate(incomingCapsulesProvider(userId));
    // Wait a bit for the provider to refresh
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final userId = userAsync.asData?.value?.id ?? '';
    final capsulesAsync = ref.watch(incomingOpenedCapsulesProvider(userId));
    final colorScheme = ref.watch(selectedColorSchemeProvider);

    return RefreshIndicator(
      onRefresh: () => _onRefresh(ref, userId),
      color: colorScheme.accent,
      backgroundColor: colorScheme.isDarkTheme 
          ? Colors.white.withOpacity(0.1)
          : Colors.black.withOpacity(0.05),
      strokeWidth: 3.0,
      displacement: 40.0,
      child: capsulesAsync.when(
        data: (capsules) {
          if (capsules.isEmpty) {
            return const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: EmptyState(
                icon: Icons.mark_email_read_outlined,
                title: 'No opened letters yet',
                message: 'When you open incoming letters, they\'ll appear here',
              ),
            );
          }

          return ListView.builder(
            key: const PageStorageKey('incoming_opened_capsules'),
            padding: EdgeInsets.only(
              left: AppTheme.spacingLg,
              right: AppTheme.spacingLg,
              top: AppTheme.spacingXs,
              bottom: AppTheme.spacingSm,
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
        error: (error, stack) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ErrorDisplay(
            message: 'Failed to load capsules',
            onRetry: () => ref.invalidate(incomingOpenedCapsulesProvider(userId)),
          ),
        ),
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
    
    // Check if capsule is anonymous and not yet revealed
    final isAnonymous = capsule.isAnonymous && !capsule.isRevealed;
    
    Widget lockIcon;
    if (shouldAnimate) {
      lockIcon = SealedLetterAnimation(
        size: AppConstants.sealedLetterIconSize,
        color: lockIconColor,
        margin: EdgeInsets.zero, // No margin since we're positioning it manually
      );
    } else {
      // Static emoji icon for capsules with unlock time >= threshold
      // Matches animated icon appearance exactly for visual consistency
      lockIcon = LockEmojiWithOutline(
        iconSize: AppConstants.sealedLetterIconSize,
        opacity: AppConstants.sealedLetterOpacity,
      );
    }
    
    // If anonymous, show anonymous icon first, then lock icon
    if (isAnonymous) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.visibility_off_outlined,
            size: AppConstants.sealedLetterIconSize * 0.7,
            color: lockIconColor.withOpacity(AppConstants.sealedLetterOpacity),
          ),
          SizedBox(width: 4),
          lockIcon,
        ],
      );
    }
    
    return lockIcon;
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
              padding: EdgeInsets.all(AppTheme.spacingSm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
            // Left: Sender profile avatar (or animated incognito icon for anonymous)
            capsule.isAnonymous && !capsule.isRevealed
                ? _AnimatedAnonymousIcon(colorScheme: colorScheme)
                : UserAvatar(
                    imageUrl: capsule.displaySenderAvatar.isNotEmpty ? capsule.displaySenderAvatar : null,
                    name: capsule.displaySenderName,
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
                          capsule.displaySenderName,
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

/// Animated anonymous icon that alternates between two icons
class _AnimatedAnonymousIcon extends StatefulWidget {
  final AppColorScheme colorScheme;
  
  const _AnimatedAnonymousIcon({required this.colorScheme});
  
  @override
  State<_AnimatedAnonymousIcon> createState() => _AnimatedAnonymousIconState();
}

class _AnimatedAnonymousIconState extends State<_AnimatedAnonymousIcon> {
  int _currentIconIndex = 0;
  late Timer _timer;
  
  final List<IconData> _icons = [
    Icons.account_circle,
    Icons.help_outline,
  ];
  
  @override
  void initState() {
    super.initState();
    // Switch icons every 2.5 seconds (average of 2-3 seconds)
    // Using a slightly longer interval to allow fade transition to complete smoothly
    _timer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (mounted) {
        setState(() {
          _currentIconIndex = (_currentIconIndex + 1) % _icons.length;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppConstants.capsuleCardAvatarSize,
      height: AppConstants.capsuleCardAvatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: DynamicTheme.getSecondaryTextColor(widget.colorScheme).withOpacity(0.15), // Darker background for incognito look
        border: Border.all(
          color: DynamicTheme.getSecondaryTextColor(widget.colorScheme).withOpacity(0.3),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.colorScheme.primary1.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 800), // Longer duration for smooth fade
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          // Smooth fade transition with ease curves
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        child: Icon(
          _icons[_currentIconIndex],
          key: ValueKey<int>(_currentIconIndex), // Key ensures AnimatedSwitcher recognizes the change
          size: AppConstants.capsuleCardAvatarSize * 0.5,
          color: DynamicTheme.getSecondaryTextColor(widget.colorScheme).withOpacity(0.6), // Muted color for incognito
        ),
      ),
    );
  }
}

