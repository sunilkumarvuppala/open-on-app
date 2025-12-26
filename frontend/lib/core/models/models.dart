import 'package:openon_app/core/constants/app_constants.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Capsule status enum
enum CapsuleStatus {
  locked,
  unlockingSoon,
  ready,
  opened,
  // NOTE: 'revealed' is not a separate status - it's just 'opened' with sender_revealed_at set
  // We use isRevealed getter to check if anonymous sender is visible
}

/// Capsule model - represents a time-locked letter
/// 
/// IMPORTANT: recipientId is the UUID of the recipient record (from recipients table),
/// NOT the user ID of the receiver. For connection-based recipients, use the recipient's
/// linked_user_id to find the actual user. For email-based recipients, match by email.
class Capsule {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String recipientId; // UUID of recipient record (references recipients table)
  final String receiverName;
  final String receiverAvatar;
  final String label; // e.g., "Open on your birthday"
  final String content;
  final String? photoUrl;
  final DateTime unlockAt;
  final DateTime createdAt;
  final DateTime? openedAt;
  final String? reaction; // Emoji reaction from receiver
  
  // Anonymous letter fields
  final bool isAnonymous;
  final int? revealDelaySeconds; // Delay in seconds before revealing sender (0-259200)
  final DateTime? revealAt; // When sender will be revealed (openedAt + revealDelaySeconds)
  final DateTime? senderRevealedAt; // When sender was actually revealed
  
  // Anonymous identity hints (current hint shown to receiver)
  final String? currentHintText; // Current eligible hint text (fetched from backend)
  final int? currentHintIndex; // Current hint index (1, 2, or 3)
  
  // Invite URL (for unregistered recipients)
  final String? inviteUrl; // Invite URL if this is for an unregistered recipient
  
  Capsule({
    String? id,
    required this.senderId,
    required this.senderName,
    String? senderAvatarValue,
    required this.recipientId,
    required this.receiverName,
    String? receiverAvatarValue,
    required this.label,
    required this.content,
    this.photoUrl,
    required this.unlockAt,
    DateTime? createdAt,
    this.openedAt,
    this.reaction,
    this.isAnonymous = false,
    this.revealDelaySeconds,
    this.revealAt,
    this.senderRevealedAt,
    this.currentHintText,
    this.currentHintIndex,
    this.inviteUrl,
  })  : id = id ?? _uuid.v4(),
        senderAvatar = senderAvatarValue ?? '',
        receiverAvatar = receiverAvatarValue ?? '',
        createdAt = createdAt ?? DateTime.now();
  
  /// Get current time (cached per status calculation to avoid multiple calls)
  DateTime get _now => DateTime.now();
  
  CapsuleStatus get status {
    final now = _now;
    
    // NOTE: 'revealed' is not a separate status - it's just 'opened' with sender visible
    // Use isRevealed getter to check if anonymous sender is visible
    // Status remains 'opened' even after anonymous sender is revealed
    
    if (openedAt != null) {
      return CapsuleStatus.opened;
    }
    
    // If unlock time has passed but not opened, it's ready
    if (unlockAt.isBefore(now) || unlockAt.isAtSameMomentAs(now)) {
      return CapsuleStatus.ready;
    }
    
    final daysUntilUnlock = unlockAt.difference(now).inDays;
    if (daysUntilUnlock <= AppConstants.unlockingSoonDaysThreshold) {
      return CapsuleStatus.unlockingSoon;
    }
    
    return CapsuleStatus.locked;
  }
  
  bool get isLocked {
    final now = _now;
    return unlockAt.isAfter(now) && openedAt == null;
  }
  
  bool get isUnlocked {
    final now = _now;
    return unlockAt.isBefore(now) && openedAt == null;
  }
  
  bool get isOpened => openedAt != null;
  
  bool get isUnlockingSoon {
    if (isOpened || isUnlocked) return false;
    final now = _now;
    final daysUntilUnlock = unlockAt.difference(now).inDays;
    return daysUntilUnlock <= AppConstants.unlockingSoonDaysThreshold;
  }
  
