import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/utils/logger.dart';

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
  Timer? _debounceTimer;
  String? _currentDraftId;
  bool _isSaving = false; // Lock to prevent concurrent saves
  static const Duration _debounceDuration = Duration(milliseconds: 800);
  
  @override
  void initState() {
    super.initState();
    final draft = ref.read(draftCapsuleProvider);
    _contentController.text = draft.content ?? '';
    _labelController.text = draft.label ?? '';
    
    // CRITICAL: Initialize _currentDraftId from draftCapsuleProvider
    // This ensures that when opening an existing draft, we update it instead of creating a new one
    _currentDraftId = draft.draftId;
    if (_currentDraftId != null) {
      Logger.debug('StepWriteLetter: Initialized with existing draft ID: $_currentDraftId');
    }
    
    // Auto-save on text changes
    _contentController.addListener(_onContentChanged);
    _labelController.addListener(_onLabelChanged);
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    _contentController.removeListener(_onContentChanged);
    _labelController.removeListener(_onLabelChanged);
    _contentController.dispose();
    _labelController.dispose();
    super.dispose();
  }
  
  void _onContentChanged() {
    // Update draft capsule state immediately
    ref.read(draftCapsuleProvider.notifier).setContent(_contentController.text);
    
    // Auto-save to draft repository (debounced)
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _saveDraft();
    });
  }
  
  void _onLabelChanged() {
    // Update draft capsule state immediately
    ref.read(draftCapsuleProvider.notifier).setLabel(_labelController.text);
  }
  
  Future<void> _saveDraft() async {
    // Prevent concurrent saves (race condition protection)
    if (_isSaving) {
      Logger.debug('Save already in progress, skipping duplicate save');
      return;
    }
    
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      return; // Don't save empty drafts
    }
    
    _isSaving = true;
    try {
      final userAsync = ref.read(currentUserProvider);
      final user = userAsync.asData?.value;
      if (user == null) {
        _isSaving = false;
        return;
      }
      
      final repo = ref.read(draftRepositoryProvider);
      final draftCapsule = ref.read(draftCapsuleProvider);
      
      // CRITICAL: Check both _currentDraftId and draftCapsule.draftId
      // This ensures we use the correct draft ID even if _currentDraftId wasn't initialized
      // (e.g., if draftId was set in CreateCapsuleScreen after StepWriteLetter initState)
      final draftId = _currentDraftId ?? draftCapsule.draftId;
      
      if (draftId == null) {
        // Create new draft - no need to check for duplicates on every auto-save
        // This is much more performant than loading all drafts each time
        final draft = await repo.createDraft(
          userId: user.id,
          title: draftCapsule.label,
          content: content,
          recipientName: draftCapsule.recipient?.name,
          recipientAvatar: draftCapsule.recipient?.avatar,
        );
        // Set draft ID immediately after creation to prevent race conditions
        _currentDraftId = draft.id;
        
        // Store in DraftCapsule so CreateCapsuleScreen knows about it
        ref.read(draftCapsuleProvider.notifier).setDraftId(_currentDraftId!);
        
        Logger.debug('Draft created from letter screen: ${draft.id}');
        
        // Only invalidate on creation (not on every update) to reduce unnecessary refreshes
        // Updates happen frequently during typing, so we avoid invalidating on every update
        ref.invalidate(draftsProvider(user.id));
      } else {
        // Update existing draft
        // Use the draftId we found (either from _currentDraftId or draftCapsule.draftId)
        await repo.updateDraft(
          draftId,
          content,
          title: draftCapsule.label,
          recipientName: draftCapsule.recipient?.name,
          recipientAvatar: draftCapsule.recipient?.avatar,
        );
        
        // Ensure both _currentDraftId and DraftCapsule have the draft ID
        _currentDraftId = draftId;
        ref.read(draftCapsuleProvider.notifier).setDraftId(draftId);
        
        Logger.debug('Draft updated from letter screen: $draftId');
        
        // Don't invalidate on every update - this causes unnecessary list refreshes
        // The draft list will refresh when user navigates to drafts screen
      }
    } catch (e) {
      Logger.error('Failed to auto-save draft from letter screen', error: e);
      // Silently fail - don't interrupt user's writing
    } finally {
      _isSaving = false;
    }
  }
  
  Future<void> _saveDraftImmediately() async {
    _debounceTimer?.cancel();
    await _saveDraft();
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
  
  Future<void> _saveAndContinue() async {
    // Save immediately before continuing
    await _saveDraftImmediately();
    
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
    
    // Keep _currentDraftId in sync with draftCapsuleProvider
    // This handles cases where draftId is set after initState (e.g., from CreateCapsuleScreen)
    if (draft.draftId != null && draft.draftId != _currentDraftId) {
      _currentDraftId = draft.draftId;
      Logger.debug('StepWriteLetter: Synced _currentDraftId from provider: $_currentDraftId');
    }
    
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
                    foregroundColor: DynamicTheme.getButtonTextColor(colorScheme),
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
