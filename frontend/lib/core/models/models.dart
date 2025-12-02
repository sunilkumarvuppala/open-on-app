import 'package:openon_app/core/constants/app_constants.dart';
import 'package:openon_app/core/utils/logger.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Capsule status enum
enum CapsuleStatus {
  locked,
  unlockingSoon,
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
  
  CapsuleStatus get status {
    final now = DateTime.now();
    
    if (openedAt != null) {
      return CapsuleStatus.opened;
    }
    
    if (unlockAt.isBefore(now)) {
      return CapsuleStatus.opened; // Can be opened
    }
    
    final daysUntilUnlock = unlockAt.difference(now).inDays;
    if (daysUntilUnlock <= AppConstants.unlockingSoonDaysThreshold) {
      return CapsuleStatus.unlockingSoon;
    }
    
    return CapsuleStatus.locked;
  }
  
  bool get isLocked => unlockAt.isAfter(DateTime.now()) && openedAt == null;
  
  bool get isUnlocked => unlockAt.isBefore(DateTime.now()) && openedAt == null;
  
  bool get isOpened => openedAt != null;
  
  bool get isUnlockingSoon {
    if (isOpened || isUnlocked) return false;
    final daysUntilUnlock = unlockAt.difference(DateTime.now()).inDays;
    return daysUntilUnlock <= AppConstants.unlockingSoonDaysThreshold;
  }
  
  bool get canOpen => unlockAt.isBefore(DateTime.now()) && openedAt == null;
  
  String get recipientName => receiverName;
  
  DateTime get unlockTime => unlockAt;
  
  Duration get timeUntilUnlock {
    if (!isLocked) return Duration.zero;
    return unlockAt.difference(DateTime.now());
  }
  
  String get countdownText {
    if (!isLocked) return 'Ready to open';
    
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
  
  Recipient({
    String? id,
    required this.userId,
    required this.name,
    required this.relationship,
    String? avatar,
    this.linkedUserId,
  })  : id = id ?? _uuid.v4(),
        avatar = avatar ?? '';
  
  Recipient copyWith({
    String? id,
    String? userId,
    String? name,
    String? relationship,
    String? avatar,
    String? linkedUserId,
  }) {
    return Recipient(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      avatar: avatar ?? this.avatar,
      linkedUserId: linkedUserId ?? this.linkedUserId,
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
  
  const DraftCapsule({
    this.recipient,
    this.content,
    this.photoPath,
    this.unlockAt,
    this.label,
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
    bool clearPhoto = false,
  }) {
    return DraftCapsule(
      recipient: recipient ?? this.recipient,
      content: content ?? this.content,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      unlockAt: unlockAt ?? this.unlockAt,
      label: label ?? this.label,
    );
  }
  
  Capsule toCapsule({
    required String senderId,
    required String senderName,
  }) {
    if (!isValid || recipient == null || content == null || unlockAt == null) {
      throw Exception('Cannot convert invalid draft to capsule');
    }
    
    // Recipient must be linked to a registered user to receive capsules
    if (recipient!.linkedUserId == null || recipient!.linkedUserId!.isEmpty) {
      throw Exception(
        'Recipient "${recipient!.name}" is not linked to a registered user. '
        'Please select a recipient that is linked to a user account.'
      );
    }
    
    // Use linkedUserId (the actual user ID) as receiver_id
    final receiverId = recipient!.linkedUserId!;
    
    // Log for debugging
    Logger.info(
      'Creating capsule: recipient.id=${recipient!.id}, '
      'recipient.linkedUserId=${recipient!.linkedUserId}, '
      'receiverId=$receiverId'
    );
    
    return Capsule(
      senderId: senderId,
      senderName: senderName,
      receiverId: receiverId,
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
class Draft {
  final String id;
  final String? title;
  final String body;
  final DateTime lastEdited;
  
  Draft({
    String? id,
    this.title,
    required this.body,
    DateTime? lastEdited,
  })  : id = id ?? _uuid.v4(),
        lastEdited = lastEdited ?? DateTime.now();
  
  String get displayTitle =>
      title?.trim().isEmpty ?? true
          ? AppConstants.untitledDraftTitle
          : title!;
  
  String get snippet {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return AppConstants.noContentText;
    if (trimmed.length <= AppConstants.draftSnippetLength) return trimmed;
    return '${trimmed.substring(0, AppConstants.draftSnippetLength)}...';
  }
  
  Draft copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? lastEdited,
  }) {
    return Draft(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      lastEdited: lastEdited ?? this.lastEdited,
    );
  }
}
