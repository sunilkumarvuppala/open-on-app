import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/utils/logger.dart';

class StepAnonymousSettings extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  
  const StepAnonymousSettings({
    super.key,
    required this.onNext,
    required this.onBack,
  });
  
  @override
  ConsumerState<StepAnonymousSettings> createState() => _StepAnonymousSettingsState();
}

class _StepAnonymousSettingsState extends ConsumerState<StepAnonymousSettings> {
  bool _isCheckingConnection = false;
  bool _isMutualConnection = false;
  bool _hasCheckedConnection = false;
  
  // Reveal delay options in seconds
  static const List<Map<String, dynamic>> _revealDelayOptions = [
    {'label': 'On open', 'seconds': 0, 'hours': 0},
    {'label': '1 hour', 'seconds': 3600, 'hours': 1},
    {'label': '6 hours', 'seconds': 21600, 'hours': 6},
    {'label': '12 hours', 'seconds': 43200, 'hours': 12},
    {'label': '24 hours', 'seconds': 86400, 'hours': 24},
    {'label': '48 hours', 'seconds': 172800, 'hours': 48},
    {'label': '72 hours', 'seconds': 259200, 'hours': 72},
  ];
  
  @override
  void initState() {
    super.initState();
    _checkMutualConnection();
  }
  
  Future<void> _checkMutualConnection() async {
    final draft = ref.read(draftCapsuleProvider);
    final recipient = draft.recipient;
    
    if (recipient == null || recipient.linkedUserId == null) {
      setState(() {
        _isMutualConnection = false;
        _hasCheckedConnection = true;
      });
      return;
    }
    
    setState(() {
      _isCheckingConnection = true;
    });
    
    try {
      final userAsync = ref.read(currentUserProvider);
      final currentUser = userAsync.asData?.value;
      if (currentUser == null) {
        setState(() {
          _isMutualConnection = false;
          _hasCheckedConnection = true;
          _isCheckingConnection = false;
        });
        return;
      }
      
      final connectionRepo = ref.read(connectionRepositoryProvider);
      final isConnected = await connectionRepo.areConnected(
        currentUser.id,
        recipient.linkedUserId!,
      );
      
      setState(() {
        _isMutualConnection = isConnected;
        _hasCheckedConnection = true;
        _isCheckingConnection = false;
      });
      
      Logger.info(
        'Mutual connection check: recipient=${recipient.linkedUserId}, '
        'isConnected=$isConnected'
      );
    } catch (e, stackTrace) {
      Logger.error('Failed to check mutual connection', error: e, stackTrace: stackTrace);
      setState(() {
        _isMutualConnection = false;
        _hasCheckedConnection = true;
        _isCheckingConnection = false;
      });
    }
  }
  
  void _saveAndContinue() {
    final draft = ref.read(draftCapsuleProvider);
    
    // If anonymous is enabled but no delay is set, use default (6 hours)
    if (draft.isAnonymous && draft.revealDelaySeconds == null) {
      ref.read(draftCapsuleProvider.notifier).setRevealDelaySeconds(21600); // 6 hours default
    }
    
    widget.onNext();
  }
  
  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(draftCapsuleProvider);
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
                  'Anonymous Letter',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: DynamicTheme.getPrimaryTextColor(colorScheme),
                      ),
                ),
                SizedBox(height: AppTheme.spacingSm),
                Text(
                  'Temporarily hide your identity when sending',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: DynamicTheme.getSecondaryTextColor(colorScheme),
                      ),
                ),
                SizedBox(height: AppTheme.spacingXl),
                
                // Check if mutual connection
                if (_isCheckingConnection)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spacingXl),
                      child: CircularProgressIndicator(
                        color: colorScheme.primary1,
                      ),
                    ),
                  )
                else if (!_hasCheckedConnection)
                  const SizedBox.shrink()
                else if (!_isMutualConnection) ...[
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
                            'Anonymous letters are only available for mutual connections. '
                            'Please connect with this user first.',
                            style: TextStyle(
                              color: DynamicTheme.getInfoTextColor(colorScheme),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
                else ...[
                  // Anonymous toggle
                  Card(
                    elevation: 2,
                    color: DynamicTheme.getCardBackgroundColor(colorScheme),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                    child: SwitchListTile(
                      value: draft.isAnonymous,
                      onChanged: (value) {
                        ref.read(draftCapsuleProvider.notifier).setIsAnonymous(value);
                        if (value && draft.revealDelaySeconds == null) {
                          // Set default to 6 hours when enabling anonymous
                          ref.read(draftCapsuleProvider.notifier).setRevealDelaySeconds(21600);
                        } else if (!value) {
                          // Clear delay when disabling anonymous
                          ref.read(draftCapsuleProvider.notifier).setRevealDelaySeconds(null);
                        }
                      },
                      title: Text(
                        'Send anonymously',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: DynamicTheme.getPrimaryTextColor(colorScheme),
                        ),
                      ),
                      subtitle: Text(
                        'Your identity will be revealed automatically after opening',
                        style: TextStyle(
                          color: DynamicTheme.getSecondaryTextColor(colorScheme),
                          fontSize: 13,
                        ),
                      ),
                      activeColor: colorScheme.primary1,
                    ),
                  ),
                  
                  // Reveal delay selector (only shown if anonymous is enabled)
                  if (draft.isAnonymous) ...[
                    SizedBox(height: AppTheme.spacingXl),
                    Text(
                      'Reveal delay',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: DynamicTheme.getPrimaryTextColor(colorScheme),
                          ),
                    ),
                    SizedBox(height: AppTheme.spacingSm),
                    Text(
                      'Identity reveals automatically after opening (default: 6 hours, max: 3 days)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: DynamicTheme.getSecondaryTextColor(colorScheme),
                          ),
                    ),
                    SizedBox(height: AppTheme.spacingMd),
                    
                    // Reveal delay options
                    Wrap(
                      spacing: AppTheme.chipSpacing,
                      runSpacing: AppTheme.chipSpacing,
                      children: _revealDelayOptions.map((option) {
                        final seconds = option['seconds'] as int;
                        final isSelected = draft.revealDelaySeconds == seconds;
                        
                        return ActionChip(
                          label: Text(
                            option['label'] as String,
                            style: TextStyle(
                              color: DynamicTheme.getChipLabelColor(colorScheme, isSelected),
                              fontSize: 13,
                            ),
                          ),
                          onPressed: () {
                            ref.read(draftCapsuleProvider.notifier).setRevealDelaySeconds(seconds);
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
                      }).toList(),
                    ),
                  ],
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
                  onPressed: _saveAndContinue,
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
}
