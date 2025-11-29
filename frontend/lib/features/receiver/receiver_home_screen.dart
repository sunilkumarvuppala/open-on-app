import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/widgets/common_widgets.dart';
import 'package:openon_app/core/router/app_router.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/models/models.dart';

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
      body: Container(
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
              
              SizedBox(height: AppTheme.spacingLg),
              
              // Tabs - Same style as Sender Home
              Container(
                margin: EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: DynamicTheme.dreamyGradient(colorScheme),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.textGrey,
                  dividerColor: Colors.transparent,
                  isScrollable: false,
                  tabAlignment: TabAlignment.fill,
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
                          Icon(Icons.favorite, size: 14),
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
    );
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
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLg,
            vertical: AppTheme.spacingSm,
          ),
          itemCount: capsules.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(bottom: AppTheme.spacingMd),
              child: _ReceiverCapsuleCard(capsule: capsules[index]),
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
            icon: Icons.schedule,
            title: 'Nothing opening soon',
            message: 'Capsules unlocking within 7 days will appear here',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLg,
            vertical: AppTheme.spacingSm,
          ),
          itemCount: capsules.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(bottom: AppTheme.spacingMd),
              child: _ReceiverCapsuleCard(capsule: capsules[index]),
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
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLg,
            vertical: AppTheme.spacingSm,
          ),
          itemCount: capsules.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(bottom: AppTheme.spacingMd),
              child: _ReceiverCapsuleCard(capsule: capsules[index]),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final softGradient = DynamicTheme.softGradient(colorScheme);
    final dreamyGradient = DynamicTheme.dreamyGradient(colorScheme);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: InkWell(
        onTap: () {
          if (capsule.isOpened) {
            context.push('/capsule/${capsule.id}/opened', extra: capsule);
          } else {
            context.push('/capsule/${capsule.id}/locked', extra: capsule);
          }
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
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
                          ? Icons.mark_email_read 
                          : Icons.mail,
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
                          StatusPill.unlockingSoon()
                        else
                          StatusPill.lockedDynamic(colorScheme.primary1),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacingXs),
                    Text(
                      capsule.label,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: AppTheme.spacingXs),
                    Row(
                      children: [
                        Icon(
                          capsule.isOpened 
                              ? Icons.check_circle 
                              : Icons.schedule,
                          size: 14,
                          color: AppTheme.textGrey,
                        ),
                        SizedBox(width: AppTheme.spacingXs),
                        Expanded(
                          child: Text(
                            capsule.isOpened
                                ? 'Opened ${dateFormat.format(capsule.openedAt!)}'
                                : 'Unlocks ${dateFormat.format(capsule.unlockTime)} at ${timeFormat.format(capsule.unlockTime)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textGrey,
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
                          color: colorScheme.primary1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              Icon(
                Icons.chevron_right,
                color: AppTheme.textGrey,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

