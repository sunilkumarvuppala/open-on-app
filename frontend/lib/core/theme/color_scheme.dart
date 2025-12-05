// EXTENDED COLOR THEMES: + Shades of Blue, Maroon, Grey

import 'package:flutter/material.dart';

class AppColorScheme {
  final String id;
  final String name;
  final Color primary1;
  final Color primary2;
  final Color secondary1;
  final Color secondary2;
  final Color accent;

  const AppColorScheme({
    required this.id,
    required this.name,
    required this.primary1,
    required this.primary2,
    required this.secondary1,
    required this.secondary2,
    required this.accent,
  });

  /// Determines if this color scheme is a dark theme based on background brightness
  /// Uses the secondary2 color (background) to calculate luminance
  /// A theme is considered dark if the background luminance is less than 0.5
  bool get isDarkTheme {
    // Use Flutter's built-in luminance calculation
    final luminance = secondary2.computeLuminance();
    // If luminance is less than 0.5, it's considered a dark theme
    return luminance < 0.5;
  }

  // ⭐ DARK VIBRANT THEMES - Similar to Deep Blue and Galaxy Aurora
  
  // 🔵 DEEP BLUE THEME (Deep blue-purple gradient, modern chat aesthetic)
  static const deepBlue = AppColorScheme(
    id: 'deep_blue',
    name: 'Deep Blue',
    primary1: Color(0xFF1D094B),      // Dark purple for AI chat bubbles
    primary2: Color(0xFF3406CA),      // Darker purple for gradient end
    secondary1: Color(0xFF062982),      // Very dark blue for gradient start (blue dominant)
    secondary2: Color(0xFF192853),     // Dark blue-purple for gradient end (more blue than purple)
    accent: Color(0xFF302452),         // Vibrant purple glow/accent color
  );

  // ⭐ GALAXY AURORA THEME - Dark purple-blue with cyan/teal aurora colors
  static const galaxyAurora = AppColorScheme(
    id: 'galaxy_aurora',
    name: 'Galaxy Aurora',
    primary1: Color(0xFF1C164E),      // Deep purple-blue
    primary2: Color(0xFF2A1D6F),       // Darker purple
    secondary1: Color(0xFF0A1B3A),    // Very dark blue (gradient start)
    secondary2: Color(0xFF1A2D5A),     // Dark blue-purple (gradient end)
    accent: Color(0xFF8EC5FF),        // Bright cyan accent (aurora)
  );

  // ⭐ GALAXY AURORA CLASSIC - Light theme version with lighter secondary colors and golden accent
  static const galaxyAuroraClassic = AppColorScheme(
    id: 'galaxy_aurora_classic',
    name: 'Galaxy Aurora Classic',
    primary1: Color(0xFF1C164E),      // Deep purple-blue
    primary2: Color(0xFF2A1D6F),       // Darker purple
    secondary1: Color(0xFF8EC5FF),    // Light cyan-blue
    secondary2: Color(0xFFD4E8F5),     // Light blue-aqua - soft cyan-blue that complements the purple and cyan-blue
    accent: Color(0xFFF8D57E),        // Golden/peachy accent
  );

  // 🌌 COSMIC VOID - Deep black with vibrant purple/blue accents
  static const cosmicVoid = AppColorScheme(
    id: 'cosmic_void',
    name: 'Cosmic Void',
    primary1: Color(0xFF1A0D2E),      // Deep purple-black
    primary2: Color(0xFF2D1B3D),       // Dark purple
    secondary1: Color(0xFF0A0A1A),     // Almost black (gradient start)
    secondary2: Color(0xFF1A1A2E),     // Dark navy (gradient end)
    accent: Color(0xFF9D4EDD),         // Vibrant purple accent
  );

  // 🌠 NEBULA DREAMS - Dark purple with pink/cyan nebula colors
  static const nebulaDreams = AppColorScheme(
    id: 'nebula_dreams',
    name: 'Nebula Dreams',
    primary1: Color(0xFF2D1B4E),      // Rich purple
    primary2: Color(0xFF3D2B5E),       // Darker purple
    secondary1: Color(0xFF1A0D3A),     // Very dark purple (gradient start)
    secondary2: Color(0xFF2A1D4A),     // Dark purple-blue (gradient end)
    accent: Color(0xFFFF6B9D),         // Vibrant pink accent
  );

