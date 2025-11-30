import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/router/app_router.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/color_scheme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';

class DraftsScreen extends ConsumerWidget {
  const DraftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final softGradient = DynamicTheme.softGradient(colorScheme);
    final drafts = ref.watch(draftsProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: softGradient,
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
                        color: colorScheme.primary1,
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
                  ],
                ),
              ),

              // Drafts List
              Expanded(
                child: drafts.isEmpty
                    ? _buildEmptyState(context, colorScheme)
                    : _buildDraftsList(context, ref, drafts, colorScheme),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.createCapsule),
        backgroundColor: colorScheme.primary1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.mail, size: 20),
            SizedBox(width: 4),
            Text('+', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
              'No drafts yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.primary1,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppTheme.spacingSm),
            Text(
              'Start writing a letter and it will appear here.',
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
  ) {
    // Sort drafts by last edited (most recent first)
    final sortedDrafts = List<Draft>.from(drafts)
      ..sort((a, b) => b.lastEdited.compareTo(a.lastEdited));

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingSm,
      ),
      itemCount: sortedDrafts.length,
      itemBuilder: (context, index) {
        final draft = sortedDrafts[index];
        return _buildDraftCard(context, ref, draft, colorScheme);
      },
    );
  }

  Widget _buildDraftCard(
    BuildContext context,
    WidgetRef ref,
    Draft draft,
    AppColorScheme colorScheme,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            // Navigate to create capsule screen with draft data
            // TODO: Pass draft data to create capsule screen
            context.push(Routes.createCapsule);
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Container(
            padding: EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        draft.displayTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: AppTheme.textGrey.withOpacity(0.6),
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _showDeleteConfirmation(context, ref, draft, colorScheme);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: AppTheme.spacingXs),
                
                // Content Snippet
                Text(
                  draft.snippet,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textGrey,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppTheme.spacingSm),
                
                // Last Edited
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppTheme.textGrey.withOpacity(0.6),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Edited $lastEditedText',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textGrey.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    Draft draft,
    AppColorScheme colorScheme,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text(
          'Delete Draft?',
          style: TextStyle(
            color: colorScheme.primary1,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This draft will be permanently deleted.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.textGrey,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(draftsProvider.notifier).deleteDraft(draft.id);
              Navigator.of(context).pop();
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Draft deleted'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
              );
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

