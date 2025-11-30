import 'package:flutter/material.dart';

/// Premium animation theme with Royal Moonlight palette
class AnimationTheme {
  // Royal Moonlight Palette
  static const Color navyDeep = Color(0xFF0A1128);
  static const Color navyMedium = Color(0xFF1B2845);
  static const Color purpleRoyal = Color(0xFF5E3A9F);
  static const Color purpleSoft = Color(0xFF8B6BBE);
  static const Color goldPremium = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFFFD700);
  static const Color goldShimmer = Color(0xFFFFF9E6);
  
  // White variations
  static const Color whitePure = Color(0xFFFFFFFF);
  static const Color whiteGlow = Color(0xFFFFFBF0);
  
  // Animation Durations - Disney-inspired timing
  static const Duration microAnimation = Duration(milliseconds: 100);
  static const Duration quickAnimation = Duration(milliseconds: 250);
  static const Duration standardAnimation = Duration(milliseconds: 350);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  static const Duration cinematicAnimation = Duration(milliseconds: 800);
  static const Duration epicAnimation = Duration(milliseconds: 1200);
  
  // Animation Curves - Premium feel
  static const Curve premiumCurve = Curves.easeInOutCubic;
  static const Curve elasticCurve = Curves.elasticOut;
  static const Curve bounceCurve = Curves.bounceOut;
  static const Curve smoothCurve = Curves.easeOutQuart;
  
  // Sparkle configurations
  static const int sparkleCount = 25;
  static const double sparkleMinSize = 2.0;
  static const double sparkleMaxSize = 6.0;
  static const double sparkleDriftSpeed = 30.0;
  
  // Glow configurations
  static const double glowRadius = 20.0;
  static const double glowSpread = 8.0;
  
  // Gradient definitions
  static LinearGradient goldGradient = const LinearGradient(
    colors: [goldLight, goldPremium, Color(0xFFB8860B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient royalGradient = const LinearGradient(
    colors: [purpleRoyal, purpleSoft, navyMedium],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static RadialGradient glowGradient = RadialGradient(
    colors: [
      goldShimmer.withOpacity(0.6),
      goldLight.withOpacity(0.3),
      goldPremium.withOpacity(0.0),
    ],
    stops: const [0.0, 0.5, 1.0],
  );
  
  // Dark mode adjustments
  static Color getAdaptiveGold(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? goldLight : goldPremium;
  }
  
  static Color getAdaptiveBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? navyDeep : whiteGlow;
  }
  
  static LinearGradient getAdaptiveGoldGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      colors: isDark
          ? [goldShimmer, goldLight, goldPremium]
          : [goldPremium, Color(0xFFB8860B), Color(0xFF9A7711)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

