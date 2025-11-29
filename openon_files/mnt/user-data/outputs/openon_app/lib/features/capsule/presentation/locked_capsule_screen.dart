import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/models.dart';

class LockedCapsuleScreen extends ConsumerStatefulWidget {
  final String capsuleId;

  const LockedCapsuleScreen({
    super.key,
    required this.capsuleId,
  });

  @override
  ConsumerState<LockedCapsuleScreen> createState() => _LockedCapsuleScreenState();
}

class _LockedCapsuleScreenState extends ConsumerState<LockedCapsuleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for envelope
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Update countdown every second
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _shareCountdown(Capsule capsule) async {
    try {
      final dateFormat = DateFormat('MMMM d, yyyy');
      final message = '''
🔒 A special letter is waiting...

"${capsule.label}"

Unlocks on ${dateFormat.format(capsule.unlockTime)}

Made with OpenOn ♥
''';

      await Share.share(
        message,
        subject: 'A time-locked letter is waiting for you',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _attemptOpen(Capsule capsule) {
    if (capsule.isUnlocked) {
      context.go('/capsule/${capsule.id}/opening');
    } else {
      // Show tooltip
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Text(
                  'Not yet... come back in ${_formatDuration(capsule.timeUntilUnlock)} ♥',
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.deepPurple,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays == 1 ? '' : 's'}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes == 1 ? '' : 's'}';
    } else {
      return 'a few seconds';
    }
  }

  @override
  Widget build(BuildContext context) {
    final capsuleAsync = ref.watch(capsuleProvider(widget.capsuleId));

    return Scaffold(
      body: capsuleAsync.when(
        data: (capsule) {
          if (capsule == null) {
            return const ErrorDisplay(message: 'Capsule not found');
          }

          return Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.dreamyGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // App Bar
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.white),
                          onPressed: () => _shareCountdown(capsule),
                        ),
                      ],
                    ),
                  ),
                  
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingXl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Sender Info
                          Text(
                            'From ${capsule.recipientName}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          
                          const SizedBox(height: AppTheme.spacingLg),
                          
                          // Envelope with Pulse Animation
                          GestureDetector(
                            onTap: () => _attemptOpen(capsule),
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: 1.0 + (_pulseController.value * 0.05),
                                  child: Container(
                                    width: 200,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.1),
                                          blurRadius: 20 + (_pulseController.value * 10),
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        const Icon(
                                          Icons.mail,
                                          size: 100,
                                          color: Colors.white,
                                        ),
                                        if (!capsule.isUnlocked)
                                          const Positioned(
                                            bottom: 40,
                                            child: Icon(
                                              Icons.lock,
                                              size: 32,
                                              color: Colors.white,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          
                          const SizedBox(height: AppTheme.spacingXl),
                          
                          // Label
                          Text(
                            capsule.label,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: AppTheme.spacingXl),
                          
                          if (capsule.isUnlocked) ...[
                            // Ready to open
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingXl,
                                vertical: AppTheme.spacingLg,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.softGold,
                                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.celebration,
                                    size: 48,
                                    color: AppTheme.textDark,
                                  ),
                                  const SizedBox(height: AppTheme.spacingMd),
                                  Text(
                                    'Ready to open!',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spacingSm),
                                  Text(
                                    'Tap the envelope above',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // Countdown Display
                            _CountdownCircle(
                              unlockTime: capsule.unlockTime,
                              timeRemaining: capsule.timeUntilUnlock,
                            ),
                            
                            const SizedBox(height: AppTheme.spacingLg),
                            
                            Text(
                              'A special message is waiting...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          
                          const Spacer(),
                          
                          // Share Button
                          OutlinedButton.icon(
                            onPressed: () => _shareCountdown(capsule),
                            icon: const Icon(Icons.share),
                            label: const Text('Share Countdown'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white, width: 2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingXl,
                                vertical: AppTheme.spacingMd,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.dreamyGradient,
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        error: (error, stack) => ErrorDisplay(
          message: 'Failed to load capsule',
          onRetry: () => ref.invalidate(capsuleProvider(widget.capsuleId)),
        ),
      ),
    );
  }
}

class _CountdownCircle extends StatelessWidget {
  final DateTime unlockTime;
  final Duration timeRemaining;

  const _CountdownCircle({
    required this.unlockTime,
    required this.timeRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    
    final days = timeRemaining.inDays;
    final hours = timeRemaining.inHours.remainder(24);
    final minutes = timeRemaining.inMinutes.remainder(60);
    final seconds = timeRemaining.inSeconds.remainder(60);

    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.1),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Opens in',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          
          if (days > 0)
            _CountdownUnit(value: days, label: days == 1 ? 'day' : 'days')
          else if (hours > 0)
            _CountdownUnit(value: hours, label: hours == 1 ? 'hour' : 'hours')
          else if (minutes > 0)
            _CountdownUnit(value: minutes, label: minutes == 1 ? 'min' : 'mins')
          else
            _CountdownUnit(value: seconds, label: seconds == 1 ? 'sec' : 'secs'),
          
          const SizedBox(height: AppTheme.spacingLg),
          
          Text(
            dateFormat.format(unlockTime),
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            timeFormat.format(unlockTime),
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownUnit extends StatelessWidget {
  final int value;
  final String label;

  const _CountdownUnit({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}
