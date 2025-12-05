import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';

class OpenedLetterScreen extends ConsumerStatefulWidget {
  final Capsule capsule;
  
  const OpenedLetterScreen({super.key, required this.capsule});
  
  @override
  ConsumerState<OpenedLetterScreen> createState() => _OpenedLetterScreenState();
}

class _OpenedLetterScreenState extends ConsumerState<OpenedLetterScreen> {
  String? _selectedReaction;
  
  @override
  void initState() {
    super.initState();
    _selectedReaction = widget.capsule.reaction;
  }
  
  Future<void> _handleReaction(String emoji) async {
    setState(() => _selectedReaction = emoji);
    
    try {
      final repo = ref.read(capsuleRepositoryProvider);
      await repo.addReaction(widget.capsule.id, emoji);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reaction sent to ${widget.capsule.senderName} ♥'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to send reaction'),
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
  
  @override
  Widget build(BuildContext context) {
    final capsule = widget.capsule;
    final openedAt = capsule.openedAt ?? DateTime.now();
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final gradient = DynamicTheme.dreamyGradient(colorScheme);
    
    return Scaffold(
      backgroundColor: AppColors.offWhite,
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
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      // TODO: Share opened letter
                      final colorScheme = ref.read(selectedColorSchemeProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Share feature coming soon',
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
                        child: const Icon(
                          Icons.mail,
                          size: 48,
                          color: AppColors.white,
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
                            'From ${capsule.senderName}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.textGrey,
                                ),
                          ),
                          SizedBox(height: AppTheme.spacingXs),
                          Text(
                            'Opened on ${DateFormat('MMMM d, y \'at\' h:mm a').format(openedAt)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textGrey,
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
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        capsule.content,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.8,
                              fontSize: 16,
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
                    const Divider(),
                    
                    SizedBox(height: AppTheme.spacingLg),
                    
                    // Reaction prompt
                    Text(
                      'How does this make you feel?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
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
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildReactionButton('❤️'),
                  _buildReactionButton('😭'),
                  _buildReactionButton('🤗'),
                  _buildReactionButton('😍'),
                  _buildReactionButton('🥰'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReactionButton(String emoji) {
    final isSelected = _selectedReaction == emoji;
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    
    return GestureDetector(
      onTap: () => _handleReaction(emoji),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary1.withOpacity(0.1)
              : AppColors.lightGray.withOpacity(0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? colorScheme.primary1 : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: AnimatedScale(
            scale: isSelected ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
      ),
    );
  }
}
