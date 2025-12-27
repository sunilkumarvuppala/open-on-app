import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:openon_app/core/models/models.dart';
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
            padding: EdgeInsets.fromLTRB(
              AppTheme.spacingLg,
              AppTheme.spacingMd,
              AppTheme.spacingLg,
              AppTheme.spacingLg,
            ),
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
                
                // Optional metadata fields for self letters (when recipient is "myself")
                Builder(
                  builder: (context) {
                    final userAsync = ref.watch(currentUserProvider);
                    final user = userAsync.asData?.value;
                    final isSelfLetter = user != null && 
                                        recipient != null && 
                                        recipient.linkedUserId == user.id;
                    
                    if (!isSelfLetter) {
                      return const SizedBox.shrink();
                    }
                    
                    return _SelfLetterMetadataSection(
                      draft: draft,
                      colorScheme: colorScheme,
                    );
                  },
                ),
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

// Optional metadata section for self letters
class _SelfLetterMetadataSection extends ConsumerStatefulWidget {
  final DraftCapsule draft;
  final AppColorScheme colorScheme;
  
  const _SelfLetterMetadataSection({
    required this.draft,
    required this.colorScheme,
  });
  
  @override
  ConsumerState<_SelfLetterMetadataSection> createState() => _SelfLetterMetadataSectionState();
}

class _SelfLetterMetadataSectionState extends ConsumerState<_SelfLetterMetadataSection> {
  final TextEditingController _cityController = TextEditingController();
  String? _selectedMood;
  String? _selectedLifeArea;
  
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
  static const List<Map<String, String>> _lifeAreaOptions = [
    {'value': 'self', 'label': 'Self'},
    {'value': 'work', 'label': 'Work'},
    {'value': 'family', 'label': 'Family'},
    {'value': 'money', 'label': 'Money'},
    {'value': 'health', 'label': 'Health'},
  ];
  
  @override
  void initState() {
    super.initState();
    _selectedMood = widget.draft.mood;
    _selectedLifeArea = widget.draft.lifeArea;
    _cityController.text = widget.draft.city ?? '';
  }
  
  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
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
        // displayStringForOption returns only text, so the field will show only text
        // (emoji is displayed in prefixIcon)
      },
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController textEditingController,
        FocusNode focusNode,
        VoidCallback onFieldSubmitted,
      ) {
        // Ensure text field shows only text when mood is selected (emoji in prefixIcon)
        if (selectedMood != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final currentText = textEditingController.text;
            final expectedText = selectedOption['text'] ?? '';
            // Only update if the text includes emoji or doesn't match expected text
            if (currentText != expectedText && currentText.isNotEmpty) {
              textEditingController.text = expectedText;
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
                ? SizedBox(
                    width: 40,
                    height: 48,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 8),
                        child: Text(
                          selectedOption['emoji'] ?? '',
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  )
                : Icon(
                    Icons.search,
                    color: DynamicTheme.getInputHintColor(colorScheme),
                  ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 48,
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
  
  void _updateMetadata() {
    ref.read(draftCapsuleProvider.notifier).setSelfLetterMetadata(
      mood: _selectedMood,
      lifeArea: _selectedLifeArea,
      city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppTheme.spacingXl),
        Divider(color: DynamicTheme.getDividerColor(widget.colorScheme)),
        const SizedBox(height: AppTheme.spacingLg),
        
        Text(
          'Optional context',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Add context to remember this moment',
          style: theme.textTheme.bodySmall?.copyWith(
            color: DynamicTheme.getSecondaryTextColor(widget.colorScheme).withOpacity(0.7),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        
        // Mood searchable dropdown
        Text(
          'Mood',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: DynamicTheme.getSecondaryTextColor(widget.colorScheme),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        _buildMoodDropdown(
          selectedMood: _selectedMood,
          onChanged: (value) {
            setState(() {
              _selectedMood = value;
            });
            _updateMetadata();
          },
          colorScheme: widget.colorScheme,
          theme: theme,
        ),
        
        const SizedBox(height: AppTheme.spacingLg),
        
        // Life area
        Text(
          'Life area',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: DynamicTheme.getSecondaryTextColor(widget.colorScheme),
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
              onSelected: (selected) {
                setState(() {
                  _selectedLifeArea = selected ? option['value'] : null;
                });
                _updateMetadata();
              },
              selectedColor: widget.colorScheme.primary1.withOpacity(0.2),
              checkmarkColor: widget.colorScheme.primary1,
              labelStyle: TextStyle(
                color: DynamicTheme.getChipLabelColor(widget.colorScheme, isSelected),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: AppTheme.spacingLg),
        
        // City - styled similar to "Add a title" field
        TextField(
          controller: _cityController,
          onChanged: (_) => _updateMetadata(),
          style: TextStyle(
            color: DynamicTheme.getInputTextColor(widget.colorScheme),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            labelText: 'City (optional)',
            labelStyle: TextStyle(
              color: DynamicTheme.getSecondaryTextColor(widget.colorScheme).withOpacity(0.7),
              fontSize: 13,
            ),
            hintText: 'Where are you writing from?',
            hintStyle: TextStyle(
              color: DynamicTheme.getInputHintColor(widget.colorScheme).withOpacity(0.5),
              fontSize: 14,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingSm,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide(
                color: DynamicTheme.getButtonBorderColor(widget.colorScheme).withOpacity(0.2),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide(
                color: DynamicTheme.getButtonBorderColor(widget.colorScheme).withOpacity(0.2),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide(
                color: DynamicTheme.getButtonBorderColor(widget.colorScheme).withOpacity(0.4),
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
