// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'incognito_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$modelDownloadServiceHash() =>
    r'097ca8206ca9d4e6c151be2e4ebd48613e194efe';

/// See also [modelDownloadService].
@ProviderFor(modelDownloadService)
final modelDownloadServiceProvider = Provider<ModelDownloadService>.internal(
  modelDownloadService,
  name: r'modelDownloadServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$modelDownloadServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ModelDownloadServiceRef = ProviderRef<ModelDownloadService>;
String _$modelPathHash() => r'3b62d252477b23a4e2498e45b53224dbecdc7ca8';

/// See also [modelPath].
@ProviderFor(modelPath)
final modelPathProvider = FutureProvider<String?>.internal(
  modelPath,
  name: r'modelPathProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$modelPathHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ModelPathRef = FutureProviderRef<String?>;
String _$incognitoModeControllerHash() =>
    r'98740ca2a9269158de9267f7f97f0b9ab4756cb3';

/// See also [IncognitoModeController].
@ProviderFor(IncognitoModeController)
final incognitoModeControllerProvider =
    NotifierProvider<IncognitoModeController, bool>.internal(
      IncognitoModeController.new,
      name: r'incognitoModeControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$incognitoModeControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$IncognitoModeController = Notifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
