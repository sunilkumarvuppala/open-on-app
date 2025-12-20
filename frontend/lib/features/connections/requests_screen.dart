import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openon_app/core/models/connection_models.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/color_scheme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/widgets/common_widgets.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final incomingAsync = ref.watch(incomingRequestsProvider);
    final outgoingAsync = ref.watch(outgoingRequestsProvider);

    return Scaffold(
      backgroundColor: colorScheme.secondary2,
      appBar: AppBar(
        backgroundColor: colorScheme.secondary2,
        elevation: 0,
        title: Text(
          'Connection Requests',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: DynamicTheme.getPrimaryTextColor(colorScheme),
              ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: DynamicTheme.getPrimaryIconColor(colorScheme),
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              // If we can't pop, navigate to home or a safe route
              context.go('/');
            }
          },
        ),
        actions: [
          ProfileAvatarButton(),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Incoming'),
                  const SizedBox(width: 8),
                  incomingAsync.when(
                    data: (requests) => requests.isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${requests.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (error, stack) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const Tab(text: 'Outgoing'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIncomingTab(incomingAsync),
          _buildOutgoingTab(outgoingAsync),
        ],
      ),
    );
  }

  Widget _buildIncomingTab(AsyncValue<List<ConnectionRequest>> incomingAsync) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    return incomingAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return _buildEmptyState(
            context,
            'No incoming requests',
            'You don\'t have any pending connection requests.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(incomingRequestsProvider);
          },
          color: colorScheme.accent,
          backgroundColor: colorScheme.isDarkTheme 
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          strokeWidth: 3.0,
          displacement: 40.0,
          child: ListView.builder(
            padding: EdgeInsets.all(AppTheme.spacingMd),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              return _buildIncomingRequestCard(requests[index]);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        Logger.error('Error loading incoming requests', error: error, stackTrace: stack);
        return ErrorDisplay(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(incomingRequestsProvider);
          },
        );
      },
    );
  }

  Widget _buildOutgoingTab(AsyncValue<List<ConnectionRequest>> outgoingAsync) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    return outgoingAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return _buildEmptyState(
            context,
            'No outgoing requests',
            'You haven\'t sent any connection requests yet.',
          );
        }

        // Separate by status
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
          backgroundColor: colorScheme.isDarkTheme 
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          strokeWidth: 3.0,
          displacement: 40.0,
          child: ListView(
            padding: EdgeInsets.all(AppTheme.spacingMd),
            children: [
              if (pending.isNotEmpty) ...[
                _buildSectionHeader('Pending'),
                ...pending.map((r) => _buildOutgoingRequestCard(r)),
                const SizedBox(height: AppTheme.spacingLg),
              ],
              if (accepted.isNotEmpty) ...[
                _buildSectionHeader('Accepted'),
                ...accepted.map((r) => _buildOutgoingRequestCard(r)),
                const SizedBox(height: AppTheme.spacingLg),
              ],
              if (declined.isNotEmpty) ...[
                _buildSectionHeader('Not Accepted'),
                ...declined.map((r) => _buildOutgoingRequestCard(r)),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        Logger.error('Error loading outgoing requests', error: error, stackTrace: stack);
        return ErrorDisplay(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(outgoingRequestsProvider);
          },
        );
      },
    );
  }

  Widget _buildIncomingRequestCard(ConnectionRequest request) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final profile = request.fromUserProfile;
    if (profile == null) return const SizedBox.shrink();

    return Card(
      color: DynamicTheme.getCardBackgroundColor(colorScheme),
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: profile.avatarUrl != null
                      ? CachedNetworkImageProvider(profile.avatarUrl!)
                      : null,
                  child: profile.avatarUrl == null
                      ? Text(
                          profile.displayName.isNotEmpty
                              ? profile.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 20),
                        )
                      : null,
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: DynamicTheme.getPrimaryTextColor(colorScheme),
                            ),
                      ),
                      if (profile.username != null)
                        Text(
                          '@${profile.username}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: DynamicTheme.getSecondaryTextColor(colorScheme),
                              ),
                        ),
                      Text(
                        _formatTimeAgo(request.createdAt),
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
              const SizedBox(height: AppTheme.spacingSm),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                decoration: BoxDecoration(
                  color: DynamicTheme.getInfoBackgroundColor(colorScheme),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: DynamicTheme.getInfoBorderColor(colorScheme),
                    width: 1,
                  ),
                ),
                child: Text(
                  request.message!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: DynamicTheme.getPrimaryTextColor(colorScheme),
                      ),
                ),
              ),
            ],
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _declineRequest(request),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptRequest(request),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutgoingRequestCard(ConnectionRequest request) {
    final profile = request.toUserProfile;
    if (profile == null) return const SizedBox.shrink();
    final colorScheme = ref.watch(selectedColorSchemeProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: profile.avatarUrl != null
                  ? CachedNetworkImageProvider(profile.avatarUrl!)
                  : null,
              child: profile.avatarUrl == null
                  ? Text(
                      profile.displayName.isNotEmpty
                          ? profile.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 20),
                    )
                  : null,
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: DynamicTheme.getPrimaryTextColor(colorScheme),
                        ),
                  ),
                  if (profile.username != null)
                    Text(
                      '@${profile.username}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DynamicTheme.getSecondaryTextColor(colorScheme),
                          ),
                    ),
                  Text(
                    _formatTimeAgo(request.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DynamicTheme.getSecondaryTextColor(colorScheme),
                        ),
                  ),
                ],
              ),
            ),
            _buildStatusChip(request.status, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ConnectionRequestStatus status, AppColorScheme colorScheme) {
    Color color;
    String text;
    Color textColor;

    switch (status) {
      case ConnectionRequestStatus.pending:
        color = colorScheme.isDarkTheme 
            ? Colors.orange.shade300 
            : Colors.orange;
        text = 'Pending';
        textColor = Colors.white;
        break;
      case ConnectionRequestStatus.accepted:
        color = AppTheme.successGreen;
        text = 'Accepted';
        textColor = Colors.white;
        break;
      case ConnectionRequestStatus.declined:
        color = colorScheme.isDarkTheme 
            ? Colors.grey.shade400 
            : Colors.grey.shade600;
        text = 'Declined';
        textColor = Colors.white;
        break;
    }

    return Chip(
      label: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 12),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildSectionHeader(String title) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: DynamicTheme.getPrimaryTextColor(colorScheme),
            ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String title, String message) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_outlined,
              size: 64,
              color: DynamicTheme.getSecondaryIconColor(colorScheme),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: DynamicTheme.getPrimaryTextColor(colorScheme),
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DynamicTheme.getSecondaryTextColor(colorScheme),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _acceptRequest(ConnectionRequest request) async {
    if (!mounted) return;
    
    try {
      final repo = ref.read(connectionRepositoryProvider);
      await repo.respondToRequest(
        requestId: request.id,
        accept: true,
      );

      if (!mounted) return;

      // Show success modal first (before invalidating providers to avoid rebuild conflicts)
      _showSuccessModalWithConfetti(request);
      
      // Invalidate providers AFTER showing dialog to refresh lists
      // Use post-frame callback to avoid rebuild conflicts during navigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.invalidate(incomingRequestsProvider);
          ref.invalidate(outgoingRequestsProvider);
          ref.invalidate(connectionsProvider);
        }
      });
    } catch (e, stackTrace) {
      Logger.error('Error accepting request', error: e, stackTrace: stackTrace);
      if (mounted) {
        final colorScheme = ref.read(selectedColorSchemeProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to accept request: ${e.toString()}',
              style: TextStyle(
                color: DynamicTheme.getSnackBarTextColor(colorScheme),
              ),
            ),
            backgroundColor: DynamicTheme.getSnackBarBackgroundColor(colorScheme) ?? AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _showSuccessModalWithConfetti(ConnectionRequest request) {
    if (!mounted) return;
    
    final colorScheme = ref.read(selectedColorSchemeProvider);
    final modalContext = context;
    
    // Use a simpler approach: just show the dialog without confetti to avoid navigation issues
    // Confetti can be added back later if needed, but for now, prioritize stability
    showDialog(
      context: modalContext,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DynamicTheme.getDialogBackgroundColor(colorScheme),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Connected! ✨',
          style: TextStyle(
            color: DynamicTheme.getDialogTitleColor(colorScheme),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'You\'re now connected with ${request.fromUserProfile?.displayName ?? 'this user'}! '
          'You can now send and receive letters.',
          style: TextStyle(
            color: DynamicTheme.getDialogContentColor(colorScheme),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Close dialog first
              Navigator.of(dialogContext).pop();
              
              // Navigate after dialog is fully closed using post-frame callback
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && modalContext.mounted) {
                  try {
                    modalContext.push('/connections');
                  } catch (e) {
                    Logger.warning('Navigation error: $e');
                  }
                }
              });
            },
            child: Text(
              'View Connections',
              style: TextStyle(
                color: DynamicTheme.getDialogButtonColor(colorScheme),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.accent,
              foregroundColor: DynamicTheme.getButtonTextColor(colorScheme),
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


  Future<void> _declineRequest(ConnectionRequest request) async {
    try {
      final repo = ref.read(connectionRepositoryProvider);
      await repo.respondToRequest(
        requestId: request.id,
        accept: false,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request declined'),
          ),
        );
      }
    } catch (e, stackTrace) {
      Logger.error('Error declining request', error: e, stackTrace: stackTrace);
      if (mounted) {
        final colorScheme = ref.read(selectedColorSchemeProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to decline request: ${e.toString()}',
              style: TextStyle(
                color: DynamicTheme.getSnackBarTextColor(colorScheme),
              ),
            ),
            backgroundColor: DynamicTheme.getSnackBarBackgroundColor(colorScheme) ?? AppTheme.errorRed,
          ),
        );
      }
    }
  }
}
