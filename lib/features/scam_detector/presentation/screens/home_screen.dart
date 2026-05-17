import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scam_message_detector/core/theme/app_colors.dart';
import 'package:scam_message_detector/features/scam_detector/domain/entities/scam_analysis.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/constants/example_messages.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/providers/scam_analysis_controller.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/widgets/analyze_button.dart';
import 'package:scam_message_detector/features/scam_detector/presentation/widgets/example_message_tile.dart';
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
  late final AnimationController _resultAnimController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  ScamAnalysis? _lastShownAnalysis;

  @override
  void initState() {
    super.initState();
    _resultAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _resultAnimController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _resultAnimController, curve: Curves.easeOutCubic),
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
    await ref
        .read(scamAnalysisControllerProvider.notifier)
        .analyze(_messageController.text);
  }

  void _onExampleTap(String body) {
    _messageController.text = body;
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
          SnackBar(
            content: Text(error?.toString() ?? 'Analysis failed.'),
            backgroundColor: AppColors.dangerousRed,
          ),
        );
      }
    });

    final analysis = analysisState.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const SmdLogo(size: 32),
        centerTitle: false,
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Scam Message Detector',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Paste a suspicious SMS, email, or URL below. '
                      'Our AI will assess the scam risk instantly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _messageController,
                      enabled: !isLoading,
                      maxLines: null,
                      minLines: 5,
                      decoration: InputDecoration(
                        hintText:
                            'Enter a URL, message, email, or snippet to check for scams.',
                        hintStyle: TextStyle(
                          color: AppColors.textMuted.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.borderBlack,
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.borderBlack,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.borderBlack,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnalyzeButton(
                      isLoading: isLoading,
                      onPressed: _onAnalyze,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Try an example',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...ExampleMessages.samples.map(
                      (sample) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                sliver: SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ResultCard(analysis: analysis),
                    ),
                  ),
                ),
              )
            else
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}
