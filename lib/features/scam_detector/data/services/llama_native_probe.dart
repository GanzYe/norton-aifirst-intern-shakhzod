import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:flutter/services.dart';

/// Thin wrapper around the platform `native_health` channel exposed by the
/// host app. Used to check whether the broken `flutter_llama` 1.1.2 native
/// libraries are actually loadable before we hand a model path to the
/// plugin — see `MainActivity.kt` for details.
class LlamaNativeProbe {
  LlamaNativeProbe({MethodChannel? channel})
      : _channel = channel ??
            const MethodChannel(
              'com.norton.intern.scam_message_detector/native_health',
            );

  final MethodChannel _channel;
  bool? _cached;

  Future<bool> isAvailable() async {
    final cached = _cached;
    if (cached != null) return cached;

    // The probe lives on the Android host. On other platforms we don't have
    // a working flutter_llama backend at all, so report unavailable.
    if (!Platform.isAndroid) {
      _cached = false;
      return false;
    }

    try {
      final result = await _channel
          .invokeMethod<bool>('isLlamaNativeAvailable')
          .timeout(const Duration(seconds: 3));
      final available = result ?? false;
      _cached = available;
      return available;
    } on Object catch (e, stack) {
      developer.log(
        'Llama native probe failed; treating model as unavailable',
        name: 'LlamaNativeProbe',
        error: e,
        stackTrace: stack,
      );
      _cached = false;
      return false;
    }
  }

  /// Force a re-probe (e.g. after the user retries the download).
  void invalidate() {
    _cached = null;
  }
}
