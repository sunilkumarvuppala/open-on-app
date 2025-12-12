import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:intl/intl.dart';

class CapsuleCard extends ConsumerWidget {
  final Capsule capsule;
  final VoidCallback onTap;
  
  const CapsuleCard({
    super.key,
    required this.capsule,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: colorScheme.primary1.withOpacity(0.1),
                child: Text(
                  capsule.receiverName[0].toUpperCase(),
                  style: TextStyle(
                    color: colorScheme.primary1,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              SizedBox(width: AppTheme.spacingMd),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      capsule.receiverName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: DynamicTheme.getPrimaryTextColor(colorScheme),
                          ),
                    ),
                    SizedBox(height: AppTheme.spacingXs),
                    Text(
                      capsule.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: DynamicTheme.getSecondaryTextColor(colorScheme),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppTheme.spacingSm),
                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(),
                          size: 16,
                          color: _getStatusColor(colorScheme.primary1),
                        ),
                        SizedBox(width: AppTheme.spacingXs),
                        Text(
                          _getStatusText(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _getStatusColor(colorScheme.primary1),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Status badge and chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSm,
                      vertical: AppTheme.spacingXs,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(colorScheme.primary1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Text(
                      _getStatusBadgeText(),
                      style: TextStyle(
                        color: _getStatusColor(colorScheme.primary1),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingSm),
                  Icon(
                    Icons.chevron_right,
                    color: DynamicTheme.getSecondaryIconColor(colorScheme),
                    size: 24,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  IconData _getStatusIcon() {
    switch (capsule.status) {
      case CapsuleStatus.locked:
        return Icons.lock_outline;
      case CapsuleStatus.unlockingSoon:
        return Icons.access_time;
      case CapsuleStatus.ready:
        return Icons.lock_open;
      case CapsuleStatus.opened:
        return Icons.check_circle_outline;
    }
  }
  
  Color _getStatusColor(Color primaryColor) {
    switch (capsule.status) {
      case CapsuleStatus.locked:
        return primaryColor;
      case CapsuleStatus.unlockingSoon:
        return AppColors.warning;
      case CapsuleStatus.ready:
        return AppTheme.successGreen;
      case CapsuleStatus.opened:
        return AppTheme.successGreen;
    }
  }
  
  String _getStatusText() {
    if (capsule.status == CapsuleStatus.opened) {
      return 'Opened ${_formatDate(capsule.openedAt ?? capsule.unlockAt)}';
    }
    return 'Unlocks ${_formatDate(capsule.unlockAt)}';
  }
  
  String _getStatusBadgeText() {
    switch (capsule.status) {
      case CapsuleStatus.locked:
        return capsule.countdownText;
      case CapsuleStatus.unlockingSoon:
        return capsule.countdownText;
      case CapsuleStatus.ready:
        return 'Ready';
      case CapsuleStatus.opened:
        return 'Opened';
    }
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'today';
    } else if (difference == 1) {
      return 'tomorrow';
    } else if (difference == -1) {
      return 'yesterday';
    } else if (difference > 0 && difference < 7) {
      return 'in ${difference}d';
    } else if (difference < 0 && difference > -7) {
      return '${-difference}d ago';
    }
    
    return DateFormat('MMM d, y').format(date);
  }
}
