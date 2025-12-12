import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';

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
  
  String? get _validationMessage {
    final combined = _combinedDateTime;
    if (combined == null) return null;
    
    final now = DateTime.now();
    final minTime = now.add(const Duration(minutes: 5));
    
    if (!combined.isAfter(minTime)) {
      return 'Please select a time at least 5 minutes in the future';
    }
    
    return null;
  }
  
  void _saveAndContinue() {
    if (!_isValidTime) {
      setState(() {
        _errorMessage = _validationMessage;
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
                        color: DynamicTheme.getPrimaryTextColor(colorScheme),
                      ),
                ),
                SizedBox(height: AppTheme.spacingSm),
                Text(
                  'Choose the perfect moment for the reveal',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: DynamicTheme.getSecondaryTextColor(colorScheme),
                      ),
                ),
                SizedBox(height: AppTheme.spacingXl),
                
                // Quick selection chips
                Wrap(
                  spacing: AppTheme.chipSpacing,
                  runSpacing: AppTheme.chipSpacing,
                  children: [
                    _quickSelectChip('Tomorrow, 9 AM', 1),
                    _quickSelectChip('In 1 week', 7),
                    _quickSelectChip('In 1 month', 30),
                    _quickSelectChip('In 3 months', 90),
                    _quickSelectChip('In 1 year', 365),
                  ],
                ),
                
                SizedBox(height: AppTheme.spacingXl),
                
                Divider(
                  color: DynamicTheme.getDividerColor(colorScheme),
                ),
                
                SizedBox(height: AppTheme.spacingXl),
                
                Text(
                  'Or choose a custom date and time',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: DynamicTheme.getPrimaryTextColor(colorScheme),
                      ),
                ),
                
                SizedBox(height: AppTheme.spacingLg),
                
                // Date picker
                Card(
                  elevation: 2,
                  color: DynamicTheme.getCardBackgroundColor(colorScheme),
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
                          Icon(
                            Icons.calendar_today, 
                            color: DynamicTheme.getPrimaryIconColor(colorScheme),
                          ),
                          SizedBox(width: AppTheme.spacingMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: DynamicTheme.getLabelTextColor(colorScheme),
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
                                        ? DynamicTheme.getPrimaryTextColor(colorScheme)
                                        : DynamicTheme.getDisabledTextColor(colorScheme),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right, 
                            color: DynamicTheme.getSecondaryIconColor(colorScheme),
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
                  color: DynamicTheme.getCardBackgroundColor(colorScheme),
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
                          Icon(
                            Icons.access_time, 
                            color: DynamicTheme.getPrimaryIconColor(colorScheme),
                          ),
                          SizedBox(width: AppTheme.spacingMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Time',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: DynamicTheme.getLabelTextColor(colorScheme),
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
                                        ? DynamicTheme.getPrimaryTextColor(colorScheme)
                                        : DynamicTheme.getDisabledTextColor(colorScheme),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right, 
                            color: DynamicTheme.getSecondaryIconColor(colorScheme),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                if (_combinedDateTime != null && _isValidTime) ...[
                  SizedBox(height: AppTheme.spacingMd),
                  Container(
                    padding: EdgeInsets.all(AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: DynamicTheme.getInfoBackgroundColor(colorScheme),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: DynamicTheme.getInfoBorderColor(colorScheme),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline, 
                          color: DynamicTheme.getInfoTextColor(colorScheme),
                        ),
                        SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: Text(
                            'This letter will unlock on ${DateFormat('MMMM d, y').format(_combinedDateTime!)} at ${_selectedTime!.format(context)}',
                            style: TextStyle(
                              color: DynamicTheme.getInfoTextColor(colorScheme),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Show validation error message when time is invalid or when explicitly set
                if ((_validationMessage != null || _errorMessage != null)) ...[
                  SizedBox(height: AppTheme.spacingMd),
                  Container(
                    padding: EdgeInsets.all(AppTheme.spacingSm),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(AppTheme.opacityLow),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(color: AppColors.error.withOpacity(AppTheme.opacityHigh)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: AppColors.error, size: 20),
                        SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: Text(
                            _validationMessage ?? _errorMessage ?? '',
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
                child: ElevatedButton(
                  onPressed: _isValidTime ? _saveAndContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary1,
                    foregroundColor: DynamicTheme.getButtonTextColor(colorScheme),
                    padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                    side: DynamicTheme.getButtonBorderSide(colorScheme),
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
    
    // Check if this chip's time matches the currently selected date/time
    final now = DateTime.now();
    final targetDate = now.add(Duration(days: days));
    final chipDate = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );
    final isSelected = _selectedDate != null &&
        _selectedDate!.year == chipDate.year &&
        _selectedDate!.month == chipDate.month &&
        _selectedDate!.day == chipDate.day &&
        _selectedTime != null &&
        _selectedTime!.hour == 9 &&
        _selectedTime!.minute == 0;
    
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          color: DynamicTheme.getChipLabelColor(colorScheme, isSelected),
          fontSize: 13,
        ),
      ),
      onPressed: () {
        setState(() {
          _selectedDate = chipDate;
          _selectedTime = const TimeOfDay(hour: 9, minute: 0);
          _errorMessage = null;
        });
      },
      backgroundColor: DynamicTheme.getChipBackgroundColor(colorScheme, isSelected),
      side: BorderSide(
        color: DynamicTheme.getChipBorderColor(colorScheme, isSelected),
        width: DynamicTheme.getChipBorderWidth(isSelected),
      ),
      elevation: DynamicTheme.getChipElevation(isSelected),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
