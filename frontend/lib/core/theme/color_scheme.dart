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

  // EXISTING TOP THEMES (kept same)
  static const royalAmethyst = AppColorScheme(
    id: 'royal_amethyst',
    name: 'Royal Amethyst',
    primary1: Color(0xFF6B46C1),
    primary2: Color(0xFF553C9A),
    secondary1: Color(0xFFE9D5FF),
    secondary2: Color(0xFFF3E8FF),
    accent: Color(0xFFFBBF24),
  );

  static const dreamLilac = AppColorScheme(
    id: 'dream_lilac',
    name: 'Dream Lilac',
    primary1: Color(0xFFCDB4DB),
    primary2: Color(0xFFB89BC9),
    secondary1: Color(0xFFFFC8DD),
    secondary2: Color(0xFFFFD9E8),
    accent: Color(0xFFB9FBC0),
  );

  static const velvetNights = AppColorScheme(
    id: 'velvet_nights',
    name: 'Velvet Nights',
    primary1: Color(0xFF1A1A2E),
    primary2: Color(0xFF0F0F1E),
    secondary1: Color(0xFFE8E3F0),
    secondary2: Color(0xFFF5F2F8),
    accent: Color(0xFFC9A9DD),
  );

  static const amethystTwilight = AppColorScheme(
    id: 'amethyst_twilight',
    name: 'Amethyst Twilight',
    primary1: Color(0xFF581C87),
    primary2: Color(0xFF6B21A8),
    secondary1: Color(0xFFF3E8FF),
    secondary2: Color(0xFFFAF5FF),
    accent: Color(0xFFA855F7),
  );

  static const emeraldElegance = AppColorScheme(
    id: 'emerald_elegance',
    name: 'Emerald Elegance',
    primary1: Color(0xFF0D4A3C),
    primary2: Color(0xFF0A3A2F),
    secondary1: Color(0xFFE8F4F1),
    secondary2: Color(0xFFF0F8F6),
    accent: Color(0xFF2ECC71),
  );

  static const midnightBlue = AppColorScheme(
    id: 'midnight_blue',
    name: 'Midnight Blue',
    primary1: Color(0xFF111827),
    primary2: Color(0xFF1F2937),
    secondary1: Color(0xFFE5E7EB),
    secondary2: Color(0xFFF3F4F6),
    accent: Color(0xFFFBBF24),
  );

  static const royalSapphire = AppColorScheme(
    id: 'royal_sapphire',
    name: 'Royal Sapphire',
    primary1: Color(0xFF1E3A8A),
    primary2: Color(0xFF1E40AF),
    secondary1: Color(0xFFE0E7FF),
    secondary2: Color(0xFFEEF2FF),
    accent: Color(0xFFF59E0B),
  );

  static const oceanDepth = AppColorScheme(
    id: 'ocean_depth',
    name: 'Ocean Depth',
    primary1: Color(0xFF0F4C75),
    primary2: Color(0xFF0A3A5C),
    secondary1: Color(0xFFB8E6E6),
    secondary2: Color(0xFFD4F1F1),
    accent: Color(0xFFFFD93D),
  );

  static const glacialNavy = AppColorScheme(
    id: 'glacial_navy',
    name: 'Glacial Navy',
    primary1: Color(0xFF1B2A41),
    primary2: Color(0xFF141D2E),
    secondary1: Color(0xFFD0E8F2),
    secondary2: Color(0xFFE5F2F8),
    accent: Color(0xFFD9C5A7),
  );

  static const softBlush = AppColorScheme(
    id: 'soft_blush',
    name: 'Soft Blush',
    primary1: Color(0xFFFADADD),
    primary2: Color(0xFFF5C5CA),
    secondary1: Color(0xFFE8D9C5),
    secondary2: Color(0xFFF2E5D3),
    accent: Color(0xFFD3B683),
  );

  // ⭐ GALAXY THEME
  static const galaxyAurora = AppColorScheme(
    id: 'galaxy_aurora',
    name: 'Galaxy Aurora',
    primary1: Color(0xFF1C164E),
    primary2: Color(0xFF2A1D6F),
    secondary1: Color(0xFF8EC5FF),
    secondary2: Color(0xFFC0FFD8),
    accent: Color(0xFFF8D57E),
  );

  // ⭐ NEW SHADE FAMILIES --------------------------------------------------

  // 🔵 SHADES OF BLUE (Modern, premium)
  static const blueHorizon = AppColorScheme(
    id: 'blue_horizon',
    name: 'Blue Horizon',
    primary1: Color(0xFF0A1A3F),
    primary2: Color(0xFF102A59),
    secondary1: Color(0xFFE0ECFF),
    secondary2: Color(0xFFF2F6FF),
    accent: Color(0xFF5EA3FF),
  );


  // 🔴 SHADES OF RED / MAROON (Emotional, warm, premium)
  static const crimsonVelvet = AppColorScheme(
    id: 'crimson_velvet',
    name: 'Crimson Velvet',
    primary1: Color(0xFF5A0E0E),
    primary2: Color(0xFF7A1B1B),
    secondary1: Color(0xFFF8EAEA),
    secondary2: Color(0xFFFFF5F5),
    accent: Color(0xFFE57373),
  );

  // ⚪ SHADES OF GREY (Luxury, neutral, minimal)
  static const silverMist = AppColorScheme(
    id: 'silver_mist',
    name: 'Silver Mist',
    primary1: Color(0xFF2E2E2E),
    primary2: Color(0xFF1F1F1F),
    secondary1: Color(0xFFF3F3F3),
    secondary2: Color(0xFFFAFAFA),
    accent: Color(0xFF9CA3AF),
  );

  // 🔵 DEEP BLUE THEME (Deep blue-purple gradient, modern chat aesthetic)
  // Dark blue dominant gradient transitioning to blue-purple with dark purple chat bubbles
  static const deepBlue = AppColorScheme(
    id: 'deep_blue',
    name: 'Deep Blue',
    primary1: Color(0xFF1D094B),      // Dark purple for AI chat bubbles
    primary2: Color.fromARGB(255, 52, 6, 202),      // Darker purple for gradient end
    secondary1: Color(0xFF062982),      // Very dark blue for gradient start (blue dominant)
    secondary2: Color(0xFF192853),     // Dark blue-purple for gradient end (more blue than purple)
    accent: Color.fromARGB(255, 48, 36, 82),         // Vibrant purple glow/accent color
  );

  // -----------------------------------------------------------------------

  static const List<AppColorScheme> allSchemes = [
    deepBlue,        // Default theme - placed first
    royalAmethyst,
    dreamLilac,
    velvetNights,
    amethystTwilight,
    emeraldElegance,
    midnightBlue,
    royalSapphire,
    oceanDepth,
    glacialNavy,
    softBlush,
    galaxyAurora,

    // New Shade families
    blueHorizon,    

    crimsonVelvet,    

    silverMist
  ];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'primary1': primary1.value,
        'primary2': primary2.value,
        'secondary1': secondary1.value,
        'secondary2': secondary2.value,
        'accent': accent.value,
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
