import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper around [Connectivity] for online/offline routing.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.any(_isConnectedResult);
  }

  static bool _isConnectedResult(ConnectivityResult result) {
    return switch (result) {
      ConnectivityResult.wifi ||
      ConnectivityResult.mobile ||
      ConnectivityResult.ethernet ||
      ConnectivityResult.vpn ||
      ConnectivityResult.satellite ||
      ConnectivityResult.other =>
        true,
      ConnectivityResult.none || ConnectivityResult.bluetooth => false,
    };
  }
}
