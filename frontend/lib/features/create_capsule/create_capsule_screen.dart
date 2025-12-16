import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  final int _totalSteps = 4;
  
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
              relationship: 'friend',
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
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      final capsule = draft.toCapsule(
        senderId: user.id,
        senderName: user.name,
      );
      
      final repo = ref.read(capsuleRepositoryProvider);
      
      // Create capsule directly with unlock time (Supabase schema)
      // Capsules are created in 'sealed' status with unlocks_at set
      await repo.createCapsule(capsule);
      
      // Invalidate capsules cache
      ref.invalidate(capsulesProvider);
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
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
        
        context.pop(); // Go back to home
      }
    } catch (e) {
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
                StepChooseRecipient(onNext: _nextStep),
                StepWriteLetter(onNext: _nextStep, onBack: _previousStep),
                StepChooseTime(onNext: _nextStep, onBack: _previousStep),
                StepPreview(onBack: _previousStep, onSubmit: _handleSubmit),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _currentStep == 0
          ? Padding(
              padding: EdgeInsets.only(bottom: 80), // Space for bottom nav if needed
              child: FloatingActionButton(
                onPressed: () async {
                  final userAsync = ref.read(currentUserProvider);
                  final user = userAsync.asData?.value;
                  if (user != null) {
                    await context.push(Routes.addRecipient);
                    ref.invalidate(recipientsProvider(user.id));
                  }
                },
                backgroundColor: colorScheme.primary1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.people_outline, size: 20),
                    SizedBox(width: 4),
                    Text('+', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
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
