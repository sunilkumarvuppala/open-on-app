import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:openon_app/core/constants/app_constants.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/theme/color_scheme.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:openon_app/core/models/countdown_share_models.dart';

/// Identity Lock Card
/// 
/// Shows a mysterious, ambiguous placeholder for anonymous sender identity.
/// Creates emotional curiosity and mystery - different from precise letter lock.
/// Displays progressive identity hints if available.
class IdentityLockCard extends ConsumerStatefulWidget {
  final Capsule capsule;
  final AppColorScheme colorScheme;
  
  const IdentityLockCard({
    super.key,
    required this.capsule,
    required this.colorScheme,
  });
  
  @override
  ConsumerState<IdentityLockCard> createState() => IdentityLockCardState();
}

// Public state class so it can be accessed from parent
class IdentityLockCardState extends ConsumerState<IdentityLockCard> with TickerProviderStateMixin {

  // Siri-style wave animations (3 waves)
  late List<AnimationController> _waveControllers;
  late List<Animation<double>> _waveAnimations;
  late AnimationController _sublineController;
  late AnimationController _hintFadeController;
  int _currentSublineIndex = 0;
  Timer? _sublineTimer;
  Timer? _hintPollTimer;
  
  String? _currentHintText;
  int? _currentHintIndex;
  bool _hintVisible = false;
  
  // Share functionality
  bool _isCreatingShare = false;
  String? _cachedShareUrl;
  ValueNotifier<String?>? _shareUrlNotifier;
  bool _isPreviewDialogOpen = false;
  bool _isPreviewOpen = false;
  
  static const int _waveCount = 3;
  static const Duration _waveDuration = Duration(milliseconds: 2000);
  static const Duration _waveDelay = Duration(milliseconds: 400);
  
  // Progressive hints (non-identifying, emotional)
  final List<String> _sublines = [
    'They chose to stay anonymous.',
    'When they\'re ready...',
    'Their name will appear soon.',
    'Some things arrive in their own time.',
  ];
  
