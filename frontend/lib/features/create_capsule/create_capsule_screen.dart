import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/router/app_router.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/data/api_repositories.dart';
import 'package:openon_app/core/utils/error_handler.dart';
import 'package:openon_app/features/create_capsule/step_choose_recipient.dart';
import 'package:openon_app/features/create_capsule/step_write_letter.dart';
import 'package:openon_app/features/create_capsule/step_choose_time.dart';
import 'package:openon_app/features/create_capsule/step_preview.dart';

class CreateCapsuleScreen extends ConsumerStatefulWidget {
  const CreateCapsuleScreen({super.key});
  
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
    // Reset draft when entering screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(draftCapsuleProvider.notifier).reset();
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
      
      // Create capsule (in draft state)
      final createdCapsule = await repo.createCapsule(capsule);
      
      // Seal capsule with unlock time (if using API repository)
      if (repo is ApiCapsuleRepository && draft.unlockAt != null) {
        await repo.sealCapsule(createdCapsule.id, draft.unlockAt!);
      }
      
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
          onPressed: () async {
            final colorScheme = ref.read(selectedColorSchemeProvider);
            
            final confirmed = await showDialog<bool>(
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
            
            if (confirmed == true && context.mounted) {
              context.pop();
            }
          },
        ),
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
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
