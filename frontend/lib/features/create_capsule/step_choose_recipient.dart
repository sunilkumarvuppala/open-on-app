import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:openon_app/core/widgets/common_widgets.dart';

/// Optimized widget for displaying letter count
/// Isolated to prevent unnecessary rebuilds of parent recipient card
class _LetterCountBadge extends ConsumerWidget {
  final String letterCountKey;
  
  const _LetterCountBadge({required this.letterCountKey});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final letterCountAsync = ref.watch(letterCountProvider(letterCountKey));
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    
    return letterCountAsync.when(
      data: (count) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mail_outline,
              size: 14,
              color: DynamicTheme.getSecondaryTextColor(colorScheme),
            ),
            const SizedBox(width: 4),
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
    );
  }
}

class StepChooseRecipient extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  
  const StepChooseRecipient({super.key, required this.onNext});
  
  @override
  ConsumerState<StepChooseRecipient> createState() => _StepChooseRecipientState();
}

class _StepChooseRecipientState extends ConsumerState<StepChooseRecipient> {
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _inviteOptionKey = GlobalKey();
  
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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollToInviteOption() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _inviteOptionKey.currentContext != null) {
        final context = _inviteOptionKey.currentContext!;
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final draftCapsule = ref.watch(draftCapsuleProvider);
    final selectedRecipient = draftCapsule.recipient;
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
            
            // STEP 1: Filter out "To Self" recipients and separate self/other recipients in one pass (optimized)
            final selfRecipients = <Recipient>[];
            final otherRecipients = <Recipient>[];
            const toSelfName = 'to self'; // Constant for comparison
            
            for (final recipient in deduplicatedRecipients) {
              final nameLower = recipient.name.toLowerCase().trim();
              // Skip "To Self" recipients
              if (nameLower == toSelfName) {
                continue;
              }
              // Categorize as self or other
              if (recipient.linkedUserId == user.id) {
                selfRecipients.add(recipient);
              } else {
                otherRecipients.add(recipient);
              }
            }
            
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
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                      AppTheme.spacingLg,
                      AppTheme.spacingSm,
                      AppTheme.spacingLg,
                      AppTheme.spacingLg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Who is this letter for?',
                                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: DynamicTheme.getPrimaryTextColor(colorScheme),
                                    ),
                              ),
                            ),
                            TextButton.icon(
                              icon: Icon(
                                Icons.person_add,
                                color: DynamicTheme.getPrimaryIconColor(colorScheme),
                                size: 20,
                              ),
                              label: Text(
                                'Invite',
                                style: TextStyle(
                                  color: DynamicTheme.getPrimaryTextColor(colorScheme),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: () {
                                // Automatically select unregistered recipient option
                                // setUnregisteredRecipient already clears the regular recipient
                                ref.read(draftCapsuleProvider.notifier).setUnregisteredRecipient();
                                // Scroll to invite option
                                _scrollToInviteOption();
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: AppTheme.spacingSm),
                        
                        // Show "Invite with a letter" option at top when selected
                        Builder(
                          builder: (context) {
                            final draftCapsule = ref.watch(draftCapsuleProvider);
                            // Show invite option when selected (setUnregisteredRecipient already clears recipient)
                            final isUnregisteredSelected = draftCapsule.isUnregisteredRecipient;
                            
                            if (!isUnregisteredSelected) {
                              return const SizedBox.shrink();
                            }
                            
                            return Column(
                              children: [
                                Card(
                                  key: _inviteOptionKey,
                                  elevation: 2,
                                  color: DynamicTheme.getButtonBackgroundColor(colorScheme, opacity: AppTheme.opacityHigh),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      // Deselect unregistered option
                                      ref.read(draftCapsuleProvider.notifier).clearUnregisteredRecipient();
                                      ref.read(draftCapsuleProvider.notifier).setRecipient(null);
                                    },
                                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                    child: Padding(
                                      padding: EdgeInsets.all(AppTheme.spacingMd),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 56,
                                                height: 56,
                                                decoration: BoxDecoration(
                                                  color: DynamicTheme.getButtonBackgroundColor(colorScheme, opacity: AppTheme.opacityHigh),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.mail_outline,
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
                                                      'Invite with a letter',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                        color: DynamicTheme.getPrimaryTextColor(colorScheme),
                                                      ),
                                                    ),
                                                    SizedBox(height: AppTheme.spacingXs),
                                                    Text(
                                                      "We'll send them a private link to unlock this letter",
                                                      style: TextStyle(
                                                        color: DynamicTheme.getSecondaryTextColor(colorScheme),
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Icon(
                                                Icons.check_circle,
                                                color: DynamicTheme.getButtonTextColor(colorScheme),
                                                size: 28,
                                              ),
                                            ],
                                          ),
                                          // Name input field (shown when unregistered recipient is selected)
                                          SizedBox(height: AppTheme.spacingMd),
                                          TextFormField(
                                            initialValue: draftCapsule.unregisteredRecipientName,
                                            decoration: InputDecoration(
                                              labelText: 'Recipient Name (Optional)',
                                              hintText: 'Enter their name',
                                              prefixIcon: Icon(
                                                Icons.person_outline,
                                                color: DynamicTheme.getInputHintColor(colorScheme),
                                              ),
                                            ),
                                            style: TextStyle(
                                              color: DynamicTheme.getInputTextColor(colorScheme),
                                            ),
                                            onChanged: (value) {
                                              ref.read(draftCapsuleProvider.notifier).setUnregisteredRecipient(
                                                recipientName: value.trim().isNotEmpty ? value.trim() : null,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: AppTheme.spacingLg),
                              ],
                            );
                          },
                        ),
                        
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
                            // Ensure mutual exclusivity: only selected if recipient matches AND unregistered is NOT selected
                            final isSelected = !draftCapsule.isUnregisteredRecipient && 
                                              selectedRecipient?.id == recipient.id;
                            final letterCountKey = '${user.id}|${recipient.id}|${recipient.linkedUserId ?? ''}';
                            
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
                                    // setRecipient automatically clears unregistered recipient
                                    ref.read(draftCapsuleProvider.notifier).setRecipient(recipient);
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
                                        // Isolated widget to prevent unnecessary rebuilds
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: _LetterCountBadge(letterCountKey: letterCountKey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        
                        SizedBox(height: AppTheme.spacingLg),
                        
                        // Send to unregistered user option - at bottom (only show when NOT selected)
                        Builder(
                          builder: (context) {
                            final draftCapsule = ref.watch(draftCapsuleProvider);
                            // Only show at bottom when NOT selected (when selected, it shows at top)
                            if (draftCapsule.isUnregisteredRecipient) {
                              return const SizedBox.shrink();
                            }
                            
                            return Card(
                              key: _inviteOptionKey,
                              elevation: 2,
                              color: DynamicTheme.getCardBackgroundColor(colorScheme),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                              ),
                              child: InkWell(
                                onTap: () {
                                  // Select unregistered option (automatically clears regular recipient)
                                  // setUnregisteredRecipient already clears the regular recipient
                                  ref.read(draftCapsuleProvider.notifier).setUnregisteredRecipient();
                                },
                                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                child: Padding(
                                  padding: EdgeInsets.all(AppTheme.spacingMd),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 56,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              color: DynamicTheme.getButtonBackgroundColor(colorScheme, opacity: 0.2),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.mail_outline,
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
                                                  'Invite with a letter',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: DynamicTheme.getPrimaryTextColor(colorScheme),
                                                  ),
                                                ),
                                                SizedBox(height: AppTheme.spacingXs),
                                                Text(
                                                  "We'll send them a private link to unlock this letter",
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
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
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
                  child: Builder(
                    builder: (context) {
                      final draftCapsule = ref.watch(draftCapsuleProvider);
                      return SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: (selectedRecipient != null || draftCapsule.isUnregisteredRecipient) ? widget.onNext : null,
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
                      );
                    },
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
