// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'connection_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ConnectionUserProfile _$ConnectionUserProfileFromJson(
    Map<String, dynamic> json) {
  return _ConnectionUserProfile.fromJson(json);
}

/// @nodoc
mixin _$ConnectionUserProfile {
  String get userId => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  String? get username => throw _privateConstructorUsedError;

  /// Serializes this ConnectionUserProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ConnectionUserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConnectionUserProfileCopyWith<ConnectionUserProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConnectionUserProfileCopyWith<$Res> {
  factory $ConnectionUserProfileCopyWith(ConnectionUserProfile value,
          $Res Function(ConnectionUserProfile) then) =
      _$ConnectionUserProfileCopyWithImpl<$Res, ConnectionUserProfile>;
  @useResult
  $Res call(
      {String userId, String displayName, String? avatarUrl, String? username});
}

/// @nodoc
class _$ConnectionUserProfileCopyWithImpl<$Res,
        $Val extends ConnectionUserProfile>
    implements $ConnectionUserProfileCopyWith<$Res> {
  _$ConnectionUserProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConnectionUserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? displayName = null,
    Object? avatarUrl = freezed,
    Object? username = freezed,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      username: freezed == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ConnectionUserProfileImplCopyWith<$Res>
    implements $ConnectionUserProfileCopyWith<$Res> {
  factory _$$ConnectionUserProfileImplCopyWith(
          _$ConnectionUserProfileImpl value,
          $Res Function(_$ConnectionUserProfileImpl) then) =
      __$$ConnectionUserProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String userId, String displayName, String? avatarUrl, String? username});
}

/// @nodoc
class __$$ConnectionUserProfileImplCopyWithImpl<$Res>
    extends _$ConnectionUserProfileCopyWithImpl<$Res,
        _$ConnectionUserProfileImpl>
    implements _$$ConnectionUserProfileImplCopyWith<$Res> {
  __$$ConnectionUserProfileImplCopyWithImpl(_$ConnectionUserProfileImpl _value,
      $Res Function(_$ConnectionUserProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of ConnectionUserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? displayName = null,
    Object? avatarUrl = freezed,
    Object? username = freezed,
  }) {
    return _then(_$ConnectionUserProfileImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      username: freezed == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ConnectionUserProfileImpl implements _ConnectionUserProfile {
  const _$ConnectionUserProfileImpl(
      {required this.userId,
      required this.displayName,
      this.avatarUrl,
      this.username});

  factory _$ConnectionUserProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConnectionUserProfileImplFromJson(json);

  @override
  final String userId;
  @override
  final String displayName;
  @override
  final String? avatarUrl;
  @override
  final String? username;

  @override
  String toString() {
    return 'ConnectionUserProfile(userId: $userId, displayName: $displayName, avatarUrl: $avatarUrl, username: $username)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConnectionUserProfileImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.username, username) ||
                other.username == username));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, userId, displayName, avatarUrl, username);

  /// Create a copy of ConnectionUserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConnectionUserProfileImplCopyWith<_$ConnectionUserProfileImpl>
      get copyWith => __$$ConnectionUserProfileImplCopyWithImpl<
          _$ConnectionUserProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ConnectionUserProfileImplToJson(
      this,
    );
  }
}

abstract class _ConnectionUserProfile implements ConnectionUserProfile {
  const factory _ConnectionUserProfile(
      {required final String userId,
      required final String displayName,
      final String? avatarUrl,
      final String? username}) = _$ConnectionUserProfileImpl;

  factory _ConnectionUserProfile.fromJson(Map<String, dynamic> json) =
      _$ConnectionUserProfileImpl.fromJson;

  @override
  String get userId;
  @override
  String get displayName;
  @override
  String? get avatarUrl;
  @override
  String? get username;

  /// Create a copy of ConnectionUserProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConnectionUserProfileImplCopyWith<_$ConnectionUserProfileImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ConnectionRequest _$ConnectionRequestFromJson(Map<String, dynamic> json) {
  return _ConnectionRequest.fromJson(json);
}

