import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/router/app_router.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/widgets/common_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    
    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Not authenticated')),
          );
        }
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: DynamicTheme.getPrimaryIconColor(colorScheme),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              TextButton(
                onPressed: () => _handleLogout(context, ref),
                child: Text(
                  'Log Out',
                  style: TextStyle(
                    color: DynamicTheme.getPrimaryTextColor(colorScheme),
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: EdgeInsets.all(AppTheme.spacingLg),
            children: [
              // Profile header
              Center(
                child: Column(
                  children: [
                    UserAvatar(
                      imageUrl: user.avatarUrl,
                      imagePath: user.localAvatarPath,
                      name: user.name,
                      size: 100,
                    ),
                    SizedBox(height: AppTheme.spacingMd),
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: DynamicTheme.getPrimaryTextColor(colorScheme),
                          ),
                    ),
                    SizedBox(height: AppTheme.spacingXs),
                    // Subtle secondary line reinforcing product intent
                    Text(
                      'Private letters, sealed with intention',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(0.7),
                            fontStyle: FontStyle.italic,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppTheme.spacingMd),
                    OutlinedButton.icon(
                      onPressed: () {
                        context.push(Routes.editProfile);
                      },
                      icon: Icon(
                        Icons.edit, 
                        size: 18,
                        color: DynamicTheme.getOutlinedButtonTextColor(colorScheme),
                      ),
                      label: Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: DynamicTheme.getOutlinedButtonTextColor(colorScheme),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: DynamicTheme.getOutlinedButtonBorderColor(colorScheme),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: AppTheme.spacingXl),
              
              // Account section
              _buildSectionTitle(context, 'Account', ref),
              // Manage Connections - emphasized as first item with subtle elevation
              _buildSettingsTile(
                context,
                ref,
                icon: Icons.people_outlined,
                title: 'Manage Connections',
                onTap: () => context.push(Routes.connections),
                isEmphasized: true,
              ),
              _buildSettingsTile(
                context,
                ref,
                icon: Icons.palette_outlined,
                title: 'Color Theme',
                onTap: () => context.push(Routes.colorScheme),
              ),
              _buildSettingsTile(
                context,
                ref,
                icon: Icons.notifications_outlined,
                title: 'Letter Alerts',
                onTap: () {
                  final colorScheme = ref.read(selectedColorSchemeProvider);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Notification settings coming soon',
                        style: TextStyle(
                          color: colorScheme.isDarkTheme ? Colors.white : Colors.black,
                        ),
                      ),
                      backgroundColor: DynamicTheme.getCardBackgroundColor(colorScheme),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                  );
                },
              ),
              
              SizedBox(height: AppTheme.spacingXl),
              
              // Privacy & Trust section
              _buildSectionTitle(context, 'Privacy & Trust', ref),
              _buildSettingsTile(
                context,
                ref,
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () {
                  // TODO: Open privacy policy
                },
              ),
              _buildSettingsTile(
                context,
                ref,
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                onTap: () {
                  // TODO: Open terms of service
                },
              ),
              
              SizedBox(height: AppTheme.spacingXl),
              
              // Support section
              _buildSectionTitle(context, 'Support', ref),
              _buildSettingsTile(
                context,
                ref,
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () {
                  final colorScheme = ref.read(selectedColorSchemeProvider);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Help center coming soon',
                        style: TextStyle(
                          color: DynamicTheme.getSnackBarTextColor(colorScheme),
                        ),
                      ),
                      backgroundColor: DynamicTheme.getSnackBarBackgroundColor(colorScheme),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                  );
                },
              ),
              
              SizedBox(height: AppTheme.spacingXl),
              
              // About section
              _buildSectionTitle(context, 'About', ref),
              _buildSettingsTile(
                context,
                ref,
                icon: Icons.info_outline,
                title: 'About OpenOn',
                subtitle: 'Version 1.0.0',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'OpenOn',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2024 OpenOn. All rights reserved.',
                  );
                },
              ),
              
              SizedBox(height: AppTheme.spacingXl),
              
              // Emotional reinforcement line
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                  child: Text(
                    'Some letters are meant to wait.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(0.6),
                          fontStyle: FontStyle.italic,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              
              SizedBox(height: AppTheme.spacingLg),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
  
  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final colorScheme = ref.read(selectedColorSchemeProvider);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DynamicTheme.getDialogBackgroundColor(colorScheme),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text(
          'Log out of OpenOn?',
          style: TextStyle(
            color: DynamicTheme.getDialogTitleColor(colorScheme),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'You can sign back in anytime.',
          style: TextStyle(
            color: DynamicTheme.getDialogContentColor(colorScheme),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: DynamicTheme.getDialogButtonColor(colorScheme),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: DynamicTheme.getSecondaryTextColor(colorScheme),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && context.mounted) {
      try {
        final authRepo = ref.read(authRepositoryProvider);
        await authRepo.signOut();
        
        // CRITICAL: Invalidate ALL data providers to prevent data leakage between users
        // This ensures that when a new user logs in, they don't see the previous user's data
        // Invalidating family providers invalidates all instances (all userIds)
        ref.invalidate(currentUserProvider);
        ref.invalidate(capsulesProvider); // Invalidates all capsulesProvider(userId) instances
        ref.invalidate(incomingCapsulesProvider); // Invalidates all incomingCapsulesProvider(userId) instances
        ref.invalidate(recipientsProvider); // Invalidates all recipientsProvider(userId) instances
        ref.invalidate(draftsProvider); // Invalidates all draftsProvider(userId) instances
        ref.invalidate(connectionsProvider);
        ref.invalidate(pendingRequestsProvider);
        ref.invalidate(incomingRequestsProvider);
        ref.invalidate(outgoingRequestsProvider);
        ref.invalidate(connectionDetailProvider); // Invalidates all connectionDetailProvider(connectionId) instances
        
        // Also invalidate derived providers that depend on base providers
        // These will automatically refresh when base providers are invalidated,
        // but we invalidate them explicitly to be safe
        ref.invalidate(upcomingCapsulesProvider);
        ref.invalidate(unlockingSoonCapsulesProvider);
        ref.invalidate(openedCapsulesProvider);
        ref.invalidate(incomingLockedCapsulesProvider);
        ref.invalidate(incomingOpeningSoonCapsulesProvider);
        ref.invalidate(incomingReadyCapsulesProvider);
        ref.invalidate(incomingOpenedCapsulesProvider);
        ref.invalidate(draftsCountProvider);
        ref.invalidate(draftsNotifierProvider);
        
        // Reset draft capsule state
        ref.read(draftCapsuleProvider.notifier).reset();
        
        if (context.mounted) {
          context.go(Routes.welcome);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to log out'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
          );
        }
      }
    }
  }
  
  Widget _buildSectionTitle(BuildContext context, String title, WidgetRef ref) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    return Padding(
      padding: EdgeInsets.only(
        bottom: AppTheme.spacingSm,
        top: AppTheme.spacingXs,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: DynamicTheme.getLabelTextColor(colorScheme),
              letterSpacing: 0.5,
            ),
      ),
    );
  }
  
  Widget _buildSettingsTile(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isEmphasized = false,
    bool isReference = false,
  }) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    
    return Card(
      margin: EdgeInsets.only(bottom: AppTheme.spacingSm),
      elevation: isEmphasized ? 3 : (isReference ? 1 : 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      color: isReference 
          ? DynamicTheme.getCardBackgroundColor(colorScheme).withOpacity(0.7)
          : DynamicTheme.getCardBackgroundColor(colorScheme),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        leading: Icon(
          icon, 
          color: isReference
              ? DynamicTheme.getPrimaryIconColor(colorScheme).withOpacity(0.7)
              : DynamicTheme.getPrimaryIconColor(colorScheme),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isReference
                ? DynamicTheme.getPrimaryTextColor(colorScheme).withOpacity(0.8)
                : DynamicTheme.getPrimaryTextColor(colorScheme),
            fontWeight: isEmphasized ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  color: DynamicTheme.getSecondaryTextColor(colorScheme),
                ),
              )
            : null,
        trailing: Icon(
          Icons.chevron_right, 
          color: isReference
              ? DynamicTheme.getSecondaryIconColor(colorScheme).withOpacity(0.5)
              : DynamicTheme.getSecondaryIconColor(colorScheme),
        ),
        onTap: onTap,
      ),
    );
  }
  
}
