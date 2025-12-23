// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'thought_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ThoughtImpl _$$ThoughtImplFromJson(Map<String, dynamic> json) =>
    _$ThoughtImpl(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      displayDate: DateTime.parse(json['displayDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      senderName: json['senderName'] as String?,
      senderAvatarUrl: json['senderAvatarUrl'] as String?,
      senderUsername: json['senderUsername'] as String?,
      receiverName: json['receiverName'] as String?,
      receiverAvatarUrl: json['receiverAvatarUrl'] as String?,
      receiverUsername: json['receiverUsername'] as String?,
    );

Map<String, dynamic> _$$ThoughtImplToJson(_$ThoughtImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'senderId': instance.senderId,
      'receiverId': instance.receiverId,
      'displayDate': instance.displayDate.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'senderName': instance.senderName,
      'senderAvatarUrl': instance.senderAvatarUrl,
      'senderUsername': instance.senderUsername,
      'receiverName': instance.receiverName,
      'receiverAvatarUrl': instance.receiverAvatarUrl,
      'receiverUsername': instance.receiverUsername,
    };

_$SendThoughtResultImpl _$$SendThoughtResultImplFromJson(
        Map<String, dynamic> json) =>
    _$SendThoughtResultImpl(
      success: json['success'] as bool,
      thoughtId: json['thoughtId'] as String?,
      errorCode: json['errorCode'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );

Map<String, dynamic> _$$SendThoughtResultImplToJson(
        _$SendThoughtResultImpl instance) =>
    <String, dynamic>{
      'success': instance.success,
      'thoughtId': instance.thoughtId,
      'errorCode': instance.errorCode,
      'errorMessage': instance.errorMessage,
    };
