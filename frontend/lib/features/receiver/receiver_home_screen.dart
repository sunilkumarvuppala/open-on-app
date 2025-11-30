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
                            'Your incoming capsules',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    
                    // Notifications icon
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {
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
              
              SizedBox(height: AppTheme.spacingLg),
              
              // Tabs - Same style as Sender Home
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

class _LockedTab extends ConsumerWidget {
  const _LockedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final userId = userAsync.asData?.value?.id ?? '';
    final capsulesAsync = ref.watch(incomingLockedCapsulesProvider(userId));

    return capsulesAsync.when(
      data: (capsules) {
        if (capsules.isEmpty) {
          return EmptyState(
            icon: Icons.mail_outline,
            title: 'No incoming capsules yet',
            message: 'When someone sends you a time capsule, it will appear here ❤️',
            action: GradientButton(
              text: 'Share your link to receive capsules',
              onPressed: () {
                // TODO: Implement share link functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Share link feature coming soon!'),
                  ),
                );
              },
              gradient: DynamicTheme.warmGradient(
                ref.watch(selectedColorSchemeProvider),
              ),
            ),
          );
        }

        return ListView.builder(
          key: const PageStorageKey('incoming_locked_capsules'),
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLg,
            vertical: AppTheme.spacingSm,
          ),
          itemCount: capsules.length,
          itemBuilder: (context, index) {
            final capsule = capsules[index];
            return Padding(
              key: ValueKey('incoming_locked_${capsule.id}'),
              padding: EdgeInsets.only(bottom: AppTheme.spacingMd),
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
        onRetry: () => ref.invalidate(incomingLockedCapsulesProvider(userId)),
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
              padding: EdgeInsets.only(bottom: AppTheme.spacingMd),
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
              padding: EdgeInsets.only(bottom: AppTheme.spacingMd),
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

/// Receiver capsule card - matches sender card style but shows sender info
class _ReceiverCapsuleCard extends ConsumerWidget {
  final Capsule capsule;

  const _ReceiverCapsuleCard({required this.capsule});

  // Cache DateFormat instances to avoid recreating on every build
  static final _dateFormat = DateFormat('MMM dd, yyyy');
  static final _timeFormat = DateFormat('h:mm a');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            // Envelope Icon - Same style as sender, with incoming indicator
            Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: capsule.isOpened 
                      ? softGradient 
                      : dreamyGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      capsule.isOpened 
                          ? Icons.mark_email_read_outlined 
                          : Icons.mail_outline,
                      color: Colors.white,
                    ),
                    // Subtle incoming indicator badge
                    if (!capsule.isOpened)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.primary1,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
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
                            'From ${capsule.senderName} ❤️',
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
                                ? 'Opened ${_dateFormat.format(capsule.openedAt!)}'
                                : 'Unlocks ${_dateFormat.format(capsule.unlockTime)} at ${_timeFormat.format(capsule.unlockTime)}',
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

