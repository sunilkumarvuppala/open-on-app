// ============================================================================
// OpenOn Type Definitions for Flutter
// Generated types matching Supabase schema
// ============================================================================

import 'package:freezed_annotation/freezed_annotation.dart';

part 'supabase_types.freezed.dart';
part 'supabase_types.g.dart';

// ============================================================================
// ENUMS
// ============================================================================

enum CapsuleStatus {
  @JsonValue('sealed')
  sealed,
  @JsonValue('ready')
  ready,
  @JsonValue('opened')
  opened,
  @JsonValue('expired')
  expired,
}

enum NotificationType {
  @JsonValue('unlock_soon')
  unlockSoon,
  @JsonValue('unlocked')
  unlocked,
  @JsonValue('new_capsule')
  newCapsule,
  @JsonValue('disappearing_warning')
  disappearingWarning,
  @JsonValue('subscription_expiring')
  subscriptionExpiring,
  @JsonValue('subscription_expired')
  subscriptionExpired,
}

enum SubscriptionStatus {
  @JsonValue('active')
  active,
  @JsonValue('canceled')
  canceled,
  @JsonValue('past_due')
  pastDue,
  @JsonValue('trialing')
  trialing,
  @JsonValue('incomplete')
  incomplete,
  @JsonValue('incomplete_expired')
  incompleteExpired,
}

// ============================================================================
// MODELS
// ============================================================================

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String userId,
    String? fullName,
    String? avatarUrl,
    @Default(false) bool premiumStatus,
    DateTime? premiumUntil,
    String? country,
    String? deviceToken,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}

@freezed
class Recipient with _$Recipient {
  const factory Recipient({
    required String id,
    required String ownerId,
    required String name,
    String? email,
    String? avatarUrl,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Recipient;

  factory Recipient.fromJson(Map<String, dynamic> json) =>
      _$RecipientFromJson(json);
}

@freezed
class Theme with _$Theme {
  const factory Theme({
    required String id,
    required String name,
    String? description,
    required String gradientStart,
    required String gradientEnd,
    String? previewUrl,
    @Default(false) bool premiumOnly,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Theme;

  factory Theme.fromJson(Map<String, dynamic> json) => _$ThemeFromJson(json);
}

@freezed
class Animation with _$Animation {
  const factory Animation({
    required String id,
    required String name,
    String? description,
    String? previewUrl,
    @Default(false) bool premiumOnly,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Animation;

  factory Animation.fromJson(Map<String, dynamic> json) =>
      _$AnimationFromJson(json);
}

@freezed
class Capsule with _$Capsule {
  const factory Capsule({
    required String id,
    required String senderId,
    String? senderName,
    String? senderAvatarUrl,
    required String recipientId,
    String? recipientName,
    @Default(false) bool isAnonymous,
    @Default(false) bool isDisappearing,
    int? disappearingAfterOpenSeconds,
    required DateTime unlocksAt,
    DateTime? openedAt,
    DateTime? expiresAt,
    String? title,
    String? bodyText,
    Map<String, dynamic>? bodyRichText,
    String? themeId,
    String? animationId,
    @Default(CapsuleStatus.sealed) CapsuleStatus status,
    DateTime? deletedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Capsule;

  factory Capsule.fromJson(Map<String, dynamic> json) =>
      _$CapsuleFromJson(json);
}

@freezed
class Notification with _$Notification {
  const factory Notification({
    required String id,
    required String userId,
    required NotificationType type,
    String? capsuleId,
    required String title,
    required String body,
    @Default(false) bool delivered,
    required DateTime createdAt,
  }) = _Notification;

  factory Notification.fromJson(Map<String, dynamic> json) =>
      _$NotificationFromJson(json);
}

@freezed
class UserSubscription with _$UserSubscription {
  const factory UserSubscription({
    required String id,
    required String userId,
    required SubscriptionStatus status,
    @Default('stripe') String provider,
    required String planId,
    String? stripeSubscriptionId,
    required DateTime startedAt,
    required DateTime endsAt,
    @Default(false) bool cancelAtPeriodEnd,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UserSubscription;

  factory UserSubscription.fromJson(Map<String, dynamic> json) =>
      _$UserSubscriptionFromJson(json);
}

@freezed
class AuditLog with _$AuditLog {
  const factory AuditLog({
    required String id,
    String? userId,
    required String action,
    String? capsuleId,
    Map<String, dynamic>? metadata,
    required DateTime createdAt,
  }) = _AuditLog;

  factory AuditLog.fromJson(Map<String, dynamic> json) =>
      _$AuditLogFromJson(json);
}

// ============================================================================
// REQUEST/RESPONSE MODELS
// ============================================================================

@freezed
class CreateCapsuleRequest with _$CreateCapsuleRequest {
  const factory CreateCapsuleRequest({
    required String recipientId,
    @Default(false) bool isAnonymous,
    @Default(false) bool isDisappearing,
    int? disappearingAfterOpenSeconds,
    required DateTime unlocksAt,
    DateTime? expiresAt,
    String? title,
    String? bodyText,
    Map<String, dynamic>? bodyRichText,
    String? themeId,
    String? animationId,
  }) = _CreateCapsuleRequest;

  factory CreateCapsuleRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateCapsuleRequestFromJson(json);
}

@freezed
class UpdateCapsuleRequest with _$UpdateCapsuleRequest {
  const factory UpdateCapsuleRequest({
    String? title,
    String? bodyText,
    Map<String, dynamic>? bodyRichText,
    String? themeId,
    String? animationId,
  }) = _UpdateCapsuleRequest;

  factory UpdateCapsuleRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateCapsuleRequestFromJson(json);
}

@freezed
class CreateRecipientRequest with _$CreateRecipientRequest {
  const factory CreateRecipientRequest({
    required String name,
    String? email,
    String? avatarUrl,
  }) = _CreateRecipientRequest;

  factory CreateRecipientRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateRecipientRequestFromJson(json);
}

@freezed
class UpdateUserProfileRequest with _$UpdateUserProfileRequest {
  const factory UpdateUserProfileRequest({
    String? fullName,
    String? avatarUrl,
    String? country,
    String? deviceToken,
  }) = _UpdateUserProfileRequest;

  factory UpdateUserProfileRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateUserProfileRequestFromJson(json);
}

// ============================================================================
// HELPER EXTENSIONS
// ============================================================================

extension CapsuleStatusExtension on CapsuleStatus {
  String get displayName {
    switch (this) {
      case CapsuleStatus.sealed:
        return 'Sealed';
      case CapsuleStatus.ready:
        return 'Ready';
      case CapsuleStatus.opened:
        return 'Opened';
      case CapsuleStatus.expired:
        return 'Expired';
    }
  }
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.unlockSoon:
        return 'Unlocking Soon';
      case NotificationType.unlocked:
        return 'Unlocked';
      case NotificationType.newCapsule:
        return 'New Letter';
      case NotificationType.disappearingWarning:
        return 'Disappearing Soon';
      case NotificationType.subscriptionExpiring:
        return 'Subscription Expiring';
      case NotificationType.subscriptionExpired:
        return 'Subscription Expired';
    }
  }
}