  // ⭐ STELLAR NIGHT - Dark blue with gold/cyan star colors
  static const stellarNight = AppColorScheme(
    id: 'stellar_night',
    name: 'Stellar Night',
    primary1: Color(0xFF0F1B3A),       // Deep navy
    primary2: Color(0xFF1A2B4A),       // Darker navy
    secondary1: Color(0xFF050A1A),     // Almost black blue (gradient start)
    secondary2: Color(0xFF0F1A2E),     // Dark blue (gradient end)
    accent: Color(0xFFFFD700),          // Gold accent (stars)
  );

  // 🌊 ABYSSAL DEPTHS - Very dark blue-green with teal accents
  static const abyssalDepths = AppColorScheme(
    id: 'abyssal_depths',
    name: 'Abyssal Depths',
    primary1: Color(0xFF0A1F2E),       // Deep teal-blue
    primary2: Color(0xFF0F2A3A),       // Darker teal
    secondary1: Color(0xFF050F1A),     // Very dark blue-green (gradient start)
    secondary2: Color(0xFF0A1A2A),    // Dark teal-blue (gradient end)
    accent: Color(0xFF00D4AA),          // Bright teal accent
  );

  // ⚡ MIDNIGHT STORM - Dark grey-blue with electric blue accents
  static const midnightStorm = AppColorScheme(
    id: 'midnight_storm',
    name: 'Midnight Storm',
    primary1: Color(0xFF1A2332),       // Dark grey-blue
    primary2: Color(0xFF2A3342),       // Darker grey-blue
    secondary1: Color(0xFF0F1419),     // Almost black (gradient start)
    secondary2: Color(0xFF1A1F2A),     // Dark grey-blue (gradient end)
    accent: Color(0xFF00BFFF),         // Electric blue accent
  );

  // 🌸 CELESTIAL PURPLE - Dark purple with magenta/cyan cosmic colors
  static const celestialPurple = AppColorScheme(
    id: 'celestial_purple',
    name: 'Celestial Purple',
    primary1: Color(0xFF2D1B4E),       // Deep purple
    primary2: Color(0xFF3D2B5E),       // Darker purple
    secondary1: Color(0xFF1A0D3A),     // Very dark purple (gradient start)
    secondary2: Color(0xFF2A1D4A),     // Dark purple-blue (gradient end)
    accent: Color(0xFFFF00FF),         // Magenta accent
  );

  // 🔮 MYSTIC SHADOWS - Dark indigo with violet/cyan mystical colors
  static const mysticShadows = AppColorScheme(
    id: 'mystic_shadows',
    name: 'Mystic Shadows',
    primary1: Color(0xFF1E1B3E),       // Deep indigo
    primary2: Color(0xFF2E2B4E),       // Darker indigo
    secondary1: Color(0xFF0F0A2A),     // Very dark indigo (gradient start)
    secondary2: Color(0xFF1A153A),     // Dark indigo-purple (gradient end)
    accent: Color(0xFF8A2BE2),         // Blue-violet accent
  );

  // -----------------------------------------------------------------------

  static const List<AppColorScheme> allSchemes = [
    deepBlue,        // Default theme - placed first
    galaxyAurora,
    galaxyAuroraClassic,  // Previous version with golden accent
    cosmicVoid,
    nebulaDreams,
    stellarNight,
    abyssalDepths,
    midnightStorm,
    celestialPurple,
    mysticShadows,
  ];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'primary1': primary1.toARGB32(),
        'primary2': primary2.toARGB32(),
        'secondary1': secondary1.toARGB32(),
        'secondary2': secondary2.toARGB32(),
        'accent': accent.toARGB32(),
      };

  factory AppColorScheme.fromJson(Map<String, dynamic> json) {
    return AppColorScheme(
      id: json['id'],
      name: json['name'],
      primary1: Color(json['primary1']),
      primary2: Color(json['primary2']),
      secondary1: Color(json['secondary1']),
      secondary2: Color(json['secondary2']),
      accent: Color(json['accent']),
    );
  }

  static AppColorScheme? fromId(String id) {
    try {
      return allSchemes.firstWhere((scheme) => scheme.id == id);
    } catch (_) {
      return null;
    }
  }
}
