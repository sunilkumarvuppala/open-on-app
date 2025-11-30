import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/theme/color_scheme.dart';
import 'package:openon_app/core/widgets/common_widgets.dart';
import 'package:openon_app/core/widgets/magic_dust_background.dart';
import 'package:openon_app/core/router/app_router.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/models/models.dart';

/// Custom FAB location to position it right above bottom navigation
class _CustomFABLocation extends FloatingActionButtonLocation {
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Position at bottom right, accounting for bottom nav (60px) + spacing (10px)
    final double fabX = scaffoldGeometry.scaffoldSize.width - 
        scaffoldGeometry.floatingActionButtonSize.width - 16;
    final double fabY = scaffoldGeometry.scaffoldSize.height - 
        scaffoldGeometry.floatingActionButtonSize.height - 70; // 60px nav + 10px spacing
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
              // Header
              Padding(
                padding: EdgeInsets.all(AppTheme.spacingLg),
                child: Row(
                  children: [
                    // User Avatar
                    GestureDetector(
                      onTap: () => context.push(Routes.profile),
                      child: userAsync.when(
                        data: (user) => UserAvatar(
                          name: user?.name ?? 'User',
                          imageUrl: user?.avatarUrl,
                          imagePath: user?.localAvatarPath,
                          size: 48,
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => const UserAvatar(
                          name: 'User',
                          size: 48,
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
                            'Your time capsules',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    
                    // Notifications icon
                    IconButton(
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: colorScheme.primary1,
                      ),
                      onPressed: () {
                        // TODO: Navigate to notifications
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notifications coming soon!'),
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
              
              // Create New Letter Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                child: Center(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: DynamicTheme.dreamyGradient(colorScheme),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02), // 2% opacity
                          blurRadius: 15, // Between 12-18
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => context.push(Routes.createCapsule),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.mail_outline, // Outline style envelope icon
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: AppTheme.spacingXs),
                          const Text(
                            'Create a New Letter',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Drafts Button
              Padding(
                padding: EdgeInsets.only(
                  top: AppTheme.spacingXs, // Moved closer to Create button
                  left: AppTheme.spacingLg,
                  right: AppTheme.spacingLg,
                ),
                child: Center(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final draftsCount = ref.watch(draftsCountProvider);
                      return _DraftsButton(
                        draftsCount: draftsCount,
                        colorScheme: colorScheme,
                        onTap: () => context.push(Routes.drafts),
                      );
                    },
                  ),
                ),
              ),
              
              SizedBox(height: AppTheme.spacingLg),
              
              // Tabs
              Container(
                margin: EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
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
                          SizedBox(width: 3),
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
                          Icon(Icons.lock_outline, size: 14), // Already outline version
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
                          Icon(Icons.favorite_outline, size: 14),
                          SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              'Revealed',
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(Routes.recipients);
        },
        backgroundColor: fabColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 18, color: Colors.white),
            SizedBox(width: 3),
            Text('+', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
      floatingActionButtonLocation: _CustomFABLocation(),
    );
  }
}

/// Drafts button with enhanced styling and tap glow effect
class _DraftsButton extends StatefulWidget {
  final int draftsCount;
  final AppColorScheme colorScheme;
  final VoidCallback onTap;

  const _DraftsButton({
    required this.draftsCount,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  State<_DraftsButton> createState() => _DraftsButtonState();
}

class _DraftsButtonState extends State<_DraftsButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _glowController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _glowController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _glowController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          final glowOpacity = _glowController.value * 0.15; // Very subtle glow
          
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacingSm + 4,
              vertical: AppTheme.spacingXs + 2,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              color: widget.colorScheme.primary1.withOpacity(0.08),
              border: Border.all(
                color: widget.colorScheme.primary1.withOpacity(0.12), // Reduced from 0.2 to 0.12
                width: 1,
              ),
              boxShadow: [
                // Inner shadow effect (0.5% opacity) - using subtle shadow
                BoxShadow(
                  color: Colors.black.withOpacity(0.005),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                  spreadRadius: 0,
                ),
                // Subtle glow when tapped
                if (_isPressed || _glowController.value > 0)
                  BoxShadow(
                    color: widget.colorScheme.primary1.withOpacity(glowOpacity),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Stack(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_note_outlined,
                      size: 14,
                      color: widget.colorScheme.primary1,
                    ),
                    SizedBox(width: AppTheme.spacingXs),
                    Text(
                      'Drafts (${widget.draftsCount})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: widget.colorScheme.primary1,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                // Inner shadow overlay (0.5% opacity)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.005),
                          ],
                          stops: const [0.0, 1.0],
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
    with SingleTickerProviderStateMixin {
  late AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sparkleController,
      builder: (context, child) {
        return TabBar(
          controller: widget.tabController,
          indicator: _MagicalTabIndicator(
            gradient: widget.gradient,
            colorScheme: widget.colorScheme,
            animationValue: _sparkleController.value * 2 * math.pi,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.textGrey,
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

/// Custom tab indicator with magical effects: glow, sparkle animation, and glow ring
class _MagicalTabIndicator extends Decoration {
  final Gradient gradient;
  final AppColorScheme colorScheme;
  final double animationValue;

  const _MagicalTabIndicator({
    required this.gradient,
    required this.colorScheme,
    required this.animationValue,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _MagicalTabIndicatorPainter(
      gradient: gradient,
      colorScheme: colorScheme,
      animationValue: animationValue,
      onChanged: onChanged,
    );
  }
}

class _MagicalTabIndicatorPainter extends BoxPainter {
  final Gradient gradient;
  final AppColorScheme colorScheme;
  final double animationValue;

  _MagicalTabIndicatorPainter({
    required this.gradient,
    required this.colorScheme,
    required this.animationValue,
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

    // Glow ring effect
    final Paint glowPaint = Paint()
      ..color = colorScheme.primary1.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(1), Radius.circular(radius)),
      glowPaint,
    );

    // Shadow/glow effect
    final Paint shadowPaint = Paint()
      ..color = colorScheme.primary1.withOpacity(0.2)
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

class _UpcomingTab extends ConsumerWidget {
  const _UpcomingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final userId = userAsync.asData?.value?.id ?? '';
    final capsulesAsync = ref.watch(upcomingCapsulesProvider(userId));

    return capsulesAsync.when(
      data: (capsules) {
        if (capsules.isEmpty) {
          return EmptyState(
            icon: Icons.mail_outline,
            title: 'No upcoming letters',
            message: 'Create a new letter to get started',
            action: ElevatedButton(
              onPressed: () => context.push(Routes.createCapsule),
              child: const Text('Create Letter'),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLg,
            vertical: AppTheme.spacingSm,
          ),
          itemCount: capsules.length,
          itemBuilder: (context, index) {
            final capsule = capsules[index];
            return Padding(
              padding: EdgeInsets.only(bottom: AppTheme.spacingMd),
              child: InkWell(
                onTap: () => context.push('/capsule/${capsule.id}', extra: capsule),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                child: _CapsuleCard(capsule: capsule),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorDisplay(
        message: 'Failed to load capsules',
        onRetry: () => ref.invalidate(upcomingCapsulesProvider(userId)),
      ),
    );
  }
}

class _UnlockingSoonTab extends ConsumerWidget {
  const _UnlockingSoonTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final userId = userAsync.asData?.value?.id ?? '';
    final capsulesAsync = ref.watch(unlockingSoonCapsulesProvider(userId));

    return capsulesAsync.when(
      data: (capsules) {
        if (capsules.isEmpty) {
          return const EmptyState(
            icon: Icons.schedule_outlined,
            title: 'Nothing unlocking soon',
            message: 'Letters within 7 days will appear here',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLg,
            vertical: AppTheme.spacingSm,
          ),
          itemCount: capsules.length,
          itemBuilder: (context, index) {
            final capsule = capsules[index];
            return Padding(
              padding: EdgeInsets.only(bottom: AppTheme.spacingMd),
              child: InkWell(
                onTap: () => context.push('/capsule/${capsule.id}', extra: capsule),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                child: _CapsuleCard(capsule: capsule),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorDisplay(
        message: 'Failed to load capsules',
        onRetry: () => ref.invalidate(unlockingSoonCapsulesProvider(userId)),
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
    final capsulesAsync = ref.watch(openedCapsulesProvider(userId));

    return capsulesAsync.when(
      data: (capsules) {
        if (capsules.isEmpty) {
          return const EmptyState(
            icon: Icons.mark_email_read_outlined,
            title: 'No opened letters yet',
            message: 'When recipients open your letters, they\'ll appear here',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLg,
            vertical: AppTheme.spacingSm,
          ),
          itemCount: capsules.length,
          itemBuilder: (context, index) {
            final capsule = capsules[index];
            return Padding(
              padding: EdgeInsets.only(bottom: AppTheme.spacingMd),
              child: InkWell(
                onTap: () => context.push('/capsule/${capsule.id}/opened', extra: capsule),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                child: _CapsuleCard(capsule: capsule),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorDisplay(
        message: 'Failed to load capsules',
        onRetry: () => ref.invalidate(openedCapsulesProvider(userId)),
      ),
    );
  }
}

class _CapsuleCard extends ConsumerWidget {
  final Capsule capsule;

  const _CapsuleCard({required this.capsule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final softGradient = DynamicTheme.softGradient(colorScheme);
    final dreamyGradient = DynamicTheme.dreamyGradient(colorScheme);

    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        child: Row(
          children: [
            // Envelope Icon
            Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: capsule.isOpened 
                      ? softGradient 
                      : dreamyGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(
                  capsule.isOpened 
                      ? Icons.mark_email_read_outlined 
                      : Icons.mail_outline,
                  color: Colors.white,
                ),
            ),
            
            SizedBox(width: AppTheme.spacingMd),
            
            // Content
            Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'To ${capsule.recipientName}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (capsule.isOpened)
                          StatusPill.opened()
                        else if (capsule.isUnlocked)
                          StatusPill.readyToOpen()
                        else if (capsule.isUnlockingSoon)
                          AnimatedUnlockingSoonBadge()
                        else
                          StatusPill.lockedDynamic(colorScheme.primary1),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacingXs),
                    Text(
                      capsule.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600, // Semi-bold for title
                      ),
                    ),
                    SizedBox(height: AppTheme.spacingXs),
                    Row(
                      children: [
                        Icon(
                          capsule.isOpened 
                              ? Icons.check_circle_outline 
                              : Icons.schedule_outlined,
                          size: 14,
                          color: AppTheme.textGrey, // 60% opacity for visibility
                        ),
                        SizedBox(width: AppTheme.spacingXs),
                        Expanded(
                          child: Text(
                            capsule.isOpened
                                ? 'Opened ${dateFormat.format(capsule.openedAt!)}'
                                : 'Unlocks ${dateFormat.format(capsule.unlockTime)} at ${timeFormat.format(capsule.unlockTime)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textGrey, // 60% opacity for visibility
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!capsule.isOpened && !capsule.isUnlocked) ...[
                      SizedBox(height: AppTheme.spacingXs),
                      CountdownDisplay(
                        duration: capsule.timeUntilUnlock,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.accent, // Slightly brighter accent purple
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (capsule.reaction != null) ...[
                      SizedBox(height: AppTheme.spacingXs),
                      Row(
                        children: [
                          Text(
                            'Reaction: ${capsule.reaction}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
            Icon(
              Icons.chevron_right_outlined,
              color: AppTheme.textGrey,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
