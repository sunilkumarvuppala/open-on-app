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
import 'package:openon_app/core/widgets/inline_name_filter_bar.dart';
import 'package:openon_app/core/widgets/magic_dust_background.dart';

/// Custom FAB location to position it right above bottom navigation
/// The Scaffold's extendBody: true and SafeArea in body ensure safe area handling
class _CustomFABLocation extends FloatingActionButtonLocation {
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = scaffoldGeometry.scaffoldSize.width -
        scaffoldGeometry.floatingActionButtonSize.width -
        AppConstants.fabMargin;
    final double fabY = scaffoldGeometry.scaffoldSize.height -
        scaffoldGeometry.floatingActionButtonSize.height -
        AppConstants.fabYOffset;
    return Offset(fabX, fabY);
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
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
    // Use darker purple from gradient (primary2) to match selected tab color
    final fabColor = colorScheme.primary2;

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
                // Header - Same structure as Receiver Home
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
                              'Your outgoing letters',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),

                      // Search icon
                      Semantics(
                        label: 'Filter by name',
                        button: true,
                        child: IconButton(
                          icon: const Icon(Icons.search),
                          tooltip: 'Filter by name',
                          onPressed: () {
                            if (!mounted) return;
                            final isExpanded = ref.read(sendFilterExpandedProvider);
                            ref.read(sendFilterExpandedProvider.notifier).state = !isExpanded;
                            // Clear query when collapsing
                            if (isExpanded) {
                              ref.read(sendFilterQueryProvider.notifier).state = '';
                            }
                          },
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

                // Filter bar (inline, expands/collapses)
                InlineNameFilterBar(
                  expanded: ref.watch(sendFilterExpandedProvider),
                  query: ref.watch(sendFilterQueryProvider),
                  onChanged: (value) {
                    ref.read(sendFilterQueryProvider.notifier).state = value;
                  },
                  onClear: () {
                    ref.read(sendFilterQueryProvider.notifier).state = '';
                  },
                  onToggleExpand: () {
                    final isExpanded = ref.read(sendFilterExpandedProvider);
                    ref.read(sendFilterExpandedProvider.notifier).state = !isExpanded;
                    if (isExpanded) {
                      ref.read(sendFilterQueryProvider.notifier).state = '';
                    }
                  },
                  placeholder: 'Filter by recipient name…',
                ),

                // Tabs with Drafts link
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                  child: Column(
                    children: [
                      // Drafts button - subtle but highlighted, near tabs
                      Consumer(
                        builder: (context, ref, child) {
                          final userAsync = ref.watch(currentUserProvider);
                          final userId = userAsync.asData?.value?.id ?? '';
                          final draftsCount = ref.watch(draftsCountProvider(userId));
                          return Align(
                            alignment: Alignment.centerRight,
                            child: Semantics(
                              label: 'Drafts, $draftsCount draft${draftsCount != 1 ? 's' : ''}',
                              button: true,
                              child: TextButton(
                                onPressed: () => context.push(Routes.drafts),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingMd,
                                    vertical: AppTheme.spacingXs + 2,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor: DynamicTheme.getCardBackgroundColor(colorScheme),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                    side: BorderSide(
                                      color: DynamicTheme.getButtonBorderColor(colorScheme).withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.edit_note_outlined,
                                      size: 16,
                                      color: DynamicTheme.getPrimaryTextColor(colorScheme),
                                    ),
                                    SizedBox(width: AppTheme.spacingXs),
                                    Text(
                                      'Drafts ($draftsCount)',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: DynamicTheme.getPrimaryTextColor(colorScheme),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: AppTheme.spacingXs),
                      // Tabs container
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.isDarkTheme
                              ? Colors.white.withOpacity(AppTheme.opacityLow)
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
                                  Icon(Icons.auto_awesome, size: 14),
                                  SizedBox(width: AppConstants.tabSpacing),
                                  Flexible(
                                    child: Text(
                                      'Unfolding',
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
                                  Icon(Icons.person_outline, size: 14),
                                  SizedBox(width: AppConstants.tabSpacing),
                                  Flexible(
                                    child: Text(
                                      'Future Me',
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
                                  SizedBox(width: AppConstants.tabSpacing),
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
                    ],
                  ),
                ),
                
                SizedBox(height: AppTheme.spacingXs),
                
                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      _UnlockingSoonTab(),
                      _ForYouTab(),
                      _OpenedTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Semantics(
        label: 'Create new letter',
        button: true,
        child: FloatingActionButton(
          onPressed: () => context.push(Routes.createCapsule),
          backgroundColor: fabColor,
          elevation: 0,
          tooltip: 'Create new letter',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit_outlined,
                size: 18,
                color: DynamicTheme.getPrimaryIconColor(colorScheme),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.mail_outline,
                size: 18,
                color: DynamicTheme.getPrimaryIconColor(colorScheme),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: _CustomFABLocation(),
    );
  }
}

/// Animated wrapper for TabBar with magical effects
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
    return RepaintBoundary(
      child: AnimatedBuilder(
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
                ? Colors.white.withOpacity(AppTheme
                    .opacityVeryHigh) // Semi-transparent white for visibility
                : AppTheme.textGrey,
            dividerColor: Colors.transparent,
            isScrollable: false,
            tabAlignment: TabAlignment.fill,
            labelPadding:
                EdgeInsets.symmetric(horizontal: AppConstants.tabLabelPadding),
            tabs: widget.tabs,
          );
        },
      ),
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

// Helper class to combine capsules and self letters in a single list
class _SealedItem {
  final Capsule? capsule;
  final SelfLetter? selfLetter;
  
  _SealedItem.capsule(this.capsule) : selfLetter = null;
  _SealedItem.selfLetter(this.selfLetter) : capsule = null;
  
  bool get isSelfLetter => selfLetter != null;
  bool get isCapsule => capsule != null;
}

class _UnlockingSoonTab extends ConsumerWidget {
  const _UnlockingSoonTab();

  Future<void> _onRefresh(WidgetRef ref, String userId) async {
    // Invalidate providers to trigger refresh, then wait for smooth animation
    ref.invalidate(unlockingSoonCapsulesProvider(userId));
    ref.invalidate(upcomingCapsulesProvider(userId));
    ref.invalidate(capsulesProvider(userId));
    ref.invalidate(selfLettersProvider);
    // Small delay for smooth animation completion
    await Future.delayed(AppConstants.refreshIndicatorDelay);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final userId = userAsync.asData?.value?.id ?? '';
    final unlockingSoonAsync = ref.watch(sendFilteredUnlockingSoonCapsulesProvider(userId));
    final upcomingAsync = ref.watch(sendFilteredUpcomingCapsulesProvider(userId));
    final selfLettersAsync = ref.watch(selfLettersProvider);
    final allCapsulesAsync = ref.watch(capsulesProvider(userId));
    final filterQuery = ref.watch(sendFilterQueryProvider);
    final colorScheme = ref.watch(selectedColorSchemeProvider);

    return RefreshIndicator(
      onRefresh: () => _onRefresh(ref, userId),
      color: colorScheme.accent,
      backgroundColor: colorScheme.isDarkTheme 
          ? Colors.white.withOpacity(0.1)
          : Colors.black.withOpacity(0.05),
      strokeWidth: AppConstants.refreshIndicatorStrokeWidth,
      displacement: AppConstants.refreshIndicatorDisplacement,
      child: unlockingSoonAsync.when(
        data: (unlockingSoonCapsules) {
          return upcomingAsync.when(
            data: (upcomingCapsules) {
              // Use previous data during refresh to avoid flickering
              final selfLetters = selfLettersAsync.asData?.value ?? <SelfLetter>[];
              
              // If loading and we have no previous data, show loading
              if (selfLettersAsync.isLoading && selfLetters.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              
              // Combine all sealed letters: unlocking soon capsules + upcoming capsules
              // Note: Self letters are now shown in the "Future Me" tab, not here
              final allItems = <_SealedItem>[];
              
              // Add unlocking soon capsules first (they should appear at top)
              for (final capsule in unlockingSoonCapsules) {
                allItems.add(_SealedItem.capsule(capsule));
              }
              
              // Add upcoming (sealed) capsules
              for (final capsule in upcomingCapsules) {
                allItems.add(_SealedItem.capsule(capsule));
              }
              
              // Sort by time remaining to open in ascending order (shortest time first)
              // Note: Only capsules are shown here, self letters are in "Future Me" tab
              allItems.sort((a, b) {
                final aDuration = a.capsule!.timeUntilUnlock;
                final bDuration = b.capsule!.timeUntilUnlock;
                return aDuration.compareTo(bDuration); // Ascending order (shortest time first)
              });
              
              if (allItems.isEmpty) {
                // Show different empty state if filtering
                if (filterQuery.trim().isNotEmpty) {
                  return const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: EmptyState(
                      icon: Icons.search_off,
                      title: 'No letters found',
                      message: 'No letters found for that name.',
                    ),
                  );
                }
                
                // Check if user has zero sent letters total
                return allCapsulesAsync.when(
                  data: (allCapsules) {
                    final hasAnyLetters = allCapsules.isNotEmpty || selfLetters.isNotEmpty;
                    
                    // Show special empty state with CTA only if user has zero letters
                    if (!hasAnyLetters) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            EmptyState(
                              icon: Icons.mail_outline,
                              title: 'No letters yet',
                              message: 'Start your journey by writing your first letter',
                              action: ElevatedButton(
                                onPressed: () => context.push(Routes.createCapsule),
                                child: const Text('Write your first letter'),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    // Normal empty state
                    return const SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: EmptyState(
                        icon: Icons.schedule_outlined,
                        title: 'Nothing unfolding yet',
                        message: "When you create letters, you'll see them here.",
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: const EmptyState(
                      icon: Icons.schedule_outlined,
                      title: 'Nothing unfolding yet',
                      message: "When you create letters, you'll see them here.",
                    ),
                  ),
                );
              }

              return ListView.builder(
                key: const PageStorageKey('unfolding_items'),
                padding: EdgeInsets.only(
                  left: AppTheme.spacingLg,
                  right: AppTheme.spacingLg,
                  top: AppTheme.spacingXs,
                  bottom: AppTheme.spacingSm,
                ),
                itemCount: allItems.length,
                itemBuilder: (context, index) {
                  final item = allItems[index];
                  return Padding(
                    key: ValueKey(
                      item.isSelfLetter
                          ? 'unfolding_self_${item.selfLetter!.id}'
                          : 'unfolding_${item.capsule!.id}',
                    ),
                    padding: EdgeInsets.only(
                      bottom: AppConstants.capsuleListItemSpacing,
                    ),
                    child: InkWell(
                      onTap: () {
                        if (item.isSelfLetter) {
                          context.push(Routes.openSelfLetter(item.selfLetter!.id));
                        } else {
                          context.push('/capsule/${item.capsule!.id}', extra: item.capsule);
                        }
                      },
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      child: item.isSelfLetter
                          ? _SelfLetterCard(letter: item.selfLetter!)
                          : _CapsuleCard(capsule: item.capsule!),
                    ),
                  );
                },
              );
            },
            loading: () {
              // Show previous data if available
              // Note: Self letters are now shown in the "Future Me" tab, not here
              if (unlockingSoonCapsules.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              
              // Show what we have while loading
              final allItems = <_SealedItem>[];
              for (final capsule in unlockingSoonCapsules) {
                allItems.add(_SealedItem.capsule(capsule));
              }
              
              if (allItems.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              
              // Sort by time remaining to open in ascending order (shortest time first)
              allItems.sort((a, b) {
                final aDuration = a.capsule!.timeUntilUnlock;
                final bDuration = b.capsule!.timeUntilUnlock;
                return aDuration.compareTo(bDuration); // Ascending order (shortest time first)
              });
              
              return ListView.builder(
                key: const PageStorageKey('unfolding_items'),
                padding: EdgeInsets.only(
                  left: AppTheme.spacingLg,
                  right: AppTheme.spacingLg,
                  top: AppTheme.spacingXs,
                  bottom: AppTheme.spacingSm,
                ),
                itemCount: allItems.length,
                itemBuilder: (context, index) {
                  final item = allItems[index];
                  return Padding(
                    key: ValueKey(
                      item.isSelfLetter
                          ? 'unfolding_self_${item.selfLetter!.id}'
                          : 'unfolding_${item.capsule!.id}',
                    ),
                    padding: EdgeInsets.only(
                      bottom: AppConstants.capsuleListItemSpacing,
                    ),
                    child: InkWell(
                      onTap: () {
                        if (item.isSelfLetter) {
                          context.push(Routes.openSelfLetter(item.selfLetter!.id));
                        } else {
                          context.push('/capsule/${item.capsule!.id}', extra: item.capsule);
                        }
                      },
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      child: item.isSelfLetter
                          ? _SelfLetterCard(letter: item.selfLetter!)
                          : _CapsuleCard(capsule: item.capsule!),
                    ),
                  );
                },
              );
            },
            error: (error, stack) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ErrorDisplay(
                message: 'Failed to load capsules',
                onRetry: () => ref.invalidate(upcomingCapsulesProvider(userId)),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ErrorDisplay(
            message: 'Failed to load capsules',
            onRetry: () => ref.invalidate(unlockingSoonCapsulesProvider(userId)),
          ),
        ),
      ),
    );
  }
}

class _ForYouTab extends ConsumerWidget {
  const _ForYouTab();

  Future<void> _onRefresh(WidgetRef ref, String userId) async {
    // Invalidate provider to trigger refresh, then wait for smooth animation
    ref.invalidate(selfLettersProvider);
    await Future.delayed(AppConstants.refreshIndicatorDelay);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final userId = userAsync.asData?.value?.id ?? '';
    final selfLettersAsync = ref.watch(selfLettersProvider);
    final filterQuery = ref.watch(sendFilterQueryProvider);
    final colorScheme = ref.watch(selectedColorSchemeProvider);

    return RefreshIndicator(
      onRefresh: () => _onRefresh(ref, userId),
      color: colorScheme.accent,
      backgroundColor: colorScheme.isDarkTheme 
          ? Colors.white.withOpacity(0.1)
          : Colors.black.withOpacity(0.05),
      strokeWidth: AppConstants.refreshIndicatorStrokeWidth,
      displacement: AppConstants.refreshIndicatorDisplacement,
      child: selfLettersAsync.when(
        data: (selfLetters) {
          // Filter self letters to only sealed ones (not yet opened)
          // This includes both sealed (not yet openable) and ready to open (openable but not opened)
          final sealedSelfLetters = selfLetters.where((l) => !l.isOpened).toList();
          
          // Sort by scheduled open date (most recent first)
          sealedSelfLetters.sort((a, b) {
            return b.scheduledOpenAt.compareTo(a.scheduledOpenAt);
          });
          
          if (sealedSelfLetters.isEmpty) {
            // Show different empty state if filtering
            if (filterQuery.trim().isNotEmpty) {
              return const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: EmptyState(
                  icon: Icons.search_off,
                  title: 'No letters found',
                  message: 'No letters found for that name.',
                ),
              );
            }
            return const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: EmptyState(
                icon: Icons.person_outline,
                title: 'No letters to future you yet',
                message: "When you write letters to yourself, they'll appear here.",
              ),
            );
          }

          return ListView.builder(
            key: const PageStorageKey('future_me_items'),
            padding: EdgeInsets.only(
              left: AppTheme.spacingLg,
              right: AppTheme.spacingLg,
              top: AppTheme.spacingXs,
              bottom: AppTheme.spacingSm,
            ),
            itemCount: sealedSelfLetters.length,
            itemBuilder: (context, index) {
              final letter = sealedSelfLetters[index];
              return Padding(
                key: ValueKey('future_me_${letter.id}'),
                padding: EdgeInsets.only(
                  bottom: AppConstants.capsuleListItemSpacing,
                ),
                child: InkWell(
                  onTap: () => context.push(Routes.openSelfLetter(letter.id)),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  child: _SelfLetterCard(letter: letter),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ErrorDisplay(
            message: 'Failed to load self letters',
            onRetry: () => ref.invalidate(selfLettersProvider),
          ),
        ),
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
    final capsulesAsync = ref.watch(sendFilteredOpenedCapsulesProvider(userId));
    final selfLettersAsync = ref.watch(selfLettersProvider);
    final filterQuery = ref.watch(sendFilterQueryProvider);

    return capsulesAsync.when(
      data: (capsules) {
        // Get self letters from async value
        final selfLetters = selfLettersAsync.asData?.value ?? <SelfLetter>[];
        
        // Filter self letters to only opened ones
        final openedSelfLetters = selfLetters.where((l) => l.isOpened).toList();
        
        // Combine capsules and opened self letters
        final allItems = <_OpenedItem>[];
        
        // Add opened self letters
        for (final letter in openedSelfLetters) {
          allItems.add(_OpenedItem.selfLetter(letter));
        }
        
        // Add capsules
        for (final capsule in capsules) {
          allItems.add(_OpenedItem.capsule(capsule));
        }
        
        // Sort by opened date (most recent first)
        allItems.sort((a, b) {
          final aDate = a.isSelfLetter 
              ? (a.selfLetter!.openedAt ?? a.selfLetter!.scheduledOpenAt)
              : (a.capsule!.openedAt ?? a.capsule!.unlockAt);
          final bDate = b.isSelfLetter 
              ? (b.selfLetter!.openedAt ?? b.selfLetter!.scheduledOpenAt)
              : (b.capsule!.openedAt ?? b.capsule!.unlockAt);
          return bDate.compareTo(aDate);
        });
        
        if (allItems.isEmpty) {
        final colorScheme = ref.watch(selectedColorSchemeProvider);
        
        // Show different empty state if filtering
        final emptyState = filterQuery.trim().isNotEmpty
            ? const EmptyState(
                icon: Icons.search_off,
                title: 'No letters found',
                message: 'No letters found for that name.',
              )
            : const EmptyState(
                icon: Icons.mark_email_read_outlined,
                title: 'No opened letters yet',
                message: 'When recipients open your letters, they\'ll appear here',
              );
        
        return RefreshIndicator(
          onRefresh: () async {
            // Invalidate provider to trigger refresh, then wait for smooth animation
            ref.invalidate(capsulesProvider(userId));
            await Future.delayed(AppConstants.refreshIndicatorDelay);
          },
          color: colorScheme.accent,
          backgroundColor: colorScheme.isDarkTheme 
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          strokeWidth: AppConstants.refreshIndicatorStrokeWidth,
          displacement: AppConstants.refreshIndicatorDisplacement,
          child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: emptyState,
              ),
            ),
          );
        }

        final colorScheme = ref.watch(selectedColorSchemeProvider);
        return RefreshIndicator(
          onRefresh: () async {
            // Invalidate providers to trigger refresh, then wait for smooth animation
            ref.invalidate(capsulesProvider(userId));
            ref.invalidate(selfLettersProvider);
            await Future.delayed(AppConstants.refreshIndicatorDelay);
          },
          color: colorScheme.accent,
          backgroundColor: colorScheme.isDarkTheme 
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          strokeWidth: AppConstants.refreshIndicatorStrokeWidth,
          displacement: AppConstants.refreshIndicatorDisplacement,
          child: ListView.builder(
            key: const PageStorageKey('opened_items'),
            padding: EdgeInsets.only(
              left: AppTheme.spacingLg,
              right: AppTheme.spacingLg,
              top: AppTheme.spacingXs,
              bottom: AppTheme.spacingSm,
            ),
            itemCount: allItems.length,
            itemBuilder: (context, index) {
              final item = allItems[index];
              return Padding(
                key: ValueKey(item.isSelfLetter 
                    ? 'opened_self_${item.selfLetter!.id}'
                    : 'opened_${item.capsule!.id}'),
                padding:
                    EdgeInsets.only(bottom: AppConstants.capsuleListItemSpacing),
                child: InkWell(
                  onTap: () {
                    if (item.isSelfLetter) {
                      context.push(Routes.openSelfLetter(item.selfLetter!.id));
                    } else {
                      context.push('/capsule/${item.capsule!.id}/opened',
                          extra: item.capsule);
                    }
                  },
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  child: item.isSelfLetter
                      ? _SelfLetterCard(letter: item.selfLetter!, isOpened: true)
                      : _CapsuleCard(capsule: item.capsule!),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorDisplay(
        message: 'Failed to load items',
        onRetry: () {
          ref.invalidate(capsulesProvider(userId));
          ref.invalidate(selfLettersProvider);
        },
      ),
    );
  }
}

// Helper class to combine capsules and self letters in opened tab
class _OpenedItem {
  final Capsule? capsule;
  final SelfLetter? selfLetter;
  
  _OpenedItem.capsule(this.capsule) : selfLetter = null;
  _OpenedItem.selfLetter(this.selfLetter) : capsule = null;
  
  bool get isSelfLetter => selfLetter != null;
}

/// Outbox capsule card - matches inbox layout with badge at top-right
class _CapsuleCard extends ConsumerWidget {
  final Capsule capsule;

  const _CapsuleCard({required this.capsule});

  // Cache DateFormat instances to avoid recreating on every build
  static final _dateFormat = DateFormat('MMM dd, yyyy');
  static final _timeFormat = DateFormat('h:mm a');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);

    return RepaintBoundary(
      child: Stack(
        children: [
          Container(
            margin:
                EdgeInsets.only(bottom: AppConstants.capsuleListItemSpacing),
            decoration: BoxDecoration(
              color: DynamicTheme.getCardBackgroundColor(colorScheme),
              borderRadius:
                  BorderRadius.circular(AppConstants.capsuleCardBorderRadius),
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
                  // Left: Recipient profile avatar
                  UserAvatar(
                    imageUrl: capsule.receiverAvatar.isNotEmpty ? capsule.receiverAvatar : null,
                    name: capsule.recipientName,
                    size: AppConstants.capsuleCardAvatarSize,
                  ),
                  SizedBox(width: AppTheme.spacingMd),
                  // Middle: Text content - expanded to take most space
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top section: Recipient name (bold) and Badge (top-right)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Recipient name - takes available space
                            Expanded(
                              child: Text(
                                // Remove "To " prefix if it exists, then add it back (handles "To Self" -> "To Self" not "To To Self")
                                capsule.recipientName.toLowerCase().startsWith('to ')
                                    ? capsule.recipientName
                                    : 'To ${capsule.recipientName}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: DynamicTheme.getPrimaryTextColor(
                                          colorScheme),
                                      fontWeight: FontWeight.w700,
                                      fontSize:
                                          AppConstants.capsuleCardTitleFontSize,
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
                                            : StatusPill.lockedDynamic(
                                                colorScheme.primary1, colorScheme),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: AppConstants.capsuleCardTitleSpacing),

                        // Subject (regular weight) - single line with ellipsis
                        Flexible(
                          child: Text(
                            capsule.label,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w400, // Regular weight
                                  color: DynamicTheme.getPrimaryTextColor(
                                      colorScheme),
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
                              color: DynamicTheme.getSecondaryTextColor(
                                  colorScheme),
                            ),
                            SizedBox(
                                width: AppConstants.capsuleCardDateIconSpacing),
                            Flexible(
                              child: Text(
                                capsule.isOpened
                                    ? 'Opened ${_dateFormat.format(capsule.openedAt!)}'
                                    : '${_dateFormat.format(capsule.unlockTime)} ${_timeFormat.format(capsule.unlockTime)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: DynamicTheme.getSecondaryTextColor(
                                          colorScheme),
                                      fontSize:
                                          AppConstants.capsuleCardDateFontSize,
                                      fontWeight: FontWeight.w500, // Medium weight
                                      height: AppConstants.textLineHeightTight,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        // Reaction - below badge if present
                        if (capsule.reaction != null) ...[
                          SizedBox(
                              height: AppConstants.capsuleCardLabelSpacing),
                          Row(
                            children: [
                              Icon(
                                Icons.favorite_outline,
                                size: AppConstants.capsuleCardCountdownIconSize,
                                color: DynamicTheme.getSecondaryTextColor(
                                    colorScheme),
                              ),
                              SizedBox(
                                  width: AppConstants
                                      .capsuleCardCountdownIconSpacing),
                              Text(
                                'Reaction: ${capsule.reaction}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: DynamicTheme.getSecondaryTextColor(
                                          colorScheme),
                                      fontSize: AppConstants
                                          .capsuleCardCountdownFontSize,
                                    ),
                              ),
                            ],
                          ),
                        ],
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
                margin: EdgeInsets
                    .zero, // No margin since we're positioning it manually
              ),
            ),
          // Opened letter pulse animation - only show on opened capsules (bottom right of card)
          if (capsule.isOpened)
            Positioned(
              bottom: AppConstants.openedLetterPulseBottomMargin,
              right: AppConstants.openedLetterPulseRightMargin,
              child: OpenedLetterPulse(
                size: AppConstants.openedLetterPulseIconSize,
                margin: EdgeInsets
                    .zero, // No margin since we're positioning it manually
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
        margin:
            EdgeInsets.zero, // No margin since we're positioning it manually
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
}

/// Self letter card - similar to capsule card but for self letters
class _SelfLetterCard extends ConsumerWidget {
  final SelfLetter letter;
  final bool isOpened;

  const _SelfLetterCard({
    required this.letter,
    this.isOpened = false,
  });

  static final _dateFormat = DateFormat('MMM dd, yyyy');
  static final _timeFormat = DateFormat('h:mm a');

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
                  // Left: Self icon (no avatar for self letters)
                  Container(
                    width: AppConstants.capsuleCardAvatarSize,
                    height: AppConstants.capsuleCardAvatarSize,
                    decoration: BoxDecoration(
                      color: colorScheme.primary1.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_outline,
                      size: AppConstants.capsuleCardAvatarSize * 0.5,
                      color: colorScheme.primary1,
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingMd),
                  // Middle: Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top section: "To myself" and Badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    'To myself',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: DynamicTheme.getPrimaryTextColor(colorScheme),
                                          fontWeight: FontWeight.w700,
                                          fontSize: AppConstants.capsuleCardTitleFontSize,
                                          height: AppConstants.textLineHeightTight,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(width: AppTheme.spacingXs),
                                  // Subtle "Self" tag
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary1.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Self',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: colorScheme.primary1,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
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
                                child: isOpened
                                    ? StatusPill.opened(colorScheme)
                                    : letter.isOpenable
                                        ? StatusPill.readyToOpen()
                                        : _isSelfLetterUnlockingSoon(letter)
                                            ? _buildAnimatedUnlockingSoonBadgeForSelfLetter(letter, colorScheme)
                                            : StatusPill.lockedDynamic(
                                                colorScheme.primary1, colorScheme),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: AppConstants.capsuleCardTitleSpacing),

                        // Title (extracted from content or default)
                        Flexible(
                          child: Text(
                            _getSelfLetterTitle(letter),
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w400,
                                  color: DynamicTheme.getPrimaryTextColor(colorScheme),
                                  fontSize: AppConstants.capsuleCardLabelFontSize,
                                  height: AppConstants.textLineHeightTight,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ),

                        SizedBox(height: AppConstants.capsuleCardLabelSpacing * 1.5),

                        // Bottom: Scheduled open date (for sealed) or opened date (for opened)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isOpened ? Icons.check_circle_outline : Icons.schedule_outlined,
                              size: AppConstants.capsuleCardDateIconSize,
                              color: DynamicTheme.getSecondaryTextColor(colorScheme),
                            ),
                            SizedBox(width: AppConstants.capsuleCardDateIconSpacing),
                            Flexible(
                              child: Text(
                                isOpened && letter.openedAt != null
                                    ? 'Opened ${_dateFormat.format(letter.openedAt!)} ${_timeFormat.format(letter.openedAt!)}'
                                    : '${_dateFormat.format(letter.scheduledOpenAt)} ${_timeFormat.format(letter.scheduledOpenAt)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: DynamicTheme.getSecondaryTextColor(colorScheme),
                                      fontSize: AppConstants.capsuleCardDateFontSize,
                                      fontWeight: FontWeight.w500,
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
          // Heartbeat animation - only show on ready self letters (bottom right of card)
          if (letter.isOpenable && !letter.isOpened)
            Positioned(
              bottom: AppConstants.heartbeatBottomMargin,
              right: AppConstants.heartbeatRightMargin,
              child: HeartbeatAnimation(
                size: AppConstants.heartbeatIconSize,
                margin: EdgeInsets.zero, // No margin since we're positioning it manually
              ),
            ),
          // Opened letter pulse animation - only show on opened self letters (bottom right of card)
          if (letter.isOpened)
            Positioned(
              bottom: AppConstants.openedLetterPulseBottomMargin,
              right: AppConstants.openedLetterPulseRightMargin,
              child: OpenedLetterPulse(
                size: AppConstants.openedLetterPulseIconSize,
                margin: EdgeInsets.zero, // No margin since we're positioning it manually
              ),
            ),
          // Sealed letter animation - only show on locked self letters (bottom right of card)
          // Animate only if unlock time is less than threshold away, otherwise show static lock icon
          if (!letter.isOpenable && !letter.isOpened)
            Positioned(
              bottom: AppConstants.sealedLetterBottomMargin,
              right: AppConstants.sealedLetterRightMargin,
              child: _buildSealedSelfLetterIcon(letter, colorScheme),
            ),
        ],
      ),
    );
  }
  
  /// Get title for self letter (use provided title or fallback)
  String _getSelfLetterTitle(SelfLetter letter) {
    // Use provided title if available
    if (letter.title != null && letter.title!.trim().isNotEmpty) {
      return letter.title!.trim();
    }
    
    // Fallback: extract from content if available
    if (letter.content != null && letter.content!.isNotEmpty) {
      final content = letter.content!.trim();
      
      // Try to get first sentence (before period, exclamation, or question mark)
      final sentenceEnders = ['.', '!', '?', '\n'];
      int? firstSentenceEnd;
      for (final ender in sentenceEnders) {
        final index = content.indexOf(ender);
        if (index != -1 && (firstSentenceEnd == null || index < firstSentenceEnd)) {
          firstSentenceEnd = index;
        }
      }
      
      String title;
      if (firstSentenceEnd != null && firstSentenceEnd > 0) {
        // Use first sentence, but limit to 40 characters
        title = content.substring(0, firstSentenceEnd).trim();
        if (title.length > 40) {
          title = '${title.substring(0, 40)}...';
        }
      } else {
        // No sentence ender found, use first 30 characters
        title = content.length > 30 
            ? '${content.substring(0, 30)}...'
            : content;
      }
      
      // Remove any trailing punctuation from title
      title = title.replaceAll(RegExp(r'[.,!?;:]+$'), '');
      
      return title.isNotEmpty ? title : 'Letter to myself';
    }
    
    // Default title if no title and content not available (sealed letter)
    return 'Letter to myself';
  }
  
  /// Check if self letter is unlocking soon (within threshold days)
  bool _isSelfLetterUnlockingSoon(SelfLetter letter) {
    if (letter.isOpenable || letter.isOpened) return false;
    final timeUntilOpen = letter.timeUntilOpen;
    if (timeUntilOpen == null) return false;
    return timeUntilOpen.inDays <= AppConstants.unlockingSoonDaysThreshold;
  }
  
  /// Build animated unlocking soon badge for self letter
  Widget _buildAnimatedUnlockingSoonBadgeForSelfLetter(SelfLetter letter, AppColorScheme colorScheme) {
    // Use the same animated badge widget but create a wrapper
    return _AnimatedUnlockingSoonSelfLetterBadge(letter: letter);
  }
  
  /// Builds the sealed self letter icon (animated or static) based on time until open
  ///
  /// Returns animated lock icon if open time is less than threshold,
  /// otherwise returns static lock icon for better performance and visual consistency.
  Widget _buildSealedSelfLetterIcon(SelfLetter letter, AppColorScheme colorScheme) {
    final timeUntilOpen = letter.timeUntilOpen;
    
    // Theme-aware lock icon color for better visibility
    final lockIconColor = DynamicTheme.getPrimaryIconColor(colorScheme);
    
    // Only animate if time until open is positive (future) and less than threshold
    // Using Duration comparison for precise time-based logic
    final shouldAnimate = timeUntilOpen != null &&
        timeUntilOpen > Duration.zero &&
        timeUntilOpen < AppConstants.sealedLetterAnimationThreshold;
    
    Widget lockIcon;
    if (shouldAnimate) {
      lockIcon = SealedLetterAnimation(
        size: AppConstants.sealedLetterIconSize,
        color: lockIconColor,
        margin: EdgeInsets.zero, // No margin since we're positioning it manually
      );
    } else {
      // Static emoji icon for letters with open time >= threshold
      // Matches animated icon appearance exactly for visual consistency
      lockIcon = LockEmojiWithOutline(
        iconSize: AppConstants.sealedLetterIconSize,
        opacity: AppConstants.sealedLetterOpacity,
      );
    }
    
    return lockIcon;
  }
}

/// Animated unlocking soon badge for self letters
/// Similar to AnimatedUnlockingSoonBadge but for SelfLetter
class _AnimatedUnlockingSoonSelfLetterBadge extends ConsumerStatefulWidget {
  final SelfLetter letter;

  const _AnimatedUnlockingSoonSelfLetterBadge({
    required this.letter,
  });

  @override
  ConsumerState<_AnimatedUnlockingSoonSelfLetterBadge> createState() =>
      _AnimatedUnlockingSoonSelfLetterBadgeState();
}

class _AnimatedUnlockingSoonSelfLetterBadgeState
    extends ConsumerState<_AnimatedUnlockingSoonSelfLetterBadge>
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
  String _formatCountdownForBadge(Duration? duration) {
    if (duration == null || duration.isNegative || duration.inSeconds <= 0) {
      return 'Opens now';
    }
    
    final totalSeconds = duration.inSeconds;
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final totalMinutes = totalSeconds ~/ 60;
    final minutes = (days > 0 || hours > 0) ? totalMinutes.remainder(60) : totalMinutes;

    String timeText;
    if (days > 0) {
      timeText = '${days}d ${hours}h';
    } else if (hours > 0) {
      timeText = '${hours}h ${minutes}m';
    } else if (totalSeconds >= 60) {
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
          // Recalculate countdown text on each rebuild (updates every second)
          final currentTimeUntilOpen = widget.letter.timeUntilOpen;
          final currentCountdownText = _formatCountdownForBadge(currentTimeUntilOpen);
          
          return ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Stack(
              children: [
                // Base badge with countdown text
                StatusPill(
                  text: currentCountdownText,
                  backgroundColor: badgeColor,
                  textColor: textColor,
                ),
                // Shimmer overlay (simplified - just use opacity animation)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: _shimmerController.value * 0.3,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.0),
                              Colors.white.withOpacity(0.5),
                              Colors.white.withOpacity(0.0),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
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
  Color _getContrastingTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

