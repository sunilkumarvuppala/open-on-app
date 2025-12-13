import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/color_scheme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/widgets/common_widgets.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:openon_app/core/data/repositories.dart';

/// Exit action options for draft exit dialog
enum ExitAction {
  save,
  discard,
  continueWriting,
}

/// Draft Letter Screen
/// 
/// A calm, distraction-free writing experience for composing letters.
/// 
/// UX Intent:
/// - No animations while typing (intentionally absent)
/// - No word count, streaks, or gamification (intentionally absent)
/// - No AI suggestions or prompts (intentionally absent)
/// - Minimal UI that feels like "writing alone with a notebook"
/// 
/// This screen protects emotional honesty, not engagement metrics.
/// 
/// Crash Safety:
/// - Auto-saves locally immediately (crash-safe)
/// - Auto-saves remotely with debouncing (800ms)
/// - Saves on app background/pause
/// - Saves on navigation
/// - Saves on widget disposal
class DraftLetterScreen extends ConsumerStatefulWidget {
  final String? draftId;

  const DraftLetterScreen({
    super.key,
    this.draftId,
  });

  @override
  ConsumerState<DraftLetterScreen> createState() => _DraftLetterScreenState();
}

class _DraftLetterScreenState extends ConsumerState<DraftLetterScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _textController;
  late final TextEditingController _titleController;
  late final FocusNode _focusNode;
  late final FocusNode _titleFocusNode;
  bool _hasAutoFocused = false;
  bool _isExiting = false;
  String? _userId;
  String? _draftId;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _titleController = TextEditingController();
    _focusNode = FocusNode();
    _titleFocusNode = FocusNode();
    
    // Observe app lifecycle for auto-save
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Save using stored values (ref is not available after dispose)
    // This is a fallback - most saves happen via auto-save or navigation handlers
    if (_userId != null && _textController.text.trim().isNotEmpty) {
      _saveDraftDirectly(_userId!, _textController.text);
    }
    
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();
    _titleController.dispose();
    _focusNode.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }
  
  /// Save draft directly without using ref (for dispose fallback)
  Future<void> _saveDraftDirectly(String userId, String content) async {
    try {
      final repo = LocalDraftRepository();
      final title = _titleController.text.trim().isEmpty ? null : _titleController.text.trim();
      // Note: DraftLetterScreen doesn't have recipient info, so pass null
      if (_draftId == null) {
        await repo.createDraft(
          userId: userId,
          title: title,
          content: content,
          recipientName: null,
          recipientAvatar: null,
        );
      } else {
        await repo.updateDraft(
          _draftId!,
          content,
          title: title,
          recipientName: null,
          recipientAvatar: null,
        );
      }
      Logger.debug('Draft saved directly on dispose');
    } catch (e) {
      // Silently fail - this is just a fallback
      Logger.debug('Failed to save draft directly: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Save on app background/pause
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _saveImmediately();
    }
  }


  Future<void> _saveImmediately() async {
    if (!mounted) return;
    
    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.asData?.value;
    if (user == null) return;

    final params = (userId: user.id, draftId: widget.draftId);
    try {
      await ref.read(draftLetterProvider(params).notifier).saveImmediately();
    } catch (e) {
      // Silently fail - local storage should have saved
      Logger.debug('Failed to save immediately: $e');
    }
  }

  void _handleTextChanged(String text) {
    if (!mounted) return;
    
    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.asData?.value;
    if (user == null || !mounted) return;

    final params = (userId: user.id, draftId: widget.draftId);
    ref.read(draftLetterProvider(params).notifier).updateContent(text);
  }
  
  void _handleTitleChanged(String title) {
    if (!mounted) return;
    
    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.asData?.value;
    if (user == null || !mounted) return;

    final params = (userId: user.id, draftId: widget.draftId);
    ref.read(draftLetterProvider(params).notifier).updateTitle(title);
  }

  Future<void> _handleContinue() async {
    if (!mounted) return;
    
    // Save immediately before navigation
    await _saveImmediately();

    // Navigate to recipient selection (next screen)
    // TODO: Replace with actual recipient selection route
    // For now, navigate back
    if (mounted) {
      context.pop();
    }
  }

  Future<void> _handleExitIntent() async {
    if (_isExiting) {
      Logger.debug('Already handling exit, ignoring duplicate call');
      return;
    }
    
    Logger.debug('_handleExitIntent called');
    
    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.asData?.value;
    if (user == null) {
      Logger.debug('No user found, exiting without dialog');
      if (mounted) context.pop();
      return;
    }

    final params = (userId: user.id, draftId: widget.draftId);
    final draftState = ref.read(draftLetterProvider(params));
    
    // Check both state and controller for content
    final content = draftState.content.trim();
    final controllerContent = _textController.text.trim();
    final hasContent = content.isNotEmpty || controllerContent.isNotEmpty;
    
    Logger.debug('Content check - state: "${content}", controller: "${controllerContent}", hasContent: $hasContent');
    
    // If content is empty, just exit
    if (!hasContent) {
      Logger.debug('No content, exiting without dialog');
      if (mounted) context.pop();
      return;
    }

    // Show exit confirmation dialog
    Logger.debug('Showing exit dialog');
    _isExiting = true;
    final result = await _showExitDialog();
    _isExiting = false;
    Logger.debug('Exit dialog result: $result');

    if (!mounted) return;

    switch (result) {
      case ExitAction.save:
        // Save and exit
        await _saveImmediately();
        if (mounted) context.pop();
        break;
      case ExitAction.discard:
        // Discard and exit
        if (mounted) context.pop();
        break;
      case ExitAction.continueWriting:
        // Cancel - stay on screen
        break;
      case null:
        // Dialog dismissed - stay on screen
        break;
    }
  }

  Future<ExitAction?> _showExitDialog() async {
    Logger.debug('_showExitDialog called');
    
    if (!mounted) {
      Logger.debug('Widget not mounted, cannot show dialog');
      return null;
    }
    
    final colorScheme = ref.read(selectedColorSchemeProvider);
    
    Logger.debug('Showing modal bottom sheet');
    return showModalBottomSheet<ExitAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) {
        Logger.debug('Building exit dialog UI');
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.secondary2,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusLg),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: AppTheme.spacingSm),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DynamicTheme.getPrimaryTextColor(colorScheme).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                Padding(
                  padding: EdgeInsets.all(AppTheme.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Save your draft?',
                        style: TextStyle(
                          color: DynamicTheme.getPrimaryTextColor(colorScheme),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingSm),
                      Text(
                        'Your changes will be saved automatically.',
                        style: TextStyle(
                          color: DynamicTheme.getPrimaryTextColor(colorScheme).withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingLg),
                      
                      // Save as draft (default)
                      _buildExitOption(
                        context: context,
                        icon: Icons.save_outlined,
                        title: 'Save as draft',
                        subtitle: 'Your draft will be saved',
                        colorScheme: colorScheme,
                        isDefault: true,
                        onTap: () => Navigator.of(context).pop(ExitAction.save),
                      ),
                      SizedBox(height: AppTheme.spacingSm),
                      
                      // Discard
                      _buildExitOption(
                        context: context,
                        icon: Icons.delete_outline,
                        title: 'Discard',
                        subtitle: 'Your changes will be lost',
                        colorScheme: colorScheme,
                        isDestructive: true,
                        onTap: () => Navigator.of(context).pop(ExitAction.discard),
                      ),
                      SizedBox(height: AppTheme.spacingSm),
                      
                      // Continue writing
                      _buildExitOption(
                        context: context,
                        icon: Icons.edit_outlined,
                        title: 'Continue writing',
                        subtitle: 'Stay on this screen',
                        colorScheme: colorScheme,
                        onTap: () => Navigator.of(context).pop(ExitAction.continueWriting),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExitOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required AppColorScheme colorScheme,
    required VoidCallback onTap,
    bool isDefault = false,
    bool isDestructive = false,
  }) {
    final textColor = isDestructive
        ? Colors.red
        : DynamicTheme.getPrimaryTextColor(colorScheme);
    
    final backgroundColor = isDefault
        ? DynamicTheme.getPrimaryTextColor(colorScheme).withOpacity(0.1)
        : Colors.transparent;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              Icon(
                icon,
                color: textColor,
                size: 24,
              ),
              SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: isDefault ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colorScheme = ref.read(selectedColorSchemeProvider);
        return AlertDialog(
          backgroundColor: colorScheme.secondary2,
          title: Text(
            'Delete Draft',
            style: TextStyle(
              color: DynamicTheme.getPrimaryTextColor(colorScheme),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this draft? This cannot be undone.',
            style: TextStyle(
              color: DynamicTheme.getPrimaryTextColor(colorScheme).withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: DynamicTheme.getPrimaryTextColor(colorScheme),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        if (!mounted) return;
        final userAsync = ref.read(currentUserProvider);
        final user = userAsync.asData?.value;
        if (user == null || !mounted) return;

        final params = (userId: user.id, draftId: widget.draftId);
        await ref.read(draftLetterProvider(params).notifier).deleteDraft();

        if (mounted) {
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to delete draft. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.asData?.value;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Please log in to continue',
            style: TextStyle(
              color: DynamicTheme.getPrimaryTextColor(colorScheme),
            ),
          ),
        ),
      );
    }

    // Store user ID and draft ID for dispose fallback
    _userId = user.id;
    _draftId = widget.draftId;

    final params = (userId: user.id, draftId: widget.draftId);
    final draftState = ref.watch(draftLetterProvider(params));

    // Sync text controllers with state
    if (draftState.content != _textController.text) {
      _textController.text = draftState.content;
    }
    if (draftState.title != _titleController.text) {
      _titleController.text = draftState.title ?? '';
    }

    // Auto-focus for new drafts
    if (widget.draftId == null && !_hasAutoFocused && !draftState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _focusNode.canRequestFocus) {
          _focusNode.requestFocus();
          _hasAutoFocused = true;
        }
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && !_isExiting && mounted) {
          await _handleExitIntent();
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.secondary2,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: DynamicTheme.getPrimaryIconColor(colorScheme),
            ),
            onPressed: () async {
              if (!mounted || _isExiting) return;
              await _handleExitIntent();
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Draft',
                style: TextStyle(
                  color: DynamicTheme.getPrimaryTextColor(colorScheme),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'This won\'t be sent until you seal it.',
                style: TextStyle(
                  color: DynamicTheme.getPrimaryTextColor(colorScheme).withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          actions: [
            // Delete button (only for existing drafts)
            if (widget.draftId != null)
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: DynamicTheme.getPrimaryIconColor(colorScheme).withOpacity(0.7),
                ),
                onPressed: _handleDelete,
                tooltip: 'Delete draft',
              ),
            // Debug button - remove in production
            if (kDebugMode)
              IconButton(
                icon: Icon(
                  Icons.bug_report,
                  color: DynamicTheme.getPrimaryIconColor(colorScheme).withOpacity(0.7),
                ),
                onPressed: () {
                  Logger.debug('=== MANUAL TEST: Exit Dialog ===');
                  Logger.debug('Text controller: "${_textController.text}"');
                  Logger.debug('Draft state content: "${draftState.content}"');
                  _handleExitIntent();
                },
                tooltip: 'Test exit dialog',
              ),
          ],
        ),
        body: draftState.isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    DynamicTheme.getPrimaryIconColor(colorScheme),
                  ),
                ),
              )
            : Column(
                children: [
                  // Save status indicator (subtle, non-distracting)
                  if (draftState.saveStatus != DraftSaveStatus.idle)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingLg,
                        vertical: AppTheme.spacingXs,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (draftState.saveStatus == DraftSaveStatus.saving)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      DynamicTheme.getPrimaryTextColor(colorScheme).withOpacity(0.6),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Saving…',
                                  style: TextStyle(
                                    color: DynamicTheme.getPrimaryTextColor(colorScheme).withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            )
                          else if (draftState.saveStatus == DraftSaveStatus.saved)
                            Text(
                              'Saved',
                              style: TextStyle(
                                color: DynamicTheme.getPrimaryTextColor(colorScheme).withOpacity(0.6),
                                fontSize: 12,
                              ),
                            )
                          else if (draftState.saveStatus == DraftSaveStatus.error)
                            Text(
                              'Save failed',
                              style: TextStyle(
                                color: Colors.red.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),

                  // Text input area
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spacingLg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title field
                          TextField(
                            controller: _titleController,
                            focusNode: _titleFocusNode,
                            onChanged: _handleTitleChanged,
                            style: TextStyle(
                              color: DynamicTheme.getPrimaryTextColor(colorScheme),
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Letter Title (optional)',
                              hintStyle: TextStyle(
                                color: DynamicTheme.getInputHintColor(colorScheme),
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          SizedBox(height: AppTheme.spacingMd),
                          // Content field
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              focusNode: _focusNode,
                              onChanged: _handleTextChanged,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              style: TextStyle(
                                color: DynamicTheme.getPrimaryTextColor(colorScheme),
                                fontSize: 16,
                                height: 1.6, // Comfortable line height
                              ),
                              decoration: InputDecoration(
                                hintText: 'Write what matters. You can take your time.',
                                hintStyle: TextStyle(
                                  color: DynamicTheme.getPrimaryTextColor(colorScheme).withOpacity(0.4),
                                  fontSize: 16,
                                  height: 1.6,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                // No rich text formatting, no markdown, no AI suggestions
                                // Intentionally minimal
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom action bar
                  Container(
                    padding: EdgeInsets.all(AppTheme.spacingLg),
                    decoration: BoxDecoration(
                      color: colorScheme.secondary2,
                      border: Border(
                        top: BorderSide(
                          color: DynamicTheme.getPrimaryTextColor(colorScheme).withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: GradientButton(
                        text: 'Continue',
                        onPressed: _handleContinue,
                        isLoading: false,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