  bool get canOpen {
    final now = _now;
    return unlockAt.isBefore(now) && openedAt == null;
  }
  
  String get recipientName => receiverName;
  
  /// Check if the current user is the sender of this capsule
  /// 
  /// This is a simple comparison since senderId is always a user UUID.
  bool isCurrentUserSender(String currentUserId) {
    return senderId == currentUserId;
  }
  
  /// Check if the current user is the receiver of this capsule
  /// 
  /// WARNING: This method cannot reliably determine receiver status on the frontend
  /// because recipientId is a recipient record UUID, not a user UUID.
  /// 
  /// For connection-based recipients: recipientId points to a recipient record
  /// that has a linked_user_id field containing the actual user ID.
  /// 
  /// For email-based recipients: recipientId points to a recipient record
  /// that has an email field that must be matched.
  /// 
  /// RECOMMENDATION: Always verify receiver status via backend API endpoints
  /// that have access to the full recipient data and can properly match users.
  /// 
  /// This method is provided for convenience but should be used with caution.
  /// Prefer backend verification for critical operations.
  @Deprecated('Use backend API verification instead. This cannot reliably determine receiver status.')
  bool isCurrentUserReceiver(String currentUserId) {
    // This is intentionally always false to prevent misuse
    // The frontend cannot reliably determine receiver status without recipient data
    return false;
  }
  
  DateTime get unlockTime => unlockAt;
  
  Duration get timeUntilUnlock {
    if (!isLocked) return Duration.zero;
    final now = _now;
    return unlockAt.difference(now);
  }
  
  String get countdownText {
    if (!isLocked) return AppConstants.readyToOpenText;
    
    final duration = timeUntilUnlock;
    // If duration is negative or zero, it's ready to open
    if (duration.isNegative || duration.inSeconds <= 0) {
      return AppConstants.readyToOpenText;
    }
    
    final totalSeconds = duration.inSeconds;
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    // Calculate minutes from total seconds (not using duration.inMinutes which can truncate)
    // This ensures 1 minute is shown when there's 60+ seconds remaining
    final totalMinutes = totalSeconds ~/ 60;
    final minutes = (days > 0 || hours > 0) ? (totalMinutes % 60) : totalMinutes;
    
    if (days > 0) {
      return '$days day${days != 1 ? 's' : ''} ${hours}h';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (totalSeconds >= 60) {
      // At least 60 seconds remaining - show minutes
      return '${minutes}m';
    } else {
      // Less than 60 seconds remaining - show "Ready to open"
      return AppConstants.readyToOpenText;
    }
  }
  
  // Anonymous letter helpers
  bool get isAnonymousLetter => isAnonymous;
  
  bool get isRevealed {
    if (!isAnonymous) return false;
    if (senderRevealedAt != null) return true;
    if (revealAt != null) {
      final now = _now;
      return revealAt!.isBefore(now) || revealAt!.isAtSameMomentAs(now);
    }
    // Backward compatibility: Calculate reveal_at on the fly if missing
    // This handles existing letters opened before reveal_at was added
    if (openedAt != null && revealDelaySeconds != null) {
      final calculatedRevealAt = openedAt!.add(Duration(seconds: revealDelaySeconds!));
      final now = _now;
      return calculatedRevealAt.isBefore(now) || calculatedRevealAt.isAtSameMomentAs(now);
    }
    return false;
  }
  
  Duration get timeUntilReveal {
    if (!isAnonymous || isRevealed) {
      return Duration.zero;
    }
    
    // Use revealAt if available
    if (revealAt != null) {
      final now = _now;
      if (revealAt!.isBefore(now)) return Duration.zero;
      return revealAt!.difference(now);
    }
    
    // Backward compatibility: Calculate reveal_at on the fly if missing
    if (openedAt != null && revealDelaySeconds != null) {
      final calculatedRevealAt = openedAt!.add(Duration(seconds: revealDelaySeconds!));
      final now = _now;
      if (calculatedRevealAt.isBefore(now)) return Duration.zero;
      return calculatedRevealAt.difference(now);
    }
    
    return Duration.zero;
  }
  
  String get revealCountdownText {
    if (!isAnonymous || isRevealed) return '';
    
    // Use revealAt if available, otherwise calculate from openedAt + delay
    DateTime? effectiveRevealAt = revealAt;
    if (effectiveRevealAt == null && openedAt != null && revealDelaySeconds != null) {
      // Backward compatibility: Calculate reveal_at on the fly if missing
      effectiveRevealAt = openedAt!.add(Duration(seconds: revealDelaySeconds!));
    }
    
    if (effectiveRevealAt == null) return '';
    
    final duration = timeUntilReveal;
    if (duration.isNegative || duration.inSeconds == 0) return 'Revealing now...';
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return 'Reveals in ${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return 'Reveals in ${minutes}m ${seconds}s';
    } else {
      return 'Reveals in ${seconds}s';
    }
  }
  
