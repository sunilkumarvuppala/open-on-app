import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/router/app_router.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:openon_app/core/widgets/common_widgets.dart';

class StepChooseRecipient extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  
  const StepChooseRecipient({super.key, required this.onNext});
  
  @override
  ConsumerState<StepChooseRecipient> createState() => _StepChooseRecipientState();
}

class _StepChooseRecipientState extends ConsumerState<StepChooseRecipient> {
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    // Refresh recipients when this screen is shown to ensure self-recipient is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userAsync = ref.read(currentUserProvider);
      userAsync.whenData((user) {
        if (user != null) {
          ref.invalidate(recipientsProvider(user.id));
        }
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final selectedRecipient = ref.watch(draftCapsuleProvider).recipient;
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    
    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox();
        
        final recipientsAsync = ref.watch(recipientsProvider(user.id));
        
        return recipientsAsync.when(
          data: (recipients) {
            // CRITICAL: Deduplicate by linked_user_id for connection-based recipients
            // Multiple recipient records can exist with different IDs but same linked_user_id
            // This happens when recipients are created multiple times (race conditions)
            // For connection-based recipients (linkedUserId != null), use linkedUserId as unique key
            // For email-based recipients (linkedUserId == null), use id as unique key
            final uniqueRecipients = <String, Recipient>{};
            final seenLinkedUserIds = <String>{};
            
            for (final recipient in recipients) {
              // For connection-based recipients, deduplicate by linked_user_id
              if (recipient.linkedUserId != null && recipient.linkedUserId!.isNotEmpty) {
                final linkedUserIdKey = recipient.linkedUserId!;
                if (!seenLinkedUserIds.contains(linkedUserIdKey)) {
                  seenLinkedUserIds.add(linkedUserIdKey);
                  uniqueRecipients[linkedUserIdKey] = recipient;
                } else {
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
            final deduplicatedRecipients = uniqueRecipients.values.toList();
            
            if (deduplicatedRecipients.length != recipients.length) {
              Logger.info(
                'Deduplicated recipients: ${recipients.length} -> ${deduplicatedRecipients.length} '
                '(removed ${recipients.length - deduplicatedRecipients.length} duplicates)'
              );
            }
            
            // STEP 1: Filter out "To Self" recipients completely
            final recipientsWithoutToSelf = deduplicatedRecipients.where((r) {
              final nameLower = r.name.toLowerCase().trim();
              if (nameLower == 'to self') {
                return false;
              }
              return true;
            }).toList();
            
            // STEP 2: Ensure only ONE self-recipient exists (where linkedUserId == user.id)
            final selfRecipients = recipientsWithoutToSelf.where((r) => r.linkedUserId == user.id).toList();
            final otherRecipients = recipientsWithoutToSelf.where((r) => r.linkedUserId != user.id).toList();
            
            // If multiple self-recipients exist, keep only the first one
            // If no self-recipient exists, create a temporary one (backend will create the real one when sending)
            final finalSelfRecipient = selfRecipients.isNotEmpty 
                ? [selfRecipients.first]
                : [
                    Recipient(
                      id: user.id, // Use user ID so backend can detect self-send
                      userId: user.id,
                      name: user.name, // Use actual user name, not "To Self"
                      username: user.username,
                      avatar: user.avatarUrl ?? '',
                      linkedUserId: user.id,
                      email: user.email,
                    )
                  ];
            
            // Combine: self-recipient (always present) + other recipients
            final allRecipients = [...finalSelfRecipient, ...otherRecipients];
            
            // STEP 3: Apply search filter
            final filteredRecipients = allRecipients.where((r) {
              if (_searchQuery.isEmpty) return true;
              final name = r.name.toLowerCase();
              final username = r.username?.toLowerCase() ?? '';
              final query = _searchQuery.toLowerCase();
              return name.contains(query) || username.contains(query);
            }).toList();
            
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(AppTheme.spacingLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Who is this letter for?',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: DynamicTheme.getPrimaryTextColor(colorScheme),
                              ),
                        ),
                        SizedBox(height: AppTheme.spacingSm),
                        
                        // Search field
                        TextField(
                          style: TextStyle(
                            color: DynamicTheme.getInputTextColor(colorScheme),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search recipients...',
                            prefixIcon: Icon(
                              Icons.search,
                              color: DynamicTheme.getInputHintColor(colorScheme),
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: DynamicTheme.getInputHintColor(colorScheme),
                                    ),
                                    onPressed: () {
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                          },
                        ),
                        
                        if (filteredRecipients.isNotEmpty)
                          SizedBox(height: AppTheme.spacingSm),
                        
                        // Recipients list
                        if (filteredRecipients.isEmpty && _searchQuery.isNotEmpty) ...[
                          SizedBox(height: AppTheme.spacingXl),
                          Center(
                            child: Text(
                              _searchQuery.isEmpty
                                  ? 'No recipients yet'
                                  : 'No recipients found',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: DynamicTheme.getSecondaryTextColor(colorScheme),
                                  ),
                            ),
                          ),
                        ] else
                          ...filteredRecipients.map((recipient) {
                            final isSelected = selectedRecipient?.id == recipient.id;
                            final letterCountKey = '${user.id}|${recipient.id}|${recipient.linkedUserId ?? ''}';
                            final letterCountAsync = ref.watch(letterCountProvider(letterCountKey));
                            
                            return Padding(
                              padding: EdgeInsets.only(bottom: AppTheme.spacingSm),
                              child: Card(
                                elevation: 2,
                                margin: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                ),
                                color: isSelected
                                    ? DynamicTheme.getButtonBackgroundColor(colorScheme, opacity: 0.2)
                                    : DynamicTheme.getCardBackgroundColor(colorScheme),
                                child: InkWell(
                                  onTap: () {
                                    ref.read(draftCapsuleProvider.notifier)
                                        .setRecipient(recipient);
                                  },
                                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                  child: Padding(
                                    padding: EdgeInsets.all(AppTheme.spacingSm),
                                    child: Stack(
                                      children: [
                                        Row(
                                          children: [
                                            UserAvatar(
                                              imageUrl: recipient.avatar.isNotEmpty ? recipient.avatar : null,
                                              name: recipient.name,
                                              size: 56,
                                            ),
                                            SizedBox(width: AppTheme.spacingMd),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    // Add "(you)" suffix if this is a self-recipient
                                                    recipient.linkedUserId != null && recipient.linkedUserId == user.id
                                                        ? '${recipient.name} (you)'
                                                        : recipient.name,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: DynamicTheme.getPrimaryTextColor(colorScheme),
                                                    ),
                                                  ),
                                                  if (recipient.username != null && recipient.username!.isNotEmpty) ...[
                                                    SizedBox(height: AppTheme.spacingXs),
                                                    Text(
                                                      '@${recipient.username}',
                                                      style: TextStyle(
                                                        color: DynamicTheme.getSecondaryTextColor(colorScheme),
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            if (isSelected)
                                              Icon(
                                                Icons.check_circle,
                                                color: DynamicTheme.getButtonTextColor(colorScheme),
                                                size: 28,
                                              ),
                                          ],
                                        ),
                                        // Letter count with icon at bottom right
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: letterCountAsync.when(
                                            data: (count) {
                                              return Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.mail_outline,
                                                    size: 14,
                                                    color: DynamicTheme.getSecondaryTextColor(colorScheme),
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    '$count letter${count == 1 ? '' : 's'}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: DynamicTheme.getSecondaryTextColor(colorScheme),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                            loading: () => const SizedBox.shrink(),
                                            error: (_, __) => const SizedBox.shrink(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        
                        SizedBox(height: AppTheme.spacingLg),
                        
                        // Add new recipient button at bottom
                        Card(
                          elevation: 2,
                          color: DynamicTheme.getCardBackgroundColor(colorScheme),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          ),
                          child: InkWell(
                            onTap: () async {
                              await context.push(Routes.addRecipient);
                              ref.invalidate(recipientsProvider(user.id));
                            },
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            child: Padding(
                              padding: EdgeInsets.all(AppTheme.spacingMd),
                              child: Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: DynamicTheme.getButtonBackgroundColor(colorScheme, opacity: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      color: DynamicTheme.getButtonTextColor(colorScheme),
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Add New Recipient',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: DynamicTheme.getPrimaryTextColor(colorScheme),
                                          ),
                                        ),
                                        SizedBox(height: AppTheme.spacingXs),
                                        Text(
                                          'Create a new person to send letters to',
                                          style: TextStyle(
                                            color: DynamicTheme.getSecondaryTextColor(colorScheme),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: DynamicTheme.getSecondaryIconColor(colorScheme),
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
                
                // Next button
                Container(
                  padding: EdgeInsets.all(AppTheme.spacingLg),
                  decoration: BoxDecoration(
                    color: DynamicTheme.getNavBarBackgroundColor(colorScheme),
                    boxShadow: [
                      BoxShadow(
                        color: DynamicTheme.getNavBarShadowColor(colorScheme),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: selectedRecipient != null ? widget.onNext : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary1,
                        foregroundColor: DynamicTheme.getButtonTextColor(colorScheme),
                        side: DynamicTheme.getButtonBorderSide(colorScheme),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        ),
                      ),
                      child: const Text('Continue'),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) {
            Logger.error('Error loading recipients', error: error, stackTrace: stack);
            // Show empty state instead of error - user might just have no recipients
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(AppTheme.spacingLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Who is this letter for?',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: DynamicTheme.getPrimaryTextColor(colorScheme),
                              ),
                        ),
                        SizedBox(height: AppTheme.spacingXl),
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'No recipients yet',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: DynamicTheme.getSecondaryTextColor(colorScheme),
                                    ),
                              ),
                              SizedBox(height: AppTheme.spacingMd),
                              ElevatedButton(
                                onPressed: () {
                                  ref.invalidate(recipientsProvider(user.id));
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        Logger.error('Error loading user', error: error, stackTrace: stack);
        return Center(child: Text('Error: $error'));
      },
    );
  }
  
}
