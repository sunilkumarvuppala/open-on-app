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
  static const Duration magicDustAnimationDuration = Duration(seconds: 8);
  static const Duration sparkleAnimationDuration = Duration(seconds: 3);
  
  // Animation particle counts (optimized for performance)
  static const int magicDustParticleCount = 20; // Reduced from 25
  static const int magicDustSparkleCount = 10; // Reduced from 12
  static const double magicDustHeaderAreaRatio = 0.4;
  static const double magicDustMinOpacity = 0.04;
  static const double magicDustMaxOpacity = 0.06;
  static const double sparkleMaxOpacity = 0.8;
  static const double sparkleMinVisibleOpacity = 0.05;
  
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

  // Default values
  static const String defaultUserId = 'current-user';
  static const String defaultUserName = 'User';
  static const String defaultAvatarPath = 'assets/images/default_avatar.png';
  static const String untitledDraftTitle = 'Untitled Draft';
  static const String noContentText = 'No content yet';

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