  /// Get display name for sender (respects anonymous status)
  String get displaySenderName {
    if (isAnonymous && !isRevealed) {
      return 'Anonymous';
    }
    return senderName;
  }
  
  /// Get display avatar for sender (respects anonymous status)
  String get displaySenderAvatar {
    if (isAnonymous && !isRevealed) {
      return ''; // No avatar for anonymous
    }
    return senderAvatar;
  }
  
  Capsule copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? recipientId,
    String? receiverName,
    String? receiverAvatar,
    String? label,
    String? content,
    String? photoUrl,
    String? inviteUrl,
    DateTime? unlockAt,
    DateTime? createdAt,
    DateTime? openedAt,
    String? reaction,
    bool? isAnonymous,
    int? revealDelaySeconds,
    DateTime? revealAt,
    DateTime? senderRevealedAt,
    String? currentHintText,
    int? currentHintIndex,
  }) {
    return Capsule(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatarValue: senderAvatar ?? this.senderAvatar,
      recipientId: recipientId ?? this.recipientId,
      receiverName: receiverName ?? this.receiverName,
      receiverAvatarValue: receiverAvatar ?? this.receiverAvatar,
      label: label ?? this.label,
      content: content ?? this.content,
      photoUrl: photoUrl ?? this.photoUrl,
      unlockAt: unlockAt ?? this.unlockAt,
      createdAt: createdAt ?? this.createdAt,
      openedAt: openedAt ?? this.openedAt,
      reaction: reaction ?? this.reaction,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      revealDelaySeconds: revealDelaySeconds ?? this.revealDelaySeconds,
      revealAt: revealAt ?? this.revealAt,
      senderRevealedAt: senderRevealedAt ?? this.senderRevealedAt,
      currentHintText: currentHintText ?? this.currentHintText,
      currentHintIndex: currentHintIndex ?? this.currentHintIndex,
      inviteUrl: inviteUrl ?? this.inviteUrl,
    );
  }
}

/// Recipient model
class Recipient {
  final String id;
  final String userId; // Owner of this recipient
  final String name;
  final String? username; // @username for display
  final String avatar; // URL or asset path
  final String? linkedUserId; // ID of the linked user (if recipient is a registered user)
  final String? email; // Email address (used for inbox matching)
  
  Recipient({
    String? id,
    required this.userId,
    required this.name,
    String? username,
    String? avatar,
    this.linkedUserId,
    this.email,
  })  : id = id ?? _uuid.v4(),
        username = username,
        avatar = avatar ?? '';
  
  Recipient copyWith({
    String? id,
    String? userId,
    String? name,
    String? username,
    String? avatar,
    String? linkedUserId,
    String? email,
  }) {
    return Recipient(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      linkedUserId: linkedUserId ?? this.linkedUserId,
      email: email ?? this.email,
    );
  }
}

/// User model
class User {
  final String id;
  final String name;
  final String email;
  final String username; // Unique username for searching
  final String avatar;
  
  User({
    String? id,
    required this.name,
    required this.email,
    String? username,
    String? avatar,
  })  : id = id ?? _uuid.v4(),
        username = username ?? email.split('@')[0], // Default to email prefix if not provided
        avatar = avatar ?? '';
  
