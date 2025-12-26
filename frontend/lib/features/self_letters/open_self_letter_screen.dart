import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/color_scheme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/utils/error_handler.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/constants/app_constants.dart';
import 'package:openon_app/animations/widgets/sparkle_particle_engine.dart';
import 'package:intl/intl.dart';

class OpenSelfLetterScreen extends ConsumerStatefulWidget {
  final String letterId;
  
  const OpenSelfLetterScreen({super.key, required this.letterId});
  
  @override
  ConsumerState<OpenSelfLetterScreen> createState() => _OpenSelfLetterScreenState();
}

class _OpenSelfLetterScreenState extends ConsumerState<OpenSelfLetterScreen>
    with TickerProviderStateMixin {
  SelfLetter? _letter;
  bool _isLoading = true;
  bool _isOpening = false;
  bool _reflectionDismissed = false;
  Timer? _countdownTimer;
  
  // Animation controllers for lock screen
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  late AnimationController _circlePulseController;
  late Animation<double> _circleSizeAnimation;
  late Animation<double> _lockHaloAnimation;
  
  // Pause cue options
  static const List<String> _pauseCues = [
    'Take a moment.',
    'Sit with this.',
    'Let this sink in.',
  ];
  final String _pauseCue = _pauseCues[0]; // Use first one for consistency
  
  @override
  void initState() {
    super.initState();
    
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
    _lockHaloAnimation = Tween<double>(
      begin: AppConstants.lockedCapsuleHaloOpacityMin,
      end: AppConstants.lockedCapsuleHaloOpacityMax,
    ).animate(CurvedAnimation(
      parent: _circlePulseController, // Use circle pulse controller for sync
      curve: Curves.easeInOut, // Smooth, gentle pulse
    ));
    
    _loadLetter();
    
    // Update countdown every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _letter != null && !_letter!.isOpened && _letter!.isSealed) {
        setState(() {});
      } else if (mounted && _letter != null && (_letter!.isOpened || !_letter!.isSealed)) {
        _countdownTimer?.cancel();
      }
    });
  }
  
  @override
  void dispose() {
    _countdownTimer?.cancel();
    _breathingController.dispose();
    _circlePulseController.dispose();
    super.dispose();
  }
  
  /// Calculate progress for countdown indicator (0.0 to 1.0)
  double _calculateProgress(SelfLetter letter) {
    try {
      final totalDuration = letter.scheduledOpenAt.difference(letter.createdAt);
      if (totalDuration.inSeconds <= 0) {
        return 0.0;
      }
      final timeUntilOpen = letter.timeUntilOpen;
      if (timeUntilOpen == null || timeUntilOpen.inSeconds < 0) {
        return 1.0;
      }
      final remaining = timeUntilOpen.inSeconds;
      final progress = 1.0 - (remaining / totalDuration.inSeconds);
      return progress.clamp(0.0, 1.0);
    } catch (e) {
      Logger.warning('Error calculating progress', error: e);
      return 0.0;
    }
  }
  
  /// Get formatted countdown text
  String _getCountdownText(SelfLetter letter) {
    if (letter.canOpen) return 'Ready to open!';
    
    final duration = letter.timeUntilOpen;
    if (duration == null) return 'Ready to open!';
    
    final totalSeconds = duration.inSeconds;
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final totalMinutes = totalSeconds ~/ 60;
    final minutes = (days > 0 || hours > 0) ? (totalMinutes % 60) : totalMinutes;
    
    if (days > 0) {
      return 'Opens in $days day${days != 1 ? 's' : ''}';
    } else if (hours > 0) {
      return 'Opens in $hours hour${hours != 1 ? 's' : ''}';
    } else if (totalSeconds >= 60) {
      return 'Opens in $minutes minute${minutes != 1 ? 's' : ''}';
    } else {
      return 'Opens soon';
    }
  }
  
  Future<void> _loadLetter() async {
    try {
      // Try to load from cached provider first (optimization)
      final lettersAsync = ref.read(selfLettersProvider);
      final letters = lettersAsync.asData?.value ?? [];
      
      SelfLetter? letter;
      try {
        letter = letters.firstWhere((l) => l.id == widget.letterId);
      } catch (_) {
        // Letter not in cache - this is fine, we'll fetch it when opening
        Logger.debug('Letter ${widget.letterId} not found in cache, will fetch on open');
      }
      
      if (letter != null) {
        setState(() {
          _letter = letter;
          _isLoading = false;
        });
      } else {
        // Letter not in cache - set loading to false, will fetch when opening
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      Logger.error('Failed to load letter', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() => _isLoading = false);
        final errorMsg = ErrorHandler.getErrorMessage(e, defaultMessage: 'Failed to load letter');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    }
  }
  
  Future<void> _openLetter() async {
    if (_isOpening || _letter == null) return;
    
    setState(() => _isOpening = true);
    
    try {
      final repo = ref.read(selfLetterRepositoryProvider);
      final openedLetter = await repo.openSelfLetter(widget.letterId);
      
      setState(() {
        _letter = openedLetter;
        _isOpening = false;
      });
      
      // Refresh the list
      ref.invalidate(selfLettersProvider);
    } catch (e, stackTrace) {
      Logger.error('Failed to open letter', error: e, stackTrace: stackTrace);
      if (mounted) {
        final errorMsg = ErrorHandler.getErrorMessage(e, defaultMessage: 'Failed to open letter');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
      setState(() => _isOpening = false);
    }
  }
  
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
    } else if (difference == 1) {
      return 'Opened yesterday';
    } else if (difference < 7) {
      return 'Opened $difference days ago';
    } else {
      return DateFormat('MMMM d, y').format(openedAt);
    }
  }
  
  Future<void> _submitReflection(String answer) async {
    if (_letter == null) return;
    
    try {
      final repo = ref.read(selfLetterRepositoryProvider);
      await repo.submitReflection(
        letterId: widget.letterId,
        answer: answer,
      );
      
      // Invalidate provider to refresh list
      ref.invalidate(selfLettersProvider);
      
      // Refresh letter from cache
      await _loadLetter();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reflection saved')),
        );
        
        // Navigate back after a moment
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) context.pop();
        });
      }
    } catch (e, stackTrace) {
      Logger.error('Failed to submit reflection', error: e, stackTrace: stackTrace);
      if (mounted) {
        final errorMsg = ErrorHandler.getErrorMessage(e, defaultMessage: 'Failed to submit reflection');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Opening Letter')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_letter == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Letter')),
        body: const Center(child: Text('Letter not found')),
      );
    }
    
    final letter = _letter!;
    
    // Note: Reflection prompt is now shown inline in the opened letter view
    
    // Show lock screen if not yet opened
    if (!letter.isOpened) {
      final canOpen = letter.canOpen;
      final gradient = DynamicTheme.dreamyGradient(colorScheme);
      final title = letter.title ?? 'Letter to myself';
      
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
                          color: DynamicTheme.getPrimaryIconColor(colorScheme),
                        ),
                        onPressed: () => context.pop(),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                
                Expanded(
                  child: Center(
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
                            // Title
                            Text(
                              title,
                              style: TextStyle(
                                color: DynamicTheme.getPrimaryTextColor(colorScheme),
                                fontSize: AppConstants.lockedCapsuleTitleFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            SizedBox(height: AppTheme.spacingMd),
                            
                            // Subtitle: "Written by you"
                            Text(
                              'Written by you',
                              style: TextStyle(
                                color: DynamicTheme.getSecondaryTextColor(colorScheme, opacity: AppTheme.opacityAlmostFull2),
                                fontSize: AppConstants.lockedCapsuleSubtitleFontSize,
                              ),
                            ),
                            
                            SizedBox(height: AppTheme.spacingLg),
                            
                            // Context text (mood, city, date)
                            if (letter.contextText.isNotEmpty)
                              Text(
                                letter.contextText,
                                style: TextStyle(
                                  color: DynamicTheme.getSecondaryTextColor(colorScheme, opacity: AppTheme.opacityAlmostFull),
                                  fontSize: AppConstants.lockedCapsuleTextFontSize,
                                  fontWeight: FontWeight.w400,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            
                            if (letter.contextText.isNotEmpty)
                              SizedBox(height: AppTheme.spacingLg),
                            
                            // Envelope with countdown - fixed size container
                            SizedBox(
                              width: AppConstants.lockedCapsuleEnvelopeContainerSize,
                              height: AppConstants.lockedCapsuleEnvelopeContainerSize,
                              child: GestureDetector(
                                onTap: canOpen ? _openLetter : null,
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
                                      if (!canOpen && letter.isSealed)
                                        CircularProgressIndicator(
                                          value: _calculateProgress(letter),
                                          strokeWidth: 6,
                                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.secondary1),
                                          backgroundColor: DynamicTheme.getCardBackgroundColor(colorScheme, opacity: AppTheme.opacityHigh),
                                        ),
                                      
                                      // Lock/envelope icon with breathing effect
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
                                                // Subtle halo effect
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
                                _getCountdownText(letter),
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
                                'Opens on ${DateFormat('MMMM d, y \'at\' h:mm a').format(letter.scheduledOpenAt)}',
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
              ],
            ),
          ),
        ),
      );
    }
    
    // Show opened letter content
    // Use soft gradient for envelope icon container (similar to share cards)
    final envelopeGradient = DynamicTheme.softGradient(colorScheme);
    // Use warm gradient for background (similar to share cards)
    final backgroundGradient = DynamicTheme.warmGradient(colorScheme);
    
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
          // Content layer on top
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => context.pop(),
                        color: DynamicTheme.getPrimaryIconColor(colorScheme),
                      ),
                      const Spacer(),
                    ],
                  ),
                  
                  const SizedBox(height: AppTheme.spacingMd),
                  
                  // Envelope icon (similar to regular opened letter)
                  Center(
                    child: Opacity(
                      opacity: AppConstants.openedLetterEnvelopeOpacityEnd,
                      child: Icon(
                        Icons.mail_outline,
                        size: AppConstants.openedLetterEnvelopeIconSize,
                        color: DynamicTheme.getPrimaryIconColor(colorScheme).withOpacity(0.6),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: AppTheme.spacingSm),
                  
                  // Opened date (friendly timestamp)
                  Center(
                    child: Text(
                      letter.openedAt != null
                          ? _formatOpenedDate(letter.openedAt!)
                          : DateFormat('MMMM d, y \'at\' h:mm a').format(letter.scheduledOpenAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(AppConstants.openedLetterSecondaryTextOpacity),
                        fontSize: AppConstants.openedLetterDateFontSize,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: AppTheme.spacingSm),
                  
                  // Title - Tangerine font, large and centered (matching regular opened letter)
                  Center(
                    child: Text(
                      letter.title ?? 'Letter to myself',
                      style: GoogleFonts.tangerine(
                        fontSize: AppConstants.openedLetterTitleFontSize,
                        fontWeight: FontWeight.w700,
                        color: DynamicTheme.getPrimaryTextColor(colorScheme),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  SizedBox(height: AppConstants.openedLetterTitleSpacing),
                  
                  // Subtitle: "Written by you"
                  Center(
                    child: Text(
                      'Written by you',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(AppConstants.openedLetterSecondaryTextOpacityMedium),
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  SizedBox(height: AppTheme.spacingXl),
                  
                  // Context strip (small, muted): City · Date · Mood emoji
                  _buildContextStrip(letter, colorScheme, theme),
                  
                  const SizedBox(height: AppTheme.spacingXl),
                  
                  // Letter body - paper-like card with gradient (matching regular opened letter)
                  Opacity(
                    opacity: AppConstants.openedLetterMessageContainerOpacity,
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(
                        minHeight: AppConstants.openedLetterMessageMinHeight,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd,
                        vertical: AppTheme.spacingXl * AppConstants.openedLetterMessageVerticalPadding,
                      ),
                      decoration: BoxDecoration(
                        // Subtle vertical gradient - top lighter, bottom darker
                        // Creates "lit by atmosphere" feeling, not sitting on top
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
                      child: letter.content != null
                          ? Text(
                              letter.content!,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                height: AppConstants.openedLetterContentLineHeight * 1.3, // Significantly increased line height
                                fontSize: AppConstants.openedLetterContentFontSize,
                                // Higher contrast text color based on background gradient
                                // Use darker text for better readability on lighter gradient background
                                color: colorScheme.isDarkTheme 
                                    ? Colors.white.withOpacity(AppConstants.openedLetterSeeReplyTextOpacity)
                                    : const Color(AppConstants.openedLetterTextColorDark),
                                fontWeight: FontWeight.w400,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                
                const SizedBox(height: AppTheme.spacingXl),
                
                // Pause cue (very subtle)
                Center(
                  child: Text(
                    _pauseCue,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(0.6),
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingXl),
                
                // Reflection prompt (optional, dismissible)
                if (!letter.hasReflection && !_reflectionDismissed)
                  _ReflectionPromptCard(
                    letter: letter,
                    onSubmit: _submitReflection,
                    onDismiss: () => setState(() => _reflectionDismissed = true),
                  ),
                
                // Reflection display (if already reflected)
                if (letter.hasReflection)
                  _buildReflectionDisplay(letter, colorScheme, theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContextStrip(SelfLetter letter, AppColorScheme colorScheme, ThemeData theme) {
    final parts = <String>[];
    
    // City
    if (letter.city != null && letter.city!.isNotEmpty) {
      parts.add(letter.city!);
    }
    
    // Date
    final dateFormat = DateFormat('MMM d, yyyy');
    parts.add(dateFormat.format(letter.createdAt));
    
    // Mood emoji
    if (letter.mood != null && letter.mood!.isNotEmpty) {
      parts.add(letter.mood!);
    }
    
    if (parts.isEmpty) return const SizedBox.shrink();
    
    return Text(
      parts.join(' · '),
      style: theme.textTheme.bodySmall?.copyWith(
        color: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(0.7),
        fontSize: 12,
      ),
    );
  }
  
  Widget _buildReflectionDisplay(SelfLetter letter, AppColorScheme colorScheme, ThemeData theme) {
    if (!letter.hasReflection) return const SizedBox.shrink();
    
    // Get reflection answer text
    String reflectionText;
    Color reflectionColor;
    IconData reflectionIcon;
    
    switch (letter.reflectionAnswer) {
      case 'yes':
        reflectionText = 'Still true';
        reflectionColor = Colors.green;
        reflectionIcon = Icons.check_circle;
        break;
      case 'no':
        reflectionText = 'Changed';
        reflectionColor = Colors.orange;
        reflectionIcon = Icons.change_circle;
        break;
      case 'skipped':
        reflectionText = 'Skipped';
        reflectionColor = DynamicTheme.getSecondaryTextColor(colorScheme);
        reflectionIcon = Icons.skip_next;
        break;
      default:
        reflectionText = 'Reflected';
        reflectionColor = Colors.green;
        reflectionIcon = Icons.check_circle;
    }
    
    // Format reflection date
    String reflectionDateText = '';
    if (letter.reflectedAt != null) {
      final dateFormat = DateFormat('MMM d, yyyy');
      reflectionDateText = ' on ${dateFormat.format(letter.reflectedAt!)}';
    }
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
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
          Row(
            children: [
              Icon(
                reflectionIcon,
                color: reflectionColor,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                'Your Reflection',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: DynamicTheme.getPrimaryTextColor(colorScheme),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingMd),
          
          // Reflection answer
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingSm,
            ),
            decoration: BoxDecoration(
              color: reflectionColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: reflectionColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  reflectionIcon,
                  color: reflectionColor,
                  size: 18,
                ),
                const SizedBox(width: AppTheme.spacingXs),
                Text(
                  reflectionText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: reflectionColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Reflection date
          if (reflectionDateText.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              'Reflected$reflectionDateText',
              style: theme.textTheme.bodySmall?.copyWith(
                color: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReflectionPromptCard extends ConsumerWidget {
  final SelfLetter letter;
  final Function(String) onSubmit;
  final VoidCallback onDismiss;
  
  const _ReflectionPromptCard({
    required this.letter,
    required this.onSubmit,
    required this.onDismiss,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
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
          // Dismiss button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(0.6),
              ),
            ],
          ),
          
          // Question
          Text(
            'How does this feel to read now?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: DynamicTheme.getPrimaryTextColor(colorScheme),
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingLg),
          
          // Reflection buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => onSubmit('yes'),
                style: TextButton.styleFrom(
                  foregroundColor: DynamicTheme.getPrimaryTextColor(colorScheme),
                ),
                child: const Text('Still true'),
              ),
              TextButton(
                onPressed: () => onSubmit('no'),
                style: TextButton.styleFrom(
                  foregroundColor: DynamicTheme.getPrimaryTextColor(colorScheme),
                ),
                child: const Text('Changed'),
              ),
              TextButton(
                onPressed: () => onSubmit('skipped'),
                style: TextButton.styleFrom(
                  foregroundColor: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(AppConstants.letterReplySecondaryTextOpacity),
                ),
                child: const Text('Skip'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
