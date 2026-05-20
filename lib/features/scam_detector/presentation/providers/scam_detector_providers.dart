import 'package:dio/dio.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scam_message_detector/core/env/env.dart';
import 'package:scam_message_detector/features/scam_detector/data/datasources/gemini_remote_datasource.dart';
import 'package:scam_message_detector/features/scam_detector/data/datasources/gemini_scam_analysis_config.dart';
import 'package:scam_message_detector/features/scam_detector/data/datasources/groq_remote_datasource.dart';
import 'package:scam_message_detector/features/scam_detector/data/repositories/scam_analysis_repository_impl.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/scam_analysis_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/usecases/analyze_message_usecase.dart';

part 'scam_detector_providers.g.dart';

@Riverpod(keepAlive: true)
GenerativeModel scamAnalysisGenerativeModel(
  ScamAnalysisGenerativeModelRef ref,
) {
  final apiKey = Env.geminiApiKey;
  if (apiKey.isEmpty || apiKey == 'your_gemini_api_key_here') {
    throw const GeminiDataSourceException(
      'Missing API key. Copy .env.example to .env and set GEMINI_API_KEY.',
    );
  }
  return createScamAnalysisGenerativeModel(apiKey);
}

@Riverpod(keepAlive: true)
GeminiRemoteDataSource geminiRemoteDataSource(GeminiRemoteDataSourceRef ref) {
  return GeminiRemoteDataSource(ref.watch(scamAnalysisGenerativeModelProvider));
}

@Riverpod(keepAlive: true)
GroqRemoteDataSource groqRemoteDataSource(GroqRemoteDataSourceRef ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.groq.com',
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 60),
      validateStatus: (status) => status != null && status < 500,
    ),
  );
  return GroqRemoteDataSource(dio: dio, apiKey: Env.groqApiKey);
}

@Riverpod(keepAlive: true)
ScamAnalysisRepository scamAnalysisRepository(ScamAnalysisRepositoryRef ref) {
  return ScamAnalysisRepositoryImpl(
    groqRemoteDataSource: ref.watch(groqRemoteDataSourceProvider),
    geminiRemoteDataSource: ref.watch(geminiRemoteDataSourceProvider),
  );
}

@Riverpod(keepAlive: true)
AnalyzeMessageUseCase analyzeMessageUseCase(AnalyzeMessageUseCaseRef ref) {
  return AnalyzeMessageUseCase(ref.watch(scamAnalysisRepositoryProvider));
}
