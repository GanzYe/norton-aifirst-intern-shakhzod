/// Whether the on-device GGUF model is present on disk.
abstract interface class ModelRepository {
  Future<bool> isModelDownloaded();
}
