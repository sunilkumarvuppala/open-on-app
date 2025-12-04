import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/app_theme.dart';

class StepChooseTime extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  
  const StepChooseTime({
    super.key,
    required this.onNext,
    required this.onBack,
  });
  
  @override
  ConsumerState<StepChooseTime> createState() => _StepChooseTimeState();
}

class _StepChooseTimeState extends ConsumerState<StepChooseTime> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    final draft = ref.read(draftCapsuleProvider);
    if (draft.unlockAt != null) {
      _selectedDate = DateTime(
        draft.unlockAt!.year,
        draft.unlockAt!.month,
        draft.unlockAt!.day,
      );
      _selectedTime = TimeOfDay(
        hour: draft.unlockAt!.hour,
        minute: draft.unlockAt!.minute,
      );
    }
  }
  
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = now.add(const Duration(minutes: 5));
    final lastDate = now.add(const Duration(days: 365 * 10));
    
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        final colorScheme = ref.read(selectedColorSchemeProvider);
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: colorScheme.primary1,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _errorMessage = null;
      });
    }
  }
  
  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        final colorScheme = ref.read(selectedColorSchemeProvider);
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: colorScheme.primary1,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (time != null) {
      setState(() {
        _selectedTime = time;
        _errorMessage = null;
      });
    }
  }
  
  DateTime? get _combinedDateTime {
    if (_selectedDate == null || _selectedTime == null) return null;
    
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
  }
  
  bool get _isValidTime {
    final combined = _combinedDateTime;
    if (combined == null) return false;
    
    final now = DateTime.now();
    final minTime = now.add(const Duration(minutes: 5));
    
    return combined.isAfter(minTime);
  }
  
  void _saveAndContinue() {
    if (!_isValidTime) {
      setState(() {
        _errorMessage = 'Please select a time at least 5 minutes in the future';
      });
      return;
    }
    
    ref.read(draftCapsuleProvider.notifier).setUnlockTime(_combinedDateTime!);
    widget.onNext();
  }
  
  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(draftCapsuleProvider);
    final recipient = draft.recipient;
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'When should ${recipient?.name ?? "they"} open this?',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.id == 'deep_blue' ? Colors.white : AppColors.textDark,
                      ),
                ),
                SizedBox(height: AppTheme.spacingSm),
                Text(
                  'Choose the perfect moment for the reveal',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.id == 'deep_blue' 
                            ? Colors.white.withOpacity(0.9) 
                            : AppTheme.textGrey,
                      ),
                ),
                SizedBox(height: AppTheme.spacingXl),
                
                // Quick selection chips
                Wrap(
                  spacing: AppTheme.spacingSm,
                  runSpacing: AppTheme.spacingSm,
                  children: [
                    _quickSelectChip('Tomorrow, 9 AM', 1),
                    _quickSelectChip('In 1 week', 7),
                    _quickSelectChip('In 1 month', 30),
                    _quickSelectChip('In 3 months', 90),
                    _quickSelectChip('In 1 year', 365),
                  ],
                ),
                
                SizedBox(height: AppTheme.spacingXl),
                
                const Divider(),
                
                SizedBox(height: AppTheme.spacingXl),
                
                Text(
                  'Or choose a custom date and time',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.id == 'deep_blue' ? Colors.white : AppColors.textDark,
                      ),
                ),
                
                SizedBox(height: AppTheme.spacingLg),
                
                // Date picker
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spacingMd),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: colorScheme.primary1),
                          SizedBox(width: AppTheme.spacingMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.id == 'deep_blue' 
                                        ? Colors.white.withOpacity(0.8) 
                                        : AppTheme.textGrey,
                                  ),
                                ),
                                SizedBox(height: AppTheme.spacingXs),
                                Text(
                                  _selectedDate != null
                                      ? DateFormat('EEEE, MMMM d, y').format(_selectedDate!)
                                      : 'Select a date',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedDate != null
                                        ? (colorScheme.id == 'deep_blue' ? Colors.white : AppColors.textDark)
                                        : (colorScheme.id == 'deep_blue' 
                                            ? Colors.white.withOpacity(0.7) 
                                            : AppTheme.textGrey),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right, 
                            color: colorScheme.id == 'deep_blue' 
                                ? Colors.white.withOpacity(0.7) 
                                : AppTheme.textGrey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: AppTheme.spacingMd),
                
                // Time picker
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spacingMd),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: colorScheme.primary1),
                          SizedBox(width: AppTheme.spacingMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Time',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.id == 'deep_blue' 
                                        ? Colors.white.withOpacity(0.8) 
                                        : AppTheme.textGrey,
                                  ),
                                ),
                                SizedBox(height: AppTheme.spacingXs),
                                Text(
                                  _selectedTime != null
                                      ? _selectedTime!.format(context)
                                      : 'Select a time',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedTime != null
                                        ? (colorScheme.id == 'deep_blue' ? Colors.white : AppColors.textDark)
                                        : (colorScheme.id == 'deep_blue' 
                                            ? Colors.white.withOpacity(0.7) 
                                            : AppTheme.textGrey),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right, 
                            color: colorScheme.id == 'deep_blue' 
                                ? Colors.white.withOpacity(0.7) 
                                : AppTheme.textGrey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                if (_combinedDateTime != null) ...[
                  SizedBox(height: AppTheme.spacingXl),
                  Container(
                    padding: EdgeInsets.all(AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: colorScheme.primary1.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: colorScheme.primary1.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: colorScheme.primary1),
                        SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: Text(
                            'This letter will unlock on ${DateFormat('MMMM d, y').format(_combinedDateTime!)} at ${_selectedTime!.format(context)}',
                            style: TextStyle(
                              color: colorScheme.primary1,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                if (_errorMessage != null) ...[
                  SizedBox(height: AppTheme.spacingMd),
                  Container(
                    padding: EdgeInsets.all(AppTheme.spacingSm),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: AppColors.error, size: 20),
                        SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: AppColors.error, fontSize: 14),
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
        
        // Navigation buttons
        Container(
          padding: EdgeInsets.all(AppTheme.spacingLg),
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
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
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
                child: ElevatedButton(
                  onPressed: _isValidTime ? _saveAndContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary1,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _quickSelectChip(String label, int days) {
    final colorScheme = ref.read(selectedColorSchemeProvider);
    return ActionChip(
      label: Text(label),
      onPressed: () {
        final now = DateTime.now();
        final targetDate = now.add(Duration(days: days));
        
        setState(() {
          _selectedDate = DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
          );
          _selectedTime = const TimeOfDay(hour: 9, minute: 0);
          _errorMessage = null;
        });
      },
      backgroundColor: colorScheme.primary1.withOpacity(0.1),
      labelStyle: TextStyle(
        color: colorScheme.primary1,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
