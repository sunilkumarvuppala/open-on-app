import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:openon_app/core/constants/app_constants.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/router/app_router.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:openon_app/core/utils/validation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:openon_app/core/data/supabase_config.dart';
import 'package:openon_app/features/capsule/letter_reply_composer.dart';
import 'package:openon_app/features/capsule/emotional_reply_reveal_screen.dart';
import 'package:openon_app/core/widgets/common_widgets.dart';
import 'package:openon_app/animations/widgets/sparkle_particle_engine.dart';

class OpenedLetterScreen extends ConsumerStatefulWidget {
  final Capsule capsule;
  
  const OpenedLetterScreen({super.key, required this.capsule});
  
  @override
  ConsumerState<OpenedLetterScreen> createState() => _OpenedLetterScreenState();
}

class _OpenedLetterScreenState extends ConsumerState<OpenedLetterScreen>
    with TickerProviderStateMixin {
  Capsule? _currentCapsule;
  Timer? _revealCountdownTimer;
  StreamSubscription? _realtimeSubscription;
  LetterReply? _reply;
  bool _isLoadingReply = false;
  bool _showReplyAnimation = false;
  bool _replySkipped = false; // Track if receiver skipped the reply option
  late AnimationController _headerFadeController;
  late Animation<double> _headerFadeAnimation;
  late AnimationController _messageFadeController;
  late Animation<double> _messageFadeAnimation;
  late AnimationController _envelopeOpacityController;
  late Animation<double> _envelopeOpacityAnimation;
  late AnimationController _replyFadeController;
  late Animation<double> _replyFadeAnimation;
  
  // Icon animation state
  bool _showSenderAvatar = false;
  Timer? _iconToggleTimer;
  
  @override
  void initState() {
    super.initState();
    _currentCapsule = widget.capsule;
    // Check if reply was skipped for this letter (will be cleared when letter is opened)
    _checkSkippedState();
    
    // Load reply if exists
    _loadReply();
    
    // Initialize fade-in animation for header icons
    _headerFadeController = AnimationController(
      vsync: this,
      duration: AppConstants.openedLetterHeaderFadeDuration,
    );
    _headerFadeAnimation = CurvedAnimation(
      parent: _headerFadeController,
      curve: Curves.easeIn,
    );
    
    // Initialize fade-in animation for message content
    _messageFadeController = AnimationController(
      vsync: this,
      duration: AppConstants.openedLetterMessageFadeDuration,
    );
    _messageFadeAnimation = CurvedAnimation(
      parent: _messageFadeController,
      curve: Curves.easeIn,
    );
    
    // Initialize envelope icon opacity animation (reduces opacity after title appears)
    _envelopeOpacityController = AnimationController(
      vsync: this,
      duration: AppConstants.openedLetterEnvelopeOpacityDuration,
    );
    // Animate from 1.0 (full opacity) to reduced opacity after title appears
    _envelopeOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: AppConstants.openedLetterEnvelopeOpacityEnd,
    ).animate(CurvedAnimation(
      parent: _envelopeOpacityController,
      curve: Curves.easeOut,
    ));
    
    // Start header fade-in after delay
    Future.delayed(AppConstants.openedLetterHeaderFadeDelay, () {
      if (mounted) {
        _headerFadeController.forward();
      }
    });
    
    // Start message fade-in after delay (moment of silence)
    Future.delayed(AppConstants.openedLetterMessageFadeDelay, () {
      if (mounted) {
        _messageFadeController.forward();
      }
    });
    
    // Reduce envelope icon opacity after title appears
    Future.delayed(AppConstants.openedLetterEnvelopeOpacityDelay, () {
      if (mounted) {
        _envelopeOpacityController.forward();
      }
    });
    
    // Initialize reply section fade-in animation
    _replyFadeController = AnimationController(
      vsync: this,
      duration: AppConstants.openedLetterReplyFadeDuration,
    );
    _replyFadeAnimation = CurvedAnimation(
      parent: _replyFadeController,
      curve: Curves.easeIn,
    );
    
    // Start reply fade-in after message appears
    Future.delayed(AppConstants.openedLetterReplyFadeDelay, () {
      if (mounted) {
        _replyFadeController.forward();
      }
    });
    
    // Start icon toggle timer
    _startIconToggleTimer();
    
    // Refresh capsule data immediately to get latest reveal_at if just opened
    // This ensures we have the correct reveal_at timestamp set by the backend
    _refreshCapsule();
    
    // Set up realtime subscription for reveal updates
    if (widget.capsule.isAnonymous && !widget.capsule.isRevealed) {
      _setupRealtimeSubscription();
      _startRevealCountdownTimer();
    }
    
    // Load reply if exists (only called once here, not duplicated)
    _loadReply();
  }
  
  Future<void> _loadReply() async {
    setState(() {
      _isLoadingReply = true;
    });
    
    try {
      final repo = ref.read(letterReplyRepositoryProvider);
      final reply = await repo.getReplyByLetterId(widget.capsule.id);
      
      if (mounted) {
        setState(() {
          _reply = reply;
          _isLoadingReply = false;
          
          // Don't automatically show animation - user will click "See Reply" button
        });
      }
    } catch (e, stackTrace) {
      Logger.error('Failed to load reply', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _isLoadingReply = false;
        });
      }
    }
  }
  
  void _handleReplySent() {
    // Reload reply after sending (no animation for receiver)
    // Reply window will close automatically when reply exists
    _loadReply();
  }
  
  Future<void> _checkSkippedState() async {
    // Clear skipped state when letter is opened (so they can respond next time)
    // This allows them to skip now but respond later when they open the letter again
    try {
      // Validate and sanitize capsule ID for security
      final validatedCapsuleId = Validation.validateAndSanitizeCapsuleId(widget.capsule.id);
      final prefs = await SharedPreferences.getInstance();
      final skipKey = Validation.sanitizeSharedPreferencesKey('reply_skipped_$validatedCapsuleId');
      final wasSkipped = prefs.getBool(skipKey) ?? false;
      
      if (wasSkipped) {
        // Clear the skip state so composer shows again next time
        await prefs.remove(skipKey);
        // Reset the skip state in memory as well
        if (mounted) {
          setState(() {
            _replySkipped = false;
          });
        }
      }
    } catch (e, stackTrace) {
      // Log error but don't block UI - skip state will just be session-based
      Logger.error('Failed to check skip state', error: e, stackTrace: stackTrace);
    }
  }
  
  Future<void> _handleReplySkipped() async {
    // Hide the reply composer when receiver skips
    // Persist skip state so it stays hidden until next time they open the letter
    setState(() {
      _replySkipped = true;
    });
    
    try {
      // Validate and sanitize capsule ID for security
      final validatedCapsuleId = Validation.validateAndSanitizeCapsuleId(widget.capsule.id);
      final prefs = await SharedPreferences.getInstance();
      final skipKey = Validation.sanitizeSharedPreferencesKey('reply_skipped_$validatedCapsuleId');
      await prefs.setBool(skipKey, true);
    } catch (e, stackTrace) {
      Logger.error('Failed to save skip state', error: e, stackTrace: stackTrace);
      // Silently fail - skip state will just be session-based
    }
  }
  
  void _handleSeeReply() {
    // Show animation screen when user clicks "See Reply" button
    if (_reply != null) {
      setState(() {
        _showReplyAnimation = true;
      });
    }
  }
  
  void _handleAnimationComplete() {
    if (mounted) {
      setState(() {
        _showReplyAnimation = false;
      });
      // Reload reply to get updated seen timestamps (but don't trigger animation)
      _loadReply();
    }
  }
  
  void _startIconToggleTimer() {
    // Toggle between letter icon and sender avatar at configured interval
    _iconToggleTimer = Timer.periodic(AppConstants.openedLetterIconToggleInterval, (timer) {
      if (mounted) {
        setState(() {
          _showSenderAvatar = !_showSenderAvatar;
        });
      } else {
        timer.cancel();
      }
    });
  }
  
  @override
  void dispose() {
    _revealCountdownTimer?.cancel();
    _realtimeSubscription?.cancel();
    _iconToggleTimer?.cancel();
    _headerFadeController.dispose();
    _messageFadeController.dispose();
    _envelopeOpacityController.dispose();
    _replyFadeController.dispose();
    super.dispose();
  }
  
  void _setupRealtimeSubscription() {
    try {
      final supabase = SupabaseConfig.client;
      _realtimeSubscription = supabase
          .from('capsules')
          .stream(primaryKey: ['id'])
          .eq('id', widget.capsule.id)
          .listen((data) {
            if (data.isNotEmpty) {
              final updated = data.first;
              if (updated['sender_revealed_at'] != null) {
                // Sender was revealed, refresh capsule
                Logger.info('Sender revealed for capsule ${widget.capsule.id}');
                _refreshCapsule();
              }
            }
          });
    } catch (e, stackTrace) {
      Logger.error('Failed to set up realtime subscription', error: e, stackTrace: stackTrace);
    }
  }
  
  void _startRevealCountdownTimer() {
    // Use _currentCapsule if available, otherwise widget.capsule
    final capsule = _currentCapsule ?? widget.capsule;
    if (capsule.revealAt == null) return;
    
    _revealCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      // Get current capsule (may have been refreshed)
      final currentCapsule = _currentCapsule ?? widget.capsule;
      if (currentCapsule.revealAt == null) {
        timer.cancel();
        return;
      }
      
      final now = DateTime.now();
      if (now.isAfter(currentCapsule.revealAt!) || now.isAtSameMomentAs(currentCapsule.revealAt!)) {
        // Reveal time has passed, refresh capsule
        timer.cancel();
        _refreshCapsule();
      } else {
        // Update UI to show countdown
        setState(() {});
      }
    });
  }
  
  Future<void> _refreshCapsule() async {
    try {
      final repo = ref.read(capsuleRepositoryProvider);
      final updatedCapsule = await repo.getCapsuleById(widget.capsule.id);
      if (updatedCapsule != null && mounted) {
        setState(() {
          _currentCapsule = updatedCapsule;
        });
        
        // If anonymous and not revealed, restart countdown timer with new reveal_at
        if (updatedCapsule.isAnonymous && !updatedCapsule.isRevealed && updatedCapsule.revealAt != null) {
          _revealCountdownTimer?.cancel();
          _startRevealCountdownTimer();
        }
      }
    } catch (e, stackTrace) {
      Logger.error('Failed to refresh capsule', error: e, stackTrace: stackTrace);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final capsule = _currentCapsule ?? widget.capsule;
    final openedAt = capsule.openedAt ?? DateTime.now();
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    // Use soft gradient for envelope icon container (similar to share cards)
    final envelopeGradient = DynamicTheme.softGradient(colorScheme);
    // Use warm gradient for background (similar to share cards)
    final backgroundGradient = DynamicTheme.warmGradient(colorScheme);
    final isAnonymous = capsule.isAnonymous;
    final isRevealed = capsule.isRevealed;
    final revealCountdown = capsule.revealCountdownText;
    
    // Check if current user is receiver
    final userAsync = ref.watch(currentUserProvider);
    final currentUserId = userAsync.asData?.value?.id;
    // If user is not the sender, they must be the receiver
    // (backend only allows viewing capsules you sent or received)
    final isReceiver = currentUserId != null && currentUserId != capsule.senderId;
    // Check if this is a self letter (sender and receiver are the same)
    final isSelfLetter = capsule.senderId == capsule.receiverId;
    
    // Show animation if needed (only once)
    if (_showReplyAnimation && _reply != null) {
      return EmotionalReplyRevealScreen(
        key: ValueKey('reply_animation_${_reply!.id}'), // Unique key to prevent recreation
        reply: _reply!,
        isReceiver: isReceiver,
        onComplete: _handleAnimationComplete,
      );
    }
    
    return Scaffold(
      body: Stack(
        children: [
          // Background layer with star dust - subtle and quiet, doesn't steal focus from letter
          SparkleParticleEngine(
            particleCount: AppConstants.starDustParticleCount,
            mode: SparkleMode.drift, // Gentle upward drift
            primaryColor: colorScheme.accent, // Base color (opacity controlled by multiplier)
            secondaryColor: colorScheme.primary1, // Base color (opacity controlled by multiplier)
            opacityMultiplier: AppConstants.starDustOpacityMultiplier,
            speedMultiplier: AppConstants.starDustSpeedMultiplier,
            child: Container(
              decoration: BoxDecoration(
                gradient: backgroundGradient,
              ),
            ),
          ),
          // Content layer on top (transparent background to show star dust, but message content blocks it)
          SafeArea(
            child: Column(
          children: [
            // Header (faded in after delay, reduced prominence)
            AnimatedBuilder(
              animation: _headerFadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _headerFadeAnimation.value * AppConstants.openedLetterHeaderOpacity,
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spacingMd),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: DynamicTheme.getPrimaryIconColor(colorScheme),
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: DynamicTheme.getCardBackgroundColor(colorScheme).withOpacity(AppConstants.openedLetterCardBackgroundOpacity),
                            foregroundColor: DynamicTheme.getPrimaryIconColor(colorScheme),
                          ),
                          onPressed: () {
                            // Navigate directly to receiver home
                            // This skips the opening animation screen and provides better UX
                            context.go(Routes.receiverHome);
                          },
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.share,
                            color: DynamicTheme.getPrimaryIconColor(colorScheme),
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: DynamicTheme.getCardBackgroundColor(colorScheme).withOpacity(AppConstants.openedLetterCardBackgroundOpacity),
                            foregroundColor: DynamicTheme.getPrimaryIconColor(colorScheme),
                          ),
                          onPressed: () {
                            final colorScheme = ref.read(selectedColorSchemeProvider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppConstants.shareFeatureComingSoon,
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
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            // Letter content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Envelope header - toggles between letter icon and sender avatar every 3 seconds
                    // Uses theme-based gradient similar to share cards
                    // Opacity reduces after title appears
                    Center(
                      child: AnimatedBuilder(
                        animation: _envelopeOpacityAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _envelopeOpacityAnimation.value,
                            child: Container(
                              padding: EdgeInsets.all(AppTheme.spacingMd),
                              decoration: BoxDecoration(
                                gradient: envelopeGradient,
                                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                // Add subtle shadow for depth (similar to share cards)
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary1.withOpacity(AppConstants.openedLetterShadowOpacity),
                                    blurRadius: AppTheme.glowBlurRadiusMedium,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: AnimatedSwitcher(
                                duration: AppConstants.openedLetterIconToggleTransitionDuration,
                                transitionBuilder: (Widget child, Animation<double> animation) {
                                  return FadeTransition(
                                    opacity: CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeInOut, // Smooth, slow fade
                                    ),
                                    child: child,
                                  );
                                },
                                child: _showSenderAvatar
                                    ? Container(
                                        key: const ValueKey('avatar'),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          // Add gradient overlay for avatar when shown
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white.withOpacity(AppConstants.openedLetterAvatarGradientOpacity),
                                              Colors.transparent,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: UserAvatar(
                                          imageUrl: capsule.senderAvatar.isNotEmpty ? capsule.senderAvatar : null,
                                          name: capsule.senderName,
                                          size: AppConstants.openedLetterEnvelopeIconSize,
                                        ),
                                      )
                                    : Icon(
                                        Icons.mail,
                                        key: const ValueKey('mail'),
                                        size: AppConstants.openedLetterEnvelopeIconSize,
                                        color: DynamicTheme.getPrimaryIconColor(colorScheme),
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    SizedBox(height: AppTheme.spacingLg),
                    
                    // Opened date (moved before title)
                    Center(
                      child: Column(
                        children: [
                          // Only show "From" line for receiver (not sender)
                          if (isReceiver) ...[
                            Text(
                              'From ${capsule.displaySenderName}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: DynamicTheme.getSecondaryTextColor(colorScheme),
                                  ),
                            ),
                            SizedBox(height: AppTheme.spacingXs),
                          ],
                          // Show reveal countdown if anonymous and not yet revealed
                          if (isAnonymous && !isRevealed && revealCountdown.isNotEmpty) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingMd,
                                vertical: AppTheme.spacingXs,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary1.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                border: Border.all(
                                  color: colorScheme.primary1.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: AppConstants.openedLetterCountdownIconSize,
                                    color: colorScheme.primary1,
                                  ),
                                  SizedBox(width: AppTheme.spacingXs),
                                  Text(
                                    revealCountdown,
                                    style: TextStyle(
                                      fontSize: AppConstants.openedLetterDateFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.primary1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: AppTheme.spacingXs),
                          ],
                          // Friendly timestamp (smaller, lower opacity, secondary position)
                          Text(
                            _formatOpenedDate(openedAt),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(AppConstants.openedLetterSecondaryTextOpacity),
                                  fontSize: AppConstants.openedLetterDateFontSize,
                                ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: AppTheme.spacingSm), // Reduced spacing above title
                    
                    // Label (title - moved after opened date) - Tangerine font, large and centered
                    Center(
                      child: Text(
                        capsule.label,
                        style: GoogleFonts.tangerine(
                          fontSize: AppConstants.openedLetterTitleFontSize,
                          fontWeight: FontWeight.w700,
                          color: DynamicTheme.getPrimaryTextColor(colorScheme),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    SizedBox(height: AppConstants.openedLetterTitleSpacing), // Minimal spacing below title
                    
                    // Soft subtitle for self letters (emotional framing)
                    if (isSelfLetter && !isReceiver) ...[
                      SizedBox(height: AppTheme.spacingXs),
                      Text(
                        'Something you left for yourself',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(AppConstants.openedLetterSecondaryTextOpacityMedium),
                              fontStyle: FontStyle.italic,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppTheme.spacingXs),
                      Text(
                        'You wrote this for a future you.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(AppConstants.openedLetterSecondaryTextOpacity),
                              fontStyle: FontStyle.italic,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    
                    SizedBox(height: AppTheme.spacingSm), // Minimal gap between title and message content
                    
                    // Letter content (page-like, not bubble) - fades in after moment of silence
                    AnimatedBuilder(
                      animation: _messageFadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _messageFadeAnimation.value,
                          child: Opacity(
                            opacity: AppConstants.openedLetterMessageContainerOpacity,
                            child: Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(
                                minHeight: AppConstants.openedLetterMessageMinHeight,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingMd, // Reduced horizontal padding to make it wider
                                vertical: AppTheme.spacingXl * AppConstants.openedLetterMessageVerticalPadding,
                              ),
                              decoration: BoxDecoration(
                                // Subtle vertical gradient - top lighter, bottom darker
                                // Creates "lit by atmosphere" feeling, not sitting on top
                                // Reduced color contrast - less blue, more neutral
                                gradient: LinearGradient(
                                  colors: [
                                    // Top: lighter, more neutral version (blend with white)
                                    Color.lerp(
                                      Color.lerp(envelopeGradient.colors[0], Colors.white, AppConstants.openedLetterGradientBlendTop) ?? envelopeGradient.colors[0],
                                      Colors.white, AppConstants.openedLetterGradientBlendTopSecondary
                                    ) ?? envelopeGradient.colors[0],
                                    // Bottom: slightly darker, more neutral version
                                    Color.lerp(
                                      Color.lerp(envelopeGradient.colors[1], Colors.white, AppConstants.openedLetterGradientBlendBottom) ?? envelopeGradient.colors[1],
                                      const Color(AppConstants.openedLetterPaperGrayColor), AppConstants.openedLetterGradientBlendDark
                                    ) ?? envelopeGradient.colors[1],
                                  ],
                                  begin: Alignment.topCenter, // Vertical gradient
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd), // Smaller radius for less bubble feel
                                // Removed shadow to eliminate card/bubble feeling
                              ),
                              child: Text(
                                capsule.content,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      height: AppConstants.openedLetterContentLineHeight * 1.3, // Significantly increased line height
                                      fontSize: AppConstants.openedLetterContentFontSize,
                                      // Higher contrast text color based on background gradient
                                      // Use darker text for better readability on lighter gradient background
                                      color: colorScheme.isDarkTheme 
                                          ? Colors.white.withOpacity(AppConstants.openedLetterSeeReplyTextOpacity)
                                          : const Color(AppConstants.openedLetterTextColorDark),
                                      fontWeight: FontWeight.w400,
                                    ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    
                    // Photo if present
                    if (capsule.photoUrl != null) ...[
                      SizedBox(height: AppTheme.spacingLg),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        child: capsule.photoUrl!.startsWith('http')
                            ? Image.network(
                                capsule.photoUrl!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(capsule.photoUrl!),
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ],
                    
                    SizedBox(height: AppTheme.spacingMd), // Reduced gap between message content and reply section
                    
                    // Reply section (if receiver and no reply yet, or if reply exists) - fades in
                    AnimatedBuilder(
                      animation: _replyFadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _replyFadeAnimation.value,
                          child: Builder(
                            builder: (context) {
                              final userAsync = ref.watch(currentUserProvider);
                              final currentUserId = userAsync.asData?.value?.id;
                              // If user is not the sender, they must be the receiver
                              // (backend only allows viewing capsules you sent or received)
                              final isReceiver = currentUserId != null && currentUserId != capsule.senderId;
                              
                              if (isReceiver && !_isLoadingReply) {
                                if (_reply == null && !_replySkipped) {
                                  // Show composer if no reply and not skipped
                                  return Column(
                                    children: [
                                      SizedBox(height: AppTheme.spacingMd), // Reduced spacing
                                      LetterReplyComposer(
                                        letterId: capsule.id,
                                        onReplySent: _handleReplySent,
                                        onSkip: _handleReplySkipped,
                                      ),
                                    ],
                                  );
                                } else {
                                  // Receiver has sent reply or skipped - don't show anything
                                  // Reply is for sender to see, not receiver
                                  return const SizedBox.shrink();
                                }
                              } else if (!isReceiver && _reply != null) {
                                // Sender viewing reply - show "See Reply" button
                                // Receiver's reply should be visible to sender, not receiver
                                return Column(
                                  children: [
                                    SizedBox(height: AppTheme.spacingSm), // Reduced spacing
                                    _buildSeeReplyButton(context, colorScheme),
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        );
                      },
                    ),
                    
                    SizedBox(height: AppTheme.spacingXl),
                  ],
                ),
              ),
            ),
          ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSeeReplyButton(BuildContext context, dynamic colorScheme) {
    if (_reply == null) return const SizedBox.shrink();
    
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subtle copy above button to make it feel earned (whisper-like)
        Padding(
          padding: EdgeInsets.only(bottom: AppTheme.spacingSm),
          child: Text(
            "They've left a short response.",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(AppConstants.openedLetterWhisperTextOpacity),
              fontStyle: FontStyle.italic,
              fontSize: theme.textTheme.bodyMedium?.fontSize != null 
                  ? theme.textTheme.bodyMedium!.fontSize! * AppConstants.opacityNearlyOpaque // Slightly smaller for whisper effect
                  : null,
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleSeeReply,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                vertical: AppTheme.spacingMd,
                horizontal: AppTheme.spacingLg,
              ),
              backgroundColor: colorScheme.primary1.withOpacity(AppConstants.openedLetterSeeReplyButtonOpacity),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              elevation: 0,
            ),
            child: Text(
              'See how it was received',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500, // Slightly lighter weight (was w600)
                color: Colors.white.withOpacity(AppConstants.openedLetterSeeReplyTextOpacity),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  /// Format opened date in a friendly, less system-like way
  String _formatOpenedDate(DateTime openedAt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final openedDate = DateTime(openedAt.year, openedAt.month, openedAt.day);
    final difference = today.difference(openedDate).inDays;
    
    // If opened today
    if (difference == 0) {
      final timeDiff = now.difference(openedAt);
      if (timeDiff.inMinutes < 1) {
        return 'Opened just now';
      } else if (timeDiff.inHours < 1) {
        return 'Opened ${timeDiff.inMinutes} minute${timeDiff.inMinutes != 1 ? 's' : ''} ago';
      } else {
        return 'Opened today';
      }
    }
    // If opened yesterday
    else if (difference == 1) {
      return 'Opened yesterday';
    }
    // If opened within last week
    else if (difference < 7) {
      return 'Opened ${difference} day${difference != 1 ? 's' : ''} ago';
    }
    // If opened this year, show month and day
    else if (openedAt.year == now.year) {
      return 'Opened ${DateFormat('MMM d').format(openedAt)}';
    }
    // Otherwise show month, day, and year
    else {
      return 'Opened ${DateFormat('MMM d, y').format(openedAt)}';
    }
  }
}
