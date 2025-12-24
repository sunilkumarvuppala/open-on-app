import 'package:openon_app/core/constants/app_constants.dart';

/// Countdown share models
/// 
/// Models for the Share Countdown feature that allows recipients to share
/// anticipation of upcoming time-locked letters without revealing content.
/// 
/// ANONYMOUS BY DEFAULT: Share Countdown must be anonymous by default.
/// Shared content MUST NOT expose sender identity unless explicitly enabled
/// by the user (future toggle: show_sender_identity = false by default).

/// Future-proof flag: Show sender identity in shares (disabled by default)
/// DO NOT expose this in UI yet - for future experimentation only
const bool showSenderIdentityInShares = false;

/// Share type enum
enum ShareType {
  story, // Instagram Stories
  video, // TikTok
  static, // Static image
  link, // URL only
}

/// Countdown share model
class CountdownShare {
  final String id;
  final String letterId;
  final String ownerUserId;
  final String shareToken;
  final ShareType shareType;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? revokedAt;
  final DateTime openAt;
  final Map<String, dynamic>? metadata;

  CountdownShare({
    required this.id,
    required this.letterId,
    required this.ownerUserId,
    required this.shareToken,
    required this.shareType,
    required this.createdAt,
    this.expiresAt,
    this.revokedAt,
    required this.openAt,
    this.metadata,
  });

  bool get isRevoked => revokedAt != null;
  bool get isExpired {
    if (expiresAt == null) return false;
    return expiresAt!.isBefore(DateTime.now());
  }
  bool get isValid => !isRevoked && !isExpired;

  /// Share URL for public access
  String get shareUrl {
    // Use configuration constant (can be overridden via environment variable)
    final baseUrl = AppConstants.shareBaseUrl;
    return '$baseUrl/$shareToken';
  }

