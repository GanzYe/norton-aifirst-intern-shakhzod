import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:scam_message_detector/core/logging/pipeline_log.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/connectivity_repository.dart';

/// Thin wrapper around [Connectivity] for online/offline routing.
class ConnectivityService implements ConnectivityRepository {
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> isOnline() async {
    PipelineLog.start('CONNECTIVITY');
    final results = await _connectivity.checkConnectivity();
    final online = results.any(_isConnectedResult);
    PipelineLog.done(
      'CONNECTIVITY',
      message: online ? 'device is online' : 'device is offline',
      context: {'transports': results.map((r) => r.name).toList()},
    );
    return online;
  }

  static bool _isConnectedResult(ConnectivityResult result) {
    return switch (result) {
      ConnectivityResult.wifi ||
      ConnectivityResult.mobile ||
      ConnectivityResult.ethernet ||
      ConnectivityResult.vpn ||
      ConnectivityResult.satellite ||
      ConnectivityResult.other => true,
      ConnectivityResult.none || ConnectivityResult.bluetooth => false,
    };
  }
}
