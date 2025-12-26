import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io' show Platform;
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/theme/app_text_styles.dart';
import 'package:openon_app/core/theme/color_scheme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:openon_app/core/utils/error_handler.dart';
import 'package:openon_app/core/widgets/common_widgets.dart';
import 'package:openon_app/core/constants/app_constants.dart';
import 'package:openon_app/core/models/countdown_share_models.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:openon_app/core/data/api_client.dart';
import 'package:openon_app/core/data/api_config.dart';

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
  bool _isCreatingShare = false; // Prevent concurrent share creation
  String? _cachedShareUrl; // Cache share URL per letter to avoid recreating
  ValueNotifier<String?>? _shareUrlNotifier; // For updating dialog content
  bool _isPreviewDialogOpen = false; // Track if preview dialog is open
  bool _isPreviewOpen = false; // Track if preview dialog is open
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  late AnimationController _circlePulseController;
  late Animation<double> _circleSizeAnimation;
  late Animation<double> _lockHaloAnimation;
  late AnimationController _emojiAnimationController;
  late Animation<double> _emojiPositionAnimation;
  late AnimationController _countdownShimmerController;
  late AnimationController _envelopeGlowController;
  late Animation<double> _envelopeGlowAnimation;
  String? _currentEmoji;
  final Random _random = Random();
  static const List<String> _emojis = ['💌', '✨', '🤍'];
  
  // Sender-only anticipation message (never visible to receiver)
  String? _anticipationMessage;
  bool _hasTrackedView = false; // Track if we've already tracked view this session
  
  @override
  void initState() {
    super.initState();
    _capsule = widget.capsule;
    // Fetch invite URL if missing for unregistered recipients
    _fetchInviteUrlIfNeeded();
    // Track view if receiver, fetch anticipation message if sender
    _handleAnticipationTracking();
    
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
    
    // Countdown shimmer animation for gradient effect
    _countdownShimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    
    // Envelope glow animation - pulses every 2 seconds
    _envelopeGlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _envelopeGlowAnimation = Tween<double>(
      begin: 0.2,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _envelopeGlowController,
      curve: Curves.easeInOut,
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
    _countdownShimmerController.dispose();
    _envelopeGlowController.dispose();
    // Clean up share URL notifier
    try {
      _shareUrlNotifier?.dispose();
    } catch (e) {
      // Ignore if already disposed
      Logger.debug('Error disposing share URL notifier: $e');
    }
    _shareUrlNotifier = null;
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
    // If duration is negative or zero, it's ready to open
    if (duration.isNegative || duration.inSeconds <= 0) {
      return 'Ready to open';
    }
    
    final totalSeconds = duration.inSeconds;
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    // Calculate minutes from total seconds (not using duration.inMinutes which can truncate)
    // This ensures 1 minute is shown when there's 60+ seconds remaining
    final totalMinutes = totalSeconds ~/ 60;
    final minutes = (days > 0 || hours > 0) ? (totalMinutes % 60) : totalMinutes;
    
    if (days > 0) {
      return 'Opens in $days day${days != 1 ? 's' : ''}';
    } else if (hours > 0) {
      return 'Opens in $hours hour${hours != 1 ? 's' : ''}';
    } else if (totalSeconds >= 60) {
      // At least 60 seconds remaining - show minutes
      return 'Opens in $minutes minute${minutes != 1 ? 's' : ''}';
    } else {
      // Less than 60 seconds remaining - show "Ready to open"
      return 'Ready to open';
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
        
        // Fetch anticipation message if sender (on refresh)
        final userAsync = ref.read(currentUserProvider);
        final currentUserId = userAsync.asData?.value?.id ?? '';
        final isSender = currentUserId.isNotEmpty && _capsule.isCurrentUserSender(currentUserId);
        if (isSender && _capsule.isLocked) {
          _fetchAnticipationMessage();
        }
        
        // Invalidate only relevant providers (optimize for performance)
        // Wrap in try-catch to prevent provider invalidation errors from breaking refresh
        try {
          final userId = currentUserId;
          if (userId.isNotEmpty) {
            // Batch invalidations - only invalidate what's needed
            // Base providers will refresh derived providers automatically
            ref.invalidate(capsulesProvider(userId));
            ref.invalidate(incomingCapsulesProvider(userId));
          }
        } catch (providerError, providerStack) {
          // Log provider invalidation errors but don't fail the refresh
          // The capsule data was successfully updated, which is the main goal
          Logger.warning('Failed to invalidate providers during refresh', 
            error: providerError, 
            stackTrace: providerStack);
        }
      } else {
        // Capsule was deleted or not found - navigate back
        if (mounted) {
          context.pop();
        }
      }
    } catch (e, stackTrace) {
      Logger.error('Failed to refresh capsule', error: e, stackTrace: stackTrace);
      
      // Import exception types for proper error detection
      final errorMessage = e.toString().toLowerCase();
      final isNetworkError = errorMessage.contains('network') || 
                            errorMessage.contains('timeout') ||
                            errorMessage.contains('connection') ||
                            errorMessage.contains('socket');
      
      // Check if it's a 403/Forbidden error (API client converts 403 to AuthenticationException)
      // Also check for permission-related errors
      final is403Error = errorMessage.contains('403') || 
                        errorMessage.contains('forbidden') ||
                        errorMessage.contains('access denied') ||
                        errorMessage.contains('permission') ||
                        errorMessage.contains('not ready yet');
      
      // For 403 errors on locked capsules, this is expected behavior
      // Recipients can view locked capsules but backend restricts refresh
      // Don't show error - just silently fail (user can still see cached data)
      if (is403Error) {
        Logger.warning('Refresh blocked by 403 - this is expected for locked capsules viewed by recipients');
        // Silently fail - user still has the cached capsule data visible
        if (mounted) {
          _isRefreshing = false;
        }
        return;
      }
      
      // Show user-friendly error feedback for other errors
      if (mounted) {
        final colorScheme = ref.read(selectedColorSchemeProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNetworkError 
                ? 'Connection issue. Please check your network and try again.'
                : 'Unable to refresh. Please try again.',
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
    
    // Prevent concurrent share creation
    if (_isCreatingShare) {
      return;
    }
    
    final colorScheme = ref.read(selectedColorSchemeProvider);
    
    // Check if letter is locked
    if (!_capsule.isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Only locked letters can be shared',
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
      return;
    }
    
    // Prevent opening multiple previews
    if (_isPreviewOpen) {
      return;
    }
    
    // Use cached share URL if available (instant preview)
    if (_cachedShareUrl != null) {
      await _showSharePreview(_cachedShareUrl!, _cachedShareUrl!);
      return;
    }
    
    // Show preview immediately with loading state, create share in background
    _shareUrlNotifier = ValueNotifier<String?>(null);
    _isPreviewDialogOpen = true;
    
    // Show dialog first (don't await - let it run in parallel with share creation)
    _showSharePreview(null, null).then((_) {
      // Dialog was closed - clean up
      _isPreviewDialogOpen = false;
      _isCreatingShare = false;
      if (_shareUrlNotifier != null) {
        _shareUrlNotifier?.dispose();
        _shareUrlNotifier = null;
      }
    });
    
    // Start share creation after a small delay to ensure dialog is built
    Future.microtask(() {
      if (!_isCreatingShare && _isPreviewDialogOpen && mounted) {
        _performShareCreationInBackground();
      }
    });
  }
  
  Future<void> _performShareCreationInBackground() async {
    // Prevent multiple concurrent share creations and check if dialog is still open
    if (!mounted || _isCreatingShare || !_isPreviewDialogOpen) {
      Logger.debug('Share creation skipped: mounted=$mounted, creating=$_isCreatingShare, dialogOpen=$_isPreviewDialogOpen');
      return;
    }
    
    _isCreatingShare = true;
    Logger.debug('Starting share creation in background');
    
    try {
      String? shareUrl;
      String? errorMessage;
      
      try {
        // Check if dialog is still open before starting share creation
        if (!_isPreviewDialogOpen || !mounted) {
          Logger.debug('Dialog closed before share creation started, aborting');
          return;
        }
        
        final controller = ref.read(createCountdownShareControllerProvider.notifier);
        await controller.createShare(
          CreateShareRequest(
            letterId: _capsule.id,
            shareType: ShareType.story,
          ),
        );
        
        // Check again after async operation
        if (!_isPreviewDialogOpen || !mounted) {
          Logger.debug('Dialog closed during share creation, aborting');
          return;
        }
        
        final result = ref.read(createCountdownShareControllerProvider).value;
        
        if (result != null && result.success && result.shareUrl != null) {
          shareUrl = result.shareUrl;
          _cachedShareUrl = shareUrl; // Cache for future use
          Logger.info('Share created successfully: $shareUrl');
          
          // Update preview dialog content via ValueNotifier (only if dialog is still open)
          if (_shareUrlNotifier != null && _isPreviewDialogOpen && mounted) {
            // Update immediately - ValueNotifier will trigger rebuild
            _shareUrlNotifier!.value = shareUrl;
            Logger.info('Share URL updated in preview dialog via ValueNotifier: $shareUrl');
          } else {
            Logger.warning('Cannot update share URL: notifier=${_shareUrlNotifier != null}, dialogOpen=$_isPreviewDialogOpen, mounted=$mounted');
          }
        } else {
          final errorCode = result?.errorCode ?? 'UNKNOWN';
          final rawErrorMessage = result?.errorMessage ?? '';
          
          // Always use user-friendly error messages (never show technical errors)
          if (errorCode == 'FUNCTION_NOT_FOUND' || errorCode == 'UNEXPECTED_ERROR') {
            // Check if it's an Edge Function availability issue
            if (rawErrorMessage.toLowerCase().contains('function') || 
                rawErrorMessage.toLowerCase().contains('edge') ||
                rawErrorMessage.toLowerCase().contains('not available') ||
                rawErrorMessage.toLowerCase().contains('deployed')) {
              errorMessage = 'Share feature is temporarily unavailable. Please try again later.';
            } else {
              errorMessage = 'Unable to create share. Please try again.';
            }
          } else if (errorCode == 'NETWORK_ERROR' || errorCode == 'PARSE_ERROR') {
            errorMessage = 'Network error. Please check your connection and try again.';
          } else if (errorCode == 'NOT_AUTHENTICATED') {
            errorMessage = 'Please sign in to create a share.';
          } else if (errorCode == 'LETTER_NOT_LOCKED') {
            errorMessage = 'This letter cannot be shared at this time.';
          } else if (errorCode == 'LETTER_ALREADY_REVEALED') {
            errorMessage = 'Anonymous sender has been revealed. Letter cannot be shared.';
          } else if (errorCode == 'DAILY_LIMIT_REACHED') {
            errorMessage = 'You have reached your daily limit of 5 shares.';
          } else if (errorCode == 'NOT_AUTHORIZED') {
            errorMessage = 'You do not have permission to share this letter.';
          } else if (errorCode == 'LETTER_NOT_FOUND') {
            errorMessage = 'Letter not found.';
          } else if (errorCode == 'LETTER_ALREADY_OPENED') {
            errorMessage = 'This letter has already been opened and cannot be shared.';
          } else if (errorCode == 'LETTER_DELETED') {
            errorMessage = 'This letter has been deleted and cannot be shared.';
          } else if (errorCode == 'INVALID_RESPONSE' || errorCode == 'INVALID_REQUEST') {
            errorMessage = 'Unable to create share. Please try again.';
          } else {
            // Generic error - always use user-friendly message
            errorMessage = 'Unable to create share. Please try again.';
          }
          
          Logger.warning('Share creation failed: code=$errorCode, rawMessage=$rawErrorMessage, userMessage=$errorMessage');
          
          // Show error and close preview (only if dialog is still open)
          if (mounted && _isPreviewDialogOpen) {
            _isPreviewDialogOpen = false;
            Navigator.of(context).pop(); // Close loading preview
            final colorScheme = ref.read(selectedColorSchemeProvider);
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
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      } catch (e, stackTrace) {
        Logger.error('Exception creating share', error: e, stackTrace: stackTrace);
        
        // Provide user-friendly error message based on exception type
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('function') || errorString.contains('edge')) {
          errorMessage = 'Share feature is temporarily unavailable. Please try again later.';
        } else if (errorString.contains('network') || errorString.contains('connection') || errorString.contains('timeout')) {
          errorMessage = 'Network error. Please check your connection and try again.';
        } else if (errorString.contains('not authenticated') || errorString.contains('unauthorized')) {
          errorMessage = 'Please sign in to create a share.';
        } else {
          errorMessage = 'Unable to create share. Please try again.';
        }
        
        // Show error and close preview (only if dialog is still open)
        if (mounted && _isPreviewDialogOpen) {
          _isPreviewDialogOpen = false;
          _shareUrlNotifier?.dispose();
          _shareUrlNotifier = null;
          Navigator.of(context).pop(); // Close loading preview
          final colorScheme = ref.read(selectedColorSchemeProvider);
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
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        _isCreatingShare = false;
      }
    }
  }
  
  
  Future<void> _showSharePreview(String? shareUrl, String? message) async {
    if (!mounted) return;
    
    // Show loading state if shareUrl is null
    final bool isLoading = shareUrl == null;
    final String displayShareUrl = shareUrl ?? 'Creating share link...';
    
    // Calculate countdown (optimized - pre-calculate before dialog)
    final now = DateTime.now();
    final timeUntilUnlock = _capsule.unlockAt.difference(now);
    final isUnlocked = timeUntilUnlock <= Duration.zero;
    
    int daysRemaining = 0;
    if (!isUnlocked) {
      daysRemaining = timeUntilUnlock.inDays;
    }
    
    // Format countdown text - romantic, contextual messages
    final String countdownText = isUnlocked
        ? "Ready to open"
        : daysRemaining > 30
            ? "Saved for a special day"
            : daysRemaining >= 14
                ? "When the time comes"
                : daysRemaining >= 7
                    ? "Getting closer"
                    : daysRemaining >= 2
                        ? "In a few days"
                        : "Almost here";
    
    // Get theme colors (default to purple gradient if no theme)
    // Optimized: Use const colors for better performance
    const Color gradientStart = Color(0xFF667eea);
    const Color gradientEnd = Color(0xFF764ba2);
    
    // Format date - no year for a softer feel (pre-calculate)
    final formattedDate = DateFormat('MMMM d').format(_capsule.unlockAt);
    final displayTitle = _capsule.label.isNotEmpty ? _capsule.label : "Something is waiting";
    
    // Use ValueNotifier for dynamic updates if shareUrl is null initially
    // Ensure we use the same notifier instance that will be updated
    // IMPORTANT: When shareUrl is null, we MUST use _shareUrlNotifier so updates work
    final ValueNotifier<String?> notifierToUse;
    final bool isOneTimeNotifier; // Track if this is a one-time notifier that needs disposal
    if (shareUrl == null) {
      // Create or reuse the shared notifier for loading state
      _shareUrlNotifier ??= ValueNotifier<String?>(null);
      notifierToUse = _shareUrlNotifier!;
      isOneTimeNotifier = false; // Shared notifier, don't dispose here
    } else {
      // For existing shareUrl, create a one-time notifier (will be disposed on dialog close)
      notifierToUse = ValueNotifier<String?>(shareUrl);
      isOneTimeNotifier = true; // One-time notifier, needs disposal
    }
    
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (dialogContext) {
        return RepaintBoundary(
          child: ValueListenableBuilder<String?>(
            valueListenable: notifierToUse,
            builder: (context, currentShareUrl, _) {
              final bool isCurrentlyLoading = currentShareUrl == null;
              final String displayCurrentUrl = currentShareUrl ?? displayShareUrl;
              
              return Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: EdgeInsets.all(AppTheme.spacingLg),
                child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: 500,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [gradientStart, gradientEnd],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: Offset(0, 10),
              ),
            ],
          ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                // Header with close button
                Padding(
                  padding: EdgeInsets.all(AppTheme.spacingMd),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Share',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          // Mark dialog as closed and stop share creation
                          _isPreviewDialogOpen = false;
                          _isCreatingShare = false;
                          // Don't dispose notifiers here - let the .then() callback handle it
                          // This prevents double-disposal issues
                          Navigator.of(dialogContext).pop();
                        },
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Preview card content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingXl,
                        vertical: AppTheme.spacingLg,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Card container with glassmorphism
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingXl,
                              vertical: AppTheme.spacingLg + 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Envelope icon with glowing border animation
                                AnimatedBuilder(
                                  animation: _envelopeGlowAnimation,
                                  builder: (context, child) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withOpacity(_envelopeGlowAnimation.value),
                                            blurRadius: 12 + (_envelopeGlowAnimation.value * 8),
                                            spreadRadius: 2 + (_envelopeGlowAnimation.value * 4),
                                          ),
                                          BoxShadow(
                                            color: Colors.white.withOpacity(_envelopeGlowAnimation.value * 0.5),
                                            blurRadius: 20 + (_envelopeGlowAnimation.value * 12),
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        '💌',
                                        style: TextStyle(fontSize: 56),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(height: AppTheme.spacingSm),
                                // Title
                                Text(
                                  displayTitle,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: AppTheme.spacingLg),
                                // Countdown - visual anchor, magical feel with gradient and shimmer
                                AnimatedBuilder(
                                  animation: _countdownShimmerController,
                                  builder: (context, child) {
                                    // Common text style to ensure alignment
                                    final baseTextStyle = GoogleFonts.tangerine(
                                      fontSize: 42,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                      height: 1.2,
                                    );
                                    
                                    return Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // White border/outline layer
                                        Text(
                                          countdownText,
                                          style: baseTextStyle.copyWith(
                                            foreground: Paint()
                                              ..style = PaintingStyle.stroke
                                              ..strokeWidth = 0.6
                                              ..color = Colors.white.withOpacity(0.8),
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 3,
                                          overflow: TextOverflow.visible,
                                        ),
                                        // Gradient fill layer
                                        ShaderMask(
                                          shaderCallback: (bounds) {
                                            final shimmerOffset = _countdownShimmerController.value * 2 - 1;
                                            return ui.Gradient.linear(
                                              Offset(bounds.width * (0.3 + shimmerOffset * 0.4), 0),
                                              Offset(bounds.width * (0.7 + shimmerOffset * 0.4), bounds.height),
                                              [
                                                Color(0xFF1e40af), // Darker Blue
                                                Color(0xFFbe185d), // Darker Pink
                                                Color(0xFF1e40af), // Darker Blue
                                              ],
                                              [0.0, 0.5, 1.0],
                                            );
                                          },
                                          child: Text(
                                            countdownText,
                                            style: baseTextStyle.copyWith(
                                              color: Colors.white,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 3,
                                            overflow: TextOverflow.visible,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                SizedBox(height: AppTheme.spacingLg),
                                // Date - smaller, lighter
                                Text(
                                  'Opening $formattedDate',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: AppTheme.spacingLg),
                                // CTA Button - moved to bottom
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {},
                                      borderRadius: BorderRadius.circular(30),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: AppTheme.spacingXl,
                                          vertical: AppTheme.spacingSm,
                                        ),
                                        child: Text(
                                          'Get OpenOn',
                                          style: TextStyle(
                                            color: gradientStart,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: AppTheme.spacingLg),
                          // Share URL info
                          Container(
                            padding: EdgeInsets.all(AppTheme.spacingMd),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            child: Row(
                              children: [
                                if (isCurrentlyLoading) ...[
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: AppTheme.spacingSm),
                                ],
                                Expanded(
                                  child: Text(
                                    displayCurrentUrl,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(isCurrentlyLoading ? 0.6 : 0.9),
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!isCurrentlyLoading && currentShareUrl != null) ...[
                                  SizedBox(width: AppTheme.spacingSm),
                                  IconButton(
                                    icon: Icon(Icons.copy, color: Colors.white, size: 18),
                                    onPressed: () async {
                                      await Clipboard.setData(ClipboardData(text: currentShareUrl!));
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Link copied to clipboard'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                    padding: EdgeInsets.all(4),
                                    constraints: BoxConstraints(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (!isCurrentlyLoading && currentShareUrl != null) ...[
                            SizedBox(height: AppTheme.spacingLg),
                            // Share platform buttons row (only show when share URL is ready)
                            Builder(
                              builder: (buttonContext) => SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingXs),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _ShareOptionButton(
                                      key: GlobalKey(),
                                      iconUrl: AppConstants.instagramIconUrl,
                                      label: 'Instagram',
                                      onTap: () async {
                                        if (currentShareUrl != null) {
                                          await _shareMessage(currentShareUrl!, buttonContext);
                                        }
                                      },
                                      colorScheme: ref.read(selectedColorSchemeProvider),
                                    ),
                                    SizedBox(width: AppTheme.spacingSm),
                                    _ShareOptionButton(
                                      key: GlobalKey(),
                                      iconUrl: AppConstants.tiktokIconUrl,
                                      label: 'TikTok',
                                      onTap: () async {
                                        if (currentShareUrl != null) {
                                          await _shareMessage(currentShareUrl!, buttonContext);
                                        }
                                      },
                                      colorScheme: ref.read(selectedColorSchemeProvider),
                                    ),
                                    SizedBox(width: AppTheme.spacingSm),
                                    _ShareOptionButton(
                                      key: GlobalKey(),
                                      iconUrl: AppConstants.whatsappIconUrl,
                                      label: 'WhatsApp',
                                      onTap: () async {
                                        if (currentShareUrl != null) {
                                          await _shareMessage(currentShareUrl!, buttonContext);
                                        }
                                      },
                                      colorScheme: ref.read(selectedColorSchemeProvider),
                                    ),
                                    SizedBox(width: AppTheme.spacingSm),
                                    _ShareOptionButton(
                                      icon: Icons.message,
                                      label: 'Text',
                                      onTap: () async {
                                        if (currentShareUrl != null) {
                                          await _shareMessage(currentShareUrl!, buttonContext);
                                        }
                                      },
                                      colorScheme: ref.read(selectedColorSchemeProvider),
                                    ),
                                    SizedBox(width: AppTheme.spacingSm),
                                    _ShareOptionButton(
                                      icon: Icons.link,
                                      label: 'Copy Link',
                                      onTap: () async {
                                        if (currentShareUrl != null) {
                                          await Clipboard.setData(ClipboardData(text: currentShareUrl!));
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Link copied to clipboard'),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      colorScheme: ref.read(selectedColorSchemeProvider),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                    ],
                  ),
                ),
              ),
            );
            },
          ),
        );
      },
    ).then((_) {
      // Mark dialog as closed and clean up when dialog is dismissed
      if (!mounted) return; // Don't do anything if widget is disposed
      
      _isPreviewDialogOpen = false;
      _isCreatingShare = false; // Stop any ongoing share creation
      
      // Only dispose one-time notifiers (created for existing shareUrl)
      // Don't dispose the shared _shareUrlNotifier here - it's managed separately
      if (isOneTimeNotifier) {
        try {
          // Safely dispose the one-time notifier
          notifierToUse.dispose();
        } catch (e) {
          // Ignore disposal errors - notifier might already be disposed
          // This can happen if the widget was disposed before the dialog closed
          Logger.debug('Error disposing one-time notifier (expected if already disposed): $e');
        }
      }
    });
  }
  
  Future<void> _shareMessage(String message, BuildContext buttonContext) async {
    try {
      if (Platform.isIOS) {
        // Get the button position for iOS share sheet
        final RenderBox? box = buttonContext.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          final Offset position = box.localToGlobal(Offset.zero);
          final Size size = box.size;
          // Ensure position is valid
          if (size.width > 0 && size.height > 0) {
            await Share.share(
              message,
              sharePositionOrigin: Rect.fromLTWH(
                position.dx,
                position.dy,
                size.width,
                size.height,
              ),
            );
            return;
          }
        }
        // Fallback: use a default position at bottom center
        final screenSize = MediaQuery.of(buttonContext).size;
        await Share.share(
          message,
          sharePositionOrigin: Rect.fromLTWH(
            screenSize.width / 2 - 50,
            screenSize.height - 100,
            100,
            100,
          ),
        );
      } else {
        await Share.share(message);
      }
    } catch (e) {
      Logger.error('Error sharing message', error: e);
      // Fallback to simple share without position
      try {
        await Share.share(message);
      } catch (e2) {
        Logger.error('Error in fallback share', error: e2);
        // Show user-friendly error message
        if (mounted) {
          final colorScheme = ref.read(selectedColorSchemeProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Unable to open share dialog. Please try again or copy the link manually.',
                style: TextStyle(
                  color: DynamicTheme.getSnackBarTextColor(colorScheme),
                ),
              ),
              backgroundColor: DynamicTheme.getSnackBarBackgroundColor(colorScheme),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              duration: Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Copy Link',
                textColor: DynamicTheme.getSnackBarTextColor(colorScheme),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: message));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Link copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ),
          );
        }
      }
    }
  }
  
  Future<void> _fetchInviteUrlIfNeeded() async {
    // Only fetch if inviteUrl is missing and we're the sender
    if (_capsule.inviteUrl != null && _capsule.inviteUrl!.isNotEmpty) {
      return; // Already has invite URL
    }
    
    final userAsync = ref.read(currentUserProvider);
    final currentUserId = userAsync.asData?.value?.id ?? '';
    final isSender = currentUserId.isNotEmpty && _capsule.senderId == currentUserId;
    
    if (!isSender) {
      return; // Only senders can fetch invite URLs
    }
    
    try {
      final capsuleRepo = ref.read(capsuleRepositoryProvider);
      final updatedCapsule = await capsuleRepo.getCapsuleById(_capsule.id);
      
      if (mounted && updatedCapsule != null && updatedCapsule.inviteUrl != null && updatedCapsule.inviteUrl!.isNotEmpty) {
        setState(() {
          _capsule = updatedCapsule;
        });
        Logger.info('Fetched invite URL for capsule ${_capsule.id}: ${_capsule.inviteUrl}');
      }
    } catch (e) {
      Logger.warning('Failed to fetch invite URL for capsule ${_capsule.id}', error: e);
      // Don't show error to user - this is a background operation
    }
  }
  
  /// Handle anticipation tracking: track view if receiver, fetch message if sender
  Future<void> _handleAnticipationTracking() async {
    if (!mounted || _capsule.isOpened) {
      return; // Don't track if letter is opened
    }
    
    final userAsync = ref.read(currentUserProvider);
    final currentUserId = userAsync.asData?.value?.id ?? '';
    if (currentUserId.isEmpty) {
      return; // Not authenticated
    }
    
    // Use helper method for clarity and consistency
    final isSender = _capsule.isCurrentUserSender(currentUserId);
    
    // For receivers: Always try to track view (backend will verify if user is recipient)
    // This works for both email-based and connection-based recipients
    // Note: recipientId in Capsule is the recipient UUID, not user UUID, so we can't check it directly
    if (!isSender && !_hasTrackedView && _capsule.isLocked) {
      // Track view when receiver views locked letter (only once per session)
      // Backend will verify if current user is actually the recipient
      _trackReceiverView();
    }
    
    // For senders: Fetch anticipation message
    if (isSender && _capsule.isLocked) {
      // Fetch anticipation message for sender
      _fetchAnticipationMessage();
    }
  }
  
  /// Track when receiver views locked letter
  Future<void> _trackReceiverView() async {
    if (_hasTrackedView || !mounted || _capsule.isOpened) {
      return; // Already tracked or letter opened
    }
    
    _hasTrackedView = true; // Mark as tracked to prevent duplicate calls
    
    try {
      final apiClient = ApiClient();
      await apiClient.post(
        ApiConfig.trackCapsuleView(_capsule.id),
        {},
      );
      Logger.debug('Tracked receiver view for capsule ${_capsule.id}');
    } catch (e) {
      // Silently fail - don't show error to receiver
      Logger.debug('Failed to track receiver view for capsule ${_capsule.id}', error: e);
      _hasTrackedView = false; // Reset on error to allow retry
    }
  }
  
  /// Fetch sender-only anticipation message
  Future<void> _fetchAnticipationMessage() async {
    if (!mounted || _capsule.isOpened) {
      return; // Don't fetch if letter is opened
    }
    
    try {
      final apiClient = ApiClient();
      final response = await apiClient.get(
        ApiConfig.senderLockState(_capsule.id),
      );
      
      if (mounted) {
        final showAnticipation = response['showAnticipation'] as bool? ?? false;
        final message = response['message'] as String?;
        
        setState(() {
          _anticipationMessage = showAnticipation && message != null ? message : null;
        });
        
        if (_anticipationMessage != null) {
          Logger.debug('Fetched anticipation message for capsule ${_capsule.id}: $_anticipationMessage');
        }
      }
    } catch (e) {
      // Silently fail - don't show error to sender
      Logger.debug('Failed to fetch anticipation message for capsule ${_capsule.id}', error: e);
    }
  }
  
  Future<void> _handleInviteShare(String inviteUrl) async {
    if (!mounted) return;
    
    final colorScheme = ref.read(selectedColorSchemeProvider);
    
    // Show share dialog similar to create_capsule_screen
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(AppTheme.spacingLg),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: 500,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colorScheme.primary1, colorScheme.primary2],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.all(AppTheme.spacingMd),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Share Invite Link',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingXl,
                          vertical: AppTheme.spacingLg,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Info message
                            Container(
                              padding: EdgeInsets.all(AppTheme.spacingLg),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.mail_outline,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                  SizedBox(height: AppTheme.spacingMd),
                                  Text(
                                    'Share this private link to send the letter',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: AppTheme.spacingLg),
                            // Share buttons
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingXs),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildInviteShareButton(
                                    icon: Icons.message,
                                    label: 'Text',
                                    onTap: () => _shareInviteLink(inviteUrl, dialogContext),
                                  ),
                                  SizedBox(width: AppTheme.spacingSm),
                                  _buildInviteShareButton(
                                    icon: Icons.link,
                                    label: 'Copy Link',
                                    onTap: () async {
                                      await Clipboard.setData(ClipboardData(text: inviteUrl));
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Link copied to clipboard'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildInviteShareButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 24,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  Future<void> _shareInviteLink(String inviteUrl, BuildContext dialogContext) async {
    try {
      if (Platform.isIOS) {
        final screenSize = MediaQuery.of(dialogContext).size;
        await Share.share(
          inviteUrl,
          sharePositionOrigin: Rect.fromLTWH(
            screenSize.width / 2 - 50,
            screenSize.height - 100,
            100,
            100,
          ),
        );
      } else {
        await Share.share(inviteUrl);
      }
    } catch (e) {
      Logger.error('Error sharing invite link', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to open share dialog. Please copy the link manually.'),
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Copy Link',
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: inviteUrl));
              },
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
        'Withdrawing letter: capsule_id=${_capsule.id}, recipient_id=${_capsule.recipientId}, is_anonymous=${_capsule.isAnonymous}, time_until_unlock_hours=${_capsule.timeUntilUnlock.inHours}',
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
    final isSender = currentUserId.isNotEmpty && capsule.isCurrentUserSender(currentUserId);
    
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
                padding: EdgeInsets.only(
                  top: AppTheme.spacingMd,
                  left: AppTheme.spacingMd,
                  right: AppTheme.spacingMd,
                  bottom: AppTheme.spacingSm,
                ),
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
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: AppTheme.spacingSm),
                          Text(
                            'Opens on ${DateFormat('MMMM d, y \'at\' h:mm a').format(capsule.unlockAt)}',
                            style: TextStyle(
                              color: DynamicTheme.getSecondaryTextColor(colorScheme, opacity: AppTheme.opacityAlmostFull),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        
                        // Sender-only anticipation message (below countdown, above CTA)
                        // CRITICAL: Only shown to sender, never to receiver
                        if (isSender && !capsule.isOpened && _anticipationMessage != null) ...[
                          SizedBox(height: AppTheme.spacingLg),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingMd,
                              vertical: AppTheme.spacingSm,
                            ),
                            decoration: BoxDecoration(
                              color: DynamicTheme.getCardBackgroundColor(
                                colorScheme,
                                opacity: AppTheme.opacityLow,
                              ),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              border: Border.all(
                                color: DynamicTheme.getBorderColor(
                                  colorScheme,
                                  opacity: AppTheme.opacityMedium,
                                ),
                                width: AppTheme.borderWidthThin,
                              ),
                            ),
                            child: Text(
                              _anticipationMessage!,
                              style: TextStyle(
                                color: DynamicTheme.getSecondaryTextColor(
                                  colorScheme,
                                  opacity: AppTheme.opacityAlmostFull2,
                                ),
                                fontSize: 15,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
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
                  child: Column(
                    children: [
                      // Always show "Share Countdown" button
                      SizedBox(
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
                      // Show "Share Invite Link" button ONLY for unregistered recipients
                      if (_capsule.inviteUrl != null && _capsule.inviteUrl!.isNotEmpty) ...[
                        SizedBox(height: AppTheme.spacingMd),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _handleInviteShare(_capsule.inviteUrl!),
                            icon: const Icon(Icons.link),
                            label: const Text('Share Invite Link'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary1,
                              foregroundColor: DynamicTheme.getButtonTextColor(colorScheme),
                              padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                              side: DynamicTheme.getButtonBorderSide(colorScheme),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
}

class _ShareOptionButton extends StatelessWidget {
  final String? iconUrl;
  final IconData? icon;
  final String label;
  final VoidCallback onTap;
  final AppColorScheme colorScheme;

  const _ShareOptionButton({
    super.key,
    this.iconUrl,
    this.icon,
    required this.label,
    required this.onTap,
    required this.colorScheme,
  }) : assert(iconUrl != null || icon != null, 'Either iconUrl or icon must be provided');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: DynamicTheme.getCardBackgroundColor(colorScheme),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: DynamicTheme.getPrimaryIconColor(colorScheme).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Center(
              child: iconUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      child: CachedNetworkImage(
                        imageUrl: iconUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => SizedBox(
                          width: 40,
                          height: 40,
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: DynamicTheme.getPrimaryIconColor(colorScheme),
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.share,
                          size: 24,
                          color: DynamicTheme.getPrimaryIconColor(colorScheme),
                        ),
                      ),
                    )
                  : Icon(
                      icon,
                      size: 24,
                      color: DynamicTheme.getPrimaryIconColor(colorScheme),
                    ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: DynamicTheme.getPrimaryTextColor(colorScheme).withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
