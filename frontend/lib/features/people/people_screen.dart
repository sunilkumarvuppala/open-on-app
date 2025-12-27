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
import 'package:openon_app/core/constants/app_constants.dart';
import 'package:openon_app/core/widgets/common_widgets.dart';
import 'package:openon_app/animations/effects/confetti_burst.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Custom FAB location to position it right above bottom navigation
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
          ProfileAvatarButton(),
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
                                  color: Colors.white, // Error badge always uses white text on red background
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(Routes.addConnection);
        },
        backgroundColor: colorScheme.primary2,
        elevation: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_add_rounded, size: 18, color: DynamicTheme.getPrimaryIconColor(colorScheme)),
            SizedBox(width: AppConstants.tabSpacing),
            Text('+', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DynamicTheme.getPrimaryIconColor(colorScheme))),
          ],
        ),
      ),
      floatingActionButtonLocation: _CustomFABLocation(),
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

    return Column(
      children: [
        _buildSearchBar(context, colorScheme),
        Expanded(
          child: connectionsAsync.when(
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
                return RefreshIndicator(
                  onRefresh: () async {
                    // StreamProvider doesn't have .future, use invalidate() and wait a bit
                    ref.invalidate(connectionsProvider);
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
                    child: _buildEmptySearchState(context, colorScheme),
                  ),
                );
              }

              if (filteredConnections.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async {
                    // StreamProvider doesn't have .future, use invalidate() and wait a bit
                    ref.invalidate(connectionsProvider);
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
                    child: _buildEmptyConnectionsState(context, colorScheme),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  // StreamProvider doesn't have .future, use invalidate() and wait a bit
                  ref.invalidate(connectionsProvider);
                  await Future.delayed(AppConstants.refreshIndicatorDelay);
                },
                color: colorScheme.accent,
                backgroundColor: colorScheme.isDarkTheme 
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                strokeWidth: AppConstants.refreshIndicatorStrokeWidth,
                displacement: AppConstants.refreshIndicatorDisplacement,
                child: ListView.builder(
                  padding: EdgeInsets.only(
                    left: AppTheme.spacingMd,
                    right: AppTheme.spacingMd,
                    top: AppTheme.spacingXs,
                    bottom: AppTheme.spacingMd,
                  ),
                  itemCount: filteredConnections.length,
                  itemBuilder: (context, index) {
                    final connection = filteredConnections[index];
                    return _buildConnectionCard(context, ref, connection, colorScheme);
                  },
                ),
              );
            },
            loading: () => Center(
              child: CircularProgressIndicator(
                color: colorScheme.accent,
              ),
            ),
            error: (error, stack) {
              // Only show error if we've been loading for a while
              // This prevents showing error immediately on first load
              Logger.error('Error loading connections', error: error, stackTrace: stack);
              
              // Check if this is a transient error by checking if we have any cached data
              final cachedData = connectionsAsync.asData?.value;
              if (cachedData != null && cachedData.isNotEmpty) {
                // We have cached data, show it instead of error
                return RefreshIndicator(
                  onRefresh: () async {
                    // StreamProvider doesn't have .future, use invalidate() and wait a bit
                    ref.invalidate(connectionsProvider);
                    await Future.delayed(AppConstants.refreshIndicatorDelay);
                  },
                  color: colorScheme.accent,
                  backgroundColor: colorScheme.isDarkTheme 
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  strokeWidth: AppConstants.refreshIndicatorStrokeWidth,
                  displacement: AppConstants.refreshIndicatorDisplacement,
                  child: ListView.builder(
                    padding: EdgeInsets.only(
                      left: AppTheme.spacingMd,
                      right: AppTheme.spacingMd,
                      top: AppTheme.spacingXs,
                      bottom: AppTheme.spacingMd,
                    ),
                    itemCount: cachedData.length,
                    itemBuilder: (context, index) {
                      final connection = cachedData[index];
                      return _buildConnectionCard(context, ref, connection, colorScheme);
                    },
                  ),
                );
              }
              
              return _buildErrorState(context, colorScheme, () {
                ref.invalidate(connectionsProvider);
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, AppColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacingMd,
        right: AppTheme.spacingMd,
        top: AppTheme.spacingMd,
        bottom: AppTheme.spacingXs,
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
          filled: true,
          fillColor: DynamicTheme.getCardBackgroundColor(colorScheme),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: DynamicTheme.getDividerColor(colorScheme),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: DynamicTheme.getDividerColor(colorScheme),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: colorScheme.accent,
              width: 2,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: DynamicTheme.getDividerColor(colorScheme),
              width: 1,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: AppColors.error,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: AppColors.error,
              width: 2,
            ),
          ),
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
                foregroundColor: DynamicTheme.getButtonTextColor(colorScheme),
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
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
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
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: () {
            // Navigate to full connection detail screen
            // The provider will use cached user data to reduce delay
            context.push('/connection/${connection.otherUserId}');
          },
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacingMd),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar with status indicator
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    UserAvatar(
                      imageUrl: profile.avatarUrl,
                      name: profile.displayName,
                      size: AppConstants.connectionCardAvatarRadius * 2,
                    ),
                    // Online indicator (can be enhanced with real status)
                    Positioned(
                      right: -AppConstants.connectionCardStatusIndicatorBorderWidth,
                      bottom: -AppConstants.connectionCardStatusIndicatorBorderWidth,
                      child: Container(
                        width: AppConstants.connectionCardStatusIndicatorSize,
                        height: AppConstants.connectionCardStatusIndicatorSize,
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: DynamicTheme.getCardBackgroundColor(colorScheme),
                            width: AppConstants.connectionCardStatusIndicatorBorderWidth,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: AppTheme.spacingSm),
                // User info - takes available space
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        profile.displayName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: DynamicTheme.getPrimaryTextColor(colorScheme),
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      if (profile.username != null)
                        Text(
                          '@${profile.username}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: DynamicTheme.getSecondaryTextColor(colorScheme),
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          'Connected $timeAgo',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: DynamicTheme.getSecondaryTextColor(colorScheme),
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                SizedBox(width: AppTheme.spacingXs),
                // Thought button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    onTap: () {
                      // Stop propagation to prevent card navigation
                      _handleSendThought(context, ref, connection, colorScheme);
                    },
                    child: Container(
                      padding: EdgeInsets.all(AppTheme.spacingXs + 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primary2.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Icon(
                        Icons.favorite_border_rounded,
                        size: AppConstants.connectionCardButtonIconSize + 2,
                        color: colorScheme.primary2,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppTheme.spacingXs),
                // Action button - fixed width to prevent layout shifts
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    onTap: () {
                      // Stop propagation to prevent card navigation
                      _handleSendLetter(context, ref, connection, colorScheme);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSm,
                        vertical: AppTheme.spacingXs,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.mail_outline_rounded,
                            size: AppConstants.connectionCardButtonIconSize,
                            color: colorScheme.accent,
                          ),
                          SizedBox(width: AppTheme.spacingXs),
                          Text(
                            'Send',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: colorScheme.accent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                          ),
                        ],
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

  Future<void> _handleSendThought(
    BuildContext context,
    WidgetRef ref,
    Connection connection,
    AppColorScheme colorScheme,
  ) async {
    final profile = connection.otherUserProfile;
    final receiverId = connection.otherUserId;
    
    // Validate receiver ID
    if (receiverId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invalid receiver. Please try again.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DynamicTheme.getSnackBarTextColor(colorScheme) ?? Colors.white,
                  ),
            ),
            backgroundColor: DynamicTheme.getSnackBarBackgroundColor(colorScheme) ?? AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }
    
    // Get current user ID for validation
    final currentUserAsync = ref.read(currentUserProvider);
    final currentUser = currentUserAsync.asData?.value;
    if (currentUser != null && currentUser.id == receiverId) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot send thought to yourself',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DynamicTheme.getSnackBarTextColor(colorScheme) ?? Colors.white,
                  ),
            ),
            backgroundColor: DynamicTheme.getSnackBarBackgroundColor(colorScheme) ?? AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }
    
    Logger.debug('Sending thought: currentUserId=${currentUser?.id}, receiverId=$receiverId, connection.otherUserId=${connection.otherUserId}');
    
    // Get the send thought controller
    final controller = ref.read(sendThoughtControllerProvider.notifier);
    
    // Show loading indicator
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    DynamicTheme.getSnackBarTextColor(colorScheme) ?? Colors.white,
                  ),
                ),
              ),
              SizedBox(width: AppTheme.spacingSm),
              Text(
                'Sending thought...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: DynamicTheme.getSnackBarTextColor(colorScheme),
                    ),
              ),
            ],
          ),
          backgroundColor: DynamicTheme.getSnackBarBackgroundColor(colorScheme) ?? colorScheme.primary2,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
    
    // Send the thought
    await controller.sendThought(receiverId);
    
    // Check result
    final result = ref.read(sendThoughtControllerProvider);
    
    if (context.mounted) {
      result.when(
        data: (data) {
          if (data.success) {
            // Show success message
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      color: DynamicTheme.getSnackBarTextColor(colorScheme) ?? Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Text(
                        'Thought sent to ${profile.displayName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: DynamicTheme.getSnackBarTextColor(colorScheme),
                            ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: DynamicTheme.getSnackBarBackgroundColor(colorScheme) ?? colorScheme.primary2,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          } else {
            // Show error message
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            String errorMessage = 'Failed to send thought';
            
            switch (data.errorCode) {
              case 'THOUGHT_ALREADY_SENT_TODAY':
                errorMessage = 'You already sent a thought to ${profile.displayName} today';
                break;
              case 'DAILY_LIMIT_REACHED':
                errorMessage = 'You\'ve reached your daily limit of thoughts';
                break;
              case 'NOT_CONNECTED':
                errorMessage = 'You must be connected to send a thought';
                break;
              case 'BLOCKED':
                errorMessage = 'Cannot send thought to this user';
                break;
              case 'INVALID_RECEIVER':
                errorMessage = 'Invalid receiver';
                break;
              default:
                errorMessage = data.errorMessage ?? 'Failed to send thought';
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  errorMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: DynamicTheme.getSnackBarTextColor(colorScheme) ?? Colors.white,
                      ),
                ),
                backgroundColor: DynamicTheme.getSnackBarBackgroundColor(colorScheme) ?? AppColors.error,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        loading: () {
          // Already showing loading
        },
        error: (error, stack) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: ${error.toString()}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: DynamicTheme.getSnackBarTextColor(colorScheme) ?? Colors.white,
                    ),
              ),
              backgroundColor: DynamicTheme.getSnackBarBackgroundColor(colorScheme) ?? AppColors.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      );
    }
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
          username: profile.username,
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

    return incomingAsync.when(
      data: (requests) {
        Logger.debug('Building incoming requests UI with ${requests.length} requests');
        if (requests.isEmpty) {
          return _buildEmptyIncomingState(context, colorScheme);
        }
        
        Logger.debug('Building ListView with ${requests.length} items');

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(incomingRequestsProvider);
          },
          color: colorScheme.accent,
          backgroundColor: colorScheme.isDarkTheme 
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          strokeWidth: AppConstants.refreshIndicatorStrokeWidth,
          displacement: AppConstants.refreshIndicatorDisplacement,
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
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(outgoingRequestsProvider);
            },
            color: colorScheme.accent,
            backgroundColor: colorScheme.isDarkTheme 
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            strokeWidth: AppConstants.refreshIndicatorStrokeWidth,
            displacement: AppConstants.refreshIndicatorDisplacement,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: _buildEmptyOutgoingState(context, colorScheme),
            ),
          );
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
          color: colorScheme.accent,
          backgroundColor: Colors.transparent,
          strokeWidth: AppConstants.refreshIndicatorStrokeWidth,
          displacement: AppConstants.refreshIndicatorDisplacement,
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
                foregroundColor: DynamicTheme.getButtonTextColor(colorScheme),
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
    final profile = request.fromUserProfile;
    // Create a fallback profile if missing
    final displayProfile = profile ?? ConnectionUserProfile(
      userId: request.fromUserId,
      displayName: 'User ${request.fromUserId.substring(0, 8)}...',
      username: null,
      avatarUrl: null,
    );

    final timeAgo = _formatTimeAgo(request.createdAt);


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
                          style: TextStyle(
                            color: DynamicTheme.getPrimaryIconColor(colorScheme),
                            fontSize: AppConstants.connectionCardAvatarTextSize,
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
                      size: AppConstants.connectionCardSmallIconSize,
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
                    icon: Icon(Icons.check_rounded, size: AppConstants.connectionCardButtonIconSize),
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
        backgroundColor: DynamicTheme.getDialogBackgroundColor(colorScheme),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        title: Row(
          children: [
            Icon(Icons.celebration_rounded, color: colorScheme.accent),
            const SizedBox(width: 8),
            Text(
              'Connected! ✨',
              style: TextStyle(
                color: DynamicTheme.getDialogTitleColor(colorScheme),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'You\'re now connected with ${request.fromUserProfile?.displayName ?? 'this user'}! '
          'You can now send and receive letters.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DynamicTheme.getDialogContentColor(colorScheme),
              ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.accent,
              foregroundColor: DynamicTheme.getButtonTextColor(colorScheme),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Done',
              style: TextStyle(
                color: DynamicTheme.getButtonTextColor(colorScheme),
                fontWeight: FontWeight.w600,
              ),
            ),
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
        statusColor = AppTheme.successGreen;
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
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
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
                          style: TextStyle(
                            color: DynamicTheme.getPrimaryIconColor(colorScheme),
                            fontSize: AppConstants.connectionCardAvatarTextSize,
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
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
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
        backgroundColor: DynamicTheme.getDialogBackgroundColor(colorScheme),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
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
                          style: TextStyle(
                            color: DynamicTheme.getPrimaryIconColor(colorScheme),
                            fontSize: AppConstants.connectionCardButtonIconSize,
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
                          color: DynamicTheme.getDialogTitleColor(colorScheme),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (displayProfile.username != null)
                    Text(
                      '@${displayProfile.username}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DynamicTheme.getDialogContentColor(colorScheme),
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
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
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
                  size: AppConstants.connectionCardSmallIconSize,
                  color: DynamicTheme.getSecondaryIconColor(colorScheme),
                ),
                SizedBox(width: 6),
                Text(
                  'Sent $sentTime',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DynamicTheme.getDialogContentColor(colorScheme),
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
                        SizedBox(width: AppTheme.chipSpacing),
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
                            color: DynamicTheme.getDialogContentColor(colorScheme),
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
                    color: DynamicTheme.getDialogButtonColor(colorScheme),
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