/// @nodoc
mixin _$ConnectionRequest {
  String get id => throw _privateConstructorUsedError;
  String get fromUserId => throw _privateConstructorUsedError;
  String get toUserId => throw _privateConstructorUsedError;
  ConnectionRequestStatus get status => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;
  String? get declinedReason => throw _privateConstructorUsedError;
  DateTime? get actedAt => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  ConnectionUserProfile? get fromUserProfile =>
      throw _privateConstructorUsedError;
  ConnectionUserProfile? get toUserProfile =>
      throw _privateConstructorUsedError;

  /// Serializes this ConnectionRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ConnectionRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConnectionRequestCopyWith<ConnectionRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConnectionRequestCopyWith<$Res> {
  factory $ConnectionRequestCopyWith(
          ConnectionRequest value, $Res Function(ConnectionRequest) then) =
      _$ConnectionRequestCopyWithImpl<$Res, ConnectionRequest>;
  @useResult
  $Res call(
      {String id,
      String fromUserId,
      String toUserId,
      ConnectionRequestStatus status,
      String? message,
      String? declinedReason,
      DateTime? actedAt,
      DateTime createdAt,
      DateTime updatedAt,
      ConnectionUserProfile? fromUserProfile,
      ConnectionUserProfile? toUserProfile});

  $ConnectionUserProfileCopyWith<$Res>? get fromUserProfile;
  $ConnectionUserProfileCopyWith<$Res>? get toUserProfile;
}

