/// Application-wide constants
/// All magic numbers and hardcoded values should be defined here
class AppConstants {
  AppConstants._();

  // Capsule status thresholds
  static const int unlockingSoonDaysThreshold = 7;
  static const int arrowDisplayDaysThreshold = 3; // Show arrow only if unlock time is within 3 days
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
  
  // Connection Detail Screen dimensions
  static const double connectionDetailAvatarSize = 64.0;
  static const double connectionDetailButtonHeight = 56.0;
  static const double connectionDetailButtonIconSize = 18.0;
  static const double connectionDetailButtonTextSize = 16.0;
  static const double connectionDetailButtonIconSpacing = 8.0;
  static const double connectionDetailStatDividerHeight = 40.0;
  static const double connectionDetailStatDividerWidth = 1.0;
  
  // Profile Avatar Button dimensions
  static const double profileAvatarButtonSize = 32.0;
  static const double profileAvatarButtonPadding = 8.0;
  static const double profileAvatarButtonLoadingStrokeWidth = 2.0;

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
  
  // Capsule card dimensions
  static const double capsuleCardIconSize = 64.0;
  static const double capsuleCardIconInnerSize = 32.0;
  static const double capsuleCardChevronSize = 18.0;
  static const double capsuleCardChevronSizeSmall = 14.0; // Smaller, less prominent arrow
  static const double capsuleCardChevronOpacity = 0.5; // Reduced opacity for subtle "sealed envelope" feel
  static const double capsuleCardBadgeIndicatorSize = 10.0;
  static const double capsuleCardBadgeBorderWidth = 1.5;
  static const double capsuleCardAvatarSize = 48.0; // Profile avatar size on capsule cards
  
  // Capsule card text sizes
  static const double capsuleCardTitleFontSize = 16.0;
  static const double capsuleCardLabelFontSize = 14.0;
  static const double capsuleCardDateFontSize = 12.0;
  static const double capsuleCardCountdownFontSize = 11.0;
  
  // Capsule card spacing
  static const double capsuleCardTitleSpacing = 4.0;
  static const double capsuleCardLabelSpacing = 6.0;
  static const double capsuleCardDateIconSize = 13.0;
  static const double capsuleCardCountdownIconSize = 11.0;
  static const double capsuleCardDateIconSpacing = 5.0;
  static const double capsuleCardCountdownIconSpacing = 3.0;
  
  // Animation durations
  static const Duration badgeAnimationDuration = Duration(milliseconds: 200);
  
  // Text line heights
  static const double textLineHeightTight = 1.2;
  static const double textLineHeightNormal = 1.0;
  
  // Border radius
  static const double capsuleCardBorderRadius = 16.0;
  
  // Shadow properties
  static const double capsuleCardShadowBlur = 8.0;
  static const double capsuleCardShadowSpread = 0.0;
  // Note: Offset cannot be const in this context, use const Offset(0, 2) directly in widgets
  
  // Opacity values
  static const double shadowOpacityDark = 0.1;
  static const double shadowOpacityLight = 0.3;
  
  // Badge indicator positioning
  static const double badgeIndicatorTop = 6.0;
  static const double badgeIndicatorRight = 6.0;

  // Opening animation screen dimensions
  static const double openingAnimationCardWidth = 300.0;
  static const double openingAnimationCardHeight = 400.0;
  
  // Identity lock card dimensions
  static const double identityLockCardWidth = 300.0;
  static const double openingAnimationIconSize = 60.0;
  static const double openingAnimationTitleFontSize = 24.0;
  static const double openingAnimationSubtitleFontSize = 16.0;
  static const double openingAnimationSkipButtonTop = 16.0;
  static const double openingAnimationSkipButtonRight = 16.0;
  static const double openingAnimationSkipButtonFontSize = 16.0;
  static const double openingAnimationCardScaleBegin = 0.8;
  static const double openingAnimationCardScaleEnd = 1.0;
  static const double openingAnimationShadowOpacity = 0.2;
  static const double openingAnimationShadowBlur = 20.0;
  static const double openingAnimationShadowOffsetY = 10.0;

