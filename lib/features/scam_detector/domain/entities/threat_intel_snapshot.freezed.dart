// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'threat_intel_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ThreatIntelSnapshot {

 VirusTotalResult? get virusTotal; AbuseIpdbResult? get abuseIpdb; UrlScanResult? get urlScan; EmailAuthAlignment? get emailAuth; bool get osintSkippedDueToIncognito;
/// Create a copy of ThreatIntelSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ThreatIntelSnapshotCopyWith<ThreatIntelSnapshot> get copyWith => _$ThreatIntelSnapshotCopyWithImpl<ThreatIntelSnapshot>(this as ThreatIntelSnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ThreatIntelSnapshot&&(identical(other.virusTotal, virusTotal) || other.virusTotal == virusTotal)&&(identical(other.abuseIpdb, abuseIpdb) || other.abuseIpdb == abuseIpdb)&&(identical(other.urlScan, urlScan) || other.urlScan == urlScan)&&(identical(other.emailAuth, emailAuth) || other.emailAuth == emailAuth)&&(identical(other.osintSkippedDueToIncognito, osintSkippedDueToIncognito) || other.osintSkippedDueToIncognito == osintSkippedDueToIncognito));
}


@override
int get hashCode => Object.hash(runtimeType,virusTotal,abuseIpdb,urlScan,emailAuth,osintSkippedDueToIncognito);

@override
String toString() {
  return 'ThreatIntelSnapshot(virusTotal: $virusTotal, abuseIpdb: $abuseIpdb, urlScan: $urlScan, emailAuth: $emailAuth, osintSkippedDueToIncognito: $osintSkippedDueToIncognito)';
}


}

/// @nodoc
abstract mixin class $ThreatIntelSnapshotCopyWith<$Res>  {
  factory $ThreatIntelSnapshotCopyWith(ThreatIntelSnapshot value, $Res Function(ThreatIntelSnapshot) _then) = _$ThreatIntelSnapshotCopyWithImpl;
@useResult
$Res call({
 VirusTotalResult? virusTotal, AbuseIpdbResult? abuseIpdb, UrlScanResult? urlScan, EmailAuthAlignment? emailAuth, bool osintSkippedDueToIncognito
});


$VirusTotalResultCopyWith<$Res>? get virusTotal;$AbuseIpdbResultCopyWith<$Res>? get abuseIpdb;$UrlScanResultCopyWith<$Res>? get urlScan;

}
/// @nodoc
class _$ThreatIntelSnapshotCopyWithImpl<$Res>
    implements $ThreatIntelSnapshotCopyWith<$Res> {
  _$ThreatIntelSnapshotCopyWithImpl(this._self, this._then);

  final ThreatIntelSnapshot _self;
  final $Res Function(ThreatIntelSnapshot) _then;

/// Create a copy of ThreatIntelSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? virusTotal = freezed,Object? abuseIpdb = freezed,Object? urlScan = freezed,Object? emailAuth = freezed,Object? osintSkippedDueToIncognito = null,}) {
  return _then(_self.copyWith(
virusTotal: freezed == virusTotal ? _self.virusTotal : virusTotal // ignore: cast_nullable_to_non_nullable
as VirusTotalResult?,abuseIpdb: freezed == abuseIpdb ? _self.abuseIpdb : abuseIpdb // ignore: cast_nullable_to_non_nullable
as AbuseIpdbResult?,urlScan: freezed == urlScan ? _self.urlScan : urlScan // ignore: cast_nullable_to_non_nullable
as UrlScanResult?,emailAuth: freezed == emailAuth ? _self.emailAuth : emailAuth // ignore: cast_nullable_to_non_nullable
as EmailAuthAlignment?,osintSkippedDueToIncognito: null == osintSkippedDueToIncognito ? _self.osintSkippedDueToIncognito : osintSkippedDueToIncognito // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of ThreatIntelSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VirusTotalResultCopyWith<$Res>? get virusTotal {
    if (_self.virusTotal == null) {
    return null;
  }

  return $VirusTotalResultCopyWith<$Res>(_self.virusTotal!, (value) {
    return _then(_self.copyWith(virusTotal: value));
  });
}/// Create a copy of ThreatIntelSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AbuseIpdbResultCopyWith<$Res>? get abuseIpdb {
    if (_self.abuseIpdb == null) {
    return null;
  }

  return $AbuseIpdbResultCopyWith<$Res>(_self.abuseIpdb!, (value) {
    return _then(_self.copyWith(abuseIpdb: value));
  });
}/// Create a copy of ThreatIntelSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UrlScanResultCopyWith<$Res>? get urlScan {
    if (_self.urlScan == null) {
    return null;
  }

  return $UrlScanResultCopyWith<$Res>(_self.urlScan!, (value) {
    return _then(_self.copyWith(urlScan: value));
  });
}
}


