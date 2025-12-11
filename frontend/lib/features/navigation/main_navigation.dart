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
    // Inbox (receiverHome) is index 0
    // Outbox (home) is index 1
    // People is index 2
    if (widget.location == Routes.receiverHome) {
      return 0;
    } else if (widget.location == Routes.home) {
      return 1;
    } else if (widget.location == Routes.people) {
      return 2;
    }
    return 0; // Default to inbox
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    // Trigger rising animation when switching tabs
    _animationController.forward(from: 0.0).then((_) {
      _animationController.reverse();
    });

    if (index == 0) {
      context.go(Routes.receiverHome); // Inbox
    } else if (index == 1) {
      context.go(Routes.home); // Outbox
    } else if (index == 2) {
      context.go(Routes.people); // People
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    
    // Use theme-aware colors for navigation bar
    final navBackgroundColor = DynamicTheme.getNavBarBackgroundColor(colorScheme);
    final shadowColor = DynamicTheme.getNavBarShadowColor(colorScheme);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: shadowColor,
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
                  icon: Icons.inbox_outlined,
                  activeIcon: Icons.inbox_outlined,
                  label: 'Inbox',
                  index: 0,
                  colorScheme: colorScheme,
                  animationController: _animationController,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.send_outlined,
                  activeIcon: Icons.send_outlined,
                  label: 'Outbox',
                  index: 1,
                  colorScheme: colorScheme,
                  animationController: _animationController,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.people_outlined,
                  activeIcon: Icons.people,
                  label: 'People',
                  index: 2,
                  colorScheme: colorScheme,
                  animationController: _animationController,
                  badgeCount: ref.watch(incomingRequestsCountProvider),
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
    int badgeCount = 0,
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

    // Use theme-aware colors for maximum visibility
    final selectedIconColor = DynamicTheme.getNavBarSelectedIconColor(colorScheme);
    final unselectedIconColor = DynamicTheme.getNavBarUnselectedIconColor(colorScheme);
    final selectedTextColor = DynamicTheme.getNavBarSelectedTextColor(colorScheme);
    final unselectedTextColor = DynamicTheme.getNavBarUnselectedTextColor(colorScheme);
    final glowColor = DynamicTheme.getNavBarGlowColor(colorScheme);

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
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                // Soft glow effect behind the icon (positioned, doesn't affect layout)
                                Positioned(
                                  left: -2,
                                  right: -2,
                                  top: -2,
                                  bottom: -2,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: glowColor,
                                      boxShadow: [
                                        BoxShadow(
                                          color: glowColor,
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Icon on top
                                Icon(
                                  activeIcon,
                                  color: selectedIconColor,
                                  size: 21,
                                ),
                              ],
                            ),
                          )
                        : Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                icon,
                                color: unselectedIconColor,
                                size: 21,
                              ),
                              // Badge for incoming requests
                              if (badgeCount > 0)
                                Positioned(
                                  right: -6,
                                  top: -6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      badgeCount > 9 ? '9+' : '$badgeCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  );
                },
              ),
              SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? selectedTextColor
                          : unselectedTextColor,
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

