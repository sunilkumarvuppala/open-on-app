import 'package:flutter/material.dart';
import 'package:openon_app/core/theme/color_scheme.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/constants/app_constants.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';

/// Centralized text style system for consistent typography across the app
/// All text styles are theme-aware and use constants for consistency
class AppTextStyles {
  AppTextStyles._();

  // ============================================================================
  // PRIMARY TEXT STYLES - For main content, headings, titles
  // ============================================================================

  /// Large display text (32px) - For hero text, main headings
  static TextStyle displayLarge(AppColorScheme scheme) {
    return TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: DynamicTheme.getPrimaryTextColor(scheme),
      height: 1.2,
    );
  }

  /// Medium display text (28px) - For section headings
  static TextStyle displayMedium(AppColorScheme scheme) {
    return TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: DynamicTheme.getPrimaryTextColor(scheme),
      height: 1.2,
    );
  }

  /// Small display text (24px) - For page titles
  static TextStyle displaySmall(AppColorScheme scheme) {
    return TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: DynamicTheme.getPrimaryTextColor(scheme),
      height: 1.2,
    );
  }

  /// Headline text (20px) - For card titles, important labels
  static TextStyle headlineMedium(AppColorScheme scheme) {
    return TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: DynamicTheme.getPrimaryTextColor(scheme),
      height: 1.3,
    );
  }

  /// Title large (18px) - For subsection headings
  static TextStyle titleLarge(AppColorScheme scheme) {
    return TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: DynamicTheme.getPrimaryTextColor(scheme),
      height: 1.3,
    );
  }

  /// Title medium (16px) - For item titles, labels
  static TextStyle titleMedium(AppColorScheme scheme) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: DynamicTheme.getPrimaryTextColor(scheme),
      height: 1.4,
    );
  }

  /// Body large (16px) - For main body text
  static TextStyle bodyLarge(AppColorScheme scheme) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: DynamicTheme.getPrimaryTextColor(scheme),
      height: 1.6,
    );
  }

  /// Body medium (14px) - For secondary body text
  static TextStyle bodyMedium(AppColorScheme scheme) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: DynamicTheme.getPrimaryTextColor(scheme),
      height: 1.5,
    );
  }

  /// Body small (12px) - For captions, metadata
  static TextStyle bodySmall(AppColorScheme scheme) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: DynamicTheme.getSecondaryTextColor(scheme),
      height: 1.4,
    );
  }

  // ============================================================================
  // SECONDARY TEXT STYLES - For less prominent content
  // ============================================================================

  /// Secondary text - For descriptions, helper text
  static TextStyle secondary(AppColorScheme scheme, {double? fontSize}) {
    return TextStyle(
      fontSize: fontSize ?? 14,
      fontWeight: FontWeight.w400,
      color: DynamicTheme.getSecondaryTextColor(scheme),
      height: 1.5,
    );
  }

  /// Label text - For form labels, small labels
  static TextStyle label(AppColorScheme scheme, {double? fontSize}) {
    return TextStyle(
      fontSize: fontSize ?? 12,
      fontWeight: FontWeight.w500,
      color: DynamicTheme.getLabelTextColor(scheme),
      height: 1.4,
    );
  }

  /// Disabled text - For disabled/placeholder content
  static TextStyle disabled(AppColorScheme scheme, {double? fontSize}) {
    return TextStyle(
      fontSize: fontSize ?? 14,
      fontWeight: FontWeight.w400,
      color: DynamicTheme.getDisabledTextColor(scheme),
      height: 1.5,
    );
  }

  // ============================================================================
  // DIALOG TEXT STYLES - For popups and dialogs
  // ============================================================================

  /// Dialog title - For dialog/popup titles
  static TextStyle dialogTitle(AppColorScheme scheme) {
    return TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: DynamicTheme.getDialogTitleColor(scheme),
      height: 1.3,
    );
  }

  /// Dialog content - For dialog/popup body text
  static TextStyle dialogContent(AppColorScheme scheme) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: DynamicTheme.getDialogContentColor(scheme),
      height: 1.5,
    );
  }

  /// Dialog button - For dialog/popup button text
  static TextStyle dialogButton(AppColorScheme scheme) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: DynamicTheme.getDialogButtonColor(scheme),
      height: 1.4,
    );
  }

  // ============================================================================
  // BUTTON TEXT STYLES
  // ============================================================================

  /// Button text - For primary action buttons
  static TextStyle buttonText(AppColorScheme scheme) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: DynamicTheme.getButtonTextColor(scheme),
      height: 1.2,
    );
  }

  /// Button text small - For smaller buttons
  static TextStyle buttonTextSmall(AppColorScheme scheme) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: DynamicTheme.getButtonTextColor(scheme),
      height: 1.2,
    );
  }

  // ============================================================================
  // INPUT TEXT STYLES
  // ============================================================================

  /// Input text - For text fields
  static TextStyle inputText(AppColorScheme scheme) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: DynamicTheme.getInputTextColor(scheme),
      height: 1.5,
    );
  }

  /// Input hint - For text field placeholders
  static TextStyle inputHint(AppColorScheme scheme) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: DynamicTheme.getInputHintColor(scheme),
      height: 1.5,
    );
  }

  /// Input label - For text field labels
  static TextStyle inputLabel(AppColorScheme scheme) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: DynamicTheme.getLabelTextColor(scheme),
      height: 1.4,
    );
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Apply custom color to any text style
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Apply custom font size to any text style
  static TextStyle withSize(TextStyle style, double fontSize) {
    return style.copyWith(fontSize: fontSize);
  }

  /// Apply custom font weight to any text style
  static TextStyle withWeight(TextStyle style, FontWeight fontWeight) {
    return style.copyWith(fontWeight: fontWeight);
  }
}

