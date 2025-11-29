import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/models.dart';

class OpenedLetterScreen extends ConsumerStatefulWidget {
  final String capsuleId;

  const OpenedLetterScreen({
    super.key,
    required this.capsuleId,
  });

  @override
  ConsumerState<OpenedLetterScreen> createState() => _OpenedLetterScreenState();
}

class _OpenedLetterScreenState extends ConsumerState<OpenedLetterScreen> {
  Future<void> _addReaction(CapsuleReaction reaction) async {
    try {
      final repo = ref.read(capsuleRepositoryProvider);
      await repo.addReaction(widget.capsuleId, reaction);
      
      // Refresh capsule
      ref.invalidate(capsuleProvider(widget.capsuleId));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: AppTheme.spacingMd),
                Text('Reaction sent!'),
              ],
            ),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reaction: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final capsuleAsync = ref.watch(capsuleProvider(widget.capsuleId));

    return Scaffold(
      body: capsuleAsync.when(
        data: (capsule) {
          if (capsule == null) {
            return const ErrorDisplay(message: 'Letter not found');
          }

          final dateFormat = DateFormat('MMMM d, yyyy');
          final timeFormat = DateFormat('h:mm a');

          return Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.softGradient,
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
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => context.pop(),
                        ),
                        Expanded(
                          child: Text(
                            'From ${capsule.recipientName}',
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48), // Balance the back button
                      ],
                    ),
                  ),
                  
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.spacingLg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Letter Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppTheme.spacingXl),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Label
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingMd,
                                    vertical: AppTheme.spacingSm,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.warmGradient,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  ),
                                  child: Text(
                                    capsule.label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: AppTheme.spacingLg),
                                
                                // Opened timestamp
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: AppTheme.textGrey,
                                    ),
                                    const SizedBox(width: AppTheme.spacingSm),
                                    Text(
                                      'Opened on ${dateFormat.format(capsule.openedAt!)} at ${timeFormat.format(capsule.openedAt!)}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textGrey,
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: AppTheme.spacingXl),
                                
                                // Letter Text
                                Text(
                                  capsule.letterText,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    height: 1.8,
                                    fontSize: 16,
                                  ),
                                ),
                                
                                // Photo if attached
                                if (capsule.localPhotoPath != null) ...[
                                  const SizedBox(height: AppTheme.spacingXl),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                    child: Image.file(
                                      File(capsule.localPhotoPath!),
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ] else if (capsule.photoUrl != null) ...[
                                  const SizedBox(height: AppTheme.spacingXl),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                    child: Image.network(
                                      capsule.photoUrl!,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                                
                                const SizedBox(height: AppTheme.spacingXl),
                                
                                // Sender signature
                                Row(
                                  children: [
                                    const Spacer(),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          'With love,',
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: AppTheme.textGrey,
                                          ),
                                        ),
                                        const SizedBox(height: AppTheme.spacingXs),
                                        Text(
                                          capsule.recipientName,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: AppTheme.spacingXl),
                          
                          // Reactions Section
                          Text(
                            'How does this make you feel?',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          
                          const SizedBox(height: AppTheme.spacingMd),
                          
                          _ReactionBar(
                            currentReaction: capsule.reaction,
                            onReactionTap: _addReaction,
                          ),
                          
                          if (capsule.reaction != null) ...[
                            const SizedBox(height: AppTheme.spacingMd),
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacingMd),
                              decoration: BoxDecoration(
                                color: AppTheme.lavender.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppTheme.successGreen,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppTheme.spacingMd),
                                  Expanded(
                                    child: Text(
                                      'Your reaction was sent to ${capsule.recipientName}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorDisplay(
          message: 'Failed to load letter',
          onRetry: () => ref.invalidate(capsuleProvider(widget.capsuleId)),
        ),
      ),
    );
  }
}

class _ReactionBar extends StatefulWidget {
  final CapsuleReaction? currentReaction;
  final Function(CapsuleReaction) onReactionTap;

  const _ReactionBar({
    required this.currentReaction,
    required this.onReactionTap,
  });

  @override
  State<_ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<_ReactionBar> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  CapsuleReaction? _lastTappedReaction;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleReactionTap(CapsuleReaction reaction) {
    setState(() {
      _lastTappedReaction = reaction;
    });
    
    _animationController.forward(from: 0);
    widget.onReactionTap(reaction);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: CapsuleReaction.values.map((reaction) {
        final isSelected = widget.currentReaction == reaction;
        final isAnimating = _lastTappedReaction == reaction;

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final scale = isAnimating
                ? 1.0 + (0.5 * _animationController.value)
                : 1.0;
            
            return Transform.scale(
              scale: scale,
              child: GestureDetector(
                onTap: () => _handleReactionTap(reaction),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppTheme.deepPurple.withOpacity(0.1) 
                        : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected 
                          ? AppTheme.deepPurple 
                          : AppTheme.lavender,
                      width: isSelected ? 3 : 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      reaction.emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
