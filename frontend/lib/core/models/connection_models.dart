import 'package:freezed_annotation/freezed_annotation.dart';

part 'connection_models.freezed.dart';
part 'connection_models.g.dart';

/// Connection request status
enum ConnectionRequestStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('accepted')
  accepted,
  @JsonValue('declined')
  declined,
}

/// User profile info (simplified for connection requests)
@freezed
class ConnectionUserProfile with _$ConnectionUserProfile {
  const factory ConnectionUserProfile({
    required String userId,
    required String displayName,
    String? avatarUrl,
    String? username,
  }) = _ConnectionUserProfile;

  factory ConnectionUserProfile.fromJson(Map<String, dynamic> json) =>
      _$ConnectionUserProfileFromJson(json);
}

/// Connection request model
@freezed
class ConnectionRequest with _$ConnectionRequest {
  const factory ConnectionRequest({
    required String id,
    required String fromUserId,
    required String toUserId,
    @Default(ConnectionRequestStatus.pending) ConnectionRequestStatus status,
    String? message,
    String? declinedReason,
    DateTime? actedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    ConnectionUserProfile? fromUserProfile,
    ConnectionUserProfile? toUserProfile,
  }) = _ConnectionRequest;

  factory ConnectionRequest.fromJson(Map<String, dynamic> json) =>
      _$ConnectionRequestFromJson(json);
}

/// Connection model (mutual friendship)
@freezed
class Connection with _$Connection {
  const factory Connection({
    required String userId1,
    required String userId2,
    required DateTime connectedAt,
    required String otherUserId,
    required ConnectionUserProfile otherUserProfile,
  }) = _Connection;

  factory Connection.fromJson(Map<String, dynamic> json) =>
      _$ConnectionFromJson(json);
}

/// Pending requests response
@freezed
class PendingRequests with _$PendingRequests {
  const factory PendingRequests({
    @Default([]) List<ConnectionRequest> incoming,
    @Default([]) List<ConnectionRequest> outgoing,
  }) = _PendingRequests;

  factory PendingRequests.fromJson(Map<String, dynamic> json) =>
      _$PendingRequestsFromJson(json);
}

/// Connection detail with letter statistics
@freezed
class ConnectionDetail with _$ConnectionDetail {
  const factory ConnectionDetail({
    required Connection connection,
    required int lettersSent, // Total letters sent by current user to this connection
    required int lettersReceived, // Total letters received from this connection
  }) = _ConnectionDetail;

  factory ConnectionDetail.fromJson(Map<String, dynamic> json) =>
      _$ConnectionDetailFromJson(json);
}
