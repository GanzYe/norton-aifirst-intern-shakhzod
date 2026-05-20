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

 RiskLevel get riskLevel; int get confidence; String get explanation; bool get resolvedLocally; bool get localModelUnavailable; bool get cloudFallback; bool get localAnalysisFailed; List<PipelineLogEntry> get pipelineLog;
/// Create a copy of ScamAnalysis
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScamAnalysisCopyWith<ScamAnalysis> get copyWith => _$ScamAnalysisCopyWithImpl<ScamAnalysis>(this as ScamAnalysis, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScamAnalysis&&(identical(other.riskLevel, riskLevel) || other.riskLevel == riskLevel)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.explanation, explanation) || other.explanation == explanation)&&(identical(other.resolvedLocally, resolvedLocally) || other.resolvedLocally == resolvedLocally)&&(identical(other.localModelUnavailable, localModelUnavailable) || other.localModelUnavailable == localModelUnavailable)&&(identical(other.cloudFallback, cloudFallback) || other.cloudFallback == cloudFallback)&&(identical(other.localAnalysisFailed, localAnalysisFailed) || other.localAnalysisFailed == localAnalysisFailed)&&const DeepCollectionEquality().equals(other.pipelineLog, pipelineLog));
}


@override
int get hashCode => Object.hash(runtimeType,riskLevel,confidence,explanation,resolvedLocally,localModelUnavailable,cloudFallback,localAnalysisFailed,const DeepCollectionEquality().hash(pipelineLog));

@override
String toString() {
  return 'ScamAnalysis(riskLevel: $riskLevel, confidence: $confidence, explanation: $explanation, resolvedLocally: $resolvedLocally, localModelUnavailable: $localModelUnavailable, cloudFallback: $cloudFallback, localAnalysisFailed: $localAnalysisFailed, pipelineLog: $pipelineLog)';
}


}

/// @nodoc
abstract mixin class $ScamAnalysisCopyWith<$Res>  {
  factory $ScamAnalysisCopyWith(ScamAnalysis value, $Res Function(ScamAnalysis) _then) = _$ScamAnalysisCopyWithImpl;
@useResult
$Res call({
 RiskLevel riskLevel, int confidence, String explanation, bool resolvedLocally, bool localModelUnavailable, bool cloudFallback, bool localAnalysisFailed, List<PipelineLogEntry> pipelineLog
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
@pragma('vm:prefer-inline') @override $Res call({Object? riskLevel = null,Object? confidence = null,Object? explanation = null,Object? resolvedLocally = null,Object? localModelUnavailable = null,Object? cloudFallback = null,Object? localAnalysisFailed = null,Object? pipelineLog = null,}) {
  return _then(_self.copyWith(
riskLevel: null == riskLevel ? _self.riskLevel : riskLevel // ignore: cast_nullable_to_non_nullable
as RiskLevel,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as int,explanation: null == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String,resolvedLocally: null == resolvedLocally ? _self.resolvedLocally : resolvedLocally // ignore: cast_nullable_to_non_nullable
as bool,localModelUnavailable: null == localModelUnavailable ? _self.localModelUnavailable : localModelUnavailable // ignore: cast_nullable_to_non_nullable
as bool,cloudFallback: null == cloudFallback ? _self.cloudFallback : cloudFallback // ignore: cast_nullable_to_non_nullable
as bool,localAnalysisFailed: null == localAnalysisFailed ? _self.localAnalysisFailed : localAnalysisFailed // ignore: cast_nullable_to_non_nullable
as bool,pipelineLog: null == pipelineLog ? _self.pipelineLog : pipelineLog // ignore: cast_nullable_to_non_nullable
as List<PipelineLogEntry>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RiskLevel riskLevel,  int confidence,  String explanation,  bool resolvedLocally,  bool localModelUnavailable,  bool cloudFallback,  bool localAnalysisFailed,  List<PipelineLogEntry> pipelineLog)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScamAnalysis() when $default != null:
return $default(_that.riskLevel,_that.confidence,_that.explanation,_that.resolvedLocally,_that.localModelUnavailable,_that.cloudFallback,_that.localAnalysisFailed,_that.pipelineLog);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RiskLevel riskLevel,  int confidence,  String explanation,  bool resolvedLocally,  bool localModelUnavailable,  bool cloudFallback,  bool localAnalysisFailed,  List<PipelineLogEntry> pipelineLog)  $default,) {final _that = this;
switch (_that) {
case _ScamAnalysis():
return $default(_that.riskLevel,_that.confidence,_that.explanation,_that.resolvedLocally,_that.localModelUnavailable,_that.cloudFallback,_that.localAnalysisFailed,_that.pipelineLog);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RiskLevel riskLevel,  int confidence,  String explanation,  bool resolvedLocally,  bool localModelUnavailable,  bool cloudFallback,  bool localAnalysisFailed,  List<PipelineLogEntry> pipelineLog)?  $default,) {final _that = this;
switch (_that) {
case _ScamAnalysis() when $default != null:
return $default(_that.riskLevel,_that.confidence,_that.explanation,_that.resolvedLocally,_that.localModelUnavailable,_that.cloudFallback,_that.localAnalysisFailed,_that.pipelineLog);case _:
  return null;

}
}

}

/// @nodoc


class _ScamAnalysis implements ScamAnalysis {
  const _ScamAnalysis({required this.riskLevel, required this.confidence, required this.explanation, this.resolvedLocally = false, this.localModelUnavailable = false, this.cloudFallback = false, this.localAnalysisFailed = false, final  List<PipelineLogEntry> pipelineLog = const []}): _pipelineLog = pipelineLog;
  

@override final  RiskLevel riskLevel;
@override final  int confidence;
@override final  String explanation;
@override@JsonKey() final  bool resolvedLocally;
@override@JsonKey() final  bool localModelUnavailable;
@override@JsonKey() final  bool cloudFallback;
@override@JsonKey() final  bool localAnalysisFailed;
 final  List<PipelineLogEntry> _pipelineLog;
@override@JsonKey() List<PipelineLogEntry> get pipelineLog {
  if (_pipelineLog is EqualUnmodifiableListView) return _pipelineLog;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pipelineLog);
}


/// Create a copy of ScamAnalysis
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScamAnalysisCopyWith<_ScamAnalysis> get copyWith => __$ScamAnalysisCopyWithImpl<_ScamAnalysis>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScamAnalysis&&(identical(other.riskLevel, riskLevel) || other.riskLevel == riskLevel)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.explanation, explanation) || other.explanation == explanation)&&(identical(other.resolvedLocally, resolvedLocally) || other.resolvedLocally == resolvedLocally)&&(identical(other.localModelUnavailable, localModelUnavailable) || other.localModelUnavailable == localModelUnavailable)&&(identical(other.cloudFallback, cloudFallback) || other.cloudFallback == cloudFallback)&&(identical(other.localAnalysisFailed, localAnalysisFailed) || other.localAnalysisFailed == localAnalysisFailed)&&const DeepCollectionEquality().equals(other._pipelineLog, _pipelineLog));
}