/// @nodoc
class _$ConnectionRequestCopyWithImpl<$Res, $Val extends ConnectionRequest>
    implements $ConnectionRequestCopyWith<$Res> {
  _$ConnectionRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConnectionRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fromUserId = null,
    Object? toUserId = null,
    Object? status = null,
    Object? message = freezed,
    Object? declinedReason = freezed,
    Object? actedAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? fromUserProfile = freezed,
    Object? toUserProfile = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      fromUserId: null == fromUserId
          ? _value.fromUserId
          : fromUserId // ignore: cast_nullable_to_non_nullable
              as String,
      toUserId: null == toUserId
          ? _value.toUserId
          : toUserId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ConnectionRequestStatus,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      declinedReason: freezed == declinedReason
          ? _value.declinedReason
          : declinedReason // ignore: cast_nullable_to_non_nullable
              as String?,
      actedAt: freezed == actedAt
          ? _value.actedAt
          : actedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      fromUserProfile: freezed == fromUserProfile
          ? _value.fromUserProfile
          : fromUserProfile // ignore: cast_nullable_to_non_nullable
              as ConnectionUserProfile?,
      toUserProfile: freezed == toUserProfile
          ? _value.toUserProfile
          : toUserProfile // ignore: cast_nullable_to_non_nullable
              as ConnectionUserProfile?,
    ) as $Val);
  }

  /// Create a copy of ConnectionRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ConnectionUserProfileCopyWith<$Res>? get fromUserProfile {
    if (_value.fromUserProfile == null) {
      return null;
    }

    return $ConnectionUserProfileCopyWith<$Res>(_value.fromUserProfile!,
        (value) {
      return _then(_value.copyWith(fromUserProfile: value) as $Val);
    });
  }

  /// Create a copy of ConnectionRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ConnectionUserProfileCopyWith<$Res>? get toUserProfile {
    if (_value.toUserProfile == null) {
      return null;
    }

    return $ConnectionUserProfileCopyWith<$Res>(_value.toUserProfile!, (value) {
      return _then(_value.copyWith(toUserProfile: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ConnectionRequestImplCopyWith<$Res>
    implements $ConnectionRequestCopyWith<$Res> {
  factory _$$ConnectionRequestImplCopyWith(_$ConnectionRequestImpl value,
          $Res Function(_$ConnectionRequestImpl) then) =
      __$$ConnectionRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String fromUserId,
      String toUserId,
      ConnectionRequestStatus status,
      String? message,
      String? declinedReason,
      DateTime? actedAt,
      DateTime createdAt,
      DateTime updatedAt,
      ConnectionUserProfile? fromUserProfile,
      ConnectionUserProfile? toUserProfile});

  @override
  $ConnectionUserProfileCopyWith<$Res>? get fromUserProfile;
  @override
  $ConnectionUserProfileCopyWith<$Res>? get toUserProfile;
}

/// @nodoc
class __$$ConnectionRequestImplCopyWithImpl<$Res>
    extends _$ConnectionRequestCopyWithImpl<$Res, _$ConnectionRequestImpl>
    implements _$$ConnectionRequestImplCopyWith<$Res> {
  __$$ConnectionRequestImplCopyWithImpl(_$ConnectionRequestImpl _value,
      $Res Function(_$ConnectionRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of ConnectionRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fromUserId = null,
    Object? toUserId = null,
    Object? status = null,
    Object? message = freezed,
    Object? declinedReason = freezed,
    Object? actedAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? fromUserProfile = freezed,
    Object? toUserProfile = freezed,
  }) {
    return _then(_$ConnectionRequestImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      fromUserId: null == fromUserId
          ? _value.fromUserId
          : fromUserId // ignore: cast_nullable_to_non_nullable
              as String,
      toUserId: null == toUserId
          ? _value.toUserId
          : toUserId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ConnectionRequestStatus,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      declinedReason: freezed == declinedReason
          ? _value.declinedReason
          : declinedReason // ignore: cast_nullable_to_non_nullable
              as String?,
      actedAt: freezed == actedAt
          ? _value.actedAt
          : actedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      fromUserProfile: freezed == fromUserProfile
          ? _value.fromUserProfile
          : fromUserProfile // ignore: cast_nullable_to_non_nullable
              as ConnectionUserProfile?,
      toUserProfile: freezed == toUserProfile
          ? _value.toUserProfile
          : toUserProfile // ignore: cast_nullable_to_non_nullable
              as ConnectionUserProfile?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ConnectionRequestImpl implements _ConnectionRequest {
  const _$ConnectionRequestImpl(
      {required this.id,
      required this.fromUserId,
      required this.toUserId,
      this.status = ConnectionRequestStatus.pending,
      this.message,
      this.declinedReason,
      this.actedAt,
      required this.createdAt,
      required this.updatedAt,
      this.fromUserProfile,
      this.toUserProfile});

  factory _$ConnectionRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConnectionRequestImplFromJson(json);

  @override
  final String id;
  @override
  final String fromUserId;
  @override
  final String toUserId;
  @override
  @JsonKey()
  final ConnectionRequestStatus status;
  @override
  final String? message;
  @override
  final String? declinedReason;
  @override
  final DateTime? actedAt;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final ConnectionUserProfile? fromUserProfile;
  @override
  final ConnectionUserProfile? toUserProfile;

  @override
  String toString() {
    return 'ConnectionRequest(id: $id, fromUserId: $fromUserId, toUserId: $toUserId, status: $status, message: $message, declinedReason: $declinedReason, actedAt: $actedAt, createdAt: $createdAt, updatedAt: $updatedAt, fromUserProfile: $fromUserProfile, toUserProfile: $toUserProfile)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConnectionRequestImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fromUserId, fromUserId) ||
                other.fromUserId == fromUserId) &&
            (identical(other.toUserId, toUserId) ||
                other.toUserId == toUserId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.declinedReason, declinedReason) ||
                other.declinedReason == declinedReason) &&
            (identical(other.actedAt, actedAt) || other.actedAt == actedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.fromUserProfile, fromUserProfile) ||
                other.fromUserProfile == fromUserProfile) &&
            (identical(other.toUserProfile, toUserProfile) ||
                other.toUserProfile == toUserProfile));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      fromUserId,
      toUserId,
      status,
      message,
      declinedReason,
      actedAt,
      createdAt,
      updatedAt,
      fromUserProfile,
      toUserProfile);

  /// Create a copy of ConnectionRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConnectionRequestImplCopyWith<_$ConnectionRequestImpl> get copyWith =>
      __$$ConnectionRequestImplCopyWithImpl<_$ConnectionRequestImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ConnectionRequestImplToJson(
      this,
    );
  }
}

abstract class _ConnectionRequest implements ConnectionRequest {
  const factory _ConnectionRequest(
      {required final String id,
      required final String fromUserId,
      required final String toUserId,
      final ConnectionRequestStatus status,
      final String? message,
      final String? declinedReason,
      final DateTime? actedAt,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      final ConnectionUserProfile? fromUserProfile,
      final ConnectionUserProfile? toUserProfile}) = _$ConnectionRequestImpl;

