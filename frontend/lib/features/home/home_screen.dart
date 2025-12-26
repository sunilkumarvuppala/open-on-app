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
                                  Icon(Icons.lock_outline, size: 14),
                                  SizedBox(width: AppConstants.tabSpacing),
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
                      _UpcomingTab(),
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

class _UpcomingTab extends ConsumerWidget {
  const _UpcomingTab();

  Future<void> _onRefresh(WidgetRef ref, String userId) async {
    ref.invalidate(upcomingCapsulesProvider(userId));
    ref.invalidate(capsulesProvider(userId));
    // Wait a bit for the provider to refresh
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final userId = userAsync.asData?.value?.id ?? '';
    final capsulesAsync = ref.watch(sendFilteredUpcomingCapsulesProvider(userId));
    final allCapsulesAsync = ref.watch(capsulesProvider(userId));
    final filterQuery = ref.watch(sendFilterQueryProvider);
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
            // Use whenData for safer async handling
            return allCapsulesAsync.when(
              data: (allCapsules) {
                final hasAnyLetters = allCapsules.isNotEmpty;
                
                // Show special empty state with CTA only if user has zero letters
                if (!hasAnyLetters) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: EmptyState(
                      icon: Icons.mail_outline,
                      title: 'No letters yet',
                      message: 'Start your journey by writing your first letter',
                      action: ElevatedButton(
                        onPressed: () => context.push(Routes.createCapsule),
                        child: const Text('Write your first letter'),
                      ),
                    ),
                  );
                }
                
                // Normal empty state without CTA (FAB is the creation affordance)
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: EmptyState(
                    icon: Icons.mail_outline,
                    title: 'No upcoming letters',
                    message: 'Letters scheduled to unlock will appear here',
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: EmptyState(
                  icon: Icons.mail_outline,
                  title: 'No upcoming letters',
                  message: 'Letters scheduled to unlock will appear here',
                ),
              ),
            );
          }

          return ListView.builder(
            key: const PageStorageKey('upcoming_capsules'),
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
                key: ValueKey('upcoming_${capsule.id}'),
                padding:
                    EdgeInsets.only(bottom: AppConstants.capsuleListItemSpacing),
                child: InkWell(
                  onTap: () =>
                      context.push('/capsule/${capsule.id}', extra: capsule),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  child: _CapsuleCard(capsule: capsule),
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
            onRetry: () => ref.invalidate(upcomingCapsulesProvider(userId)),
          ),
        ),
      ),
    );
  }
}

class _UnlockingSoonTab extends ConsumerWidget {
  const _UnlockingSoonTab();

  Future<void> _onRefresh(WidgetRef ref, String userId) async {
    ref.invalidate(unlockingSoonCapsulesProvider(userId));
    ref.invalidate(capsulesProvider(userId));
    // Wait a bit for the provider to refresh
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final userId = userAsync.asData?.value?.id ?? '';
    final capsulesAsync = ref.watch(sendFilteredUnlockingSoonCapsulesProvider(userId));
    final filterQuery = ref.watch(sendFilterQueryProvider);
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
                icon: Icons.schedule_outlined,
                title: 'Nothing unfolding yet',
                message: "When a letter is close to opening, you'll see it here.",
              ),
            );
          }

          return ListView.builder(
            key: const PageStorageKey('unlocking_soon_capsules'),
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
                key: ValueKey('unlocking_soon_${capsule.id}'),
                padding:
                    EdgeInsets.only(bottom: AppConstants.capsuleListItemSpacing),
                child: InkWell(
                  onTap: () =>
                      context.push('/capsule/${capsule.id}', extra: capsule),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  child: _CapsuleCard(capsule: capsule),
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
            onRetry: () => ref.invalidate(unlockingSoonCapsulesProvider(userId)),
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
    final filterQuery = ref.watch(sendFilterQueryProvider);

    return capsulesAsync.when(
      data: (capsules) {
        if (capsules.isEmpty) {
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
            // Invalidate the base provider to force refresh
            ref.invalidate(capsulesProvider(userId));
            // Wait for refresh to complete
            await Future.delayed(const Duration(milliseconds: 300));
          },
          color: colorScheme.accent,
          backgroundColor: colorScheme.isDarkTheme 
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          strokeWidth: 3.0,
          displacement: 40.0,
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
            // Invalidate the base provider to force refresh
            ref.invalidate(capsulesProvider(userId));
            // Wait for refresh to complete
            await Future.delayed(const Duration(milliseconds: 300));
          },
          color: colorScheme.accent,
          backgroundColor: colorScheme.isDarkTheme 
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          strokeWidth: 3.0,
          displacement: 40.0,
          child: ListView.builder(
            key: const PageStorageKey('opened_capsules'),
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
                key: ValueKey('opened_${capsule.id}'),
                padding:
                    EdgeInsets.only(bottom: AppConstants.capsuleListItemSpacing),
                child: InkWell(
                  onTap: () => context.push('/capsule/${capsule.id}/opened',
                      extra: capsule),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  child: _CapsuleCard(capsule: capsule),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorDisplay(
        message: 'Failed to load capsules',
        onRetry: () {
          ref.invalidate(capsulesProvider(userId));
        },
      ),
    );
  }
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

