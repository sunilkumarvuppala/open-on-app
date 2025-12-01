import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/router/app_router.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/models.dart';

// State provider for draft capsule
final draftCapsuleProvider = StateProvider.autoDispose<DraftCapsule>((ref) {
  return DraftCapsule();
});

class DraftCapsule {
  final Recipient? recipient;
  final String letterText;
  final XFile? photo;
  final DateTime? unlockTime;
  final String label;

  DraftCapsule({
    this.recipient,
    this.letterText = '',
    this.photo,
    this.unlockTime,
    this.label = '',
  });

  DraftCapsule copyWith({
    Recipient? recipient,
    String? letterText,
    XFile? photo,
    DateTime? unlockTime,
    String? label,
    bool clearPhoto = false,
  }) {
    return DraftCapsule(
      recipient: recipient ?? this.recipient,
      letterText: letterText ?? this.letterText,
      photo: clearPhoto ? null : (photo ?? this.photo),
      unlockTime: unlockTime ?? this.unlockTime,
      label: label ?? this.label,
    );
  }

  bool get isValid {
    return recipient != null &&
        letterText.trim().isNotEmpty &&
        unlockTime != null &&
        unlockTime!.isAfter(DateTime.now()) &&
        label.trim().isNotEmpty;
  }
}

class CreateCapsuleScreen extends ConsumerStatefulWidget {
  final String? preSelectedRecipientId;

  const CreateCapsuleScreen({
    super.key,
    this.preSelectedRecipientId,
  });

  @override
  ConsumerState<CreateCapsuleScreen> createState() => _CreateCapsuleScreenState();
}

class _CreateCapsuleScreenState extends ConsumerState<CreateCapsuleScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    // Pre-select recipient if provided
    if (widget.preSelectedRecipientId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadPreSelectedRecipient();
      });
    }
  }

  Future<void> _loadPreSelectedRecipient() async {
    final recipientAsync = ref.read(recipientProvider(widget.preSelectedRecipientId!));
    recipientAsync.whenData((recipient) {
      if (recipient != null) {
        ref.read(draftCapsuleProvider.notifier).state = 
            ref.read(draftCapsuleProvider).copyWith(recipient: recipient);
      }
    });
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: AppTheme.animationNormal,
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: AppTheme.animationNormal,
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Letter'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          _StepIndicator(
            currentStep: _currentStep,
            totalSteps: 5,
          ),
          
          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _ChooseRecipientStep(onNext: _nextStep),
                _WriteLetterStep(onNext: _nextStep, onBack: _previousStep),
                _AddPhotoStep(onNext: _nextStep, onBack: _previousStep),
                _ChooseDateTimeStep(onNext: _nextStep, onBack: _previousStep),
                _PreviewStep(onBack: _previousStep),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final isActive = index <= currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(
                right: index < totalSteps - 1 ? AppTheme.spacingSm : 0,
              ),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.deepPurple : AppTheme.lavender,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// Step 1: Choose Recipient
class _ChooseRecipientStep extends ConsumerWidget {
  final VoidCallback onNext;

  const _ChooseRecipientStep({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipientsAsync = ref.watch(recipientsProvider);
    final draft = ref.watch(draftCapsuleProvider);

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Who is this letter for?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Choose the person who will receive your time-locked letter',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spacingXl),
          
          Expanded(
            child: recipientsAsync.when(
              data: (recipients) {
                if (recipients.isEmpty) {
                  return EmptyState(
                    icon: Icons.people_outline,
                    title: 'No recipients yet',
                    message: 'Add a recipient first',
                    action: ElevatedButton(
                      onPressed: () => context.push(AppRoutes.addRecipient),
                      child: const Text('Add Recipient'),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: recipients.length,
                  itemBuilder: (context, index) {
                    final recipient = recipients[index];
                    final isSelected = draft.recipient?.id == recipient.id;
                    
                    return Card(
                      color: isSelected ? AppTheme.lavender : Colors.white,
                      child: InkWell(
                        onTap: () {
                          ref.read(draftCapsuleProvider.notifier).state =
                              draft.copyWith(recipient: recipient);
                        },
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spacingMd),
                          child: Row(
                            children: [
                              UserAvatar(
                                name: recipient.name,
                                imageUrl: recipient.avatarUrl,
                                imagePath: recipient.localAvatarPath,
                                size: 48,
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
                                    Text(
                                      recipient.displayRelationship,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppTheme.deepPurple,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const ErrorDisplay(message: 'Failed to load recipients'),
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingLg),
          
          GradientButton(
            text: 'Continue',
            onPressed: draft.recipient != null ? onNext : null,
          ),
        ],
      ),
    );
  }
}

// Step 2: Write Letter
class _WriteLetterStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _WriteLetterStep({
    required this.onNext,
    required this.onBack,
  });

  @override
  ConsumerState<_WriteLetterStep> createState() => _WriteLetterStepState();
}

class _WriteLetterStepState extends ConsumerState<_WriteLetterStep> {
  final _textController = TextEditingController();
  final _labelController = TextEditingController();
  static const int maxLength = 1000;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(draftCapsuleProvider);
    _textController.text = draft.letterText;
    _labelController.text = draft.label;
  }

  @override
  void dispose() {
    _textController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(draftCapsuleProvider);
    final remainingChars = maxLength - _textController.text.length;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Write your letter',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Pour your heart out to ${draft.recipient?.name ?? 'them'}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spacingXl),
          
          // Label field
          TextFormField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Label',
              hintText: 'e.g., Open on your birthday 🎂',
            ),
            onChanged: (value) {
              ref.read(draftCapsuleProvider.notifier).state =
                  draft.copyWith(label: value);
            },
          ),
          
          const SizedBox(height: AppTheme.spacingLg),
          
          // Letter text
          Expanded(
            child: TextFormField(
              controller: _textController,
              maxLines: null,
              maxLength: maxLength,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: 'Write from the heart...',
                alignLabelWithHint: true,
              ),
              onChanged: (value) {
                ref.read(draftCapsuleProvider.notifier).state =
                    draft.copyWith(letterText: value);
              },
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingSm),
          
          Text(
            '$remainingChars characters remaining',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: remainingChars < 100 ? AppTheme.errorRed : AppTheme.textGrey,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingLg),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                flex: 2,
                child: GradientButton(
                  text: 'Continue',
                  onPressed: _textController.text.trim().isNotEmpty && 
                      _labelController.text.trim().isNotEmpty
                      ? widget.onNext
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Continuing in next file...