  // Opened letter screen dimensions
  static const double openedLetterEnvelopeIconSize = 48.0;
  static const double openedLetterContentFontSize = 16.0;
  static const double openedLetterContentLineHeight = 1.8;
  static const double openedLetterReactionButtonSize = 60.0;
  static const double openedLetterReactionEmojiSize = 28.0;
  static const double openedLetterReactionSelectedScale = 1.2;
  static const double openedLetterReactionBorderWidth = 2.0;
  static const double openedLetterReactionSelectedOpacity = 0.1;
  static const double openedLetterReactionUnselectedOpacity = 0.5;
  static const double openedLetterCardShadowOpacity = 0.05;
  static const double openedLetterCardShadowBlur = 10.0;
  static const double openedLetterCardShadowOffsetY = 4.0;
  static const double openedLetterBottomBarShadowOffsetY = -5.0;
  
  // Opened letter screen animation durations
  static const Duration openedLetterHeaderFadeDuration = Duration(milliseconds: 400);
  static const Duration openedLetterMessageFadeDuration = Duration(milliseconds: 600);
  static const Duration openedLetterEnvelopeOpacityDuration = Duration(milliseconds: 800);
  static const Duration openedLetterReplyFadeDuration = Duration(milliseconds: 600);
  static const Duration openedLetterHeaderFadeDelay = Duration(milliseconds: 500);
  static const Duration openedLetterMessageFadeDelay = Duration(milliseconds: 400);
  static const Duration openedLetterEnvelopeOpacityDelay = Duration(milliseconds: 600);
  static const Duration openedLetterReplyFadeDelay = Duration(milliseconds: 1000);
  static const Duration openedLetterIconToggleInterval = Duration(seconds: 5);
  static const Duration openedLetterIconToggleTransitionDuration = Duration(milliseconds: 3000);
  
  // Opened letter screen opacity values
  static const double openedLetterHeaderOpacity = 0.5;
  static const double openedLetterEnvelopeOpacityEnd = 0.5;
  static const double openedLetterMessageContainerOpacity = 0.91;
  static const double openedLetterCardBackgroundOpacity = 0.3;
  static const double openedLetterShadowOpacity = 0.15;
  static const double openedLetterAvatarGradientOpacity = 0.2;
  static const double openedLetterSeeReplyButtonOpacity = 0.85;
  static const double openedLetterSeeReplyTextOpacity = 0.95;
  static const double openedLetterWhisperTextOpacity = 0.5;
  static const double openedLetterSecondaryTextOpacity = 0.6;
  static const double openedLetterSecondaryTextOpacityMedium = 0.7;
  
  // Opened letter screen sizes and spacing
  static const double openedLetterTitleFontSize = 48.0;
  static const double openedLetterTitleSpacing = 2.0;
  static const double openedLetterMessageMinHeight = 300.0;
  static const double openedLetterMessageVerticalPadding = 2.0; // Multiplier for spacingXl
  static const double openedLetterDateFontSize = 12.0;
  static const double openedLetterCountdownIconSize = 14.0;
  
  // Opened letter screen gradient blend values
  static const double openedLetterGradientBlendTop = 0.15;
  static const double openedLetterGradientBlendTopSecondary = 0.08;
  static const double openedLetterGradientBlendBottom = 0.05;
  static const double openedLetterGradientBlendDark = 0.03;
  static const double openedLetterWarmColorBlendRed = 0.08;
  static const double openedLetterWarmColorBlendGreen = 0.07;
  static const double openedLetterWarmColorBlendBlue = 0.90;
  static const double openedLetterWarmColorBlendGray = 0.20;
  static const double openedLetterWarmColorBlendWhite = 0.15;
  static const double openedLetterLightEnvelopeBlend1 = 0.65;
  static const double openedLetterLightEnvelopeBlend2 = 0.70;
  static const double openedLetterLightEnvelopeBlendMix = 0.6;
  
  // Opened letter screen colors
  static const int openedLetterTextColorDark = 0xFF1A1A1A;
  static const int openedLetterPaperGrayColor = 0xFF2A2A2A;
  
  // Letter reply composer dimensions
  static const double letterReplyEmojiSize = 32.0;
  static const double letterReplyEmojiContainerSize = 56.0;
  static const double letterReplyEmojiRowHeight = 64.0;
  static const double letterReplyEmojiSpacing = 0.0;
  static const double letterReplyArrowGradientWidth = 40.0;
  static const double letterReplyArrowIconSize = 26.0;
  static const double letterReplyLoadingIndicatorSize = 20.0;
  static const double letterReplyBorderWidth = 2.0;
  static const Duration letterReplyEmojiAnimationDuration = Duration(milliseconds: 200);
  