  String get firstName {
    final parts = name.split(' ');
    return parts.isNotEmpty ? parts[0] : name;
  }
  
  String? get avatarUrl => avatar.isNotEmpty && avatar.startsWith('http') ? avatar : null;
  
  String? get localAvatarPath => avatar.isNotEmpty && !avatar.startsWith('http') ? avatar : null;
  
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? username,
    String? avatar,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
    );
  }
}

/// Draft capsule model for multi-step creation flow
class DraftCapsule {
  final Recipient? recipient;
  final String? content;
  final String? photoPath;
  final DateTime? unlockAt;
  final String? label;
  final String? draftId; // Track the draft ID if one was created during auto-save
  
  // Anonymous letter fields
  final bool isAnonymous;
  final int? revealDelaySeconds; // Delay in seconds (0-259200, default 21600 = 6 hours)
  
  // Anonymous identity hints (optional, only for anonymous letters)
  final String? hint1;
  final String? hint2;
  final String? hint3;
  
  // Unregistered recipient fields
  final bool isUnregisteredRecipient; // True if sending to someone not on OpenOn
  final String? unregisteredRecipientName; // Name for unregistered recipient
  final String? unregisteredPhoneNumber; // Optional phone number for sharing
  
  const DraftCapsule({
    this.recipient,
    this.content,
    this.photoPath,
    this.unlockAt,
    this.label,
    this.draftId,
    this.isAnonymous = false,
    this.revealDelaySeconds,
    this.hint1,
    this.hint2,
    this.hint3,
    this.isUnregisteredRecipient = false,
    this.unregisteredRecipientName,
    this.unregisteredPhoneNumber,
  });
  
  bool get isValid {
    // For unregistered recipients, we don't need a recipient object
    if (isUnregisteredRecipient) {
      return content != null &&
          content!.trim().isNotEmpty &&
          unlockAt != null &&
          unlockAt!.isAfter(DateTime.now());
    }
    // For registered recipients, recipient is required
    return recipient != null &&
        content != null &&
        content!.trim().isNotEmpty &&
        unlockAt != null &&
        unlockAt!.isAfter(DateTime.now());
  }
  
  DraftCapsule copyWith({
    Recipient? recipient,
    String? content,
    String? photoPath,
    DateTime? unlockAt,
    String? label,
    String? draftId,
    bool clearPhoto = false,
    bool? isAnonymous,
    int? revealDelaySeconds,
    String? hint1,
    String? hint2,
    String? hint3,
    bool? isUnregisteredRecipient,
    String? unregisteredRecipientName,
    String? unregisteredPhoneNumber,
    bool clearUnregisteredPhone = false,
  }) {
    return DraftCapsule(
      recipient: recipient ?? this.recipient,
      content: content ?? this.content,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      unlockAt: unlockAt ?? this.unlockAt,
      label: label ?? this.label,
      draftId: draftId ?? this.draftId,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      revealDelaySeconds: revealDelaySeconds ?? this.revealDelaySeconds,
      hint1: hint1 ?? this.hint1,
      hint2: hint2 ?? this.hint2,
      hint3: hint3 ?? this.hint3,
      isUnregisteredRecipient: isUnregisteredRecipient != null ? isUnregisteredRecipient : this.isUnregisteredRecipient,
      unregisteredRecipientName: unregisteredRecipientName ?? this.unregisteredRecipientName,
      unregisteredPhoneNumber: clearUnregisteredPhone ? null : (unregisteredPhoneNumber ?? this.unregisteredPhoneNumber),
    );
  }
  
