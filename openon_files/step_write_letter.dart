import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/app_theme.dart';

class StepWriteLetter extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  
  const StepWriteLetter({
    super.key,
    required this.onNext,
    required this.onBack,
  });
  
  @override
  ConsumerState<StepWriteLetter> createState() => _StepWriteLetterState();
}

class _StepWriteLetterState extends ConsumerState<StepWriteLetter> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();
  final int _maxCharacters = 1000;
  final ImagePicker _picker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    final draft = ref.read(draftCapsuleProvider);
    _contentController.text = draft.content ?? '';
    _labelController.text = draft.label ?? '';
  }
  
  @override
  void dispose() {
    _contentController.dispose();
    _labelController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        ref.read(draftCapsuleProvider.notifier).setPhoto(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to pick image'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  void _removePhoto() {
    ref.read(draftCapsuleProvider.notifier).setPhoto(null);
  }
  
  void _saveAndContinue() {
    ref.read(draftCapsuleProvider.notifier).setContent(_contentController.text);
    ref.read(draftCapsuleProvider.notifier).setLabel(_labelController.text);
    widget.onNext();
  }
  
  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(draftCapsuleProvider);
    final recipient = draft.recipient;
    final photoPath = draft.photoPath;
    final characterCount = _contentController.text.length;
    final isValid = _contentController.text.trim().isNotEmpty;
    
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Write your letter to ${recipient?.name ?? "them"}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share what\'s in your heart ♥',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.gray,
                      ),
                ),
                const SizedBox(height: 32),
                
                // Label/title field
                TextField(
                  controller: _labelController,
                  decoration: const InputDecoration(
                    labelText: 'Letter Title (optional)',
                    hintText: 'e.g., "Open on your birthday 🎂"',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                
                const SizedBox(height: 24),
                
                // Letter content field
                TextField(
                  controller: _contentController,
                  maxLines: null,
                  minLines: 10,
                  maxLength: _maxCharacters,
                  decoration: InputDecoration(
                    labelText: 'Your Letter *',
                    hintText: 'Write from the heart...',
                    alignLabelWithHint: true,
                    counterText: '$characterCount / $_maxCharacters',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) {
                    setState(() {}); // Update character count
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Photo section
                if (photoPath != null) ...[
                  Row(
                    children: [
                      Text(
                        'Attached Photo',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _removePhoto,
                        icon: const Icon(Icons.delete_outline, size: 20),
                        label: const Text('Remove'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(photoPath),
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Add Photo (Optional)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.lightGray),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // AI assist button (stubbed)
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement AI writing assistance
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('AI writing assistance coming soon'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Improve with AI'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppColors.deepPurple.withOpacity(0.3)),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Navigation buttons
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: isValid ? _saveAndContinue : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
