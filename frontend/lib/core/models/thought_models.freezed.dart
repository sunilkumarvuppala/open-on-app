// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'thought_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Thought _$ThoughtFromJson(Map<String, dynamic> json) {
  return _Thought.fromJson(json);
}

/// @nodoc
mixin _$Thought {
  String get id => throw _privateConstructorUsedError;
  String get senderId => throw _privateConstructorUsedError;
  String get receiverId => throw _privateConstructorUsedError;
  DateTime get displayDate =>
      throw _privateConstructorUsedError; // Only date, not exact time
  DateTime get createdAt =>
      throw _privateConstructorUsedError; // For internal sorting only
  String? get senderName => throw _privateConstructorUsedError;
  String? get senderAvatarUrl => throw _privateConstructorUsedError;
  String? get senderUsername => throw _privateConstructorUsedError;
  String? get receiverName => throw _privateConstructorUsedError;
  String? get receiverAvatarUrl => throw _privateConstructorUsedError;
  String? get receiverUsername => throw _privateConstructorUsedError;

  /// Serializes this Thought to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Thought
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ThoughtCopyWith<Thought> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ThoughtCopyWith<$Res> {
  factory $ThoughtCopyWith(Thought value, $Res Function(Thought) then) =
      _$ThoughtCopyWithImpl<$Res, Thought>;
  @useResult
  $Res call(
      {String id,
      String senderId,
      String receiverId,
      DateTime displayDate,
      DateTime createdAt,
      String? senderName,
      String? senderAvatarUrl,
      String? senderUsername,
      String? receiverName,
      String? receiverAvatarUrl,
      String? receiverUsername});
}

/// @nodoc
class _$ThoughtCopyWithImpl<$Res, $Val extends Thought>
    implements $ThoughtCopyWith<$Res> {
  _$ThoughtCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Thought
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? senderId = null,
    Object? receiverId = null,
    Object? displayDate = null,
    Object? createdAt = null,
    Object? senderName = freezed,
    Object? senderAvatarUrl = freezed,
    Object? senderUsername = freezed,
    Object? receiverName = freezed,
    Object? receiverAvatarUrl = freezed,
    Object? receiverUsername = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      receiverId: null == receiverId
          ? _value.receiverId
          : receiverId // ignore: cast_nullable_to_non_nullable
              as String,
      displayDate: null == displayDate
          ? _value.displayDate
          : displayDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      senderName: freezed == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String?,
      senderAvatarUrl: freezed == senderAvatarUrl
          ? _value.senderAvatarUrl
          : senderAvatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      senderUsername: freezed == senderUsername
          ? _value.senderUsername
          : senderUsername // ignore: cast_nullable_to_non_nullable
              as String?,
      receiverName: freezed == receiverName
          ? _value.receiverName
          : receiverName // ignore: cast_nullable_to_non_nullable
              as String?,
      receiverAvatarUrl: freezed == receiverAvatarUrl
          ? _value.receiverAvatarUrl
          : receiverAvatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      receiverUsername: freezed == receiverUsername
          ? _value.receiverUsername
          : receiverUsername // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ThoughtImplCopyWith<$Res> implements $ThoughtCopyWith<$Res> {
  factory _$$ThoughtImplCopyWith(
          _$ThoughtImpl value, $Res Function(_$ThoughtImpl) then) =
      __$$ThoughtImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String senderId,
      String receiverId,
      DateTime displayDate,
      DateTime createdAt,
      String? senderName,
      String? senderAvatarUrl,
      String? senderUsername,
      String? receiverName,
      String? receiverAvatarUrl,
      String? receiverUsername});
}

