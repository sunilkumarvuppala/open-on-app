import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/color_scheme.dart';

class ColorSchemeScreen extends ConsumerWidget {
  const ColorSchemeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentScheme = ref.watch(selectedColorSchemeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Color Theme'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
                  color: AppColors.textDark,
                ),
          ),
          SizedBox(height: AppTheme.spacingMd),
          Text(
            'Choose a color scheme that matches your style',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textGrey,
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
                onTap: () async {
                  await ref.read(selectedColorSchemeProvider.notifier).setScheme(scheme);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${scheme.name} theme applied'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: scheme.primary1,
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
  final VoidCallback onTap;

  const _ColorSchemeCard({
    required this.scheme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(
          color: isSelected ? scheme.primary1 : Colors.transparent,
          width: isSelected ? 3 : 0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    scheme.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: scheme.primary1,
                      size: 24,
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
                                color: AppTheme.textGrey,
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
                                color: AppTheme.textGrey,
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
                                color: AppTheme.textGrey,
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
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;

  const _ColorSwatch({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: Colors.black.withOpacity(0.1),
          width: 1,
        ),
      ),
    );
  }
}

