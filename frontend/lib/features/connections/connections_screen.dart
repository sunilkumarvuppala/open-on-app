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

class ConnectionsScreen extends ConsumerWidget {
  const ConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final connectionsAsync = ref.watch(connectionsProvider);

    return Scaffold(
      backgroundColor: colorScheme.secondary2,
      appBar: AppBar(
        backgroundColor: colorScheme.secondary2,
        elevation: 0,
        title: Text(
          'Connections',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: DynamicTheme.getPrimaryTextColor(colorScheme),
              ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: DynamicTheme.getPrimaryIconColor(colorScheme),
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              context.push('/connections/add');
            },
          ),
        ],
      ),
      body: connectionsAsync.when(
        data: (connections) {
          if (connections.isEmpty) {
            return _buildEmptyState(context, ref);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(connectionsProvider);
            },
            child: ListView.builder(
              padding: EdgeInsets.all(AppTheme.spacingMd),
              itemCount: connections.length,
              itemBuilder: (context, index) {
                return _buildConnectionCard(context, connections[index], colorScheme);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          Logger.error('Error loading connections', error: error, stackTrace: stack);
          return ErrorDisplay(
            message: error.toString(),
            onRetry: () {
              ref.invalidate(connectionsProvider);
            },
          );
        },
      ),
    );
  }

  Widget _buildConnectionCard(BuildContext context, Connection connection, AppColorScheme colorScheme) {
    final profile = connection.otherUserProfile;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
        color: DynamicTheme.getCardBackgroundColor(colorScheme),
      child: ListTile(
        leading: CircleAvatar(
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
        title: Text(
          profile.displayName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: DynamicTheme.getPrimaryTextColor(colorScheme),
              ),
        ),
        subtitle: profile.username != null
            ? Text(
                '@${profile.username}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DynamicTheme.getSecondaryTextColor(colorScheme),
                    ),
              )
            : Text(
                'Connected ${_formatTimeAgo(connection.connectedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DynamicTheme.getSecondaryTextColor(colorScheme),
                    ),
              ),
        trailing: IconButton(
          icon: Icon(
            Icons.send,
            color: DynamicTheme.getPrimaryIconColor(colorScheme),
          ),
          onPressed: () {
            // Navigate to create capsule with this user as recipient
            // This would need to be implemented based on your capsule creation flow
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Send letter feature coming soon',
                  style: TextStyle(
                    color: DynamicTheme.getSnackBarTextColor(colorScheme),
                  ),
                ),
                backgroundColor: DynamicTheme.getSnackBarBackgroundColor(colorScheme),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: DynamicTheme.getSecondaryIconColor(colorScheme),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'No connections yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: DynamicTheme.getPrimaryTextColor(colorScheme),
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Send connection requests to start connecting with others.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DynamicTheme.getSecondaryTextColor(colorScheme),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/connections/add');
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Add Connection'),
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
      return '${difference.inDays} day${difference.inDays != 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours != 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes != 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
