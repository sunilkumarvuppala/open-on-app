import 'package:flutter/material.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class CapsuleCard extends StatelessWidget {
  final Capsule capsule;
  final VoidCallback onTap;
  
  const CapsuleCard({
    super.key,
    required this.capsule,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.deepPurple.withOpacity(0.1),
                child: Text(
                  capsule.receiverName[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.deepPurple,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      capsule.receiverName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      capsule.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.gray,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(),
                          size: 16,
                          color: _getStatusColor(),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getStatusText(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _getStatusColor(),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusBadgeText(),
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.gray,
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
      case CapsuleStatus.opened:
        return Icons.check_circle_outline;
    }
  }
  
  Color _getStatusColor() {
    switch (capsule.status) {
      case CapsuleStatus.locked:
        return AppColors.deepPurple;
      case CapsuleStatus.unlockingSoon:
        return AppColors.warning;
      case CapsuleStatus.opened:
        return AppColors.success;
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
