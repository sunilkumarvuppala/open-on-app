import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openon_app/core/router/app_router.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/color_scheme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/providers/providers.dart';

/// Main navigation shell with bottom navigation bar
class MainNavigation extends ConsumerStatefulWidget {
  final Widget child;
  final String location;

  const MainNavigation({
    super.key,
    required this.child,
    required this.location,
  });

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int get _currentIndex {
    if (widget.location == Routes.home) {
      return 0;
    } else if (widget.location == Routes.receiverHome) {
      return 1;
    }
    return 0;
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    // Trigger rising animation when switching tabs
    _animationController.forward(from: 0.0).then((_) {
      _animationController.reverse();
    });

    if (index == 0) {
      context.go(Routes.home);
    } else if (index == 1) {
      context.go(Routes.receiverHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 60,
            padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context: context,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_outlined, // Changed to outline version
                  label: 'Home',
                  index: 0,
                  colorScheme: colorScheme,
                  animationController: _animationController,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.inbox_outlined,
                  activeIcon: Icons.inbox_outlined,
                  label: 'Inbox',
                  index: 1,
                  colorScheme: colorScheme,
                  animationController: _animationController,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required AppColorScheme colorScheme,
    required AnimationController animationController,
  }) {
    final isSelected = index == _currentIndex;
    
    // Rising animation - moves up when this tab is selected
    final risingAnimation = Tween<double>(
      begin: 0.0,
      end: -4.0, // Move up by 4px
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    ));

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: 6,
            horizontal: AppTheme.spacingMd,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: animationController,
                builder: (context, child) {
                  // Only animate if this tab is selected
                  final translateY = isSelected ? risingAnimation.value : 0.0;
                  
                  return Transform.translate(
                    offset: Offset(0, translateY),
                    child: isSelected
                        ? ShaderMask(
                            shaderCallback: (bounds) {
                              final gradient = DynamicTheme.dreamyGradient(colorScheme);
                              return gradient.createShader(bounds);
                            },
                            child: Icon(
                              activeIcon,
                              color: Colors.white, // White is required for ShaderMask
                              size: 21, // Reduced from 24 to 21 (3px reduction)
                            ),
                          )
                        : Icon(
                            icon,
                            color: AppTheme.textGrey,
                            size: 21, // Reduced from 24 to 21 (3px reduction)
                          ),
                  );
                },
              ),
              SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? colorScheme.primary1
                          : AppTheme.textGrey,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