  factory CountdownShare.fromJson(Map<String, dynamic> json) {
    return CountdownShare(
      id: json['id'] as String,
      letterId: json['letter_id'] as String,
      ownerUserId: json['owner_user_id'] as String,
      shareToken: json['share_token'] as String,
      shareType: _shareTypeFromString(json['share_type'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      revokedAt: json['revoked_at'] != null
          ? DateTime.parse(json['revoked_at'] as String)
          : null,
      openAt: DateTime.parse(json['open_at'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'letter_id': letterId,
      'owner_user_id': ownerUserId,
      'share_token': shareToken,
      'share_type': _shareTypeToString(shareType),
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'revoked_at': revokedAt?.toIso8601String(),
      'open_at': openAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  static ShareType _shareTypeFromString(String value) {
    switch (value) {
      case 'story':
        return ShareType.story;
      case 'video':
        return ShareType.video;
      case 'static':
        return ShareType.static;
      case 'link':
        return ShareType.link;
      default:
        return ShareType.link;
    }
  }

  static String _shareTypeToString(ShareType type) {
    switch (type) {
      case ShareType.story:
        return 'story';
      case ShareType.video:
        return 'video';
      case ShareType.static:
        return 'static';
      case ShareType.link:
        return 'link';
    }
  }
}

/// Create share request
class CreateShareRequest {
  final String letterId;
  final ShareType shareType;
  final DateTime? expiresAt;

  CreateShareRequest({
    required this.letterId,
    required this.shareType,
    this.expiresAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'letter_id': letterId,
      'share_type': CountdownShare._shareTypeToString(shareType),
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
    };
  }
}

/// Create share result
class CreateShareResult {
  final bool success;
  final String? shareId;
  final String? shareToken;
  final String? shareUrl;
  final String? assetUrl;
  final DateTime? expiresAt;
  final String? errorCode;
  final String? errorMessage;

  CreateShareResult({
    required this.success,
    this.shareId,
    this.shareToken,
    this.shareUrl,
    this.assetUrl,
    this.expiresAt,
    this.errorCode,
    this.errorMessage,
  });

  factory CreateShareResult.fromJson(Map<String, dynamic> json) {
    return CreateShareResult(
      success: json['success'] as bool,
      shareId: json['share_id'] as String?,
      shareToken: json['share_token'] as String?,
      shareUrl: json['share_url'] as String?,
      assetUrl: json['asset_url'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      errorCode: json['error_code'] as String?,
      errorMessage: json['error_message'] as String?,
    );
  }
}

/// Revoke share result
class RevokeShareResult {
  final bool success;
  final String? message;
  final String? errorCode;
  final String? errorMessage;

  RevokeShareResult({
    required this.success,
    this.message,
    this.errorCode,
    this.errorMessage,
  });

  factory RevokeShareResult.fromJson(Map<String, dynamic> json) {
    return RevokeShareResult(
      success: json['success'] as bool,
      message: json['message'] as String?,
      errorCode: json['error_code'] as String?,
      errorMessage: json['error_message'] as String?,
    );
  }
}

/// Share error codes
enum ShareErrorCode {
  letterNotFound,
  letterNotLocked,
  letterAlreadyOpened,
  letterDeleted,
  notAuthorized,
  dailyLimitReached,
  invalidShareType,
  shareNotFound,
  shareRevoked,
  shareExpired,
  notAuthenticated,
  unexpectedError,
}

extension ShareErrorCodeExtension on ShareErrorCode {
  String get code {
    switch (this) {
      case ShareErrorCode.letterNotFound:
        return 'LETTER_NOT_FOUND';
      case ShareErrorCode.letterNotLocked:
        return 'LETTER_NOT_LOCKED';
      case ShareErrorCode.letterAlreadyOpened:
        return 'LETTER_ALREADY_OPENED';
      case ShareErrorCode.letterDeleted:
        return 'LETTER_DELETED';
      case ShareErrorCode.notAuthorized:
        return 'NOT_AUTHORIZED';
      case ShareErrorCode.dailyLimitReached:
        return 'DAILY_LIMIT_REACHED';
      case ShareErrorCode.invalidShareType:
        return 'INVALID_SHARE_TYPE';
      case ShareErrorCode.shareNotFound:
        return 'SHARE_NOT_FOUND';
      case ShareErrorCode.shareRevoked:
        return 'SHARE_REVOKED';
      case ShareErrorCode.shareExpired:
        return 'SHARE_EXPIRED';
      case ShareErrorCode.notAuthenticated:
        return 'NOT_AUTHENTICATED';
      case ShareErrorCode.unexpectedError:
        return 'UNEXPECTED_ERROR';
    }
  }

  static ShareErrorCode? fromString(String code) {
    switch (code) {
      case 'LETTER_NOT_FOUND':
        return ShareErrorCode.letterNotFound;
      case 'LETTER_NOT_LOCKED':
        return ShareErrorCode.letterNotLocked;
      case 'LETTER_ALREADY_OPENED':
        return ShareErrorCode.letterAlreadyOpened;
      case 'LETTER_DELETED':
        return ShareErrorCode.letterDeleted;
      case 'NOT_AUTHORIZED':
        return ShareErrorCode.notAuthorized;
      case 'DAILY_LIMIT_REACHED':
        return ShareErrorCode.dailyLimitReached;
      case 'INVALID_SHARE_TYPE':
        return ShareErrorCode.invalidShareType;
      case 'SHARE_NOT_FOUND':
        return ShareErrorCode.shareNotFound;
      case 'SHARE_REVOKED':
        return ShareErrorCode.shareRevoked;
      case 'SHARE_EXPIRED':
        return ShareErrorCode.shareExpired;
      case 'NOT_AUTHENTICATED':
        return ShareErrorCode.notAuthenticated;
      case 'UNEXPECTED_ERROR':
        return ShareErrorCode.unexpectedError;
      default:
        return null;
    }
  }
}

