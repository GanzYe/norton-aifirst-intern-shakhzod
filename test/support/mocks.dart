import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_llama/flutter_llama.dart';
import 'package:mockito/annotations.dart';
import 'package:scam_message_detector/features/scam_detector/data/datasources/gemini_remote_datasource.dart';
import 'package:scam_message_detector/features/scam_detector/data/datasources/groq_remote_datasource.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/connectivity_service.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/llama_native_probe.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/local_scam_analysis_service.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/model_download_service.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/abuse_ipdb_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/eml_parse_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/pii_redaction_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/scam_analysis_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/url_scan_repository.dart';
import 'package:scam_message_detector/features/scam_detector/domain/repositories/virus_total_repository.dart';

/// Single source-of-truth for generated `mockito` mocks used across the
/// test suite. Run `dart run build_runner build --delete-conflicting-outputs`
/// after editing this list.
@GenerateNiceMocks([
  MockSpec<FlutterLlama>(),
  MockSpec<ModelDownloadService>(),
  MockSpec<LlamaNativeProbe>(),
  MockSpec<Connectivity>(),
  MockSpec<ConnectivityService>(),
  MockSpec<GroqRemoteDataSource>(),
  MockSpec<GeminiRemoteDataSource>(),
  MockSpec<ScamAnalysisRepository>(),
  MockSpec<VirusTotalRepository>(),
  MockSpec<AbuseIpdbRepository>(),
  MockSpec<UrlScanRepository>(),
  MockSpec<EmlParseRepository>(),
  MockSpec<PiiRedactionRepository>(),
  MockSpec<LocalScamAnalysisService>(),
])
void main() {}