@override
int get hashCode => Object.hash(runtimeType,riskLevel,confidence,explanation,resolvedLocally,localModelUnavailable,cloudFallback,localAnalysisFailed,const DeepCollectionEquality().hash(_pipelineLog));

@override
String toString() {
  return 'ScamAnalysis(riskLevel: $riskLevel, confidence: $confidence, explanation: $explanation, resolvedLocally: $resolvedLocally, localModelUnavailable: $localModelUnavailable, cloudFallback: $cloudFallback, localAnalysisFailed: $localAnalysisFailed, pipelineLog: $pipelineLog)';
}


}

/// @nodoc
abstract mixin class _$ScamAnalysisCopyWith<$Res> implements $ScamAnalysisCopyWith<$Res> {
  factory _$ScamAnalysisCopyWith(_ScamAnalysis value, $Res Function(_ScamAnalysis) _then) = __$ScamAnalysisCopyWithImpl;
@override @useResult
$Res call({
 RiskLevel riskLevel, int confidence, String explanation, bool resolvedLocally, bool localModelUnavailable, bool cloudFallback, bool localAnalysisFailed, List<PipelineLogEntry> pipelineLog
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
@override @pragma('vm:prefer-inline') $Res call({Object? riskLevel = null,Object? confidence = null,Object? explanation = null,Object? resolvedLocally = null,Object? localModelUnavailable = null,Object? cloudFallback = null,Object? localAnalysisFailed = null,Object? pipelineLog = null,}) {
  return _then(_ScamAnalysis(
riskLevel: null == riskLevel ? _self.riskLevel : riskLevel // ignore: cast_nullable_to_non_nullable
as RiskLevel,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as int,explanation: null == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String,resolvedLocally: null == resolvedLocally ? _self.resolvedLocally : resolvedLocally // ignore: cast_nullable_to_non_nullable
as bool,localModelUnavailable: null == localModelUnavailable ? _self.localModelUnavailable : localModelUnavailable // ignore: cast_nullable_to_non_nullable
as bool,cloudFallback: null == cloudFallback ? _self.cloudFallback : cloudFallback // ignore: cast_nullable_to_non_nullable
as bool,localAnalysisFailed: null == localAnalysisFailed ? _self.localAnalysisFailed : localAnalysisFailed // ignore: cast_nullable_to_non_nullable
as bool,pipelineLog: null == pipelineLog ? _self._pipelineLog : pipelineLog // ignore: cast_nullable_to_non_nullable
as List<PipelineLogEntry>,
  ));
}


}

// dart format on
