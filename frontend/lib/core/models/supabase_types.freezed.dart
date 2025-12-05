// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'supabase_types.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) {
  return _UserProfile.fromJson(json);
}

/// @nodoc
mixin _$UserProfile {
  String get userId => throw _privateConstructorUsedError;
  String? get fullName => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  bool get premiumStatus => throw _privateConstructorUsedError;
  DateTime? get premiumUntil => throw _privateConstructorUsedError;
  String? get country => throw _privateConstructorUsedError;
  String? get deviceToken => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this UserProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserProfileCopyWith<UserProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserProfileCopyWith<$Res> {
  factory $UserProfileCopyWith(
          UserProfile value, $Res Function(UserProfile) then) =
      _$UserProfileCopyWithImpl<$Res, UserProfile>;
  @useResult
  $Res call(
      {String userId,
      String? fullName,
      String? avatarUrl,
      bool premiumStatus,
      DateTime? premiumUntil,
      String? country,
      String? deviceToken,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$UserProfileCopyWithImpl<$Res, $Val extends UserProfile>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? fullName = freezed,
    Object? avatarUrl = freezed,
    Object? premiumStatus = null,
    Object? premiumUntil = freezed,
    Object? country = freezed,
    Object? deviceToken = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: freezed == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      premiumStatus: null == premiumStatus
          ? _value.premiumStatus
          : premiumStatus // ignore: cast_nullable_to_non_nullable
              as bool,
      premiumUntil: freezed == premiumUntil
          ? _value.premiumUntil
          : premiumUntil // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      deviceToken: freezed == deviceToken
          ? _value.deviceToken
          : deviceToken // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserProfileImplCopyWith<$Res>
    implements $UserProfileCopyWith<$Res> {
  factory _$$UserProfileImplCopyWith(
          _$UserProfileImpl value, $Res Function(_$UserProfileImpl) then) =
      __$$UserProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String userId,
      String? fullName,
      String? avatarUrl,
      bool premiumStatus,
      DateTime? premiumUntil,
      String? country,
      String? deviceToken,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$$UserProfileImplCopyWithImpl<$Res>
    extends _$UserProfileCopyWithImpl<$Res, _$UserProfileImpl>
    implements _$$UserProfileImplCopyWith<$Res> {
  __$$UserProfileImplCopyWithImpl(
      _$UserProfileImpl _value, $Res Function(_$UserProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? fullName = freezed,
    Object? avatarUrl = freezed,
    Object? premiumStatus = null,
    Object? premiumUntil = freezed,
    Object? country = freezed,
    Object? deviceToken = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$UserProfileImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: freezed == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      premiumStatus: null == premiumStatus
          ? _value.premiumStatus
          : premiumStatus // ignore: cast_nullable_to_non_nullable
              as bool,
      premiumUntil: freezed == premiumUntil
          ? _value.premiumUntil
          : premiumUntil // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      deviceToken: freezed == deviceToken
          ? _value.deviceToken
          : deviceToken // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserProfileImpl implements _UserProfile {
  const _$UserProfileImpl(
      {required this.userId,
      this.fullName,
      this.avatarUrl,
      this.premiumStatus = false,
      this.premiumUntil,
      this.country,
      this.deviceToken,
      required this.createdAt,
      required this.updatedAt});

  factory _$UserProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserProfileImplFromJson(json);

  @override
  final String userId;
  @override
  final String? fullName;
  @override
  final String? avatarUrl;
  @override
  @JsonKey()
  final bool premiumStatus;
  @override
  final DateTime? premiumUntil;
  @override
  final String? country;
  @override
  final String? deviceToken;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'UserProfile(userId: $userId, fullName: $fullName, avatarUrl: $avatarUrl, premiumStatus: $premiumStatus, premiumUntil: $premiumUntil, country: $country, deviceToken: $deviceToken, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserProfileImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.premiumStatus, premiumStatus) ||
                other.premiumStatus == premiumStatus) &&
            (identical(other.premiumUntil, premiumUntil) ||
                other.premiumUntil == premiumUntil) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.deviceToken, deviceToken) ||
                other.deviceToken == deviceToken) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, userId, fullName, avatarUrl,
      premiumStatus, premiumUntil, country, deviceToken, createdAt, updatedAt);

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      __$$UserProfileImplCopyWithImpl<_$UserProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserProfileImplToJson(
      this,
    );
  }
}

abstract class _UserProfile implements UserProfile {
  const factory _UserProfile(
      {required final String userId,
      final String? fullName,
      final String? avatarUrl,
      final bool premiumStatus,
      final DateTime? premiumUntil,
      final String? country,
      final String? deviceToken,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$UserProfileImpl;

  factory _UserProfile.fromJson(Map<String, dynamic> json) =
      _$UserProfileImpl.fromJson;

  @override
  String get userId;
  @override
  String? get fullName;
  @override
  String? get avatarUrl;
  @override
  bool get premiumStatus;
  @override
  DateTime? get premiumUntil;
  @override
  String? get country;
  @override
  String? get deviceToken;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Recipient _$RecipientFromJson(Map<String, dynamic> json) {
  return _Recipient.fromJson(json);
}

/// @nodoc
mixin _$Recipient {
  String get id => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Recipient to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Recipient
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecipientCopyWith<Recipient> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecipientCopyWith<$Res> {
  factory $RecipientCopyWith(Recipient value, $Res Function(Recipient) then) =
      _$RecipientCopyWithImpl<$Res, Recipient>;
  @useResult
  $Res call(
      {String id,
      String ownerId,
      String name,
      String? email,
      String? avatarUrl,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$RecipientCopyWithImpl<$Res, $Val extends Recipient>
    implements $RecipientCopyWith<$Res> {
  _$RecipientCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Recipient
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? name = null,
    Object? email = freezed,
    Object? avatarUrl = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RecipientImplCopyWith<$Res>
    implements $RecipientCopyWith<$Res> {
  factory _$$RecipientImplCopyWith(
          _$RecipientImpl value, $Res Function(_$RecipientImpl) then) =
      __$$RecipientImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String ownerId,
      String name,
      String? email,
      String? avatarUrl,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$$RecipientImplCopyWithImpl<$Res>
    extends _$RecipientCopyWithImpl<$Res, _$RecipientImpl>
    implements _$$RecipientImplCopyWith<$Res> {
  __$$RecipientImplCopyWithImpl(
      _$RecipientImpl _value, $Res Function(_$RecipientImpl) _then)
      : super(_value, _then);

  /// Create a copy of Recipient
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerId = null,
    Object? name = null,
    Object? email = freezed,
    Object? avatarUrl = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$RecipientImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RecipientImpl implements _Recipient {
  const _$RecipientImpl(
      {required this.id,
      required this.ownerId,
      required this.name,
      this.email,
      this.avatarUrl,
      required this.createdAt,
      required this.updatedAt});

  factory _$RecipientImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecipientImplFromJson(json);

  @override
  final String id;
  @override
  final String ownerId;
  @override
  final String name;
  @override
  final String? email;
  @override
  final String? avatarUrl;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Recipient(id: $id, ownerId: $ownerId, name: $name, email: $email, avatarUrl: $avatarUrl, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecipientImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, ownerId, name, email, avatarUrl, createdAt, updatedAt);

  /// Create a copy of Recipient
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecipientImplCopyWith<_$RecipientImpl> get copyWith =>
      __$$RecipientImplCopyWithImpl<_$RecipientImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecipientImplToJson(
      this,
    );
  }
}

abstract class _Recipient implements Recipient {
  const factory _Recipient(
      {required final String id,
      required final String ownerId,
      required final String name,
      final String? email,
      final String? avatarUrl,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$RecipientImpl;

  factory _Recipient.fromJson(Map<String, dynamic> json) =
      _$RecipientImpl.fromJson;

  @override
  String get id;
  @override
  String get ownerId;
  @override
  String get name;
  @override
  String? get email;
  @override
  String? get avatarUrl;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of Recipient
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecipientImplCopyWith<_$RecipientImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Theme _$ThemeFromJson(Map<String, dynamic> json) {
  return _Theme.fromJson(json);
}

/// @nodoc
mixin _$Theme {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get gradientStart => throw _privateConstructorUsedError;
  String get gradientEnd => throw _privateConstructorUsedError;
  String? get previewUrl => throw _privateConstructorUsedError;
  bool get premiumOnly => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Theme to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Theme
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ThemeCopyWith<Theme> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ThemeCopyWith<$Res> {
  factory $ThemeCopyWith(Theme value, $Res Function(Theme) then) =
      _$ThemeCopyWithImpl<$Res, Theme>;
  @useResult
  $Res call(
      {String id,
      String name,
      String? description,
      String gradientStart,
      String gradientEnd,
      String? previewUrl,
      bool premiumOnly,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$ThemeCopyWithImpl<$Res, $Val extends Theme>
    implements $ThemeCopyWith<$Res> {
  _$ThemeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Theme
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? gradientStart = null,
    Object? gradientEnd = null,
    Object? previewUrl = freezed,
    Object? premiumOnly = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      gradientStart: null == gradientStart
          ? _value.gradientStart
          : gradientStart // ignore: cast_nullable_to_non_nullable
              as String,
      gradientEnd: null == gradientEnd
          ? _value.gradientEnd
          : gradientEnd // ignore: cast_nullable_to_non_nullable
              as String,
      previewUrl: freezed == previewUrl
          ? _value.previewUrl
          : previewUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      premiumOnly: null == premiumOnly
          ? _value.premiumOnly
          : premiumOnly // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ThemeImplCopyWith<$Res> implements $ThemeCopyWith<$Res> {
  factory _$$ThemeImplCopyWith(
          _$ThemeImpl value, $Res Function(_$ThemeImpl) then) =
      __$$ThemeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String? description,
      String gradientStart,
      String gradientEnd,
      String? previewUrl,
      bool premiumOnly,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$$ThemeImplCopyWithImpl<$Res>
    extends _$ThemeCopyWithImpl<$Res, _$ThemeImpl>
    implements _$$ThemeImplCopyWith<$Res> {
  __$$ThemeImplCopyWithImpl(
      _$ThemeImpl _value, $Res Function(_$ThemeImpl) _then)
      : super(_value, _then);

  /// Create a copy of Theme
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? gradientStart = null,
    Object? gradientEnd = null,
    Object? previewUrl = freezed,
    Object? premiumOnly = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$ThemeImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      gradientStart: null == gradientStart
          ? _value.gradientStart
          : gradientStart // ignore: cast_nullable_to_non_nullable
              as String,
      gradientEnd: null == gradientEnd
          ? _value.gradientEnd
          : gradientEnd // ignore: cast_nullable_to_non_nullable
              as String,
      previewUrl: freezed == previewUrl
          ? _value.previewUrl
          : previewUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      premiumOnly: null == premiumOnly
          ? _value.premiumOnly
          : premiumOnly // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ThemeImpl implements _Theme {
  const _$ThemeImpl(
      {required this.id,
      required this.name,
      this.description,
      required this.gradientStart,
      required this.gradientEnd,
      this.previewUrl,
      this.premiumOnly = false,
      required this.createdAt,
      required this.updatedAt});

  factory _$ThemeImpl.fromJson(Map<String, dynamic> json) =>
      _$$ThemeImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? description;
  @override
  final String gradientStart;
  @override
  final String gradientEnd;
  @override
  final String? previewUrl;
  @override
  @JsonKey()
  final bool premiumOnly;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Theme(id: $id, name: $name, description: $description, gradientStart: $gradientStart, gradientEnd: $gradientEnd, previewUrl: $previewUrl, premiumOnly: $premiumOnly, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ThemeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.gradientStart, gradientStart) ||
                other.gradientStart == gradientStart) &&
            (identical(other.gradientEnd, gradientEnd) ||
                other.gradientEnd == gradientEnd) &&
            (identical(other.previewUrl, previewUrl) ||
                other.previewUrl == previewUrl) &&
            (identical(other.premiumOnly, premiumOnly) ||
                other.premiumOnly == premiumOnly) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      description,
      gradientStart,
      gradientEnd,
      previewUrl,
      premiumOnly,
      createdAt,
      updatedAt);

  /// Create a copy of Theme
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ThemeImplCopyWith<_$ThemeImpl> get copyWith =>
      __$$ThemeImplCopyWithImpl<_$ThemeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ThemeImplToJson(
      this,
    );
  }
}

abstract class _Theme implements Theme {
  const factory _Theme(
      {required final String id,
      required final String name,
      final String? description,
      required final String gradientStart,
      required final String gradientEnd,
      final String? previewUrl,
      final bool premiumOnly,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$ThemeImpl;

  factory _Theme.fromJson(Map<String, dynamic> json) = _$ThemeImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get description;
  @override
  String get gradientStart;
  @override
  String get gradientEnd;
  @override
  String? get previewUrl;
  @override
  bool get premiumOnly;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of Theme
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ThemeImplCopyWith<_$ThemeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Animation _$AnimationFromJson(Map<String, dynamic> json) {
  return _Animation.fromJson(json);
}

/// @nodoc
mixin _$Animation {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get previewUrl => throw _privateConstructorUsedError;
  bool get premiumOnly => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Animation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Animation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AnimationCopyWith<Animation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AnimationCopyWith<$Res> {
  factory $AnimationCopyWith(Animation value, $Res Function(Animation) then) =
      _$AnimationCopyWithImpl<$Res, Animation>;
  @useResult
  $Res call(
      {String id,
      String name,
      String? description,
      String? previewUrl,
      bool premiumOnly,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$AnimationCopyWithImpl<$Res, $Val extends Animation>
    implements $AnimationCopyWith<$Res> {
  _$AnimationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Animation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? previewUrl = freezed,
    Object? premiumOnly = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      previewUrl: freezed == previewUrl
          ? _value.previewUrl
          : previewUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      premiumOnly: null == premiumOnly
          ? _value.premiumOnly
          : premiumOnly // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AnimationImplCopyWith<$Res>
    implements $AnimationCopyWith<$Res> {
  factory _$$AnimationImplCopyWith(
          _$AnimationImpl value, $Res Function(_$AnimationImpl) then) =
      __$$AnimationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String? description,
      String? previewUrl,
      bool premiumOnly,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$$AnimationImplCopyWithImpl<$Res>
    extends _$AnimationCopyWithImpl<$Res, _$AnimationImpl>
    implements _$$AnimationImplCopyWith<$Res> {
  __$$AnimationImplCopyWithImpl(
      _$AnimationImpl _value, $Res Function(_$AnimationImpl) _then)
      : super(_value, _then);

  /// Create a copy of Animation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? previewUrl = freezed,
    Object? premiumOnly = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$AnimationImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      previewUrl: freezed == previewUrl
          ? _value.previewUrl
          : previewUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      premiumOnly: null == premiumOnly
          ? _value.premiumOnly
          : premiumOnly // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AnimationImpl implements _Animation {
  const _$AnimationImpl(
      {required this.id,
      required this.name,
      this.description,
      this.previewUrl,
      this.premiumOnly = false,
      required this.createdAt,
      required this.updatedAt});

  factory _$AnimationImpl.fromJson(Map<String, dynamic> json) =>
      _$$AnimationImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? description;
  @override
  final String? previewUrl;
  @override
  @JsonKey()
  final bool premiumOnly;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Animation(id: $id, name: $name, description: $description, previewUrl: $previewUrl, premiumOnly: $premiumOnly, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AnimationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.previewUrl, previewUrl) ||
                other.previewUrl == previewUrl) &&
            (identical(other.premiumOnly, premiumOnly) ||
                other.premiumOnly == premiumOnly) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, description,
      previewUrl, premiumOnly, createdAt, updatedAt);

  /// Create a copy of Animation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AnimationImplCopyWith<_$AnimationImpl> get copyWith =>
      __$$AnimationImplCopyWithImpl<_$AnimationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AnimationImplToJson(
      this,
    );
  }
}

abstract class _Animation implements Animation {
  const factory _Animation(
      {required final String id,
      required final String name,
      final String? description,
      final String? previewUrl,
      final bool premiumOnly,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$AnimationImpl;

  factory _Animation.fromJson(Map<String, dynamic> json) =
      _$AnimationImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get description;
  @override
  String? get previewUrl;
  @override
  bool get premiumOnly;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of Animation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AnimationImplCopyWith<_$AnimationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Capsule _$CapsuleFromJson(Map<String, dynamic> json) {
  return _Capsule.fromJson(json);
}

/// @nodoc
mixin _$Capsule {
  String get id => throw _privateConstructorUsedError;
  String get senderId => throw _privateConstructorUsedError;
  String? get senderName => throw _privateConstructorUsedError;
  String? get senderAvatarUrl => throw _privateConstructorUsedError;
  String get recipientId => throw _privateConstructorUsedError;
  String? get recipientName => throw _privateConstructorUsedError;
  bool get isAnonymous => throw _privateConstructorUsedError;
  bool get isDisappearing => throw _privateConstructorUsedError;
  int? get disappearingAfterOpenSeconds => throw _privateConstructorUsedError;
  DateTime get unlocksAt => throw _privateConstructorUsedError;
  DateTime? get openedAt => throw _privateConstructorUsedError;
  DateTime? get expiresAt => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  String? get bodyText => throw _privateConstructorUsedError;
  Map<String, dynamic>? get bodyRichText => throw _privateConstructorUsedError;
  String? get themeId => throw _privateConstructorUsedError;
  String? get animationId => throw _privateConstructorUsedError;
  CapsuleStatus get status => throw _privateConstructorUsedError;
  DateTime? get deletedAt => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Capsule to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Capsule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CapsuleCopyWith<Capsule> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CapsuleCopyWith<$Res> {
  factory $CapsuleCopyWith(Capsule value, $Res Function(Capsule) then) =
      _$CapsuleCopyWithImpl<$Res, Capsule>;
  @useResult
  $Res call(
      {String id,
      String senderId,
      String? senderName,
      String? senderAvatarUrl,
      String recipientId,
      String? recipientName,
      bool isAnonymous,
      bool isDisappearing,
      int? disappearingAfterOpenSeconds,
      DateTime unlocksAt,
      DateTime? openedAt,
      DateTime? expiresAt,
      String? title,
      String? bodyText,
      Map<String, dynamic>? bodyRichText,
      String? themeId,
      String? animationId,
      CapsuleStatus status,
      DateTime? deletedAt,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$CapsuleCopyWithImpl<$Res, $Val extends Capsule>
    implements $CapsuleCopyWith<$Res> {
  _$CapsuleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Capsule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? senderId = null,
    Object? senderName = freezed,
    Object? senderAvatarUrl = freezed,
    Object? recipientId = null,
    Object? recipientName = freezed,
    Object? isAnonymous = null,
    Object? isDisappearing = null,
    Object? disappearingAfterOpenSeconds = freezed,
    Object? unlocksAt = null,
    Object? openedAt = freezed,
    Object? expiresAt = freezed,
    Object? title = freezed,
    Object? bodyText = freezed,
    Object? bodyRichText = freezed,
    Object? themeId = freezed,
    Object? animationId = freezed,
    Object? status = null,
    Object? deletedAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
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
      senderName: freezed == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String?,
      senderAvatarUrl: freezed == senderAvatarUrl
          ? _value.senderAvatarUrl
          : senderAvatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      recipientId: null == recipientId
          ? _value.recipientId
          : recipientId // ignore: cast_nullable_to_non_nullable
              as String,
      recipientName: freezed == recipientName
          ? _value.recipientName
          : recipientName // ignore: cast_nullable_to_non_nullable
              as String?,
      isAnonymous: null == isAnonymous
          ? _value.isAnonymous
          : isAnonymous // ignore: cast_nullable_to_non_nullable
              as bool,
      isDisappearing: null == isDisappearing
          ? _value.isDisappearing
          : isDisappearing // ignore: cast_nullable_to_non_nullable
              as bool,
      disappearingAfterOpenSeconds: freezed == disappearingAfterOpenSeconds
          ? _value.disappearingAfterOpenSeconds
          : disappearingAfterOpenSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      unlocksAt: null == unlocksAt
          ? _value.unlocksAt
          : unlocksAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      openedAt: freezed == openedAt
          ? _value.openedAt
          : openedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      bodyText: freezed == bodyText
          ? _value.bodyText
          : bodyText // ignore: cast_nullable_to_non_nullable
              as String?,
      bodyRichText: freezed == bodyRichText
          ? _value.bodyRichText
          : bodyRichText // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      themeId: freezed == themeId
          ? _value.themeId
          : themeId // ignore: cast_nullable_to_non_nullable
              as String?,
      animationId: freezed == animationId
          ? _value.animationId
          : animationId // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as CapsuleStatus,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CapsuleImplCopyWith<$Res> implements $CapsuleCopyWith<$Res> {
  factory _$$CapsuleImplCopyWith(
          _$CapsuleImpl value, $Res Function(_$CapsuleImpl) then) =
      __$$CapsuleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String senderId,
      String? senderName,
      String? senderAvatarUrl,
      String recipientId,
      String? recipientName,
      bool isAnonymous,
      bool isDisappearing,
      int? disappearingAfterOpenSeconds,
      DateTime unlocksAt,
      DateTime? openedAt,
      DateTime? expiresAt,
      String? title,
      String? bodyText,
      Map<String, dynamic>? bodyRichText,
      String? themeId,
      String? animationId,
      CapsuleStatus status,
      DateTime? deletedAt,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$$CapsuleImplCopyWithImpl<$Res>
    extends _$CapsuleCopyWithImpl<$Res, _$CapsuleImpl>
    implements _$$CapsuleImplCopyWith<$Res> {
  __$$CapsuleImplCopyWithImpl(
      _$CapsuleImpl _value, $Res Function(_$CapsuleImpl) _then)
      : super(_value, _then);

  /// Create a copy of Capsule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? senderId = null,
    Object? senderName = freezed,
    Object? senderAvatarUrl = freezed,
    Object? recipientId = null,
    Object? recipientName = freezed,
    Object? isAnonymous = null,
    Object? isDisappearing = null,
    Object? disappearingAfterOpenSeconds = freezed,
    Object? unlocksAt = null,
    Object? openedAt = freezed,
    Object? expiresAt = freezed,
    Object? title = freezed,
    Object? bodyText = freezed,
    Object? bodyRichText = freezed,
    Object? themeId = freezed,
    Object? animationId = freezed,
    Object? status = null,
    Object? deletedAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$CapsuleImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      senderName: freezed == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String?,
      senderAvatarUrl: freezed == senderAvatarUrl
          ? _value.senderAvatarUrl
          : senderAvatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      recipientId: null == recipientId
          ? _value.recipientId
          : recipientId // ignore: cast_nullable_to_non_nullable
              as String,
      recipientName: freezed == recipientName
          ? _value.recipientName
          : recipientName // ignore: cast_nullable_to_non_nullable
              as String?,
      isAnonymous: null == isAnonymous
          ? _value.isAnonymous
          : isAnonymous // ignore: cast_nullable_to_non_nullable
              as bool,
      isDisappearing: null == isDisappearing
          ? _value.isDisappearing
          : isDisappearing // ignore: cast_nullable_to_non_nullable
              as bool,
      disappearingAfterOpenSeconds: freezed == disappearingAfterOpenSeconds
          ? _value.disappearingAfterOpenSeconds
          : disappearingAfterOpenSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      unlocksAt: null == unlocksAt
          ? _value.unlocksAt
          : unlocksAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      openedAt: freezed == openedAt
          ? _value.openedAt
          : openedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      bodyText: freezed == bodyText
          ? _value.bodyText
          : bodyText // ignore: cast_nullable_to_non_nullable
              as String?,
      bodyRichText: freezed == bodyRichText
          ? _value._bodyRichText
          : bodyRichText // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      themeId: freezed == themeId
          ? _value.themeId
          : themeId // ignore: cast_nullable_to_non_nullable
              as String?,
      animationId: freezed == animationId
          ? _value.animationId
          : animationId // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as CapsuleStatus,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CapsuleImpl implements _Capsule {
  const _$CapsuleImpl(
      {required this.id,
      required this.senderId,
      this.senderName,
      this.senderAvatarUrl,
      required this.recipientId,
      this.recipientName,
      this.isAnonymous = false,
      this.isDisappearing = false,
      this.disappearingAfterOpenSeconds,
      required this.unlocksAt,
      this.openedAt,
      this.expiresAt,
      this.title,
      this.bodyText,
      final Map<String, dynamic>? bodyRichText,
      this.themeId,
      this.animationId,
      this.status = CapsuleStatus.sealed,
      this.deletedAt,
      required this.createdAt,
      required this.updatedAt})
      : _bodyRichText = bodyRichText;

  factory _$CapsuleImpl.fromJson(Map<String, dynamic> json) =>
      _$$CapsuleImplFromJson(json);

  @override
  final String id;
  @override
  final String senderId;
  @override
  final String? senderName;
  @override
  final String? senderAvatarUrl;
  @override
  final String recipientId;
  @override
  final String? recipientName;
  @override
  @JsonKey()
  final bool isAnonymous;
  @override
  @JsonKey()
  final bool isDisappearing;
  @override
  final int? disappearingAfterOpenSeconds;
  @override
  final DateTime unlocksAt;
  @override
  final DateTime? openedAt;
  @override
  final DateTime? expiresAt;
  @override
  final String? title;
  @override
  final String? bodyText;
  final Map<String, dynamic>? _bodyRichText;
  @override
  Map<String, dynamic>? get bodyRichText {
    final value = _bodyRichText;
    if (value == null) return null;
    if (_bodyRichText is EqualUnmodifiableMapView) return _bodyRichText;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final String? themeId;
  @override
  final String? animationId;
  @override
  @JsonKey()
  final CapsuleStatus status;
  @override
  final DateTime? deletedAt;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Capsule(id: $id, senderId: $senderId, senderName: $senderName, senderAvatarUrl: $senderAvatarUrl, recipientId: $recipientId, recipientName: $recipientName, isAnonymous: $isAnonymous, isDisappearing: $isDisappearing, disappearingAfterOpenSeconds: $disappearingAfterOpenSeconds, unlocksAt: $unlocksAt, openedAt: $openedAt, expiresAt: $expiresAt, title: $title, bodyText: $bodyText, bodyRichText: $bodyRichText, themeId: $themeId, animationId: $animationId, status: $status, deletedAt: $deletedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CapsuleImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.senderName, senderName) ||
                other.senderName == senderName) &&
            (identical(other.senderAvatarUrl, senderAvatarUrl) ||
                other.senderAvatarUrl == senderAvatarUrl) &&
            (identical(other.recipientId, recipientId) ||
                other.recipientId == recipientId) &&
            (identical(other.recipientName, recipientName) ||
                other.recipientName == recipientName) &&
            (identical(other.isAnonymous, isAnonymous) ||
                other.isAnonymous == isAnonymous) &&
            (identical(other.isDisappearing, isDisappearing) ||
                other.isDisappearing == isDisappearing) &&
            (identical(other.disappearingAfterOpenSeconds,
                    disappearingAfterOpenSeconds) ||
                other.disappearingAfterOpenSeconds ==
                    disappearingAfterOpenSeconds) &&
            (identical(other.unlocksAt, unlocksAt) ||
                other.unlocksAt == unlocksAt) &&
            (identical(other.openedAt, openedAt) ||
                other.openedAt == openedAt) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.bodyText, bodyText) ||
                other.bodyText == bodyText) &&
            const DeepCollectionEquality()
                .equals(other._bodyRichText, _bodyRichText) &&
            (identical(other.themeId, themeId) || other.themeId == themeId) &&
            (identical(other.animationId, animationId) ||
                other.animationId == animationId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        senderId,
        senderName,
        senderAvatarUrl,
        recipientId,
        recipientName,
        isAnonymous,
        isDisappearing,
        disappearingAfterOpenSeconds,
        unlocksAt,
        openedAt,
        expiresAt,
        title,
        bodyText,
        const DeepCollectionEquality().hash(_bodyRichText),
        themeId,
        animationId,
        status,
        deletedAt,
        createdAt,
        updatedAt
      ]);

  /// Create a copy of Capsule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CapsuleImplCopyWith<_$CapsuleImpl> get copyWith =>
      __$$CapsuleImplCopyWithImpl<_$CapsuleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CapsuleImplToJson(
      this,
    );
  }
}

abstract class _Capsule implements Capsule {
  const factory _Capsule(
      {required final String id,
      required final String senderId,
      final String? senderName,
      final String? senderAvatarUrl,
      required final String recipientId,
      final String? recipientName,
      final bool isAnonymous,
      final bool isDisappearing,
      final int? disappearingAfterOpenSeconds,
      required final DateTime unlocksAt,
      final DateTime? openedAt,
      final DateTime? expiresAt,
      final String? title,
      final String? bodyText,
      final Map<String, dynamic>? bodyRichText,
      final String? themeId,
      final String? animationId,
      final CapsuleStatus status,
      final DateTime? deletedAt,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$CapsuleImpl;

  factory _Capsule.fromJson(Map<String, dynamic> json) = _$CapsuleImpl.fromJson;

  @override
  String get id;
  @override
  String get senderId;
  @override
  String? get senderName;
  @override
  String? get senderAvatarUrl;
  @override
  String get recipientId;
  @override
  String? get recipientName;
  @override
  bool get isAnonymous;
  @override
  bool get isDisappearing;
  @override
  int? get disappearingAfterOpenSeconds;
  @override
  DateTime get unlocksAt;
  @override
  DateTime? get openedAt;
  @override
  DateTime? get expiresAt;
  @override
  String? get title;
  @override
  String? get bodyText;
  @override
  Map<String, dynamic>? get bodyRichText;
  @override
  String? get themeId;
  @override
  String? get animationId;
  @override
  CapsuleStatus get status;
  @override
  DateTime? get deletedAt;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of Capsule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CapsuleImplCopyWith<_$CapsuleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Notification _$NotificationFromJson(Map<String, dynamic> json) {
  return _Notification.fromJson(json);
}

/// @nodoc
mixin _$Notification {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  NotificationType get type => throw _privateConstructorUsedError;
  String? get capsuleId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;
  bool get delivered => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this Notification to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Notification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NotificationCopyWith<Notification> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationCopyWith<$Res> {
  factory $NotificationCopyWith(
          Notification value, $Res Function(Notification) then) =
      _$NotificationCopyWithImpl<$Res, Notification>;
  @useResult
  $Res call(
      {String id,
      String userId,
      NotificationType type,
      String? capsuleId,
      String title,
      String body,
      bool delivered,
      DateTime createdAt});
}

/// @nodoc
class _$NotificationCopyWithImpl<$Res, $Val extends Notification>
    implements $NotificationCopyWith<$Res> {
  _$NotificationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Notification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? type = null,
    Object? capsuleId = freezed,
    Object? title = null,
    Object? body = null,
    Object? delivered = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as NotificationType,
      capsuleId: freezed == capsuleId
          ? _value.capsuleId
          : capsuleId // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      delivered: null == delivered
          ? _value.delivered
          : delivered // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NotificationImplCopyWith<$Res>
    implements $NotificationCopyWith<$Res> {
  factory _$$NotificationImplCopyWith(
          _$NotificationImpl value, $Res Function(_$NotificationImpl) then) =
      __$$NotificationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      NotificationType type,
      String? capsuleId,
      String title,
      String body,
      bool delivered,
      DateTime createdAt});
}

/// @nodoc
class __$$NotificationImplCopyWithImpl<$Res>
    extends _$NotificationCopyWithImpl<$Res, _$NotificationImpl>
    implements _$$NotificationImplCopyWith<$Res> {
  __$$NotificationImplCopyWithImpl(
      _$NotificationImpl _value, $Res Function(_$NotificationImpl) _then)
      : super(_value, _then);

  /// Create a copy of Notification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? type = null,
    Object? capsuleId = freezed,
    Object? title = null,
    Object? body = null,
    Object? delivered = null,
    Object? createdAt = null,
  }) {
    return _then(_$NotificationImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as NotificationType,
      capsuleId: freezed == capsuleId
          ? _value.capsuleId
          : capsuleId // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      delivered: null == delivered
          ? _value.delivered
          : delivered // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NotificationImpl implements _Notification {
  const _$NotificationImpl(
      {required this.id,
      required this.userId,
      required this.type,
      this.capsuleId,
      required this.title,
      required this.body,
      this.delivered = false,
      required this.createdAt});

  factory _$NotificationImpl.fromJson(Map<String, dynamic> json) =>
      _$$NotificationImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final NotificationType type;
  @override
  final String? capsuleId;
  @override
  final String title;
  @override
  final String body;
  @override
  @JsonKey()
  final bool delivered;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'Notification(id: $id, userId: $userId, type: $type, capsuleId: $capsuleId, title: $title, body: $body, delivered: $delivered, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.capsuleId, capsuleId) ||
                other.capsuleId == capsuleId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.delivered, delivered) ||
                other.delivered == delivered) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, type, capsuleId,
      title, body, delivered, createdAt);

  /// Create a copy of Notification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationImplCopyWith<_$NotificationImpl> get copyWith =>
      __$$NotificationImplCopyWithImpl<_$NotificationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NotificationImplToJson(
      this,
    );
  }
}

abstract class _Notification implements Notification {
  const factory _Notification(
      {required final String id,
      required final String userId,
      required final NotificationType type,
      final String? capsuleId,
      required final String title,
      required final String body,
      final bool delivered,
      required final DateTime createdAt}) = _$NotificationImpl;

  factory _Notification.fromJson(Map<String, dynamic> json) =
      _$NotificationImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  NotificationType get type;
  @override
  String? get capsuleId;
  @override
  String get title;
  @override
  String get body;
  @override
  bool get delivered;
  @override
  DateTime get createdAt;

  /// Create a copy of Notification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotificationImplCopyWith<_$NotificationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserSubscription _$UserSubscriptionFromJson(Map<String, dynamic> json) {
  return _UserSubscription.fromJson(json);
}

/// @nodoc
mixin _$UserSubscription {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  SubscriptionStatus get status => throw _privateConstructorUsedError;
  String get provider => throw _privateConstructorUsedError;
  String get planId => throw _privateConstructorUsedError;
  String? get stripeSubscriptionId => throw _privateConstructorUsedError;
  DateTime get startedAt => throw _privateConstructorUsedError;
  DateTime get endsAt => throw _privateConstructorUsedError;
  bool get cancelAtPeriodEnd => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this UserSubscription to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserSubscription
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserSubscriptionCopyWith<UserSubscription> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserSubscriptionCopyWith<$Res> {
  factory $UserSubscriptionCopyWith(
          UserSubscription value, $Res Function(UserSubscription) then) =
      _$UserSubscriptionCopyWithImpl<$Res, UserSubscription>;
  @useResult
  $Res call(
      {String id,
      String userId,
      SubscriptionStatus status,
      String provider,
      String planId,
      String? stripeSubscriptionId,
      DateTime startedAt,
      DateTime endsAt,
      bool cancelAtPeriodEnd,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$UserSubscriptionCopyWithImpl<$Res, $Val extends UserSubscription>
    implements $UserSubscriptionCopyWith<$Res> {
  _$UserSubscriptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserSubscription
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? status = null,
    Object? provider = null,
    Object? planId = null,
    Object? stripeSubscriptionId = freezed,
    Object? startedAt = null,
    Object? endsAt = null,
    Object? cancelAtPeriodEnd = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as SubscriptionStatus,
      provider: null == provider
          ? _value.provider
          : provider // ignore: cast_nullable_to_non_nullable
              as String,
      planId: null == planId
          ? _value.planId
          : planId // ignore: cast_nullable_to_non_nullable
              as String,
      stripeSubscriptionId: freezed == stripeSubscriptionId
          ? _value.stripeSubscriptionId
          : stripeSubscriptionId // ignore: cast_nullable_to_non_nullable
              as String?,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endsAt: null == endsAt
          ? _value.endsAt
          : endsAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      cancelAtPeriodEnd: null == cancelAtPeriodEnd
          ? _value.cancelAtPeriodEnd
          : cancelAtPeriodEnd // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserSubscriptionImplCopyWith<$Res>
    implements $UserSubscriptionCopyWith<$Res> {
  factory _$$UserSubscriptionImplCopyWith(_$UserSubscriptionImpl value,
          $Res Function(_$UserSubscriptionImpl) then) =
      __$$UserSubscriptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      SubscriptionStatus status,
      String provider,
      String planId,
      String? stripeSubscriptionId,
      DateTime startedAt,
      DateTime endsAt,
      bool cancelAtPeriodEnd,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$$UserSubscriptionImplCopyWithImpl<$Res>
    extends _$UserSubscriptionCopyWithImpl<$Res, _$UserSubscriptionImpl>
    implements _$$UserSubscriptionImplCopyWith<$Res> {
  __$$UserSubscriptionImplCopyWithImpl(_$UserSubscriptionImpl _value,
      $Res Function(_$UserSubscriptionImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserSubscription
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? status = null,
    Object? provider = null,
    Object? planId = null,
    Object? stripeSubscriptionId = freezed,
    Object? startedAt = null,
    Object? endsAt = null,
    Object? cancelAtPeriodEnd = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$UserSubscriptionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as SubscriptionStatus,
      provider: null == provider
          ? _value.provider
          : provider // ignore: cast_nullable_to_non_nullable
              as String,
      planId: null == planId
          ? _value.planId
          : planId // ignore: cast_nullable_to_non_nullable
              as String,
      stripeSubscriptionId: freezed == stripeSubscriptionId
          ? _value.stripeSubscriptionId
          : stripeSubscriptionId // ignore: cast_nullable_to_non_nullable
              as String?,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endsAt: null == endsAt
          ? _value.endsAt
          : endsAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      cancelAtPeriodEnd: null == cancelAtPeriodEnd
          ? _value.cancelAtPeriodEnd
          : cancelAtPeriodEnd // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserSubscriptionImpl implements _UserSubscription {
  const _$UserSubscriptionImpl(
      {required this.id,
      required this.userId,
      required this.status,
      this.provider = 'stripe',
      required this.planId,
      this.stripeSubscriptionId,
      required this.startedAt,
      required this.endsAt,
      this.cancelAtPeriodEnd = false,
      required this.createdAt,
      required this.updatedAt});

  factory _$UserSubscriptionImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserSubscriptionImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final SubscriptionStatus status;
  @override
  @JsonKey()
  final String provider;
  @override
  final String planId;
  @override
  final String? stripeSubscriptionId;
  @override
  final DateTime startedAt;
  @override
  final DateTime endsAt;
  @override
  @JsonKey()
  final bool cancelAtPeriodEnd;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'UserSubscription(id: $id, userId: $userId, status: $status, provider: $provider, planId: $planId, stripeSubscriptionId: $stripeSubscriptionId, startedAt: $startedAt, endsAt: $endsAt, cancelAtPeriodEnd: $cancelAtPeriodEnd, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserSubscriptionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.provider, provider) ||
                other.provider == provider) &&
            (identical(other.planId, planId) || other.planId == planId) &&
            (identical(other.stripeSubscriptionId, stripeSubscriptionId) ||
                other.stripeSubscriptionId == stripeSubscriptionId) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.endsAt, endsAt) || other.endsAt == endsAt) &&
            (identical(other.cancelAtPeriodEnd, cancelAtPeriodEnd) ||
                other.cancelAtPeriodEnd == cancelAtPeriodEnd) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      status,
      provider,
      planId,
      stripeSubscriptionId,
      startedAt,
      endsAt,
      cancelAtPeriodEnd,
      createdAt,
      updatedAt);

  /// Create a copy of UserSubscription
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserSubscriptionImplCopyWith<_$UserSubscriptionImpl> get copyWith =>
      __$$UserSubscriptionImplCopyWithImpl<_$UserSubscriptionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserSubscriptionImplToJson(
      this,
    );
  }
}

abstract class _UserSubscription implements UserSubscription {
  const factory _UserSubscription(
      {required final String id,
      required final String userId,
      required final SubscriptionStatus status,
      final String provider,
      required final String planId,
      final String? stripeSubscriptionId,
      required final DateTime startedAt,
      required final DateTime endsAt,
      final bool cancelAtPeriodEnd,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$UserSubscriptionImpl;

  factory _UserSubscription.fromJson(Map<String, dynamic> json) =
      _$UserSubscriptionImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  SubscriptionStatus get status;
  @override
  String get provider;
  @override
  String get planId;
  @override
  String? get stripeSubscriptionId;
  @override
  DateTime get startedAt;
  @override
  DateTime get endsAt;
  @override
  bool get cancelAtPeriodEnd;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of UserSubscription
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserSubscriptionImplCopyWith<_$UserSubscriptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AuditLog _$AuditLogFromJson(Map<String, dynamic> json) {
  return _AuditLog.fromJson(json);
}

/// @nodoc
mixin _$AuditLog {
  String get id => throw _privateConstructorUsedError;
  String? get userId => throw _privateConstructorUsedError;
  String get action => throw _privateConstructorUsedError;
  String? get capsuleId => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this AuditLog to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AuditLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuditLogCopyWith<AuditLog> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuditLogCopyWith<$Res> {
  factory $AuditLogCopyWith(AuditLog value, $Res Function(AuditLog) then) =
      _$AuditLogCopyWithImpl<$Res, AuditLog>;
  @useResult
  $Res call(
      {String id,
      String? userId,
      String action,
      String? capsuleId,
      Map<String, dynamic>? metadata,
      DateTime createdAt});
}

/// @nodoc
class _$AuditLogCopyWithImpl<$Res, $Val extends AuditLog>
    implements $AuditLogCopyWith<$Res> {
  _$AuditLogCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuditLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = freezed,
    Object? action = null,
    Object? capsuleId = freezed,
    Object? metadata = freezed,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      action: null == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as String,
      capsuleId: freezed == capsuleId
          ? _value.capsuleId
          : capsuleId // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AuditLogImplCopyWith<$Res>
    implements $AuditLogCopyWith<$Res> {
  factory _$$AuditLogImplCopyWith(
          _$AuditLogImpl value, $Res Function(_$AuditLogImpl) then) =
      __$$AuditLogImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String? userId,
      String action,
      String? capsuleId,
      Map<String, dynamic>? metadata,
      DateTime createdAt});
}

/// @nodoc
class __$$AuditLogImplCopyWithImpl<$Res>
    extends _$AuditLogCopyWithImpl<$Res, _$AuditLogImpl>
    implements _$$AuditLogImplCopyWith<$Res> {
  __$$AuditLogImplCopyWithImpl(
      _$AuditLogImpl _value, $Res Function(_$AuditLogImpl) _then)
      : super(_value, _then);

  /// Create a copy of AuditLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = freezed,
    Object? action = null,
    Object? capsuleId = freezed,
    Object? metadata = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$AuditLogImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      action: null == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as String,
      capsuleId: freezed == capsuleId
          ? _value.capsuleId
          : capsuleId // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AuditLogImpl implements _AuditLog {
  const _$AuditLogImpl(
      {required this.id,
      this.userId,
      required this.action,
      this.capsuleId,
      final Map<String, dynamic>? metadata,
      required this.createdAt})
      : _metadata = metadata;

  factory _$AuditLogImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuditLogImplFromJson(json);

  @override
  final String id;
  @override
  final String? userId;
  @override
  final String action;
  @override
  final String? capsuleId;
  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'AuditLog(id: $id, userId: $userId, action: $action, capsuleId: $capsuleId, metadata: $metadata, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuditLogImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.capsuleId, capsuleId) ||
                other.capsuleId == capsuleId) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, action, capsuleId,
      const DeepCollectionEquality().hash(_metadata), createdAt);

  /// Create a copy of AuditLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuditLogImplCopyWith<_$AuditLogImpl> get copyWith =>
      __$$AuditLogImplCopyWithImpl<_$AuditLogImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AuditLogImplToJson(
      this,
    );
  }
}

abstract class _AuditLog implements AuditLog {
  const factory _AuditLog(
      {required final String id,
      final String? userId,
      required final String action,
      final String? capsuleId,
      final Map<String, dynamic>? metadata,
      required final DateTime createdAt}) = _$AuditLogImpl;

  factory _AuditLog.fromJson(Map<String, dynamic> json) =
      _$AuditLogImpl.fromJson;

  @override
  String get id;
  @override
  String? get userId;
  @override
  String get action;
  @override
  String? get capsuleId;
  @override
  Map<String, dynamic>? get metadata;
  @override
  DateTime get createdAt;

  /// Create a copy of AuditLog
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuditLogImplCopyWith<_$AuditLogImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CreateCapsuleRequest _$CreateCapsuleRequestFromJson(Map<String, dynamic> json) {
  return _CreateCapsuleRequest.fromJson(json);
}

/// @nodoc
mixin _$CreateCapsuleRequest {
  String get recipientId => throw _privateConstructorUsedError;
  bool get isAnonymous => throw _privateConstructorUsedError;
  bool get isDisappearing => throw _privateConstructorUsedError;
  int? get disappearingAfterOpenSeconds => throw _privateConstructorUsedError;
  DateTime get unlocksAt => throw _privateConstructorUsedError;
  DateTime? get expiresAt => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  String? get bodyText => throw _privateConstructorUsedError;
  Map<String, dynamic>? get bodyRichText => throw _privateConstructorUsedError;
  String? get themeId => throw _privateConstructorUsedError;
  String? get animationId => throw _privateConstructorUsedError;

  /// Serializes this CreateCapsuleRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreateCapsuleRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreateCapsuleRequestCopyWith<CreateCapsuleRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreateCapsuleRequestCopyWith<$Res> {
  factory $CreateCapsuleRequestCopyWith(CreateCapsuleRequest value,
          $Res Function(CreateCapsuleRequest) then) =
      _$CreateCapsuleRequestCopyWithImpl<$Res, CreateCapsuleRequest>;
  @useResult
  $Res call(
      {String recipientId,
      bool isAnonymous,
      bool isDisappearing,
      int? disappearingAfterOpenSeconds,
      DateTime unlocksAt,
      DateTime? expiresAt,
      String? title,
      String? bodyText,
      Map<String, dynamic>? bodyRichText,
      String? themeId,
      String? animationId});
}

/// @nodoc
class _$CreateCapsuleRequestCopyWithImpl<$Res,
        $Val extends CreateCapsuleRequest>
    implements $CreateCapsuleRequestCopyWith<$Res> {
  _$CreateCapsuleRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreateCapsuleRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recipientId = null,
    Object? isAnonymous = null,
    Object? isDisappearing = null,
    Object? disappearingAfterOpenSeconds = freezed,
    Object? unlocksAt = null,
    Object? expiresAt = freezed,
    Object? title = freezed,
    Object? bodyText = freezed,
    Object? bodyRichText = freezed,
    Object? themeId = freezed,
    Object? animationId = freezed,
  }) {
    return _then(_value.copyWith(
      recipientId: null == recipientId
          ? _value.recipientId
          : recipientId // ignore: cast_nullable_to_non_nullable
              as String,
      isAnonymous: null == isAnonymous
          ? _value.isAnonymous
          : isAnonymous // ignore: cast_nullable_to_non_nullable
              as bool,
      isDisappearing: null == isDisappearing
          ? _value.isDisappearing
          : isDisappearing // ignore: cast_nullable_to_non_nullable
              as bool,
      disappearingAfterOpenSeconds: freezed == disappearingAfterOpenSeconds
          ? _value.disappearingAfterOpenSeconds
          : disappearingAfterOpenSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      unlocksAt: null == unlocksAt
          ? _value.unlocksAt
          : unlocksAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      bodyText: freezed == bodyText
          ? _value.bodyText
          : bodyText // ignore: cast_nullable_to_non_nullable
              as String?,
      bodyRichText: freezed == bodyRichText
          ? _value.bodyRichText
          : bodyRichText // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      themeId: freezed == themeId
          ? _value.themeId
          : themeId // ignore: cast_nullable_to_non_nullable
              as String?,
      animationId: freezed == animationId
          ? _value.animationId
          : animationId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CreateCapsuleRequestImplCopyWith<$Res>
    implements $CreateCapsuleRequestCopyWith<$Res> {
  factory _$$CreateCapsuleRequestImplCopyWith(_$CreateCapsuleRequestImpl value,
          $Res Function(_$CreateCapsuleRequestImpl) then) =
      __$$CreateCapsuleRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String recipientId,
      bool isAnonymous,
      bool isDisappearing,
      int? disappearingAfterOpenSeconds,
      DateTime unlocksAt,
      DateTime? expiresAt,
      String? title,
      String? bodyText,
      Map<String, dynamic>? bodyRichText,
      String? themeId,
      String? animationId});
}

/// @nodoc
class __$$CreateCapsuleRequestImplCopyWithImpl<$Res>
    extends _$CreateCapsuleRequestCopyWithImpl<$Res, _$CreateCapsuleRequestImpl>
    implements _$$CreateCapsuleRequestImplCopyWith<$Res> {
  __$$CreateCapsuleRequestImplCopyWithImpl(_$CreateCapsuleRequestImpl _value,
      $Res Function(_$CreateCapsuleRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of CreateCapsuleRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recipientId = null,
    Object? isAnonymous = null,
    Object? isDisappearing = null,
    Object? disappearingAfterOpenSeconds = freezed,
    Object? unlocksAt = null,
    Object? expiresAt = freezed,
    Object? title = freezed,
    Object? bodyText = freezed,
    Object? bodyRichText = freezed,
    Object? themeId = freezed,
    Object? animationId = freezed,
  }) {
    return _then(_$CreateCapsuleRequestImpl(
      recipientId: null == recipientId
          ? _value.recipientId
          : recipientId // ignore: cast_nullable_to_non_nullable
              as String,
      isAnonymous: null == isAnonymous
          ? _value.isAnonymous
          : isAnonymous // ignore: cast_nullable_to_non_nullable
              as bool,
      isDisappearing: null == isDisappearing
          ? _value.isDisappearing
          : isDisappearing // ignore: cast_nullable_to_non_nullable
              as bool,
      disappearingAfterOpenSeconds: freezed == disappearingAfterOpenSeconds
          ? _value.disappearingAfterOpenSeconds
          : disappearingAfterOpenSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      unlocksAt: null == unlocksAt
          ? _value.unlocksAt
          : unlocksAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      bodyText: freezed == bodyText
          ? _value.bodyText
          : bodyText // ignore: cast_nullable_to_non_nullable
              as String?,
      bodyRichText: freezed == bodyRichText
          ? _value._bodyRichText
          : bodyRichText // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      themeId: freezed == themeId
          ? _value.themeId
          : themeId // ignore: cast_nullable_to_non_nullable
              as String?,
      animationId: freezed == animationId
          ? _value.animationId
          : animationId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CreateCapsuleRequestImpl implements _CreateCapsuleRequest {
  const _$CreateCapsuleRequestImpl(
      {required this.recipientId,
      this.isAnonymous = false,
      this.isDisappearing = false,
      this.disappearingAfterOpenSeconds,
      required this.unlocksAt,
      this.expiresAt,
      this.title,
      this.bodyText,
      final Map<String, dynamic>? bodyRichText,
      this.themeId,
      this.animationId})
      : _bodyRichText = bodyRichText;

  factory _$CreateCapsuleRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreateCapsuleRequestImplFromJson(json);

  @override
  final String recipientId;
  @override
  @JsonKey()
  final bool isAnonymous;
  @override
  @JsonKey()
  final bool isDisappearing;
  @override
  final int? disappearingAfterOpenSeconds;
  @override
  final DateTime unlocksAt;
  @override
  final DateTime? expiresAt;
  @override
  final String? title;
  @override
  final String? bodyText;
  final Map<String, dynamic>? _bodyRichText;
  @override
  Map<String, dynamic>? get bodyRichText {
    final value = _bodyRichText;
    if (value == null) return null;
    if (_bodyRichText is EqualUnmodifiableMapView) return _bodyRichText;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final String? themeId;
  @override
  final String? animationId;

  @override
  String toString() {
    return 'CreateCapsuleRequest(recipientId: $recipientId, isAnonymous: $isAnonymous, isDisappearing: $isDisappearing, disappearingAfterOpenSeconds: $disappearingAfterOpenSeconds, unlocksAt: $unlocksAt, expiresAt: $expiresAt, title: $title, bodyText: $bodyText, bodyRichText: $bodyRichText, themeId: $themeId, animationId: $animationId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreateCapsuleRequestImpl &&
            (identical(other.recipientId, recipientId) ||
                other.recipientId == recipientId) &&
            (identical(other.isAnonymous, isAnonymous) ||
                other.isAnonymous == isAnonymous) &&
            (identical(other.isDisappearing, isDisappearing) ||
                other.isDisappearing == isDisappearing) &&
            (identical(other.disappearingAfterOpenSeconds,
                    disappearingAfterOpenSeconds) ||
                other.disappearingAfterOpenSeconds ==
                    disappearingAfterOpenSeconds) &&
            (identical(other.unlocksAt, unlocksAt) ||
                other.unlocksAt == unlocksAt) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.bodyText, bodyText) ||
                other.bodyText == bodyText) &&
            const DeepCollectionEquality()
                .equals(other._bodyRichText, _bodyRichText) &&
            (identical(other.themeId, themeId) || other.themeId == themeId) &&
            (identical(other.animationId, animationId) ||
                other.animationId == animationId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      recipientId,
      isAnonymous,
      isDisappearing,
      disappearingAfterOpenSeconds,
      unlocksAt,
      expiresAt,
      title,
      bodyText,
      const DeepCollectionEquality().hash(_bodyRichText),
      themeId,
      animationId);

  /// Create a copy of CreateCapsuleRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreateCapsuleRequestImplCopyWith<_$CreateCapsuleRequestImpl>
      get copyWith =>
          __$$CreateCapsuleRequestImplCopyWithImpl<_$CreateCapsuleRequestImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CreateCapsuleRequestImplToJson(
      this,
    );
  }
}

abstract class _CreateCapsuleRequest implements CreateCapsuleRequest {
  const factory _CreateCapsuleRequest(
      {required final String recipientId,
      final bool isAnonymous,
      final bool isDisappearing,
      final int? disappearingAfterOpenSeconds,
      required final DateTime unlocksAt,
      final DateTime? expiresAt,
      final String? title,
      final String? bodyText,
      final Map<String, dynamic>? bodyRichText,
      final String? themeId,
      final String? animationId}) = _$CreateCapsuleRequestImpl;

  factory _CreateCapsuleRequest.fromJson(Map<String, dynamic> json) =
      _$CreateCapsuleRequestImpl.fromJson;

  @override
  String get recipientId;
  @override
  bool get isAnonymous;
  @override
  bool get isDisappearing;
  @override
  int? get disappearingAfterOpenSeconds;
  @override
  DateTime get unlocksAt;
  @override
  DateTime? get expiresAt;
  @override
  String? get title;
  @override
  String? get bodyText;
  @override
  Map<String, dynamic>? get bodyRichText;
  @override
  String? get themeId;
  @override
  String? get animationId;

  /// Create a copy of CreateCapsuleRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreateCapsuleRequestImplCopyWith<_$CreateCapsuleRequestImpl>
      get copyWith => throw _privateConstructorUsedError;
}

UpdateCapsuleRequest _$UpdateCapsuleRequestFromJson(Map<String, dynamic> json) {
  return _UpdateCapsuleRequest.fromJson(json);
}

/// @nodoc
mixin _$UpdateCapsuleRequest {
  String? get title => throw _privateConstructorUsedError;
  String? get bodyText => throw _privateConstructorUsedError;
  Map<String, dynamic>? get bodyRichText => throw _privateConstructorUsedError;
  String? get themeId => throw _privateConstructorUsedError;
  String? get animationId => throw _privateConstructorUsedError;

  /// Serializes this UpdateCapsuleRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UpdateCapsuleRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UpdateCapsuleRequestCopyWith<UpdateCapsuleRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UpdateCapsuleRequestCopyWith<$Res> {
  factory $UpdateCapsuleRequestCopyWith(UpdateCapsuleRequest value,
          $Res Function(UpdateCapsuleRequest) then) =
      _$UpdateCapsuleRequestCopyWithImpl<$Res, UpdateCapsuleRequest>;
  @useResult
  $Res call(
      {String? title,
      String? bodyText,
      Map<String, dynamic>? bodyRichText,
      String? themeId,
      String? animationId});
}

/// @nodoc
class _$UpdateCapsuleRequestCopyWithImpl<$Res,
        $Val extends UpdateCapsuleRequest>
    implements $UpdateCapsuleRequestCopyWith<$Res> {
  _$UpdateCapsuleRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UpdateCapsuleRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = freezed,
    Object? bodyText = freezed,
    Object? bodyRichText = freezed,
    Object? themeId = freezed,
    Object? animationId = freezed,
  }) {
    return _then(_value.copyWith(
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      bodyText: freezed == bodyText
          ? _value.bodyText
          : bodyText // ignore: cast_nullable_to_non_nullable
              as String?,
      bodyRichText: freezed == bodyRichText
          ? _value.bodyRichText
          : bodyRichText // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      themeId: freezed == themeId
          ? _value.themeId
          : themeId // ignore: cast_nullable_to_non_nullable
              as String?,
      animationId: freezed == animationId
          ? _value.animationId
          : animationId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UpdateCapsuleRequestImplCopyWith<$Res>
    implements $UpdateCapsuleRequestCopyWith<$Res> {
  factory _$$UpdateCapsuleRequestImplCopyWith(_$UpdateCapsuleRequestImpl value,
          $Res Function(_$UpdateCapsuleRequestImpl) then) =
      __$$UpdateCapsuleRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? title,
      String? bodyText,
      Map<String, dynamic>? bodyRichText,
      String? themeId,
      String? animationId});
}

/// @nodoc
class __$$UpdateCapsuleRequestImplCopyWithImpl<$Res>
    extends _$UpdateCapsuleRequestCopyWithImpl<$Res, _$UpdateCapsuleRequestImpl>
    implements _$$UpdateCapsuleRequestImplCopyWith<$Res> {
  __$$UpdateCapsuleRequestImplCopyWithImpl(_$UpdateCapsuleRequestImpl _value,
      $Res Function(_$UpdateCapsuleRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of UpdateCapsuleRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = freezed,
    Object? bodyText = freezed,
    Object? bodyRichText = freezed,
    Object? themeId = freezed,
    Object? animationId = freezed,
  }) {
    return _then(_$UpdateCapsuleRequestImpl(
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      bodyText: freezed == bodyText
          ? _value.bodyText
          : bodyText // ignore: cast_nullable_to_non_nullable
              as String?,
      bodyRichText: freezed == bodyRichText
          ? _value._bodyRichText
          : bodyRichText // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      themeId: freezed == themeId
          ? _value.themeId
          : themeId // ignore: cast_nullable_to_non_nullable
              as String?,
      animationId: freezed == animationId
          ? _value.animationId
          : animationId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UpdateCapsuleRequestImpl implements _UpdateCapsuleRequest {
  const _$UpdateCapsuleRequestImpl(
      {this.title,
      this.bodyText,
      final Map<String, dynamic>? bodyRichText,
      this.themeId,
      this.animationId})
      : _bodyRichText = bodyRichText;

  factory _$UpdateCapsuleRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$UpdateCapsuleRequestImplFromJson(json);

  @override
  final String? title;
  @override
  final String? bodyText;
  final Map<String, dynamic>? _bodyRichText;
  @override
  Map<String, dynamic>? get bodyRichText {
    final value = _bodyRichText;
    if (value == null) return null;
    if (_bodyRichText is EqualUnmodifiableMapView) return _bodyRichText;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final String? themeId;
  @override
  final String? animationId;

  @override
  String toString() {
    return 'UpdateCapsuleRequest(title: $title, bodyText: $bodyText, bodyRichText: $bodyRichText, themeId: $themeId, animationId: $animationId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateCapsuleRequestImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.bodyText, bodyText) ||
                other.bodyText == bodyText) &&
            const DeepCollectionEquality()
                .equals(other._bodyRichText, _bodyRichText) &&
            (identical(other.themeId, themeId) || other.themeId == themeId) &&
            (identical(other.animationId, animationId) ||
                other.animationId == animationId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, title, bodyText,
      const DeepCollectionEquality().hash(_bodyRichText), themeId, animationId);

  /// Create a copy of UpdateCapsuleRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateCapsuleRequestImplCopyWith<_$UpdateCapsuleRequestImpl>
      get copyWith =>
          __$$UpdateCapsuleRequestImplCopyWithImpl<_$UpdateCapsuleRequestImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UpdateCapsuleRequestImplToJson(
      this,
    );
  }
}

abstract class _UpdateCapsuleRequest implements UpdateCapsuleRequest {
  const factory _UpdateCapsuleRequest(
      {final String? title,
      final String? bodyText,
      final Map<String, dynamic>? bodyRichText,
      final String? themeId,
      final String? animationId}) = _$UpdateCapsuleRequestImpl;

  factory _UpdateCapsuleRequest.fromJson(Map<String, dynamic> json) =
      _$UpdateCapsuleRequestImpl.fromJson;

  @override
  String? get title;
  @override
  String? get bodyText;
  @override
  Map<String, dynamic>? get bodyRichText;
  @override
  String? get themeId;
  @override
  String? get animationId;

  /// Create a copy of UpdateCapsuleRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdateCapsuleRequestImplCopyWith<_$UpdateCapsuleRequestImpl>
      get copyWith => throw _privateConstructorUsedError;
}

CreateRecipientRequest _$CreateRecipientRequestFromJson(
    Map<String, dynamic> json) {
  return _CreateRecipientRequest.fromJson(json);
}

/// @nodoc
mixin _$CreateRecipientRequest {
  String get name => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;

  /// Serializes this CreateRecipientRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreateRecipientRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreateRecipientRequestCopyWith<CreateRecipientRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreateRecipientRequestCopyWith<$Res> {
  factory $CreateRecipientRequestCopyWith(CreateRecipientRequest value,
          $Res Function(CreateRecipientRequest) then) =
      _$CreateRecipientRequestCopyWithImpl<$Res, CreateRecipientRequest>;
  @useResult
  $Res call({String name, String? email, String? avatarUrl});
}

/// @nodoc
class _$CreateRecipientRequestCopyWithImpl<$Res,
        $Val extends CreateRecipientRequest>
    implements $CreateRecipientRequestCopyWith<$Res> {
  _$CreateRecipientRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreateRecipientRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? email = freezed,
    Object? avatarUrl = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CreateRecipientRequestImplCopyWith<$Res>
    implements $CreateRecipientRequestCopyWith<$Res> {
  factory _$$CreateRecipientRequestImplCopyWith(
          _$CreateRecipientRequestImpl value,
          $Res Function(_$CreateRecipientRequestImpl) then) =
      __$$CreateRecipientRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, String? email, String? avatarUrl});
}

/// @nodoc
class __$$CreateRecipientRequestImplCopyWithImpl<$Res>
    extends _$CreateRecipientRequestCopyWithImpl<$Res,
        _$CreateRecipientRequestImpl>
    implements _$$CreateRecipientRequestImplCopyWith<$Res> {
  __$$CreateRecipientRequestImplCopyWithImpl(
      _$CreateRecipientRequestImpl _value,
      $Res Function(_$CreateRecipientRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of CreateRecipientRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? email = freezed,
    Object? avatarUrl = freezed,
  }) {
    return _then(_$CreateRecipientRequestImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CreateRecipientRequestImpl implements _CreateRecipientRequest {
  const _$CreateRecipientRequestImpl(
      {required this.name, this.email, this.avatarUrl});

  factory _$CreateRecipientRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreateRecipientRequestImplFromJson(json);

  @override
  final String name;
  @override
  final String? email;
  @override
  final String? avatarUrl;

  @override
  String toString() {
    return 'CreateRecipientRequest(name: $name, email: $email, avatarUrl: $avatarUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreateRecipientRequestImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, email, avatarUrl);

  /// Create a copy of CreateRecipientRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreateRecipientRequestImplCopyWith<_$CreateRecipientRequestImpl>
      get copyWith => __$$CreateRecipientRequestImplCopyWithImpl<
          _$CreateRecipientRequestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CreateRecipientRequestImplToJson(
      this,
    );
  }
}

abstract class _CreateRecipientRequest implements CreateRecipientRequest {
  const factory _CreateRecipientRequest(
      {required final String name,
      final String? email,
      final String? avatarUrl}) = _$CreateRecipientRequestImpl;

  factory _CreateRecipientRequest.fromJson(Map<String, dynamic> json) =
      _$CreateRecipientRequestImpl.fromJson;

  @override
  String get name;
  @override
  String? get email;
  @override
  String? get avatarUrl;

  /// Create a copy of CreateRecipientRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreateRecipientRequestImplCopyWith<_$CreateRecipientRequestImpl>
      get copyWith => throw _privateConstructorUsedError;
}

UpdateUserProfileRequest _$UpdateUserProfileRequestFromJson(
    Map<String, dynamic> json) {
  return _UpdateUserProfileRequest.fromJson(json);
}

/// @nodoc
mixin _$UpdateUserProfileRequest {
  String? get fullName => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  String? get country => throw _privateConstructorUsedError;
  String? get deviceToken => throw _privateConstructorUsedError;

  /// Serializes this UpdateUserProfileRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UpdateUserProfileRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UpdateUserProfileRequestCopyWith<UpdateUserProfileRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UpdateUserProfileRequestCopyWith<$Res> {
  factory $UpdateUserProfileRequestCopyWith(UpdateUserProfileRequest value,
          $Res Function(UpdateUserProfileRequest) then) =
      _$UpdateUserProfileRequestCopyWithImpl<$Res, UpdateUserProfileRequest>;
  @useResult
  $Res call(
      {String? fullName,
      String? avatarUrl,
      String? country,
      String? deviceToken});
}

/// @nodoc
class _$UpdateUserProfileRequestCopyWithImpl<$Res,
        $Val extends UpdateUserProfileRequest>
    implements $UpdateUserProfileRequestCopyWith<$Res> {
  _$UpdateUserProfileRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UpdateUserProfileRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fullName = freezed,
    Object? avatarUrl = freezed,
    Object? country = freezed,
    Object? deviceToken = freezed,
  }) {
    return _then(_value.copyWith(
      fullName: freezed == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      deviceToken: freezed == deviceToken
          ? _value.deviceToken
          : deviceToken // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UpdateUserProfileRequestImplCopyWith<$Res>
    implements $UpdateUserProfileRequestCopyWith<$Res> {
  factory _$$UpdateUserProfileRequestImplCopyWith(
          _$UpdateUserProfileRequestImpl value,
          $Res Function(_$UpdateUserProfileRequestImpl) then) =
      __$$UpdateUserProfileRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? fullName,
      String? avatarUrl,
      String? country,
      String? deviceToken});
}

/// @nodoc
class __$$UpdateUserProfileRequestImplCopyWithImpl<$Res>
    extends _$UpdateUserProfileRequestCopyWithImpl<$Res,
        _$UpdateUserProfileRequestImpl>
    implements _$$UpdateUserProfileRequestImplCopyWith<$Res> {
  __$$UpdateUserProfileRequestImplCopyWithImpl(
      _$UpdateUserProfileRequestImpl _value,
      $Res Function(_$UpdateUserProfileRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of UpdateUserProfileRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fullName = freezed,
    Object? avatarUrl = freezed,
    Object? country = freezed,
    Object? deviceToken = freezed,
  }) {
    return _then(_$UpdateUserProfileRequestImpl(
      fullName: freezed == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      deviceToken: freezed == deviceToken
          ? _value.deviceToken
          : deviceToken // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UpdateUserProfileRequestImpl implements _UpdateUserProfileRequest {
  const _$UpdateUserProfileRequestImpl(
      {this.fullName, this.avatarUrl, this.country, this.deviceToken});

  factory _$UpdateUserProfileRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$UpdateUserProfileRequestImplFromJson(json);

  @override
  final String? fullName;
  @override
  final String? avatarUrl;
  @override
  final String? country;
  @override
  final String? deviceToken;

  @override
  String toString() {
    return 'UpdateUserProfileRequest(fullName: $fullName, avatarUrl: $avatarUrl, country: $country, deviceToken: $deviceToken)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateUserProfileRequestImpl &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.deviceToken, deviceToken) ||
                other.deviceToken == deviceToken));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, fullName, avatarUrl, country, deviceToken);

  /// Create a copy of UpdateUserProfileRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateUserProfileRequestImplCopyWith<_$UpdateUserProfileRequestImpl>
      get copyWith => __$$UpdateUserProfileRequestImplCopyWithImpl<
          _$UpdateUserProfileRequestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UpdateUserProfileRequestImplToJson(
      this,
    );
  }
}

abstract class _UpdateUserProfileRequest implements UpdateUserProfileRequest {
  const factory _UpdateUserProfileRequest(
      {final String? fullName,
      final String? avatarUrl,
      final String? country,
      final String? deviceToken}) = _$UpdateUserProfileRequestImpl;

  factory _UpdateUserProfileRequest.fromJson(Map<String, dynamic> json) =
      _$UpdateUserProfileRequestImpl.fromJson;

  @override
  String? get fullName;
  @override
  String? get avatarUrl;
  @override
  String? get country;
  @override
  String? get deviceToken;

  /// Create a copy of UpdateUserProfileRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdateUserProfileRequestImplCopyWith<_$UpdateUserProfileRequestImpl>
      get copyWith => throw _privateConstructorUsedError;
}
