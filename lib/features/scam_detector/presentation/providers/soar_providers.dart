import 'package:flutter_llama/flutter_llama.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scam_message_detector/core/env/env.dart';
import 'package:scam_message_detector/features/scam_detector/data/network/osint_dio_factory.dart';
import 'package:scam_message_detector/features/scam_detector/data/repositories/abuse_ipdb_repository_impl.dart';
import 'package:scam_message_detector/features/scam_detector/data/repositories/eml_parse_repository_impl.dart';
import 'package:scam_message_detector/features/scam_detector/data/repositories/url_scan_repository_impl.dart';
import 'package:scam_message_detector/features/scam_detector/data/repositories/virus_total_repository_impl.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/local_pii_redaction_service.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/abuse_ipdb_repository.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/providers/incognito_mode_provider.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/eml_parse_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/pii_redaction_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/url_scan_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/virus_total_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/usecases/build_augmented_prompt_usecase.dart';
import 'package:scam_message_detector/features/scam_detector/domain/usecases/orchestrate_scam_analysis_usecase.dart';
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

@Riverpod(keepAlive: true)
PiiRedactionRepository piiRedactionRepository(PiiRedactionRepositoryRef ref) {
  final modelPathAsync = ref.watch(modelPathProvider);
  final path = modelPathAsync.valueOrNull ?? '';
  return LocalPiiRedactionService(
    llama: FlutterLlama.instance,
    modelPath: path,
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
  );
}