  factory _ConnectionRequest.fromJson(Map<String, dynamic> json) =
      _$ConnectionRequestImpl.fromJson;

  @override
  String get id;
  @override
  String get fromUserId;
  @override
  String get toUserId;
  @override
  ConnectionRequestStatus get status;
  @override
  String? get message;
  @override
  String? get declinedReason;
  @override
  DateTime? get actedAt;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  ConnectionUserProfile? get fromUserProfile;
  @override
  ConnectionUserProfile? get toUserProfile;

  /// Create a copy of ConnectionRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConnectionRequestImplCopyWith<_$ConnectionRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Connection _$ConnectionFromJson(Map<String, dynamic> json) {
  return _Connection.fromJson(json);
}

/// @nodoc
mixin _$Connection {
  String get userId1 => throw _privateConstructorUsedError;
  String get userId2 => throw _privateConstructorUsedError;
  DateTime get connectedAt => throw _privateConstructorUsedError;
  String get otherUserId => throw _privateConstructorUsedError;
  ConnectionUserProfile get otherUserProfile =>
      throw _privateConstructorUsedError;

  /// Serializes this Connection to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Connection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConnectionCopyWith<Connection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConnectionCopyWith<$Res> {
  factory $ConnectionCopyWith(
          Connection value, $Res Function(Connection) then) =
      _$ConnectionCopyWithImpl<$Res, Connection>;
  @useResult
  $Res call(
      {String userId1,
      String userId2,
      DateTime connectedAt,
      String otherUserId,
      ConnectionUserProfile otherUserProfile});

  $ConnectionUserProfileCopyWith<$Res> get otherUserProfile;
}