/// Adds pattern-matching-related methods to [ThreatIntelSnapshot].
extension ThreatIntelSnapshotPatterns on ThreatIntelSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ThreatIntelSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ThreatIntelSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ThreatIntelSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _ThreatIntelSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ThreatIntelSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _ThreatIntelSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( VirusTotalResult? virusTotal,  AbuseIpdbResult? abuseIpdb,  UrlScanResult? urlScan,  EmailAuthAlignment? emailAuth,  bool osintSkippedDueToIncognito)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ThreatIntelSnapshot() when $default != null:
return $default(_that.virusTotal,_that.abuseIpdb,_that.urlScan,_that.emailAuth,_that.osintSkippedDueToIncognito);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( VirusTotalResult? virusTotal,  AbuseIpdbResult? abuseIpdb,  UrlScanResult? urlScan,  EmailAuthAlignment? emailAuth,  bool osintSkippedDueToIncognito)  $default,) {final _that = this;
switch (_that) {
case _ThreatIntelSnapshot():
return $default(_that.virusTotal,_that.abuseIpdb,_that.urlScan,_that.emailAuth,_that.osintSkippedDueToIncognito);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( VirusTotalResult? virusTotal,  AbuseIpdbResult? abuseIpdb,  UrlScanResult? urlScan,  EmailAuthAlignment? emailAuth,  bool osintSkippedDueToIncognito)?  $default,) {final _that = this;
switch (_that) {
case _ThreatIntelSnapshot() when $default != null:
return $default(_that.virusTotal,_that.abuseIpdb,_that.urlScan,_that.emailAuth,_that.osintSkippedDueToIncognito);case _:
  return null;

}
}

}

/// @nodoc


class _ThreatIntelSnapshot implements ThreatIntelSnapshot {
  const _ThreatIntelSnapshot({this.virusTotal, this.abuseIpdb, this.urlScan, this.emailAuth, this.osintSkippedDueToIncognito = false});
  

@override final  VirusTotalResult? virusTotal;
@override final  AbuseIpdbResult? abuseIpdb;
@override final  UrlScanResult? urlScan;
@override final  EmailAuthAlignment? emailAuth;
@override@JsonKey() final  bool osintSkippedDueToIncognito;

/// Create a copy of ThreatIntelSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ThreatIntelSnapshotCopyWith<_ThreatIntelSnapshot> get copyWith => __$ThreatIntelSnapshotCopyWithImpl<_ThreatIntelSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ThreatIntelSnapshot&&(identical(other.virusTotal, virusTotal) || other.virusTotal == virusTotal)&&(identical(other.abuseIpdb, abuseIpdb) || other.abuseIpdb == abuseIpdb)&&(identical(other.urlScan, urlScan) || other.urlScan == urlScan)&&(identical(other.emailAuth, emailAuth) || other.emailAuth == emailAuth)&&(identical(other.osintSkippedDueToIncognito, osintSkippedDueToIncognito) || other.osintSkippedDueToIncognito == osintSkippedDueToIncognito));
}


@override
int get hashCode => Object.hash(runtimeType,virusTotal,abuseIpdb,urlScan,emailAuth,osintSkippedDueToIncognito);

@override
String toString() {
  return 'ThreatIntelSnapshot(virusTotal: $virusTotal, abuseIpdb: $abuseIpdb, urlScan: $urlScan, emailAuth: $emailAuth, osintSkippedDueToIncognito: $osintSkippedDueToIncognito)';
}


}

