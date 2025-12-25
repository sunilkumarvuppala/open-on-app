import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/constants/app_constants.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/utils/logger.dart';

/// Letter Reply Composer Widget
/// 
/// Allows receiver to compose a one-time reply to a letter.
/// - Single-line text input (max 60 characters)
/// - Emoji selection from fixed set
/// - Skip and Send buttons
class LetterReplyComposer extends ConsumerStatefulWidget {
  final String letterId;
  final VoidCallback? onReplySent;
  final VoidCallback? onSkip;
  
  const LetterReplyComposer({
    super.key,
    required this.letterId,
    this.onReplySent,
    this.onSkip,
  });
  
  @override
  ConsumerState<LetterReplyComposer> createState() => _LetterReplyComposerState();
}

class _LetterReplyComposerState extends ConsumerState<LetterReplyComposer> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _emojiScrollController = ScrollController();
  String? _selectedEmoji;
  bool _isSending = false;
  bool _replyAlreadyExists = false;
  bool _canScrollLeft = false;
  bool _canScrollRight = true; // Assume we can scroll right initially
  
  @override
  void initState() {
    super.initState();
    // Check if reply exists after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfReplyExists();
      _updateScrollButtons();
    });
    
    // Listen to scroll changes to update arrow visibility
    _emojiScrollController.addListener(_updateScrollButtons);
  }
  
  @override
  void dispose() {
    _textController.dispose();
    _emojiScrollController.dispose();
    super.dispose();
  }
  
  void _updateScrollButtons() {
    if (!_emojiScrollController.hasClients) return;
    
    final position = _emojiScrollController.position;
    final canScrollLeft = position.pixels > 0;
    final canScrollRight = position.pixels < position.maxScrollExtent;
    
    if (mounted && (canScrollLeft != _canScrollLeft || canScrollRight != _canScrollRight)) {
      setState(() {
        _canScrollLeft = canScrollLeft;
        _canScrollRight = canScrollRight;
      });
    }
  }
  
  Future<void> _checkIfReplyExists() async {
    if (!mounted) return;
    
    try {
      final repo = ref.read(letterReplyRepositoryProvider);
      final existingReply = await repo.getReplyByLetterId(widget.letterId);
      if (existingReply != null && mounted) {
        setState(() {
          _replyAlreadyExists = true;
        });
      }
    } catch (e) {
      // Silently fail - if check fails, we'll rely on backend validation
      Logger.error('Failed to check if reply exists', error: e);
    }
  }
  
  bool get _canSend {
    return !_replyAlreadyExists &&
           _textController.text.trim().isNotEmpty &&
           _selectedEmoji != null &&
           !_isSending;
  }
  
  void _handleEmojiSelect(String emoji) {
    setState(() {
      _selectedEmoji = emoji;
    });
  }
  
  Future<void> _handleSend() async {
    if (!_canSend) return;
    
    setState(() {
      _isSending = true;
    });
    
    try {
      final repo = ref.read(letterReplyRepositoryProvider);
      final replyText = _textController.text.trim();
      
      await repo.createReply(
        widget.letterId,
        replyText,
        _selectedEmoji!,
      );
      
      Logger.info('Reply sent successfully for letter ${widget.letterId}');
      
      if (mounted) {
        // Callback to reload reply and close composer window
        // No animation for receiver - reply window will close automatically
        widget.onReplySent?.call();
      }
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to send reply',
        error: e,
        stackTrace: stackTrace,
      );
      
      if (mounted) {
        final colorScheme = ref.read(selectedColorSchemeProvider);
        
        // Check if error is due to reply already existing
        final errorMessage = e.toString().toLowerCase();
        final isAlreadyExists = errorMessage.contains('already exists') ||
                                errorMessage.contains('duplicate') ||
                                errorMessage.contains('unique');
        
        if (isAlreadyExists) {
          setState(() {
            _replyAlreadyExists = true;
          });
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAlreadyExists
                  ? 'You have already sent a reply to this letter.'
                  : 'Failed to send reply. Please try again.',
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
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }
  
  void _handleSkip() {
    // Notify parent that reply was skipped
    widget.onSkip?.call();
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final theme = Theme.of(context);
    
    // If reply already exists, don't show the composer
    if (_replyAlreadyExists) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: DynamicTheme.getCardBackgroundColor(colorScheme),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: DynamicTheme.getDividerColor(colorScheme).withOpacity(AppConstants.letterReplyDividerOpacity),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            'Would you like to leave a short reply?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: DynamicTheme.getPrimaryTextColor(colorScheme),
            ),
          ),
          
          SizedBox(height: AppTheme.spacingXs),
          
          // Subtext
          Text(
            'One line. One feeling. Optional.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(AppConstants.letterReplySecondaryTextOpacity),
            ),
          ),
          
          SizedBox(height: AppTheme.spacingLg),
          
          // Text input
          TextField(
            controller: _textController,
            maxLength: 60,
            maxLines: 1,
            enabled: !_isSending,
            decoration: InputDecoration(
              hintText: 'Just a few words…',
              hintStyle: TextStyle(
                color: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(AppConstants.letterReplyHintTextOpacity),
              ),
              filled: true,
              fillColor: DynamicTheme.getCardBackgroundColor(colorScheme),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide(
                  color: DynamicTheme.getDividerColor(colorScheme),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide(
                  color: DynamicTheme.getDividerColor(colorScheme),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide(
                  color: colorScheme.primary1,
                  width: 2,
                ),
              ),
              counterText: '',
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: DynamicTheme.getPrimaryTextColor(colorScheme),
            ),
            onChanged: (_) => setState(() {}),
            inputFormatters: [
              LengthLimitingTextInputFormatter(60),
            ],
          ),
          
          SizedBox(height: AppTheme.spacingSm), // Reduced gap between text box and emojis
          
          // Emoji row with scroll arrows (horizontally scrollable)
          Stack(
            children: [
              SizedBox(
                height: AppConstants.letterReplyEmojiRowHeight,
                child: ListView.separated(
                  controller: _emojiScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.only(
                    left: 0, // Start from left edge
                    right: AppTheme.spacingMd, // Keep right padding
                  ),
                  itemCount: LetterReply.allowedEmojis.length,
                  separatorBuilder: (context, index) => SizedBox(width: AppConstants.letterReplyEmojiSpacing),
                  itemBuilder: (context, index) {
                    final emoji = LetterReply.allowedEmojis[index];
                    final isSelected = _selectedEmoji == emoji;
                    return GestureDetector(
                      onTap: _isSending ? null : () => _handleEmojiSelect(emoji),
                      child: AnimatedContainer(
                        duration: AppConstants.letterReplyEmojiAnimationDuration,
                        width: AppConstants.letterReplyEmojiContainerSize,
                        height: AppConstants.letterReplyEmojiContainerSize,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary1.withOpacity(AppConstants.letterReplyEmojiSelectedOpacity)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary1
                                : Colors.transparent,
                            width: AppConstants.letterReplyBorderWidth,
                          ),
                        ),
                        child: Center(
                          child: Opacity(
                            opacity: _isSending ? AppConstants.letterReplyEmojiDisabledOpacity : AppConstants.opacityFull,
                            child: Text(
                              emoji,
                              style: const TextStyle(
                                fontSize: AppConstants.letterReplyEmojiSize,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Left arrow indicator
              if (_canScrollLeft)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: AppConstants.letterReplyArrowGradientWidth,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          DynamicTheme.getCardBackgroundColor(colorScheme),
                          DynamicTheme.getCardBackgroundColor(colorScheme).withOpacity(AppConstants.opacityTransparent),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.chevron_left,
                        color: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(AppConstants.opacityFull),
                        size: AppConstants.letterReplyArrowIconSize,
                      ),
                    ),
                  ),
                ),
              // Right arrow indicator
              if (_canScrollRight)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: AppConstants.letterReplyArrowGradientWidth,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          DynamicTheme.getCardBackgroundColor(colorScheme).withOpacity(AppConstants.opacityTransparent),
                          DynamicTheme.getCardBackgroundColor(colorScheme),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.chevron_right,
                        color: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(AppConstants.opacityFull),
                        size: AppConstants.letterReplyArrowIconSize,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          SizedBox(height: AppTheme.spacingMd), // Reduced gap between emojis and buttons
          
          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Skip button
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSending ? null : _handleSkip,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                    side: BorderSide(
                      color: DynamicTheme.getDividerColor(colorScheme),
                    ),
                  ),
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: DynamicTheme.getSecondaryTextColor(colorScheme),
                    ),
                  ),
                ),
              ),
              
              SizedBox(width: AppTheme.spacingMd),
              
              // Send button
              Expanded(
                child: FilledButton(
                  onPressed: _canSend ? _handleSend : null,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                    backgroundColor: colorScheme.primary1,
                    disabledBackgroundColor: DynamicTheme.getDividerColor(colorScheme).withOpacity(AppConstants.letterReplyDisabledBackgroundOpacity),
                  ),
                  child: _isSending
                      ? SizedBox(
                          width: AppConstants.letterReplyLoadingIndicatorSize,
                          height: AppConstants.letterReplyLoadingIndicatorSize,
                          child: CircularProgressIndicator(
                            strokeWidth: AppConstants.letterReplyBorderWidth,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Send',
                          style: TextStyle(
                            color: _canSend ? Colors.white : DynamicTheme.getSecondaryTextColor(colorScheme),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

