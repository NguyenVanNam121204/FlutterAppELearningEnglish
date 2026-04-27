import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router/route_paths.dart';
import '../../../viewmodels/quiz/quiz_screen_viewmodel.dart';
import '../../widgets/common/catalunya_scaffold.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/quiz/quiz_question_card.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({
    required this.quizId,
    this.attemptId,
    this.forceNewAttempt = false,
    super.key,
  });
  final String quizId;
  final String? attemptId;
  final bool forceNewAttempt;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(quizScreenViewModelProvider(widget.quizId).notifier)
          .initialize(
            widget.quizId,
            resumeAttemptId: widget.attemptId,
            forceStartNew: widget.forceNewAttempt,
          );
    });
  }

  String _formatRemaining(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _onSubmitPressed(
    QuizScreenState state,
    QuizScreenViewModel notifier,
  ) async {
    if (!state.hasAttempt || state.isSubmitting) return;

    final answeredCount = state.answers.keys.length;
    final totalQuestions = state.questions.length;
    if (answeredCount < totalQuestions && mounted) {
      final shouldSubmit = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Chưa hoàn thành'),
            content: Text(
              'Bạn mới trả lời $answeredCount/$totalQuestions câu. Bạn có chắc muốn nộp bài?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Tiếp tục làm'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Nộp bài'),
              ),
            ],
          );
        },
      );
      if (shouldSubmit != true) return;
    }

    await notifier.submitAttempt();
  }

  Future<void> _goBack() async {
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
      return;
    }
    if (mounted) {
      context.go(RoutePaths.mainAppHome);
    }
  }

  Future<void> _continueAttempt(QuizScreenViewModel notifier) async {
    await notifier.startAttempt(
      resumeAttemptId: widget.attemptId,
      forceStartNew: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizScreenViewModelProvider(widget.quizId));
    final notifier = ref.read(
      quizScreenViewModelProvider(widget.quizId).notifier,
    );

    ref.listen(quizScreenViewModelProvider(widget.quizId), (prev, next) {
      if ((prev?.errorMessage != next.errorMessage) &&
          (next.errorMessage?.isNotEmpty ?? false) &&
          next.questions.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
        notifier.clearError();
      }
      if ((prev?.submittedAttemptId != next.submittedAttemptId) &&
          (next.submittedAttemptId?.isNotEmpty ?? false)) {
        context.pushReplacement(
          '${RoutePaths.lessonResult}?attemptId=${next.submittedAttemptId}',
          extra: next.submittedResult,
        );
        notifier.clearSubmittedAttempt();
      }
    });

    return CatalunyaScaffold(
      appBar: (state.questions.isEmpty || state.isLoading)
          ? AppBar(
              title: Text(state.quiz.title.isNotEmpty
                  ? state.quiz.title
                  : 'Chi tiết bài tập'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBack,
              ),
            )
          : null,
      body: Builder(
        builder: (context) {
          if (state.isLoading) {
            return const LoadingStateView();
          }
          if (state.questions.isEmpty) {
            final isCannotContinue = (state.errorMessage ?? '')
                .contains('Bài quiz này đã được nộp hoặc không thể tiếp tục');
            final message = (state.errorMessage ?? '').trim().isNotEmpty
                ? state.errorMessage!
                : 'Không tải được đề thi, vui lòng thử lại.';

            return _QuizInfoView(
              title: state.quiz.title.isNotEmpty
                  ? state.quiz.title
                  : 'Thông báo',
              message: state.isStarting ? 'Đang tải đề thi...' : message,
              icon: isCannotContinue
                  ? Icons.lock_clock_outlined
                  : Icons.quiz_outlined,
              onBack: _goBack,
              onRetry: (state.isStarting || isCannotContinue)
                  ? null
                  : () => _continueAttempt(notifier),
              retryLabel: state.isStarting ? 'Đang xử lý...' : 'Thử lại',
            );
          }

          final clampedIndex = state.currentIndex.clamp(
            0,
            state.questions.length - 1,
          );
          final question = state.questions[clampedIndex];
          final questionId = question.questionId;
          final answer = state.answers[questionId];

          final warning = (state.remainingSeconds ?? 999999) < 300;
          final danger = (state.remainingSeconds ?? 999999) < 60;
          final answeredIds = state.answers.keys.toSet();

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        state.quiz.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    TextButton(
                      onPressed: state.hasAttempt && !state.isSubmitting
                          ? () => _onSubmitPressed(state, notifier)
                          : null,
                      child: const Text('Nộp bài'),
                    ),
                  ],
                ),
              ),
              if (state.remainingSeconds != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: danger
                      ? const Color(0xFFFEE2E2)
                      : warning
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFEFF6FF),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.schedule,
                        color: danger
                            ? const Color(0xFFEF4444)
                            : warning
                            ? const Color(0xFFF59E0B)
                            : Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatRemaining(state.remainingSeconds!),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: danger
                              ? const Color(0xFFEF4444)
                              : warning
                              ? const Color(0xFFF59E0B)
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                color: Theme.of(context).cardColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < state.questions.length; i++)
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(
                            right: i == state.questions.length - 1 ? 0 : 6,
                          ),
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: i == clampedIndex
                                ? const Color(0xFFEF4444)
                                : answeredIds.contains(
                                    state.questions[i].questionId,
                                  )
                                ? const Color(0xFF10B981)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: QuizQuestionCard(
                    question: question,
                    answer: answer,
                    hasAttempt: state.hasAttempt,
                    questionNumber: clampedIndex + 1,
                    totalQuestions: state.questions.length,
                    onTextChanged: (v) => notifier.setTextAnswer(questionId, v),
                    onToggleMulti: (optionId, checked) => notifier
                        .toggleMultiAnswer(questionId, optionId, checked),
                    onSelectSingle: (optionId) =>
                        notifier.setSingleAnswer(questionId, optionId),
                    onSetMatching: (pairs) =>
                        notifier.setMatchingAnswer(questionId, pairs),
                    onSetOrdering: (orderedIds) =>
                        notifier.setOrderingAnswer(questionId, orderedIds),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: clampedIndex > 0
                          ? notifier.previousQuestion
                          : null,
                      icon: const Icon(Icons.chevron_left),
                      label: const Text('Trước'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: clampedIndex == state.questions.length - 1
                          ? FilledButton.icon(
                              onPressed: state.isSubmitting
                                  ? null
                                  : () => _onSubmitPressed(state, notifier),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                backgroundColor: const Color(0xFF059669),
                              ),
                              icon: state.isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check_circle),
                              label: Text(
                                state.isSubmitting ? 'Đang nộp...' : 'Nộp bài',
                              ),
                            )
                          : FilledButton.icon(
                              onPressed: notifier.nextQuestion,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                              ),
                              iconAlignment: IconAlignment.end,
                              icon: const Icon(Icons.chevron_right),
                              label: const Text('Tiếp theo'),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuizInfoView extends StatelessWidget {
  const _QuizInfoView({
    required this.title,
    required this.message,
    required this.onBack,
    this.onRetry,
    this.retryLabel,
    this.icon,
  });

  final String title;
  final String message;
  final VoidCallback onBack;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isError = message.contains('không thể tiếp tục') ||
        message.contains('Không tải được');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: (isError ? Colors.red : Colors.blue).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon ?? Icons.info_outline_rounded,
              size: 64,
              color: isError ? Colors.red : Colors.blue,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'QUAY LẠI',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onRetry,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      retryLabel?.toUpperCase() ?? 'TIẾP TỤC',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