/// @nodoc
class _$ConnectionCopyWithImpl<$Res, $Val extends Connection>
    implements $ConnectionCopyWith<$Res> {
  _$ConnectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Connection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId1 = null,
    Object? userId2 = null,
    Object? connectedAt = null,
    Object? otherUserId = null,
    Object? otherUserProfile = null,
  }) {
    return _then(_value.copyWith(
      userId1: null == userId1
          ? _value.userId1
          : userId1 // ignore: cast_nullable_to_non_nullable
              as String,
      userId2: null == userId2
          ? _value.userId2
          : userId2 // ignore: cast_nullable_to_non_nullable
              as String,
      connectedAt: null == connectedAt
          ? _value.connectedAt
          : connectedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      otherUserId: null == otherUserId
          ? _value.otherUserId
          : otherUserId // ignore: cast_nullable_to_non_nullable
              as String,
      otherUserProfile: null == otherUserProfile
          ? _value.otherUserProfile
          : otherUserProfile // ignore: cast_nullable_to_non_nullable
              as ConnectionUserProfile,
    ) as $Val);
  }

  /// Create a copy of Connection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ConnectionUserProfileCopyWith<$Res> get otherUserProfile {
    return $ConnectionUserProfileCopyWith<$Res>(_value.otherUserProfile,
        (value) {
      return _then(_value.copyWith(otherUserProfile: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ConnectionImplCopyWith<$Res>
    implements $ConnectionCopyWith<$Res> {
  factory _$$ConnectionImplCopyWith(
          _$ConnectionImpl value, $Res Function(_$ConnectionImpl) then) =
      __$$ConnectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String userId1,
      String userId2,
      DateTime connectedAt,
      String otherUserId,
      ConnectionUserProfile otherUserProfile});

  @override
  $ConnectionUserProfileCopyWith<$Res> get otherUserProfile;
}

/// @nodoc
class __$$ConnectionImplCopyWithImpl<$Res>
    extends _$ConnectionCopyWithImpl<$Res, _$ConnectionImpl>
    implements _$$ConnectionImplCopyWith<$Res> {
  __$$ConnectionImplCopyWithImpl(
      _$ConnectionImpl _value, $Res Function(_$ConnectionImpl) _then)
      : super(_value, _then);

  /// Create a copy of Connection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId1 = null,
    Object? userId2 = null,
    Object? connectedAt = null,
    Object? otherUserId = null,
    Object? otherUserProfile = null,
  }) {
    return _then(_$ConnectionImpl(
      userId1: null == userId1
          ? _value.userId1
          : userId1 // ignore: cast_nullable_to_non_nullable
              as String,
      userId2: null == userId2
          ? _value.userId2
          : userId2 // ignore: cast_nullable_to_non_nullable
              as String,
      connectedAt: null == connectedAt
          ? _value.connectedAt
          : connectedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      otherUserId: null == otherUserId
          ? _value.otherUserId
          : otherUserId // ignore: cast_nullable_to_non_nullable
              as String,
      otherUserProfile: null == otherUserProfile
          ? _value.otherUserProfile
          : otherUserProfile // ignore: cast_nullable_to_non_nullable
              as ConnectionUserProfile,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ConnectionImpl implements _Connection {
  const _$ConnectionImpl(
      {required this.userId1,
      required this.userId2,
      required this.connectedAt,
      required this.otherUserId,
      required this.otherUserProfile});

  factory _$ConnectionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConnectionImplFromJson(json);

  @override
  final String userId1;
  @override
  final String userId2;
  @override
  final DateTime connectedAt;
  @override
  final String otherUserId;
  @override
  final ConnectionUserProfile otherUserProfile;

  @override
  String toString() {
    return 'Connection(userId1: $userId1, userId2: $userId2, connectedAt: $connectedAt, otherUserId: $otherUserId, otherUserProfile: $otherUserProfile)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConnectionImpl &&
            (identical(other.userId1, userId1) || other.userId1 == userId1) &&
            (identical(other.userId2, userId2) || other.userId2 == userId2) &&
            (identical(other.connectedAt, connectedAt) ||
                other.connectedAt == connectedAt) &&
            (identical(other.otherUserId, otherUserId) ||
                other.otherUserId == otherUserId) &&
            (identical(other.otherUserProfile, otherUserProfile) ||
                other.otherUserProfile == otherUserProfile));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, userId1, userId2, connectedAt,
      otherUserId, otherUserProfile);

  /// Create a copy of Connection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConnectionImplCopyWith<_$ConnectionImpl> get copyWith =>
      __$$ConnectionImplCopyWithImpl<_$ConnectionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ConnectionImplToJson(
      this,
    );
  }
}

abstract class _Connection implements Connection {
  const factory _Connection(
          {required final String userId1,
          required final String userId2,
          required final DateTime connectedAt,
          required final String otherUserId,
          required final ConnectionUserProfile otherUserProfile}) =
      _$ConnectionImpl;

  factory _Connection.fromJson(Map<String, dynamic> json) =
      _$ConnectionImpl.fromJson;

  @override
  String get userId1;
  @override
  String get userId2;
  @override
  DateTime get connectedAt;
  @override
  String get otherUserId;
  @override
  ConnectionUserProfile get otherUserProfile;

  /// Create a copy of Connection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConnectionImplCopyWith<_$ConnectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PendingRequests _$PendingRequestsFromJson(Map<String, dynamic> json) {
  return _PendingRequests.fromJson(json);
}

/// @nodoc
mixin _$PendingRequests {
  List<ConnectionRequest> get incoming => throw _privateConstructorUsedError;
  List<ConnectionRequest> get outgoing => throw _privateConstructorUsedError;

  /// Serializes this PendingRequests to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PendingRequests
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PendingRequestsCopyWith<PendingRequests> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PendingRequestsCopyWith<$Res> {
  factory $PendingRequestsCopyWith(
          PendingRequests value, $Res Function(PendingRequests) then) =
      _$PendingRequestsCopyWithImpl<$Res, PendingRequests>;
  @useResult
  $Res call(
      {List<ConnectionRequest> incoming, List<ConnectionRequest> outgoing});
}

/// @nodoc
class _$PendingRequestsCopyWithImpl<$Res, $Val extends PendingRequests>
    implements $PendingRequestsCopyWith<$Res> {
  _$PendingRequestsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PendingRequests
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? incoming = null,
    Object? outgoing = null,
  }) {
    return _then(_value.copyWith(
      incoming: null == incoming
          ? _value.incoming
          : incoming // ignore: cast_nullable_to_non_nullable
              as List<ConnectionRequest>,
      outgoing: null == outgoing
          ? _value.outgoing
          : outgoing // ignore: cast_nullable_to_non_nullable
              as List<ConnectionRequest>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PendingRequestsImplCopyWith<$Res>
    implements $PendingRequestsCopyWith<$Res> {
  factory _$$PendingRequestsImplCopyWith(_$PendingRequestsImpl value,
          $Res Function(_$PendingRequestsImpl) then) =
      __$$PendingRequestsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<ConnectionRequest> incoming, List<ConnectionRequest> outgoing});
}

/// @nodoc
class __$$PendingRequestsImplCopyWithImpl<$Res>
    extends _$PendingRequestsCopyWithImpl<$Res, _$PendingRequestsImpl>
    implements _$$PendingRequestsImplCopyWith<$Res> {
  __$$PendingRequestsImplCopyWithImpl(
      _$PendingRequestsImpl _value, $Res Function(_$PendingRequestsImpl) _then)
      : super(_value, _then);

  /// Create a copy of PendingRequests
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? incoming = null,
    Object? outgoing = null,
  }) {
    return _then(_$PendingRequestsImpl(
      incoming: null == incoming
          ? _value._incoming
          : incoming // ignore: cast_nullable_to_non_nullable
              as List<ConnectionRequest>,
      outgoing: null == outgoing
          ? _value._outgoing
          : outgoing // ignore: cast_nullable_to_non_nullable
              as List<ConnectionRequest>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PendingRequestsImpl implements _PendingRequests {
  const _$PendingRequestsImpl(
      {final List<ConnectionRequest> incoming = const [],
      final List<ConnectionRequest> outgoing = const []})
      : _incoming = incoming,
        _outgoing = outgoing;

  factory _$PendingRequestsImpl.fromJson(Map<String, dynamic> json) =>
      _$$PendingRequestsImplFromJson(json);

  final List<ConnectionRequest> _incoming;
  @override
  @JsonKey()
  List<ConnectionRequest> get incoming {
    if (_incoming is EqualUnmodifiableListView) return _incoming;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_incoming);
  }

  final List<ConnectionRequest> _outgoing;
  @override
  @JsonKey()
  List<ConnectionRequest> get outgoing {
    if (_outgoing is EqualUnmodifiableListView) return _outgoing;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_outgoing);
  }

  @override
  String toString() {
    return 'PendingRequests(incoming: $incoming, outgoing: $outgoing)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PendingRequestsImpl &&
            const DeepCollectionEquality().equals(other._incoming, _incoming) &&
            const DeepCollectionEquality().equals(other._outgoing, _outgoing));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_incoming),
      const DeepCollectionEquality().hash(_outgoing));

  /// Create a copy of PendingRequests
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PendingRequestsImplCopyWith<_$PendingRequestsImpl> get copyWith =>
      __$$PendingRequestsImplCopyWithImpl<_$PendingRequestsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PendingRequestsImplToJson(
      this,
    );
  }
}

