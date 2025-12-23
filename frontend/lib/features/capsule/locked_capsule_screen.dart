import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/theme/app_text_styles.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:openon_app/core/utils/error_handler.dart';
import 'package:openon_app/core/widgets/common_widgets.dart';
import 'package:openon_app/core/constants/app_constants.dart';
import 'package:intl/intl.dart';

class LockedCapsuleScreen extends ConsumerStatefulWidget {
  final Capsule capsule;
  
  const LockedCapsuleScreen({super.key, required this.capsule});
  
  @override
  ConsumerState<LockedCapsuleScreen> createState() => _LockedCapsuleScreenState();
}

class _LockedCapsuleScreenState extends ConsumerState<LockedCapsuleScreen>
    with TickerProviderStateMixin {
  Timer? _countdownTimer;
  Timer? _emojiTimer;
  late Capsule _capsule;
  bool _isWithdrawing = false; // Prevent double-withdrawal
  bool _isRefreshing = false; // Prevent concurrent refreshes
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  late AnimationController _circlePulseController;
  late Animation<double> _circleSizeAnimation;
  late Animation<double> _lockHaloAnimation;
  late AnimationController _emojiAnimationController;
  late Animation<double> _emojiPositionAnimation;
  String? _currentEmoji;
  final Random _random = Random();
  static const List<String> _emojis = ['💌', '✨', '🤍'];
  
  @override
  void initState() {
    super.initState();
    _capsule = widget.capsule;
    
    // Breathing animation for lock icon - very slow, subtle pulse (6s cycle)
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6), // Slow breathing cycle
    )..repeat(reverse: true);
    
    // Subtle opacity breathing: from 0.85 to 1.0 (very subtle)
    _breathingAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut, // Smooth, gentle curve for breathing effect
    ));
    
    // Circle pulse animation - grows from small to current size every second
    _circlePulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // 1 second cycle
    )..repeat(reverse: true);
    
    // Circle size animation: from min to max size
    _circleSizeAnimation = Tween<double>(
      begin: AppConstants.lockedCapsuleCircleSizeMin,
      end: AppConstants.lockedCapsuleCircleSizeMax,
    ).animate(CurvedAnimation(
      parent: _circlePulseController,
      curve: Curves.easeInOut, // Smooth pulse
    ));
    
    // Lock halo animation - syncs with circle pulse animation
    // Use the same controller as circle pulse for synchronized timing
    // Halo pulse: fades in and out very subtly following circle pulse
    _lockHaloAnimation = Tween<double>(
      begin: AppConstants.lockedCapsuleHaloOpacityMin,
      end: AppConstants.lockedCapsuleHaloOpacityMax,
    ).animate(CurvedAnimation(
      parent: _circlePulseController, // Use circle pulse controller for sync
      curve: Curves.easeInOut, // Smooth, gentle pulse - fades in and out
    ));
    
    // Emoji animation - moves from sender to receiver
    _emojiAnimationController = AnimationController(
      vsync: this,
      duration: AppConstants.lockedCapsuleEmojiAnimationDuration,
    );
    
    _emojiPositionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _emojiAnimationController,
      curve: Curves.easeOut, // Ease out for natural movement
    ));
    
    // Start emoji timer - trigger at configured interval
    _emojiTimer = Timer.periodic(AppConstants.lockedCapsuleEmojiTimerInterval, (_) {
      if (mounted && !_capsule.isOpened) {
        _triggerEmojiAnimation();
      }
    });
    
    // Trigger first emoji immediately
    _triggerEmojiAnimation();
    
    // Update countdown every second
    // Only update if capsule is still locked to save battery
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_capsule.isOpened && _capsule.timeUntilUnlock > Duration.zero) {
        setState(() {});
      } else if (mounted && (_capsule.isOpened || _capsule.timeUntilUnlock <= Duration.zero)) {
        // Stop timer if letter is opened or ready
        _countdownTimer?.cancel();
      }
    });
  }
  
  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emojiTimer?.cancel();
    _breathingController.dispose();
    _circlePulseController.dispose();
    _emojiAnimationController.dispose();
    super.dispose();
  }
  
  /// Trigger emoji animation - randomly select emoji and animate
  void _triggerEmojiAnimation() {
    if (!mounted) return;
    
    // Stop any ongoing animation first to prevent conflicts
    if (_emojiAnimationController.isAnimating) {
      _emojiAnimationController.stop();
    }
    
    // Randomly select an emoji
    _currentEmoji = _emojis[_random.nextInt(_emojis.length)];
    
    // Reset to beginning and start animation from scratch
    _emojiAnimationController.reset();
    
    // Start animation and handle completion
    _emojiAnimationController.forward().then((_) {
      // Clear emoji after animation completes
      if (mounted) {
        setState(() {
          _currentEmoji = null;
        });
      }
    }).catchError((error, stackTrace) {
      // Handle any errors gracefully with logging
      Logger.warning('Emoji animation error', error: error, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _currentEmoji = null;
        });
      }
    });
    
    setState(() {});
  }
  
  /// Calculate progress for countdown indicator (0.0 to 1.0)
  /// Returns 0.0 if calculation would be invalid (prevents division by zero)
  double _calculateProgress(Capsule capsule) {
    try {
      final totalDuration = capsule.unlockAt.difference(capsule.createdAt);
      if (totalDuration.inSeconds <= 0) {
        return 0.0;
      }
      final remaining = capsule.timeUntilUnlock.inSeconds;
      if (remaining < 0) {
        return 1.0;
      }
      final progress = 1.0 - (remaining / totalDuration.inSeconds);
      // Clamp between 0.0 and 1.0 for safety
      return progress.clamp(0.0, 1.0);
    } catch (e) {
      Logger.warning('Error calculating progress', error: e);
      return 0.0;
    }
  }
  
  /// Get formatted sender text: "A letter from {firstName}"
  /// Extracts first name from full name, or uses full name if it's "Anonymous"
  String _getSenderText(String displaySenderName) {
    if (displaySenderName == 'Anonymous') {
      return 'Written by Anonymous';
    }
    // Extract first name (first word)
    final firstName = displaySenderName.split(' ').first;
    return 'Written by $firstName';
  }
  
  /// Get formatted countdown text with warmer phrasing: "Opens in X days"
  String _getCountdownText(Capsule capsule) {
    if (!capsule.isLocked) return 'Ready to open';
    
    final duration = capsule.timeUntilUnlock;
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    
    if (days > 0) {
      return 'Opens in $days day${days != 1 ? 's' : ''}';
    } else if (hours > 0) {
      return 'Opens in $hours hour${hours != 1 ? 's' : ''}';
    } else {
      return 'Opens in $minutes minute${minutes != 1 ? 's' : ''}';
    }
  }
  
  Future<void> _handleRefresh() async {
    // Prevent concurrent refreshes
    if (_isRefreshing || !mounted) {
      return;
    }
    
    _isRefreshing = true;
    try {
      // Fetch updated capsule data
      final capsuleRepo = ref.read(capsuleRepositoryProvider);
      final updatedCapsule = await capsuleRepo.getCapsuleById(_capsule.id);
      
      if (!mounted) {
        return;
      }
      
      if (updatedCapsule != null) {
        setState(() {
          _capsule = updatedCapsule;
        });
        
        // Invalidate only relevant providers (optimize for performance)
        final userAsync = ref.read(currentUserProvider);
        final userId = userAsync.asData?.value?.id ?? '';
        if (userId.isNotEmpty) {
          // Batch invalidations - only invalidate what's needed
          // Base providers will refresh derived providers automatically
          ref.invalidate(capsulesProvider(userId));
          ref.invalidate(incomingCapsulesProvider(userId));
        }
      } else {
        // Capsule was deleted or not found - navigate back
        if (mounted) {
          context.pop();
        }
      }
    } catch (e, stackTrace) {
      Logger.error('Failed to refresh capsule', error: e, stackTrace: stackTrace);
      
      // Show user-friendly error feedback
      if (mounted) {
        final colorScheme = ref.read(selectedColorSchemeProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to refresh. Please try again.',
              style: TextStyle(
                color: DynamicTheme.getSnackBarTextColor(colorScheme),
              ),
            ),
            backgroundColor: DynamicTheme.getSnackBarBackgroundColor(colorScheme),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        _isRefreshing = false;
      }
    }
  }
  
  void _handleShare() async {
    if (!mounted) return;
    
    try {
      // TODO: Generate and share beautiful countdown image
      final message = '⏰ I have a special letter unlocking on ${DateFormat('MMMM d, y').format(_capsule.unlockAt)}!\n\nMade with OpenOn 💌';
      
      await Share.share(message);
    } catch (e, stackTrace) {
      Logger.error('Failed to share countdown', error: e, stackTrace: stackTrace);
      if (mounted) {
        final colorScheme = ref.read(selectedColorSchemeProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to share. Please try again.',
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
    }
  }
  
  Future<void> _handleWithdraw() async {
    // Prevent double-withdrawal (race condition protection)
    if (_isWithdrawing || !mounted) {
      return;
    }
    
    final colorScheme = ref.read(selectedColorSchemeProvider);
    
    // Ensure letter hasn't been opened (safety check)
    if (_capsule.isOpened) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This letter has already been opened and cannot be withdrawn.',
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
      return;
    }
    
    // Safely get recipient name (handle edge cases)
    final recipientName = _capsule.recipientName.isNotEmpty 
        ? _capsule.recipientName 
        : 'the recipient';
    
    // Show thoughtful confirmation dialog
    final confirmed = await AppDialogBuilder.showConfirmationDialog(
      context: context,
      colorScheme: colorScheme,
      title: 'Withdraw Letter',
      message: 'This letter will not be sent to $recipientName. It will be immediately removed from their inbox and will never be delivered, including any anonymous identity.\n\nThis action cannot be undone.',
      confirmText: 'Withdraw',
      cancelText: 'Keep Letter',
      confirmColor: DynamicTheme.getSecondaryTextColor(colorScheme), // Calmer color, not red
      barrierColor: Colors.black.withOpacity(0.4), // Softer barrier
    );
    
    if (confirmed != true || !mounted) {
      return;
    }
    
    _isWithdrawing = true;
    try {
      // Show gentle loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      DynamicTheme.getSnackBarTextColor(colorScheme),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Text(
                  'Withdrawing letter...',
                  style: TextStyle(
                    color: DynamicTheme.getSnackBarTextColor(colorScheme),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: DynamicTheme.getSnackBarBackgroundColor(colorScheme),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        );
      }
      
      // Withdraw the capsule (soft delete)
      final capsuleRepo = ref.read(capsuleRepositoryProvider);
      
      // Log withdrawal action for analytics (production monitoring)
      Logger.info(
        'Withdrawing letter: capsule_id=${_capsule.id}, recipient_id=${_capsule.receiverId}, is_anonymous=${_capsule.isAnonymous}, time_until_unlock_hours=${_capsule.timeUntilUnlock.inHours}',
      );
      
      await capsuleRepo.deleteCapsule(_capsule.id);
      
      // Invalidate providers to refresh lists
      // This ensures the letter is removed from recipient's inbox immediately
      // Only invalidate base providers - derived providers will update automatically
      final userAsync = ref.read(currentUserProvider);
      final userId = userAsync.asData?.value?.id ?? '';
      if (userId.isNotEmpty) {
        // Invalidate base providers (optimized - derived providers auto-update)
        ref.invalidate(capsulesProvider(userId));
        ref.invalidate(incomingCapsulesProvider(userId));
      }
      
      // Navigate back before showing success message
      if (mounted) {
        final navigator = Navigator.of(context, rootNavigator: false);
        navigator.pop();
        
        // Show thoughtful success message after navigation
        // Use a small delay to ensure navigation completes and context is valid
        await Future.delayed(const Duration(milliseconds: 150));
        
        // Check if we still have a valid context after navigation
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Letter withdrawn. It will not be delivered.',
                style: TextStyle(
                  color: DynamicTheme.getSnackBarTextColor(colorScheme),
                ),
              ),
              backgroundColor: DynamicTheme.getSnackBarBackgroundColor(colorScheme),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      Logger.error('Failed to withdraw letter', error: e, stackTrace: stackTrace);
      
      if (mounted) {
        final errorMessage = ErrorHandler.getErrorMessage(
          e,
          defaultMessage: 'Unable to withdraw letter. Please try again.',
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
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
        _isWithdrawing = false;
      }
    }
  }
  
  void _handleTapEnvelope() {
    if (!mounted) return;
    
    // Use current capsule state (may have been refreshed)
    if (_capsule.canOpen) {
      // Navigate to opening animation
      context.push(
        '/capsule/${_capsule.id}/opening',
        extra: _capsule,
      );
    } else {
      // Show tooltip
      final colorScheme = ref.read(selectedColorSchemeProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Not yet… come back in ${_capsule.countdownText} ♥',
            style: TextStyle(
              color: DynamicTheme.getSnackBarTextColor(colorScheme),
            ),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: DynamicTheme.getSnackBarBackgroundColor(colorScheme),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final capsule = _capsule;
    final canOpen = capsule.canOpen;
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final gradient = DynamicTheme.dreamyGradient(colorScheme);
    final userAsync = ref.watch(currentUserProvider);
    final currentUserId = userAsync.asData?.value?.id ?? '';
    final isSender = currentUserId.isNotEmpty && capsule.senderId == currentUserId;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: gradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: EdgeInsets.all(AppTheme.spacingMd),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back, 
                        color: DynamicTheme.getPrimaryIconColor(
                          ref.read(selectedColorSchemeProvider),
                        ),
                      ),
                      onPressed: () => context.pop(),
                    ),
                    const Spacer(),
                    // Only show withdraw option for unopened letters the user sent
                    // Once opened, the moment is respected and final - withdraw is disabled
                    if (isSender && !capsule.isOpened)
                      Semantics(
                        label: 'Withdraw letter',
                        button: true,
                        enabled: !_isWithdrawing,
                        child: IconButton(
                          icon: Icon(
                            Icons.history,
                            color: DynamicTheme.getSecondaryTextColor(
                              ref.read(selectedColorSchemeProvider),
                            ), // Muted color for calm, reflective feel
                          ),
                          onPressed: _isWithdrawing ? null : _handleWithdraw,
                          tooltip: 'Withdraw letter',
                        ),
                      ),
                  ],
                ),
              ),
              
              Expanded(
                child: Center(
                  child: RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: colorScheme.accent,
                    backgroundColor: colorScheme.isDarkTheme 
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                    strokeWidth: 3.0,
                    displacement: 40.0,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.only(                          
                          bottom: AppTheme.spacingXl,
                          left: AppTheme.spacingXl,
                          right: AppTheme.spacingXl,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                        // Label
                        Text(
                          capsule.label,
                          style: TextStyle(
                            color: DynamicTheme.getPrimaryTextColor(colorScheme),
                            fontSize: AppConstants.lockedCapsuleTitleFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: AppTheme.spacingMd),
                        
                        Text(
                          _getSenderText(capsule.displaySenderName),
                          style: TextStyle(
                            color: DynamicTheme.getSecondaryTextColor(colorScheme, opacity: AppTheme.opacityAlmostFull2),
                            fontSize: AppConstants.lockedCapsuleSubtitleFontSize,
                          ),
                        ),
                        
                        SizedBox(height: AppTheme.spacingLg),
                        
                        // Sender and recipient avatars with labels and animated emoji
                        SizedBox(
                          height: AppConstants.lockedCapsuleEmojiStackHeight,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Capture colorScheme for use in AnimatedBuilder
                              final currentColorScheme = colorScheme;
                              return Stack(
                                children: [
                                  // Avatars row with labels
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Sender section (left)
                                      Expanded(
                                        child: Center(
                                          child: capsule.isAnonymous && !capsule.isRevealed
                                              ? CircleAvatar(
                                                  radius: AppConstants.lockedCapsuleAvatarRadius,
                                                  backgroundColor: DynamicTheme.getCardBackgroundColor(colorScheme, opacity: AppTheme.opacityMedium),
                                                  child: Icon(
                                                    Icons.visibility_off_outlined,
                                                    color: DynamicTheme.getPrimaryIconColor(colorScheme),
                                                    size: AppConstants.lockedCapsuleAvatarRadius,
                                                  ),
                                                )
                                              : UserAvatar(
                                                  imageUrl: capsule.displaySenderAvatar.isNotEmpty ? capsule.displaySenderAvatar : null,
                                                  name: capsule.displaySenderName,
                                                  size: AppConstants.lockedCapsuleAvatarSize,
                                                ),
                                        ),
                                      ),
                                      
                                      // Spacing between sender and receiver
                                      SizedBox(width: AppTheme.spacingXl * AppConstants.lockedCapsuleAvatarSpacing),
                                      
                                      // Recipient section (right)
                                      Expanded(
                                        child: Center(
                                          child: UserAvatar(
                                            imageUrl: capsule.receiverAvatar.isNotEmpty ? capsule.receiverAvatar : null,
                                            name: capsule.receiverName,
                                            size: AppConstants.lockedCapsuleAvatarSize,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  // Text in the middle: "A thought on its way…"
                                  // Positioned below the avatars
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    top: AppConstants.lockedCapsuleEmojiTextTopPosition,
                                    child: Center(
                                      child: Text(
                                        'A thought on its way…',
                                        style: TextStyle(
                                          color: DynamicTheme.getSecondaryTextColor(colorScheme, opacity: AppTheme.opacityAlmostFull),
                                          fontSize: AppConstants.lockedCapsuleTextFontSize,
                                          fontWeight: FontWeight.w400,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  // Animated emoji overlay - moves from sender to receiver
                                  if (_currentEmoji != null)
                                    AnimatedBuilder(
                                      animation: _emojiPositionAnimation,
                                      builder: (context, child) {
                                        // Ensure animation value is valid (0.0 to 1.0)
                                        final progress = _emojiPositionAnimation.value.clamp(0.0, 1.0);
                                        
                                        // Use constants for avatar and emoji sizes
                                        final avatarRadius = AppConstants.lockedCapsuleAvatarRadius;
                                        final emojiSize = AppConstants.lockedCapsuleEmojiSize;
                                        
                                        // Calculate positions based on the Row layout
                                        // Row structure: Expanded(sender) | SizedBox(spacing) | Expanded(receiver)
                                        // Each Expanded takes equal space, avatars are centered within them
                                        final totalWidth = constraints.maxWidth;
                                        
                                        // Safety check: ensure minimum width to prevent calculation errors
                                        if (totalWidth < AppConstants.lockedCapsuleMinScreenWidth) {
                                          // If screen is too small, hide emoji or position at center
                                          return Positioned(
                                            left: (totalWidth - emojiSize) / 2,
                                            top: 0,
                                            child: Opacity(
                                              opacity: 0.0, // Hide if screen too small
                                              child: Text(
                                                _currentEmoji!,
                                                style: TextStyle(fontSize: AppConstants.lockedCapsuleEmojiFontSize),
                                              ),
                                            ),
                                          );
                                        }
                                        
                                        final spacingWidth = AppTheme.spacingXl * AppConstants.lockedCapsuleAvatarSpacing;
                                        
                                        // Ensure we have enough space for both avatars and spacing
                                        final minRequiredWidth = (avatarRadius * 4) + spacingWidth; // 2 avatars + spacing
                                        if (totalWidth < minRequiredWidth) {
                                          // Fallback: center the emoji if not enough space
                                          final opacity = (AppConstants.lockedCapsuleEmojiBaseOpacity - 
                                              (progress * AppConstants.lockedCapsuleEmojiOpacityFade))
                                              .clamp(AppConstants.lockedCapsuleEmojiOpacityMin, AppConstants.lockedCapsuleEmojiOpacityMax);
                                          final scale = AppConstants.lockedCapsuleEmojiScaleMin + 
                                              (progress * AppConstants.lockedCapsuleEmojiScaleRange);
                                          
                                          return Positioned(
                                            left: (totalWidth - emojiSize) / 2,
                                            top: 0,
                                            child: Opacity(
                                              opacity: opacity,
                                              child: Transform.scale(
                                                scale: scale,
                                                child: Container(
                                                  width: AppConstants.lockedCapsuleEmojiContainerSize,
                                                  height: AppConstants.lockedCapsuleEmojiContainerSize,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: DynamicTheme.getPrimaryTextColor(currentColorScheme)
                                                            .withOpacity(AppConstants.lockedCapsuleEmojiGlowOpacity),
                                                        blurRadius: AppConstants.lockedCapsuleEmojiGlowBlurRadius,
                                                        spreadRadius: AppConstants.lockedCapsuleEmojiGlowSpreadRadius,
                                                      ),
                                                    ],
                                                  ),
                                                  child: Text(
                                                    _currentEmoji!,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: AppConstants.lockedCapsuleEmojiFontSize,
                                                      height: AppConstants.lockedCapsuleTextLineHeight,
                                                      shadows: [
                                                        Shadow(
                                                          color: DynamicTheme.getPrimaryTextColor(currentColorScheme)
                                                              .withOpacity(AppConstants.lockedCapsuleEmojiTextShadowOpacity),
                                                          blurRadius: AppConstants.lockedCapsuleEmojiTextShadowBlurRadius,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        
                                        final expandedSectionWidth = (totalWidth - spacingWidth) / 2;
                                        
                                        // Sender avatar is centered in left Expanded section
                                        // Avatar center X = expandedSectionWidth / 2
                                        // Start position: right edge of sender avatar = center + radius
                                        final senderAvatarCenterX = expandedSectionWidth / 2;
                                        final startX = senderAvatarCenterX + avatarRadius;
                                        
                                        // Receiver avatar is centered in right Expanded section
                                        // Avatar center X = expandedSectionWidth + spacingWidth + expandedSectionWidth / 2
                                        // End position: left edge of receiver avatar = center - radius
                                        final receiverAvatarCenterX = expandedSectionWidth + spacingWidth + (expandedSectionWidth / 2);
                                        final endX = receiverAvatarCenterX - avatarRadius;
                                        
                                        // Calculate current position between start and end
                                        final distance = endX - startX;
                                        
                                        // Safety check: ensure valid distance
                                        if (distance <= 0) {
                                          // If distance is invalid, position at start with proper styling
                                          final opacity = (AppConstants.lockedCapsuleEmojiBaseOpacity - 
                                              (progress * AppConstants.lockedCapsuleEmojiOpacityFade))
                                              .clamp(AppConstants.lockedCapsuleEmojiOpacityMin, AppConstants.lockedCapsuleEmojiOpacityMax);
                                          final scale = AppConstants.lockedCapsuleEmojiScaleMin + 
                                              (progress * AppConstants.lockedCapsuleEmojiScaleRange);
                                          
                                          return Positioned(
                                            left: startX - (emojiSize / 2),
                                            top: 0,
                                            child: Opacity(
                                              opacity: opacity,
                                              child: Transform.scale(
                                                scale: scale,
                                                child: Container(
                                                  width: AppConstants.lockedCapsuleEmojiContainerSize,
                                                  height: AppConstants.lockedCapsuleEmojiContainerSize,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: DynamicTheme.getPrimaryTextColor(currentColorScheme)
                                                            .withOpacity(AppConstants.lockedCapsuleEmojiGlowOpacity),
                                                        blurRadius: AppConstants.lockedCapsuleEmojiGlowBlurRadius,
                                                        spreadRadius: AppConstants.lockedCapsuleEmojiGlowSpreadRadius,
                                                      ),
                                                    ],
                                                  ),
                                                  child: Text(
                                                    _currentEmoji!,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: AppConstants.lockedCapsuleEmojiFontSize,
                                                      height: AppConstants.lockedCapsuleTextLineHeight,
                                                      shadows: [
                                                        Shadow(
                                                          color: DynamicTheme.getPrimaryTextColor(currentColorScheme)
                                                              .withOpacity(AppConstants.lockedCapsuleEmojiTextShadowOpacity),
                                                          blurRadius: AppConstants.lockedCapsuleEmojiTextShadowBlurRadius,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        
                                        final currentX = startX + (distance * progress);
                                        
                                        // Position emoji so its center is at currentX
                                        // Clamp to ensure emoji stays within bounds
                                        final emojiLeft = (currentX - (emojiSize / 2)).clamp(0.0, totalWidth - emojiSize);
                                        
                                        // Calculate opacity and scale using constants
                                        final opacity = (AppConstants.lockedCapsuleEmojiBaseOpacity - 
                                            (progress * AppConstants.lockedCapsuleEmojiOpacityFade))
                                            .clamp(AppConstants.lockedCapsuleEmojiOpacityMin, AppConstants.lockedCapsuleEmojiOpacityMax);
                                        final scale = AppConstants.lockedCapsuleEmojiScaleMin + 
                                            (progress * AppConstants.lockedCapsuleEmojiScaleRange);
                                        
                                        return Positioned(
                                          left: emojiLeft,
                                          top: 0, // Position at top of the Stack (above avatars)
                                          child: Opacity(
                                            opacity: opacity,
                                            child: Transform.scale(
                                              scale: scale,
                                              child: Container(
                                                width: AppConstants.lockedCapsuleEmojiContainerSize,
                                                height: AppConstants.lockedCapsuleEmojiContainerSize,
                                                alignment: Alignment.center,
                                                // Circular glow effect for ethereal appearance
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: DynamicTheme.getPrimaryTextColor(currentColorScheme)
                                                          .withOpacity(AppConstants.lockedCapsuleEmojiGlowOpacity),
                                                      blurRadius: AppConstants.lockedCapsuleEmojiGlowBlurRadius,
                                                      spreadRadius: AppConstants.lockedCapsuleEmojiGlowSpreadRadius,
                                                    ),
                                                  ],
                                                ),
                                                child: Text(
                                                  _currentEmoji!,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: AppConstants.lockedCapsuleEmojiFontSize,
                                                    height: AppConstants.lockedCapsuleTextLineHeight,
                                                    shadows: [
                                                      // Additional subtle text shadow for glow
                                                      Shadow(
                                                        color: DynamicTheme.getPrimaryTextColor(currentColorScheme)
                                                            .withOpacity(AppConstants.lockedCapsuleEmojiTextShadowOpacity),
                                                        blurRadius: AppConstants.lockedCapsuleEmojiTextShadowBlurRadius,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                        
                        SizedBox(height: AppTheme.spacingLg),
                        
                        // Envelope with countdown - fixed size container to prevent layout shifts
                        SizedBox(
                          width: AppConstants.lockedCapsuleEnvelopeContainerSize,
                          height: AppConstants.lockedCapsuleEnvelopeContainerSize,
                          child: GestureDetector(
                            onTap: _handleTapEnvelope,
                            child: AnimatedBuilder(
                              animation: _circleSizeAnimation,
                              builder: (context, child) {
                                return Center(
                                  child: Container(
                                    width: _circleSizeAnimation.value,
                                    height: _circleSizeAnimation.value,
                                    decoration: BoxDecoration(
                                      color: DynamicTheme.getCardBackgroundColor(colorScheme, opacity: AppTheme.opacityMedium),
                                      shape: BoxShape.circle,
                                    ),
                                    child: child,
                                  ),
                                );
                              },
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Countdown progress indicator
                                  if (!canOpen && capsule.timeUntilUnlock > Duration.zero)
                                    CircularProgressIndicator(
                                      value: _calculateProgress(capsule),
                                      strokeWidth: 6,
                                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.secondary1),
                                      backgroundColor: DynamicTheme.getCardBackgroundColor(colorScheme, opacity: AppTheme.opacityHigh),
                                    ),
                                  
                                  // Envelope/lock icon with anonymous icon if applicable
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Animated lock icon with subtle breathing effect and halo when locked
                                      if (canOpen)
                                        Icon(
                                          Icons.mail_outline,
                                          size: AppConstants.lockedCapsuleLockIconSize,
                                          color: DynamicTheme.getPrimaryIconColor(colorScheme),
                                        )
                                      else
                                        AnimatedBuilder(
                                          animation: Listenable.merge([_breathingAnimation, _lockHaloAnimation]),
                                          builder: (context, child) {
                                            return Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                // Subtle halo effect - pulses with circle animation
                                                AnimatedBuilder(
                                                  animation: _lockHaloAnimation,
                                                  builder: (context, child) {
                                                    return Container(
                                                      width: AppConstants.lockedCapsuleLockHaloSize,
                                                      height: AppConstants.lockedCapsuleLockHaloSize,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: DynamicTheme.getPrimaryIconColor(colorScheme)
                                                                .withOpacity(_lockHaloAnimation.value),
                                                            blurRadius: AppConstants.lockedCapsuleHaloBlurRadius,
                                                            spreadRadius: AppConstants.lockedCapsuleHaloSpreadRadius,
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                                // Lock icon with breathing opacity
                                                Opacity(
                                                  opacity: _breathingAnimation.value,
                                                  child: Icon(
                                                    Icons.lock_outline,
                                                    size: AppConstants.lockedCapsuleLockIconSize,
                                                    color: DynamicTheme.getPrimaryIconColor(colorScheme),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      // Show anonymous icon if capsule is anonymous and not revealed
                                      if (capsule.isAnonymous && !capsule.isRevealed) ...[
                                        SizedBox(width: 8),
                                        Icon(
                                          Icons.visibility_off_outlined,
                                          size: 35,
                                          color: DynamicTheme.getPrimaryIconColor(colorScheme).withOpacity(0.8),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        SizedBox(height: AppTheme.spacingXl),
                        
                        // Countdown or ready message
                        if (canOpen) ...[
                          Text(
                            'Ready to open!',
                            style: TextStyle(
                              color: DynamicTheme.getPrimaryTextColor(colorScheme),
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: AppTheme.spacingMd),
                          Text(
                            'Tap the envelope to reveal your letter',
                            style: TextStyle(
                              color: DynamicTheme.getSecondaryTextColor(colorScheme, opacity: AppTheme.opacityFull),
                              fontSize: AppConstants.lockedCapsuleSubtitleFontSize,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ] else ...[
                          Text(
                            _getCountdownText(capsule),
                            style: TextStyle(
                              color: DynamicTheme.getPrimaryTextColor(colorScheme),
                              fontSize: AppConstants.lockedCapsuleCountdownFontSize,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: AppTheme.spacingLg),
                          Text(
                            'Opens on ${DateFormat('MMMM d, y \'at\' h:mm a').format(capsule.unlockAt)}',
                            style: TextStyle(
                              color: DynamicTheme.getSecondaryTextColor(colorScheme, opacity: AppTheme.opacityAlmostFull),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              ),
              
              // Bottom buttons
              if (!canOpen)
                Padding(
                  padding: EdgeInsets.all(AppTheme.spacingLg),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _handleShare,
                      icon: const Icon(Icons.share),
                      label: const Text('Share Countdown'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DynamicTheme.getCardBackgroundColor(colorScheme),
                        foregroundColor: DynamicTheme.getButtonTextColor(colorScheme),
                        padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                        side: DynamicTheme.getButtonBorderSide(colorScheme),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
}