  // Letter reply composer opacity values
  static const double letterReplyDividerOpacity = 0.3;
  static const double letterReplySecondaryTextOpacity = 0.7;
  static const double letterReplyHintTextOpacity = 0.5;
  static const double letterReplyEmojiSelectedOpacity = 0.2;
  static const double letterReplyEmojiDisabledOpacity = 0.5;
  static const double letterReplyDisabledBackgroundOpacity = 0.3;
  
  // Star dust particle settings
  static const int starDustParticleCount = 15;
  static const double starDustOpacityMultiplier = 0.50;
  static const double starDustSpeedMultiplier = 0.4;

  // Reaction emojis (centralized for consistency)
  static const List<String> reactionEmojis = ['❤️', '😭', '🤗', '😍', '🥰'];

  // Heartbeat animation constants
  static const double heartbeatIconSize = 20.4; // Reduced by 15% from 24.0
  static const double heartbeatIconSizeMin = 17.0; // Minimum scale (83% of base) - resting size, reduced by 15%
  static const double heartbeatIconSizeSmall = 21.25; // Small beat size (104% of base) - "lub", reduced by 15%
  static const double heartbeatIconSizeBig = 25.5; // Big beat size (125% of base) - "dub", reduced by 15%
  static const Duration heartbeatSmallBeatDuration = Duration(milliseconds: 200); // Small beat duration
  static const Duration heartbeatBigBeatDuration = Duration(milliseconds: 300); // Big beat duration
  static const Duration heartbeatPauseDuration = Duration(milliseconds: 150); // Pause between beats
  static const Duration heartbeatCycleDuration = Duration(milliseconds: 1200); // Full cycle (lub-pause-dub-longpause)
  static const double heartbeatBottomMargin = 16.0;
  static const double heartbeatRightMargin = 19.5; // Moved 3.5px inward from right edge (was 16.0)
  // Heartbeat color: Dark red (#C62828) - darker than standard red for better visibility
  static const int heartbeatColorValue = 0xFFC62828;
  static const double heartbeatOpacity = 0.7; // Reduced opacity for subtle appearance
  
  // Icon outline constants (for white outline effect)
  static const double iconOutlineWidth = 0.5; // Base white outline thickness for icons
  static const double lockEmojiOutlineSizeMultiplier = 2.0; // Multiplier for lock emoji outline (needs larger outline for visibility)

  // Opened letter pulse animation constants
  static const double openedLetterPulseIconSize = 20.4; // Reduced by 15% from 24.0
  static const double openedLetterPulseIconSizeMin = 18.7; // Minimum scale (92% of base) - gentle pulse, reduced by 15%
  static const double openedLetterPulseIconSizeMax = 22.1; // Maximum scale (108% of base) - gentle expansion, reduced by 15%
  static const Duration openedLetterPulseCycleDuration = Duration(milliseconds: 2000); // Slow, gentle breathing cycle
  static const double openedLetterPulseBottomMargin = 16.0;
  static const double openedLetterPulseRightMargin = 19.5; // Moved 3.5px inward from right edge (was 16.0)
  // Opened letter pulse color: Soft green (#4CAF50) - success/completion color
  static const int openedLetterPulseColorValue = 0xFF4CAF50;
  static const double openedLetterPulseOpacity = 0.7; // Reduced opacity for subtle appearance

  // Capsule list spacing constants
  static const double capsuleListItemSpacing = 5.0; // Spacing between capsule items in lists (tight layout for better density)

  // Sealed letter animation constants (for locked capsules)
  static const double sealedLetterIconSize = 20.4; // Reduced by 15% from 24.0
  static const double sealedLetterRotationAngle = 0.3; // Rotation angle in radians (about 17 degrees) - left and right
  static const Duration sealedLetterShakeDuration = Duration(milliseconds: 150); // Duration of each rapid left-right rotation
  static const Duration sealedLetterPauseDuration = Duration(milliseconds: 400); // Pause duration before repeating
  static const Duration sealedLetterCycleDuration = Duration(milliseconds: 1000); // Full cycle (4 shakes + pause = 4*150 + 400 = 1000ms)
  static const double sealedLetterBottomMargin = 16.0;
  static const double sealedLetterRightMargin = 19.5; // Moved 3.5px inward from right edge (was 16.0)
  // Sealed letter color: Deep purple/indigo (#5C6BC0) - mysterious, locked appearance
  static const int sealedLetterColorValue = 0xFF5C6BC0;
  static const double sealedLetterOpacity = 0.7; // Reduced opacity for subtle appearance
  // Animation threshold: only animate if unlock time is less than this duration away
  // Using Duration for precise comparison (6 hours = 21600 seconds)
  static const Duration sealedLetterAnimationThreshold = Duration(hours: 6);

