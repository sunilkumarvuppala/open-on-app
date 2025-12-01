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
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.deepPurple,
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
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.deepPurple,
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
    
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'When should ${recipient?.name ?? "they"} open this?',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose the perfect moment for the reveal',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.gray,
                      ),
                ),
                const SizedBox(height: 48),
                
                // Quick selection chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _quickSelectChip('Tomorrow, 9 AM', 1),
                    _quickSelectChip('In 1 week', 7),
                    _quickSelectChip('In 1 month', 30),
                    _quickSelectChip('In 3 months', 90),
                    _quickSelectChip('In 1 year', 365),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                const Divider(),
                
                const SizedBox(height: 32),
                
                Text(
                  'Or choose a custom date and time',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                
                const SizedBox(height: 24),
                
                // Date picker
                Card(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: AppColors.deepPurple),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.gray,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedDate != null
                                      ? DateFormat('EEEE, MMMM d, y').format(_selectedDate!)
                                      : 'Select a date',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedDate != null
                                        ? AppColors.darkGray
                                        : AppColors.gray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.gray),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Time picker
                Card(
                  child: InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: AppColors.deepPurple),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Time',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.gray,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedTime != null
                                      ? _selectedTime!.format(context)
                                      : 'Select a time',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedTime != null
                                        ? AppColors.darkGray
                                        : AppColors.gray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.gray),
                        ],
                      ),
                    ),
                  ),
                ),
                
                if (_combinedDateTime != null) ...[
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.deepPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.deepPurple.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.deepPurple),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This letter will unlock on ${DateFormat('MMMM d, y').format(_combinedDateTime!)} at ${_selectedTime!.format(context)}',
                            style: const TextStyle(
                              color: AppColors.deepPurple,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.error, fontSize: 14),
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
          padding: const EdgeInsets.all(24),
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isValidTime ? _saveAndContinue : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
      backgroundColor: AppColors.deepPurple.withOpacity(0.1),
      labelStyle: const TextStyle(
        color: AppColors.deepPurple,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
