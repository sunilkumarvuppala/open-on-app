import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openon_app/core/models/connection_models.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/router/app_router.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/color_scheme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:openon_app/animations/effects/confetti_burst.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Main People screen - hub for all connection-related features
class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key});

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final incomingCount = ref.watch(incomingRequestsCountProvider);

    return Scaffold(
      backgroundColor: colorScheme.secondary2,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.secondary2,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'People',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: DynamicTheme.getPrimaryTextColor(colorScheme),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (incomingCount > 0)
              Text(
                '$incomingCount new request${incomingCount > 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DynamicTheme.getSecondaryTextColor(colorScheme),
                    ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_add_rounded,
                color: colorScheme.accent,
                size: 20,
              ),
            ),
            tooltip: 'Add Connection',
            onPressed: () {
              context.push(Routes.addConnection);
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.secondary2,
              border: Border(
                bottom: BorderSide(
                  color: DynamicTheme.getDividerColor(colorScheme),
                  width: 0.5,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: colorScheme.accent,
              indicatorWeight: 3,
              labelColor: DynamicTheme.getPrimaryTextColor(colorScheme),
              unselectedLabelColor: DynamicTheme.getSecondaryTextColor(colorScheme),
              labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Connections'),
                      if (incomingCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$incomingCount',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'Requests'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ConnectionsTabView(searchQuery: _searchQuery),
          const RequestsTabView(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(Routes.addConnection);
        },
        backgroundColor: colorScheme.accent,
        icon: const Icon(Icons.person_add_rounded, color: AppColors.white),
        label: Text(
          'Add Connection',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

/// Connections tab view - shows all mutual connections
class ConnectionsTabView extends ConsumerStatefulWidget {
  final String searchQuery;
  
  const ConnectionsTabView({super.key, this.searchQuery = ''});

  @override
  ConsumerState<ConnectionsTabView> createState() => _ConnectionsTabViewState();
}

class _ConnectionsTabViewState extends ConsumerState<ConnectionsTabView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final connectionsAsync = ref.watch(connectionsProvider);

    return connectionsAsync.when(
      data: (connections) {
        // Filter connections based on search
        final filteredConnections = _searchController.text.isEmpty
            ? connections
            : connections.where((conn) {
                final profile = conn.otherUserProfile;
                final query = _searchController.text.toLowerCase();
                return profile.displayName.toLowerCase().contains(query) ||
                    (profile.username?.toLowerCase().contains(query) ?? false);
              }).toList();

        if (filteredConnections.isEmpty && _searchController.text.isNotEmpty) {
          return Column(
            children: [
              _buildSearchBar(context, colorScheme),
              Expanded(
                child: _buildEmptySearchState(context, colorScheme),
              ),
            ],
          );
        }

        if (filteredConnections.isEmpty) {
          return Column(
            children: [
              _buildSearchBar(context, colorScheme),
              Expanded(
                child: _buildEmptyConnectionsState(context, colorScheme),
              ),
            ],
          );
        }

        return Column(
          children: [
            _buildSearchBar(context, colorScheme),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(connectionsProvider);
                },
                child: ListView.builder(
                  padding: EdgeInsets.all(AppTheme.spacingMd),
                  itemCount: filteredConnections.length,
                  itemBuilder: (context, index) {
                    final connection = filteredConnections[index];
                    return _buildConnectionCard(context, ref, connection, colorScheme);
                  },
                ),
              ),
            ),
          ],
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(
          color: colorScheme.accent,
        ),
      ),
      error: (error, stack) {
        Logger.error('Error loading connections', error: error, stackTrace: stack);
        return _buildErrorState(context, colorScheme, () {
          ref.invalidate(connectionsProvider);
        });
      },
    );
  }

  Widget _buildSearchBar(BuildContext context, AppColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.all(AppTheme.spacingMd),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: DynamicTheme.getCardBackgroundColor(colorScheme),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: DynamicTheme.getDividerColor(colorScheme),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search connections...',
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DynamicTheme.getSecondaryTextColor(colorScheme),
              ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: DynamicTheme.getSecondaryIconColor(colorScheme),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: DynamicTheme.getSecondaryIconColor(colorScheme),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
        ),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: DynamicTheme.getPrimaryTextColor(colorScheme),
            ),
      ),
    );
  }

  Widget _buildEmptyConnectionsState(
      BuildContext context, AppColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 64,
                color: colorScheme.accent,
              ),
            ),
            SizedBox(height: AppTheme.spacingXl),
            Text(
              'No Connections Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: DynamicTheme.getPrimaryTextColor(colorScheme),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: AppTheme.spacingMd),
            Text(
              'Start connecting with people to send\nand receive letters!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: DynamicTheme.getSecondaryTextColor(colorScheme),
                  ),
            ),
            SizedBox(height: AppTheme.spacingXl),
            ElevatedButton.icon(
              onPressed: () {
                context.push(Routes.addConnection);
              },
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Add Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.accent,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchState(
      BuildContext context, AppColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: DynamicTheme.getSecondaryIconColor(colorScheme),
          ),
          SizedBox(height: AppTheme.spacingLg),
          Text(
            'No results found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: DynamicTheme.getPrimaryTextColor(colorScheme),
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: AppTheme.spacingSm),
          Text(
            'Try a different search term',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DynamicTheme.getSecondaryTextColor(colorScheme),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    AppColorScheme colorScheme,
    VoidCallback onRetry,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            SizedBox(height: AppTheme.spacingLg),
            Text(
              'Failed to load connections',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: DynamicTheme.getPrimaryTextColor(colorScheme),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            SizedBox(height: AppTheme.spacingMd),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.accent,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard(
    BuildContext context,
    WidgetRef ref,
    Connection connection,
    AppColorScheme colorScheme,
  ) {
    final profile = connection.otherUserProfile;
    final timeAgo = _formatTimeAgo(connection.connectedAt);

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: DynamicTheme.getCardBackgroundColor(colorScheme),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.isDarkTheme
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showUserProfileDialog(context, connection, colorScheme),
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacingMd),
            child: Row(
              children: [
                // Avatar with status indicator
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.accent.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: colorScheme.primary1,
                        backgroundImage: profile.avatarUrl != null
                            ? CachedNetworkImageProvider(profile.avatarUrl!)
                            : null,
                        child: profile.avatarUrl == null
                            ? Text(
                                profile.displayName.isNotEmpty
                                    ? profile.displayName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : null,
                      ),
                    ),
                    // Online indicator (can be enhanced with real status)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: DynamicTheme.getCardBackgroundColor(colorScheme),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: DynamicTheme.getPrimaryTextColor(colorScheme),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      SizedBox(height: 4),
                      if (profile.username != null)
                        Text(
                          '@${profile.username}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: DynamicTheme.getSecondaryTextColor(colorScheme),
                              ),
                        )
                      else
                        Text(
                          'Connected $timeAgo',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: DynamicTheme.getSecondaryTextColor(colorScheme),
                              ),
                        ),
                    ],
                  ),
                ),
                // Action button
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _handleSendLetter(context, ref, connection, colorScheme),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.mail_outline_rounded,
                              size: 18,
                              color: colorScheme.accent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Send',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: colorScheme.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSendLetter(
    BuildContext context,
    WidgetRef ref,
    Connection connection,
    AppColorScheme colorScheme,
  ) async {
    final profile = connection.otherUserProfile;
    final currentUserAsync = ref.read(currentUserProvider);
    final currentUser = currentUserAsync.asData?.value;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please sign in to send letters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DynamicTheme.getSnackBarTextColor(colorScheme),
                ),
          ),
          backgroundColor: DynamicTheme.getSnackBarBackgroundColor(colorScheme) ?? AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    try {
      // Check if recipient exists
      final recipientsAsync = ref.read(recipientsProvider(currentUser.id));
      final recipients = await recipientsAsync.when(
        data: (data) => Future.value(data),
        loading: () => Future.value(<Recipient>[]),
        error: (_, __) => Future.value(<Recipient>[]),
      );
      
      // Find recipient by linkedUserId (connection user ID)
      Recipient? recipient = recipients.firstWhere(
        (r) => r.linkedUserId == connection.otherUserId,
        orElse: () => Recipient(
          userId: currentUser.id,
          name: profile.displayName,
          relationship: 'friend',
          avatar: profile.avatarUrl ?? '',
          linkedUserId: connection.otherUserId,
        ),
      );

      // If recipient doesn't exist, create it
      if (!recipients.any((r) => r.linkedUserId == connection.otherUserId)) {
        final recipientRepo = ref.read(recipientRepositoryProvider);
        recipient = await recipientRepo.createRecipient(
          recipient,
          linkedUserId: connection.otherUserId,
        );
      }

      // Set recipient in draft and navigate to create capsule
      ref.read(draftCapsuleProvider.notifier).setRecipient(recipient);
      
      if (context.mounted) {
        context.push(Routes.createCapsule);
      }
    } catch (e) {
      Logger.error('Error preparing to send letter', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to prepare letter: ${e.toString()}',
              style: TextStyle(
                color: DynamicTheme.getSnackBarTextColor(colorScheme),
              ),
            ),
            backgroundColor: DynamicTheme.getSnackBarBackgroundColor(colorScheme) ?? AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showUserProfileDialog(
    BuildContext context,
    Connection connection,
    AppColorScheme colorScheme,
  ) {
    final profile = connection.otherUserProfile;
    final timeAgo = _formatTimeAgo(connection.connectedAt);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DynamicTheme.getCardBackgroundColor(colorScheme),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: EdgeInsets.all(AppTheme.spacingLg),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: colorScheme.primary1,
              backgroundImage: profile.avatarUrl != null
                  ? CachedNetworkImageProvider(profile.avatarUrl!)
                  : null,
              child: profile.avatarUrl == null
                  ? Text(
                      profile.displayName.isNotEmpty
                          ? profile.displayName[0].toUpperCase()
                          : '?',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                          ),
                    )
                  : null,
            ),
            SizedBox(height: AppTheme.spacingMd),
            Text(
              profile.displayName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: DynamicTheme.getPrimaryTextColor(colorScheme),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (profile.username != null) ...[
              SizedBox(height: 4),
              Text(
                '@${profile.username}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: DynamicTheme.getSecondaryTextColor(colorScheme),
                    ),
              ),
            ],
            SizedBox(height: AppTheme.spacingLg),
            Container(
              padding: EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: colorScheme.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: colorScheme.accent,
                    size: 20,
                  ),
                  SizedBox(width: AppTheme.spacingSm),
                  Text(
                    'Connected $timeAgo',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: DynamicTheme.getPrimaryTextColor(colorScheme),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: DynamicTheme.getPrimaryTextColor(colorScheme),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

/// Requests tab view - shows incoming and outgoing requests
class RequestsTabView extends ConsumerStatefulWidget {
  const RequestsTabView({super.key});

  @override
  ConsumerState<RequestsTabView> createState() => _RequestsTabViewState();
}

class _RequestsTabViewState extends ConsumerState<RequestsTabView>
    with SingleTickerProviderStateMixin {
  late TabController _nestedTabController;

  @override
  void initState() {
    super.initState();
    _nestedTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _nestedTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final incomingCount = ref.watch(incomingRequestsCountProvider);

    return Column(
      children: [
        Container(
          margin: EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: DynamicTheme.getCardBackgroundColor(colorScheme),
            borderRadius: BorderRadius.circular(30),
          ),
          child: TabBar(
            controller: _nestedTabController,
            indicator: BoxDecoration(
              color: colorScheme.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: DynamicTheme.getDividerColor(colorScheme),
            labelColor: colorScheme.accent,
            unselectedLabelColor: DynamicTheme.getSecondaryTextColor(colorScheme),
            labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Incoming'),
                    if (incomingCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$incomingCount',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(text: 'Outgoing'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _nestedTabController,
            children: [
              _buildIncomingRequests(context, ref),
              _buildOutgoingRequests(context, ref),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIncomingRequests(BuildContext context, WidgetRef ref) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final incomingAsync = ref.watch(incomingRequestsProvider);

    // Debug logging
    print('🟡 [UI] Watching incomingRequestsProvider');
    print('🟡 [UI] AsyncValue state: ${incomingAsync.runtimeType}');
    incomingAsync.whenData((requests) {
      print('🟢 [UI] Received ${requests.length} requests in UI');
      Logger.info('Incoming requests UI - received ${requests.length} requests');
      for (var i = 0; i < requests.length; i++) {
        print('🟢 [UI] Request $i: id=${requests[i].id}, status=${requests[i].status}');
        Logger.info('UI Request $i: id=${requests[i].id}, status=${requests[i].status}');
      }
    });

    return incomingAsync.when(
      data: (requests) {
        print('🟢 [UI] Building UI with ${requests.length} requests');
        Logger.info('Building incoming requests UI with ${requests.length} requests');
        if (requests.isEmpty) {
          print('🟡 [UI] No requests, showing empty state');
          Logger.info('No incoming requests, showing empty state');
          return _buildEmptyIncomingState(context, colorScheme);
        }
        
        print('🟢 [UI] Building ListView with ${requests.length} items');
        Logger.info('Building ListView with ${requests.length} items');

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(incomingRequestsProvider);
          },
          child: ListView.builder(
            padding: EdgeInsets.all(AppTheme.spacingMd),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _buildIncomingRequestCard(context, ref, request, colorScheme);
            },
          ),
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(color: colorScheme.accent),
      ),
      error: (error, stack) {
        Logger.error('Error loading incoming requests', error: error, stackTrace: stack);
        return _buildErrorState(context, colorScheme, () {
          ref.invalidate(incomingRequestsProvider);
        });
      },
    );
  }

  Widget _buildOutgoingRequests(BuildContext context, WidgetRef ref) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final outgoingAsync = ref.watch(outgoingRequestsProvider);

    return outgoingAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return _buildEmptyOutgoingState(context, colorScheme);
        }

        // Group by status
        final pending = requests
            .where((r) => r.status == ConnectionRequestStatus.pending)
            .toList();
        final accepted = requests
            .where((r) => r.status == ConnectionRequestStatus.accepted)
            .toList();
        final declined = requests
            .where((r) => r.status == ConnectionRequestStatus.declined)
            .toList();

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(outgoingRequestsProvider);
          },
          child: ListView(
            padding: EdgeInsets.all(AppTheme.spacingMd),
            children: [
              if (pending.isNotEmpty) ...[
                _buildSectionHeader(context, 'Pending', colorScheme),
                ...pending.map((r) => _buildOutgoingRequestCard(context, ref, r, colorScheme)),
                SizedBox(height: AppTheme.spacingLg),
              ],
              if (accepted.isNotEmpty) ...[
                _buildSectionHeader(context, 'Accepted', colorScheme),
                ...accepted.map((r) => _buildOutgoingRequestCard(context, ref, r, colorScheme)),
                SizedBox(height: AppTheme.spacingLg),
              ],
              if (declined.isNotEmpty) ...[
                _buildSectionHeader(context, 'Not Accepted', colorScheme),
                ...declined.map((r) => _buildOutgoingRequestCard(context, ref, r, colorScheme)),
              ],
            ],
          ),
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(color: colorScheme.accent),
      ),
      error: (error, stack) {
        Logger.error('Error loading outgoing requests', error: error, stackTrace: stack);
        return _buildErrorState(context, colorScheme, () {
          ref.invalidate(outgoingRequestsProvider);
        });
      },
    );
  }

  Widget _buildEmptyIncomingState(BuildContext context, AppColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 64,
                color: colorScheme.accent,
              ),
            ),
            SizedBox(height: AppTheme.spacingXl),
            Text(
              'No Incoming Requests',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: DynamicTheme.getPrimaryTextColor(colorScheme),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: AppTheme.spacingMd),
            Text(
              'When someone sends you a connection\nrequest, it will appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: DynamicTheme.getSecondaryTextColor(colorScheme),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOutgoingState(BuildContext context, AppColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send_outlined,
                size: 64,
                color: colorScheme.accent,
              ),
            ),
            SizedBox(height: AppTheme.spacingXl),
            Text(
              'No Outgoing Requests',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: DynamicTheme.getPrimaryTextColor(colorScheme),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: AppTheme.spacingMd),
            Text(
              'Send connection requests to start\nconnecting with people!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: DynamicTheme.getSecondaryTextColor(colorScheme),
                  ),
            ),
            SizedBox(height: AppTheme.spacingXl),
            ElevatedButton.icon(
              onPressed: () {
                context.push(Routes.addConnection);
              },
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Add Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.accent,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    AppColorScheme colorScheme,
    VoidCallback onRetry,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            SizedBox(height: AppTheme.spacingLg),
            Text(
              'Failed to load requests',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: DynamicTheme.getPrimaryTextColor(colorScheme),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            SizedBox(height: AppTheme.spacingMd),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.accent,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, AppColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.only(
        top: AppTheme.spacingMd,
        bottom: AppTheme.spacingSm,
        left: AppTheme.spacingSm,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: DynamicTheme.getLabelTextColor(colorScheme),
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Widget _buildIncomingRequestCard(
    BuildContext context,
    WidgetRef ref,
    ConnectionRequest request,
    AppColorScheme colorScheme,
  ) {
    print('🟡 [CARD] Building incoming request card for request: ${request.id}');
    print('🟡 [CARD] fromUserProfile: ${request.fromUserProfile}');
    print('🟡 [CARD] fromUserId: ${request.fromUserId}');
    
    final profile = request.fromUserProfile;
    // Create a fallback profile if missing
    final displayProfile = profile ?? ConnectionUserProfile(
      userId: request.fromUserId,
      displayName: 'User ${request.fromUserId.substring(0, 8)}...',
      username: null,
      avatarUrl: null,
    );
    
    print('🟡 [CARD] Using profile: ${displayProfile.displayName}');

    final timeAgo = _formatTimeAgo(request.createdAt);

    print('🟢 [CARD] Building card UI with profile: ${displayProfile.displayName}');

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: DynamicTheme.getCardBackgroundColor(colorScheme),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
              color: colorScheme.accent.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.isDarkTheme
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colorScheme.primary1,
                  backgroundImage: displayProfile.avatarUrl != null
                      ? CachedNetworkImageProvider(displayProfile.avatarUrl!)
                      : null,
                  child: displayProfile.avatarUrl == null
                      ? Text(
                          displayProfile.displayName.isNotEmpty
                              ? displayProfile.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
                SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayProfile.displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: DynamicTheme.getPrimaryTextColor(colorScheme),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      SizedBox(height: 4),
                      if (displayProfile.username != null)
                        Text(
                          '@${displayProfile.username}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: DynamicTheme.getSecondaryTextColor(colorScheme),
                              ),
                        ),
                      Text(
                        timeAgo,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DynamicTheme.getSecondaryTextColor(colorScheme),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (request.message != null && request.message!.isNotEmpty) ...[
              SizedBox(height: AppTheme.spacingMd),
              Container(
                padding: EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: colorScheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.message_outlined,
                      size: 16,
                      color: colorScheme.accent,
                    ),
                    SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Text(
                        request.message!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: DynamicTheme.getPrimaryTextColor(colorScheme),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final repo = ref.read(connectionRepositoryProvider);
                        await repo.respondToRequest(
                          requestId: request.id,
                          accept: false,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Request declined',
                                style: TextStyle(
                                  color: DynamicTheme.getSnackBarTextColor(colorScheme),
                                ),
                              ),
                              backgroundColor: DynamicTheme.getSnackBarBackgroundColor(colorScheme),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error: ${e.toString()}',
                                style: TextStyle(
                                  color: DynamicTheme.getSnackBarTextColor(colorScheme),
                                ),
                              ),
                              backgroundColor: DynamicTheme.getSnackBarBackgroundColor(colorScheme) ?? AppColors.error,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      }
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: DynamicTheme.getOutlinedButtonTextColor(colorScheme),
                    ),
                    label: Text(
                      'Decline',
                      style: TextStyle(
                        color: DynamicTheme.getOutlinedButtonTextColor(colorScheme),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: DynamicTheme.getOutlinedButtonBorderColor(colorScheme),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final repo = ref.read(connectionRepositoryProvider);
                        
                        // Show confetti animation
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            barrierColor: colorScheme.isDarkTheme
                                ? Colors.black.withValues(alpha: 0.7)
                                : Colors.black.withValues(alpha: 0.3),
                            builder: (dialogContext) => PopScope(
                              canPop: false,
                              child: ConfettiBurst(
                                isActive: true,
                                onComplete: () {
                                  Navigator.of(dialogContext).pop();
                                  _showSuccessModal(request, colorScheme);
                                },
                              ),
                            ),
                          );
                        }
                        
                        await repo.respondToRequest(
                          requestId: request.id,
                          accept: true,
                        );
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.of(context).pop(); // Close confetti if open
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error: ${e.toString()}',
                                style: TextStyle(
                                  color: DynamicTheme.getSnackBarTextColor(colorScheme),
                                ),
                              ),
                              backgroundColor: DynamicTheme.getSnackBarBackgroundColor(colorScheme) ?? AppColors.error,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.accent,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessModal(
    ConnectionRequest request,
    AppColorScheme colorScheme,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DynamicTheme.getCardBackgroundColor(colorScheme),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.celebration_rounded, color: colorScheme.accent),
            const SizedBox(width: 8),
            Text(
              'Connected! ✨',
              style: TextStyle(
                color: DynamicTheme.getPrimaryTextColor(colorScheme),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'You\'re now connected with ${request.fromUserProfile?.displayName ?? 'this user'}! '
          'You can now send and receive letters.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DynamicTheme.getSecondaryTextColor(colorScheme),
              ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.accent,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildOutgoingRequestCard(
    BuildContext context,
    WidgetRef ref,
    ConnectionRequest request,
    AppColorScheme colorScheme,
  ) {
    final profile = request.toUserProfile;
    // Create a fallback profile if missing
    final displayProfile = profile ?? ConnectionUserProfile(
      userId: request.toUserId,
      displayName: 'User ${request.toUserId.substring(0, 8)}...',
      username: null,
      avatarUrl: null,
    );

    final timeAgo = _formatTimeAgo(request.createdAt);
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (request.status) {
      case ConnectionRequestStatus.pending:
        statusColor = colorScheme.isDarkTheme
            ? Colors.orange.shade300
            : Colors.orange;
        statusText = 'Pending';
        statusIcon = Icons.schedule_rounded;
        break;
      case ConnectionRequestStatus.accepted:
        statusColor = AppColors.success;
        statusText = 'Accepted';
        statusIcon = Icons.check_circle_rounded;
        break;
      case ConnectionRequestStatus.declined:
        statusColor = colorScheme.isDarkTheme
            ? Colors.grey.shade400
            : Colors.grey.shade600;
        statusText = 'Not Accepted';
        statusIcon = Icons.cancel_rounded;
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: DynamicTheme.getCardBackgroundColor(colorScheme),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.isDarkTheme
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showRequestDetailsDialog(context, request, colorScheme),
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacingMd),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colorScheme.primary1,
                  backgroundImage: displayProfile.avatarUrl != null
                      ? CachedNetworkImageProvider(displayProfile.avatarUrl!)
                      : null,
                  child: displayProfile.avatarUrl == null
                      ? Text(
                          displayProfile.displayName.isNotEmpty
                              ? displayProfile.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
                SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayProfile.displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: DynamicTheme.getPrimaryTextColor(colorScheme),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      SizedBox(height: 4),
                      if (displayProfile.username != null)
                        Text(
                          '@${displayProfile.username}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: DynamicTheme.getSecondaryTextColor(colorScheme),
                              ),
                        ),
                      Text(
                        timeAgo,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DynamicTheme.getSecondaryTextColor(colorScheme),
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
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

  void _showRequestDetailsDialog(
    BuildContext context,
    ConnectionRequest request,
    AppColorScheme colorScheme,
  ) {
    final profile = request.fromUserProfile ?? request.toUserProfile;
    // Create fallback profile
    final displayProfile = profile ?? ConnectionUserProfile(
      userId: request.fromUserId.isNotEmpty ? request.fromUserId : request.toUserId,
      displayName: 'User',
      username: null,
      avatarUrl: null,
    );

    final sentTime = _formatTimeAgo(request.createdAt);
    final statusText = request.status == ConnectionRequestStatus.pending
        ? 'Pending'
        : request.status == ConnectionRequestStatus.accepted
            ? 'Accepted'
            : 'Not Accepted';
    
    Color statusColor;
    IconData statusIcon;
    if (request.status == ConnectionRequestStatus.pending) {
      statusColor = colorScheme.isDarkTheme
          ? Colors.orange.shade300
          : Colors.orange;
      statusIcon = Icons.schedule_rounded;
    } else if (request.status == ConnectionRequestStatus.accepted) {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle_rounded;
    } else {
      statusColor = colorScheme.isDarkTheme
          ? Colors.grey.shade400
          : Colors.grey.shade600;
      statusIcon = Icons.cancel_rounded;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DynamicTheme.getCardBackgroundColor(colorScheme),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: EdgeInsets.all(AppTheme.spacingLg),
        title: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: colorScheme.primary1,
              backgroundImage: displayProfile.avatarUrl != null
                  ? CachedNetworkImageProvider(displayProfile.avatarUrl!)
                  : null,
              child: displayProfile.avatarUrl == null
                  ? Text(
                      displayProfile.displayName.isNotEmpty
                          ? displayProfile.displayName[0].toUpperCase()
                          : '?',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                    )
                  : null,
            ),
            SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayProfile.displayName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: DynamicTheme.getPrimaryTextColor(colorScheme),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (displayProfile.username != null)
                    Text(
                      '@${displayProfile.username}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DynamicTheme.getSecondaryTextColor(colorScheme),
                          ),
                    ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingSm,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 16, color: statusColor),
                  SizedBox(width: 6),
                  Text(
                    statusText,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: DynamicTheme.getSecondaryIconColor(colorScheme),
                ),
                SizedBox(width: 6),
                Text(
                  'Sent $sentTime',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DynamicTheme.getSecondaryTextColor(colorScheme),
                      ),
                ),
              ],
            ),
            if (request.message != null && request.message!.isNotEmpty) ...[
              SizedBox(height: AppTheme.spacingMd),
              Container(
                padding: EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: colorScheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.message_outlined,
                          size: 16,
                          color: colorScheme.accent,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Message',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: DynamicTheme.getLabelTextColor(colorScheme),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacingSm),
                    Text(
                      request.message!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: DynamicTheme.getPrimaryTextColor(colorScheme),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: DynamicTheme.getPrimaryTextColor(colorScheme),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