  // Locked capsule screen constants
  static const double lockedCapsuleAvatarSize = 60.0;
  static const double lockedCapsuleAvatarRadius = 30.0; // Half of avatar size
  static const double lockedCapsuleEmojiSize = 30.0;
  static const double lockedCapsuleEmojiContainerSize = 36.0; // Slightly larger than emoji for circular glow
  static const double lockedCapsuleEmojiStackHeight = 100.0;
  static const double lockedCapsuleEmojiTextTopPosition = 65.0;
  static const double lockedCapsuleLockIconSize = 70.0;
  static const double lockedCapsuleLockHaloSize = 90.0;
  static const double lockedCapsuleCircleSizeMin = 160.0;
  static const double lockedCapsuleCircleSizeMax = 180.0;
  
  // Locked capsule emoji animation constants
  static const Duration lockedCapsuleEmojiAnimationDuration = Duration(milliseconds: 2000);
  static const Duration lockedCapsuleEmojiTimerInterval = Duration(seconds: 2);
  static const double lockedCapsuleEmojiBaseOpacity = 0.75;
  static const double lockedCapsuleEmojiOpacityFade = 0.15; // Amount to fade during animation
  static const double lockedCapsuleEmojiOpacityMin = 0.6;
  static const double lockedCapsuleEmojiOpacityMax = 0.75;
  static const double lockedCapsuleEmojiScaleMin = 0.8;
  static const double lockedCapsuleEmojiScaleMax = 1.0;
  static const double lockedCapsuleEmojiScaleRange = 0.2; // Scale range (max - min)
  
  // Locked capsule emoji glow constants
  static const double lockedCapsuleEmojiGlowOpacity = 0.1;
  static const double lockedCapsuleEmojiGlowBlurRadius = 4.0;
  static const double lockedCapsuleEmojiGlowSpreadRadius = 1.0;
  static const double lockedCapsuleEmojiTextShadowOpacity = 0.15;
  static const double lockedCapsuleEmojiTextShadowBlurRadius = 3.0;
  
  // Locked capsule halo animation constants
  static const double lockedCapsuleHaloOpacityMin = 0.0;
  static const double lockedCapsuleHaloOpacityMax = 0.25;
  static const double lockedCapsuleHaloBlurRadius = 20.0;
  static const double lockedCapsuleHaloSpreadRadius = 5.0;
  
  // Locked capsule layout constants
  static const double lockedCapsuleMinScreenWidth = 200.0;
  static const double lockedCapsuleAvatarSpacing = 2.0; // Multiplier for spacingXl
  static const double lockedCapsuleTextFontSize = 12.0;
  static const double lockedCapsuleEmojiFontSize = 30.0;
  static const double lockedCapsuleTextLineHeight = 1.0;
  static const double lockedCapsuleEnvelopeContainerSize = 180.0;
  static const double lockedCapsuleCountdownFontSize = 30.0;
  static const double lockedCapsuleTitleFontSize = 22.0;
  static const double lockedCapsuleSubtitleFontSize = 16.0;

  // Tab indicator sparkle animation constants
  static const int tabIndicatorSparkleCount = 3;
  static const double tabIndicatorMaxRadiusMultiplier = 0.3;
  static const double tabIndicatorRadiusMinMultiplier = 0.3;
  static const double tabIndicatorRadiusRangeMultiplier = 0.7;
  static const double tabIndicatorSparkleSizeBase = 2.5;
  static const double tabIndicatorSparkleSizeRange = 1.5;
  static const double tabIndicatorAnimationSpeedRadius = 2.0;
  static const double tabIndicatorAnimationSpeedOpacity = 3.0;
  static const double tabIndicatorAnimationSpeedSize = 4.0;
  static const Duration tabIndicatorBreathingAnimationDuration = Duration(seconds: 3);
  
