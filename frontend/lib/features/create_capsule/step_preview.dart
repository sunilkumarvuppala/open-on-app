import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/theme/color_scheme.dart';

class StepPreview extends ConsumerWidget {
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  
  const StepPreview({
    super.key,
    required this.onBack,
    required this.onSubmit,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(draftCapsuleProvider);
    final recipient = draft.recipient!;
    final unlockAt = draft.unlockAt!;
    final label = draft.label?.isNotEmpty == true
        ? draft.label!
        : 'A special letter';
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final dreamyGradient = DynamicTheme.dreamyGradient(colorScheme);
    
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preview your letter',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: DynamicTheme.getPrimaryTextColor(colorScheme),
                      ),
                ),
                SizedBox(height: AppTheme.spacingSm),
                Text(
                  'Everything looks good? Let\'s send it!',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: DynamicTheme.getSecondaryTextColor(colorScheme),
                      ),
                ),
                SizedBox(height: AppTheme.spacingXl),
                
                // Envelope preview
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppTheme.spacingLg),
                  decoration: BoxDecoration(
                    gradient: dreamyGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary1.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Envelope icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: DynamicTheme.getCardBackgroundColor(colorScheme, opacity: AppTheme.opacityHigh),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mail_outline,
                          size: 40,
                          color: DynamicTheme.getPrimaryIconColor(colorScheme),
                        ),
                      ),
                      
                      SizedBox(height: AppTheme.spacingLg),
                      
                      // Label
                      Text(
                        label,
                        style: TextStyle(
                          color: DynamicTheme.getPrimaryTextColor(colorScheme),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: AppTheme.spacingSm),
                      
                      // To/From
                      Text(
                        'To: ${recipient.name}',
                        style: TextStyle(
                          color: DynamicTheme.getSecondaryTextColor(colorScheme, opacity: AppTheme.opacityFull),
                          fontSize: 14,
                        ),
                      ),
                      if (draft.isAnonymous) ...[
                        SizedBox(height: AppTheme.spacingXs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.visibility_off_outlined,
                              size: 14,
                              color: DynamicTheme.getSecondaryTextColor(colorScheme, opacity: AppTheme.opacityFull),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Anonymous',
                              style: TextStyle(
                                color: DynamicTheme.getSecondaryTextColor(colorScheme, opacity: AppTheme.opacityFull),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                SizedBox(height: AppTheme.spacingXl),
                
                // Details card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spacingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(
                          context,
                          icon: Icons.person_outline,
                          label: 'Recipient',
                          value: recipient.username != null && recipient.username!.isNotEmpty
                              ? '${recipient.name} (@${recipient.username})'
                              : recipient.name,
                          primaryColor: colorScheme.primary1,
                          colorScheme: colorScheme,
                        ),
                        Divider(height: AppTheme.spacingXl),
                        _buildDetailRow(
                          context,
                          icon: Icons.access_time,
                          label: 'Unlocks On',
                          value: DateFormat('EEEE, MMMM d, y \'at\' h:mm a').format(unlockAt),
                          primaryColor: colorScheme.primary1,
                          colorScheme: colorScheme,
                        ),
                        Divider(height: AppTheme.spacingXl),
                        _buildDetailRow(
                          context,
                          icon: Icons.description_outlined,
                          label: 'Letter Length',
                          value: '${draft.content?.length ?? 0} characters',
                          primaryColor: colorScheme.primary1,
                          colorScheme: colorScheme,
                        ),
                        if (draft.photoPath != null) ...[
                          Divider(height: AppTheme.spacingXl),
                          _buildDetailRow(
                            context,
                            icon: Icons.photo_outlined,
                            label: 'Photo',
                            value: 'Included',
                            primaryColor: colorScheme.primary1,
                            colorScheme: colorScheme,
                          ),
                        ],
                        if (draft.isAnonymous) ...[
                          Divider(height: AppTheme.spacingXl),
                          _buildDetailRow(
                            context,
                            icon: Icons.visibility_off_outlined,
                            label: 'Anonymous',
                            value: _getRevealDelayText(draft.revealDelaySeconds ?? 21600),
                            primaryColor: colorScheme.primary1,
                            colorScheme: colorScheme,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: AppTheme.spacingLg),
                
                // Letter preview
                Text(
                  'Letter Preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: DynamicTheme.getPrimaryTextColor(colorScheme),
                      ),
                ),
                SizedBox(height: AppTheme.spacingSm),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: DynamicTheme.getCardBackgroundColor(colorScheme),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: DynamicTheme.getBorderColor(colorScheme),
                    ),
                  ),
                  child: Text(
                    draft.content ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                        color: DynamicTheme.getSecondaryTextColor(colorScheme),
                        ),
                  ),
                ),
                
                if (draft.photoPath != null) ...[
                  SizedBox(height: AppTheme.spacingLg),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: Image.file(
                      File(draft.photoPath!),
                      width: double.infinity,
                      fit: BoxFit.cover,
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
                  onPressed: onBack,
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
                child: ElevatedButton.icon(
                  onPressed: onSubmit,
                  icon: const Icon(Icons.send),
                  label: const Text('Send Letter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary1,
                    foregroundColor: DynamicTheme.getButtonTextColor(colorScheme),
                    padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                    side: DynamicTheme.getButtonBorderSide(colorScheme),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  String _getRevealDelayText(int seconds) {
    if (seconds == 0) return 'On open';
    final hours = seconds ~/ 3600;
    if (hours == 1) return '1 hour after opening';
    if (hours < 24) return '$hours hours after opening';
    final days = hours ~/ 24;
    if (days == 1) return '1 day after opening';
    return '$days days after opening';
  }
  
  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color primaryColor,
    required AppColorScheme colorScheme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: primaryColor),
        SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: DynamicTheme.getSecondaryTextColor(colorScheme),
                ),
              ),
              SizedBox(height: AppTheme.spacingXs),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: DynamicTheme.getPrimaryTextColor(colorScheme),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
