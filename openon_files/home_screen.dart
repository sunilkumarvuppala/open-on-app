import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/router/app_router.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/models.dart';

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

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.softGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Row(
                  children: [
                    // User Avatar
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.profile),
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
                    const SizedBox(width: AppTheme.spacingMd),
                    
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
                      icon: const Icon(Icons.notifications_outlined),
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
              
              // Create New Letter Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                child: GradientButton(
                  text: '✉️  Create a New Letter',
                  onPressed: () => context.push(AppRoutes.createCapsule),
                  gradient: AppTheme.warmGradient,
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingLg),
              
              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: AppTheme.dreamyGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.textGrey,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Upcoming'),
                    Tab(text: 'Soon'),
                    Tab(text: 'Opened'),
                  ],
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingMd),
              
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    _UpcomingTab(),
                    _UnlockingSoonTab(),
                    _OpenedTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.recipients),
        icon: const Icon(Icons.people_outline),
        label: const Text('Recipients'),
        backgroundColor: AppTheme.deepPurple,
      ),
    );
  }
}

class _UpcomingTab extends ConsumerWidget {
  const _UpcomingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capsulesAsync = ref.watch(upcomingCapsulesProvider);

    return capsulesAsync.when(
      data: (capsules) {
        if (capsules.isEmpty) {
          return EmptyState(
            icon: Icons.mail_outline,
            title: 'No upcoming letters',
            message: 'Create a new letter to get started',
            action: ElevatedButton(
              onPressed: () => context.push(AppRoutes.createCapsule),
              child: const Text('Create Letter'),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
          itemCount: capsules.length,
          itemBuilder: (context, index) {
            return _CapsuleCard(capsule: capsules[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorDisplay(
        message: 'Failed to load capsules',
        onRetry: () => ref.invalidate(upcomingCapsulesProvider),
      ),
    );
  }
}

class _UnlockingSoonTab extends ConsumerWidget {
  const _UnlockingSoonTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capsulesAsync = ref.watch(unlockingSoonCapsulesProvider);

    return capsulesAsync.when(
      data: (capsules) {
        if (capsules.isEmpty) {
          return const EmptyState(
            icon: Icons.schedule,
            title: 'Nothing unlocking soon',
            message: 'Letters within 7 days will appear here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
          itemCount: capsules.length,
          itemBuilder: (context, index) {
            return _CapsuleCard(capsule: capsules[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorDisplay(
        message: 'Failed to load capsules',
        onRetry: () => ref.invalidate(unlockingSoonCapsulesProvider),
      ),
    );
  }
}

class _OpenedTab extends ConsumerWidget {
  const _OpenedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capsulesAsync = ref.watch(openedCapsulesProvider);

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
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
          itemCount: capsules.length,
          itemBuilder: (context, index) {
            return _CapsuleCard(capsule: capsules[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorDisplay(
        message: 'Failed to load capsules',
        onRetry: () => ref.invalidate(openedCapsulesProvider),
      ),
    );
  }
}

class _CapsuleCard extends StatelessWidget {
  final Capsule capsule;

  const _CapsuleCard({required this.capsule});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      child: InkWell(
        onTap: () {
          if (capsule.isOpened) {
            context.push('/capsule/${capsule.id}/opened');
          } else {
            context.push('/capsule/${capsule.id}/locked');
          }
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              // Envelope Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: capsule.isOpened 
                      ? AppTheme.softGradient 
                      : AppTheme.dreamyGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(
                  capsule.isOpened 
                      ? Icons.mark_email_read 
                      : Icons.mail,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(width: AppTheme.spacingMd),
              
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
                          StatusPill.unlockingSoon()
                        else
                          StatusPill.locked(),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      capsule.label,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Row(
                      children: [
                        Icon(
                          capsule.isOpened 
                              ? Icons.check_circle 
                              : Icons.schedule,
                          size: 14,
                          color: AppTheme.textGrey,
                        ),
                        const SizedBox(width: AppTheme.spacingXs),
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
                      const SizedBox(height: AppTheme.spacingXs),
                      CountdownDisplay(
                        duration: capsule.timeUntilUnlock,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.deepPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (capsule.reaction != null) ...[
                      const SizedBox(height: AppTheme.spacingXs),
                      Row(
                        children: [
                          Text(
                            'Reaction: ${capsule.reaction!.emoji}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
