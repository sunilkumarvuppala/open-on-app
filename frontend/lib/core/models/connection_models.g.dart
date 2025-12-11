// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ConnectionUserProfileImpl _$$ConnectionUserProfileImplFromJson(
        Map<String, dynamic> json) =>
    _$ConnectionUserProfileImpl(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      username: json['username'] as String?,
    );

Map<String, dynamic> _$$ConnectionUserProfileImplToJson(
        _$ConnectionUserProfileImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
      'username': instance.username,
    };

_$ConnectionRequestImpl _$$ConnectionRequestImplFromJson(
        Map<String, dynamic> json) =>
    _$ConnectionRequestImpl(
      id: json['id'] as String,
      fromUserId: json['fromUserId'] as String,
      toUserId: json['toUserId'] as String,
      status: $enumDecodeNullable(
              _$ConnectionRequestStatusEnumMap, json['status']) ??
          ConnectionRequestStatus.pending,
      message: json['message'] as String?,
      declinedReason: json['declinedReason'] as String?,
      actedAt: json['actedAt'] == null
          ? null
          : DateTime.parse(json['actedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      fromUserProfile: json['fromUserProfile'] == null
          ? null
          : ConnectionUserProfile.fromJson(
              json['fromUserProfile'] as Map<String, dynamic>),
      toUserProfile: json['toUserProfile'] == null
          ? null
          : ConnectionUserProfile.fromJson(
              json['toUserProfile'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ConnectionRequestImplToJson(
        _$ConnectionRequestImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fromUserId': instance.fromUserId,
      'toUserId': instance.toUserId,
      'status': _$ConnectionRequestStatusEnumMap[instance.status]!,
      'message': instance.message,
      'declinedReason': instance.declinedReason,
      'actedAt': instance.actedAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'fromUserProfile': instance.fromUserProfile,
      'toUserProfile': instance.toUserProfile,
    };

const _$ConnectionRequestStatusEnumMap = {
  ConnectionRequestStatus.pending: 'pending',
  ConnectionRequestStatus.accepted: 'accepted',
  ConnectionRequestStatus.declined: 'declined',
};

_$ConnectionImpl _$$ConnectionImplFromJson(Map<String, dynamic> json) =>
    _$ConnectionImpl(
      userId1: json['userId1'] as String,
      userId2: json['userId2'] as String,
      connectedAt: DateTime.parse(json['connectedAt'] as String),
      otherUserId: json['otherUserId'] as String,
      otherUserProfile: ConnectionUserProfile.fromJson(
          json['otherUserProfile'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ConnectionImplToJson(_$ConnectionImpl instance) =>
    <String, dynamic>{
      'userId1': instance.userId1,
      'userId2': instance.userId2,
      'connectedAt': instance.connectedAt.toIso8601String(),
      'otherUserId': instance.otherUserId,
      'otherUserProfile': instance.otherUserProfile,
    };

_$PendingRequestsImpl _$$PendingRequestsImplFromJson(
        Map<String, dynamic> json) =>
    _$PendingRequestsImpl(
      incoming: (json['incoming'] as List<dynamic>?)
              ?.map(
                  (e) => ConnectionRequest.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      outgoing: (json['outgoing'] as List<dynamic>?)
              ?.map(
                  (e) => ConnectionRequest.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$PendingRequestsImplToJson(
        _$PendingRequestsImpl instance) =>
    <String, dynamic>{
      'incoming': instance.incoming,
      'outgoing': instance.outgoing,
    };
