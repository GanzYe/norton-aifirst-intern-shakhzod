/// Online/offline routing for the analysis pipeline.
abstract interface class ConnectivityRepository {
  Future<bool> isOnline();
}