  @override
  void initState() {
    super.initState();
    
    // Initialize Siri-style wave animations
    _waveControllers = List.generate(_waveCount, (index) {
      return AnimationController(
        vsync: this,
        duration: _waveDuration,
      );
    });
    
    _waveAnimations = _waveControllers.map((controller) {
      // Each wave expands from 0.8 to 1.4 scale
      // Opacity fades from 0.6 to 0.0 as it expands
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOut,
        ),
      );
    }).toList();
    
    // Start waves with staggered delays (Siri effect)
    for (int i = 0; i < _waveCount; i++) {
      Future.delayed(_waveDelay * i, () {
        if (mounted) {
          _waveControllers[i].repeat();
        }
      });
    }
    
    // Subline rotation animation
    _sublineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    // Hint fade-in animation
    _hintFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Rotate sublines every 4 seconds
    _sublineTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        _sublineController.forward(from: 0.0).then((_) {
          if (mounted) {
            setState(() {
              _currentSublineIndex = (_currentSublineIndex + 1) % _sublines.length;
            });
            _sublineController.reverse();
          }
        });
      }
    });
    
    // Fetch initial hint and poll for updates
    _fetchHint();
    _hintPollTimer = Timer.periodic(AppConstants.hintPollInterval, (timer) {
      if (mounted) {
        _fetchHint();
      }
    });
  }
  
  Future<void> _fetchHint() async {
    if (!mounted || widget.capsule.isRevealed) return;
    
    try {
      final repo = ref.read(capsuleRepositoryProvider);
      final hintResult = await repo.getCurrentHint(widget.capsule.id);
      
      if (mounted && hintResult != null) {
        final hintText = hintResult['hint_text'] as String?;
        final hintIndex = hintResult['hint_index'] as int?;
        if (hintText != null && hintText != _currentHintText) {
          setState(() {
            _currentHintText = hintText;
            _currentHintIndex = hintIndex;
            _hintVisible = true;
          });
          // Fade in the hint
          _hintFadeController.forward(from: 0.0);
        }
      } else if (mounted && hintResult == null && _currentHintText != null) {
        // Hint was removed or no longer eligible
        setState(() {
          _currentHintText = null;
          _currentHintIndex = null;
          _hintVisible = false;
        });
        _hintFadeController.reverse();
      }
    } catch (e, stackTrace) {
      Logger.error('Failed to fetch hint', error: e, stackTrace: stackTrace);
      // Silently fail - hints are optional
    }
  }
  
  @override
  void dispose() {
    for (final controller in _waveControllers) {
      controller.dispose();
    }
    _sublineController.dispose();
    _hintFadeController.dispose();
    _sublineTimer?.cancel();
    _hintPollTimer?.cancel();
    try {
      _shareUrlNotifier?.dispose();
    } catch (e) {
      Logger.debug('Error disposing share URL notifier: $e');
    }
    _shareUrlNotifier = null;
    super.dispose();
  }
  
  String _getVagueCountdown(Duration timeUntilReveal) {
    final hours = timeUntilReveal.inHours;
    final minutes = timeUntilReveal.inMinutes;
    
    // Very vague at first (more than 2 hours) - whisper-like
    if (hours >= 2) {
      if (hours >= 24) {
        return 'When the time comes';
      } else if (hours >= 12) {
        return 'Not much longer';
      } else if (hours >= 6) {
        return 'Soon';
      } else {
        return 'Soon';
      }
    }
    // Getting more precise (1-2 hours) - still whisper
    else if (hours >= 1) {
      return 'Not much longer';
    }
    // More precise (30-60 minutes) - whisper
    else if (minutes >= 30) {
      return 'Soon';
    }
    // Very precise (under 30 minutes) - still whisper but slightly more aware
    else if (minutes >= 10) {
      return 'Soon';
    }
    // Most precise (under 10 minutes) - whisper with slight urgency
    else if (minutes >= 1) {
      return 'Almost there';
    }
    // Almost there - whisper
    else {
      return 'When the time comes';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeUntilReveal = widget.capsule.timeUntilReveal;
    final vagueCountdown = _getVagueCountdown(timeUntilReveal);
    
    return Center(
      child: SizedBox(
        width: AppConstants.identityLockCardWidth,
        child: Stack(
          children: [
            Opacity(
              opacity: 0.90, // Reduced opacity (10% reduction) - feels like fog hovering
              child: Container(
                width: AppConstants.identityLockCardWidth,
                constraints: BoxConstraints(
                  minWidth: AppConstants.identityLockCardWidth,
                  maxWidth: AppConstants.identityLockCardWidth,
                ),
                padding: EdgeInsets.all(AppTheme.spacingLg),
                decoration: BoxDecoration(
                  // Softer gradient with more transparency - background shows through
                  gradient: LinearGradient(
                    colors: [
                      DynamicTheme.getCardBackgroundColor(widget.colorScheme).withOpacity(0.25),
                      DynamicTheme.getCardBackgroundColor(widget.colorScheme).withOpacity(0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  // Softer edges - less card-like
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl), // Larger radius for softer feel
                  // Remove border - no hard edges
                ),
                child: IgnorePointer(
                  // Remove tap-ability sense - it's just visual presence
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
          // Siri-style pulsing waves
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Multiple expanding waves (Siri effect)
                ...List.generate(_waveCount, (index) {
                  return AnimatedBuilder(
                    animation: _waveAnimations[index],
                    builder: (context, child) {
                      final progress = _waveAnimations[index].value;
                      // Scale from 0.8 to 1.4
                      final scale = 0.8 + (progress * 0.6);
                      // Opacity fades from 0.6 to 0.0
                      final opacity = 0.6 * (1.0 - progress);
                      
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.colorScheme.primary1.withOpacity(opacity),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.colorScheme.primary1.withOpacity(opacity * 0.5),
                                blurRadius: 20 * (1 - progress * 0.5),
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
                // Center icon (static)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.colorScheme.primary1.withOpacity(0.4),
                        widget.colorScheme.primary1.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.colorScheme.primary1.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.help_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: AppTheme.spacingMd),
          
          // Title - slightly more transparent to let background show through
          Text(
            'Someone wrote this.',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: DynamicTheme.getPrimaryTextColor(widget.colorScheme).withOpacity(0.95),
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: AppTheme.spacingSm),
          
          // Rotating subline
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  )),
                  child: child,
                ),
              );
            },
            child: Text(
              _sublines[_currentSublineIndex],
              key: ValueKey(_currentSublineIndex),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: DynamicTheme.getSecondaryTextColor(widget.colorScheme).withOpacity(0.65),
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              softWrap: true,
            ),
          ),
          
          SizedBox(height: AppTheme.spacingMd),
          
          // Current hint from backend (if available)
          if (_currentHintText != null && _hintVisible) ...[
            AnimatedBuilder(
              animation: _hintFadeController,
              builder: (context, child) {
                final hintPrefix = _currentHintIndex != null ? 'Hint ${_currentHintIndex}: ' : '';
                return Opacity(
                  opacity: _hintFadeController.value,
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                      vertical: AppTheme.spacingSm,
                    ),
                    decoration: BoxDecoration(
                      color: DynamicTheme.getCardBackgroundColor(widget.colorScheme)
                          .withOpacity(0.3),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: DynamicTheme.getPrimaryTextColor(widget.colorScheme)
                            .withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '$hintPrefix${_currentHintText!}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: DynamicTheme.getPrimaryTextColor(widget.colorScheme)
                            .withOpacity(0.85),
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) * 1.05,
                        height: 1.4,
                        letterSpacing: 0.3,
                        shadows: [
                          Shadow(
                            color: DynamicTheme.getPrimaryTextColor(widget.colorScheme)
                                .withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: AppTheme.spacingMd),
          ],
          
          SizedBox(height: AppTheme.spacingMd),
          
          // Vague countdown - whisper-like, not a label
          Text(
            vagueCountdown,
            style: theme.textTheme.bodySmall?.copyWith(
              // Smaller, lower opacity, less contrast - feels like a whisper
              fontSize: (theme.textTheme.bodySmall?.fontSize ?? 12) * 0.9, // 10% smaller
              color: DynamicTheme.getSecondaryTextColor(widget.colorScheme).withOpacity(0.5), // Lower opacity
              fontWeight: FontWeight.w400, // Lighter weight (was w500)
              letterSpacing: 0.2, // Less letter spacing
              fontStyle: FontStyle.italic, // Softer, more whisper-like
            ),
            textAlign: TextAlign.center,
          ),
                    ],
                  ),
                ),
              ),
            ),
            // Share button - positioned at top right
            Positioned(
              top: AppTheme.spacingSm,
              right: AppTheme.spacingSm,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _handleShare,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: Container(
                    padding: EdgeInsets.all(AppTheme.spacingXs),
                    decoration: BoxDecoration(
                      color: DynamicTheme.getCardBackgroundColor(widget.colorScheme).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: DynamicTheme.getPrimaryIconColor(widget.colorScheme).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.share_outlined,
                      size: 20,
                      color: DynamicTheme.getPrimaryIconColor(widget.colorScheme).withOpacity(0.8),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
  
  // Public method to trigger share from parent widget
  void share() {
    _handleShare();
  }
  
  void _handleShare() async {
    if (!mounted) return;
    
    // Prevent concurrent share creation
    if (_isCreatingShare) {
      return;
    }
    
    // Check if letter can be shared:
    // 1. Letter is locked (not yet opened), OR
    // 2. Letter is opened, anonymous, and not yet revealed
    final canShare = widget.capsule.isLocked || 
                     (widget.capsule.isAnonymous && 
                      !widget.capsule.isRevealed && 
                      widget.capsule.openedAt != null);
    
    if (!canShare) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.capsule.isRevealed 
              ? 'Anonymous sender has been revealed. Letter cannot be shared.'
              : 'This letter cannot be shared',
            style: TextStyle(
              color: DynamicTheme.getSnackBarTextColor(widget.colorScheme),
            ),
          ),
          backgroundColor: DynamicTheme.getSnackBarBackgroundColor(widget.colorScheme),
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
            letterId: widget.capsule.id,
            shareType: ShareType.story,
          ),
        );
        
        // Check again after async operation
        if (!_isPreviewDialogOpen || !mounted) {
          Logger.debug('Dialog closed during share creation, aborting');
          return;
        }
        
        // Wait for the controller state to update (with timeout)
        int attempts = 0;
        CreateShareResult? result;
        while (attempts < 10 && mounted && _isPreviewDialogOpen) {
          await Future.delayed(Duration(milliseconds: 50));
          final resultAsync = ref.read(createCountdownShareControllerProvider);
          if (resultAsync.hasValue && !resultAsync.isLoading) {
            result = resultAsync.asData?.value;
            if (result != null) {
              break;
            }
          }
          attempts++;
        }
        
        // If still no result, try reading directly
        if (result == null) {
          final resultAsync = ref.read(createCountdownShareControllerProvider);
          result = resultAsync.asData?.value;
          
          // Check for errors
          if (resultAsync.hasError) {
            Logger.error('Share creation has error: ${resultAsync.error}');
            errorMessage = 'Unable to create share. Please try again.';
            if (mounted && _isPreviewDialogOpen) {
              _isPreviewDialogOpen = false;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    errorMessage,
                    style: TextStyle(
                      color: DynamicTheme.getSnackBarTextColor(widget.colorScheme),
                    ),
                  ),
                  backgroundColor: DynamicTheme.getSnackBarBackgroundColor(widget.colorScheme),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  duration: Duration(seconds: 4),
                ),
              );
            }
            return;
          }
        }
        
        Logger.debug('Share creation result: success=${result?.success}, errorCode=${result?.errorCode}, errorMessage=${result?.errorMessage}, shareUrl=${result?.shareUrl}');
        
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
          // Handle case where result is null
          if (result == null) {
            Logger.error('Share creation result is null - this should not happen');
            errorMessage = 'Unable to create share. Please try again.';
            if (mounted && _isPreviewDialogOpen) {
              _isPreviewDialogOpen = false;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    errorMessage,
                    style: TextStyle(
                      color: DynamicTheme.getSnackBarTextColor(widget.colorScheme),
                    ),
                  ),
                  backgroundColor: DynamicTheme.getSnackBarBackgroundColor(widget.colorScheme),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  duration: Duration(seconds: 4),
                ),
              );
            }
            return;
          }
          
          final errorCode = result.errorCode ?? 'UNKNOWN';
          final rawErrorMessage = result.errorMessage ?? '';
          
          Logger.error('Share creation failed - errorCode: $errorCode, rawMessage: $rawErrorMessage');
          Logger.error('Full result object: success=${result.success}, shareUrl=${result.shareUrl}');
          Logger.error('Error code type: ${errorCode.runtimeType}, Error message type: ${rawErrorMessage.runtimeType}');
          
          // Always use user-friendly error messages (never show technical errors)
          if (errorCode == 'EXCEPTION' || errorCode == 'UNKNOWN' || errorCode.isEmpty) {
            // Try to extract error code from the raw error message
            final lowerMessage = rawErrorMessage.toLowerCase();
            Logger.debug('Parsing error message for patterns: $lowerMessage');
            
            if (lowerMessage.contains('letter_not_found') || lowerMessage.contains('404')) {
              errorMessage = 'Letter not found.';
            } else if (lowerMessage.contains('letter_not_locked')) {
              errorMessage = 'This letter cannot be shared at this time.';
            } else if (lowerMessage.contains('letter_already_revealed') || lowerMessage.contains('already been revealed')) {
              errorMessage = 'Anonymous sender has been revealed. Letter cannot be shared.';
            } else if (lowerMessage.contains('letter_already_opened') && !lowerMessage.contains('anonymous')) {
              errorMessage = 'This letter has already been opened and cannot be shared.';
            } else if (lowerMessage.contains('not authenticated') || lowerMessage.contains('unauthorized') || lowerMessage.contains('auth.uid()')) {
              errorMessage = 'Please sign in to create a share.';
            } else if (lowerMessage.contains('not_authorized') || lowerMessage.contains('not authorized')) {
              errorMessage = 'You do not have permission to share this letter.';
            } else if (lowerMessage.contains('daily_limit') || lowerMessage.contains('limit reached')) {
              errorMessage = 'You have reached your daily limit of 5 shares.';
            } else if (lowerMessage.contains('network') || lowerMessage.contains('connection') || lowerMessage.contains('timeout') || lowerMessage.contains('socket')) {
              errorMessage = 'Network error. Please check your connection and try again.';
            } else if (lowerMessage.contains('function') || lowerMessage.contains('edge') || lowerMessage.contains('not available') || lowerMessage.contains('deployed')) {
              errorMessage = 'Share feature is temporarily unavailable. Please try again later.';
            } else if (rawErrorMessage.isNotEmpty) {
              // If we have an error message but can't parse it, show a generic message
              // but log the actual error for debugging
              Logger.error('Unhandled error message pattern: $rawErrorMessage');
              errorMessage = 'Unable to create share. Please try again.';
            } else {
              errorMessage = 'Unable to create share. Please try again.';
            }
          } else if (errorCode == 'FUNCTION_NOT_FOUND' || errorCode == 'UNEXPECTED_ERROR') {
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
          } else if (errorCode == 'INVALID_RESPONSE' || errorCode == 'INVALID_REQUEST' || errorCode == 'INVALID_STATE') {
            errorMessage = 'Unable to create share. Please try again.';
          } else {
            // Generic error - always use user-friendly message
            errorMessage = 'Unable to create share. Please try again.';
          }
          
          Logger.error('Share creation failed: code=$errorCode, rawMessage=$rawErrorMessage, userMessage=$errorMessage');
          Logger.error('Result object: ${result.toString()}');
          
          // Show error and close preview (only if dialog is still open)
          if (mounted && _isPreviewDialogOpen) {
            _isPreviewDialogOpen = false;
            Navigator.of(context).pop(); // Close loading preview
            
            // For debugging: show the actual error code and message in development
            final debugMessage = errorCode == 'UNKNOWN' || errorCode == 'EXCEPTION' || errorCode == 'UNEXPECTED_ERROR'
                ? '$errorMessage\n\n(Debug: Code=$errorCode, Msg=$rawErrorMessage)'
                : errorMessage;
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  debugMessage,
                  style: TextStyle(
                    color: DynamicTheme.getSnackBarTextColor(widget.colorScheme),
                  ),
                ),
                backgroundColor: DynamicTheme.getSnackBarBackgroundColor(widget.colorScheme),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                duration: Duration(seconds: 6), // Longer duration for debug message
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errorMessage,
                style: TextStyle(
                  color: DynamicTheme.getSnackBarTextColor(widget.colorScheme),
                ),
              ),
              backgroundColor: DynamicTheme.getSnackBarBackgroundColor(widget.colorScheme),
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
    
    _isPreviewOpen = true;
    
    // Get theme colors
    final gradientStart = widget.colorScheme.primary1;
    final gradientEnd = widget.colorScheme.primary2;
    final timeUntilReveal = widget.capsule.timeUntilReveal;
    final vagueCountdown = _getVagueCountdown(timeUntilReveal);
    final displayTitle = widget.capsule.label.isNotEmpty ? widget.capsule.label : "Something is waiting";
    
    // Use ValueNotifier for dynamic updates if shareUrl is null initially
    final ValueNotifier<String?> notifierToUse;
    final bool isOneTimeNotifier;
    if (shareUrl == null) {
      // Create or reuse the shared notifier for loading state
      _shareUrlNotifier ??= ValueNotifier<String?>(null);
      notifierToUse = _shareUrlNotifier!;
      isOneTimeNotifier = false;
    } else {
      // For existing shareUrl, create a one-time notifier (will be disposed on dialog close)
      notifierToUse = ValueNotifier<String?>(shareUrl);
      isOneTimeNotifier = true;
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
                                'Share Anonymous Letter',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, color: Colors.white),
                                onPressed: () {
                                  _isPreviewDialogOpen = false;
                                  _isCreatingShare = false;
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
                                  // Anonymous card preview
                                  Container(
                                    padding: EdgeInsets.all(AppTheme.spacingXl),
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
                                        // Siri-style pulsing waves (animated, same as main card)
                                        SizedBox(
                                          width: 80,
                                          height: 80,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              // Multiple expanding waves (Siri effect)
                                              ...List.generate(_waveCount, (index) {
                                                return AnimatedBuilder(
                                                  animation: _waveAnimations[index],
                                                  builder: (context, child) {
                                                    final progress = _waveAnimations[index].value;
                                                    // Scale from 0.8 to 1.4
                                                    final scale = 0.8 + (progress * 0.6);
                                                    // Opacity fades from 0.6 to 0.0
                                                    final opacity = 0.6 * (1.0 - progress);
                                                    
                                                    return Transform.scale(
                                                      scale: scale,
                                                      child: Container(
                                                        width: 80,
                                                        height: 80,
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          border: Border.all(
                                                            color: Colors.white.withOpacity(opacity),
                                                            width: 2,
                                                          ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.white.withOpacity(opacity * 0.5),
                                                              blurRadius: 20 * (1 - progress * 0.5),
                                                              spreadRadius: 2,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              }),
                                              // Center icon (static)
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: RadialGradient(
                                                    colors: [
                                                      Colors.white.withOpacity(0.4),
                                                      Colors.white.withOpacity(0.2),
                                                      Colors.transparent,
                                                    ],
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.white.withOpacity(0.3),
                                                      blurRadius: 15,
                                                      spreadRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                                child: Center(
                                                  child: Container(
                                                    width: 32,
                                                    height: 32,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Colors.white.withOpacity(0.15),
                                                      border: Border.all(
                                                        color: Colors.white.withOpacity(0.25),
                                                        width: 1.5,
                                                      ),
                                                    ),
                                                    child: Icon(
                                                      Icons.help_outline,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: AppTheme.spacingMd),
                                        // Title (capsule label)
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
                                        // Subline
                                        Text(
                                          'Someone wrote this.',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.65),
                                            fontSize: 14,
                                            fontStyle: FontStyle.italic,
                                            height: 1.4,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: AppTheme.spacingSm),
                                        // Rotating subline
                                        Text(
                                          _sublines[_currentSublineIndex],
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.65),
                                            fontSize: 14,
                                            fontStyle: FontStyle.italic,
                                            height: 1.4,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        // Current hint if available
                                        if (_currentHintText != null && _hintVisible) ...[
                                          SizedBox(height: AppTheme.spacingMd),
                                          Container(
                                            margin: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: AppTheme.spacingMd,
                                              vertical: AppTheme.spacingSm,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.2),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              '${_currentHintIndex != null ? 'Hint ${_currentHintIndex}: ' : ''}${_currentHintText!}',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.9),
                                                fontSize: 13,
                                                fontStyle: FontStyle.italic,
                                                fontWeight: FontWeight.w500,
                                                height: 1.4,
                                                letterSpacing: 0.3,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black.withOpacity(0.2),
                                                    blurRadius: 4,
                                                    offset: Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                        SizedBox(height: AppTheme.spacingMd),
                                        // Vague countdown
                                        Text(
                                          vagueCountdown,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.5),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w400,
                                            letterSpacing: 0.2,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: AppTheme.spacingLg),
                                  // Loading or share URL
                                  if (isCurrentlyLoading) ...[
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                    SizedBox(height: AppTheme.spacingMd),
                                    Text(
                                      'Creating share link...',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ] else ...[
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
                                                await _shareMessage(currentShareUrl, buttonContext);
                                              },
                                              colorScheme: widget.colorScheme,
                                            ),
                                            SizedBox(width: AppTheme.spacingSm),
                                            _ShareOptionButton(
                                              key: GlobalKey(),
                                              iconUrl: AppConstants.tiktokIconUrl,
                                              label: 'TikTok',
                                              onTap: () async {
                                                await _shareMessage(currentShareUrl, buttonContext);
                                              },
                                              colorScheme: widget.colorScheme,
                                            ),
                                            SizedBox(width: AppTheme.spacingSm),
                                            _ShareOptionButton(
                                              key: GlobalKey(),
                                              iconUrl: AppConstants.whatsappIconUrl,
                                              label: 'WhatsApp',
                                              onTap: () async {
                                                await _shareMessage(currentShareUrl, buttonContext);
                                              },
                                              colorScheme: widget.colorScheme,
                                            ),
                                            SizedBox(width: AppTheme.spacingSm),
                                            _ShareOptionButton(
                                              icon: Icons.message,
                                              label: 'Text',
                                              onTap: () async {
                                                await _shareMessage(currentShareUrl, buttonContext);
                                              },
                                              colorScheme: widget.colorScheme,
                                            ),
                                            SizedBox(width: AppTheme.spacingSm),
                                            _ShareOptionButton(
                                              icon: Icons.link,
                                              label: 'Copy Link',
                                              onTap: () async {
                                                await Clipboard.setData(ClipboardData(text: currentShareUrl));
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Link copied to clipboard'),
                                                      duration: Duration(seconds: 2),
                                                    ),
                                                  );
                                                }
                                              },
                                              colorScheme: widget.colorScheme,
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
      if (!mounted) return;
      
      _isPreviewOpen = false;
      _isPreviewDialogOpen = false;
      _isCreatingShare = false;
      
      // Only dispose one-time notifiers
      if (isOneTimeNotifier) {
        try {
          notifierToUse.dispose();
        } catch (e) {
          Logger.debug('Error disposing one-time notifier: $e');
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
          final colorScheme = widget.colorScheme;
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
}

// Share option button widget
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