  Capsule toCapsule({
    required String senderId,
    required String senderName,
  }) {
    if (!isValid || content == null || unlockAt == null) {
      throw Exception('Cannot convert invalid draft to capsule');
    }
    
    // For unregistered recipients, recipientId will be set by backend
    // For registered recipients, use recipient.id
    final recipientId = isUnregisteredRecipient ? '' : (recipient?.id ?? '');
    final receiverName = isUnregisteredRecipient 
        ? (this.unregisteredRecipientName ?? 'Someone special') 
        : (recipient?.name ?? 'Recipient');
    final receiverAvatar = isUnregisteredRecipient ? '' : (recipient?.avatar ?? '');
    
    Logger.debug(
      'Converting draft to capsule: isUnregistered=$isUnregisteredRecipient, '
      'recipientId=${recipient?.id}, receiverName=$receiverName'
    );
    
    return Capsule(
      senderId: senderId,
      senderName: senderName,
      recipientId: recipientId, // Will be validated and resolved by backend
      receiverName: receiverName,
      receiverAvatarValue: receiverAvatar,
      label: label ?? 'A special letter',
      content: content!,
      photoUrl: photoPath,
      unlockAt: unlockAt!,
      isAnonymous: isAnonymous,
      revealDelaySeconds: revealDelaySeconds,
    );
  }
}

/// Draft model - represents a saved draft letter
/// 
/// Drafts are private, editable letters that haven't been sealed yet.
/// They are stored locally and remotely for crash safety.
/// 
/// Fields:
/// - id: Unique draft identifier
/// - userId: Owner of the draft
/// - title: Optional title/label for the draft
/// - body: Draft content (plain text only)
/// - recipientName: Optional recipient name (for display)
/// - recipientAvatar: Optional recipient avatar URL/path (for display)
/// - lastEdited: Last modification timestamp
/// 
/// Note: Drafts do NOT include recipient_id, unlock_at, or status.
/// These are added later when converting to a capsule.
class Draft {
  final String id;
  final String userId;
  final String? title;
  final String body;
  final String? recipientName;
  final String? recipientAvatar;
  final DateTime lastEdited;
  
  Draft({
    String? id,
    required this.userId,
    this.title,
    required this.body,
    this.recipientName,
    this.recipientAvatar,
    DateTime? lastEdited,
  })  : id = id ?? _uuid.v4(),
        lastEdited = lastEdited ?? DateTime.now();
  
  String get displayTitle => title?.trim().isNotEmpty == true 
      ? title!.trim() 
      : AppConstants.untitledDraftTitle;
  
  String get snippet {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return AppConstants.noContentText;
    if (trimmed.length <= AppConstants.draftSnippetLength) return trimmed;
    return '${trimmed.substring(0, AppConstants.draftSnippetLength)}...';
  }
  
  Draft copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? recipientName,
    String? recipientAvatar,
    DateTime? lastEdited,
  }) {
    return Draft(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      recipientName: recipientName ?? this.recipientName,
      recipientAvatar: recipientAvatar ?? this.recipientAvatar,
      lastEdited: lastEdited ?? this.lastEdited,
    );
  }
}

/// Self letter model - represents an irreversible time-locked letter to future self
class SelfLetter {
  final String id;
  final String userId;
  final String? content; // Only visible after scheduled_open_at
  final int charCount;
  final DateTime scheduledOpenAt;
  final DateTime? openedAt;
  final String? mood; // e.g. "calm", "anxious", "tired"
  final String? lifeArea; // "self" | "work" | "family" | "money" | "health"
  final String? city;
  final String? reflectionAnswer; // "yes" | "no" | "skipped"
  final DateTime? reflectedAt;
  final bool sealed; // Always true
  final DateTime createdAt;
  
  SelfLetter({
    required this.id,
    required this.userId,
    this.content,
    required this.charCount,
    required this.scheduledOpenAt,
    this.openedAt,
    this.mood,
    this.lifeArea,
    this.city,
    this.reflectionAnswer,
    this.reflectedAt,
    this.sealed = true,
    required this.createdAt,
  });
  
  /// Check if letter can be opened (scheduled time has passed, not yet opened)
  bool get canOpen {
    final now = DateTime.now();
    return scheduledOpenAt.isBefore(now) || scheduledOpenAt.isAtSameMomentAs(now);
  }
  
  /// Check if letter is openable but not yet opened
  bool get isOpenable {
    return canOpen && openedAt == null;
  }
  
  /// Check if letter has been opened
  bool get isOpened => openedAt != null;
  
