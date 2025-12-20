import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:intl/intl.dart';

class LockedCapsuleScreen extends ConsumerStatefulWidget {
  final Capsule capsule;
  
  const LockedCapsuleScreen({super.key, required this.capsule});
  
  @override
  ConsumerState<LockedCapsuleScreen> createState() => _LockedCapsuleScreenState();
}

class _LockedCapsuleScreenState extends ConsumerState<LockedCapsuleScreen> {
  Timer? _countdownTimer;
  
  @override
  void initState() {
    super.initState();
    
    // Update countdown every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }
  
  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
  
  void _handleShare() async {
    try {
      // TODO: Generate and share beautiful countdown image
      final message = '⏰ I have a special letter unlocking on ${DateFormat('MMMM d, y').format(widget.capsule.unlockAt)}!\n\nMade with OpenOn 💌';
      
      await Share.share(message);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to share'),
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
  
  void _handleTapEnvelope() {
    if (widget.capsule.canOpen) {
      // Navigate to opening animation
      context.push(
        '/capsule/${widget.capsule.id}/opening',
        extra: widget.capsule,
      );
    } else {
      // Show tooltip
      final colorScheme = ref.read(selectedColorSchemeProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Not yet… come back in ${widget.capsule.countdownText} ♥',
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
    final capsule = widget.capsule;
    final canOpen = capsule.canOpen;
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final gradient = DynamicTheme.dreamyGradient(colorScheme);
    
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
                    if (!canOpen)
                      IconButton(
                        icon: Icon(
                          Icons.share, 
                          color: DynamicTheme.getPrimaryIconColor(
                            ref.read(selectedColorSchemeProvider),
                          ),
                        ),
                        onPressed: _handleShare,
                      ),
                  ],
                ),
              ),
              
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
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
                                if (!canOpen)
                                  CircularProgressIndicator(
                                    value: 1.0 - (capsule.timeUntilUnlock.inSeconds / capsule.unlockAt.difference(capsule.createdAt).inSeconds),
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
