import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/color_scheme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/utils/error_handler.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:intl/intl.dart';

class CreateSelfLetterScreen extends ConsumerStatefulWidget {
  const CreateSelfLetterScreen({super.key});
  
  @override
  ConsumerState<CreateSelfLetterScreen> createState() => _CreateSelfLetterScreenState();
}

class _CreateSelfLetterScreenState extends ConsumerState<CreateSelfLetterScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  DateTime? _selectedDate;
  String? _selectedMood; // Emoji value
  String? _selectedLifeArea; // "self" | "work" | "family" | "money" | "health"
  bool _isCreating = false;
  
  // Mood options with emoji and text
  static const List<Map<String, String>> _moodOptions = [
    {'emoji': '😊', 'text': 'Happy', 'value': '😊'},
    {'emoji': '😔', 'text': 'Sad', 'value': '😔'},
    {'emoji': '😌', 'text': 'Peaceful', 'value': '😌'},
    {'emoji': '🥹', 'text': 'Touched', 'value': '🥹'},
    {'emoji': '😐', 'text': 'Neutral', 'value': '😐'},
    {'emoji': '😄', 'text': 'Joyful', 'value': '😄'},
    {'emoji': '😢', 'text': 'Crying', 'value': '😢'},
    {'emoji': '😴', 'text': 'Tired', 'value': '😴'},
    {'emoji': '🤔', 'text': 'Thoughtful', 'value': '🤔'},
    {'emoji': '😍', 'text': 'Loving', 'value': '😍'},
    {'emoji': '😤', 'text': 'Frustrated', 'value': '😤'},
    {'emoji': '😌', 'text': 'Content', 'value': '😌'},
    {'emoji': '🙂', 'text': 'Grateful', 'value': '🙂'},
    {'emoji': '😕', 'text': 'Confused', 'value': '😕'},
    {'emoji': '😎', 'text': 'Confident', 'value': '😎'},
    {'emoji': '🥰', 'text': 'Adoring', 'value': '🥰'},
    {'emoji': '😟', 'text': 'Worried', 'value': '😟'},
    {'emoji': '😇', 'text': 'Blessed', 'value': '😇'},
    {'emoji': '🤗', 'text': 'Hugging', 'value': '🤗'},
    {'emoji': '😑', 'text': 'Expressionless', 'value': '😑'},
  ];
  
  // Life area options
  static const List<Map<String, String>> _lifeAreaOptions = [
    {'value': 'self', 'label': 'Self'},
    {'value': 'work', 'label': 'Work'},
    {'value': 'family', 'label': 'Family'},
    {'value': 'money', 'label': 'Money'},
    {'value': 'health', 'label': 'Health'},
  ];
  
  // Date presets
  static const List<Map<String, dynamic>> _datePresets = [
    {'label': '1 month', 'months': 1},
    {'label': '3 months', 'months': 3},
    {'label': '6 months', 'months': 6},
    {'label': '1 year', 'months': 12},
    {'label': 'Custom', 'custom': true},
  ];
  
  @override
  void initState() {
    super.initState();
    // Default to 1 month
    _selectedDate = DateTime.now().add(const Duration(days: 30));
    // Try to auto-detect city (optional, non-blocking)
    _detectCity();
  }
  
  @override
  void dispose() {
    _contentController.dispose();
    _cityController.dispose();
    super.dispose();
  }
  
  bool get _isValid => _contentController.text.trim().isNotEmpty && _selectedDate != null;
  
  Future<void> _detectCity() async {
    // Placeholder for future geolocation implementation
    // For now, leave city empty and allow manual entry
  }
  
  void _selectDatePreset(Map<String, dynamic> preset) {
    if (preset['custom'] == true) {
      _selectCustomDate();
      return;
    }
    
    final now = DateTime.now();
    final months = preset['months'] as int;
    setState(() {
      _selectedDate = DateTime(now.year, now.month + months, now.day, now.hour, now.minute);
    });
  }
  
  Future<void> _selectCustomDate() async {
    final now = DateTime.now();
    final firstDate = now.add(const Duration(days: 1));
    final lastDate = now.add(const Duration(days: 365 * 5)); // 5 years max
    
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'When should this letter open?',
    );
    
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate ?? now),
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
    } else if (difference.inDays < 30) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'}';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'}';
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
        mood: _selectedMood, // Emoji only
        lifeArea: _selectedLifeArea,
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      );
      
      if (!mounted) return;
      
      // Invalidate provider to trigger refresh
      ref.invalidate(selfLettersProvider);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Letter sealed successfully')),
        );
      }
      
      // Small delay to allow provider refresh to start before navigating
      // The widget watching the provider will automatically rebuild when data is ready
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Navigate back
      if (mounted) {
        context.pop();
      }
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
    final softGradient = DynamicTheme.softGradient(colorScheme);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write to myself'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: softGradient),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Content editor - canvas-style, no character counter
                // Reduced minLines to ensure optional fields are visible
                TextFormField(
                  controller: _contentController,
                  maxLines: null,
                  minLines: 8, // Reduced from 12 to make room for optional fields
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Write a letter to your future self...\n\n'
                        'What do you want to remember? What are you feeling right now?',
                    border: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.all(AppTheme.spacingMd),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                
                const SizedBox(height: AppTheme.spacingXl),
                
                // Open date presets
                _buildSection(
                  title: 'Open date',
                  child: Wrap(
                    spacing: AppTheme.spacingSm,
                    runSpacing: AppTheme.spacingSm,
                    children: _datePresets.map((preset) {
                      final isSelected = preset['custom'] != true &&
                          _selectedDate != null &&
                          _isDatePresetSelected(preset);
                      final isCustom = preset['custom'] == true;
                      
                      return ChoiceChip(
                        label: Text(preset['label'] as String),
                        selected: isSelected || (isCustom && _selectedDate != null && !_isAnyPresetSelected()),
                        onSelected: (_) => _selectDatePreset(preset),
                        selectedColor: colorScheme.primary1.withOpacity(0.2),
                        checkmarkColor: colorScheme.primary1,
                        labelStyle: TextStyle(
                          color: isSelected || (isCustom && _selectedDate != null && !_isAnyPresetSelected())
                              ? colorScheme.primary1
                              : DynamicTheme.getPrimaryTextColor(colorScheme),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                if (_selectedDate != null) ...[
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    'Opens ${_formatDate(_selectedDate!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: DynamicTheme.getSecondaryTextColor(colorScheme),
                    ),
                  ),
                ],
                
                const SizedBox(height: AppTheme.spacingLg),
                
                // Divider to separate main content from optional fields
                Divider(
                  color: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(0.2),
                  thickness: 1,
                ),
                
                const SizedBox(height: AppTheme.spacingLg),
                
                // Optional metadata - make it more prominent
                _buildSection(
                  title: 'Optional context',
                  subtitle: 'Add context to remember this moment',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Mood searchable dropdown
                      Text(
                        'Mood',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: DynamicTheme.getSecondaryTextColor(colorScheme),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      _buildMoodDropdown(
                        selectedMood: _selectedMood,
                        onChanged: (value) => setState(() {
                          _selectedMood = value;
                        }),
                        colorScheme: colorScheme,
                        theme: theme,
                      ),
                      
                      const SizedBox(height: AppTheme.spacingLg),
                      
                      // Life area
                      Text(
                        'Life area',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: DynamicTheme.getSecondaryTextColor(colorScheme),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Wrap(
                        spacing: AppTheme.spacingSm,
                        runSpacing: AppTheme.spacingSm,
                        children: _lifeAreaOptions.map((option) {
                          final isSelected = _selectedLifeArea == option['value'];
                          return ChoiceChip(
                            label: Text(option['label']!),
                            selected: isSelected,
                            onSelected: (selected) => setState(() {
                              _selectedLifeArea = selected ? option['value'] : null;
                            }),
                            selectedColor: colorScheme.primary1.withOpacity(0.2),
                            checkmarkColor: colorScheme.primary1,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? colorScheme.primary1
                                  : DynamicTheme.getPrimaryTextColor(colorScheme),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: AppTheme.spacingLg),
                      
                      // City
                      TextFormField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          labelText: 'City (optional)',
                          hintText: 'Where are you writing from?',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          filled: true,
                          fillColor: DynamicTheme.getCardBackgroundColor(colorScheme),
                        ),
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
                    backgroundColor: colorScheme.primary1,
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Seal Letter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  bool _isDatePresetSelected(Map<String, dynamic> preset) {
    if (_selectedDate == null || preset['custom'] == true) return false;
    final now = DateTime.now();
    final months = preset['months'] as int;
    final expectedDate = DateTime(now.year, now.month + months, now.day, now.hour, now.minute);
    // Allow some tolerance (within 2 days)
    return (_selectedDate!.difference(expectedDate).inDays.abs() <= 2);
  }
  
  bool _isAnyPresetSelected() {
    return _datePresets.any((preset) => 
      preset['custom'] != true && _isDatePresetSelected(preset)
    );
  }
  
  Widget _buildSection({required String title, String? subtitle, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: DynamicTheme.getSecondaryTextColor(
                ref.watch(selectedColorSchemeProvider),
              ).withOpacity(0.7),
            ),
          ),
        ],
        const SizedBox(height: AppTheme.spacingSm),
        child,
      ],
    );
  }
  
  Widget _buildMoodDropdown({
    required String? selectedMood,
    required ValueChanged<String?> onChanged,
    required AppColorScheme colorScheme,
    required ThemeData theme,
  }) {
    final selectedOption = _moodOptions.firstWhere(
      (option) => option['value'] == selectedMood,
      orElse: () => _moodOptions[0],
    );
    
    return Autocomplete<Map<String, String>>(
      initialValue: selectedMood != null ? TextEditingValue(text: selectedOption['text'] ?? '') : null,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return _moodOptions;
        }
        final query = textEditingValue.text.toLowerCase();
        return _moodOptions.where((option) {
          final text = option['text']?.toLowerCase() ?? '';
          final emoji = option['emoji'] ?? '';
          return text.contains(query) || emoji.contains(query);
        }).toList();
      },
      displayStringForOption: (Map<String, String> option) {
        return option['text'] ?? '';
      },
      onSelected: (Map<String, String> option) {
        onChanged(option['value']);
      },
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController textEditingController,
        FocusNode focusNode,
        VoidCallback onFieldSubmitted,
      ) {
        // Update controller text when mood is selected (show only text, emoji in prefix)
        if (selectedMood != null && textEditingController.text != selectedOption['text']) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (textEditingController.text != selectedOption['text']) {
              textEditingController.text = selectedOption['text'] ?? '';
            }
          });
        }
        
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          onTapOutside: (event) {
            // Unfocus when tapping outside to close dropdown
            focusNode.unfocus();
          },
          onSubmitted: (String value) {
            onFieldSubmitted();
          },
          decoration: InputDecoration(
            hintText: 'Search or select mood...',
            hintStyle: TextStyle(
              color: DynamicTheme.getInputHintColor(colorScheme).withOpacity(0.5),
            ),
            prefixIcon: selectedMood != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Text(
                      selectedOption['emoji'] ?? '',
                      style: const TextStyle(fontSize: 20),
                    ),
                  )
                : Icon(
                    Icons.search,
                    color: DynamicTheme.getInputHintColor(colorScheme),
                  ),
            suffixIcon: selectedMood != null
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: DynamicTheme.getInputHintColor(colorScheme),
                    ),
                    onPressed: () {
                      textEditingController.clear();
                      onChanged(null);
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide(
                color: DynamicTheme.getButtonBorderColor(colorScheme).withOpacity(0.2),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide(
                color: DynamicTheme.getButtonBorderColor(colorScheme).withOpacity(0.2),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide(
                color: DynamicTheme.getButtonBorderColor(colorScheme).withOpacity(0.4),
                width: 1,
              ),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingSm,
            ),
          ),
          style: TextStyle(
            color: DynamicTheme.getInputTextColor(colorScheme),
          ),
        );
      },
      optionsViewBuilder: (
        BuildContext context,
        AutocompleteOnSelected<Map<String, String>> onSelected,
        Iterable<Map<String, String>> options,
      ) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            color: Color.lerp(colorScheme.secondary1, Colors.white, 0.1) ?? colorScheme.secondary1,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Container(
              decoration: BoxDecoration(
                color: Color.lerp(colorScheme.secondary1, Colors.white, 0.1) ?? colorScheme.secondary1,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: DynamicTheme.getButtonBorderColor(colorScheme),
                  width: 1,
                ),
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    hoverColor: colorScheme.primary1.withOpacity(0.2),
                    splashColor: colorScheme.primary1.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd,
                        vertical: AppTheme.spacingSm,
                      ),
                      child: Row(
                        children: [
                          Text(
                            option['emoji'] ?? '',
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: AppTheme.spacingSm),
                          Text(
                            option['text'] ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