  /// Check if letter is sealed (not yet openable)
  bool get isSealed {
    final now = DateTime.now();
    return scheduledOpenAt.isAfter(now);
  }
  
  /// Get time until open (or null if already openable)
  Duration? get timeUntilOpen {
    if (canOpen) return null;
    return scheduledOpenAt.difference(DateTime.now());
  }
  
  /// Get formatted time until open text
  String get timeUntilOpenText {
    if (canOpen) return 'Ready to open';
    final duration = timeUntilOpen;
    if (duration == null) return 'Ready to open';
    
    if (duration.inDays > 0) {
      return 'Opens in ${duration.inDays} ${duration.inDays == 1 ? 'day' : 'days'}';
    } else if (duration.inHours > 0) {
      return 'Opens in ${duration.inHours} ${duration.inHours == 1 ? 'hour' : 'hours'}';
    } else if (duration.inMinutes > 0) {
      return 'Opens in ${duration.inMinutes} ${duration.inMinutes == 1 ? 'minute' : 'minutes'}';
    } else {
      return 'Opens soon';
    }
  }
  
  /// Get context text for display
  String get contextText {
    final parts = <String>[];
    
    if (mood != null) {
      parts.add(mood!);
    }
    
    // Format: "Wednesday night"
    final weekday = _getWeekdayName(createdAt.weekday);
    final timeOfDay = _getTimeOfDay(createdAt.hour);
    parts.add('$weekday $timeOfDay');
    
    if (city != null) {
      parts.add('in $city');
    }
    
    if (parts.isEmpty) {
      return 'Written to future you';
    }
    
    return 'Written on a ${parts.join(' ')}';
  }
  
  String _getWeekdayName(int weekday) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekdays[weekday - 1];
  }
  
  String _getTimeOfDay(int hour) {
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }
  
  /// Check if reflection has been submitted
  bool get hasReflection => reflectionAnswer != null;
  
  /// Check if reflection can be submitted (opened but not yet reflected)
  bool get canReflect => isOpened && !hasReflection;
}

/// Letter Reply model - one-time acknowledgment reply from receiver to sender
class LetterReply {
  final String id;
  final String letterId;
  final String replyText;
  final String replyEmoji;
  final DateTime? receiverAnimationSeenAt;
  final DateTime? senderAnimationSeenAt;
  final DateTime createdAt;
  
  LetterReply({
    required this.id,
    required this.letterId,
    required this.replyText,
    required this.replyEmoji,
    this.receiverAnimationSeenAt,
    this.senderAnimationSeenAt,
    required this.createdAt,
  });
  
  /// Check if receiver has seen the animation
  bool get hasReceiverSeenAnimation => receiverAnimationSeenAt != null;
  
  /// Check if sender has seen the animation
  bool get hasSenderSeenAnimation => senderAnimationSeenAt != null;
  
  /// Allowed emoji set
  static const List<String> allowedEmojis = ['❤️', '🥹', '😊', '😎', '😢', '🤍', '🙏'];
  
  /// Validate emoji is from allowed set
  static bool isValidEmoji(String emoji) {
    return allowedEmojis.contains(emoji);
  }
  
  /// Validate reply text length
  static bool isValidReplyText(String text) {
    return text.trim().isNotEmpty && text.length <= 60;
  }
  
  factory LetterReply.fromJson(Map<String, dynamic> json) {
    return LetterReply(
      id: json['id'] as String,
      letterId: json['letter_id'] as String,
      replyText: json['reply_text'] as String,
      replyEmoji: json['reply_emoji'] as String,
      receiverAnimationSeenAt: json['receiver_animation_seen_at'] != null
          ? DateTime.parse(json['receiver_animation_seen_at'] as String)
          : null,
      senderAnimationSeenAt: json['sender_animation_seen_at'] != null
          ? DateTime.parse(json['sender_animation_seen_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'letter_id': letterId,
      'reply_text': replyText,
      'reply_emoji': replyEmoji,
      'receiver_animation_seen_at': receiverAnimationSeenAt?.toIso8601String(),
      'sender_animation_seen_at': senderAnimationSeenAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
