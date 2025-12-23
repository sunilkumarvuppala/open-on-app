import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:openon_app/core/widgets/common_widgets.dart';

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
  
  void _showTimeLockedInfo() {
    final colorScheme = ref.read(selectedColorSchemeProvider);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: DynamicTheme.getCardBackgroundColor(colorScheme),
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
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Time-Locked Letters',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: DynamicTheme.getPrimaryTextColor(colorScheme),
                          ),
                    ),
                    SizedBox(height: AppTheme.spacingMd),
                    Text(
                      'They won\'t see this until you choose a time.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: DynamicTheme.getSecondaryTextColor(colorScheme),
                            height: 1.5,
                          ),
                    ),
                    SizedBox(height: AppTheme.spacingSm),
                    Text(
                      'You\'ll set the unlock date and time in the next step. Until then, your letter stays sealed and private.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(0.8),
                            height: 1.5,
                          ),
                    ),
                    SizedBox(height: AppTheme.spacingLg),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                        ),
                        child: Text(
                          'Got it',
                          style: TextStyle(
                            color: DynamicTheme.getPrimaryTextColor(colorScheme),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
            padding: EdgeInsets.only(
              left: AppTheme.spacingLg,
              right: AppTheme.spacingLg,
              top: AppTheme.spacingMd, // Reduced top padding to bring closer to progress bar
              bottom: AppTheme.spacingLg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recipient pill - reinforces who this is for
                if (recipient != null)
                  InkWell(
                    onTap: _showTimeLockedInfo,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd,
                        vertical: AppTheme.spacingSm,
                      ),
                      decoration: BoxDecoration(
                        color: DynamicTheme.getCardBackgroundColor(colorScheme),
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        border: Border.all(
                          color: DynamicTheme.getButtonBorderColor(colorScheme).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          UserAvatar(
                            name: recipient.name,
                            imageUrl: recipient.avatar.isNotEmpty ? recipient.avatar : null,
                            size: 24, // Smaller avatar for pill
                          ),
                          SizedBox(width: AppTheme.spacingSm),
                          Flexible(
                            child: Text(
                              '${recipient.name} - Will receive this letter',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: DynamicTheme.getSecondaryTextColor(colorScheme),
                                    fontSize: 13,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: AppTheme.spacingXs),
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(0.6),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Text(
                    'Write to them',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                  ),
                SizedBox(height: AppTheme.spacingXs),
                Text(
                  'This will open when the time is right.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: bodyColor,
                      ),
                ),
                SizedBox(height: AppTheme.spacingSm),
                
                // Letter content field - Canvas feel, not a text field
                Container(
                  decoration: BoxDecoration(
                    // Subtle gradient for paper-like texture - reduced brightness
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        DynamicTheme.getCardBackgroundColor(colorScheme, opacity: AppTheme.opacityLow), // Reduced brightness
                        DynamicTheme.getCardBackgroundColor(colorScheme, opacity: AppTheme.opacityLow).withOpacity(0.7), // Reduced bottom-right brightness
                      ],
                      stops: const [0.0, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(
                      color: DynamicTheme.getButtonBorderColor(colorScheme).withOpacity(0.1), // Further reduced contrast
                      width: 1, // Thinner border
                    ),
                    // Very subtle shadow for depth without boxiness
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.isDarkTheme
                            ? Colors.black.withOpacity(0.1)
                            : Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias, // Ensure background fills to border
                  child: TextField(
                    controller: _contentController,
                    maxLines: null,
                    minLines: 14, // Expanded height for more writing space
                    maxLength: _maxCharacters,
                    style: TextStyle(
                      color: DynamicTheme.getInputTextColor(colorScheme),
                      fontSize: 16,
                      height: 1.6, // Slightly more line spacing for readability
                    ),
                    decoration: InputDecoration(
                      hintText: 'Write from your heart…',
                      hintStyle: TextStyle(
                        color: DynamicTheme.getInputHintColor(colorScheme).withOpacity(0.6),
                        fontSize: 16,
                        height: 1.6,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: true, // Fill the background
                      fillColor: Colors.transparent, // Use container's background color
                      contentPadding: const EdgeInsets.all(AppTheme.spacingLg), // Increased inner padding
                      counterText: '',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (value) {
                      setState(() {}); // Update character count
                    },
                  ),
                ),
                // Character count and supportive hint - subtle, below body field
                Padding(
                  padding: const EdgeInsets.only(top: AppTheme.spacingXs, left: AppTheme.spacingMd, right: AppTheme.spacingMd),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Supportive hint
                      Expanded(
                        child: Text(
                          'You can always edit before sealing.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(0.6),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ),
                      // Character count
                      Text(
                        '$characterCount / $_maxCharacters',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(0.6),
                              fontSize: 12,
                            ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: AppTheme.spacingMd),
                
                // Photo section (when photo is attached)
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
                  SizedBox(height: AppTheme.spacingLg),
                ],
                
                // Title field - DEMOTED, smaller, lighter
                TextField(
                  controller: _labelController,
                  style: TextStyle(
                    color: DynamicTheme.getInputTextColor(colorScheme),
                    fontSize: 14, // Smaller text
                  ),
                  decoration: InputDecoration(
                    labelText: 'Add a title (optional, but better)',
                    labelStyle: TextStyle(
                      color: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(0.7), // Lighter label
                      fontSize: 13,
                    ),
                    hintText: 'e.g., "Open on your birthday 🎂"',
                    hintStyle: TextStyle(
                      color: DynamicTheme.getInputHintColor(colorScheme).withOpacity(0.5),
                      fontSize: 14,
                    ),
                    isDense: true, // More compact
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                      vertical: AppTheme.spacingSm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide(
                        color: DynamicTheme.getButtonBorderColor(colorScheme).withOpacity(0.2), // Lighter border
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide(
                        color: DynamicTheme.getButtonBorderColor(colorScheme).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide(
                        color: DynamicTheme.getButtonBorderColor(colorScheme).withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                
                SizedBox(height: AppTheme.spacingLg),
                
                // Add Photo - at the very bottom
                if (photoPath == null) ...[
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 18, // Smaller icon
                      color: DynamicTheme.getOutlinedButtonTextColor(colorScheme),
                    ),
                    label: Text(
                      'Add Photo (Optional)',
                      style: TextStyle(
                        fontSize: 14, // Smaller text
                        color: DynamicTheme.getOutlinedButtonTextColor(colorScheme),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd,
                        vertical: AppTheme.spacingSm, // Smaller padding
                      ),
                      side: BorderSide(
                        color: DynamicTheme.getOutlinedButtonBorderColor(colorScheme).withOpacity(0.5),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        // Navigation buttons
        Container(
          padding: EdgeInsets.only(
            left: AppTheme.spacingLg,
            right: AppTheme.spacingLg,
            top: AppTheme.spacingSm,
            bottom: AppTheme.spacingMd,
          ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Micro-feedback hint - fades out when text appears
              AnimatedOpacity(
                opacity: isValid ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
                  child: Text(
                    'Write a few words to continue.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(0.6),
                          fontSize: 12,
                        ),
                  ),
                ),
              ),
              Row(
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
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: ElevatedButton(
                        onPressed: isValid ? _saveAndContinue : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary1,
                          foregroundColor: DynamicTheme.getButtonTextColor(colorScheme),
                          padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                          side: DynamicTheme.getButtonBorderSide(colorScheme),
                          elevation: isValid ? 3.0 : 1.0, // Subtly brighter elevation when enabled
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          ),
                        ),
                        child: const Text('Continue'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
