import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class ModelDownloadException implements Exception {
  ModelDownloadException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class ModelDownloadService {
  ModelDownloadService({Dio? dio}) : _dio = dio ?? _createDownloadDio();

  static const modelDisplayName = 'Qwen2.5-1.5B-Instruct';

  static const _modelUrl =
      'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/'
      'qwen2.5-1.5b-instruct-q4_k_m.gguf';
  static const _fileName = 'qwen2.5-1.5b-instruct-q4_k_m.gguf';

  final Dio _dio;

  static Dio _createDownloadDio() {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(hours: 2),
        sendTimeout: const Duration(minutes: 5),
      ),
    );
  }

  Future<File> _modelFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<bool> isModelDownloaded() async {
    final file = await _modelFile();
    if (!file.existsSync()) {
      return false;
    }
    return file.lengthSync() > 0;
  }

  Future<String> getModelPath() async {
    final file = await _modelFile();
    return file.path;
  }

  Future<String> downloadModel({
    required void Function(double progress) onProgress,
  }) async {
    final file = await _modelFile();
    final tempFile = File('${file.path}.partial');

    try {
      await _dio.download(
        _modelUrl,
        tempFile.path,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress(received / total);
          }
        },
      );

      if (await file.exists()) {
        await file.delete();
      }
      await tempFile.rename(file.path);

      return file.path;
    } on DioException catch (e) {
      await _deleteIfExists(tempFile);
      final message = switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout =>
          'Download timed out. Check your connection and try again.',
        DioExceptionType.connectionError =>
          'Connection lost. Check your network and try again.',
        _ => e.message ?? 'Model download failed.',
      };
      throw ModelDownloadException(message, cause: e);
    } on Object catch (e) {
      await _deleteIfExists(tempFile);
      if (e is ModelDownloadException) {
        rethrow;
      }
      throw ModelDownloadException(
        'Model download failed.',
        cause: e,
      );
    }
  }

  Future<void> deleteModel() async {
    final file = await _modelFile();
    await _deleteIfExists(file);
    await _deleteIfExists(File('${file.path}.partial'));
  }

  Future<void> _deleteIfExists(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }
}