  // Tab indicator sparkle layer constants
  static const double tabIndicatorAccentGlowOpacityMultiplier = 0.25;
  static const double tabIndicatorAccentGlowBlurMultiplier = 1.2;
  static const double tabIndicatorAccentGlowSizeMultiplier = 0.7;
  static const double tabIndicatorMainSparkleOpacityMultiplier = 0.5;
  static const double tabIndicatorMainSparkleBlurMultiplier = 0.6;
  static const double tabIndicatorCenterGlowOpacityMultiplier = 0.7;
  static const double tabIndicatorCenterGlowBlurMultiplier = 1.2;
  static const double tabIndicatorCenterGlowSizeMultiplier = 0.6;
  static const double tabIndicatorInnerCircleOpacityMultiplier = 0.8;
  static const double tabIndicatorInnerCircleSizeMultiplier = 0.25;
  
  // Badge shimmer animation constants
  static const int badgeSparkleCount = 2; // Number of sparkles in badge shimmer
  static const double badgeShimmerWidth = 40.0; // Width of shimmer sweep
  static const double badgeShimmerAngle = -0.7853981633974483; // -π/4 radians (diagonal angle for shimmer)
  
  // Badge dimensions and styling
  static const double badgeFixedWidth = 110.0; // Fixed width for all status badges to ensure consistent alignment
  static const double badgeColorLightenFactor = 0.3; // Factor for lightening locked badge color (30% blend with light color)
  static const double badgeColorDarkenFactor = 0.2; // Factor for darkening opened badge color (20% blend with dark color)
  
  // Connection card dimensions
  static const double connectionCardAvatarRadius = 24.0; // Avatar radius in connection cards (reduced from 28)
  static const double connectionCardStatusIndicatorSize = 12.0; // Online/status indicator size (reduced from 14)
  static const double connectionCardStatusIndicatorBorderWidth = 2.0; // Border width for status indicator
  static const double connectionCardButtonIconSize = 16.0; // Icon size in action buttons (reduced from 18)
  static const double connectionCardAvatarTextSize = 18.0; // Font size for avatar initials (reduced from 20)
  static const double connectionCardDialogIconSize = 20.0; // Icon size in dialogs
  static const double connectionCardSmallIconSize = 16.0; // Small icon size for status indicators
  static const double connectionCardPadding = 12.0; // Padding inside connection cards (reduced from 16)
  static const double connectionCardAvatarBorderWidth = 1.5; // Border width around avatar (reduced from 2)

  // Dialog text colors - ensure consistent, theme-aware colors for all popups
  // These constants ensure all dialogs use proper colors for visibility
  static const int dialogTitleColorLight = 0xFF1A1A1A; // Very dark for light themes (high contrast)
  static const int dialogTitleColorDark = 0xFFFFFFFF; // White for dark themes
  static const int dialogContentColorLight = 0xFF4A4A4A; // Dark gray for light themes
  static const int dialogContentColorDark = 0xFFFFFFFF; // White for dark themes
  static const int dialogButtonColorLight = 0xFF9E9E9E; // Medium gray for light themes
  static const int dialogButtonColorDark = 0xFFFFFFFF; // White for dark themes

  // Icon types for animations (using Material Icons)
  // Ready: sparkle/star for excitement, Opened: checkmark for completion, Sealed: lock for locked state

  // Text strings (centralized for i18n readiness)
  static const String readyToOpenText = 'Ready to open';
  static const String reactionSentMessage = 'Reaction sent to';
  static const String failedToSendReaction = 'Failed to send reaction';
  static const String shareFeatureComingSoon = 'Share feature coming soon';
  static const String howDoesThisMakeYouFeel = 'How does this make you feel?';
  static const String fromPrefix = 'From';
  static const String openedOnPrefix = 'Opened on';
  
  // Connection Detail Screen strings
  static const String connectionDetailTitle = 'Connection';
  static const String writeLetterButtonText = 'Write letter';
  static const String lettersSentLabel = 'Letters sent';
  static const String lettersReceivedLabel = 'Letters received';
  static const String relationshipSummaryTitle = 'Relationship Summary';
  static const String relationshipSummaryMessage = 'Some words are still waiting for the right moment.';
  static const String lettersPlaceholderText = 'Letters will appear here when they are opened.';
  static const String connectedSincePrefix = 'Connected since';
  static const String pleaseLogInMessage = 'Please log in to send a letter';
  static const String failedToPrepareLetterMessage = 'Failed to prepare letter';
  static const String failedToLoadConnectionDetailsMessage = 'Failed to load connection details';
  static const String connectionNotFoundMessage = 'Connection not found';
  
