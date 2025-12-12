import 'package:flutter/material.dart';

/// App color palette - natural, earthy, warm
class AppColors {
  // Primary colors
  static const forestGreen = Color(0xFF0E3B2E);
  static const deepMoss = Color(0xFF0C2F24);
  
  // Secondary colors
  static const warmBeige = Color(0xFFF2EAD3);
  static const sandstone = Color(0xFFDCC9A1);
  
  // Accent color
  static const amberGlow = Color(0xFFF2A65A);
  
  // Legacy color names for backward compatibility
  static const deepPurple = forestGreen;
  static const midnightBlue = deepMoss;
  static const softPink = warmBeige;
  static const peach = sandstone;
  static const softGold = amberGlow;
  
  // Neutrals
  static const white = Color(0xFFFFFFFF);
  static const offWhite = Color(0xFFFAF9F6);
  static const lightGray = Color(0xFFE8E8E8);
  static const gray = Color(0xFF9E9E9E);
  static const darkGray = Color(0xFF4A4A4A);
  
  // Status colors
  static const success = Color(0xFF4CAF50);
  static const error = Color(0xFFEF5350);
  static const warning = Color(0xFFFFA726);
  
  // Additional colors
  static const pastelPink = warmBeige;
  static const successGreen = Color(0xFF4CAF50);
  static const errorRed = Color(0xFFEF5350);
  static const textGrey = Color(0xFF9E9E9E);
  static const textDark = Color(0xFF4A4A4A);
  
  // Gradient colors
  static const gradientStart = forestGreen;
  static const gradientMiddle = Color(0xFF1A5A47); // Intermediate green
  static const gradientEnd = deepMoss;
}

/// App theme configuration
class AppTheme {
  // Spacing constants
  static const spacingXs = 4.0;
  static const spacingSm = 8.0;
  static const spacingMd = 16.0;
  static const spacingLg = 24.0;
  static const spacingXl = 32.0;
  
  // Radius constants
  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;
  static const radiusXl = 20.0;
  
  // Opacity constants for consistent theming
  static const opacityLow = 0.1;
  static const opacityMedium = 0.15;
  static const opacityMediumHigh = 0.2;
  static const opacityHigh = 0.3;
  static const opacityVeryHigh = 0.6;
  static const opacityAlmostFull = 0.7;
  static const opacityAlmostFull2 = 0.8;
  static const opacityFull = 0.9;
  static const opacitySemiTransparent = 0.95;
  
  // Chip spacing constants
  static const chipSpacing = 6.0;
  
  // Border width constants
  static const borderWidthThin = 0.5;
  static const borderWidthStandard = 1.0;
  static const borderWidthThick = 2.0;
  
  // Shadow/glow constants
  static const shadowOpacityVerySubtle = 0.005;
  static const shadowOpacitySubtle = 0.08;
  static const shadowOpacityMedium = 0.1;
  static const shadowOpacityHigh = 0.2;
  static const shadowOpacityVeryHigh = 0.3;
  
  // Glow blur/spread constants
  static const glowBlurRadiusSmall = 8.0;
  static const glowBlurRadiusMedium = 12.0;
  static const glowBlurRadiusLarge = 16.0;
  static const glowSpreadRadiusSmall = 0.5;
  static const glowSpreadRadiusMedium = 1.5;
  
  // Color shortcuts
  static const deepPurple = AppColors.forestGreen;
  static const softPink = AppColors.warmBeige;
  static const softGold = AppColors.amberGlow;
  static const pastelPink = AppColors.warmBeige;
  static const successGreen = AppColors.successGreen;
  static const errorRed = AppColors.errorRed;
  static const textGrey = AppColors.textGrey;
  static const textDark = AppColors.textDark;
  static const lavender = AppColors.amberGlow;
  
  // New color shortcuts
  static const forestGreen = AppColors.forestGreen;
  static const deepMoss = AppColors.deepMoss;
  static const warmBeige = AppColors.warmBeige;
  static const sandstone = AppColors.sandstone;
  static const amberGlow = AppColors.amberGlow;
  
  // Gradients
  static const warmGradient = LinearGradient(
    colors: [AppColors.warmBeige, AppColors.sandstone],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const softGradient = LinearGradient(
    colors: [AppColors.warmBeige, AppColors.amberGlow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const dreamyGradient = LinearGradient(
    colors: [AppColors.gradientStart, AppColors.gradientMiddle, AppColors.gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      // fontFamily: 'Poppins', // Commented out - Poppins fonts not included
      brightness: Brightness.light,
      
      colorScheme: ColorScheme.light(
        primary: AppColors.forestGreen,
        secondary: AppColors.warmBeige,
        surface: AppColors.white,
        background: AppColors.offWhite,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.forestGreen,
        onSurface: AppColors.darkGray,
        onBackground: AppColors.darkGray,
      ),
      
      scaffoldBackgroundColor: AppColors.offWhite,
      
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.darkGray,
        titleTextStyle: TextStyle(
          // fontFamily: 'Poppins', // Commented out - Poppins fonts not included
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.darkGray,
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forestGreen,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            // fontFamily: 'Poppins', // Commented out - Poppins fonts not included
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.forestGreen,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            // fontFamily: 'Poppins', // Commented out - Poppins fonts not included
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.forestGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(
          color: AppColors.gray,
          // fontFamily: 'Poppins', // Commented out - Poppins fonts not included
        ),
        hintStyle: const TextStyle(
          color: AppColors.gray,
          // fontFamily: 'Poppins', // Commented out - Poppins fonts not included
        ),
      ),
      
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: AppColors.white,
      ),
      
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.darkGray,
          // fontFamily: 'Poppins', // Commented out - Poppins fonts not included
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AppColors.darkGray,
          // fontFamily: 'Poppins', // Commented out - Poppins fonts not included
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.darkGray,
          // fontFamily: 'Poppins', // Commented out - Poppins fonts not included
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.darkGray,
          // fontFamily: 'Poppins', // Commented out - Poppins fonts not included
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.darkGray,
          // fontFamily: 'Poppins', // Commented out - Poppins fonts not included
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.darkGray,
          // fontFamily: 'Poppins', // Commented out - Poppins fonts not included
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.darkGray,
          height: 1.6,
          // fontFamily: 'Poppins', // Commented out - Poppins fonts not included
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.darkGray,
          height: 1.5,
          // fontFamily: 'Poppins', // Commented out - Poppins fonts not included
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.darkGray,
          // fontFamily: 'Poppins', // Commented out - Poppins fonts not included
        ),
      ),
    );
  }
}
