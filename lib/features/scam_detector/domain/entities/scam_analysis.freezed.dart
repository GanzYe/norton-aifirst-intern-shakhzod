// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scam_analysis.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ScamAnalysis {

 RiskLevel get riskLevel; int get confidence; String get explanation;
/// Create a copy of ScamAnalysis
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScamAnalysisCopyWith<ScamAnalysis> get copyWith => _$ScamAnalysisCopyWithImpl<ScamAnalysis>(this as ScamAnalysis, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScamAnalysis&&(identical(other.riskLevel, riskLevel) || other.riskLevel == riskLevel)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.explanation, explanation) || other.explanation == explanation));
}


@override
int get hashCode => Object.hash(runtimeType,riskLevel,confidence,explanation);

@override
String toString() {
  return 'ScamAnalysis(riskLevel: $riskLevel, confidence: $confidence, explanation: $explanation)';
}


}

/// @nodoc
abstract mixin class $ScamAnalysisCopyWith<$Res>  {
  factory $ScamAnalysisCopyWith(ScamAnalysis value, $Res Function(ScamAnalysis) _then) = _$ScamAnalysisCopyWithImpl;
@useResult
$Res call({
 RiskLevel riskLevel, int confidence, String explanation
});




}
/// @nodoc
class _$ScamAnalysisCopyWithImpl<$Res>
    implements $ScamAnalysisCopyWith<$Res> {
  _$ScamAnalysisCopyWithImpl(this._self, this._then);

  final ScamAnalysis _self;
  final $Res Function(ScamAnalysis) _then;

/// Create a copy of ScamAnalysis
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? riskLevel = null,Object? confidence = null,Object? explanation = null,}) {
  return _then(_self.copyWith(
riskLevel: null == riskLevel ? _self.riskLevel : riskLevel // ignore: cast_nullable_to_non_nullable
as RiskLevel,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as int,explanation: null == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ScamAnalysis].
extension ScamAnalysisPatterns on ScamAnalysis {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScamAnalysis value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScamAnalysis() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScamAnalysis value)  $default,){
final _that = this;
switch (_that) {
case _ScamAnalysis():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScamAnalysis value)?  $default,){
final _that = this;
switch (_that) {
case _ScamAnalysis() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RiskLevel riskLevel,  int confidence,  String explanation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScamAnalysis() when $default != null:
return $default(_that.riskLevel,_that.confidence,_that.explanation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RiskLevel riskLevel,  int confidence,  String explanation)  $default,) {final _that = this;
switch (_that) {
case _ScamAnalysis():
return $default(_that.riskLevel,_that.confidence,_that.explanation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RiskLevel riskLevel,  int confidence,  String explanation)?  $default,) {final _that = this;
switch (_that) {
case _ScamAnalysis() when $default != null:
return $default(_that.riskLevel,_that.confidence,_that.explanation);case _:
  return null;

}
}

}

/// @nodoc


class _ScamAnalysis implements ScamAnalysis {
  const _ScamAnalysis({required this.riskLevel, required this.confidence, required this.explanation});
  

@override final  RiskLevel riskLevel;
@override final  int confidence;
@override final  String explanation;

/// Create a copy of ScamAnalysis
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScamAnalysisCopyWith<_ScamAnalysis> get copyWith => __$ScamAnalysisCopyWithImpl<_ScamAnalysis>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScamAnalysis&&(identical(other.riskLevel, riskLevel) || other.riskLevel == riskLevel)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.explanation, explanation) || other.explanation == explanation));
}


@override
int get hashCode => Object.hash(runtimeType,riskLevel,confidence,explanation);

@override
String toString() {
  return 'ScamAnalysis(riskLevel: $riskLevel, confidence: $confidence, explanation: $explanation)';
}


}

/// @nodoc
abstract mixin class _$ScamAnalysisCopyWith<$Res> implements $ScamAnalysisCopyWith<$Res> {
  factory _$ScamAnalysisCopyWith(_ScamAnalysis value, $Res Function(_ScamAnalysis) _then) = __$ScamAnalysisCopyWithImpl;
@override @useResult
$Res call({
 RiskLevel riskLevel, int confidence, String explanation
});




}
/// @nodoc
class __$ScamAnalysisCopyWithImpl<$Res>
    implements _$ScamAnalysisCopyWith<$Res> {
  __$ScamAnalysisCopyWithImpl(this._self, this._then);

  final _ScamAnalysis _self;
  final $Res Function(_ScamAnalysis) _then;

/// Create a copy of ScamAnalysis
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? riskLevel = null,Object? confidence = null,Object? explanation = null,}) {
  return _then(_ScamAnalysis(
riskLevel: null == riskLevel ? _self.riskLevel : riskLevel // ignore: cast_nullable_to_non_nullable
as RiskLevel,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as int,explanation: null == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