/// @nodoc
class __$$ThoughtImplCopyWithImpl<$Res>
    extends _$ThoughtCopyWithImpl<$Res, _$ThoughtImpl>
    implements _$$ThoughtImplCopyWith<$Res> {
  __$$ThoughtImplCopyWithImpl(
      _$ThoughtImpl _value, $Res Function(_$ThoughtImpl) _then)
      : super(_value, _then);

  /// Create a copy of Thought
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? senderId = null,
    Object? receiverId = null,
    Object? displayDate = null,
    Object? createdAt = null,
    Object? senderName = freezed,
    Object? senderAvatarUrl = freezed,
    Object? senderUsername = freezed,
    Object? receiverName = freezed,
    Object? receiverAvatarUrl = freezed,
    Object? receiverUsername = freezed,
  }) {
    return _then(_$ThoughtImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      receiverId: null == receiverId
          ? _value.receiverId
          : receiverId // ignore: cast_nullable_to_non_nullable
              as String,
      displayDate: null == displayDate
          ? _value.displayDate
          : displayDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      senderName: freezed == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String?,
      senderAvatarUrl: freezed == senderAvatarUrl
          ? _value.senderAvatarUrl
          : senderAvatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      senderUsername: freezed == senderUsername
          ? _value.senderUsername
          : senderUsername // ignore: cast_nullable_to_non_nullable
              as String?,
      receiverName: freezed == receiverName
          ? _value.receiverName
          : receiverName // ignore: cast_nullable_to_non_nullable
              as String?,
      receiverAvatarUrl: freezed == receiverAvatarUrl
          ? _value.receiverAvatarUrl
          : receiverAvatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      receiverUsername: freezed == receiverUsername
          ? _value.receiverUsername
          : receiverUsername // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ThoughtImpl implements _Thought {
  const _$ThoughtImpl(
      {required this.id,
      required this.senderId,
      required this.receiverId,
      required this.displayDate,
      required this.createdAt,
      this.senderName,
      this.senderAvatarUrl,
      this.senderUsername,
      this.receiverName,
      this.receiverAvatarUrl,
      this.receiverUsername});

  factory _$ThoughtImpl.fromJson(Map<String, dynamic> json) =>
      _$$ThoughtImplFromJson(json);

  @override
  final String id;
  @override
  final String senderId;
  @override
  final String receiverId;
  @override
  final DateTime displayDate;
// Only date, not exact time
  @override
  final DateTime createdAt;
// For internal sorting only
  @override
  final String? senderName;
  @override
  final String? senderAvatarUrl;
  @override
  final String? senderUsername;
  @override
  final String? receiverName;
  @override
  final String? receiverAvatarUrl;
  @override
  final String? receiverUsername;

  @override
  String toString() {
    return 'Thought(id: $id, senderId: $senderId, receiverId: $receiverId, displayDate: $displayDate, createdAt: $createdAt, senderName: $senderName, senderAvatarUrl: $senderAvatarUrl, senderUsername: $senderUsername, receiverName: $receiverName, receiverAvatarUrl: $receiverAvatarUrl, receiverUsername: $receiverUsername)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ThoughtImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.receiverId, receiverId) ||
                other.receiverId == receiverId) &&
            (identical(other.displayDate, displayDate) ||
                other.displayDate == displayDate) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.senderName, senderName) ||
                other.senderName == senderName) &&
            (identical(other.senderAvatarUrl, senderAvatarUrl) ||
                other.senderAvatarUrl == senderAvatarUrl) &&
            (identical(other.senderUsername, senderUsername) ||
                other.senderUsername == senderUsername) &&
            (identical(other.receiverName, receiverName) ||
                other.receiverName == receiverName) &&
            (identical(other.receiverAvatarUrl, receiverAvatarUrl) ||
                other.receiverAvatarUrl == receiverAvatarUrl) &&
            (identical(other.receiverUsername, receiverUsername) ||
                other.receiverUsername == receiverUsername));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      senderId,
      receiverId,
      displayDate,
      createdAt,
      senderName,
      senderAvatarUrl,
      senderUsername,
      receiverName,
      receiverAvatarUrl,
      receiverUsername);

  /// Create a copy of Thought
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ThoughtImplCopyWith<_$ThoughtImpl> get copyWith =>
      __$$ThoughtImplCopyWithImpl<_$ThoughtImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ThoughtImplToJson(
      this,
    );
  }
}

abstract class _Thought implements Thought {
  const factory _Thought(
      {required final String id,
      required final String senderId,
      required final String receiverId,
      required final DateTime displayDate,
      required final DateTime createdAt,
      final String? senderName,
      final String? senderAvatarUrl,
      final String? senderUsername,
      final String? receiverName,
      final String? receiverAvatarUrl,
      final String? receiverUsername}) = _$ThoughtImpl;

  factory _Thought.fromJson(Map<String, dynamic> json) = _$ThoughtImpl.fromJson;

  @override
  String get id;
  @override
  String get senderId;
  @override
  String get receiverId;
  @override
  DateTime get displayDate; // Only date, not exact time
  @override
  DateTime get createdAt; // For internal sorting only
  @override
  String? get senderName;
  @override
  String? get senderAvatarUrl;
  @override
  String? get senderUsername;
  @override
  String? get receiverName;
  @override
  String? get receiverAvatarUrl;
  @override
  String? get receiverUsername;

