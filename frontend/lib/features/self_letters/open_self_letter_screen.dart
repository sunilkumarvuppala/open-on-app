import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/router/app_router.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/color_scheme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/utils/error_handler.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:intl/intl.dart';

class OpenSelfLetterScreen extends ConsumerStatefulWidget {
  final String letterId;
  
  const OpenSelfLetterScreen({super.key, required this.letterId});
  
  @override
  ConsumerState<OpenSelfLetterScreen> createState() => _OpenSelfLetterScreenState();
}

class _OpenSelfLetterScreenState extends ConsumerState<OpenSelfLetterScreen> {
  SelfLetter? _letter;
  bool _isLoading = true;
  bool _isOpening = false;
  bool _showReflection = false;
  
  @override
  void initState() {
    super.initState();
    _loadLetter();
  }
  
  Future<void> _loadLetter() async {
    try {
      final lettersAsync = ref.read(selfLettersProvider);
      final letters = lettersAsync.asData?.value ?? [];
      final letter = letters.firstWhere(
        (l) => l.id == widget.letterId,
        orElse: () => throw Exception('Letter not found'),
      );
      
      setState(() {
        _letter = letter;
        _isLoading = false;
      });
      
      // If already opened, show reflection if not yet submitted
      if (letter.isOpened && !letter.hasReflection) {
        setState(() => _showReflection = true);
      }
    } catch (e, stackTrace) {
      Logger.error('Failed to load letter', error: e, stackTrace: stackTrace);
      if (mounted) {
        final errorMsg = ErrorHandler.getErrorMessage(e, defaultMessage: 'Failed to load letter');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
        context.pop();
      }
    }
  }
  
  Future<void> _openLetter() async {
    if (_isOpening || _letter == null) return;
    
    setState(() => _isOpening = true);
    
    try {
      final repo = ref.read(selfLetterRepositoryProvider);
      final openedLetter = await repo.openSelfLetter(widget.letterId);
      
      setState(() {
        _letter = openedLetter;
        _isOpening = false;
        _showReflection = true;
      });
      
      // Refresh the list
      ref.invalidate(selfLettersProvider);
    } catch (e, stackTrace) {
      Logger.error('Failed to open letter', error: e, stackTrace: stackTrace);
      if (mounted) {
        final errorMsg = ErrorHandler.getErrorMessage(e, defaultMessage: 'Failed to open letter');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
      setState(() => _isOpening = false);
    }
  }
  
  Future<void> _submitReflection(String answer) async {
    if (_letter == null) return;
    
    try {
      final repo = ref.read(selfLetterRepositoryProvider);
      await repo.submitReflection(
        letterId: widget.letterId,
        answer: answer,
      );
      
      // Refresh letter
      await _loadLetter();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reflection saved')),
        );
        
        // Navigate back after a moment
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) context.pop();
        });
      }
    } catch (e, stackTrace) {
      Logger.error('Failed to submit reflection', error: e, stackTrace: stackTrace);
      if (mounted) {
        final errorMsg = ErrorHandler.getErrorMessage(e, defaultMessage: 'Failed to submit reflection');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Opening Letter')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_letter == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Letter')),
        body: const Center(child: Text('Letter not found')),
      );
    }
    
    final letter = _letter!;
    
    // Show reflection prompt if needed
    if (_showReflection && letter.isOpened && !letter.hasReflection) {
      return _ReflectionPrompt(
        letter: letter,
        onSubmit: _submitReflection,
        onSkip: () => context.pop(),
      );
    }
    
    // Show opening button if not yet opened
    if (!letter.isOpened) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Your Letter'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingXl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mail_outline,
                  size: 80,
                  color: colorScheme.primary1,
                ),
                const SizedBox(height: AppTheme.spacingXl),
                Text(
                  'Ready to open',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  letter.contextText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingXl),
                FilledButton(
                  onPressed: _isOpening ? null : _openLetter,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingXl,
                      vertical: AppTheme.spacingMd,
                    ),
                  ),
                  child: _isOpening
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Open Letter'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Show opened letter content
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Letter'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Context
            if (letter.contextText.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: colorScheme.primary1,
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Text(
                        letter.contextText,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: AppTheme.spacingXl),
            
            // Content
            if (letter.content != null)
              Text(
                letter.content!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                ),
              ),
            
            const SizedBox(height: AppTheme.spacingXl),
            
            // Reflection status
            if (letter.hasReflection)
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: AppTheme.spacingSm),
                    Text(
                      'Reflected: ${letter.reflectionAnswer}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReflectionPrompt extends ConsumerWidget {
  final SelfLetter letter;
  final Function(String) onSubmit;
  final VoidCallback onSkip;
  
  const _ReflectionPrompt({
    required this.letter,
    required this.onSubmit,
    required this.onSkip,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Question
              Text(
                'Does this still feel true?',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppTheme.spacingXl),
              
              // Answer buttons
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => onSubmit('yes'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                  ),
                  child: const Text('Yes'),
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingMd),
              
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => onSubmit('no'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                  ),
                  child: const Text('Not anymore'),
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingMd),
              
              TextButton(
                onPressed: () => onSubmit('skipped'),
                child: const Text('Skip'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
