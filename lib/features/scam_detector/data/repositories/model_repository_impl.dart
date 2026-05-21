import 'package:scam_message_detector/features/scam_detector/data/services/model_download_service.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/model_repository.dart';

/// Adapts [ModelDownloadService] to the domain [ModelRepository].
class ModelRepositoryImpl implements ModelRepository {
  const ModelRepositoryImpl(this._service);

  final ModelDownloadService _service;

  @override
  Future<bool> isModelDownloaded() => _service.isModelDownloaded();
}