  // Default relationship type
  static const String defaultRelationshipType = 'friend';
  
  // Date format strings
  static const String connectionDateFormat = 'MMM dd, yyyy';
  static const String previewUnlockDateFormat = 'EEEE, MMMM d, y \'at\' h:mm a';

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
  
  // Preview screen dimensions
  static const double previewEnvelopeIconSize = 60.0;
  static const double previewEnvelopeIconInnerSize = 30.0;
  static const double previewAvatarSize = 60.0;
  static const double previewArrowIconSizeLarge = 18.0;
  static const double previewArrowIconSizeSmall = 16.0;
  static const double previewSmallIconSize = 14.0;
  static const double previewButtonIconSize = 20.0;
  static const double previewDetailRowIconSize = 20.0;
  
  // Preview screen spacing
  static const double previewIconTextSpacing = 6.0;
  static const double previewAnonymousIconSpacing = 4.0;
  static const double previewArrowOffsetStart = -12.0;
  static const double previewArrowOffsetEnd = 8.0;
  
  // Preview screen font sizes
  static const double previewLabelFontSize = 18.0;
  static const double previewRecipientFontSize = 14.0;
  static const double previewUnlockTimeFontSize = 12.0;
  static const double previewLetterContentFontSize = 16.0;
  static const double previewDetailRowLabelFontSize = 12.0;
  static const double previewDetailRowValueFontSize = 16.0;
  
  // Preview screen animation durations
  static const Duration previewArrowAnimationDuration = Duration(seconds: 2);
  static const Duration previewButtonAnimationDuration = Duration(milliseconds: 600);
  static const Duration previewButtonDelayDuration = Duration(milliseconds: 400);
  
  // Preview screen animation values
  static const double previewArrowOpacityThresholdLow = 0.2;
  static const double previewArrowOpacityThresholdHigh = 0.8;
  static const double previewSecondArrowDelay = 0.5;
  static const double previewArrowOpacityFade = 0.8;
  
  // Preview screen shadow/glow values
  static const double previewEnvelopeShadowOpacity = 0.3;
  static const double previewEnvelopeShadowBlur = 20.0;
  static const double previewEnvelopeShadowOffsetY = 10.0;
  static const double previewLetterShadowOpacityDark = 0.1;
  static const double previewLetterShadowOpacityLight = 0.03;
  static const double previewLetterShadowBlur = 4.0;
  static const double previewLetterShadowOffsetY = 1.0;
  static const double previewNavBarShadowBlur = 10.0;
  static const double previewNavBarShadowOffsetY = -5.0;
  
  // Preview screen other values
  static const double previewBorderWidth = 1.0;
  static const double previewLetterLineHeight = 1.6;
  static const double previewButtonMinHeight = 56.0;
  static const double previewGradientOpacityEnd = 0.7;
  static const double previewTextOpacity = 0.9;
  
  // ============================================================================
  // Thoughts Feature Constants
  // ============================================================================
  
  // Pagination limits (should match database config, but used for client-side validation)
  static const int thoughtsDefaultLimit = 30;
  static const int thoughtsMinLimit = 1;
  static const int thoughtsMaxLimit = 100;
  
  // Client source identifiers
  static const String clientSourceIOS = 'ios';
  static const String clientSourceAndroid = 'android';
  static const String clientSourceWeb = 'web';
  
  // Default fallback values
  static const String defaultSenderName = 'Someone';
  
  // ============================================================================
  // Countdown Share Configuration
  // ============================================================================
  // Share base URL - can be overridden via environment variable
  static String get shareBaseUrl {
    // Check environment variable first (for production)
    const envUrl = String.fromEnvironment('SHARE_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    // Default production URL
    return 'https://openon.app/share';
  }
  
  // Share page cache TTL in seconds (60 seconds = 1 minute)
  static const int sharePageCacheTtl = 60;
  
  // Share creation debounce duration (prevents double-clicks)
  static const Duration shareCreationDebounce = Duration(milliseconds: 500);
  
  // Maximum retry attempts for share creation
  static const int shareCreationMaxRetries = 3;
  
  // Retry delay for share creation (exponential backoff)
  static const Duration shareCreationRetryDelay = Duration(milliseconds: 500);
}

