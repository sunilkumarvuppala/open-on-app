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
}

/// Capsule model - represents a time-locked letter
class Capsule {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final String receiverAvatar;
  final String label; // e.g., "Open on your birthday"
  final String content;
  final String? photoUrl;
  final DateTime unlockAt;
  final DateTime createdAt;
  final DateTime? openedAt;
  final String? reaction; // Emoji reaction from receiver
  
  Capsule({
    String? id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.receiverAvatar,
    required this.label,
    required this.content,
    this.photoUrl,
    required this.unlockAt,
    DateTime? createdAt,
    this.openedAt,
    this.reaction,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();
  
  /// Get current time (cached per status calculation to avoid multiple calls)
  DateTime get _now => DateTime.now();
  
  CapsuleStatus get status {
    final now = _now;
    
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
  
  DateTime get unlockTime => unlockAt;
  
  Duration get timeUntilUnlock {
    if (!isLocked) return Duration.zero;
    final now = _now;
    return unlockAt.difference(now);
  }
  
  String get countdownText {
    if (!isLocked) return AppConstants.readyToOpenText;
    
    final duration = timeUntilUnlock;
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    
    if (days > 0) {
      return '$days day${days != 1 ? 's' : ''} ${hours}h';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
  
  Capsule copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? receiverId,
    String? receiverName,
    String? receiverAvatar,
    String? label,
    String? content,
    String? photoUrl,
    DateTime? unlockAt,
    DateTime? createdAt,
    DateTime? openedAt,
    String? reaction,
  }) {
    return Capsule(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      receiverAvatar: receiverAvatar ?? this.receiverAvatar,
      label: label ?? this.label,
      content: content ?? this.content,
      photoUrl: photoUrl ?? this.photoUrl,
      unlockAt: unlockAt ?? this.unlockAt,
      createdAt: createdAt ?? this.createdAt,
      openedAt: openedAt ?? this.openedAt,
      reaction: reaction ?? this.reaction,
    );
  }
}

/// Recipient model
class Recipient {
  final String id;
  final String userId; // Owner of this recipient
  final String name;
  final String relationship;
  final String avatar; // URL or asset path
  final String? linkedUserId; // ID of the linked user (if recipient is a registered user)
  final String? email; // Email address (used for inbox matching)
  
  Recipient({
    String? id,
    required this.userId,
    required this.name,
    required this.relationship,
    String? avatar,
    this.linkedUserId,
    this.email,
  })  : id = id ?? _uuid.v4(),
        avatar = avatar ?? '';
  
  Recipient copyWith({
    String? id,
    String? userId,
    String? name,
    String? relationship,
    String? avatar,
    String? linkedUserId,
    String? email,
  }) {
    return Recipient(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
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
  
  const DraftCapsule({
    this.recipient,
    this.content,
    this.photoPath,
    this.unlockAt,
    this.label,
    this.draftId,
  });
  
  bool get isValid {
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
  }) {
    return DraftCapsule(
      recipient: recipient ?? this.recipient,
      content: content ?? this.content,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      unlockAt: unlockAt ?? this.unlockAt,
      label: label ?? this.label,
      draftId: draftId ?? this.draftId,
    );
  }
  
  Capsule toCapsule({
    required String senderId,
    required String senderName,
  }) {
    if (!isValid || recipient == null || content == null || unlockAt == null) {
      throw Exception('Cannot convert invalid draft to capsule');
    }
    
    // Use recipient.id as receiver_id (backend expects recipient_id UUID)
    // In Supabase schema, recipient_id is the UUID of the recipient record
    final receiverId = recipient!.id;
    
    // Log for debugging
    Logger.info(
      'Creating capsule: recipient.id=${recipient!.id}, '
      'recipient.name=${recipient!.name}, '
      'receiverId=$receiverId'
    );
    
    return Capsule(
      senderId: senderId,
      senderName: senderName,
      receiverId: receiverId, // Use recipient.id (UUID) as recipient_id
      receiverName: recipient!.name,
      receiverAvatar: recipient!.avatar,
      label: label ?? 'A special letter',
      content: content!,
      photoUrl: photoPath,
      unlockAt: unlockAt!,
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
