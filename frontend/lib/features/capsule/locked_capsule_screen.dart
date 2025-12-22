import 'dart:async';
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
import 'package:intl/intl.dart';

class LockedCapsuleScreen extends ConsumerStatefulWidget {
  final Capsule capsule;
  
  const LockedCapsuleScreen({super.key, required this.capsule});
  
  @override
  ConsumerState<LockedCapsuleScreen> createState() => _LockedCapsuleScreenState();
}

class _LockedCapsuleScreenState extends ConsumerState<LockedCapsuleScreen> {
  Timer? _countdownTimer;
  late Capsule _capsule;
  bool _isWithdrawing = false; // Prevent double-withdrawal
  bool _isRefreshing = false; // Prevent concurrent refreshes
  
  @override
  void initState() {
    super.initState();
    _capsule = widget.capsule;
    
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
    super.dispose();
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
                        padding: const EdgeInsets.all(AppTheme.spacingXl),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                        // Label
                        Text(
                          capsule.label,
                          style: TextStyle(
                            color: DynamicTheme.getPrimaryTextColor(colorScheme),
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: AppTheme.spacingSm),
                        
                        Text(
                          'From ${capsule.displaySenderName}',
                          style: TextStyle(
                            color: DynamicTheme.getSecondaryTextColor(colorScheme, opacity: AppTheme.opacityAlmostFull2),
                            fontSize: 16,
                          ),
                        ),
                        
                        SizedBox(height: AppTheme.spacingXl * 2),
                        
                        // Envelope with countdown
                        GestureDetector(
                          onTap: _handleTapEnvelope,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: DynamicTheme.getCardBackgroundColor(colorScheme, opacity: AppTheme.opacityMedium),
                              shape: BoxShape.circle,
                            ),
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
                                    Icon(
                                      canOpen ? Icons.mail_outline : Icons.lock_outline,
                                      size: 70,
                                      color: DynamicTheme.getPrimaryIconColor(colorScheme),
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
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ] else ...[
                          Text(
                            capsule.countdownText,
                            style: TextStyle(
                              color: DynamicTheme.getPrimaryTextColor(colorScheme),
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: AppTheme.spacingMd),
                          Text(
                            'Until unlock',
                            style: TextStyle(
                              color: DynamicTheme.getSecondaryTextColor(colorScheme, opacity: AppTheme.opacityAlmostFull2),
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: AppTheme.spacingXl),
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