/// @nodoc
abstract mixin class _$ThreatIntelSnapshotCopyWith<$Res> implements $ThreatIntelSnapshotCopyWith<$Res> {
  factory _$ThreatIntelSnapshotCopyWith(_ThreatIntelSnapshot value, $Res Function(_ThreatIntelSnapshot) _then) = __$ThreatIntelSnapshotCopyWithImpl;
@override @useResult
$Res call({
 VirusTotalResult? virusTotal, AbuseIpdbResult? abuseIpdb, UrlScanResult? urlScan, EmailAuthAlignment? emailAuth, bool osintSkippedDueToIncognito
});


@override $VirusTotalResultCopyWith<$Res>? get virusTotal;@override $AbuseIpdbResultCopyWith<$Res>? get abuseIpdb;@override $UrlScanResultCopyWith<$Res>? get urlScan;

}
/// @nodoc
class __$ThreatIntelSnapshotCopyWithImpl<$Res>
    implements _$ThreatIntelSnapshotCopyWith<$Res> {
  __$ThreatIntelSnapshotCopyWithImpl(this._self, this._then);

  final _ThreatIntelSnapshot _self;
  final $Res Function(_ThreatIntelSnapshot) _then;

/// Create a copy of ThreatIntelSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? virusTotal = freezed,Object? abuseIpdb = freezed,Object? urlScan = freezed,Object? emailAuth = freezed,Object? osintSkippedDueToIncognito = null,}) {
  return _then(_ThreatIntelSnapshot(
virusTotal: freezed == virusTotal ? _self.virusTotal : virusTotal // ignore: cast_nullable_to_non_nullable
as VirusTotalResult?,abuseIpdb: freezed == abuseIpdb ? _self.abuseIpdb : abuseIpdb // ignore: cast_nullable_to_non_nullable
as AbuseIpdbResult?,urlScan: freezed == urlScan ? _self.urlScan : urlScan // ignore: cast_nullable_to_non_nullable
as UrlScanResult?,emailAuth: freezed == emailAuth ? _self.emailAuth : emailAuth // ignore: cast_nullable_to_non_nullable
as EmailAuthAlignment?,osintSkippedDueToIncognito: null == osintSkippedDueToIncognito ? _self.osintSkippedDueToIncognito : osintSkippedDueToIncognito // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of ThreatIntelSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VirusTotalResultCopyWith<$Res>? get virusTotal {
    if (_self.virusTotal == null) {
    return null;
  }

  return $VirusTotalResultCopyWith<$Res>(_self.virusTotal!, (value) {
    return _then(_self.copyWith(virusTotal: value));
  });
}/// Create a copy of ThreatIntelSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AbuseIpdbResultCopyWith<$Res>? get abuseIpdb {
    if (_self.abuseIpdb == null) {
    return null;
  }

  return $AbuseIpdbResultCopyWith<$Res>(_self.abuseIpdb!, (value) {
    return _then(_self.copyWith(abuseIpdb: value));
  });
}/// Create a copy of ThreatIntelSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UrlScanResultCopyWith<$Res>? get urlScan {
    if (_self.urlScan == null) {
    return null;
  }

  return $UrlScanResultCopyWith<$Res>(_self.urlScan!, (value) {
    return _then(_self.copyWith(urlScan: value));
  });
}
}

/// @nodoc
mixin _$VirusTotalResult {

 String get url; int get maliciousCount; int get totalEngines;
/// Create a copy of VirusTotalResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VirusTotalResultCopyWith<VirusTotalResult> get copyWith => _$VirusTotalResultCopyWithImpl<VirusTotalResult>(this as VirusTotalResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VirusTotalResult&&(identical(other.url, url) || other.url == url)&&(identical(other.maliciousCount, maliciousCount) || other.maliciousCount == maliciousCount)&&(identical(other.totalEngines, totalEngines) || other.totalEngines == totalEngines));
}


@override
int get hashCode => Object.hash(runtimeType,url,maliciousCount,totalEngines);

@override
String toString() {
  return 'VirusTotalResult(url: $url, maliciousCount: $maliciousCount, totalEngines: $totalEngines)';
}


}

