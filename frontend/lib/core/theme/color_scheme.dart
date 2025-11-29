import 'package:flutter/material.dart';

/// Color scheme model for theme customization
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

  // Predefined color schemes
  static const forestGreen = AppColorScheme(
    id: 'forest_green',
    name: 'Forest Green',
    primary1: Color(0xFF0E3B2E),
    primary2: Color(0xFF0C2F24),
    secondary1: Color(0xFFF2EAD3),
    secondary2: Color(0xFFDCC9A1),
    accent: Color(0xFFF2A65A),
  );

  static const deepNavy = AppColorScheme(
    id: 'deep_navy',
    name: 'Deep Navy',
    primary1: Color(0xFF0A0F1F),
    primary2: Color(0xFF1F2A44),
    secondary1: Color(0xFFE8D4A2),
    secondary2: Color(0xFFF8F1E7),
    accent: Color(0xFFFFBE76),
  );

  static const midnightBlue = AppColorScheme(
    id: 'midnight_blue',
    name: 'Midnight Blue',
    primary1: Color(0xFF111827),
    primary2: Color(0xFF1F2937),
    secondary1: Color(0xFFE5E7EB),
    secondary2: Color(0xFFF3F4F6),
    accent: Color(0xFF3B82F6),
  );

  static const richMaroon = AppColorScheme(
    id: 'rich_maroon',
    name: 'Rich Maroon',
    primary1: Color(0xFF6A1B1A),
    primary2: Color(0xFF7D2C2A),
    secondary1: Color(0xFFF7EFE3),
    secondary2: Color(0xFFE7DCC4),
    accent: Color(0xFFC0784B),
  );

  static const deepMidnightNavy = AppColorScheme(
    id: 'deep_midnight_navy',
    name: 'Deep Midnight Navy',
    primary1: Color(0xFF0A0F29),
    primary2: Color(0xFF050714),
    secondary1: Color(0xFF5F2EEA),
    secondary2: Color(0xFF7A4FED),
    accent: Color(0xFFDCC38A),
  );

  static const deepEmerald = AppColorScheme(
    id: 'deep_emerald',
    name: 'Deep Emerald',
    primary1: Color(0xFF014D40),
    primary2: Color(0xFF013A30),
    secondary1: Color(0xFFC7D8C6),
    secondary2: Color(0xFFE0E8DF),
    accent: Color(0xFFCBAF6E),
  );

  static const voidBlack = AppColorScheme(
    id: 'void_black',
    name: 'Void Black',
    primary1: Color(0xFF050505),
    primary2: Color(0xFF000000),
    secondary1: Color(0xFF3A0CA3),
    secondary2: Color(0xFF4D1FC7),
    accent: Color(0xFFE9C46A),
  );

  static const duskyPurple = AppColorScheme(
    id: 'dusky_purple',
    name: 'Dusky Purple',
    primary1: Color(0xFF6F4A8E),
    primary2: Color(0xFF5A3D72),
    secondary1: Color(0xFFF7AA74),
    secondary2: Color(0xFFFFC19A),
    accent: Color(0xFFE8D6B1),
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

  static const dreamLilac = AppColorScheme(
    id: 'dream_lilac',
    name: 'Dream Lilac',
    primary1: Color(0xFFCDB4DB),
    primary2: Color(0xFFB89BC9),
    secondary1: Color(0xFFFFC8DD),
    secondary2: Color(0xFFFFD9E8),
    accent: Color(0xFFB9FBC0),
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

  // Premium color schemes based on user feedback
  static const royalAmethyst = AppColorScheme(
    id: 'royal_amethyst',
    name: 'Royal Amethyst',
    primary1: Color(0xFF6B46C1),
    primary2: Color(0xFF553C9A),
    secondary1: Color(0xFFE9D5FF),
    secondary2: Color(0xFFF3E8FF),
    accent: Color(0xFFFBBF24),
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

  static const sunsetVibes = AppColorScheme(
    id: 'sunset_vibes',
    name: 'Sunset Vibes',
    primary1: Color(0xFFE63946),
    primary2: Color(0xFFC1121F),
    secondary1: Color(0xFFFFE5D9),
    secondary2: Color(0xFFFFF0EB),
    accent: Color(0xFFFFB703),
  );

  static const lavenderDreams = AppColorScheme(
    id: 'lavender_dreams',
    name: 'Lavender Dreams',
    primary1: Color(0xFF9B59B6),
    primary2: Color(0xFF7D3C98),
    secondary1: Color(0xFFE8DAEF),
    secondary2: Color(0xFFF4ECF7),
    accent: Color(0xFFF39C12),
  );

  static const forestMist = AppColorScheme(
    id: 'forest_mist',
    name: 'Forest Mist',
    primary1: Color(0xFF2D5016),
    primary2: Color(0xFF1F350F),
    secondary1: Color(0xFFD4E6D1),
    secondary2: Color(0xFFE8F3E6),
    accent: Color(0xFFE67E22),
  );

  static const midnightRose = AppColorScheme(
    id: 'midnight_rose',
    name: 'Midnight Rose',
    primary1: Color(0xFF2C1810),
    primary2: Color(0xFF1A0F09),
    secondary1: Color(0xFFF4E6E6),
    secondary2: Color(0xFFFAF0F0),
    accent: Color(0xFFE74C3C),
  );

  static const auroraBorealis = AppColorScheme(
    id: 'aurora_borealis',
    name: 'Aurora Borealis',
    primary1: Color(0xFF1A5F7A),
    primary2: Color(0xFF134A5F),
    secondary1: Color(0xFFA8E6CF),
    secondary2: Color(0xFFD4F4E8),
    accent: Color(0xFF00D9FF),
  );

  static const goldenHour = AppColorScheme(
    id: 'golden_hour',
    name: 'Golden Hour',
    primary1: Color(0xFF8B4513),
    primary2: Color(0xFF6B3410),
    secondary1: Color(0xFFFFF8DC),
    secondary2: Color(0xFFFFFEF5),
    accent: Color(0xFFFFD700),
  );

  static const cherryBlossom = AppColorScheme(
    id: 'cherry_blossom',
    name: 'Cherry Blossom',
    primary1: Color(0xFFB91C1C),
    primary2: Color(0xFF991B1B),
    secondary1: Color(0xFFFFE4E6),
    secondary2: Color(0xFFFFF1F2),
    accent: Color(0xFFFF69B4),
  );

  static const sageGarden = AppColorScheme(
    id: 'sage_garden',
    name: 'Sage Garden',
    primary1: Color(0xFF4A6741),
    primary2: Color(0xFF3A5232),
    secondary1: Color(0xFFE8F5E9),
    secondary2: Color(0xFFF1F8F2),
    accent: Color(0xFF81C784),
  );

  // Premium elegant color schemes
  static const velvetNights = AppColorScheme(
    id: 'velvet_nights',
    name: 'Velvet Nights',
    primary1: Color(0xFF1A1A2E),
    primary2: Color(0xFF0F0F1E),
    secondary1: Color(0xFFE8E3F0),
    secondary2: Color(0xFFF5F2F8),
    accent: Color(0xFFC9A9DD),
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

  static const royalSapphire = AppColorScheme(
    id: 'royal_sapphire',
    name: 'Royal Sapphire',
    primary1: Color(0xFF1E3A8A),
    primary2: Color(0xFF1E40AF),
    secondary1: Color(0xFFE0E7FF),
    secondary2: Color(0xFFEEF2FF),
    accent: Color(0xFFF59E0B),
  );

  static const burgundyLuxury = AppColorScheme(
    id: 'burgundy_luxury',
    name: 'Burgundy Luxury',
    primary1: Color(0xFF7C2D12),
    primary2: Color(0xFF991B1B),
    secondary1: Color(0xFFFEF2F2),
    secondary2: Color(0xFFFFF5F5),
    accent: Color(0xFFDC2626),
  );

  static const platinumFrost = AppColorScheme(
    id: 'platinum_frost',
    name: 'Platinum Frost',
    primary1: Color(0xFF374151),
    primary2: Color(0xFF1F2937),
    secondary1: Color(0xFFF3F4F6),
    secondary2: Color(0xFFF9FAFB),
    accent: Color(0xFF6366F1),
  );

  static const roseGold = AppColorScheme(
    id: 'rose_gold',
    name: 'Rose Gold',
    primary1: Color(0xFFB45309),
    primary2: Color(0xFF92400E),
    secondary1: Color(0xFFFFF7ED),
    secondary2: Color(0xFFFFFBEB),
    accent: Color(0xFFF59E0B),
  );

  static const jadeSerenity = AppColorScheme(
    id: 'jade_serenity',
    name: 'Jade Serenity',
    primary1: Color(0xFF065F46),
    primary2: Color(0xFF047857),
    secondary1: Color(0xFFD1FAE5),
    secondary2: Color(0xFFECFDF5),
    accent: Color(0xFF10B981),
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

  static const copperSunset = AppColorScheme(
    id: 'copper_sunset',
    name: 'Copper Sunset',
    primary1: Color(0xFF92400E),
    primary2: Color(0xFF78350F),
    secondary1: Color(0xFFFFEDD5),
    secondary2: Color(0xFFFFF7ED),
    accent: Color(0xFFF97316),
  );

  static const tealSophistication = AppColorScheme(
    id: 'teal_sophistication',
    name: 'Teal Sophistication',
    primary1: Color(0xFF134E4A),
    primary2: Color(0xFF0F766E),
    secondary1: Color(0xFFCCFBF1),
    secondary2: Color(0xFFE6FFFA),
    accent: Color(0xFF14B8A6),
  );

  static const indigoNoble = AppColorScheme(
    id: 'indigo_noble',
    name: 'Indigo Noble',
    primary1: Color(0xFF312E81),
    primary2: Color(0xFF3730A3),
    secondary1: Color(0xFFE0E7FF),
    secondary2: Color(0xFFEEF2FF),
    accent: Color(0xFF818CF8),
  );

  static const crimsonRoyal = AppColorScheme(
    id: 'crimson_royal',
    name: 'Crimson Royal',
    primary1: Color(0xFF7F1D1D),
    primary2: Color(0xFF991B1B),
    secondary1: Color(0xFFFEE2E2),
    secondary2: Color(0xFFFEF2F2),
    accent: Color(0xFFEF4444),
  );

  static const slateElite = AppColorScheme(
    id: 'slate_elite',
    name: 'Slate Elite',
    primary1: Color(0xFF1E293B),
    primary2: Color(0xFF0F172A),
    secondary1: Color(0xFFF1F5F9),
    secondary2: Color(0xFFF8FAFC),
    accent: Color(0xFF64748B),
  );

  static const List<AppColorScheme> allSchemes = [
    forestGreen,
    deepNavy,
    midnightBlue,
    richMaroon,
    deepMidnightNavy,
    deepEmerald,
    voidBlack,
    duskyPurple,
    softBlush,
    dreamLilac,
    glacialNavy,
    royalAmethyst,
    oceanDepth,
    sunsetVibes,
    lavenderDreams,
    forestMist,
    midnightRose,
    auroraBorealis,
    goldenHour,
    cherryBlossom,
    sageGarden,
    velvetNights,
    emeraldElegance,
    royalSapphire,
    burgundyLuxury,
    platinumFrost,
    roseGold,
    jadeSerenity,
    amethystTwilight,
    copperSunset,
    tealSophistication,
    indigoNoble,
    crimsonRoyal,
    slateElite,
  ];

  // Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'primary1': primary1.value,
      'primary2': primary2.value,
      'secondary1': secondary1.value,
      'secondary2': secondary2.value,
      'accent': accent.value,
    };
  }

  // Create from JSON
  factory AppColorScheme.fromJson(Map<String, dynamic> json) {
    return AppColorScheme(
      id: json['id'] as String,
      name: json['name'] as String,
      primary1: Color(json['primary1'] as int),
      primary2: Color(json['primary2'] as int),
      secondary1: Color(json['secondary1'] as int),
      secondary2: Color(json['secondary2'] as int),
      accent: Color(json['accent'] as int),
    );
  }

  // Find scheme by ID
  static AppColorScheme? fromId(String id) {
    try {
      return allSchemes.firstWhere((scheme) => scheme.id == id);
    } catch (e) {
      return null;
    }
  }
}

