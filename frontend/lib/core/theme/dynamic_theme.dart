import 'package:flutter/material.dart';
import 'package:openon_app/core/theme/color_scheme.dart';
import 'package:openon_app/core/theme/app_theme.dart';

/// Dynamic theme builder that uses the selected color scheme
class DynamicTheme {
  static ThemeData buildTheme(AppColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      // Disable all Material animations
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      
      colorScheme: ColorScheme.light(
        primary: scheme.primary1,
        secondary: scheme.secondary1,
        surface: Colors.white,
        background: scheme.secondary2,
        error: const Color(0xFFEF5350),
        onPrimary: Colors.white,
        onSecondary: scheme.primary1,
        onSurface: scheme.isDarkTheme ? Colors.white : const Color(0xFF4A4A4A),
        onBackground: scheme.isDarkTheme ? Colors.white : const Color(0xFF4A4A4A),
        // Input text color - ensures text in TextFields is visible
        onSurfaceVariant: scheme.isDarkTheme ? Colors.white : const Color(0xFF4A4A4A),
      ),
      
      scaffoldBackgroundColor: scheme.secondary2,
      
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.isDarkTheme ? Colors.white : const Color(0xFF4A4A4A),
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: scheme.isDarkTheme ? Colors.white : const Color(0xFF4A4A4A),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary1,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          side: getButtonBorderSide(scheme),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary1,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.isDarkTheme 
            ? Colors.white.withOpacity(0.15) 
            : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: scheme.isDarkTheme 
                ? Colors.white.withOpacity(0.3) 
                : const Color(0xFFE8E8E8),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: scheme.isDarkTheme 
                ? Colors.white.withOpacity(0.3) 
                : const Color(0xFFE8E8E8),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: scheme.isDarkTheme 
                ? Colors.white 
                : scheme.primary1, 
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF5350)),
        ),
        labelStyle: TextStyle(
          color: scheme.isDarkTheme 
              ? Colors.white.withOpacity(0.9) 
              : const Color(0xFF9E9E9E),
        ),
        hintStyle: TextStyle(
          color: scheme.isDarkTheme 
              ? Colors.white.withOpacity(0.6) 
              : const Color(0xFF9E9E9E),
        ),
        helperStyle: TextStyle(
          color: scheme.isDarkTheme 
              ? Colors.white.withOpacity(0.7) 
              : const Color(0xFF9E9E9E),
        ),
        errorStyle: const TextStyle(
          color: Color(0xFFEF5350),
        ),
      ),
      
      // Global text style for input fields - ensures text is visible
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.isDarkTheme ? Colors.white : scheme.primary1,
        selectionColor: scheme.primary1.withOpacity(0.3),
        selectionHandleColor: scheme.isDarkTheme ? Colors.white : scheme.primary1,
      ),
      
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: scheme.isDarkTheme 
            ? Colors.white.withOpacity(0.1) // Semi-transparent white for dark themes
            : Colors.white,
      ),
      
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.isDarkTheme
            ? scheme.secondary2.withOpacity(0.95) // Semi-transparent for dark themes
            : Colors.white,
        selectedItemColor: scheme.isDarkTheme
            ? Colors.white
            : scheme.primary1,
        unselectedItemColor: scheme.isDarkTheme
            ? Colors.white.withOpacity(0.6)
            : const Color(0xFF9E9E9E),
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: scheme.isDarkTheme ? Colors.white : scheme.primary1,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: scheme.isDarkTheme 
              ? Colors.white.withOpacity(0.6)
              : const Color(0xFF9E9E9E),
        ),
        elevation: 8,
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: _getChipBackgroundColor(scheme, false),
        selectedColor: _getChipBackgroundColor(scheme, true),
        labelStyle: TextStyle(
          color: _getChipLabelColor(scheme, false),
          fontSize: 14,
        ),
        side: BorderSide(
          color: _getChipBorderColor(scheme, false),
          width: 2.5,
        ),
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: scheme.isDarkTheme ? Colors.white : const Color(0xFF4A4A4A),
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: scheme.isDarkTheme ? Colors.white : const Color(0xFF4A4A4A),
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: scheme.isDarkTheme ? Colors.white : const Color(0xFF4A4A4A),
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: scheme.isDarkTheme ? Colors.white : const Color(0xFF4A4A4A),
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: scheme.isDarkTheme ? Colors.white : const Color(0xFF4A4A4A),
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: scheme.isDarkTheme ? Colors.white : const Color(0xFF4A4A4A),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: scheme.isDarkTheme ? Colors.white : const Color(0xFF4A4A4A),
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: scheme.isDarkTheme ? Colors.white : const Color(0xFF4A4A4A),
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: scheme.isDarkTheme ? Colors.white : const Color(0xFF4A4A4A),
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: scheme.isDarkTheme ? Colors.white.withOpacity(0.9) : const Color(0xFF4A4A4A),
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: scheme.isDarkTheme ? Colors.white.withOpacity(0.8) : const Color(0xFF6A6A6A),
        ),
      ),
    );
  }

  // Helper methods to get gradients from scheme
  static LinearGradient warmGradient(AppColorScheme scheme) {
    return LinearGradient(
      colors: [scheme.secondary1, scheme.secondary2],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient softGradient(AppColorScheme scheme) {
    return LinearGradient(
      colors: [scheme.secondary1, scheme.accent],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient dreamyGradient(AppColorScheme scheme) {
    return LinearGradient(
      colors: [scheme.primary1, scheme.primary2],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Background gradient for screens - uses secondary colors for dark gradient backgrounds
  static LinearGradient backgroundGradient(AppColorScheme scheme) {
    return LinearGradient(
      colors: [scheme.secondary1, scheme.secondary2],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // Chip color helpers - theme-aware colors for ActionChips
  static Color _getChipBackgroundColor(AppColorScheme scheme, bool isSelected) {
    if (scheme.isDarkTheme) {
      return isSelected 
          ? Colors.white.withOpacity(0.8) 
          : Colors.white.withOpacity(0.7);
    }
    return isSelected 
        ? scheme.primary1 
        : scheme.primary1.withOpacity(0.15);
  }

  static Color _getChipLabelColor(AppColorScheme scheme, bool isSelected) {
    if (scheme.isDarkTheme) {
      return scheme.primary1; // Dark color for contrast on white background
    }
    return isSelected 
        ? Colors.white 
        : scheme.primary1;
  }

  static Color _getChipBorderColor(AppColorScheme scheme, bool isSelected) {
    if (scheme.isDarkTheme) {
      return Colors.white;
    }
    return isSelected 
        ? scheme.primary1 
        : scheme.primary1.withOpacity(0.4);
  }

  /// Get chip background color for a given scheme and selection state
  static Color getChipBackgroundColor(AppColorScheme scheme, bool isSelected) {
    return _getChipBackgroundColor(scheme, isSelected);
  }

  /// Get chip label color for a given scheme and selection state
  static Color getChipLabelColor(AppColorScheme scheme, bool isSelected) {
    return _getChipLabelColor(scheme, isSelected);
  }

  /// Get chip border color for a given scheme and selection state
  static Color getChipBorderColor(AppColorScheme scheme, bool isSelected) {
    return _getChipBorderColor(scheme, isSelected);
  }

  /// Get chip border width for a given selection state
  static double getChipBorderWidth(bool isSelected) {
    return isSelected ? 3.0 : 2.5;
  }

  /// Get chip elevation for a given selection state
  static double getChipElevation(bool isSelected) {
    return isSelected ? 4 : 2;
  }

  // ============================================================================
  // REUSABLE COLOR HELPERS - Theme-aware color methods for consistent theming
  // ============================================================================

  /// Get primary text color (for headings, titles)
  static Color getPrimaryTextColor(AppColorScheme scheme) {
    return scheme.isDarkTheme ? Colors.white : const Color(0xFF4A4A4A);
  }

  /// Get secondary text color (for body text, descriptions)
  static Color getSecondaryTextColor(AppColorScheme scheme, {double opacity = AppTheme.opacityFull}) {
    return scheme.isDarkTheme 
        ? Colors.white.withOpacity(opacity) 
        : const Color(0xFF9E9E9E);
  }

  /// Get disabled/placeholder text color
  static Color getDisabledTextColor(AppColorScheme scheme) {
    return scheme.isDarkTheme 
        ? Colors.white.withOpacity(AppTheme.opacityAlmostFull) 
        : const Color(0xFF9E9E9E);
  }

  /// Get label text color (for form labels, small text)
  static Color getLabelTextColor(AppColorScheme scheme) {
    return scheme.isDarkTheme 
        ? Colors.white.withOpacity(AppTheme.opacityAlmostFull2) 
        : const Color(0xFF9E9E9E);
  }

  /// Get primary icon color
  static Color getPrimaryIconColor(AppColorScheme scheme) {
    return scheme.isDarkTheme 
        ? Colors.white.withOpacity(AppTheme.opacityFull) 
        : scheme.primary1;
  }

  /// Get secondary icon color (for chevrons, less important icons)
  static Color getSecondaryIconColor(AppColorScheme scheme) {
    return scheme.isDarkTheme 
        ? Colors.white.withOpacity(AppTheme.opacityAlmostFull) 
        : const Color(0xFF9E9E9E);
  }

  /// Get card/container background color
  static Color getCardBackgroundColor(AppColorScheme scheme, {double opacity = AppTheme.opacityLow}) {
    return scheme.isDarkTheme 
        ? Colors.white.withOpacity(opacity) 
        : Colors.white;
  }

  /// Get info/alert container background color
  static Color getInfoBackgroundColor(AppColorScheme scheme) {
    return scheme.isDarkTheme 
        ? Colors.white.withOpacity(AppTheme.opacityMedium) 
        : scheme.primary1.withOpacity(AppTheme.opacityLow);
  }

  /// Get divider color
  static Color getDividerColor(AppColorScheme scheme) {
    return scheme.isDarkTheme 
        ? Colors.white.withOpacity(AppTheme.opacityMediumHigh) 
        : const Color(0xFFE8E8E8);
  }

  /// Get border color for cards/containers
  static Color getBorderColor(AppColorScheme scheme, {double opacity = AppTheme.opacityHigh}) {
    return scheme.isDarkTheme 
        ? Colors.white.withOpacity(opacity) 
        : scheme.primary1.withOpacity(AppTheme.opacityMediumHigh);
  }

  /// Get info/alert border color
  static Color getInfoBorderColor(AppColorScheme scheme) {
    return scheme.isDarkTheme 
        ? Colors.white.withOpacity(AppTheme.opacityHigh) 
        : scheme.primary1.withOpacity(AppTheme.opacityMediumHigh);
  }

  /// Get info/alert text color
  static Color getInfoTextColor(AppColorScheme scheme) {
    return scheme.isDarkTheme 
        ? Colors.white.withOpacity(AppTheme.opacityFull) 
        : scheme.primary1;
  }

  /// Get navigation bar background color
  static Color getNavBarBackgroundColor(AppColorScheme scheme) {
    return scheme.isDarkTheme 
        ? scheme.secondary2.withOpacity(AppTheme.opacitySemiTransparent) 
        : Colors.white;
  }

  /// Get navigation bar shadow color
  static Color getNavBarShadowColor(AppColorScheme scheme) {
    return scheme.isDarkTheme 
        ? Colors.black.withOpacity(AppTheme.opacityHigh) 
        : Colors.black.withOpacity(0.05);
  }

  /// Get outlined button border color
  static Color getOutlinedButtonBorderColor(AppColorScheme scheme) {
    return scheme.isDarkTheme 
        ? Colors.white.withOpacity(AppTheme.opacityHigh) 
        : const Color(0xFFE8E8E8);
  }

  /// Get outlined button text color
  static Color? getOutlinedButtonTextColor(AppColorScheme scheme) {
    return scheme.isDarkTheme ? Colors.white : null;
  }

  // ============================================================================
  // NAVIGATION BAR COLOR HELPERS
  // ============================================================================

  /// Get navigation bar selected icon color (high contrast for visibility)
  static Color getNavBarSelectedIconColor(AppColorScheme scheme) {
    if (scheme.isDarkTheme) {
      return Colors.white; // Full white for maximum visibility on dark backgrounds
    }
    // For light themes, use primary color for good contrast
    return scheme.primary1;
  }

  /// Get navigation bar unselected icon color (visible but muted)
  static Color getNavBarUnselectedIconColor(AppColorScheme scheme) {
    return scheme.isDarkTheme 
        ? Colors.white.withOpacity(0.7) // Visible but muted on dark
        : const Color(0xFF9E9E9E); // Standard grey for light
  }

  /// Get navigation bar selected text color (high contrast)
  static Color getNavBarSelectedTextColor(AppColorScheme scheme) {
    return scheme.isDarkTheme 
        ? Colors.white // Full white for maximum visibility
        : scheme.primary1; // Primary color for light themes
  }

  /// Get navigation bar unselected text color (visible but muted)
  static Color getNavBarUnselectedTextColor(AppColorScheme scheme) {
    return scheme.isDarkTheme 
        ? Colors.white.withOpacity(0.7) // Visible but muted on dark
        : const Color(0xFF9E9E9E); // Standard grey for light
  }

  /// Get navigation bar glow effect color (for selected item)
  static Color getNavBarGlowColor(AppColorScheme scheme) {
    return scheme.isDarkTheme 
        ? Colors.white.withOpacity(AppTheme.opacityMediumHigh) // Subtle white glow on dark
        : scheme.primary1.withOpacity(AppTheme.opacityMedium); // Subtle primary glow on light
  }

  /// Get SnackBar background color
  static Color? getSnackBarBackgroundColor(AppColorScheme scheme) {
    return scheme.isDarkTheme ? scheme.secondary2 : null;
  }

  /// Get SnackBar text color
  static Color getSnackBarTextColor(AppColorScheme scheme) {
    return scheme.isDarkTheme ? Colors.white : const Color(0xFF4A4A4A);
  }

  /// Get button background color (for custom buttons)
  static Color getButtonBackgroundColor(AppColorScheme scheme, {double opacity = AppTheme.opacityLow}) {
    return scheme.isDarkTheme 
        ? Colors.white.withOpacity(AppTheme.opacityMedium) 
        : scheme.primary1.withOpacity(opacity);
  }

  /// Get button border color
  static Color getButtonBorderColor(AppColorScheme scheme, {double opacity = AppTheme.opacityHigh}) {
    return scheme.isDarkTheme 
        ? Colors.white.withOpacity(opacity) 
        : scheme.primary1.withOpacity(AppTheme.opacityLow);
  }

  /// Get button border side (for ElevatedButton and other buttons)
  static BorderSide getButtonBorderSide(AppColorScheme scheme, {double width = AppTheme.borderWidthStandard, double opacity = AppTheme.opacityHigh}) {
    return BorderSide(
      color: getButtonBorderColor(scheme, opacity: opacity),
      width: width,
    );
  }

  /// Get subtle button border side (for special cases like Create Letter button)
  static BorderSide getSubtleButtonBorderSide(AppColorScheme scheme) {
    return BorderSide(
      color: scheme.isDarkTheme 
          ? Colors.white.withOpacity(AppTheme.opacityMedium) 
          : scheme.primary1.withOpacity(AppTheme.opacityLow),
      width: AppTheme.borderWidthThin,
    );
  }

  /// Get button text/icon color
  static Color getButtonTextColor(AppColorScheme scheme) {
    return scheme.isDarkTheme 
        ? Colors.white.withOpacity(AppTheme.opacityFull) 
        : scheme.primary1;
  }

  /// Get input field background color
  static Color getInputBackgroundColor(AppColorScheme scheme) {
    return scheme.isDarkTheme 
        ? Colors.white.withOpacity(AppTheme.opacityMedium) 
        : Colors.white;
  }

  /// Get input field border color
  static Color getInputBorderColor(AppColorScheme scheme, {bool isFocused = false}) {
    if (isFocused) {
      return scheme.isDarkTheme 
          ? Colors.white.withOpacity(0.5) 
          : scheme.primary1;
    }
    return scheme.isDarkTheme 
        ? Colors.white.withOpacity(AppTheme.opacityHigh) 
        : const Color(0xFFE8E8E8);
  }

  /// Get input field text color
  static Color getInputTextColor(AppColorScheme scheme) {
    return scheme.isDarkTheme ? Colors.white : const Color(0xFF4A4A4A);
  }

  /// Get input field hint/placeholder color
  static Color getInputHintColor(AppColorScheme scheme) {
    return scheme.isDarkTheme 
        ? Colors.white.withOpacity(AppTheme.opacityAlmostFull) 
        : const Color(0xFF9E9E9E);
  }

  /// Get button glow color (for pressed/tapped states)
  static Color getButtonGlowColor(AppColorScheme scheme, {double opacity = 1.0}) {
    return scheme.isDarkTheme 
        ? DynamicTheme.getButtonTextColor(scheme).withOpacity(opacity * 0.5)
        : scheme.primary1.withOpacity(opacity);
  }

  /// Get button glow shadow (for elevated buttons)
  static List<BoxShadow> getButtonGlowShadows(AppColorScheme scheme) {
    return [
      // Outer glow with accent color
      BoxShadow(
        color: scheme.accent.withOpacity(AppTheme.opacityHigh),
        blurRadius: AppTheme.glowBlurRadiusLarge,
        spreadRadius: AppTheme.glowSpreadRadiusMedium,
      ),
      // Inner glow
      BoxShadow(
        color: scheme.primary1.withOpacity(AppTheme.opacityMediumHigh),
        blurRadius: AppTheme.glowBlurRadiusMedium,
        spreadRadius: AppTheme.glowSpreadRadiusSmall,
      ),
      // Subtle shadow for depth
      BoxShadow(
        color: Colors.black.withOpacity(AppTheme.shadowOpacitySubtle),
        blurRadius: AppTheme.glowBlurRadiusSmall,
        offset: const Offset(0, 4),
      ),
    ];
  }

  /// Get tab container border
  static Border? getTabContainerBorder(AppColorScheme scheme) {
    return Border.all(
      color: scheme.isDarkTheme
          ? Colors.white.withOpacity(AppTheme.opacityMediumHigh)
          : Colors.black.withOpacity(AppTheme.opacityLow),
      width: AppTheme.borderWidthStandard,
    );
  }

  /// Get dialog background color
  static Color getDialogBackgroundColor(AppColorScheme scheme) {
    return scheme.isDarkTheme ? scheme.secondary2 : Colors.white;
  }

  /// Get dialog title text color
  static Color getDialogTitleColor(AppColorScheme scheme) {
    return scheme.isDarkTheme ? Colors.white : scheme.primary1;
  }

  /// Get dialog content text color
  static Color getDialogContentColor(AppColorScheme scheme) {
    return scheme.isDarkTheme 
        ? Colors.white.withOpacity(AppTheme.opacityFull) 
        : const Color(0xFF4A4A4A);
  }

  /// Get dialog button text color (for cancel/secondary actions)
  static Color getDialogButtonColor(AppColorScheme scheme) {
    return scheme.isDarkTheme 
        ? Colors.white.withOpacity(AppTheme.opacityFull) 
        : const Color(0xFF9E9E9E);
  }
}

