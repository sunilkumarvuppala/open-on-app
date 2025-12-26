import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openon_app/core/data/api_client.dart';
import 'package:openon_app/core/data/api_config.dart';
import 'package:openon_app/core/router/app_router.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:openon_app/core/errors/app_exceptions.dart';
import 'package:openon_app/core/providers/providers.dart';

/// Preview screen for letter invites (public, no auth required)
/// 
/// Shows a calm, minimal preview with countdown to open time.
/// When open time is reached, prompts user to create account.
class InvitePreviewScreen extends ConsumerStatefulWidget {
  final String inviteToken;
  
  const InvitePreviewScreen({
    super.key,
    required this.inviteToken,
  });
  
  @override
  ConsumerState<InvitePreviewScreen> createState() => _InvitePreviewScreenState();
}

class _InvitePreviewScreenState extends ConsumerState<InvitePreviewScreen> {
  Map<String, dynamic>? _inviteData;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _countdownTimer;
  
  @override
  void initState() {
    super.initState();
    _loadInviteData();
  }
  
  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _loadInviteData() async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.get(
        ApiConfig.getInvitePreview(widget.inviteToken),
        includeAuth: false, // Public endpoint
      );
      
      setState(() {
        _inviteData = response;
        _isLoading = false;
      });
      
      // Start countdown timer if not unlocked
      if (_inviteData != null && !(_inviteData!['is_unlocked'] as bool? ?? false)) {
        _startCountdownTimer();
      }
    } catch (e, stackTrace) {
      Logger.error('Failed to load invite preview', error: e, stackTrace: stackTrace);
      setState(() {
        _errorMessage = e is AppException 
            ? e.message 
            : 'Unable to load invite. Please check the link and try again.';
        _isLoading = false;
      });
    }
  }
  
  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Recalculate time remaining
          final unlocksAt = _inviteData?['unlocks_at'];
          if (unlocksAt != null) {
            try {
              final unlockTime = DateTime.parse(unlocksAt).toLocal();
              final now = DateTime.now();
              if (unlockTime.isBefore(now) || unlockTime.isAtSameMomentAs(now)) {
                _inviteData!['is_unlocked'] = true;
                timer.cancel();
              }
            } catch (e) {
              Logger.warning('Failed to parse unlock time: $e');
            }
          }
        });
      }
    });
  }
  
  String _formatCountdown() {
    if (_inviteData == null) return '';
    
    final isUnlocked = _inviteData!['is_unlocked'] as bool? ?? false;
    if (isUnlocked) {
      return 'Ready to open';
    }
    
    final days = _inviteData!['days_remaining'] as int? ?? 0;
    final hours = _inviteData!['hours_remaining'] as int? ?? 0;
    final minutes = _inviteData!['minutes_remaining'] as int? ?? 0;
    final seconds = _inviteData!['seconds_remaining'] as int? ?? 0;
    
    if (days > 0) {
      return '$days day${days != 1 ? 's' : ''} ${hours}h';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
  
  void _handleCreateAccount() {
    // Navigate to signup with invite token
    context.push('${Routes.signup}?invite_token=${widget.inviteToken}');
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.secondary2,
        body: Center(
          child: CircularProgressIndicator(
            color: colorScheme.primary1,
          ),
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: colorScheme.secondary2,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacingXl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                SizedBox(height: AppTheme.spacingLg),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    fontSize: 16,
                    color: DynamicTheme.getPrimaryTextColor(colorScheme),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    final isUnlocked = _inviteData!['is_unlocked'] as bool? ?? false;
    final title = _inviteData!['title'] as String? ?? 'Something meaningful is waiting for you';
    final theme = _inviteData!['theme'] as Map<String, dynamic>?;
    final gradientStart = theme != null 
        ? Color(int.parse(theme['gradient_start'] as String? ?? 'FF000000', radix: 16))
        : colorScheme.primary1;
    final gradientEnd = theme != null
        ? Color(int.parse(theme['gradient_end'] as String? ?? 'FF000000', radix: 16))
        : colorScheme.primary2;
    
    return Scaffold(
      backgroundColor: colorScheme.secondary2,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [gradientStart, gradientEnd],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppTheme.spacingXl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Envelope icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.mail_outline,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  
                  SizedBox(height: AppTheme.spacingXl),
                  
                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: AppTheme.spacingMd),
                  
                  // Subtitle
                  Text(
                    'Something meaningful is waiting for you.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: AppTheme.spacingXl),
                  
                  // Countdown or unlock message
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingLg,
                      vertical: AppTheme.spacingMd,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      isUnlocked ? 'Ready to open' : _formatCountdown(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: AppTheme.spacingXl),
                  
                  // Create account button (shown when unlocked)
                  if (isUnlocked)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _handleCreateAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: gradientStart,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Create an account to unlock this letter',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  
                  // Info text (shown when locked)
                  if (!isUnlocked)
                    Text(
                      'Create an account when it\'s time to open',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

