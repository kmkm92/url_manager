// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'url_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Url {
  int? get id => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  String get details => throw _privateConstructorUsedError;
  DateTime get savedAt => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $UrlCopyWith<Url> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UrlCopyWith<$Res> {
  factory $UrlCopyWith(Url value, $Res Function(Url) then) =
      _$UrlCopyWithImpl<$Res, Url>;
  @useResult
  $Res call(
      {int? id, String message, String url, String details, DateTime savedAt});
}

/// @nodoc
class _$UrlCopyWithImpl<$Res, $Val extends Url> implements $UrlCopyWith<$Res> {
  _$UrlCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? message = null,
    Object? url = null,
    Object? details = null,
    Object? savedAt = null,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      details: null == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as String,
      savedAt: null == savedAt
          ? _value.savedAt
          : savedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UrlImplCopyWith<$Res> implements $UrlCopyWith<$Res> {
  factory _$$UrlImplCopyWith(_$UrlImpl value, $Res Function(_$UrlImpl) then) =
      __$$UrlImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int? id, String message, String url, String details, DateTime savedAt});
}

/// @nodoc
class __$$UrlImplCopyWithImpl<$Res> extends _$UrlCopyWithImpl<$Res, _$UrlImpl>
    implements _$$UrlImplCopyWith<$Res> {
  __$$UrlImplCopyWithImpl(_$UrlImpl _value, $Res Function(_$UrlImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? message = null,
    Object? url = null,
    Object? details = null,
    Object? savedAt = null,
  }) {
    return _then(_$UrlImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      details: null == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as String,
      savedAt: null == savedAt
          ? _value.savedAt
          : savedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

class _$UrlImpl implements _Url {
  const _$UrlImpl(
      {required this.id,
      required this.message,
      required this.url,
      required this.details,
      required this.savedAt});

  @override
  final int? id;
  @override
  final String message;
  @override
  final String url;
  @override
  final String details;
  @override
  final DateTime savedAt;

  @override
  String toString() {
    return 'Url(id: $id, message: $message, url: $url, details: $details, savedAt: $savedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UrlImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.details, details) || other.details == details) &&
            (identical(other.savedAt, savedAt) || other.savedAt == savedAt));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, message, url, details, savedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UrlImplCopyWith<_$UrlImpl> get copyWith =>
      __$$UrlImplCopyWithImpl<_$UrlImpl>(this, _$identity);
}

abstract class _Url implements Url {
  const factory _Url(
      {required final int? id,
      required final String message,
      required final String url,
      required final String details,
      required final DateTime savedAt}) = _$UrlImpl;

  @override
  int? get id;
  @override
  String get message;
  @override
  String get url;
  @override
  String get details;
  @override
  DateTime get savedAt;
  @override
  @JsonKey(ignore: true)
  _$$UrlImplCopyWith<_$UrlImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
