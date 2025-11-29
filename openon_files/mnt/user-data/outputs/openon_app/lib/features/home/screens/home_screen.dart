import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/router/app_router.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/features/home/widgets/capsule_card.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
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
    
    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Not authenticated')),
          );
        }
        
        return _buildHomeContent(context, user);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
  
  Widget _buildHomeContent(BuildContext context, User user) {
    final upcomingCapsules = ref.watch(upcomingCapsulesProvider(user.id));
    final unlockingSoonCapsules = ref.watch(unlockingSoonCapsulesProvider(user.id));
    final openedCapsules = ref.watch(openedCapsulesProvider(user.id));
    
    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: _buildHeader(context, user),
              ),
              SliverToBoxAdapter(
                child: _buildCreateButton(context),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.deepPurple,
                    unselectedLabelColor: AppColors.gray,
                    indicatorColor: AppColors.deepPurple,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    tabs: [
                      Tab(
                        text: 'Upcoming (${upcomingCapsules.length})',
                      ),
                      Tab(
                        text: 'Soon (${unlockingSoonCapsules.length})',
                      ),
                      Tab(
                        text: 'Opened (${openedCapsules.length})',
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildCapsuleList(upcomingCapsules, 'No upcoming letters yet'),
              _buildCapsuleList(unlockingSoonCapsules, 'No letters unlocking soon'),
              _buildCapsuleList(openedCapsules, 'No opened letters yet'),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context, User user) {
    final hour = DateTime.now().hour;
    String greeting = 'Good morning';
    if (hour >= 12 && hour < 17) {
      greeting = 'Good afternoon';
    } else if (hour >= 17) {
      greeting = 'Good evening';
    }
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.gray,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${user.name} 👋',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push(Routes.profile),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.deepPurple,
              child: Text(
                user.name[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCreateButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: () => context.push(Routes.createCapsule),
          icon: const Icon(Icons.add, size: 24),
          label: const Text('Create a new letter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.deepPurple,
            foregroundColor: AppColors.white,
          ),
        ),
      ),
    );
  }
  
  Widget _buildCapsuleList(List<Capsule> capsules, String emptyMessage) {
    if (capsules.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mail_outline,
                size: 64,
                color: AppColors.gray.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.gray,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh capsules
        ref.invalidate(capsulesProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: capsules.length,
        itemBuilder: (context, index) {
          return CapsuleCard(
            capsule: capsules[index],
            onTap: () {
              context.push(
                '/capsule/${capsules[index].id}',
                extra: capsules[index],
              );
            },
          );
        },
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  
  _TabBarDelegate(this.tabBar);
  
  @override
  double get minExtent => tabBar.preferredSize.height;
  
  @override
  double get maxExtent => tabBar.preferredSize.height;
  
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.offWhite,
      child: tabBar,
    );
  }
  
  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return false;
  }
}
