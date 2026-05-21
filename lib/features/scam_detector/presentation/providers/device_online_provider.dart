import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/providers/soar_providers.dart';

/// Live online/offline state for contextual UI (e.g. offline warning notes).
final deviceOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  final service = ref.watch(connectivityRepositoryProvider);

  yield await service.isOnline();

  await for (final _ in connectivity.onConnectivityChanged) {
    yield await service.isOnline();
  }
});
