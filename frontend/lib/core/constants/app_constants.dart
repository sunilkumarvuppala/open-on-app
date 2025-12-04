/// Application-wide constants
/// All magic numbers and hardcoded values should be defined here
class AppConstants {
  AppConstants._();

  // Capsule status thresholds
  static const int unlockingSoonDaysThreshold = 7;
  static const int maxContentLength = 10000;
  static const int maxTitleLength = 200;
  static const int maxLabelLength = 100;
  static const int minContentLength = 1;

  // Time durations
  static const Duration networkDelaySimulation = Duration(milliseconds: 500);
  static const Duration createCapsuleDelay = Duration(milliseconds: 800);
  static const Duration updateDelay = Duration(milliseconds: 500);
  static const Duration deleteDelay = Duration(milliseconds: 300);
  static const Duration authDelay = Duration(milliseconds: 1000);
  static const Duration signOutDelay = Duration(milliseconds: 300);
  static const Duration getCurrentUserDelay = Duration(milliseconds: 200);
  static const Duration routerNavigationDelay = Duration(milliseconds: 200);

  // UI dimensions
  static const double bottomNavHeight = 60.0;
  static const double fabSpacing = 10.0;
  static const double fabSize = 56.0;
  static const double fabMargin = 16.0;
  static const double fabYOffset = 70.0; // bottomNavHeight + fabSpacing
  static const double userAvatarSize = 48.0;
  static const double defaultPadding = 16.0;
  static const double headerSeparatorHeight = 1.0;
  static const double createButtonHeight = 56.0;
  static const double tabLabelPadding = 4.0;
  static const double tabSpacing = 3.0;
  static const double separatorLineWidth = 1.0;

  // Animation durations
  static const Duration animationDurationShort = Duration(milliseconds: 200);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration animationDurationLong = Duration(milliseconds: 500);
  static const Duration openingAnimationDuration = Duration(milliseconds: 1500);
  static const Duration openingAnimationDelay = Duration(milliseconds: 500);
  static const Duration magicDustAnimationDuration = Duration(seconds: 60); // Longer duration for extended sparkle movement
  static const Duration sparkleAnimationDuration = Duration(seconds: 3);
  
  // Animation particle counts (optimized for performance)
  static const int magicDustParticleCount = 20;
  static const int magicDustSparkleCount = 10;
  static const double magicDustSparkleCountMultiplier = 1.5; // Multiplier for full-screen coverage
  static const double magicDustHeaderAreaRatio = 0.4;
  static const double magicDustMinOpacity = 0.04;
  static const double magicDustMaxOpacity = 0.06;
  static const double sparkleMaxOpacity = 0.8;
  static const double sparkleMinVisibleOpacity = 0.05;
  
  // Sparkle movement constants
  static const double sparkleBaseVelocity = 0.00001; // Base velocity multiplier for slow movement
  static const double sparkleSizeMin = 1.5;
  static const double sparkleSizeMax = 3.5; // 1.5 + 2.0
  
  // Sparkle rendering constants
  static const double sparkleGlowOpacityMultiplier = 0.3; // Outer glow opacity relative to main sparkle
  static const double sparkleGlowSizeMultiplier = 1.5; // Outer glow size relative to sparkle
  static const double sparkleBlurMultiplier = 3.0; // Blur radius multiplier for outer glow
  static const double sparkleMainBlurMultiplier = 0.5; // Blur radius multiplier for main sparkle
  static const double sparkleCenterOpacityMultiplier = 1.2; // Center point opacity multiplier
  static const double sparkleCenterSizeMultiplier = 0.3; // Center point size relative to sparkle
  static const int millisecondsPerSecond = 1000; // Conversion factor
  
  // UI Opacity constants (for theme-aware transparency)
  static const double opacityTransparent = 0.0;
  static const double opacityVeryLow = 0.05;
  static const double opacityLow = 0.1;
  static const double opacityMedium = 0.15;
  static const double opacityMediumHigh = 0.2;
  static const double opacityHigh = 0.3;
  static const double opacityVeryHigh = 0.6;
  static const double opacityNearlyOpaque = 0.9;
  static const double opacityOpaque = 0.95;
  static const double opacityFull = 1.0;
  
  // Shimmer opacity constants
  static const double shimmerEdgeOpacity = 0.15;
  static const double shimmerCenterOpacity = 0.3;
  
  // Badge glow opacity constants
  static const double badgeGlowBackgroundOpacity = 0.1;
  static const double badgeGlowShadowOpacity = 0.2;
  
  // Navigation glow constants
  static const double navGlowBackgroundOpacity = 0.1;
  static const double navGlowShadowOpacity = 0.2;
  static const double navGlowSize = 24.0;
  static const double navGlowOffset = 2.0;
  
  // Animation performance settings
  static const int targetFPS = 60;
  static const double frameTime = 1.0 / targetFPS; // ~16.67ms

  // Text limits
  static const int draftSnippetLength = 100;
  static const int maxRecipientNameLength = 50;
  static const int maxRelationshipLength = 30;

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int maxEmailLength = 254;
  static const int maxNameLength = 100;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 100;

  // Search settings
  static const int minSearchQueryLength = 2;
  static const int searchDebounceMs = 500;
  static const int maxSearchResults = 10;
  static const int defaultSearchLimit = 10;
  static const int maxSearchLimit = 50;
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const int defaultPage = 1;
  
  // Default values
  static const String defaultUserId = 'current-user';
  static const String defaultUserName = 'User';
  static const String defaultAvatarPath = 'assets/images/default_avatar.png';
  static const String untitledDraftTitle = 'Untitled Draft';
  static const String noContentText = 'No content yet';
  
  // UI component sizes
  static const double avatarRadius = 50.0;
  static const double avatarIconSize = 36.0;
  static const double searchResultsMaxHeight = 200.0;
  static const double searchIndicatorSize = 20.0;

  // Asset paths
  static const String avatarPriya = 'assets/images/avatar_priya.png';
  static const String avatarAnanya = 'assets/images/avatar_ananya.png';
  static const String avatarRaj = 'assets/images/avatar_raj.png';
  static const String avatarMom = 'assets/images/avatar_mom.png';

  // Mock data IDs
  static const String mockUserId = 'current-user';
  static const String mockPriyaId = 'priya-123';
  static const String mockAnanyaId = 'ananya-456';
  static const String mockRajId = 'raj-789';
  static const String mockMomId = 'mom-999';
}

