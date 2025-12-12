import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openon_app/core/models/connection_models.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/color_scheme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/data/api_repositories.dart';
import 'package:openon_app/core/constants/app_constants.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:openon_app/core/widgets/common_widgets.dart';

class AddConnectionScreen extends ConsumerStatefulWidget {
  const AddConnectionScreen({super.key});

  @override
  ConsumerState<AddConnectionScreen> createState() => _AddConnectionScreenState();
}

class _AddConnectionScreenState extends ConsumerState<AddConnectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  List<ConnectionUserProfile> _searchResults = [];
  bool _isSearching = false;
  ConnectionUserProfile? _selectedUser;
  bool _isSending = false;
  Timer? _searchDebounce;
  final ApiUserService _userService = ApiUserService();

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    _searchDebounce?.cancel();
    
    if (query.trim().isEmpty || query.length < AppConstants.minSearchQueryLength) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    _searchDebounce = Timer(const Duration(milliseconds: AppConstants.searchDebounceMs), () async {
      try {
        // Use ApiUserService like add recipient screen does
        final users = await _userService.searchUsers(query);
        
        // Get current user's connections to filter out already connected users
        final currentUserAsync = ref.read(currentUserProvider);
        final currentUserId = currentUserAsync.asData?.value?.id ?? '';
        
        Set<String> connectedUserIds = {};
        if (currentUserId.isNotEmpty) {
          try {
            final connectionsAsync = ref.read(connectionsProvider);
            // Get connections synchronously if available
            if (connectionsAsync.hasValue) {
              final connections = connectionsAsync.value ?? [];
              // Extract user IDs from connections
              for (final connection in connections) {
                // connection.otherUserId is the connected user's ID
                connectedUserIds.add(connection.otherUserId);
              }
            }
          } catch (e) {
            Logger.warning('Error loading connections for filtering: $e');
          }
        }
        
        // Convert User to ConnectionUserProfile and filter out already connected users
        final results = users
            .where((user) => !connectedUserIds.contains(user.id)) // Filter out connected users
            .map((user) {
              // Build display name from user name
              final displayName = user.name.isNotEmpty ? user.name : user.username;
              
              return ConnectionUserProfile(
                userId: user.id,
                displayName: displayName,
                avatarUrl: user.avatarUrl, // User model has avatarUrl getter
                username: user.username,
              );
            }).toList();
        
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
        }
      } catch (e, stackTrace) {
        Logger.error('Error searching users', error: e, stackTrace: stackTrace);
        if (mounted) {
          setState(() {
            _isSearching = false;
            _searchResults = [];
          });
          final colorScheme = ref.read(selectedColorSchemeProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to search users: ${e.toString()}',
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
    });
  }

  Future<void> _sendRequest(ConnectionUserProfile user) async {
    setState(() {
      _isSending = true;
    });

    try {
      final repo = ref.read(connectionRepositoryProvider);
      final message = _messageController.text.trim();
      
      await repo.sendConnectionRequest(
        toUserId: user.userId,
        message: message.isEmpty ? null : message,
      );

      if (mounted) {
        final colorScheme = ref.read(selectedColorSchemeProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Connection request sent!',
              style: TextStyle(
                color: DynamicTheme.getSnackBarTextColor(colorScheme),
              ),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        context.pop();
      }
    } catch (e, stackTrace) {
      Logger.error('Error sending request', error: e, stackTrace: stackTrace);
      if (mounted) {
        final colorScheme = ref.read(selectedColorSchemeProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
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
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Connection'),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: DynamicTheme.getPrimaryIconColor(colorScheme),
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          ProfileAvatarButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by username, name, or email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                _searchUsers(value);
              },
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Search results
            if (_isSearching)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacingLg),
                  child: CircularProgressIndicator(
                    color: colorScheme.accent,
                  ),
                ),
              )
            else if (_searchResults.isEmpty && _searchController.text.length >= AppConstants.minSearchQueryLength)
              Padding(
                padding: EdgeInsets.all(AppTheme.spacingLg),
                child: Center(
                  child: Text(
                    'No users found',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: DynamicTheme.getSecondaryTextColor(colorScheme),
                        ),
                  ),
                ),
              )
            else if (_searchResults.isNotEmpty)
              ..._searchResults.map((user) => _buildUserCard(user)),

            // Selected user details
            if (_selectedUser != null) ...[
              const SizedBox(height: AppTheme.spacingLg),
              const Divider(),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                'Send Request To',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              _buildSelectedUserCard(_selectedUser!, colorScheme),
              const SizedBox(height: AppTheme.spacingMd),
              TextField(
                controller: _messageController,
                maxLength: 120,
                decoration: InputDecoration(
                  hintText: 'Add a note (optional)',
                  labelText: 'Message',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              ElevatedButton(
                onPressed: _isSending
                    ? null
                    : () => _sendRequest(_selectedUser!),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send Request'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(ConnectionUserProfile user) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: user.avatarUrl != null
              ? CachedNetworkImageProvider(user.avatarUrl!)
              : null,
          child: user.avatarUrl == null
              ? Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontSize: 20),
                )
              : null,
        ),
        title: Text(user.displayName),
        subtitle: user.username != null ? Text('@${user.username}') : null,
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () {
            setState(() {
              _selectedUser = user;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSelectedUserCard(ConnectionUserProfile user, AppColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: user.avatarUrl != null
                  ? CachedNetworkImageProvider(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? Text(
                      user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 24),
                    )
                  : null,
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: DynamicTheme.getPrimaryTextColor(colorScheme),
                        ),
                  ),
                  if (user.username != null)
                    Text(
                      '@${user.username}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: DynamicTheme.getSecondaryTextColor(colorScheme),
                          ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _selectedUser = null;
                  _messageController.clear();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
