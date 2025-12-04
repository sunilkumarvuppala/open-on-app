import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/router/app_router.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';

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
          ),
          body: ListView(
            padding: EdgeInsets.all(AppTheme.spacingLg),
            children: [
              // Profile header
              Center(
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.accent.withOpacity(AppTheme.opacityAlmostFull2),
                          width: AppTheme.borderWidthStandard,
                        ),
                        boxShadow: [
                          // Reduced glow
                          BoxShadow(
                            color: colorScheme.accent.withOpacity(AppTheme.opacityMediumHigh),
                            blurRadius: AppTheme.glowBlurRadiusMedium,
                            spreadRadius: AppTheme.glowSpreadRadiusSmall,
                          ),
                          // Subtle shadow
                          BoxShadow(
                            color: colorScheme.primary1.withOpacity(AppTheme.opacityMediumHigh),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: colorScheme.primary1,
                        child: Text(
                          user.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: DynamicTheme.getSecondaryTextColor(colorScheme),
                          ),
                    ),
                    SizedBox(height: AppTheme.spacingMd),
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Implement edit profile
                        final colorScheme = ref.read(selectedColorSchemeProvider);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Edit profile feature coming soon',
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
              
              // Settings sections
              _buildSectionTitle(context, 'Account', ref),
              _buildSettingsTile(
                context,
                ref,
                icon: Icons.manage_accounts_outlined,
                title: 'Manage Recipients',
                onTap: () => context.push(Routes.recipients),
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
                title: 'Notifications',
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
              
              SizedBox(height: AppTheme.spacingLg),
              
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
              
              SizedBox(height: AppTheme.spacingLg),
              
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
              
              // Logout button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    final colorScheme = ref.read(selectedColorSchemeProvider);
                    
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: DynamicTheme.getCardBackgroundColor(colorScheme),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        ),
                        title: Text(
                          'Log out',
                          style: TextStyle(
                            color: DynamicTheme.getPrimaryTextColor(colorScheme),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        content: Text(
                          'Are you sure you want to log out?',
                          style: TextStyle(
                            color: DynamicTheme.getSecondaryTextColor(colorScheme),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: DynamicTheme.getPrimaryTextColor(colorScheme),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
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
                        
                        // Invalidate auth state to trigger refresh
                        ref.invalidate(currentUserProvider);
                        
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
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                  ),
                  child: const Text('Log Out'),
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
  
  Widget _buildSectionTitle(BuildContext context, String title, WidgetRef ref) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: DynamicTheme.getLabelTextColor(colorScheme),
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
  }) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    
    return Card(
      margin: EdgeInsets.only(bottom: AppTheme.spacingSm),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        leading: Icon(
          icon, 
          color: DynamicTheme.getPrimaryIconColor(colorScheme),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: DynamicTheme.getPrimaryTextColor(colorScheme),
            fontWeight: FontWeight.w500,
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
          color: DynamicTheme.getSecondaryIconColor(colorScheme),
        ),
        onTap: onTap,
      ),
    );
  }
}
