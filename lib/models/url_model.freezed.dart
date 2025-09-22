// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'url_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UrlItem {
  int? get id;
  String get message;
  String get url;
  String get details;
  DateTime get savedAt;

  /// Create a copy of UrlItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UrlItemCopyWith<UrlItem> get copyWith =>
      _$UrlItemCopyWithImpl<UrlItem>(this as UrlItem, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UrlItem &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.details, details) || other.details == details) &&
            (identical(other.savedAt, savedAt) || other.savedAt == savedAt));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, message, url, details, savedAt);

  @override
  String toString() {
    return 'UrlItem(id: $id, message: $message, url: $url, details: $details, savedAt: $savedAt)';
  }
}

/// @nodoc
abstract mixin class $UrlItemCopyWith<$Res> {
  factory $UrlItemCopyWith(UrlItem value, $Res Function(UrlItem) _then) =
      _$UrlItemCopyWithImpl;
  @useResult
  $Res call(
      {int? id, String message, String url, String details, DateTime savedAt});
}

/// @nodoc
class _$UrlItemCopyWithImpl<$Res> implements $UrlItemCopyWith<$Res> {
  _$UrlItemCopyWithImpl(this._self, this._then);

  final UrlItem _self;
  final $Res Function(UrlItem) _then;

  /// Create a copy of UrlItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? message = null,
    Object? url = null,
    Object? details = null,
    Object? savedAt = null,
  }) {
    return _then(_self.copyWith(
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      details: null == details
          ? _self.details
          : details // ignore: cast_nullable_to_non_nullable
              as String,
      savedAt: null == savedAt
          ? _self.savedAt
          : savedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [UrlItem].
extension UrlItemPatterns on UrlItem {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_UrlItem value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UrlItem() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_UrlItem value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UrlItem():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_UrlItem value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UrlItem() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(int? id, String message, String url, String details,
            DateTime savedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _UrlItem() when $default != null:
        return $default(
            _that.id, _that.message, _that.url, _that.details, _that.savedAt);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(int? id, String message, String url, String details,
            DateTime savedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UrlItem():
        return $default(
            _that.id, _that.message, _that.url, _that.details, _that.savedAt);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(int? id, String message, String url, String details,
            DateTime savedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _UrlItem() when $default != null:
        return $default(
            _that.id, _that.message, _that.url, _that.details, _that.savedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _UrlItem implements UrlItem {
  const _UrlItem(
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

  /// Create a copy of UrlItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$UrlItemCopyWith<_UrlItem> get copyWith =>
      __$UrlItemCopyWithImpl<_UrlItem>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _UrlItem &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.details, details) || other.details == details) &&
            (identical(other.savedAt, savedAt) || other.savedAt == savedAt));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, message, url, details, savedAt);

  @override
  String toString() {
    return 'UrlItem(id: $id, message: $message, url: $url, details: $details, savedAt: $savedAt)';
  }
}

/// @nodoc
abstract mixin class _$UrlItemCopyWith<$Res> implements $UrlItemCopyWith<$Res> {
  factory _$UrlItemCopyWith(_UrlItem value, $Res Function(_UrlItem) _then) =
      __$UrlItemCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int? id, String message, String url, String details, DateTime savedAt});
}

/// @nodoc
class __$UrlItemCopyWithImpl<$Res> implements _$UrlItemCopyWith<$Res> {
  __$UrlItemCopyWithImpl(this._self, this._then);

  final _UrlItem _self;
  final $Res Function(_UrlItem) _then;

  /// Create a copy of UrlItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = freezed,
    Object? message = null,
    Object? url = null,
    Object? details = null,
    Object? savedAt = null,
  }) {
    return _then(_UrlItem(
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      details: null == details
          ? _self.details
          : details // ignore: cast_nullable_to_non_nullable
              as String,
      savedAt: null == savedAt
          ? _self.savedAt
          : savedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
