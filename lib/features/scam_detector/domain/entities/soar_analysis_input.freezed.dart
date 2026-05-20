// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'soar_analysis_input.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SoarAnalysisInput {

 String get rawContent; SoarInputKind get kind; bool get incognitoEnabled; String? get emlRawContent;
/// Create a copy of SoarAnalysisInput
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SoarAnalysisInputCopyWith<SoarAnalysisInput> get copyWith => _$SoarAnalysisInputCopyWithImpl<SoarAnalysisInput>(this as SoarAnalysisInput, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SoarAnalysisInput&&(identical(other.rawContent, rawContent) || other.rawContent == rawContent)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.incognitoEnabled, incognitoEnabled) || other.incognitoEnabled == incognitoEnabled)&&(identical(other.emlRawContent, emlRawContent) || other.emlRawContent == emlRawContent));
}


@override
int get hashCode => Object.hash(runtimeType,rawContent,kind,incognitoEnabled,emlRawContent);

@override
String toString() {
  return 'SoarAnalysisInput(rawContent: $rawContent, kind: $kind, incognitoEnabled: $incognitoEnabled, emlRawContent: $emlRawContent)';
}


}

/// @nodoc
abstract mixin class $SoarAnalysisInputCopyWith<$Res>  {
  factory $SoarAnalysisInputCopyWith(SoarAnalysisInput value, $Res Function(SoarAnalysisInput) _then) = _$SoarAnalysisInputCopyWithImpl;
@useResult
$Res call({
 String rawContent, SoarInputKind kind, bool incognitoEnabled, String? emlRawContent
});




}
/// @nodoc
class _$SoarAnalysisInputCopyWithImpl<$Res>
    implements $SoarAnalysisInputCopyWith<$Res> {
  _$SoarAnalysisInputCopyWithImpl(this._self, this._then);

  final SoarAnalysisInput _self;
  final $Res Function(SoarAnalysisInput) _then;

/// Create a copy of SoarAnalysisInput
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rawContent = null,Object? kind = null,Object? incognitoEnabled = null,Object? emlRawContent = freezed,}) {
  return _then(_self.copyWith(
rawContent: null == rawContent ? _self.rawContent : rawContent // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as SoarInputKind,incognitoEnabled: null == incognitoEnabled ? _self.incognitoEnabled : incognitoEnabled // ignore: cast_nullable_to_non_nullable
as bool,emlRawContent: freezed == emlRawContent ? _self.emlRawContent : emlRawContent // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SoarAnalysisInput].
extension SoarAnalysisInputPatterns on SoarAnalysisInput {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SoarAnalysisInput value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SoarAnalysisInput() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SoarAnalysisInput value)  $default,){
final _that = this;
switch (_that) {
case _SoarAnalysisInput():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SoarAnalysisInput value)?  $default,){
final _that = this;
switch (_that) {
case _SoarAnalysisInput() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String rawContent,  SoarInputKind kind,  bool incognitoEnabled,  String? emlRawContent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SoarAnalysisInput() when $default != null:
return $default(_that.rawContent,_that.kind,_that.incognitoEnabled,_that.emlRawContent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String rawContent,  SoarInputKind kind,  bool incognitoEnabled,  String? emlRawContent)  $default,) {final _that = this;
switch (_that) {
case _SoarAnalysisInput():
return $default(_that.rawContent,_that.kind,_that.incognitoEnabled,_that.emlRawContent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String rawContent,  SoarInputKind kind,  bool incognitoEnabled,  String? emlRawContent)?  $default,) {final _that = this;
switch (_that) {
case _SoarAnalysisInput() when $default != null:
return $default(_that.rawContent,_that.kind,_that.incognitoEnabled,_that.emlRawContent);case _:
  return null;

}
}

}

/// @nodoc


class _SoarAnalysisInput implements SoarAnalysisInput {
  const _SoarAnalysisInput({required this.rawContent, required this.kind, this.incognitoEnabled = false, this.emlRawContent});
  

@override final  String rawContent;
@override final  SoarInputKind kind;
@override@JsonKey() final  bool incognitoEnabled;
@override final  String? emlRawContent;

/// Create a copy of SoarAnalysisInput
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SoarAnalysisInputCopyWith<_SoarAnalysisInput> get copyWith => __$SoarAnalysisInputCopyWithImpl<_SoarAnalysisInput>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SoarAnalysisInput&&(identical(other.rawContent, rawContent) || other.rawContent == rawContent)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.incognitoEnabled, incognitoEnabled) || other.incognitoEnabled == incognitoEnabled)&&(identical(other.emlRawContent, emlRawContent) || other.emlRawContent == emlRawContent));
}


@override
int get hashCode => Object.hash(runtimeType,rawContent,kind,incognitoEnabled,emlRawContent);

@override
String toString() {
  return 'SoarAnalysisInput(rawContent: $rawContent, kind: $kind, incognitoEnabled: $incognitoEnabled, emlRawContent: $emlRawContent)';
}


}

/// @nodoc
abstract mixin class _$SoarAnalysisInputCopyWith<$Res> implements $SoarAnalysisInputCopyWith<$Res> {
  factory _$SoarAnalysisInputCopyWith(_SoarAnalysisInput value, $Res Function(_SoarAnalysisInput) _then) = __$SoarAnalysisInputCopyWithImpl;
@override @useResult
$Res call({
 String rawContent, SoarInputKind kind, bool incognitoEnabled, String? emlRawContent
});




}
/// @nodoc
class __$SoarAnalysisInputCopyWithImpl<$Res>
    implements _$SoarAnalysisInputCopyWith<$Res> {
  __$SoarAnalysisInputCopyWithImpl(this._self, this._then);

  final _SoarAnalysisInput _self;
  final $Res Function(_SoarAnalysisInput) _then;

/// Create a copy of SoarAnalysisInput
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rawContent = null,Object? kind = null,Object? incognitoEnabled = null,Object? emlRawContent = freezed,}) {
  return _then(_SoarAnalysisInput(
rawContent: null == rawContent ? _self.rawContent : rawContent // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as SoarInputKind,incognitoEnabled: null == incognitoEnabled ? _self.incognitoEnabled : incognitoEnabled // ignore: cast_nullable_to_non_nullable
as bool,emlRawContent: freezed == emlRawContent ? _self.emlRawContent : emlRawContent // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
