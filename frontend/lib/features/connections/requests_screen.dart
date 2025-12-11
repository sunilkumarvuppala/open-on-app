import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openon_app/core/models/connection_models.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/widgets/common_widgets.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:openon_app/animations/effects/confetti_burst.dart';
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
      appBar: AppBar(
        title: const Text('Connection Requests'),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: DynamicTheme.getPrimaryIconColor(colorScheme),
          ),
          onPressed: () => context.pop(),
        ),
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
    final profile = request.fromUserProfile;
    if (profile == null) return const SizedBox.shrink();

    return Card(
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
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (profile.username != null)
                        Text(
                          '@${profile.username}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                      Text(
                        _formatTimeAgo(request.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
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
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  request.message!,
                  style: Theme.of(context).textTheme.bodyMedium,
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
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (profile.username != null)
                    Text(
                      '@${profile.username}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  Text(
                    _formatTimeAgo(request.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            ),
            _buildStatusChip(request.status),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ConnectionRequestStatus status) {
    Color color;
    String text;

    switch (status) {
      case ConnectionRequestStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case ConnectionRequestStatus.accepted:
        color = Colors.green;
        text = 'Accepted';
        break;
      case ConnectionRequestStatus.declined:
        color = Colors.grey;
        text = 'Declined';
        break;
    }

    return Chip(
      label: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String title, String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
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
    try {
      final repo = ref.read(connectionRepositoryProvider);
      await repo.respondToRequest(
        requestId: request.id,
        accept: true,
      );

      if (mounted) {
        // Show confetti animation in a full-screen overlay
        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withValues(alpha: 0.3),
          builder: (dialogContext) => PopScope(
            canPop: false,
            child: ConfettiBurst(
              isActive: true,
              onComplete: () {
                Navigator.of(dialogContext).pop();
                _showSuccessModal(request);
              },
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      Logger.error('Error accepting request', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept request: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessModal(ConnectionRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connected! ✨'),
        content: Text(
          'You\'re now connected with ${request.fromUserProfile?.displayName ?? 'this user'}! '
          'You can now send and receive letters.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Optionally navigate to connections screen
              context.push('/connections');
            },
            child: const Text('View Connections'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline request: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
