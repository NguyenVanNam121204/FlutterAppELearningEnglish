import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router/route_paths.dart';
import '../../widgets/common/catalunya_scaffold.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/quiz/quiz_question_card.dart';
import '../../widgets/quiz/quiz_step_controls.dart';

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
        context.push(
          '${RoutePaths.lessonResult}?attemptId=${next.submittedAttemptId}',
          extra: next.submittedResult,
        );
        notifier.clearSubmittedAttempt();
      }
    });

    return CatalunyaScaffold(
      appBar: AppBar(title: const Text('Bài kiểm tra')),
      body: Builder(
        builder: (context) {
          if (state.isLoading) {
            return const LoadingStateView();
          }
          if (state.questions.isEmpty && !state.hasAttempt) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.quiz.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.isStarting
                        ? 'Đang tải đề thi...'
                        : 'Không tải được đề thi, vui lòng thử lại.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: state.isStarting ? null : notifier.startAttempt,
                    child: Text(
                      state.isStarting ? 'Đang bắt đầu...' : 'Thử lại',
                    ),
                  ),
                ],
              ),
            );
          }
          if (state.questions.isEmpty && state.hasAttempt) {
            final message = (state.errorMessage ?? '').trim().isNotEmpty
                ? state.errorMessage!
                : 'Không tải được câu hỏi. Vui lòng thử lại.';
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFFDC2626),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: state.isStarting
                        ? null
                        : () => notifier.startAttempt(forceStartNew: true),
                    child: Text(state.isStarting ? 'Đang xử lý...' : 'Thử lại'),
                  ),
                ],
              ),
            );
          }
          final clampedIndex = state.currentIndex.clamp(
            0,
            state.questions.length - 1,
          );
          final q = state.questions[clampedIndex];
          final qid = q.questionId;
          final answer = state.answers[qid];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                state.quiz.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (state.remainingSeconds != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Thời gian còn lại: ${(state.remainingSeconds! ~/ 60).toString().padLeft(2, '0')}:${(state.remainingSeconds! % 60).toString().padLeft(2, '0')}',
                ),
              ],
              const SizedBox(height: 12),
              if (!state.hasAttempt)
                FilledButton(
                  onPressed: state.isStarting ? null : notifier.startAttempt,
                  child: Text(
                    state.isStarting ? 'Đang bắt đầu...' : 'Bắt đầu làm bài',
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                'Câu ${clampedIndex + 1}/${state.questions.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              QuizQuestionCard(
                question: q,
                answer: answer,
                hasAttempt: state.hasAttempt,
                onTextChanged: (v) => notifier.setTextAnswer(qid, v),
                onToggleMulti: (optionId, checked) =>
                    notifier.toggleMultiAnswer(qid, optionId, checked),
                onSelectSingle: (optionId) =>
                    notifier.setSingleAnswer(qid, optionId),
                onSetMatching: (pairs) =>
                    notifier.setMatchingAnswer(qid, pairs),
                onSetOrdering: (orderedIds) =>
                    notifier.setOrderingAnswer(qid, orderedIds),
              ),
              QuizStepControls(
                canGoBack: clampedIndex > 0,
                canGoNext: clampedIndex < state.questions.length - 1,
                onBack: notifier.previousQuestion,
                onNext: notifier.nextQuestion,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: (!state.hasAttempt || state.isSubmitting)
                    ? null
                    : notifier.submitAttempt,
                child: Text(state.isSubmitting ? 'Đang nộp bài...' : 'Nộp bài'),
              ),
            ],
          );
        },
      ),
    );
  }
}
