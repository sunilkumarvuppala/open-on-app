import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';

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
          SnackBar(
            content: const Text('Failed to pick image'),
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
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    
    // Theme-aware text colors
    final titleColor = DynamicTheme.getPrimaryTextColor(colorScheme);
    final bodyColor = DynamicTheme.getSecondaryTextColor(colorScheme);
    
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Write your letter to ${recipient?.name ?? "them"}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                ),
                SizedBox(height: AppTheme.spacingSm),
                Text(
                  'Share what\'s in your heart ♥',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: bodyColor,
                      ),
                ),
                SizedBox(height: AppTheme.spacingXl),
                
                // Label/title field
                TextField(
                  controller: _labelController,
                  style: TextStyle(
                    color: DynamicTheme.getInputTextColor(colorScheme),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Letter Title (optional)',
                    hintText: 'e.g., "Open on your birthday 🎂"',
                    prefixIcon: Icon(
                      Icons.label_outline,
                      color: DynamicTheme.getInputHintColor(colorScheme),
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                
                SizedBox(height: AppTheme.spacingLg),
                
                // Letter content field
                TextField(
                  controller: _contentController,
                  maxLines: null,
                  minLines: 10,
                  maxLength: _maxCharacters,
                  style: TextStyle(
                    color: DynamicTheme.getInputTextColor(colorScheme),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Your Letter *',
                    hintText: 'Write from the heart...',
                    alignLabelWithHint: true,
                    counterText: '$characterCount / $_maxCharacters',
                    counterStyle: TextStyle(
                      color: DynamicTheme.getSecondaryTextColor(colorScheme),
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) {
                    setState(() {}); // Update character count
                  },
                ),
                
                SizedBox(height: AppTheme.spacingLg),
                
                // Photo section
                if (photoPath != null) ...[
                  Row(
                    children: [
                      Text(
                        'Attached Photo',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: DynamicTheme.getInputTextColor(colorScheme),
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
                  SizedBox(height: AppTheme.spacingSm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: Image.file(
                      File(photoPath),
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingMd),
                ] else ...[
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(
                      Icons.add_photo_alternate_outlined,
                      color: DynamicTheme.getOutlinedButtonTextColor(colorScheme),
                    ),
                    label: Text(
                      'Add Photo (Optional)',
                      style: TextStyle(
                        color: DynamicTheme.getOutlinedButtonTextColor(colorScheme),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                      side: BorderSide(
                        color: DynamicTheme.getOutlinedButtonBorderColor(colorScheme),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      ),
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingMd),
                ],
                
                // AI assist button (stubbed)
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement AI writing assistance
                    final colorScheme = ref.read(selectedColorSchemeProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'AI writing assistance coming soon',
                          style: TextStyle(
                            color: DynamicTheme.getSnackBarTextColor(colorScheme),
                          ),
                        ),
                        backgroundColor: DynamicTheme.getSnackBarBackgroundColor(colorScheme),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.auto_awesome,
                    color: DynamicTheme.getButtonTextColor(colorScheme),
                  ),
                  label: Text(
                    'Improve with AI',
                    style: TextStyle(
                      color: DynamicTheme.getButtonTextColor(colorScheme),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                    side: BorderSide(
                        color: DynamicTheme.getButtonBorderColor(colorScheme),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Navigation buttons
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
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                    side: BorderSide(
                      color: DynamicTheme.getOutlinedButtonBorderColor(colorScheme),
                    ),
                    foregroundColor: DynamicTheme.getOutlinedButtonTextColor(colorScheme),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                  ),
                  child: const Text('Back'),
                ),
              ),
              SizedBox(width: AppTheme.spacingMd),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: isValid ? _saveAndContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary1,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                    side: DynamicTheme.getButtonBorderSide(colorScheme),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
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
