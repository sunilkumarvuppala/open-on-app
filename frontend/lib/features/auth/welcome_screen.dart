import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openon_app/core/router/app_router.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/widgets/magic_dust_background.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final gradient = DynamicTheme.dreamyGradient(colorScheme);
    
    return Scaffold(
      body: MagicDustBackground(
        baseColor: colorScheme.primary1,
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
          ),
          child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // App logo or icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: DynamicTheme.getCardBackgroundColor(colorScheme, opacity: AppTheme.opacityHigh),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mail_outline,
                    size: 60,
                    color: DynamicTheme.getPrimaryIconColor(colorScheme),
                  ),
                ),
                
                SizedBox(height: AppTheme.spacingXl),
                
                // Headline
                Text(
                  'Send letters that unlock\nat the perfect moment',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: DynamicTheme.getPrimaryTextColor(colorScheme),
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                ),
                
                SizedBox(height: AppTheme.spacingLg),
                
                // Subtext
                Text(
                  'Create emotional time capsules for the people you love',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: DynamicTheme.getSecondaryTextColor(colorScheme, opacity: AppTheme.opacityFull),
                        fontSize: 16,
                      ),
                ),
                
                SizedBox(height: AppTheme.spacingMd),
                
                Text(
                  'Watch the magic unfold when the time is right',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: DynamicTheme.getSecondaryTextColor(colorScheme, opacity: AppTheme.opacityAlmostFull2),
                      ),
                ),
                
                const Spacer(),
                
                // CTA Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push(Routes.signup),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DynamicTheme.getCardBackgroundColor(colorScheme),
                      foregroundColor: DynamicTheme.getButtonTextColor(colorScheme),
                      padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                      side: DynamicTheme.getButtonBorderSide(colorScheme),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      ),
                    ),
                    child: Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: DynamicTheme.getButtonTextColor(colorScheme),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: AppTheme.spacingMd),
                
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.push(Routes.login),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DynamicTheme.getOutlinedButtonTextColor(colorScheme),
                      side: BorderSide(
                        color: DynamicTheme.getOutlinedButtonBorderColor(colorScheme),
                        width: 2,
                      ),
                      padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      ),
                    ),
                    child: Text(
                      'Log In',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: DynamicTheme.getOutlinedButtonTextColor(colorScheme),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: AppTheme.spacingXl),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
