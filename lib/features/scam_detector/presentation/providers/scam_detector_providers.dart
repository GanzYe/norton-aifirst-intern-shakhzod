import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scam_message_detector/core/network/dio_provider.dart';
import 'package:scam_message_detector/features/scam_detector/data/datasources/anthropic_remote_datasource.dart';
import 'package:scam_message_detector/features/scam_detector/data/repositories/scam_analysis_repository_impl.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/scam_analysis_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/usecases/analyze_message_usecase.dart';

part 'scam_detector_providers.g.dart';

@Riverpod(keepAlive: true)
AnthropicRemoteDataSource anthropicRemoteDataSource(
  AnthropicRemoteDataSourceRef ref,
) {
  return AnthropicRemoteDataSource(ref.watch(dioProvider));
}

@Riverpod(keepAlive: true)
ScamAnalysisRepository scamAnalysisRepository(ScamAnalysisRepositoryRef ref) {
  return ScamAnalysisRepositoryImpl(ref.watch(anthropicRemoteDataSourceProvider));
}

@Riverpod(keepAlive: true)
AnalyzeMessageUseCase analyzeMessageUseCase(AnalyzeMessageUseCaseRef ref) {
  return AnalyzeMessageUseCase(ref.watch(scamAnalysisRepositoryProvider));
}
