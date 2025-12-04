import 'package:flutter/material.dart';
import 'package:openon_app/core/theme/color_scheme.dart';

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
        onSurface: scheme.id == 'deep_blue' ? Colors.white : const Color(0xFF4A4A4A),
        onBackground: scheme.id == 'deep_blue' ? Colors.white : const Color(0xFF4A4A4A),
      ),
      
      scaffoldBackgroundColor: scheme.secondary2,
      
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.id == 'deep_blue' ? Colors.white : const Color(0xFF4A4A4A),
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: scheme.id == 'deep_blue' ? Colors.white : const Color(0xFF4A4A4A),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary1,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary1, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF5350)),
        ),
        labelStyle: const TextStyle(
          color: Color(0xFF9E9E9E),
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF9E9E9E),
        ),
      ),
      
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: scheme.id == 'deep_blue' 
            ? Colors.white.withOpacity(0.1) // Semi-transparent white for deep blue
            : Colors.white,
      ),
      
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.id == 'deep_blue'
            ? scheme.secondary2.withOpacity(0.95) // Semi-transparent dark blue
            : Colors.white,
        selectedItemColor: scheme.id == 'deep_blue'
            ? Colors.white
            : scheme.primary1,
        unselectedItemColor: scheme.id == 'deep_blue'
            ? Colors.white.withOpacity(0.6)
            : const Color(0xFF9E9E9E),
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: scheme.id == 'deep_blue' ? Colors.white : scheme.primary1,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: scheme.id == 'deep_blue' 
              ? Colors.white.withOpacity(0.6)
              : const Color(0xFF9E9E9E),
        ),
        elevation: 8,
      ),
      
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: scheme.id == 'deep_blue' ? Colors.white : const Color(0xFF4A4A4A),
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: scheme.id == 'deep_blue' ? Colors.white : const Color(0xFF4A4A4A),
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: scheme.id == 'deep_blue' ? Colors.white : const Color(0xFF4A4A4A),
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: scheme.id == 'deep_blue' ? Colors.white : const Color(0xFF4A4A4A),
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: scheme.id == 'deep_blue' ? Colors.white : const Color(0xFF4A4A4A),
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: scheme.id == 'deep_blue' ? Colors.white : const Color(0xFF4A4A4A),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: scheme.id == 'deep_blue' ? Colors.white : const Color(0xFF4A4A4A),
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: scheme.id == 'deep_blue' ? Colors.white : const Color(0xFF4A4A4A),
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: scheme.id == 'deep_blue' ? Colors.white : const Color(0xFF4A4A4A),
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
}

