import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:openon_app/core/constants/app_constants.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/router/app_router.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/utils/logger.dart';

class OpenedLetterScreen extends ConsumerStatefulWidget {
  final Capsule capsule;
  
  const OpenedLetterScreen({super.key, required this.capsule});
  
  @override
  ConsumerState<OpenedLetterScreen> createState() => _OpenedLetterScreenState();
}

class _OpenedLetterScreenState extends ConsumerState<OpenedLetterScreen> {
  String? _selectedReaction;
  bool _isSendingReaction = false;
  
  @override
  void initState() {
    super.initState();
    _selectedReaction = widget.capsule.reaction;
  }
  
  Future<void> _handleReaction(String emoji) async {
    if (_isSendingReaction || _selectedReaction == emoji) return;
    
    setState(() {
      _selectedReaction = emoji;
      _isSendingReaction = true;
    });
    
    try {
      final repo = ref.read(capsuleRepositoryProvider);
      await repo.addReaction(widget.capsule.id, emoji);
      
      Logger.info('Reaction $emoji sent for capsule ${widget.capsule.id}');
      
      if (mounted) {
        final colorScheme = ref.read(selectedColorSchemeProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppConstants.reactionSentMessage} ${widget.capsule.senderName} ♥',
            ),
            backgroundColor: AppColors.success,
            duration: AppConstants.animationDurationMedium,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to send reaction',
        error: e,
        stackTrace: stackTrace,
      );
      
      // Revert reaction on error
      if (mounted) {
        setState(() => _selectedReaction = widget.capsule.reaction);
        
        final colorScheme = ref.read(selectedColorSchemeProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppConstants.failedToSendReaction,
              style: TextStyle(
                color: DynamicTheme.getSnackBarTextColor(colorScheme),
              ),
            ),
            backgroundColor: DynamicTheme.getSnackBarBackgroundColor(colorScheme),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            action: SnackBarAction(
              label: 'Retry',
              textColor: DynamicTheme.getSnackBarTextColor(colorScheme),
              onPressed: () => _handleReaction(emoji),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingReaction = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final capsule = widget.capsule;
    final openedAt = capsule.openedAt ?? DateTime.now();
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final gradient = DynamicTheme.dreamyGradient(colorScheme);
    
    return Scaffold(
      backgroundColor: colorScheme.secondary2,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(AppTheme.spacingMd),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: DynamicTheme.getPrimaryIconColor(colorScheme),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: DynamicTheme.getCardBackgroundColor(colorScheme).withOpacity(0.5),
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
                      backgroundColor: DynamicTheme.getCardBackgroundColor(colorScheme).withOpacity(0.5),
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
            
            // Letter content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Envelope header
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(AppTheme.spacingMd),
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        ),
                        child: Icon(
                          Icons.mail,
                          size: AppConstants.openedLetterEnvelopeIconSize,
                          color: DynamicTheme.getPrimaryIconColor(colorScheme),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: AppTheme.spacingLg),
                    
                    // Label
                    Text(
                      capsule.label,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: DynamicTheme.getPrimaryTextColor(colorScheme),
                          ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: AppTheme.spacingSm),
                    
                    // From and timestamp
                    Center(
                      child: Column(
                        children: [
                          Text(
                            '${AppConstants.fromPrefix} ${capsule.senderName}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: DynamicTheme.getSecondaryTextColor(colorScheme),
                                ),
                          ),
                          SizedBox(height: AppTheme.spacingXs),
                          Text(
                            '${AppConstants.openedOnPrefix} ${DateFormat('MMMM d, y \'at\' h:mm a').format(openedAt)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: DynamicTheme.getSecondaryTextColor(colorScheme),
                                ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: AppTheme.spacingXl),
                    
                    // Letter content
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(AppTheme.spacingLg),
                      decoration: BoxDecoration(
                        color: DynamicTheme.getCardBackgroundColor(colorScheme),
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              AppConstants.openedLetterCardShadowOpacity,
                            ),
                            blurRadius: AppConstants.openedLetterCardShadowBlur,
                            offset: Offset(
                              0,
                              AppConstants.openedLetterCardShadowOffsetY,
                            ),
                          ),
                        ],
                      ),
                      child: Text(
                        capsule.content,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: AppConstants.openedLetterContentLineHeight,
                              fontSize: AppConstants.openedLetterContentFontSize,
                              color: colorScheme.isDarkTheme 
                                  ? Colors.white 
                                  : const Color(0xFF2A2A2A), // Darker text for better contrast on light backgrounds
                              fontWeight: FontWeight.w400,
                            ),
                      ),
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
                    
                    SizedBox(height: AppTheme.spacingXl),
                    
                    // Divider
                    Divider(
                      color: DynamicTheme.getDividerColor(colorScheme),
                      thickness: 1,
                    ),
                    
                    SizedBox(height: AppTheme.spacingLg),
                    
                    // Reaction prompt
                    Text(
                        AppConstants.howDoesThisMakeYouFeel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.isDarkTheme 
                                ? Colors.white 
                                : const Color(0xFF1A1A1A), // Very dark for maximum contrast
                          ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: AppTheme.spacingXl),
                  ],
                ),
              ),
            ),
            
            // Emoji reactions bar
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacingLg,
                vertical: AppTheme.spacingMd,
              ),
              decoration: BoxDecoration(
                color: DynamicTheme.getCardBackgroundColor(colorScheme),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      AppConstants.openedLetterCardShadowOpacity,
                    ),
                    blurRadius: AppConstants.openedLetterCardShadowBlur,
                    offset: Offset(
                      0,
                      AppConstants.openedLetterBottomBarShadowOffsetY,
                    ),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: AppConstants.reactionEmojis
                    .map((emoji) => _buildReactionButton(emoji))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReactionButton(String emoji) {
    final isSelected = _selectedReaction == emoji;
    final isDisabled = _isSendingReaction;
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    
    return GestureDetector(
      onTap: isDisabled ? null : () => _handleReaction(emoji),
      child: AnimatedContainer(
        duration: AppConstants.animationDurationShort,
        width: AppConstants.openedLetterReactionButtonSize,
        height: AppConstants.openedLetterReactionButtonSize,
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary1.withOpacity(
                  AppConstants.openedLetterReactionSelectedOpacity,
                )
              : AppColors.lightGray.withOpacity(
                  AppConstants.openedLetterReactionUnselectedOpacity,
                ),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? colorScheme.primary1 : Colors.transparent,
            width: AppConstants.openedLetterReactionBorderWidth,
          ),
        ),
        child: Center(
          child: AnimatedScale(
            scale: isSelected
                ? AppConstants.openedLetterReactionSelectedScale
                : 1.0,
            duration: AppConstants.animationDurationShort,
            child: Opacity(
              opacity: isDisabled ? AppConstants.opacityMediumHigh : 1.0,
            child: Text(
              emoji,
                style: const TextStyle(
                  fontSize: AppConstants.openedLetterReactionEmojiSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
