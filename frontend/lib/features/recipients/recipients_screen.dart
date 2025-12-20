import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/router/app_router.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/widgets/common_widgets.dart';
import 'package:openon_app/core/utils/logger.dart';

// Import AppColors for error color
import 'package:openon_app/core/theme/app_theme.dart' show AppColors;

class RecipientsScreen extends ConsumerWidget {
  const RecipientsScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    
    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Not authenticated')),
          );
        }
        
        final recipientsAsync = ref.watch(recipientsProvider(user.id));
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Recipients'),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: DynamicTheme.getPrimaryIconColor(
                  ref.watch(selectedColorSchemeProvider),
                ),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              ProfileAvatarButton(),
            ],
          ),
          body: recipientsAsync.when(
            data: (recipients) {
              // Debug logging
              Logger.info('Recipients screen: Received ${recipients.length} recipients');
              
              // Log all recipients for debugging
              for (final recipient in recipients) {
                Logger.debug(
                  'Recipient: id=${recipient.id}, name="${recipient.name}", '
                  'linkedUserId=${recipient.linkedUserId}, username=${recipient.username}'
                );
              }
              
              // STEP 1: First, filter out all "To Self" recipients completely
              // Check multiple variations: "To Self", "to self", "ToSelf", etc.
              final recipientsWithoutToSelf = recipients.where((recipient) {
                final nameLower = recipient.name.toLowerCase().trim();
                final nameTrimmed = recipient.name.trim();
                
                // Check various forms of "To Self"
                if (nameLower == 'to self' || 
                    nameLower == 'toself' ||
                    nameTrimmed == 'To Self' ||
                    nameTrimmed == 'to self') {
                  Logger.info('Filtering out "To Self" recipient: id=${recipient.id}, name="${recipient.name}", linkedUserId=${recipient.linkedUserId}');
                  return false;
                }
                return true;
              }).toList();
              
              Logger.info('After filtering "To Self": ${recipients.length} -> ${recipientsWithoutToSelf.length}');
              
              // Log remaining recipients
              for (final recipient in recipientsWithoutToSelf) {
                Logger.debug(
                  'After filter: id=${recipient.id}, name="${recipient.name}", '
                  'linkedUserId=${recipient.linkedUserId}'
                );
              }
              
              // STEP 2: Deduplicate by linked_user_id for connection-based recipients
              // Multiple recipient records can exist with different IDs but same linked_user_id
              // This happens when recipients are created multiple times (race conditions)
              // For connection-based recipients (linkedUserId != null), use linkedUserId as unique key
              // For email-based recipients (linkedUserId == null), use id as unique key
              final uniqueRecipients = <String, Recipient>{};
              final seenLinkedUserIds = <String>{};
              
              for (final recipient in recipientsWithoutToSelf) {
                // For connection-based recipients, deduplicate by linked_user_id
                if (recipient.linkedUserId != null && recipient.linkedUserId!.isNotEmpty) {
                  final linkedUserIdKey = recipient.linkedUserId!;
                  if (!seenLinkedUserIds.contains(linkedUserIdKey)) {
                    seenLinkedUserIds.add(linkedUserIdKey);
                    uniqueRecipients[linkedUserIdKey] = recipient;
                  } else {
                    // Duplicate found - keep the first one (both should be valid now since "To Self" is filtered)
                    Logger.warning(
                      'Found duplicate recipient with same linked_user_id: ${recipient.linkedUserId} '
                      '(ID: ${recipient.id}, Name: ${recipient.name}). Keeping first occurrence.'
                    );
                  }
                } else {
                  // For email-based recipients, deduplicate by id
                  if (!uniqueRecipients.containsKey(recipient.id)) {
                    uniqueRecipients[recipient.id] = recipient;
                  } else {
                    Logger.warning(
                      'Found duplicate recipient with same id: ${recipient.id} '
                      '(Name: ${recipient.name}). Keeping first occurrence.'
                    );
                  }
                }
              }
              var finalRecipients = uniqueRecipients.values.toList();
              
              // STEP 3: Final safety check - ensure only ONE self-recipient exists
              // If multiple recipients have linkedUserId == user.id, keep only the first one
              final selfRecipients = finalRecipients.where((r) => r.linkedUserId == user.id).toList();
              if (selfRecipients.length > 1) {
                Logger.warning(
                  'Found ${selfRecipients.length} self-recipients, keeping only the first one. '
                  'Names: ${selfRecipients.map((r) => r.name).join(", ")}'
                );
                // Remove all but the first self-recipient
                final selfRecipientToKeep = selfRecipients.first;
                finalRecipients = finalRecipients.where((r) {
                  if (r.linkedUserId == user.id) {
                    return r.id == selfRecipientToKeep.id;
                  }
                  return true;
                }).toList();
                
                Logger.info(
                  'After self-recipient deduplication: ${uniqueRecipients.values.length} -> ${finalRecipients.length}'
                );
              }
              
              if (finalRecipients.length != recipients.length) {
                Logger.info(
                  'Final recipients after filtering and deduplication: ${recipients.length} -> ${finalRecipients.length} '
                  '(removed ${recipients.length - finalRecipients.length} recipients)'
                );
              }
              
              if (finalRecipients.isEmpty) {
                Logger.info('Recipients screen: Showing empty state');
                return _buildEmptyState(context);
              }
              
              Logger.info('Recipients screen: Building list with ${finalRecipients.length} items');
              
              final colorScheme = ref.watch(selectedColorSchemeProvider);
              return RefreshIndicator(
                onRefresh: () async {
                  Logger.info('Recipients screen: Refreshing recipients');
                  ref.invalidate(recipientsProvider(user.id));
                  // Wait for the provider to refresh
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                color: colorScheme.accent,
                backgroundColor: colorScheme.isDarkTheme 
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                strokeWidth: 3.0,
                displacement: 40.0,
                child: ListView.builder(
                  padding: EdgeInsets.all(AppTheme.spacingMd),
                  itemCount: finalRecipients.length,
                  itemBuilder: (context, index) {
                    final recipient = finalRecipients[index];
                    Logger.debug('Recipients screen: Building card for recipient ${recipient.id}: ${recipient.name}');
                    return Padding(
                      padding: EdgeInsets.only(bottom: AppTheme.spacingMd),
                      child: _buildRecipientCard(
                        context,
                        ref,
                        recipient,
                        user,
                      ),
                    );
                  },
                ),
              );
            },
            loading: () {
              Logger.info('Recipients screen: Loading state');
              return const Center(child: CircularProgressIndicator());
            },
            error: (error, stack) {
              // Log the error for debugging
              Logger.error('Recipients screen error', error: error, stackTrace: stack);
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ErrorDisplay(
                    message: error.toString(),
                    onRetry: () {
                      Logger.info('Recipients screen: Retrying after error');
                      ref.invalidate(recipientsProvider(user.id));
                    },
                  ),
                  const SizedBox(height: 16),
                  // Debug button to show more info
                  ElevatedButton(
                    onPressed: () {
                      final colorScheme = ref.read(selectedColorSchemeProvider);
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: DynamicTheme.getDialogBackgroundColor(colorScheme),
                          title: Text(
                            'Debug Info',
                            style: TextStyle(
                              color: DynamicTheme.getDialogTitleColor(colorScheme),
                            ),
                          ),
                          content: SingleChildScrollView(
                            child: Text(
                              'Error: $error\n\n'
                              'User ID: ${user.id}\n'
                              'Stack: $stack',
                              style: TextStyle(
                                fontSize: 12,
                                color: DynamicTheme.getDialogContentColor(colorScheme),
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Close',
                                style: TextStyle(
                                  color: DynamicTheme.getDialogButtonColor(colorScheme),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Show Debug Info'),
                  ),
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push(Routes.addRecipient),
            child: const Icon(Icons.add),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: ErrorDisplay(message: error.toString()),
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return EmptyState(
      icon: Icons.person_add,
      title: 'No Recipients Yet',
      message: 'Add someone special to send them a time-locked letter',
      action: GradientButton(
        text: 'Add Recipient',
        onPressed: () => context.push(Routes.addRecipient),
      ),
    );
  }
  
  Widget _buildRecipientCard(
    BuildContext context,
    WidgetRef ref,
    Recipient recipient,
    User user,
  ) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      color: DynamicTheme.getCardBackgroundColor(colorScheme),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: colorScheme.primary1.withOpacity(0.1),
          backgroundImage: recipient.avatar.startsWith('http')
              ? NetworkImage(recipient.avatar)
              : null,
          child: recipient.avatar.startsWith('http')
              ? null
              : Text(
                  recipient.name[0].toUpperCase(),
                  style: TextStyle(
                    color: colorScheme.primary1,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        title: Text(
          // Add "(you)" suffix if this is a self-recipient (linkedUserId matches current user)
          recipient.linkedUserId != null && recipient.linkedUserId == user.id 
              ? '${recipient.name} (you)'
              : recipient.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: DynamicTheme.getPrimaryTextColor(colorScheme),
              ),
        ),
        subtitle: recipient.username != null && recipient.username!.isNotEmpty
            ? Text(
                '@${recipient.username}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: DynamicTheme.getSecondaryTextColor(colorScheme),
                    ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              color: DynamicTheme.getPrimaryIconColor(colorScheme),
              onPressed: () => context.push(
                Routes.addRecipient,
                extra: recipient,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppTheme.errorRed,
              onPressed: () => _showDeleteDialog(context, ref, recipient),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    Recipient recipient,
  ) {
    final colorScheme = ref.read(selectedColorSchemeProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DynamicTheme.getDialogBackgroundColor(colorScheme),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text(
          'Delete Recipient',
          style: TextStyle(
            color: DynamicTheme.getDialogTitleColor(colorScheme),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${recipient.name}?',
          style: TextStyle(
            color: DynamicTheme.getDialogContentColor(colorScheme),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: DynamicTheme.getDialogButtonColor(colorScheme),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final userAsync = ref.read(currentUserProvider);
                await userAsync.when(
                  data: (user) async {
                    if (user != null) {
                      final repo = ref.read(recipientRepositoryProvider);
                      await repo.deleteRecipient(recipient.id);
                      ref.invalidate(recipientsProvider(user.id));
                    }
                  },
                  loading: () async {},
                  error: (_, __) async {},
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

