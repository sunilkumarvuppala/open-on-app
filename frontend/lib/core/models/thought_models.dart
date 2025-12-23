import 'package:freezed_annotation/freezed_annotation.dart';

part 'thought_models.freezed.dart';
part 'thought_models.g.dart';

/// Thought model - represents a gentle presence signal
@freezed
class Thought with _$Thought {
  const factory Thought({
    required String id,
    required String senderId,
    required String receiverId,
    required DateTime displayDate, // Only date, not exact time
    required DateTime createdAt, // For internal sorting only
    String? senderName,
    String? senderAvatarUrl,
    String? senderUsername,
    String? receiverName,
    String? receiverAvatarUrl,
    String? receiverUsername,
  }) = _Thought;

  factory Thought.fromJson(Map<String, dynamic> json) =>
      _$ThoughtFromJson(json);
}

/// Send thought result
@freezed
class SendThoughtResult with _$SendThoughtResult {
  const factory SendThoughtResult({
    required bool success,
    String? thoughtId,
    String? errorCode,
    String? errorMessage,
  }) = _SendThoughtResult;

  factory SendThoughtResult.fromJson(Map<String, dynamic> json) =>
      _$SendThoughtResultFromJson(json);
}

/// Thought error codes
enum ThoughtErrorCode {
  @JsonValue('THOUGHT_ALREADY_SENT_TODAY')
  thoughtAlreadySentToday,
  @JsonValue('DAILY_LIMIT_REACHED')
  dailyLimitReached,
  @JsonValue('NOT_CONNECTED')
  notConnected,
  @JsonValue('BLOCKED')
  blocked,
  @JsonValue('INVALID_RECEIVER')
  invalidReceiver,
  @JsonValue('NOT_AUTHENTICATED')
  notAuthenticated,
  @JsonValue('UNEXPECTED_ERROR')
  unexpectedError,
}

