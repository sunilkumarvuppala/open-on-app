// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supabase_types.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserProfileImpl _$$UserProfileImplFromJson(Map<String, dynamic> json) =>
    _$UserProfileImpl(
      userId: json['userId'] as String,
      fullName: json['fullName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      premiumStatus: json['premiumStatus'] as bool? ?? false,
      premiumUntil: json['premiumUntil'] == null
          ? null
          : DateTime.parse(json['premiumUntil'] as String),
      country: json['country'] as String?,
      deviceToken: json['deviceToken'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$UserProfileImplToJson(_$UserProfileImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'fullName': instance.fullName,
      'avatarUrl': instance.avatarUrl,
      'premiumStatus': instance.premiumStatus,
      'premiumUntil': instance.premiumUntil?.toIso8601String(),
      'country': instance.country,
      'deviceToken': instance.deviceToken,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

_$RecipientImpl _$$RecipientImplFromJson(Map<String, dynamic> json) =>
    _$RecipientImpl(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$RecipientImplToJson(_$RecipientImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ownerId': instance.ownerId,
      'name': instance.name,
      'email': instance.email,
      'avatarUrl': instance.avatarUrl,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

_$ThemeImpl _$$ThemeImplFromJson(Map<String, dynamic> json) => _$ThemeImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      gradientStart: json['gradientStart'] as String,
      gradientEnd: json['gradientEnd'] as String,
      previewUrl: json['previewUrl'] as String?,
      premiumOnly: json['premiumOnly'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$ThemeImplToJson(_$ThemeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'gradientStart': instance.gradientStart,
      'gradientEnd': instance.gradientEnd,
      'previewUrl': instance.previewUrl,
      'premiumOnly': instance.premiumOnly,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

_$AnimationImpl _$$AnimationImplFromJson(Map<String, dynamic> json) =>
    _$AnimationImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      previewUrl: json['previewUrl'] as String?,
      premiumOnly: json['premiumOnly'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$AnimationImplToJson(_$AnimationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'previewUrl': instance.previewUrl,
      'premiumOnly': instance.premiumOnly,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

_$CapsuleImpl _$$CapsuleImplFromJson(Map<String, dynamic> json) =>
    _$CapsuleImpl(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String?,
      senderAvatarUrl: json['senderAvatarUrl'] as String?,
      recipientId: json['recipientId'] as String,
      recipientName: json['recipientName'] as String?,
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      isDisappearing: json['isDisappearing'] as bool? ?? false,
      disappearingAfterOpenSeconds:
          (json['disappearingAfterOpenSeconds'] as num?)?.toInt(),
      unlocksAt: DateTime.parse(json['unlocksAt'] as String),
      openedAt: json['openedAt'] == null
          ? null
          : DateTime.parse(json['openedAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      title: json['title'] as String?,
      bodyText: json['bodyText'] as String?,
      bodyRichText: json['bodyRichText'] as Map<String, dynamic>?,
      themeId: json['themeId'] as String?,
      animationId: json['animationId'] as String?,
      status: $enumDecodeNullable(_$CapsuleStatusEnumMap, json['status']) ??
          CapsuleStatus.sealed,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$CapsuleImplToJson(_$CapsuleImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'senderId': instance.senderId,
      'senderName': instance.senderName,
      'senderAvatarUrl': instance.senderAvatarUrl,
      'recipientId': instance.recipientId,
      'recipientName': instance.recipientName,
      'isAnonymous': instance.isAnonymous,
      'isDisappearing': instance.isDisappearing,
      'disappearingAfterOpenSeconds': instance.disappearingAfterOpenSeconds,
      'unlocksAt': instance.unlocksAt.toIso8601String(),
      'openedAt': instance.openedAt?.toIso8601String(),
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'title': instance.title,
      'bodyText': instance.bodyText,
      'bodyRichText': instance.bodyRichText,
      'themeId': instance.themeId,
      'animationId': instance.animationId,
      'status': _$CapsuleStatusEnumMap[instance.status]!,
      'deletedAt': instance.deletedAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$CapsuleStatusEnumMap = {
  CapsuleStatus.sealed: 'sealed',
  CapsuleStatus.ready: 'ready',
  CapsuleStatus.opened: 'opened',
  CapsuleStatus.expired: 'expired',
};

_$NotificationImpl _$$NotificationImplFromJson(Map<String, dynamic> json) =>
    _$NotificationImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: $enumDecode(_$NotificationTypeEnumMap, json['type']),
      capsuleId: json['capsuleId'] as String?,
      title: json['title'] as String,
      body: json['body'] as String,
      delivered: json['delivered'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$NotificationImplToJson(_$NotificationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'type': _$NotificationTypeEnumMap[instance.type]!,
      'capsuleId': instance.capsuleId,
      'title': instance.title,
      'body': instance.body,
      'delivered': instance.delivered,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$NotificationTypeEnumMap = {
  NotificationType.unlockSoon: 'unlock_soon',
  NotificationType.unlocked: 'unlocked',
  NotificationType.newCapsule: 'new_capsule',
  NotificationType.disappearingWarning: 'disappearing_warning',
  NotificationType.subscriptionExpiring: 'subscription_expiring',
  NotificationType.subscriptionExpired: 'subscription_expired',
};

_$UserSubscriptionImpl _$$UserSubscriptionImplFromJson(
        Map<String, dynamic> json) =>
    _$UserSubscriptionImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      status: $enumDecode(_$SubscriptionStatusEnumMap, json['status']),
      provider: json['provider'] as String? ?? 'stripe',
      planId: json['planId'] as String,
      stripeSubscriptionId: json['stripeSubscriptionId'] as String?,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endsAt: DateTime.parse(json['endsAt'] as String),
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$UserSubscriptionImplToJson(
        _$UserSubscriptionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'status': _$SubscriptionStatusEnumMap[instance.status]!,
      'provider': instance.provider,
      'planId': instance.planId,
      'stripeSubscriptionId': instance.stripeSubscriptionId,
      'startedAt': instance.startedAt.toIso8601String(),
      'endsAt': instance.endsAt.toIso8601String(),
      'cancelAtPeriodEnd': instance.cancelAtPeriodEnd,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$SubscriptionStatusEnumMap = {
  SubscriptionStatus.active: 'active',
  SubscriptionStatus.canceled: 'canceled',
  SubscriptionStatus.pastDue: 'past_due',
  SubscriptionStatus.trialing: 'trialing',
  SubscriptionStatus.incomplete: 'incomplete',
  SubscriptionStatus.incompleteExpired: 'incomplete_expired',
};

_$AuditLogImpl _$$AuditLogImplFromJson(Map<String, dynamic> json) =>
    _$AuditLogImpl(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      action: json['action'] as String,
      capsuleId: json['capsuleId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$AuditLogImplToJson(_$AuditLogImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'action': instance.action,
      'capsuleId': instance.capsuleId,
      'metadata': instance.metadata,
      'createdAt': instance.createdAt.toIso8601String(),
    };

_$CreateCapsuleRequestImpl _$$CreateCapsuleRequestImplFromJson(
        Map<String, dynamic> json) =>
    _$CreateCapsuleRequestImpl(
      recipientId: json['recipientId'] as String,
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      isDisappearing: json['isDisappearing'] as bool? ?? false,
      disappearingAfterOpenSeconds:
          (json['disappearingAfterOpenSeconds'] as num?)?.toInt(),
      unlocksAt: DateTime.parse(json['unlocksAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      title: json['title'] as String?,
      bodyText: json['bodyText'] as String?,
      bodyRichText: json['bodyRichText'] as Map<String, dynamic>?,
      themeId: json['themeId'] as String?,
      animationId: json['animationId'] as String?,
    );

Map<String, dynamic> _$$CreateCapsuleRequestImplToJson(
        _$CreateCapsuleRequestImpl instance) =>
    <String, dynamic>{
      'recipientId': instance.recipientId,
      'isAnonymous': instance.isAnonymous,
      'isDisappearing': instance.isDisappearing,
      'disappearingAfterOpenSeconds': instance.disappearingAfterOpenSeconds,
      'unlocksAt': instance.unlocksAt.toIso8601String(),
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'title': instance.title,
      'bodyText': instance.bodyText,
      'bodyRichText': instance.bodyRichText,
      'themeId': instance.themeId,
      'animationId': instance.animationId,
    };

_$UpdateCapsuleRequestImpl _$$UpdateCapsuleRequestImplFromJson(
        Map<String, dynamic> json) =>
    _$UpdateCapsuleRequestImpl(
      title: json['title'] as String?,
      bodyText: json['bodyText'] as String?,
      bodyRichText: json['bodyRichText'] as Map<String, dynamic>?,
      themeId: json['themeId'] as String?,
      animationId: json['animationId'] as String?,
    );

Map<String, dynamic> _$$UpdateCapsuleRequestImplToJson(
        _$UpdateCapsuleRequestImpl instance) =>
    <String, dynamic>{
      'title': instance.title,
      'bodyText': instance.bodyText,
      'bodyRichText': instance.bodyRichText,
      'themeId': instance.themeId,
      'animationId': instance.animationId,
    };

_$CreateRecipientRequestImpl _$$CreateRecipientRequestImplFromJson(
        Map<String, dynamic> json) =>
    _$CreateRecipientRequestImpl(
      name: json['name'] as String,
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$$CreateRecipientRequestImplToJson(
        _$CreateRecipientRequestImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'avatarUrl': instance.avatarUrl,
    };

_$UpdateUserProfileRequestImpl _$$UpdateUserProfileRequestImplFromJson(
        Map<String, dynamic> json) =>
    _$UpdateUserProfileRequestImpl(
      fullName: json['fullName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      country: json['country'] as String?,
      deviceToken: json['deviceToken'] as String?,
    );

Map<String, dynamic> _$$UpdateUserProfileRequestImplToJson(
        _$UpdateUserProfileRequestImpl instance) =>
    <String, dynamic>{
      'fullName': instance.fullName,
      'avatarUrl': instance.avatarUrl,
      'country': instance.country,
      'deviceToken': instance.deviceToken,
    };