abstract class _PendingRequests implements PendingRequests {
  const factory _PendingRequests(
      {final List<ConnectionRequest> incoming,
      final List<ConnectionRequest> outgoing}) = _$PendingRequestsImpl;

  factory _PendingRequests.fromJson(Map<String, dynamic> json) =
      _$PendingRequestsImpl.fromJson;

  @override
  List<ConnectionRequest> get incoming;
  @override
  List<ConnectionRequest> get outgoing;

  /// Create a copy of PendingRequests
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PendingRequestsImplCopyWith<_$PendingRequestsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ConnectionDetail _$ConnectionDetailFromJson(Map<String, dynamic> json) {
  return _ConnectionDetail.fromJson(json);
}

/// @nodoc
mixin _$ConnectionDetail {
  Connection get connection => throw _privateConstructorUsedError;
  int get lettersSent =>
      throw _privateConstructorUsedError; // Total letters sent by current user to this connection
  int get lettersReceived => throw _privateConstructorUsedError;

  /// Serializes this ConnectionDetail to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ConnectionDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConnectionDetailCopyWith<ConnectionDetail> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConnectionDetailCopyWith<$Res> {
  factory $ConnectionDetailCopyWith(
          ConnectionDetail value, $Res Function(ConnectionDetail) then) =
      _$ConnectionDetailCopyWithImpl<$Res, ConnectionDetail>;
  @useResult
  $Res call({Connection connection, int lettersSent, int lettersReceived});

  $ConnectionCopyWith<$Res> get connection;
}

/// @nodoc
class _$ConnectionDetailCopyWithImpl<$Res, $Val extends ConnectionDetail>
    implements $ConnectionDetailCopyWith<$Res> {
  _$ConnectionDetailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConnectionDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? connection = null,
    Object? lettersSent = null,
    Object? lettersReceived = null,
  }) {
    return _then(_value.copyWith(
      connection: null == connection
          ? _value.connection
          : connection // ignore: cast_nullable_to_non_nullable
              as Connection,
      lettersSent: null == lettersSent
          ? _value.lettersSent
          : lettersSent // ignore: cast_nullable_to_non_nullable
              as int,
      lettersReceived: null == lettersReceived
          ? _value.lettersReceived
          : lettersReceived // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }

  /// Create a copy of ConnectionDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ConnectionCopyWith<$Res> get connection {
    return $ConnectionCopyWith<$Res>(_value.connection, (value) {
      return _then(_value.copyWith(connection: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ConnectionDetailImplCopyWith<$Res>
    implements $ConnectionDetailCopyWith<$Res> {
  factory _$$ConnectionDetailImplCopyWith(_$ConnectionDetailImpl value,
          $Res Function(_$ConnectionDetailImpl) then) =
      __$$ConnectionDetailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Connection connection, int lettersSent, int lettersReceived});

  @override
  $ConnectionCopyWith<$Res> get connection;
}

/// @nodoc
class __$$ConnectionDetailImplCopyWithImpl<$Res>
    extends _$ConnectionDetailCopyWithImpl<$Res, _$ConnectionDetailImpl>
    implements _$$ConnectionDetailImplCopyWith<$Res> {
  __$$ConnectionDetailImplCopyWithImpl(_$ConnectionDetailImpl _value,
      $Res Function(_$ConnectionDetailImpl) _then)
      : super(_value, _then);

  /// Create a copy of ConnectionDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? connection = null,
    Object? lettersSent = null,
    Object? lettersReceived = null,
  }) {
    return _then(_$ConnectionDetailImpl(
      connection: null == connection
          ? _value.connection
          : connection // ignore: cast_nullable_to_non_nullable
              as Connection,
      lettersSent: null == lettersSent
          ? _value.lettersSent
          : lettersSent // ignore: cast_nullable_to_non_nullable
              as int,
      lettersReceived: null == lettersReceived
          ? _value.lettersReceived
          : lettersReceived // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ConnectionDetailImpl implements _ConnectionDetail {
  const _$ConnectionDetailImpl(
      {required this.connection,
      required this.lettersSent,
      required this.lettersReceived});

  factory _$ConnectionDetailImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConnectionDetailImplFromJson(json);

  @override
  final Connection connection;
  @override
  final int lettersSent;
// Total letters sent by current user to this connection
  @override
  final int lettersReceived;

  @override
  String toString() {
    return 'ConnectionDetail(connection: $connection, lettersSent: $lettersSent, lettersReceived: $lettersReceived)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConnectionDetailImpl &&
            (identical(other.connection, connection) ||
                other.connection == connection) &&
            (identical(other.lettersSent, lettersSent) ||
                other.lettersSent == lettersSent) &&
            (identical(other.lettersReceived, lettersReceived) ||
                other.lettersReceived == lettersReceived));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, connection, lettersSent, lettersReceived);

  /// Create a copy of ConnectionDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConnectionDetailImplCopyWith<_$ConnectionDetailImpl> get copyWith =>
      __$$ConnectionDetailImplCopyWithImpl<_$ConnectionDetailImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ConnectionDetailImplToJson(
      this,
    );
  }
}

abstract class _ConnectionDetail implements ConnectionDetail {
  const factory _ConnectionDetail(
      {required final Connection connection,
      required final int lettersSent,
      required final int lettersReceived}) = _$ConnectionDetailImpl;

  factory _ConnectionDetail.fromJson(Map<String, dynamic> json) =
      _$ConnectionDetailImpl.fromJson;

  @override
  Connection get connection;
  @override
  int get lettersSent; // Total letters sent by current user to this connection
  @override
  int get lettersReceived;

  /// Create a copy of ConnectionDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConnectionDetailImplCopyWith<_$ConnectionDetailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
