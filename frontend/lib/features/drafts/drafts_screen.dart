import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/router/app_router.dart';
import 'package:openon_app/features/create_capsule/create_capsule_screen.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/color_scheme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:openon_app/core/widgets/common_widgets.dart';
import 'package:openon_app/core/constants/app_constants.dart';

/// Drafts List Screen
/// 
/// Displays all saved drafts for the current user.
/// 
/// UX Intent:
/// - Calm, minimal interface
/// - No engagement mechanics
/// - Focus on resuming writing, not metrics
class DraftsScreen extends ConsumerWidget {
  const DraftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.asData?.value;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Please log in to view drafts',
            style: TextStyle(
              color: DynamicTheme.getPrimaryTextColor(colorScheme),
            ),
          ),
        ),
      );
    }

    final draftsAsync = ref.watch(draftsProvider(user.id));

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: DynamicTheme.softGradient(colorScheme),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: EdgeInsets.all(AppTheme.spacingLg),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: DynamicTheme.getPrimaryIconColor(colorScheme),
                      ),
                      onPressed: () => context.pop(),
                    ),
                    SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Text(
                        'Drafts',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary1,
                        ),
                      ),
                    ),
                    // Refresh button
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: DynamicTheme.getPrimaryIconColor(colorScheme),
                      ),
                      onPressed: () {
                        Logger.debug('Manually refreshing drafts for user: ${user.id}');
                        ref.invalidate(draftsProvider(user.id));
                      },
                      tooltip: 'Refresh drafts',
                    ),
                  ],
                ),
              ),

              // Drafts List
              Expanded(
                child: draftsAsync.when(
                  data: (drafts) {
                    // Debug: Log drafts count
                    Logger.debug('Drafts loaded: ${drafts.length} for user ${user.id}');
                    
                    // Deduplicate drafts by ID (final safety check)
                    final uniqueDrafts = <String, Draft>{};
                    for (final draft in drafts) {
                      if (!uniqueDrafts.containsKey(draft.id)) {
                        uniqueDrafts[draft.id] = draft;
                      } else {
                        Logger.warning('Found duplicate draft in list: ${draft.id}');
                      }
                    }
                    final deduplicatedDrafts = uniqueDrafts.values.toList();
                    
                    if (deduplicatedDrafts.length != drafts.length) {
                      Logger.info(
                        'Deduplicated drafts: ${drafts.length} -> ${deduplicatedDrafts.length}'
                      );
                    }
                    
                    if (deduplicatedDrafts.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: () async {
                          Logger.debug('Pull-to-refresh: Refreshing drafts for user: ${user.id}');
                          // Invalidate provider to trigger refresh, then wait for smooth animation
                          ref.invalidate(draftsProvider(user.id));
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
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height - 200,
                            child: _buildEmptyState(context, colorScheme),
                          ),
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        Logger.debug('Pull-to-refresh: Refreshing drafts for user: ${user.id}');
                        // Invalidate provider to trigger refresh, then wait for smooth animation
                        ref.invalidate(draftsProvider(user.id));
                        await Future.delayed(AppConstants.refreshIndicatorDelay);
                      },
                      color: colorScheme.accent,
                      backgroundColor: colorScheme.isDarkTheme 
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                      strokeWidth: AppConstants.refreshIndicatorStrokeWidth,
                      displacement: AppConstants.refreshIndicatorDisplacement,
                      child: _buildDraftsList(context, ref, deduplicatedDrafts, colorScheme, user.id),
                    );
                  },
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        DynamicTheme.getPrimaryIconColor(colorScheme),
                      ),
                    ),
                  ),
                  error: (error, stack) => RefreshIndicator(
                    onRefresh: () async {
                      // Invalidate provider to trigger refresh, then wait for smooth animation
                      ref.invalidate(draftsProvider(user.id));
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
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppTheme.spacingLg),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Failed to load drafts',
                                style: TextStyle(
                                  color: DynamicTheme.getPrimaryTextColor(colorScheme),
                                ),
                              ),
                              SizedBox(height: AppTheme.spacingMd),
                              ElevatedButton(
                                onPressed: () {
                                  // Invalidate and reload
                                  ref.invalidate(draftsProvider(user.id));
                                },
                                child: const Text('Retry'),
                              ),
                              if (kDebugMode) ...[
                                SizedBox(height: AppTheme.spacingMd),
                                Text(
                                  'Error: $error',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit_note,
              size: 80,
              color: colorScheme.primary1.withOpacity(0.3),
            ),
            SizedBox(height: AppTheme.spacingLg),
            Text(
              'You don\'t have any drafts yet.',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.primary1,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppTheme.spacingSm),
            Text(
              'Drafts appear automatically when you start writing.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary1.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftsList(
    BuildContext context,
    WidgetRef ref,
    List<Draft> drafts,
    AppColorScheme colorScheme,
    String userId,
  ) {
    // Sort drafts by lastEdited (most recent first)
    final sortedDrafts = List<Draft>.from(drafts)
      ..sort((a, b) => b.lastEdited.compareTo(a.lastEdited));

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(), // Required for RefreshIndicator
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingSm,
      ),
      itemCount: sortedDrafts.length,
      itemBuilder: (context, index) {
        final draft = sortedDrafts[index];
        return _buildDraftCard(context, ref, draft, colorScheme, userId);
      },
    );
  }

  Widget _buildDraftCard(
    BuildContext context,
    WidgetRef ref,
    Draft draft,
    AppColorScheme colorScheme,
    String userId,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final lastEditedText = draft.lastEdited.day == DateTime.now().day &&
            draft.lastEdited.month == DateTime.now().month &&
            draft.lastEdited.year == DateTime.now().year
        ? 'Today at ${timeFormat.format(draft.lastEdited)}'
        : dateFormat.format(draft.lastEdited);

    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Material(
        color: DynamicTheme.getCardBackgroundColor(colorScheme),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            // Use draft data directly from the list (already loaded) for instant navigation
            // No need to reload from storage - this eliminates blocking I/O
            final draftData = DraftNavigationData(
              draftId: draft.id,
              content: draft.body,
              title: draft.title,
              recipientName: draft.recipientName,
              recipientAvatar: draft.recipientAvatar,
            );
            
            // Navigate immediately without blocking
            context.push(Routes.createCapsule, extra: draftData);
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingSm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.isDarkTheme
                      ? Colors.black.withOpacity(AppTheme.shadowOpacityHigh)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Receiver avatar (left side, like capsule cards)
                _buildReceiverAvatar(context, ref, draft, colorScheme),
                SizedBox(width: AppTheme.spacingSm),
                
                // Content (expanded, like capsule cards)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Recipient name (like capsule.receiverName)
                      Text(
                        draft.recipientName ?? 'Untitled Draft',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: DynamicTheme.getPrimaryTextColor(colorScheme),
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Draft title/label (like capsule.label)
                      if (draft.title != null && draft.title!.trim().isNotEmpty) ...[
                        SizedBox(height: 2),
                        Text(
                          draft.title!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: DynamicTheme.getSecondaryTextColor(colorScheme),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      SizedBox(height: AppTheme.spacingXs),
                      // Last Edited
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: DynamicTheme.getSecondaryIconColor(colorScheme),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Last edited $lastEditedText',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DynamicTheme.getSecondaryTextColor(colorScheme),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Delete button
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: DynamicTheme.getSecondaryIconColor(colorScheme),
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _showDeleteConfirmation(context, ref, draft, colorScheme, userId);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiverAvatar(
    BuildContext context,
    WidgetRef ref,
    Draft draft,
    AppColorScheme colorScheme,
  ) {
    // Use actual recipient avatar if available, otherwise show placeholder
    // Similar to how capsule cards display receiver avatar
    final recipientName = draft.recipientName;
    final recipientAvatar = draft.recipientAvatar;
    
    // If we have recipient info, use it (like capsule cards)
    if (recipientName != null && recipientName.isNotEmpty) {
      final hasAvatar = recipientAvatar != null && recipientAvatar.isNotEmpty;
      final avatarUrl = hasAvatar && recipientAvatar.startsWith('http')
          ? recipientAvatar
          : null;
      final avatarPath = hasAvatar && !recipientAvatar.startsWith('http')
          ? recipientAvatar
          : null;
      
      // Compact size for draft cards: radius 24 = diameter 48
      if (hasAvatar && (avatarUrl != null || avatarPath != null)) {
        // Use UserAvatar widget for proper image handling
        return UserAvatar(
          name: recipientName,
          imageUrl: avatarUrl,
          imagePath: avatarPath,
          size: 48, // diameter = 2 * radius
        );
      }
      
      // Placeholder avatar with recipient's initial
      return CircleAvatar(
        radius: 24,
        backgroundColor: colorScheme.primary1.withOpacity(0.1),
        child: Text(
          recipientName[0].toUpperCase(),
          style: TextStyle(
            color: colorScheme.primary1,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    
    // No recipient info - show placeholder
    return CircleAvatar(
      radius: 24,
      backgroundColor: colorScheme.primary1.withOpacity(0.1),
      child: Icon(
        Icons.person_outline,
        size: 24,
        color: colorScheme.primary1,
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    Draft draft,
    AppColorScheme colorScheme,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DynamicTheme.getDialogBackgroundColor(colorScheme),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text(
          'Delete Draft?',
          style: TextStyle(
            color: DynamicTheme.getDialogTitleColor(colorScheme),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This draft will be permanently deleted.',
          style: TextStyle(
            color: DynamicTheme.getDialogContentColor(colorScheme),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: DynamicTheme.getDialogButtonColor(colorScheme),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              HapticFeedback.mediumImpact();
              
              try {
                final notifier = ref.read(draftsNotifierProvider(userId).notifier);
                await notifier.deleteDraft(draft.id);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Draft deleted'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Failed to delete draft'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
