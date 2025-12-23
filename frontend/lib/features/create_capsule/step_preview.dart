import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/theme/color_scheme.dart';
import 'package:openon_app/core/widgets/common_widgets.dart';

class StepPreview extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  
  const StepPreview({
    super.key,
    required this.onBack,
    required this.onSubmit,
  });
  
  @override
  ConsumerState<StepPreview> createState() => _StepPreviewState();
}

class _StepPreviewState extends ConsumerState<StepPreview>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _arrowController;
  late Animation<double> _arrowAnimation;
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    // Animation that repeats every 2 seconds
    _arrowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    // Animation from 0.0 to 1.0 for arrow movement
    _arrowAnimation = CurvedAnimation(
      parent: _arrowController,
      curve: Curves.easeInOut,
    );
  }
  
  @override
  void dispose() {
    _arrowController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final draft = ref.watch(draftCapsuleProvider);
    final recipient = draft.recipient!;
    final unlockAt = draft.unlockAt!;
    final label = draft.label?.isNotEmpty == true
        ? draft.label!
        : 'A special letter';
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final dreamyGradient = DynamicTheme.dreamyGradient(colorScheme);
    
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready to seal this letter?',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: DynamicTheme.getPrimaryTextColor(colorScheme),
                      ),
                ),
                SizedBox(height: AppTheme.spacingSm),
                Text(
                  'Once sent, it will open only at the chosen time.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: DynamicTheme.getSecondaryTextColor(colorScheme),
                      ),
                ),
                SizedBox(height: AppTheme.spacingMd),
                
                // Envelope preview
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppTheme.spacingLg),
                  decoration: BoxDecoration(
                    gradient: dreamyGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary1.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Envelope icon and recipient avatar side by side with animated arrows
                      SizedBox(
                        height: 60,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Envelope icon
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: DynamicTheme.getCardBackgroundColor(colorScheme, opacity: AppTheme.opacityHigh),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.mail_outline,
                                size: 30,
                                color: DynamicTheme.getPrimaryIconColor(colorScheme),
                              ),
                            ),
                            // Animated arrows area
                            SizedBox(
                              width: AppTheme.spacingMd + 60, // Space between icons + avatar width
                              height: 60,
                              child: Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  // Animated arrows moving from letter icon to avatar
                                  AnimatedBuilder(
                                    animation: _arrowAnimation,
                                    builder: (context, child) {
                                      // Calculate arrow positions
                                      // Start from left (letter icon edge), end at right (avatar edge)
                                      final spacing = AppTheme.spacingMd;
                                      final startX = 0.0;
                                      final endX = spacing + 60.0; // Full distance
                                      final arrowX = startX + (endX - startX) * _arrowAnimation.value;
                                      
                                      // Opacity: fade in at start, fade out at end
                                      final opacity = _arrowAnimation.value < 0.2
                                          ? (_arrowAnimation.value / 0.2).clamp(0.0, 1.0)
                                          : _arrowAnimation.value > 0.8
                                              ? ((1.0 - _arrowAnimation.value) / 0.2).clamp(0.0, 1.0)
                                              : 1.0;
                                      
                                      // Second arrow delay (increased for more visible gap)
                                      final secondArrowDelay = 0.5;
                                      final secondArrowProgress = (_arrowAnimation.value - secondArrowDelay).clamp(0.0, 1.0) / (1.0 - secondArrowDelay);
                                      
                                      return IgnorePointer(
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            // First arrow
                                            if (opacity > 0.1)
                                              Positioned(
                                                left: arrowX - 8,
                                                child: Opacity(
                                                  opacity: opacity,
                                                  child: Icon(
                                                    Icons.arrow_forward,
                                                    size: 18,
                                                    color: DynamicTheme.getPrimaryTextColor(colorScheme),
                                                  ),
                                                ),
                                              ),
                                            // Second arrow (slightly delayed)
                                            if (secondArrowProgress > 0 && secondArrowProgress < 1.0)
                                              Positioned(
                                                left: startX + (endX - startX) * secondArrowProgress - 8,
                                                child: Opacity(
                                                  opacity: (1.0 - secondArrowProgress.abs()) * 0.8,
                                                  child: Icon(
                                                    Icons.arrow_forward,
                                                    size: 16,
                                                    color: DynamicTheme.getPrimaryTextColor(colorScheme).withOpacity(0.8),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            // Recipient avatar
                            UserAvatar(
                              name: recipient.name,
                              imageUrl: recipient.avatar.isNotEmpty ? recipient.avatar : null,
                              size: 60,
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: AppTheme.spacingSm),
                      
                      // Label
                      Text(
                        label,
                        style: TextStyle(
                          color: DynamicTheme.getPrimaryTextColor(colorScheme),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: AppTheme.spacingSm),
                      
                      // To/From
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: DynamicTheme.getSecondaryTextColor(colorScheme, opacity: AppTheme.opacityFull),
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: RichText(
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: TextStyle(
                                  color: DynamicTheme.getSecondaryTextColor(colorScheme, opacity: AppTheme.opacityFull),
                                  fontSize: 14,
                                ),
                                children: [
                                  const TextSpan(text: 'To: '),
                                  TextSpan(
                                    text: recipient.username != null && recipient.username!.isNotEmpty
                                        ? '${recipient.name} (@${recipient.username})'
                                        : recipient.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppTheme.spacingXs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: DynamicTheme.getSecondaryTextColor(colorScheme, opacity: AppTheme.opacityFull),
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: RichText(
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              text: TextSpan(
                                style: TextStyle(
                                  color: DynamicTheme.getSecondaryTextColor(colorScheme, opacity: AppTheme.opacityFull),
                                  fontSize: 12,
                                ),
                                children: [
                                  const TextSpan(text: 'Unlocks On: '),
                                  TextSpan(
                                    text: DateFormat('EEEE, MMMM d, y \'at\' h:mm a').format(unlockAt),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (draft.isAnonymous) ...[
                        SizedBox(height: AppTheme.spacingXs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.visibility_off_outlined,
                              size: 14,
                              color: DynamicTheme.getSecondaryTextColor(colorScheme, opacity: AppTheme.opacityFull),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Anonymous',
                              style: TextStyle(
                                color: DynamicTheme.getSecondaryTextColor(colorScheme, opacity: AppTheme.opacityFull),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                SizedBox(height: AppTheme.spacingMd),
                
                // Details card (only show if there's additional info like photo or anonymous)
                if (draft.photoPath != null || draft.isAnonymous) ...[
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spacingMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (draft.photoPath != null) ...[
                            _buildDetailRow(
                              context,
                              icon: Icons.photo_outlined,
                              label: 'Photo',
                              value: 'Included',
                              primaryColor: colorScheme.primary1,
                              colorScheme: colorScheme,
                            ),
                          ],
                          if (draft.photoPath != null && draft.isAnonymous) ...[
                            Divider(height: AppTheme.spacingXl),
                          ],
                          if (draft.isAnonymous) ...[
                            _buildDetailRow(
                              context,
                              icon: Icons.visibility_off_outlined,
                              label: 'Anonymous',
                              value: _getRevealDelayText(draft.revealDelaySeconds ?? 21600),
                              primaryColor: colorScheme.primary1,
                              colorScheme: colorScheme,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingMd),
                ],
                
                SizedBox(height: AppTheme.spacingSm),
                
                // Letter preview
                Text(
                  'Letter Preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: DynamicTheme.getPrimaryTextColor(colorScheme),
                      ),
                ),
                SizedBox(height: AppTheme.spacingSm),
                // Letter preview - matches writing area styling
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    // Subtle gradient for paper-like texture - matches writing area with reduced brightness
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        DynamicTheme.getCardBackgroundColor(colorScheme, opacity: AppTheme.opacityLow), // Reduced brightness
                        DynamicTheme.getCardBackgroundColor(colorScheme, opacity: AppTheme.opacityLow).withOpacity(0.7), // Reduced bottom-right brightness
                      ],
                      stops: const [0.0, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(
                      color: DynamicTheme.getButtonBorderColor(colorScheme).withOpacity(0.1), // Further reduced contrast
                      width: 1, // Thinner border
                    ),
                    // Very subtle shadow for depth without boxiness
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.isDarkTheme
                            ? Colors.black.withOpacity(0.1)
                            : Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias, // Ensure background fills to border
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingLg), // Match writing area padding
                    child: Text(
                      draft.content ?? '',
                      style: TextStyle(
                        color: DynamicTheme.getInputTextColor(colorScheme).withOpacity(0.9), // Slightly reduced brightness to match canvas feel
                        fontSize: 16,
                        height: 1.6, // Match writing area line height
                      ),
                    ),
                  ),
                ),
                
                if (draft.photoPath != null) ...[
                  SizedBox(height: AppTheme.spacingLg),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: Image.file(
                      File(draft.photoPath!),
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        // Navigation buttons
        Container(
          padding: EdgeInsets.only(
            left: AppTheme.spacingLg,
            right: AppTheme.spacingLg,
            top: AppTheme.spacingSm,
            bottom: AppTheme.spacingMd,
          ),
          decoration: BoxDecoration(
            color: DynamicTheme.getNavBarBackgroundColor(colorScheme),
            boxShadow: [
              BoxShadow(
                color: DynamicTheme.getNavBarShadowColor(colorScheme),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                    side: BorderSide(
                      color: DynamicTheme.getOutlinedButtonBorderColor(colorScheme),
                    ),
                    foregroundColor: DynamicTheme.getOutlinedButtonTextColor(colorScheme),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                  ),
                  child: const Text('Back'),
                ),
              ),
              SizedBox(width: AppTheme.spacingMd),
              Expanded(
                flex: 2,
                child: _CeremonialSendButton(
                  onPressed: widget.onSubmit,
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  String _getRevealDelayText(int seconds) {
    if (seconds == 0) return 'On open';
    final hours = seconds ~/ 3600;
    if (hours == 1) return '1 hour after opening';
    if (hours < 24) return '$hours hours after opening';
    final days = hours ~/ 24;
    if (days == 1) return '1 day after opening';
    return '$days days after opening';
  }
  
  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color primaryColor,
    required AppColorScheme colorScheme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: primaryColor),
        SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: DynamicTheme.getSecondaryTextColor(colorScheme),
                ),
              ),
              SizedBox(height: AppTheme.spacingXs),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: DynamicTheme.getPrimaryTextColor(colorScheme),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Ceremonial Send Letter button with icon animation and intentional delay
class _CeremonialSendButton extends StatefulWidget {
  final VoidCallback onPressed;
  final AppColorScheme colorScheme;
  
  const _CeremonialSendButton({
    required this.onPressed,
    required this.colorScheme,
  });
  
  @override
  State<_CeremonialSendButton> createState() => _CeremonialSendButtonState();
}

class _CeremonialSendButtonState extends State<_CeremonialSendButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  bool _isPressed = false;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Arrow slides into envelope: starts on the left, slides right into envelope
    _slideAnimation = Tween<double>(
      begin: -12.0, // Start on the left of envelope
      end: 8.0,     // Slide right into envelope center
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  Future<void> _handlePress() async {
    if (_isPressed) return;
    
    setState(() {
      _isPressed = true;
    });
    
    // Trigger icon animation
    _controller.forward();
    
    // Intentional delay (0.3-0.5s) before transition - feels ceremonial, not laggy
    await Future.delayed(const Duration(milliseconds: 400));
    
    if (mounted) {
      widget.onPressed();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isPressed ? null : _handlePress,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.colorScheme.primary1,
        foregroundColor: DynamicTheme.getButtonTextColor(widget.colorScheme),
        padding: EdgeInsets.symmetric(
          vertical: AppTheme.spacingLg, // Taller button for ceremonial feel
          horizontal: AppTheme.spacingMd,
        ),
        minimumSize: const Size(0, 56), // Ensure minimum height
        side: DynamicTheme.getButtonBorderSide(widget.colorScheme),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              // Arrow opacity: starts at 1.0, fades as it slides into envelope
              final arrowOpacity = _isPressed 
                  ? ((_slideAnimation.value + 12.0) / 20.0).clamp(0.0, 1.0) // Fade from 1.0 to 0.0 as it slides
                  : 1.0;
              
              // Arrow position: starts on the left when not pressed, slides right when pressed
              final arrowOffset = _isPressed 
                  ? _slideAnimation.value  // Animated position (-12.0 to 8.0)
                  : -12.0;                 // Initial position (on the left)
              
              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Envelope icon (always visible)
                  Icon(
                    Icons.mail_outline,
                    size: 20,
                  ),
                  // Arrow icon (slides into envelope when pressed)
                  Transform.translate(
                    offset: Offset(arrowOffset, 0),
                    child: Opacity(
                      opacity: arrowOpacity,
                      child: Icon(
                        Icons.arrow_forward,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(width: AppTheme.spacingSm),
          const Text('Send Letter'),
        ],
      ),
    );
  }
}
