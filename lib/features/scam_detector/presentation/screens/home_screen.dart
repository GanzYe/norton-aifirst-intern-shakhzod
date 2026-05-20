import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scam_message_detector/core/constants/app_branding.dart';
import 'package:scam_message_detector/core/theme/app_colors.dart';
import 'package:scam_message_detector/core/theme/app_durations.dart';
import 'package:scam_message_detector/core/theme/app_sizes.dart';
import 'package:scam_message_detector/core/theme/app_spacing.dart';
import 'package:scam_message_detector/core/theme/app_text_styles.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/scam_analysis.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/providers/device_online_provider.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/providers/incognito_mode_provider.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/providers/scam_analysis_controller.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/utils/friendly_error.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/widgets/analysis_background_lifecycle.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/widgets/analysis_loading_indicator.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/widgets/analysis_notes_section.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/widgets/app_modal_dialog.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/widgets/example_samples_row.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/widgets/incognito_mode_switch.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/widgets/measure_size.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/widgets/message_field_shell.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/widgets/message_input_field.dart';
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
  String? _attachedEmlName;
  late final AnimationController _resultAnimController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  ScamAnalysis? _lastShownAnalysis;
  bool _inputFocused = false;
  double _inputSlotHeight = AppSizes.inputFieldMinHeight;

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
      _attachedEmlName = file.name;
      _messageController.text = 'Attached EML: ${file.name}';
    });
    ref.read(scamAnalysisControllerProvider.notifier).reset();
    _resultAnimController.reset();
    setState(() => _lastShownAnalysis = null);
  }

  void _clearEmlAttachment() {
    setState(() {
      _attachedEmlRaw = null;
      _attachedEmlName = null;
      if (_messageController.text.startsWith('Attached EML:')) {
        _messageController.clear();
      }
    });
  }

  Widget? _buildAnalysisResult(ScamAnalysis analysis) {
    if (analysis.localModelUnavailable || analysis.localAnalysisFailed) {
      return null;
    }
    return ResultCard(analysis: analysis);
  }

  void _maybeShowAnalysisWarning(ScamAnalysis analysis) {
    if (!mounted) return;

    if (analysis.localModelUnavailable) {
      showAppNoticeDialog(
        context,
        title: 'Analysis unavailable',
        message:
            "No internet connection and the local model hasn't been "
            'downloaded yet. Please connect to the internet to analyze '
            'this message, or enable Incognito mode to download the '
            'on-device model.',
        tone: AppModalTone.danger,
        icon: Icons.cloud_off_outlined,
      );
      return;
    }

    if (analysis.localAnalysisFailed) {
      showAppNoticeDialog(
        context,
        title: 'On-device analysis failed',
        message:
            "We couldn't complete on-device analysis for this message. "
            'Please connect to the internet for full analysis, or try '
            'again in a moment.',
        tone: AppModalTone.danger,
        icon: Icons.report_gmailerrorred_outlined,
      );
      return;
    }

    if (analysis.resolvedLocally) {
      final cloudFallback = analysis.cloudFallback;
      showAppNoticeDialog(
        context,
        title: 'Local analysis only',
        tone: AppModalTone.warning,
        message: cloudFallback
            ? 'Cloud analysis is temporarily unavailable. This result was '
                  'generated on-device and may be less accurate. Try again '
                  'later for full analysis.'
            : 'No internet connection. This result was generated '
                  'on-device and may be less accurate. Connect to the '
                  'internet for full analysis.',
      );
    }
  }

  void _onExampleTap(String body) {
    _messageController.text = body;
    setState(() {
      _attachedEmlRaw = null;
      _attachedEmlName = null;
    });
    ref.read(scamAnalysisControllerProvider.notifier).reset();
    _resultAnimController.reset();
    setState(() => _lastShownAnalysis = null);
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(scamAnalysisControllerProvider);
    final isLoading = analysisState.isLoading;
    final incognito = ref.watch(incognitoModeControllerProvider);
    final isOnline = ref.watch(deviceOnlineProvider).value ?? true;
    final showContextNotes = incognito || !isOnline;

    ref.listen(scamAnalysisControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (analysis) {
          if (analysis != null && analysis != _lastShownAnalysis) {
            setState(() => _lastShownAnalysis = analysis);
            _resultAnimController.forward(from: 0);
            _maybeShowAnalysisWarning(analysis);
          }
        },
      );
      if ((previous?.isLoading ?? false) && next.hasError && mounted) {
        showAppNoticeDialog(
          context,
          title: 'Analysis failed',
          message: friendlyAnalysisError(next.error),
          tone: AppModalTone.danger,
        );
      }
    });

    final analysis = analysisState.valueOrNull;
    final resultWidget =
        analysis != null ? _buildAnalysisResult(analysis) : null;
    final muted = AppColors.resolveTextMuted(incognito: incognito);

    return AnalysisBackgroundLifecycle(
      child: Scaffold(
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
                        AppBranding.name,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Paste a suspicious SMS, email body, or link—or '
                        'attach an .eml file—and tap Analyze. We score scam '
                        'risk with AI and explain what looks unsafe.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.homeSubtitle.copyWith(
                          color: muted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      IncognitoModeSwitch(enabled: !isLoading),
                      const SizedBox(height: AppSpacing.md),
                      ExampleSamplesRow(
                        incognito: incognito,
                        enabled: !isLoading,
                        onSampleTap: _onExampleTap,
                      ),
                      if (showContextNotes) ...[
                        const SizedBox(height: AppSpacing.md),
                        AnalysisNotesSection(
                          incognito: incognito,
                          isOnline: isOnline,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ] else
                        const SizedBox(height: AppSpacing.md),
                      MessageFieldShell(
                        incognito: incognito,
                        focused: !isLoading && _inputFocused,
                        child: AnimatedSwitcher(
                          duration: AppDurations.loaderCrossfade,
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeOutCubic,
                          layoutBuilder: (current, previous) {
                            return Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                ...previous,
                                if (current != null) current,
                              ],
                            );
                          },
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                          child: isLoading
                              ? SizedBox(
                                  key: const ValueKey('loader'),
                                  width: double.infinity,
                                  height: _inputSlotHeight,
                                  child: AnalysisLoadingIndicator(
                                    incognito: incognito,
                                  ),
                                )
                              : MeasureSize(
                                  key: const ValueKey('input'),
                                  onChange: (size) {
                                    if (size.height <= 0) {
                                      return;
                                    }
                                    if ((size.height - _inputSlotHeight).abs() >
                                        1) {
                                      setState(
                                        () => _inputSlotHeight = size.height,
                                      );
                                    }
                                  },
                                  child: MessageInputField(
                                    controller: _messageController,
                                    enabled: !isLoading,
                                    incognito: incognito,
                                    onAnalyze: _onAnalyze,
                                    onPickEml: _onPickEml,
                                    onClearEml: _clearEmlAttachment,
                                    attachedEmlName: _attachedEmlName,
                                    onFocusChanged: (focused) {
                                      setState(() => _inputFocused = focused);
                                    },
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (resultWidget != null)
                SliverPadding(
                  padding: AppSpacing.resultSection,
                  sliver: SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: resultWidget,
                      ),
                    ),
                  ),
                )
              else
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxl),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
