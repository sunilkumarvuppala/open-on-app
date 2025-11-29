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

class _LockedCapsuleScreenState extends ConsumerState<LockedCapsuleScreen>
    with SingleTickerProviderStateMixin {
  Timer? _countdownTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Set up pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
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
    _pulseController.dispose();
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
          const SnackBar(
            content: Text('Failed to share'),
            backgroundColor: AppColors.error,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not yet… come back in ${widget.capsule.countdownText} ♥'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final capsule = widget.capsule;
    final canOpen = capsule.canOpen;
    final progress = _calculateProgress();
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
                      icon: const Icon(Icons.arrow_back, color: AppColors.white),
                      onPressed: () => context.pop(),
                    ),
                    const Spacer(),
                    if (!canOpen)
                      IconButton(
                        icon: const Icon(Icons.share, color: AppColors.white),
                        onPressed: _handleShare,
                      ),
                  ],
                ),
              ),
              
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spacingXl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Label
                        Text(
                          capsule.label,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: AppTheme.spacingSm),
                        
                        Text(
                          'From ${capsule.senderName}',
                          style: TextStyle(
                            color: AppColors.white.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                        
                        SizedBox(height: AppTheme.spacingXl * 2),
                        
                        // Envelope with progress ring
                        GestureDetector(
                          onTap: _handleTapEnvelope,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Progress ring
                              SizedBox(
                                width: 200,
                                height: 200,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 4,
                                backgroundColor: AppColors.white.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.accent,
                                ),
                              ),
                              ),
                              
                              // Envelope icon with pulse
                              ScaleTransition(
                                scale: _pulseAnimation,
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    color: AppColors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    canOpen ? Icons.mail_outline : Icons.lock_outline,
                                    size: 70,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: AppTheme.spacingXl),
                        
                        // Countdown or ready message
                        if (canOpen) ...[
                          const Text(
                            'Ready to open!',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: AppTheme.spacingMd),
                          Text(
                            'Tap the envelope to reveal your letter',
                            style: TextStyle(
                              color: AppColors.white.withOpacity(0.9),
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ] else ...[
                          Text(
                            capsule.countdownText,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: AppTheme.spacingMd),
                          Text(
                            'Until unlock',
                            style: TextStyle(
                              color: AppColors.white.withOpacity(0.8),
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: AppTheme.spacingXl),
                          Text(
                            'Opens on ${DateFormat('MMMM d, y \'at\' h:mm a').format(capsule.unlockAt)}',
                            style: TextStyle(
                              color: AppColors.white.withOpacity(0.7),
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
                          backgroundColor: AppColors.white,
                          foregroundColor: colorScheme.primary1,
                          padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
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
  
  double _calculateProgress() {
    final now = DateTime.now();
    final total = widget.capsule.unlockAt.difference(widget.capsule.createdAt);
    final elapsed = now.difference(widget.capsule.createdAt);
    
    if (elapsed.inSeconds <= 0) return 0.0;
    if (elapsed >= total) return 1.0;
    
    return elapsed.inSeconds / total.inSeconds;
  }
}