/// @nodoc
abstract mixin class $VirusTotalResultCopyWith<$Res>  {
  factory $VirusTotalResultCopyWith(VirusTotalResult value, $Res Function(VirusTotalResult) _then) = _$VirusTotalResultCopyWithImpl;
@useResult
$Res call({
 String url, int maliciousCount, int totalEngines
});




}
/// @nodoc
class _$VirusTotalResultCopyWithImpl<$Res>
    implements $VirusTotalResultCopyWith<$Res> {
  _$VirusTotalResultCopyWithImpl(this._self, this._then);

  final VirusTotalResult _self;
  final $Res Function(VirusTotalResult) _then;

/// Create a copy of VirusTotalResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? maliciousCount = null,Object? totalEngines = null,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,maliciousCount: null == maliciousCount ? _self.maliciousCount : maliciousCount // ignore: cast_nullable_to_non_nullable
as int,totalEngines: null == totalEngines ? _self.totalEngines : totalEngines // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [VirusTotalResult].
extension VirusTotalResultPatterns on VirusTotalResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VirusTotalResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VirusTotalResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VirusTotalResult value)  $default,){
final _that = this;
switch (_that) {
case _VirusTotalResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VirusTotalResult value)?  $default,){
final _that = this;
switch (_that) {
case _VirusTotalResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  int maliciousCount,  int totalEngines)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VirusTotalResult() when $default != null:
return $default(_that.url,_that.maliciousCount,_that.totalEngines);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  int maliciousCount,  int totalEngines)  $default,) {final _that = this;
switch (_that) {
case _VirusTotalResult():
return $default(_that.url,_that.maliciousCount,_that.totalEngines);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  int maliciousCount,  int totalEngines)?  $default,) {final _that = this;
switch (_that) {
case _VirusTotalResult() when $default != null:
return $default(_that.url,_that.maliciousCount,_that.totalEngines);case _:
  return null;

}
}

}

/// @nodoc


class _VirusTotalResult implements VirusTotalResult {
  const _VirusTotalResult({required this.url, required this.maliciousCount, required this.totalEngines});
  

@override final  String url;
@override final  int maliciousCount;
@override final  int totalEngines;

/// Create a copy of VirusTotalResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VirusTotalResultCopyWith<_VirusTotalResult> get copyWith => __$VirusTotalResultCopyWithImpl<_VirusTotalResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VirusTotalResult&&(identical(other.url, url) || other.url == url)&&(identical(other.maliciousCount, maliciousCount) || other.maliciousCount == maliciousCount)&&(identical(other.totalEngines, totalEngines) || other.totalEngines == totalEngines));
}


@override
int get hashCode => Object.hash(runtimeType,url,maliciousCount,totalEngines);

@override
String toString() {
  return 'VirusTotalResult(url: $url, maliciousCount: $maliciousCount, totalEngines: $totalEngines)';
}


}

/// @nodoc
abstract mixin class _$VirusTotalResultCopyWith<$Res> implements $VirusTotalResultCopyWith<$Res> {
  factory _$VirusTotalResultCopyWith(_VirusTotalResult value, $Res Function(_VirusTotalResult) _then) = __$VirusTotalResultCopyWithImpl;
@override @useResult
$Res call({
 String url, int maliciousCount, int totalEngines
});




}
/// @nodoc
class __$VirusTotalResultCopyWithImpl<$Res>
    implements _$VirusTotalResultCopyWith<$Res> {
  __$VirusTotalResultCopyWithImpl(this._self, this._then);

  final _VirusTotalResult _self;
  final $Res Function(_VirusTotalResult) _then;

/// Create a copy of VirusTotalResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? maliciousCount = null,Object? totalEngines = null,}) {
  return _then(_VirusTotalResult(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,maliciousCount: null == maliciousCount ? _self.maliciousCount : maliciousCount // ignore: cast_nullable_to_non_nullable
as int,totalEngines: null == totalEngines ? _self.totalEngines : totalEngines // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$AbuseIpdbResult {

 String get ipAddress; int get abuseConfidenceScore; int get totalReports;
/// Create a copy of AbuseIpdbResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AbuseIpdbResultCopyWith<AbuseIpdbResult> get copyWith => _$AbuseIpdbResultCopyWithImpl<AbuseIpdbResult>(this as AbuseIpdbResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AbuseIpdbResult&&(identical(other.ipAddress, ipAddress) || other.ipAddress == ipAddress)&&(identical(other.abuseConfidenceScore, abuseConfidenceScore) || other.abuseConfidenceScore == abuseConfidenceScore)&&(identical(other.totalReports, totalReports) || other.totalReports == totalReports));
}


@override
int get hashCode => Object.hash(runtimeType,ipAddress,abuseConfidenceScore,totalReports);

@override
String toString() {
  return 'AbuseIpdbResult(ipAddress: $ipAddress, abuseConfidenceScore: $abuseConfidenceScore, totalReports: $totalReports)';
}


}

/// @nodoc
abstract mixin class $AbuseIpdbResultCopyWith<$Res>  {
  factory $AbuseIpdbResultCopyWith(AbuseIpdbResult value, $Res Function(AbuseIpdbResult) _then) = _$AbuseIpdbResultCopyWithImpl;
@useResult
$Res call({
 String ipAddress, int abuseConfidenceScore, int totalReports
});




}
/// @nodoc
class _$AbuseIpdbResultCopyWithImpl<$Res>
    implements $AbuseIpdbResultCopyWith<$Res> {
  _$AbuseIpdbResultCopyWithImpl(this._self, this._then);

  final AbuseIpdbResult _self;
  final $Res Function(AbuseIpdbResult) _then;

/// Create a copy of AbuseIpdbResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ipAddress = null,Object? abuseConfidenceScore = null,Object? totalReports = null,}) {
  return _then(_self.copyWith(
ipAddress: null == ipAddress ? _self.ipAddress : ipAddress // ignore: cast_nullable_to_non_nullable
as String,abuseConfidenceScore: null == abuseConfidenceScore ? _self.abuseConfidenceScore : abuseConfidenceScore // ignore: cast_nullable_to_non_nullable
as int,totalReports: null == totalReports ? _self.totalReports : totalReports // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AbuseIpdbResult].
extension AbuseIpdbResultPatterns on AbuseIpdbResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AbuseIpdbResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AbuseIpdbResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AbuseIpdbResult value)  $default,){
final _that = this;
switch (_that) {
case _AbuseIpdbResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AbuseIpdbResult value)?  $default,){
final _that = this;
switch (_that) {
case _AbuseIpdbResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String ipAddress,  int abuseConfidenceScore,  int totalReports)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AbuseIpdbResult() when $default != null:
return $default(_that.ipAddress,_that.abuseConfidenceScore,_that.totalReports);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String ipAddress,  int abuseConfidenceScore,  int totalReports)  $default,) {final _that = this;
switch (_that) {
case _AbuseIpdbResult():
return $default(_that.ipAddress,_that.abuseConfidenceScore,_that.totalReports);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String ipAddress,  int abuseConfidenceScore,  int totalReports)?  $default,) {final _that = this;
switch (_that) {
case _AbuseIpdbResult() when $default != null:
return $default(_that.ipAddress,_that.abuseConfidenceScore,_that.totalReports);case _:
  return null;

}
}

}