/// Centralized container/background styling system
class AppContainerStyles {
  AppContainerStyles._();

  /// Standard card container - For cards, containers
  static BoxDecoration card(AppColorScheme scheme) {
    return BoxDecoration(
      color: DynamicTheme.getCardBackgroundColor(scheme),
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(AppTheme.shadowOpacitySubtle),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Dialog container - For popups/dialogs
  static BoxDecoration dialog(AppColorScheme scheme) {
    return BoxDecoration(
      color: DynamicTheme.getDialogBackgroundColor(scheme),
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(AppTheme.shadowOpacityHigh),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Info container - For info boxes, alerts
  static BoxDecoration info(AppColorScheme scheme) {
    return BoxDecoration(
      color: DynamicTheme.getInfoBackgroundColor(scheme),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      border: Border.all(
        color: DynamicTheme.getInfoBorderColor(scheme),
        width: AppTheme.borderWidthStandard,
      ),
    );
  }

  /// Input container - For text fields
  static BoxDecoration input(AppColorScheme scheme, {bool isFocused = false}) {
    return BoxDecoration(
      color: DynamicTheme.getInputBackgroundColor(scheme),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      border: Border.all(
        color: DynamicTheme.getInputBorderColor(scheme, isFocused: isFocused),
        width: isFocused ? AppTheme.borderWidthThick : AppTheme.borderWidthStandard,
      ),
    );
  }

  /// Button container - For custom buttons
  static BoxDecoration button(AppColorScheme scheme, {bool isPressed = false}) {
    return BoxDecoration(
      color: DynamicTheme.getButtonBackgroundColor(scheme),
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      border: Border.all(
        color: DynamicTheme.getButtonBorderColor(scheme),
        width: AppTheme.borderWidthStandard,
      ),
      boxShadow: isPressed ? [] : DynamicTheme.getButtonGlowShadows(scheme),
    );
  }
}

/// Centralized dialog builder for consistent popups
class AppDialogBuilder {
  AppDialogBuilder._();

  /// Build a standard dialog with consistent styling
  static Widget buildDialog({
    required BuildContext context,
    required AppColorScheme colorScheme,
    required Widget content,
    String? title,
    List<Widget>? actions,
    bool barrierDismissible = true,
    Color? barrierColor,
  }) {
    return AlertDialog(
      backgroundColor: DynamicTheme.getDialogBackgroundColor(colorScheme),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      contentPadding: EdgeInsets.all(AppTheme.spacingLg),
      title: title != null
          ? Text(
              title,
              style: AppTextStyles.dialogTitle(colorScheme),
            )
          : null,
      content: content,
      actions: actions,
    );
  }

  /// Build a confirmation dialog
  static Future<bool?> showConfirmationDialog({
    required BuildContext context,
    required AppColorScheme colorScheme,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    Color? barrierColor,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: barrierColor ?? Colors.black.withOpacity(0.5),
      barrierDismissible: true,
      builder: (context) => buildDialog(
        context: context,
        colorScheme: colorScheme,
        title: title,
        content: Text(
          message,
          style: AppTextStyles.dialogContent(colorScheme),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelText,
              style: AppTextStyles.dialogButton(colorScheme),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: confirmColor ?? DynamicTheme.getDialogButtonColor(colorScheme),
            ),
            child: Text(
              confirmText,
              style: AppTextStyles.dialogButton(colorScheme).copyWith(
                color: confirmColor ?? DynamicTheme.getDialogButtonColor(colorScheme),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build an info dialog
  static Future<void> showInfoDialog({
    required BuildContext context,
    required AppColorScheme colorScheme,
    required String title,
    required String message,
    String buttonText = 'OK',
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      barrierDismissible: true,
      builder: (context) => buildDialog(
        context: context,
        colorScheme: colorScheme,
        title: title,
        content: Text(
          message,
          style: AppTextStyles.dialogContent(colorScheme),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              buttonText,
              style: AppTextStyles.dialogButton(colorScheme),
            ),
          ),
        ],
      ),
    );
  }
}
