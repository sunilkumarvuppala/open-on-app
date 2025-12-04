import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/router/app_router.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/widgets/common_widgets.dart';

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
          ),
          body: recipientsAsync.when(
            data: (recipients) {
              if (recipients.isEmpty) {
                return _buildEmptyState(context);
              }
              
              return ListView.builder(
                padding: EdgeInsets.all(AppTheme.spacingMd),
                itemCount: recipients.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: AppTheme.spacingMd),
                    child: _buildRecipientCard(
                      context,
                      ref,
                      recipients[index],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => ErrorDisplay(
              message: error.toString(),
              onRetry: () => ref.invalidate(recipientsProvider(user.id)),
            ),
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
          recipient.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: DynamicTheme.getPrimaryTextColor(colorScheme),
              ),
        ),
        subtitle: Text(
          recipient.relationship,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DynamicTheme.getSecondaryTextColor(colorScheme),
              ),
        ),
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
        backgroundColor: DynamicTheme.getCardBackgroundColor(colorScheme),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text(
          'Delete Recipient',
          style: TextStyle(
            color: DynamicTheme.getPrimaryTextColor(colorScheme),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${recipient.name}?',
          style: TextStyle(
            color: DynamicTheme.getSecondaryTextColor(colorScheme),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: DynamicTheme.getPrimaryTextColor(colorScheme),
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