/// @nodoc


class _AbuseIpdbResult implements AbuseIpdbResult {
  const _AbuseIpdbResult({required this.ipAddress, required this.abuseConfidenceScore, required this.totalReports});
  

@override final  String ipAddress;
@override final  int abuseConfidenceScore;
@override final  int totalReports;

/// Create a copy of AbuseIpdbResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AbuseIpdbResultCopyWith<_AbuseIpdbResult> get copyWith => __$AbuseIpdbResultCopyWithImpl<_AbuseIpdbResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AbuseIpdbResult&&(identical(other.ipAddress, ipAddress) || other.ipAddress == ipAddress)&&(identical(other.abuseConfidenceScore, abuseConfidenceScore) || other.abuseConfidenceScore == abuseConfidenceScore)&&(identical(other.totalReports, totalReports) || other.totalReports == totalReports));
}


@override
int get hashCode => Object.hash(runtimeType,ipAddress,abuseConfidenceScore,totalReports);

@override
String toString() {
  return 'AbuseIpdbResult(ipAddress: $ipAddress, abuseConfidenceScore: $abuseConfidenceScore, totalReports: $totalReports)';
}


}

/// @nodoc
abstract mixin class _$AbuseIpdbResultCopyWith<$Res> implements $AbuseIpdbResultCopyWith<$Res> {
  factory _$AbuseIpdbResultCopyWith(_AbuseIpdbResult value, $Res Function(_AbuseIpdbResult) _then) = __$AbuseIpdbResultCopyWithImpl;
@override @useResult
$Res call({
 String ipAddress, int abuseConfidenceScore, int totalReports
});




}
/// @nodoc
class __$AbuseIpdbResultCopyWithImpl<$Res>
    implements _$AbuseIpdbResultCopyWith<$Res> {
  __$AbuseIpdbResultCopyWithImpl(this._self, this._then);

  final _AbuseIpdbResult _self;
  final $Res Function(_AbuseIpdbResult) _then;

/// Create a copy of AbuseIpdbResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ipAddress = null,Object? abuseConfidenceScore = null,Object? totalReports = null,}) {
  return _then(_AbuseIpdbResult(
ipAddress: null == ipAddress ? _self.ipAddress : ipAddress // ignore: cast_nullable_to_non_nullable
as String,abuseConfidenceScore: null == abuseConfidenceScore ? _self.abuseConfidenceScore : abuseConfidenceScore // ignore: cast_nullable_to_non_nullable
as int,totalReports: null == totalReports ? _self.totalReports : totalReports // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$UrlScanResult {

 String get url; String get scanId; String get visibility;
/// Create a copy of UrlScanResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UrlScanResultCopyWith<UrlScanResult> get copyWith => _$UrlScanResultCopyWithImpl<UrlScanResult>(this as UrlScanResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UrlScanResult&&(identical(other.url, url) || other.url == url)&&(identical(other.scanId, scanId) || other.scanId == scanId)&&(identical(other.visibility, visibility) || other.visibility == visibility));
}


@override
int get hashCode => Object.hash(runtimeType,url,scanId,visibility);

@override
String toString() {
  return 'UrlScanResult(url: $url, scanId: $scanId, visibility: $visibility)';
}


}

/// @nodoc
abstract mixin class $UrlScanResultCopyWith<$Res>  {
  factory $UrlScanResultCopyWith(UrlScanResult value, $Res Function(UrlScanResult) _then) = _$UrlScanResultCopyWithImpl;
@useResult
$Res call({
 String url, String scanId, String visibility
});




}
/// @nodoc
class _$UrlScanResultCopyWithImpl<$Res>
    implements $UrlScanResultCopyWith<$Res> {
  _$UrlScanResultCopyWithImpl(this._self, this._then);

  final UrlScanResult _self;
  final $Res Function(UrlScanResult) _then;

/// Create a copy of UrlScanResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? scanId = null,Object? visibility = null,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,scanId: null == scanId ? _self.scanId : scanId // ignore: cast_nullable_to_non_nullable
as String,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [UrlScanResult].
extension UrlScanResultPatterns on UrlScanResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UrlScanResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UrlScanResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UrlScanResult value)  $default,){
final _that = this;
switch (_that) {
case _UrlScanResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UrlScanResult value)?  $default,){
final _that = this;
switch (_that) {
case _UrlScanResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  String scanId,  String visibility)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UrlScanResult() when $default != null:
return $default(_that.url,_that.scanId,_that.visibility);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  String scanId,  String visibility)  $default,) {final _that = this;
switch (_that) {
case _UrlScanResult():
return $default(_that.url,_that.scanId,_that.visibility);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  String scanId,  String visibility)?  $default,) {final _that = this;
switch (_that) {
case _UrlScanResult() when $default != null:
return $default(_that.url,_that.scanId,_that.visibility);case _:
  return null;

}
}

}

