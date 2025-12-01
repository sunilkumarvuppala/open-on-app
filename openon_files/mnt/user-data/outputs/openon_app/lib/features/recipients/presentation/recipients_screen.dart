import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/router/app_router.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/models.dart';

class RecipientsScreen extends ConsumerWidget {
  const RecipientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipientsAsync = ref.watch(recipientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipients'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: recipientsAsync.when(
        data: (recipients) {
          if (recipients.isEmpty) {
            return EmptyState(
              icon: Icons.people_outline,
              title: 'No recipients yet',
              message: 'Add people you want to send letters to',
              action: ElevatedButton(
                onPressed: () => context.push(AppRoutes.addRecipient),
                child: const Text('Add Recipient'),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            itemCount: recipients.length,
            itemBuilder: (context, index) {
              return _RecipientCard(
                recipient: recipients[index],
                onTap: () {
                  context.push(
                    '${AppRoutes.createCapsule}?recipientId=${recipients[index].id}',
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorDisplay(
          message: 'Failed to load recipients',
          onRetry: () => ref.invalidate(recipientsProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addRecipient),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Recipient'),
        backgroundColor: AppTheme.deepPurple,
      ),
    );
  }
}

class _RecipientCard extends StatelessWidget {
  final Recipient recipient;
  final VoidCallback onTap;

  const _RecipientCard({
    required this.recipient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              UserAvatar(
                name: recipient.name,
                imageUrl: recipient.avatarUrl,
                imagePath: recipient.localAvatarPath,
                size: 56,
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipient.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      recipient.displayRelationship,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textGrey,
                      ),
                    ),
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
