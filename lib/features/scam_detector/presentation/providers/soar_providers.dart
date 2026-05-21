import 'package:flutter_llama/flutter_llama.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scam_message_detector/core/env/env.dart';
import 'package:scam_message_detector/features/scam_detector/data/network/osint_dio_factory.dart';
import 'package:scam_message_detector/features/scam_detector/data/repositories/abuse_ipdb_repository_impl.dart';
import 'package:scam_message_detector/features/scam_detector/data/repositories/eml_parse_repository_impl.dart';
import 'package:scam_message_detector/features/scam_detector/data/repositories/local_analysis_repository_impl.dart';
import 'package:scam_message_detector/features/scam_detector/data/repositories/model_repository_impl.dart';
import 'package:scam_message_detector/features/scam_detector/data/repositories/url_scan_repository_impl.dart';
import 'package:scam_message_detector/features/scam_detector/data/repositories/virus_total_repository_impl.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/connectivity_service.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/llama_native_probe.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/local_llama_inference.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/local_pii_redaction_service.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/local_scam_analysis_service.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/abuse_ipdb_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/connectivity_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/eml_parse_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/local_analysis_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/model_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/pii_redaction_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/url_scan_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/virus_total_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/usecases/build_augmented_prompt_usecase.dart';
import 'package:scam_message_detector/features/scam_detector/domain/usecases/orchestrate_scam_analysis_usecase.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/providers/incognito_mode_provider.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/providers/scam_detector_providers.dart';

part 'soar_providers.g.dart';

@Riverpod(keepAlive: true)
VirusTotalRepository virusTotalRepository(VirusTotalRepositoryRef ref) {
  return VirusTotalRepositoryImpl(
    OsintDioFactory.virusTotal(apiKey: Env.virusTotalApiKey),
  );
}

@Riverpod(keepAlive: true)
AbuseIpdbRepository abuseIpdbRepository(AbuseIpdbRepositoryRef ref) {
  return AbuseIpdbRepositoryImpl(
    OsintDioFactory.abuseIpdb(apiKey: Env.abuseIpdbApiKey),
  );
}

@Riverpod(keepAlive: true)
UrlScanRepository urlScanRepository(UrlScanRepositoryRef ref) {
  return UrlScanRepositoryImpl(
    OsintDioFactory.urlScan(apiKey: Env.urlScanApiKey),
  );
}

@Riverpod(keepAlive: true)
EmlParseRepository emlParseRepository(EmlParseRepositoryRef ref) {
  return EmlParseRepositoryImpl();
}

// FIXED: [P1] Expose connectivity via domain [ConnectivityRepository].
@Riverpod(keepAlive: true)
ConnectivityRepository connectivityRepository(ConnectivityRepositoryRef ref) {
  return ConnectivityService();
}

@Riverpod(keepAlive: true)
LlamaNativeProbe llamaNativeProbe(LlamaNativeProbeRef ref) {
  return LlamaNativeProbe();
}

@Riverpod(keepAlive: true)
LocalLlamaInference localLlamaInference(LocalLlamaInferenceRef ref) {
  return LocalLlamaInference(FlutterLlama.instance);
}

@Riverpod(keepAlive: true)
LocalScamAnalysisService localScamAnalysisService(
  LocalScamAnalysisServiceRef ref,
) {
  return LocalScamAnalysisService(
    llamaInference: ref.watch(localLlamaInferenceProvider),
    modelDownloadService: ref.watch(modelDownloadServiceProvider),
    nativeProbe: ref.watch(llamaNativeProbeProvider),
  );
}

@Riverpod(keepAlive: true)
LocalAnalysisRepository localAnalysisRepository(
  LocalAnalysisRepositoryRef ref,
) {
  return LocalAnalysisRepositoryImpl(
    ref.watch(localScamAnalysisServiceProvider),
  );
}

@Riverpod(keepAlive: true)
ModelRepository modelRepository(ModelRepositoryRef ref) {
  return ModelRepositoryImpl(ref.watch(modelDownloadServiceProvider));
}

@Riverpod(keepAlive: true)
PiiRedactionRepository piiRedactionRepository(PiiRedactionRepositoryRef ref) {
  return LocalPiiRedactionService(
    llamaInference: ref.watch(localLlamaInferenceProvider),
    modelDownloadService: ref.watch(modelDownloadServiceProvider),
    nativeProbe: ref.watch(llamaNativeProbeProvider),
  );
}

@Riverpod(keepAlive: true)
BuildAugmentedPromptUseCase buildAugmentedPromptUseCase(
  BuildAugmentedPromptUseCaseRef ref,
) {
  return const BuildAugmentedPromptUseCase();
}

@Riverpod(keepAlive: true)
OrchestrateScamAnalysisUseCase orchestrateScamAnalysisUseCase(
  OrchestrateScamAnalysisUseCaseRef ref,
) {
  return OrchestrateScamAnalysisUseCase(
    scamAnalysisRepository: ref.watch(scamAnalysisRepositoryProvider),
    piiRedactionRepository: ref.watch(piiRedactionRepositoryProvider),
    virusTotalRepository: ref.watch(virusTotalRepositoryProvider),
    abuseIpdbRepository: ref.watch(abuseIpdbRepositoryProvider),
    urlScanRepository: ref.watch(urlScanRepositoryProvider),
    emlParseRepository: ref.watch(emlParseRepositoryProvider),
    buildAugmentedPromptUseCase: ref.watch(buildAugmentedPromptUseCaseProvider),
    connectivityRepository: ref.watch(connectivityRepositoryProvider),
    localAnalysisRepository: ref.watch(localAnalysisRepositoryProvider),
    modelRepository: ref.watch(modelRepositoryProvider),
  );
}
