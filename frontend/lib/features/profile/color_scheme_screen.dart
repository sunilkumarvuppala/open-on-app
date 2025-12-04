import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/color_scheme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';

class ColorSchemeScreen extends ConsumerWidget {
  const ColorSchemeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentScheme = ref.watch(selectedColorSchemeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Color Theme'),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: DynamicTheme.getPrimaryIconColor(currentScheme),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(AppTheme.spacingLg),
        children: [
          Text(
            'Select your preferred color theme',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: DynamicTheme.getPrimaryTextColor(currentScheme),
                ),
          ),
          SizedBox(height: AppTheme.spacingMd),
          Text(
            'Choose a color scheme that matches your style',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DynamicTheme.getSecondaryTextColor(currentScheme),
                ),
          ),
          SizedBox(height: AppTheme.spacingXl),
          
          ...AppColorScheme.allSchemes.map((scheme) {
            final isSelected = currentScheme.id == scheme.id;
            
            return Padding(
              padding: EdgeInsets.only(bottom: AppTheme.spacingMd),
              child: _ColorSchemeCard(
                scheme: scheme,
                isSelected: isSelected,
                currentScheme: currentScheme,
                onTap: () async {
                  await ref.read(selectedColorSchemeProvider.notifier).setScheme(scheme);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${scheme.name} theme applied',
                          style: TextStyle(
                            color: scheme.primary1.computeLuminance() < 0.5 
                                ? Colors.white 
                                : Colors.black,
                          ),
                        ),
                        duration: const Duration(seconds: 2),
                        backgroundColor: scheme.primary1,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                    );
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ColorSchemeCard extends StatelessWidget {
  final AppColorScheme scheme;
  final bool isSelected;
  final AppColorScheme currentScheme;
  final VoidCallback onTap;

  const _ColorSchemeCard({
    required this.scheme,
    required this.isSelected,
    required this.currentScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine border color for selected state - use accent color or white for visibility
    final selectedBorderColor = scheme.accent.computeLuminance() > 0.3 
        ? scheme.accent 
        : Colors.white;
    
    return Card(
      elevation: isSelected ? 6 : 2,
      color: isSelected 
          ? scheme.primary1.withOpacity(AppTheme.opacityMedium) // Subtle background tint for selected
          : DynamicTheme.getCardBackgroundColor(currentScheme),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(
          color: isSelected 
              ? selectedBorderColor 
              : DynamicTheme.getBorderColor(currentScheme, opacity: AppTheme.opacityMediumHigh),
          width: isSelected ? AppTheme.borderWidthThick + 1 : AppTheme.borderWidthStandard,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary1.withOpacity(AppTheme.opacityLow),
                      scheme.accent.withOpacity(0.05),
                    ],
                  ),
                )
              : null,
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            scheme.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: DynamicTheme.getPrimaryTextColor(currentScheme),
                                ),
                          ),
                          if (isSelected) ...[
                            SizedBox(width: AppTheme.spacingSm),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingSm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.accent,
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              ),
                              child: Text(
                                'SELECTED',
                                style: TextStyle(
                                  color: scheme.accent.computeLuminance() > 0.5 
                                      ? Colors.black 
                                      : Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: scheme.accent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: scheme.accent.computeLuminance() > 0.5 
                              ? Colors.black 
                              : Colors.white,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              SizedBox(height: AppTheme.spacingMd),
              
              // Color preview
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Primary',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: DynamicTheme.getLabelTextColor(currentScheme),
                                fontSize: 12,
                              ),
                        ),
                        SizedBox(height: AppTheme.spacingXs),
                        Row(
                          children: [
                            _ColorSwatch(color: scheme.primary1),
                            SizedBox(width: AppTheme.spacingXs),
                            _ColorSwatch(color: scheme.primary2),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Secondary',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: DynamicTheme.getLabelTextColor(currentScheme),
                                fontSize: 12,
                              ),
                        ),
                        SizedBox(height: AppTheme.spacingXs),
                        Row(
                          children: [
                            _ColorSwatch(color: scheme.secondary1),
                            SizedBox(width: AppTheme.spacingXs),
                            _ColorSwatch(color: scheme.secondary2),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Accent',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: DynamicTheme.getLabelTextColor(currentScheme),
                                fontSize: 12,
                              ),
                        ),
                        SizedBox(height: AppTheme.spacingXs),
                        _ColorSwatch(color: scheme.accent),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;

  const _ColorSwatch({required this.color});

  @override
  Widget build(BuildContext context) {
    // Determine border color based on swatch color luminance
    // Use darker border for light swatches, lighter border for dark swatches
    final swatchLuminance = color.computeLuminance();
    final borderColor = swatchLuminance > 0.5
        ? Colors.black.withOpacity(AppTheme.opacityMedium) // Dark border for light colors
        : Colors.white.withOpacity(AppTheme.opacityHigh); // Light border for dark colors
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
    );
  }
}

