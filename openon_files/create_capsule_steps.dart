// Continuation of create_capsule_screen.dart
// This file contains the remaining steps: Add Photo, Choose DateTime, and Preview

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/providers/providers.dart';
import 'create_capsule_screen.dart';

// Step 3: Add Photo (Optional)
class _AddPhotoStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _AddPhotoStep({
    required this.onNext,
    required this.onBack,
  });

  @override
  ConsumerState<_AddPhotoStep> createState() => _AddPhotoStepState();
}

class _AddPhotoStepState extends ConsumerState<_AddPhotoStep> {
  final _imagePicker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        final draft = ref.read(draftCapsuleProvider);
        ref.read(draftCapsuleProvider.notifier).state =
            draft.copyWith(photo: image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _removePhoto() {
    final draft = ref.read(draftCapsuleProvider);
    ref.read(draftCapsuleProvider.notifier).state =
        draft.copyWith(clearPhoto: true);
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(draftCapsuleProvider);

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add a photo (optional)',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Make your letter even more special with a photo',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spacingXl),
          
          Expanded(
            child: Center(
              child: draft.photo != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            child: Image.file(
                              File(draft.photo!.path),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingLg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.swap_horiz),
                              label: const Text('Change Photo'),
                            ),
                            const SizedBox(width: AppTheme.spacingMd),
                            OutlinedButton.icon(
                              onPressed: _removePhoto,
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Remove'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.errorRed,
                                side: const BorderSide(color: AppTheme.errorRed),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppTheme.spacingXxl),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppTheme.lavender,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacingLg),
                              decoration: BoxDecoration(
                                color: AppTheme.lavender.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 48,
                                color: AppTheme.deepPurple,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingLg),
                            Text(
                              'Tap to add a photo',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppTheme.spacingSm),
                            Text(
                              'Add a meaningful image to your letter',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
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
                  text: draft.photo != null ? 'Continue' : 'Skip',
                  onPressed: widget.onNext,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Step 4: Choose Date & Time
class _ChooseDateTimeStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _ChooseDateTimeStep({
    required this.onNext,
    required this.onBack,
  });

  @override
  ConsumerState<_ChooseDateTimeStep> createState() => _ChooseDateTimeStepState();
}

class _ChooseDateTimeStepState extends ConsumerState<_ChooseDateTimeStep> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(draftCapsuleProvider);
    if (draft.unlockTime != null) {
      _selectedDate = DateTime(
        draft.unlockTime!.year,
        draft.unlockTime!.month,
        draft.unlockTime!.day,
      );
      _selectedTime = TimeOfDay.fromDateTime(draft.unlockTime!);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = now.add(const Duration(minutes: 1));
    final lastDate = now.add(const Duration(days: 365 * 10));

    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.deepPurple,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() => _selectedDate = date);
      _updateDraft();
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.deepPurple,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() => _selectedTime = time);
      _updateDraft();
    }
  }

  void _updateDraft() {
    if (_selectedDate != null && _selectedTime != null) {
      final unlockTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final draft = ref.read(draftCapsuleProvider);
      ref.read(draftCapsuleProvider.notifier).state =
          draft.copyWith(unlockTime: unlockTime);
    }
  }

  bool get _isValid {
    if (_selectedDate == null || _selectedTime == null) return false;
    
    final unlockTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    return unlockTime.isAfter(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(draftCapsuleProvider);
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'When should it unlock?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Choose the perfect moment for ${draft.recipient?.name ?? 'them'} to receive your letter',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spacingXl),
          
          // Date Picker
          Card(
            child: InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        gradient: AppTheme.dreamyGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppTheme.spacingXs),
                          Text(
                            _selectedDate != null
                                ? dateFormat.format(_selectedDate!)
                                : 'Choose a date',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingMd),
          
          // Time Picker
          Card(
            child: InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        gradient: AppTheme.dreamyGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: const Icon(
                        Icons.access_time,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppTheme.spacingXs),
                          Text(
                            _selectedTime != null
                                ? _selectedTime!.format(context)
                                : 'Choose a time',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
          
          if (draft.unlockTime != null) ...[
            const SizedBox(height: AppTheme.spacingXl),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                gradient: AppTheme.warmGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_clock, color: Colors.white),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Will unlock on',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXs),
                        Text(
                          '${dateFormat.format(draft.unlockTime!)} at ${timeFormat.format(draft.unlockTime!)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const Spacer(),
          
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
                  onPressed: _isValid ? widget.onNext : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Step 5: Preview & Confirm
class _PreviewStep extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const _PreviewStep({required this.onBack});

  @override
  ConsumerState<_PreviewStep> createState() => _PreviewStepState();
}

class _PreviewStepState extends ConsumerState<_PreviewStep> {
  bool _isCreating = false;

  Future<void> _createCapsule() async {
    final draft = ref.read(draftCapsuleProvider);
    
    if (!draft.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final repo = ref.read(capsuleRepositoryProvider);
      await repo.createCapsule(
        recipientId: draft.recipient!.id,
        recipientName: draft.recipient!.name,
        letterText: draft.letterText,
        unlockTime: draft.unlockTime!,
        label: draft.label,
        photoPath: draft.photo?.path,
      );

      if (mounted) {
        // Invalidate capsules to refresh
        ref.invalidate(capsulesProvider);
        ref.invalidate(sentCapsulesProvider);
        
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Letter created successfully! ♥'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create letter: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(draftCapsuleProvider);
    final dateFormat = DateFormat('MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview your letter',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Everything looks good? Let\'s send it!',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spacingXl),
          
          Expanded(
            child: SingleChildScrollView(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Envelope Visual
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(AppTheme.spacingXl),
                          decoration: BoxDecoration(
                            gradient: AppTheme.warmGradient,
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.mail,
                                size: 64,
                                color: Colors.white,
                              ),
                              const SizedBox(height: AppTheme.spacingMd),
                              Text(
                                draft.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: AppTheme.spacingXl),
                      
                      // Details
                      _DetailRow(
                        icon: Icons.person,
                        label: 'To',
                        value: draft.recipient?.name ?? '',
                      ),
                      const Divider(height: AppTheme.spacingLg),
                      
                      _DetailRow(
                        icon: Icons.lock_clock,
                        label: 'Unlocks',
                        value: draft.unlockTime != null
                            ? '${dateFormat.format(draft.unlockTime!)} at ${timeFormat.format(draft.unlockTime!)}'
                            : '',
                      ),
                      const Divider(height: AppTheme.spacingLg),
                      
                      _DetailRow(
                        icon: Icons.message,
                        label: 'Letter',
                        value: '${draft.letterText.length} characters',
                      ),
                      
                      if (draft.photo != null) ...[
                        const Divider(height: AppTheme.spacingLg),
                        _DetailRow(
                          icon: Icons.image,
                          label: 'Photo',
                          value: 'Attached',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
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
                  text: '✉️  Send Letter',
                  onPressed: _createCapsule,
                  isLoading: _isCreating,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.deepPurple),
        const SizedBox(width: AppTheme.spacingMd),
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textGrey,
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
