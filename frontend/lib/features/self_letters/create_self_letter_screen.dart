import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/color_scheme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/utils/error_handler.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:intl/intl.dart';

class CreateSelfLetterScreen extends ConsumerStatefulWidget {
  const CreateSelfLetterScreen({super.key});
  
  @override
  ConsumerState<CreateSelfLetterScreen> createState() => _CreateSelfLetterScreenState();
}

class _CreateSelfLetterScreenState extends ConsumerState<CreateSelfLetterScreen> {
  final TextEditingController _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  static const int _minCharacters = 280;
  static const int _maxCharacters = 500;
  
  DateTime? _selectedDate;
  String? _selectedMood;
  String? _selectedLifeArea;
  String? _city;
  bool _isCreating = false;
  
  final List<String> _moodOptions = ['calm', 'anxious', 'tired', 'excited', 'grateful', 'worried'];
  final List<String> _lifeAreaOptions = ['self', 'work', 'family', 'money', 'health'];
  
  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
  
  int get _charCount => _contentController.text.length;
  bool get _isValid => _charCount >= _minCharacters && _charCount <= _maxCharacters && _selectedDate != null;
  
  Future<void> _selectDate() async {
    final now = DateTime.now();
    final firstDate = now.add(const Duration(days: 1));
    final lastDate = now.add(const Duration(days: 365 * 5)); // 5 years max
    
    final picked = await showDatePicker(
      context: context,
      initialDate: firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'When should this letter open?',
    );
    
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(picked),
      );
      
      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.inDays == 0) {
      return 'Today at ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow at ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days from now';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} from now';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} from now';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} from now';
    }
  }
  
  Future<void> _showSealConfirmation() async {
    if (!_isValid) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Seal This Letter?'),
        content: const Text(
          'Once sealed, this message cannot be changed — even by you.\n\n'
          'This letter will be locked until the scheduled time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Seal It'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _createLetter();
    }
  }
  
  Future<void> _createLetter() async {
    if (!_isValid || _isCreating) return;
    
    setState(() => _isCreating = true);
    
    try {
      final repo = ref.read(selfLetterRepositoryProvider);
      
      await repo.createSelfLetter(
        content: _contentController.text.trim(),
        scheduledOpenAt: _selectedDate!,
        mood: _selectedMood,
        lifeArea: _selectedLifeArea,
        city: _city,
      );
      
      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Letter sealed successfully')),
      );
      
      // Navigate back
      context.pop();
    } catch (e, stackTrace) {
      Logger.error('Failed to create self letter', error: e, stackTrace: stackTrace);
      if (!mounted) return;
      
      final errorMsg = ErrorHandler.getErrorMessage(e, defaultMessage: 'Failed to create letter');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write to Future Me'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Character counter
              Text(
                '$_charCount / $_maxCharacters',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _charCount < _minCharacters || _charCount > _maxCharacters
                      ? Colors.red
                      : null,
                ),
                textAlign: TextAlign.right,
              ),
              
              const SizedBox(height: AppTheme.spacingSm),
              
              // Content editor
              TextFormField(
                controller: _contentController,
                maxLines: 12,
                maxLength: _maxCharacters,
                decoration: InputDecoration(
                  hintText: 'Write a letter to your future self...\n\n'
                      'What do you want to remember? What are you feeling right now?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  filled: true,
                  fillColor: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(0.05),
                ),
                onChanged: (_) => setState(() {}),
              ),
              
              const SizedBox(height: AppTheme.spacingLg),
              
              // Time selection
              _buildSection(
                title: 'When should this open?',
                child: InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(0.2),
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: colorScheme.primary1,
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Expanded(
                          child: Text(
                            _selectedDate != null
                                ? _formatDate(_selectedDate!)
                                : 'Select date and time',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingMd),
              
              // Optional context
              _buildSection(
                title: 'Context (optional)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mood
                    DropdownButtonFormField<String>(
                      value: _selectedMood,
                      decoration: InputDecoration(
                        labelText: 'How are you feeling?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                      items: _moodOptions.map((mood) {
                        return DropdownMenuItem(
                          value: mood,
                          child: Text(mood[0].toUpperCase() + mood.substring(1)),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedMood = value),
                    ),
                    
                    const SizedBox(height: AppTheme.spacingMd),
                    
                    // Life area
                    DropdownButtonFormField<String>(
                      value: _selectedLifeArea,
                      decoration: InputDecoration(
                        labelText: 'Life area',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                      items: _lifeAreaOptions.map((area) {
                        return DropdownMenuItem(
                          value: area,
                          child: Text(area[0].toUpperCase() + area.substring(1)),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedLifeArea = value),
                    ),
                    
                    const SizedBox(height: AppTheme.spacingMd),
                    
                    // City
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'City (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                      onChanged: (value) => setState(() => _city = value.isEmpty ? null : value),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingXl),
              
              // Seal button
              FilledButton(
                onPressed: _isValid && !_isCreating ? _showSealConfirmation : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                ),
                child: _isCreating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Seal Letter'),
              ),
              
              if (_charCount < _minCharacters)
                Padding(
                  padding: const EdgeInsets.only(top: AppTheme.spacingSm),
                  child: Text(
                    'At least $_minCharacters characters required',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppTheme.spacingSm),
        child,
      ],
    );
  }
}
