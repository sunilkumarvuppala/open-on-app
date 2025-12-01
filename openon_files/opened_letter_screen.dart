import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/app_theme.dart';

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
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send reaction'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final capsule = widget.capsule;
    final openedAt = capsule.openedAt ?? DateTime.now();
    
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      // TODO: Share opened letter
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Share feature coming soon'),
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
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Envelope header
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.gradientStart,
                              AppColors.gradientMiddle,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.mail_open,
                          size: 48,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Label
                    Text(
                      capsule.label,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepPurple,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // From and timestamp
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'From ${capsule.senderName}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.gray,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Opened on ${DateFormat('MMMM d, y \'at\' h:mm a').format(openedAt)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.gray,
                                ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Letter content
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
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
                      const SizedBox(height: 24),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
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
                    
                    const SizedBox(height: 32),
                    
                    // Divider
                    const Divider(),
                    
                    const SizedBox(height: 24),
                    
                    // Reaction prompt
                    Text(
                      'How does this make you feel?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            
            // Emoji reactions bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
    
    return GestureDetector(
      onTap: () => _handleReaction(emoji),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.deepPurple.withOpacity(0.1)
              : AppColors.lightGray.withOpacity(0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.deepPurple : Colors.transparent,
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