  /// Create a copy of Thought
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ThoughtImplCopyWith<_$ThoughtImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SendThoughtResult _$SendThoughtResultFromJson(Map<String, dynamic> json) {
  return _SendThoughtResult.fromJson(json);
}

/// @nodoc
mixin _$SendThoughtResult {
  bool get success => throw _privateConstructorUsedError;
  String? get thoughtId => throw _privateConstructorUsedError;
  String? get errorCode => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Serializes this SendThoughtResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SendThoughtResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SendThoughtResultCopyWith<SendThoughtResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SendThoughtResultCopyWith<$Res> {
  factory $SendThoughtResultCopyWith(
          SendThoughtResult value, $Res Function(SendThoughtResult) then) =
      _$SendThoughtResultCopyWithImpl<$Res, SendThoughtResult>;
  @useResult
  $Res call(
      {bool success,
      String? thoughtId,
      String? errorCode,
      String? errorMessage});
}

/// @nodoc
class _$SendThoughtResultCopyWithImpl<$Res, $Val extends SendThoughtResult>
    implements $SendThoughtResultCopyWith<$Res> {
  _$SendThoughtResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SendThoughtResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? thoughtId = freezed,
    Object? errorCode = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(_value.copyWith(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      thoughtId: freezed == thoughtId
          ? _value.thoughtId
          : thoughtId // ignore: cast_nullable_to_non_nullable
              as String?,
      errorCode: freezed == errorCode
          ? _value.errorCode
          : errorCode // ignore: cast_nullable_to_non_nullable
              as String?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SendThoughtResultImplCopyWith<$Res>
    implements $SendThoughtResultCopyWith<$Res> {
  factory _$$SendThoughtResultImplCopyWith(_$SendThoughtResultImpl value,
          $Res Function(_$SendThoughtResultImpl) then) =
      __$$SendThoughtResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool success,
      String? thoughtId,
      String? errorCode,
      String? errorMessage});
}

/// @nodoc
class __$$SendThoughtResultImplCopyWithImpl<$Res>
    extends _$SendThoughtResultCopyWithImpl<$Res, _$SendThoughtResultImpl>
    implements _$$SendThoughtResultImplCopyWith<$Res> {
  __$$SendThoughtResultImplCopyWithImpl(_$SendThoughtResultImpl _value,
      $Res Function(_$SendThoughtResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of SendThoughtResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? thoughtId = freezed,
    Object? errorCode = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(_$SendThoughtResultImpl(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      thoughtId: freezed == thoughtId
          ? _value.thoughtId
          : thoughtId // ignore: cast_nullable_to_non_nullable
              as String?,
      errorCode: freezed == errorCode
          ? _value.errorCode
          : errorCode // ignore: cast_nullable_to_non_nullable
              as String?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SendThoughtResultImpl implements _SendThoughtResult {
  const _$SendThoughtResultImpl(
      {required this.success,
      this.thoughtId,
      this.errorCode,
      this.errorMessage});

  factory _$SendThoughtResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$SendThoughtResultImplFromJson(json);

  @override
  final bool success;
  @override
  final String? thoughtId;
  @override
  final String? errorCode;
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'SendThoughtResult(success: $success, thoughtId: $thoughtId, errorCode: $errorCode, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SendThoughtResultImpl &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.thoughtId, thoughtId) ||
                other.thoughtId == thoughtId) &&
            (identical(other.errorCode, errorCode) ||
                other.errorCode == errorCode) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, success, thoughtId, errorCode, errorMessage);

  /// Create a copy of SendThoughtResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SendThoughtResultImplCopyWith<_$SendThoughtResultImpl> get copyWith =>
      __$$SendThoughtResultImplCopyWithImpl<_$SendThoughtResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SendThoughtResultImplToJson(
      this,
    );
  }
}

abstract class _SendThoughtResult implements SendThoughtResult {
  const factory _SendThoughtResult(
      {required final bool success,
      final String? thoughtId,
      final String? errorCode,
      final String? errorMessage}) = _$SendThoughtResultImpl;

  factory _SendThoughtResult.fromJson(Map<String, dynamic> json) =
      _$SendThoughtResultImpl.fromJson;

  @override
  bool get success;
  @override
  String? get thoughtId;
  @override
  String? get errorCode;
  @override
  String? get errorMessage;

  /// Create a copy of SendThoughtResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SendThoughtResultImplCopyWith<_$SendThoughtResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