/// @nodoc


class _UrlScanResult implements UrlScanResult {
  const _UrlScanResult({required this.url, required this.scanId, required this.visibility});
  

@override final  String url;
@override final  String scanId;
@override final  String visibility;

/// Create a copy of UrlScanResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UrlScanResultCopyWith<_UrlScanResult> get copyWith => __$UrlScanResultCopyWithImpl<_UrlScanResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UrlScanResult&&(identical(other.url, url) || other.url == url)&&(identical(other.scanId, scanId) || other.scanId == scanId)&&(identical(other.visibility, visibility) || other.visibility == visibility));
}


@override
int get hashCode => Object.hash(runtimeType,url,scanId,visibility);

@override
String toString() {
  return 'UrlScanResult(url: $url, scanId: $scanId, visibility: $visibility)';
}


}

/// @nodoc
abstract mixin class _$UrlScanResultCopyWith<$Res> implements $UrlScanResultCopyWith<$Res> {
  factory _$UrlScanResultCopyWith(_UrlScanResult value, $Res Function(_UrlScanResult) _then) = __$UrlScanResultCopyWithImpl;
@override @useResult
$Res call({
 String url, String scanId, String visibility
});




}
/// @nodoc
class __$UrlScanResultCopyWithImpl<$Res>
    implements _$UrlScanResultCopyWith<$Res> {
  __$UrlScanResultCopyWithImpl(this._self, this._then);

  final _UrlScanResult _self;
  final $Res Function(_UrlScanResult) _then;

/// Create a copy of UrlScanResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? scanId = null,Object? visibility = null,}) {
  return _then(_UrlScanResult(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,scanId: null == scanId ? _self.scanId : scanId // ignore: cast_nullable_to_non_nullable
as String,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
