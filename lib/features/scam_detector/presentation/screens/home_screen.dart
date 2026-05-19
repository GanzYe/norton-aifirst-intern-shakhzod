import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scam_message_detector/core/theme/app_decorations.dart';
import 'package:scam_message_detector/core/theme/app_durations.dart';
import 'package:scam_message_detector/core/theme/app_sizes.dart';
import 'package:scam_message_detector/core/theme/app_spacing.dart';
import 'package:scam_message_detector/core/theme/app_text_styles.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/scam_analysis.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/constants/example_messages.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/providers/scam_analysis_controller.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/widgets/analyze_button.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/widgets/incognito_mode_switch.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/widgets/example_message_tile.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/widgets/local_analysis_warning_banner.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/widgets/local_model_unavailable_message.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/widgets/result_card.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/widgets/smd_logo.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();
  String? _attachedEmlRaw;
  late final AnimationController _resultAnimController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  ScamAnalysis? _lastShownAnalysis;

  @override
  void initState() {
    super.initState();
    _resultAnimController = AnimationController(
      vsync: this,
      duration: AppDurations.resultAnimation,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _resultAnimController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _resultAnimController,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _resultAnimController.dispose();
    super.dispose();
  }

  Future<void> _onAnalyze() async {
    FocusScope.of(context).unfocus();
    _resultAnimController.reset();
    await ref.read(scamAnalysisControllerProvider.notifier).analyze(
          message: _messageController.text,
          emlRawContent: _attachedEmlRaw,
        );
  }

  Future<void> _onPickEml() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['eml'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      return;
    }
    final raw = String.fromCharCodes(bytes);
    setState(() {
      _attachedEmlRaw = raw;
      _messageController.text = 'Attached EML: ${file.name}';
    });
    ref.read(scamAnalysisControllerProvider.notifier).reset();
    _resultAnimController.reset();
    setState(() => _lastShownAnalysis = null);
  }

  void _clearEmlAttachment() {
    setState(() => _attachedEmlRaw = null);
  }

  Widget _buildAnalysisResult(ScamAnalysis analysis) {
    if (analysis.localModelUnavailable) {
      return const LocalModelUnavailableMessage();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (analysis.resolvedLocally) ...[
          const LocalAnalysisWarningBanner(),
          const SizedBox(height: AppSpacing.md),
        ],
        ResultCard(analysis: analysis),
      ],
    );
  }

  void _onExampleTap(String body) {
    _messageController.text = body;
    _attachedEmlRaw = null;
    ref.read(scamAnalysisControllerProvider.notifier).reset();
    _resultAnimController.reset();
    setState(() => _lastShownAnalysis = null);
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(scamAnalysisControllerProvider);
    final isLoading = analysisState.isLoading;

    ref.listen(scamAnalysisControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (analysis) {
          if (analysis != null && analysis != _lastShownAnalysis) {
            setState(() => _lastShownAnalysis = analysis);
            _resultAnimController.forward(from: 0);
          }
        },
      );
      if (previous?.isLoading == true && next.hasError && mounted) {
        final error = next.error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error?.toString() ?? 'Analysis failed.')),
        );
      }
    });

    final analysis = analysisState.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const SmdLogo(size: AppSizes.logoAppBar),
        centerTitle: false,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: AppSpacing.screenContent,
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Scam Message Detector',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Paste a suspicious SMS, email, or URL below. '
                      'Our AI will assess the scam risk instantly.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.homeSubtitle,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: _messageController,
                      enabled: !isLoading,
                      maxLines: null,
                      minLines: 5,
                      decoration: AppDecorations.inputField(
                        hintText:
                            'Enter a URL, message, email,'
                            ' or snippet to check for scams.',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    IncognitoModeSwitch(enabled: !isLoading),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: isLoading ? null : _onPickEml,
                          icon: const Icon(Icons.attach_email_outlined),
                          label: const Text('Upload .eml'),
                        ),
                        if (_attachedEmlRaw != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          TextButton(
                            onPressed: isLoading ? null : _clearEmlAttachment,
                            child: const Text('Clear EML'),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AnalyzeButton(isLoading: isLoading, onPressed: _onAnalyze),
                    const SizedBox(height: AppSpacing.xl),
                    const Text(
                      'Try an example',
                      style: AppTextStyles.sectionLabel,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...ExampleMessages.samples.map(
                      (sample) => Padding(
                        padding: AppSpacing.exampleItemBottom,
                        child: ExampleMessageTile(
                          title: sample.title,
                          onTap: () => _onExampleTap(sample.body),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (analysis != null)
              SliverPadding(
                padding: AppSpacing.resultSection,
                sliver: SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildAnalysisResult(analysis),
                    ),
                  ),
                ),
              )
            else
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    );
  }
}
