import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/router/app_router.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/color_scheme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/utils/error_handler.dart';
import 'package:openon_app/core/widgets/common_widgets.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:openon_app/features/create_capsule/step_choose_recipient.dart';
import 'package:openon_app/features/create_capsule/step_write_letter.dart';
import 'package:openon_app/features/create_capsule/step_choose_time.dart';
import 'package:openon_app/features/create_capsule/step_anonymous_settings.dart';
import 'package:openon_app/features/create_capsule/step_preview.dart';

/// Exit action options for letter creation exit dialog
enum ExitAction {
  save,
  discard,
  continueWriting,
}

/// Data passed when navigating to CreateCapsuleScreen with a draft
class DraftNavigationData {
  final String draftId;
  final String content;
  final String? title;
  final String? recipientName;
  final String? recipientAvatar;
  
  const DraftNavigationData({
    required this.draftId,
    required this.content,
    this.title,
    this.recipientName,
    this.recipientAvatar,
  });
}

class CreateCapsuleScreen extends ConsumerStatefulWidget {
  final DraftNavigationData? draftData;
  
  const CreateCapsuleScreen({super.key, this.draftData});
  
  @override
  ConsumerState<CreateCapsuleScreen> createState() => _CreateCapsuleScreenState();
}

class _CreateCapsuleScreenState extends ConsumerState<CreateCapsuleScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 5;
  
  @override
  void initState() {
    super.initState();
    // Always reset state first to ensure clean slate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      // Clear any leftover state
      ref.read(draftCapsuleProvider.notifier).reset();
      
      // If draft data was passed via route, populate it
      if (widget.draftData != null) {
        final draftData = widget.draftData!;
        
        // Populate draft capsule with passed data
        ref.read(draftCapsuleProvider.notifier).setContent(draftData.content);
        if (draftData.title != null && draftData.title!.trim().isNotEmpty) {
          ref.read(draftCapsuleProvider.notifier).setLabel(draftData.title!);
        }
        ref.read(draftCapsuleProvider.notifier).setDraftId(draftData.draftId);
        
        // Restore recipient if available (async, non-blocking)
        if (draftData.recipientName != null) {
          final userAsync = ref.read(currentUserProvider);
          final user = userAsync.asData?.value;
          if (user != null) {
            // Create temporary recipient immediately for instant UI update
            final tempRecipient = Recipient(
              userId: user.id,
              name: draftData.recipientName!,
              avatar: draftData.recipientAvatar ?? '',
            );
            ref.read(draftCapsuleProvider.notifier).setRecipient(tempRecipient);
            
            // Try to find matching recipient in background (non-blocking)
            final recipientsAsync = ref.read(recipientsProvider(user.id));
            recipientsAsync.whenData((recipients) {
              if (!mounted) return;
              try {
                final matchingRecipient = recipients.firstWhere(
                  (r) => r.name == draftData.recipientName,
                );
                // Update with real recipient if found
                ref.read(draftCapsuleProvider.notifier).setRecipient(matchingRecipient);
              } catch (e) {
                // Keep temporary recipient if not found
              }
            });
          }
        }
        
        // Start at step 1 (Write Letter) with pre-populated data
        _currentStep = 1;
        // Use SchedulerBinding to ensure frame is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pageController.hasClients) {
            _pageController.jumpToPage(_currentStep);
          }
        });
      }
    });
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  Future<void> _handleExitIntent() async {
    final draft = ref.read(draftCapsuleProvider);
    final hasContent = (draft.content?.trim().isNotEmpty ?? false);
    
    // If no content, just show simple discard dialog
    if (!hasContent) {
      final confirmed = await _showDiscardDialog();
      if (confirmed == true && context.mounted) {
        context.pop();
      }
      return;
    }
    
    // If has content, show save as draft options
    final result = await _showSaveDraftDialog();
    
    if (!context.mounted) return;
    
    switch (result) {
      case ExitAction.save:
        // Save as draft and exit
        await _saveAsDraft();
        if (context.mounted) {
          context.pop();
        }
        break;
      case ExitAction.discard:
        // Discard and exit
        if (context.mounted) {
          context.pop();
        }
        break;
      case ExitAction.continueWriting:
      case null:
        // Cancel - stay on screen
        break;
    }
  }
  
  Future<bool?> _showDiscardDialog() async {
    final colorScheme = ref.read(selectedColorSchemeProvider);
    
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DynamicTheme.getDialogBackgroundColor(colorScheme),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text(
          'Discard letter?',
          style: TextStyle(
            color: DynamicTheme.getDialogTitleColor(colorScheme),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to discard this letter?',
          style: TextStyle(
            color: DynamicTheme.getDialogContentColor(colorScheme),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: DynamicTheme.getDialogButtonColor(colorScheme),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }
  
  Future<ExitAction?> _showSaveDraftDialog() async {
    final colorScheme = ref.read(selectedColorSchemeProvider);
    
    return showModalBottomSheet<ExitAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => Container(
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
                      'Save your letter?',
                      style: TextStyle(
                        color: DynamicTheme.getPrimaryTextColor(colorScheme),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppTheme.spacingSm),
                    Text(
                      'Your letter will be saved as a draft.',
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
                      subtitle: 'Your letter will be saved',
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
      ),
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
  
  Future<void> _saveAsDraft() async {
    try {
      final draft = ref.read(draftCapsuleProvider);
      final content = draft.content?.trim() ?? '';
      
      if (content.isEmpty) {
        Logger.debug('No content to save as draft');
        return;
      }
      
      final userAsync = ref.read(currentUserProvider);
      final user = userAsync.asData?.value;
      if (user == null) {
        Logger.debug('No user to save draft');
        return;
      }
      
      final repo = ref.read(draftRepositoryProvider);
      
      // Check if a draft ID already exists (from auto-save in StepWriteLetter)
      if (draft.draftId != null) {
        // Update existing draft instead of creating a new one
        Logger.debug('Updating existing draft: ${draft.draftId}');
        await repo.updateDraft(
          draft.draftId!,
          content,
          title: draft.label,
          recipientName: draft.recipient?.name,
          recipientAvatar: draft.recipient?.avatar,
        );
        Logger.info('Letter updated as draft from create capsule screen');
      } else {
        // No existing draft ID - create new one
        // Don't check for duplicates - it's expensive and not necessary
        // If user wants to save, create a new draft
        final newDraft = await repo.createDraft(
          userId: user.id,
          title: draft.label,
          content: content,
          recipientName: draft.recipient?.name,
          recipientAvatar: draft.recipient?.avatar,
        );
        
        // Store draft ID in DraftCapsule for future reference
        ref.read(draftCapsuleProvider.notifier).setDraftId(newDraft.id);
        
        Logger.info('Letter saved as draft from create capsule screen');
      }
      
      // Invalidate drafts provider to refresh the list
      ref.invalidate(draftsProvider(user.id));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Letter saved as draft'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        );
      }
    } catch (e) {
      Logger.error('Failed to save letter as draft', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save draft'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    final draft = ref.read(draftCapsuleProvider);
    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.asData?.value;
    
    if (user == null || !draft.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please complete all required fields'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      );
      return;
    }
    
    try {
      // Check if this is a self letter (recipient is "myself")
      final isSelfLetter = draft.recipient != null && 
                          draft.recipient!.linkedUserId == user.id;
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // If self letter, create self letter instead of capsule
      if (isSelfLetter) {
        if (draft.content == null || draft.unlockAt == null) {
          throw Exception('Content and unlock time are required');
        }
        
        // Validate content length for self letters (20-500 characters)
        final contentLength = draft.content!.trim().length;
        if (contentLength < 20) {
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Self letters must be at least 20 characters (currently $contentLength). '
                  'Please add more to your letter.',
                ),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
            );
          }
          return;
        }
        if (contentLength > 500) {
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Self letters must be at most 500 characters (currently $contentLength). '
                  'Please shorten your letter.',
                ),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
            );
          }
          return;
        }
        
        final selfLetterRepo = ref.read(selfLetterRepositoryProvider);
        await selfLetterRepo.createSelfLetter(
          content: draft.content!,
          scheduledOpenAt: draft.unlockAt!,
          title: draft.label, // Use label as title
          mood: draft.mood,
          lifeArea: draft.lifeArea,
          city: draft.city,
        );
        
        Logger.info('Self letter created successfully');
        
        // Delete draft if it exists
        final draftId = draft.draftId;
        if (draftId != null) {
          try {
            final draftRepo = ref.read(draftRepositoryProvider);
            await draftRepo.deleteDraft(draftId, user.id);
            ref.invalidate(draftsProvider(user.id));
            Logger.info('Deleted draft $draftId after sending');
          } catch (e) {
            Logger.warning('Failed to delete draft $draftId after sending: $e');
          }
        }
        
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          
          // Invalidate self letters provider to refresh the list
          ref.invalidate(selfLettersProvider);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Letter to yourself created successfully! 💌'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
          );
          
          // Navigate to home screen
          context.go(Routes.home);
        }
        return;
      }
      
      // Regular capsule creation flow
      final capsule = draft.toCapsule(
        senderId: user.id,
        senderName: user.name,
      );
      
      Logger.info(
        'Creating capsule: recipientId=${draft.recipient?.id}, '
        'recipientId=${capsule.recipientId}, receiverName=${capsule.receiverName}'
      );
      
      final repo = ref.read(capsuleRepositoryProvider);
      final createdCapsule = await repo.createCapsule(
        capsule,
        hint1: draft.hint1,
        hint2: draft.hint2,
        hint3: draft.hint3,
        isUnregisteredRecipient: draft.isUnregisteredRecipient,
        unregisteredRecipientName: draft.isUnregisteredRecipient ? (draft.unregisteredRecipientName ?? 'Someone special') : null,
      );
      
      Logger.info(
        'Capsule created successfully: id=${createdCapsule.id}, '
        'isUnregistered=${draft.isUnregisteredRecipient}, '
        'inviteUrl=${createdCapsule.inviteUrl}'
      );
      
      // Delete draft if it exists (draft was sent, so it should be removed)
      final draftId = draft.draftId;
      if (draftId != null) {
        try {
          final draftRepo = ref.read(draftRepositoryProvider);
          await draftRepo.deleteDraft(draftId, user.id);
          // Invalidate drafts provider to refresh the list
          ref.invalidate(draftsProvider(user.id));
          Logger.info('Deleted draft $draftId after sending');
        } catch (e) {
          // Log error but don't fail the whole operation
          Logger.warning('Failed to delete draft $draftId after sending: $e');
        }
      }
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // If this is for an unregistered recipient, show invite URL
        if (draft.isUnregisteredRecipient) {
          if (createdCapsule.inviteUrl != null && createdCapsule.inviteUrl!.isNotEmpty) {
            Logger.info('Showing invite share dialog with URL: ${createdCapsule.inviteUrl}');
            await _showInviteShareDialog(createdCapsule.inviteUrl!);
          } else {
            Logger.warning('Unregistered recipient but no invite URL received. Response: ${createdCapsule.inviteUrl}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Letter created successfully! 💌\nInvite link will be available in your outbox.'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Letter created successfully! 💌'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
          );
        }
        
        // Invalidate capsules cache to refresh outbox
        ref.invalidate(capsulesProvider);
        
        // Navigate to home screen instead of just popping
        // This ensures we don't stay on drafts screen if we came from there
        context.go(Routes.home);
      }
    } catch (e, stackTrace) {
      Logger.error(
        'Error creating capsule',
        error: e,
        stackTrace: stackTrace,
      );
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        final errorMsg = ErrorHandler.getErrorMessage(
          e,
          defaultMessage: ErrorHandler.getDefaultErrorMessage('create letter'),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        );
      }
    }
  }
  
  Future<void> _showInviteShareDialog(String inviteUrl) async {
    final colorScheme = ref.read(selectedColorSchemeProvider);
    
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(AppTheme.spacingLg),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: 500,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colorScheme.primary1, colorScheme.primary2],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.all(AppTheme.spacingMd),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Share Invite Link',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingXl,
                          vertical: AppTheme.spacingLg,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Success message
                            Container(
                              padding: EdgeInsets.all(AppTheme.spacingLg),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                  SizedBox(height: AppTheme.spacingMd),
                                  Text(
                                    'Letter created successfully!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: AppTheme.spacingSm),
                                  Text(
                                    'Share this private link to send the letter',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: AppTheme.spacingLg),
                            // Share buttons
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingXs),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildShareButton(
                                    icon: Icons.message,
                                    label: 'Text',
                                    onTap: () => _shareInviteLink(inviteUrl, dialogContext),
                                  ),
                                  SizedBox(width: AppTheme.spacingSm),
                                  _buildShareButton(
                                    icon: Icons.link,
                                    label: 'Copy Link',
                                    onTap: () async {
                                      await Clipboard.setData(ClipboardData(text: inviteUrl));
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Link copied to clipboard'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
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
        );
      },
    );
  }
  
  Widget _buildShareButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 24,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  Future<void> _shareInviteLink(String inviteUrl, BuildContext dialogContext) async {
    try {
      if (Platform.isIOS) {
        final screenSize = MediaQuery.of(dialogContext).size;
        await Share.share(
          inviteUrl,
          sharePositionOrigin: Rect.fromLTWH(
            screenSize.width / 2 - 50,
            screenSize.height - 100,
            100,
            100,
          ),
        );
      } else {
        await Share.share(inviteUrl);
      }
    } catch (e) {
      Logger.error('Error sharing invite link', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to open share dialog. Please copy the link manually.'),
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Copy Link',
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: inviteUrl));
              },
            ),
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Letter'),
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: DynamicTheme.getPrimaryIconColor(colorScheme),
          ),
          onPressed: () => _handleExitIntent(),
        ),
        actions: [
          ProfileAvatarButton(),
        ],
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StepChooseRecipient(key: const ValueKey('step_recipient'), onNext: _nextStep),
                StepWriteLetter(key: const ValueKey('step_write'), onNext: _nextStep, onBack: _previousStep),
                StepChooseTime(key: const ValueKey('step_time'), onNext: _nextStep, onBack: _previousStep),
                StepAnonymousSettings(key: const ValueKey('step_anonymous'), onNext: _nextStep, onBack: _previousStep),
                StepPreview(key: const ValueKey('step_preview'), onBack: _previousStep, onSubmit: _handleSubmit),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _currentStep == 0
          ? Padding(
              // Position FAB above the continue button (56px button + 24px padding top + 24px padding bottom = 104px)
              padding: const EdgeInsets.only(bottom: 104),
              child: FloatingActionButton(
                onPressed: () async {
                  final userAsync = ref.read(currentUserProvider);
                  final user = userAsync.asData?.value;
                  if (user != null) {
                    await context.push(Routes.addConnection);
                    // Refresh recipients list after returning from add connection
                    ref.invalidate(recipientsProvider(user.id));
                  }
                },
                backgroundColor: colorScheme.primary1,
                elevation: 4,
                child: const Icon(Icons.person_add, color: Colors.white),
              ),
            )
          : null,
    );
  }
  
  Widget _buildProgressIndicator() {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        color: DynamicTheme.getCardBackgroundColor(colorScheme),
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
        children: List.generate(_totalSteps, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isCurrent
                          ? colorScheme.primary1
                          : AppColors.lightGray,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < _totalSteps - 1) SizedBox(width: AppTheme.spacingSm),
              ],
            ),
          );
        }),
      ),
    );
  }
}
