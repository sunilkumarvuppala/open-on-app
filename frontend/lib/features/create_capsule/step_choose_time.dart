import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/color_scheme.dart';
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
  bool _isCustomSectionExpanded = false;
  
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
      // Auto-expand custom section if a custom date/time is already selected
      _isCustomSectionExpanded = true;
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
        _isCustomSectionExpanded = true; // Expand section when date is selected
      });
    }
  }
  
  Future<void> _pickTime() async {
    final initialTime = _selectedTime ?? const TimeOfDay(hour: 9, minute: 0);
    final colorScheme = ref.read(selectedColorSchemeProvider);
    
    final time = await showDialog<TimeOfDay>(
      context: context,
      builder: (context) => _CustomTimePickerDialog(
        initialTime: initialTime,
        colorScheme: colorScheme,
      ),
    );
    
    if (time != null) {
      setState(() {
        _selectedTime = time;
        _errorMessage = null;
        _isCustomSectionExpanded = true; // Expand section when time is selected
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
                SizedBox(height: AppTheme.spacingMd),
                
                // Quick selection chips
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppTheme.chipSpacing,
                      runSpacing: AppTheme.chipSpacing,
                      children: [
                        _quickSelectChip('Tomorrow, 9 AM', 1, isRecommended: false),
                        _quickSelectChip('In 1 week', 7, isRecommended: true),
                        _quickSelectChip('In 1 month', 30, isRecommended: false),
                        _quickSelectChip('In 3 months', 90, isRecommended: false),
                        _quickSelectChip('In 1 year', 365, isRecommended: false),
                      ],
                    ),
                    // Recommendation hint for "In 1 week"
                    Padding(
                      padding: const EdgeInsets.only(top: AppTheme.spacingXs, left: AppTheme.spacingXs),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_outline,
                            size: 14,
                            color: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(0.6),
                          ),
                          SizedBox(width: AppTheme.spacingXs),
                          Text(
                            'A thoughtful default',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(0.6),
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: AppTheme.spacingMd),
                
                Divider(
                  color: DynamicTheme.getDividerColor(colorScheme),
                ),
                
                SizedBox(height: AppTheme.spacingMd),
                
                // Collapsible custom date section
                Container(
                  decoration: BoxDecoration(
                    color: DynamicTheme.getCardBackgroundColor(colorScheme).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: DynamicTheme.getButtonBorderColor(colorScheme).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isCustomSectionExpanded = !_isCustomSectionExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd,
                        vertical: AppTheme.spacingSm,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 20,
                            color: DynamicTheme.getPrimaryIconColor(colorScheme).withOpacity(0.7),
                          ),
                          SizedBox(width: AppTheme.spacingSm),
                          Expanded(
                            child: Text(
                              'Choose a custom date and time',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: DynamicTheme.getPrimaryTextColor(colorScheme),
                                  ),
                            ),
                          ),
                          Icon(
                            _isCustomSectionExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: DynamicTheme.getPrimaryIconColor(colorScheme),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Date and time pickers - only show when expanded
                if (_isCustomSectionExpanded) ...[
                  SizedBox(height: AppTheme.spacingMd),
                  
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
                  
                  SizedBox(height: AppTheme.spacingXs),
                  
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
                ],
                
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
  
  Widget _quickSelectChip(String label, int days, {bool isRecommended = false}) {
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
    
    // Determine border color - recommended chips get a subtle glow
    final borderColor = isSelected
        ? DynamicTheme.getChipBorderColor(colorScheme, isSelected)
        : (isRecommended
            ? colorScheme.primary1.withOpacity(0.3) // Subtle glow for recommended
            : DynamicTheme.getChipBorderColor(colorScheme, isSelected));
    
    // Determine border width - recommended chips get slightly thicker border
    final borderWidth = isSelected
        ? DynamicTheme.getChipBorderWidth(isSelected)
        : (isRecommended ? 1.5 : 1.0);
    
    return Container(
      decoration: isRecommended && !isSelected
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary1.withOpacity(0.15),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            )
          : null,
      child: ActionChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isRecommended && !isSelected) ...[
              Icon(
                Icons.star,
                size: 14,
                color: colorScheme.primary1.withOpacity(0.7),
              ),
              SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: DynamicTheme.getChipLabelColor(colorScheme, isSelected),
                fontSize: 13,
                fontWeight: isRecommended ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
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
          color: borderColor,
          width: borderWidth,
        ),
        elevation: DynamicTheme.getChipElevation(isSelected),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// Custom time picker dialog with hour/minute selectors instead of dial
class _CustomTimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;
  final AppColorScheme colorScheme;

  const _CustomTimePickerDialog({
    required this.initialTime,
    required this.colorScheme,
  });

  @override
  State<_CustomTimePickerDialog> createState() => _CustomTimePickerDialogState();
}

class _CustomTimePickerDialogState extends State<_CustomTimePickerDialog> {
  late int _selectedHour;
  late int _selectedMinute;
  late bool _isAm;

  @override
  void initState() {
    super.initState();
    final hour = widget.initialTime.hour;
    _selectedHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    _selectedMinute = widget.initialTime.minute;
    _isAm = hour < 12;
  }

  void _updateHour(int hour) {
    setState(() {
      _selectedHour = hour;
    });
  }

  void _updateMinute(int minute) {
    setState(() {
      _selectedMinute = minute;
    });
  }

  TimeOfDay _getSelectedTime() {
    int hour24 = _selectedHour;
    if (!_isAm && _selectedHour != 12) {
      hour24 = _selectedHour + 12;
    } else if (_isAm && _selectedHour == 12) {
      hour24 = 0;
    }
    return TimeOfDay(hour: hour24, minute: _selectedMinute);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.colorScheme;
    
    return Dialog(
      backgroundColor: DynamicTheme.getDialogBackgroundColor(colorScheme),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Container(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Time',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: DynamicTheme.getDialogTitleColor(colorScheme),
                      ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: DynamicTheme.getSecondaryIconColor(colorScheme),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingXl),
            
            // Time picker
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Hour picker
                Flexible(
                  child: _TimePickerColumn(
                    label: 'Hour',
                    value: _selectedHour,
                    min: 1,
                    max: 12,
                    onChanged: _updateHour,
                    colorScheme: colorScheme,
                  ),
                ),
                
                SizedBox(width: AppTheme.spacingSm),
                
                // Separator
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    ':',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      color: DynamicTheme.getPrimaryTextColor(colorScheme),
                    ),
                  ),
                ),
                
                SizedBox(width: AppTheme.spacingSm),
                
                // Minute picker
                Flexible(
                  child: _TimePickerColumn(
                    label: 'Minute',
                    value: _selectedMinute,
                    min: 0,
                    max: 59,
                    step: 5,
                    onChanged: _updateMinute,
                    colorScheme: colorScheme,
                  ),
                ),
                
                SizedBox(width: AppTheme.spacingSm),
                
                // AM/PM toggle
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 24),
                      _PeriodButton(
                        label: 'AM',
                        isSelected: _isAm,
                        onTap: () => setState(() => _isAm = true),
                        colorScheme: colorScheme,
                      ),
                      SizedBox(height: AppTheme.spacingSm),
                      _PeriodButton(
                        label: 'PM',
                        isSelected: !_isAm,
                        onTap: () => setState(() => _isAm = false),
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: AppTheme.spacingXl),
            
            // Selected time display
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacingLg,
                vertical: AppTheme.spacingMd,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primary1.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: colorScheme.primary1.withOpacity(0.3),
                ),
              ),
              child: Text(
                _getSelectedTime().format(context),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: DynamicTheme.getDialogTitleColor(colorScheme),
                ),
              ),
            ),
            
            SizedBox(height: AppTheme.spacingXl),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
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
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_getSelectedTime()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary1,
                      foregroundColor: DynamicTheme.getButtonTextColor(colorScheme),
                      padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      ),
                    ),
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Scrollable column for selecting hour or minute
class _TimePickerColumn extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;
  final AppColorScheme colorScheme;

  const _TimePickerColumn({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    required this.onChanged,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final items = <int>[];
    for (int i = min; i <= max; i += step) {
      items.add(i);
    }

    return Column(
      children: [
        Text(
          label,
                      style: TextStyle(
                        fontSize: 12,
                        color: DynamicTheme.getDialogContentColor(colorScheme).withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
        ),
        SizedBox(height: AppTheme.spacingXs),
        Container(
          width: 80,
          height: 200,
          decoration: BoxDecoration(
            color: DynamicTheme.getCardBackgroundColor(colorScheme),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: colorScheme.accent.withOpacity(0.2),
            ),
          ),
          child: ListWheelScrollView.useDelegate(
            itemExtent: 50,
            diameterRatio: 1.5,
            physics: const FixedExtentScrollPhysics(),
            controller: FixedExtentScrollController(
              initialItem: items.indexOf(value),
            ),
            onSelectedItemChanged: (index) {
              if (index >= 0 && index < items.length) {
                onChanged(items[index]);
              }
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                if (index < 0 || index >= items.length) return null;
                final itemValue = items[index];
                final isSelected = itemValue == value;
                
                return Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary1.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text(
                      itemValue.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: isSelected ? 24 : 18,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? DynamicTheme.getDialogTitleColor(colorScheme)
                            : DynamicTheme.getDialogContentColor(colorScheme),
                      ),
                    ),
                  ),
                );
              },
              childCount: items.length,
            ),
          ),
        ),
      ],
    );
  }
}

/// AM/PM period button
class _PeriodButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final AppColorScheme colorScheme;

  const _PeriodButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary1
              : DynamicTheme.getCardBackgroundColor(colorScheme),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary1
                : colorScheme.accent.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? DynamicTheme.getButtonTextColor(colorScheme)
                          : DynamicTheme.getDialogButtonColor(colorScheme),
                    ),
          ),
        ),
      ),
    );
  }
}
