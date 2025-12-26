import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openon_app/core/constants/app_constants.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';

/// Inline name filter bar that expands/collapses on demand
/// 
/// Features:
/// - Hidden by default, expands when search icon is tapped
/// - Auto-focuses text field when expanded
/// - Shows clear button when text is entered
/// - Smooth expand/collapse animation
/// - Matches app theme styling
class InlineNameFilterBar extends ConsumerStatefulWidget {
  final bool expanded;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onToggleExpand;
  final String placeholder;

  const InlineNameFilterBar({
    super.key,
    required this.expanded,
    required this.query,
    required this.onChanged,
    required this.onClear,
    required this.onToggleExpand,
    this.placeholder = 'Filter by name…',
  });

  @override
  ConsumerState<InlineNameFilterBar> createState() => _InlineNameFilterBarState();
}

class _InlineNameFilterBarState extends ConsumerState<InlineNameFilterBar>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
    _focusNode = FocusNode();
    _animationController = AnimationController(
      vsync: this,
      duration: AppConstants.filterBarAnimationDuration,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    if (widget.expanded) {
      _animationController.value = 1.0;
      // Auto-focus when expanded on init
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(InlineNameFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update controller text if query changed externally
    if (widget.query != _controller.text) {
      _controller.text = widget.query;
    }
    
    // Handle expand/collapse animation
    if (widget.expanded != oldWidget.expanded) {
      if (widget.expanded) {
        _animationController.forward();
        // Auto-focus when expanding
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _focusNode.requestFocus();
          }
        });
      } else {
        _animationController.reverse();
        // Unfocus when collapsing
        _focusNode.unfocus();
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleTextChanged(String value) {
    // Security: Limit input length to prevent DoS
    if (value.length > AppConstants.maxFilterQueryLength) {
      // Truncate and update controller
      final truncated = value.substring(0, AppConstants.maxFilterQueryLength);
      _controller.value = TextEditingValue(
        text: truncated,
        selection: TextSelection.collapsed(offset: truncated.length),
      );
      value = truncated;
    }
    
    // Update controller immediately for UI responsiveness
    // Debounce the actual filter update and defer to avoid setState during layout
    _debounceTimer?.cancel();
    _debounceTimer = Timer(AppConstants.filterDebounceDuration, () {
      // Defer state update to next frame to avoid "Build scheduled during frame" error
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onChanged(value);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);

    return ClipRect(
      child: SizeTransition(
        sizeFactor: _expandAnimation,
        axisAlignment: -1.0,
        child: FadeTransition(
          opacity: _expandAnimation,
          child: SizedBox(
            height: AppConstants.filterBarHeight,
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: AppTheme.spacingLg,
                vertical: AppTheme.spacingXs,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingSm,
              ),
              decoration: BoxDecoration(
                color: DynamicTheme.getCardBackgroundColor(colorScheme),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: DynamicTheme.getButtonBorderColor(colorScheme).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    size: AppConstants.filterIconSize,
                    color: DynamicTheme.getSecondaryTextColor(colorScheme),
                  ),
                  SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: _handleTextChanged,
                      maxLength: AppConstants.maxFilterQueryLength,
                      buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null, // Hide counter
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(AppConstants.maxFilterQueryLength),
                      ],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: DynamicTheme.getPrimaryTextColor(colorScheme),
                          ),
                      decoration: InputDecoration(
                        hintText: widget.placeholder,
                        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: DynamicTheme.getSecondaryTextColor(colorScheme),
                            ),
                        filled: false,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_controller.text.isNotEmpty) ...[
                    SizedBox(width: AppTheme.spacingXs),
                    IconButton(
                      icon: const Icon(Icons.clear, size: AppConstants.filterClearIconSize),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        _controller.clear();
                        widget.onClear();
                        _focusNode.requestFocus();
                      },
                      color: DynamicTheme.getSecondaryTextColor(colorScheme),
                      tooltip: 'Clear filter',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

