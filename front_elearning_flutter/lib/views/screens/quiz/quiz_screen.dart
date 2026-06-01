import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router/route_paths.dart';
import '../../../viewmodels/quiz/quiz_screen_viewmodel.dart';
import '../../widgets/quiz/game/game_quiz_constants.dart';
import '../../widgets/quiz/game/game_quiz_question_card.dart';

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
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
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
            backgroundColor: GameQuizColors.surface,
            title: const Text(
              'Chưa hoàn thành',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Bạn mới trả lời $answeredCount/$totalQuestions câu. Bạn có chắc muốn nộp bài?',
              style: const TextStyle(color: GameQuizColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Tiếp tục'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: GameQuizColors.correct,
                ),
                child: const Text(
                  'Nộp bài',
                  style: TextStyle(color: Colors.black),
                ),
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizScreenViewModelProvider(widget.quizId));
    final notifier = ref.read(
      quizScreenViewModelProvider(widget.quizId).notifier,
    );

    ref.listen<QuizScreenState>(quizScreenViewModelProvider(widget.quizId), (
      prev,
      next,
    ) {
      if (prev != null &&
          prev.errorMessage != next.errorMessage &&
          (next.errorMessage?.isNotEmpty ?? false) &&
          next.questions.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: GameQuizColors.incorrect,
            content: Text(
              next.errorMessage!,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
        notifier.clearError();
      }
      if (prev != null &&
          prev.submittedAttemptId != next.submittedAttemptId &&
          (next.submittedAttemptId?.isNotEmpty ?? false)) {
        context.pushReplacement(
          '${RoutePaths.lessonResult}?attemptId=${next.submittedAttemptId}',
          extra: next.submittedResult,
        );
        notifier.clearSubmittedAttempt();
      }
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: GameQuizColors.bgGradient,
          ),
        ),
        child: SafeArea(
          child: Builder(
            builder: (context) {
              if (state.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: GameQuizColors.primary,
                  ),
                );
              }

              if (state.questions.isEmpty) {
                return _buildEmptyState(state, notifier);
              }

              final clampedIndex = state.currentIndex.clamp(
                0,
                state.questions.length - 1,
              );
              final question = state.questions[clampedIndex];
              final questionId = question.questionId;
              final answer = state.answers[questionId];

              return Column(
                children: [
                  // Game Header
                  _buildGameHeader(state, notifier, clampedIndex),

                  // Question Card
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: GameQuizQuestionCard(
                        question: question,
                        answer: answer,
                        onTextChanged: (v) =>
                            notifier.setTextAnswer(questionId, v),
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

                  // Bottom Controls
                  _buildBottomControls(state, notifier, clampedIndex),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGameHeader(
    QuizScreenState state,
    QuizScreenViewModel notifier,
    int currentIndex,
  ) {
    final progress = (currentIndex + 1) / state.questions.length;
    final timeStr = state.remainingSeconds != null
        ? _formatRemaining(state.remainingSeconds!)
        : "--:--";
    final isWarning = (state.remainingSeconds ?? 999) < 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _goBack,
                icon: const Icon(Icons.close, color: Colors.white70),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      GameQuizColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isWarning
                      ? GameQuizColors.incorrect.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isWarning
                        ? GameQuizColors.incorrect
                        : Colors.white24,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 18,
                      color: isWarning
                          ? GameQuizColors.incorrect
                          : Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: TextStyle(
                        color: isWarning
                            ? GameQuizColors.incorrect
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Câu hỏi ${currentIndex + 1}/${state.questions.length}",
            style: const TextStyle(
              color: GameQuizColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(
    QuizScreenState state,
    QuizScreenViewModel notifier,
    int currentIndex,
  ) {
    final isLast = currentIndex == state.questions.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          if (currentIndex > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: notifier.previousQuestion,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          if (currentIndex > 0) const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: FilledButton(
              onPressed: isLast
                  ? () => _onSubmitPressed(state, notifier)
                  : notifier.nextQuestion,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: isLast
                    ? GameQuizColors.correct
                    : GameQuizColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor:
                    (isLast ? GameQuizColors.correct : GameQuizColors.primary)
                        .withValues(alpha: 0.5),
              ),
              child: Text(
                isLast
                    ? (state.isSubmitting ? "Đang nộp..." : "NỘP BÀI")
                    : "TIẾP THEO",
                style: TextStyle(
                  color: isLast ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(QuizScreenState state, QuizScreenViewModel notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.quiz_outlined,
              size: 80,
              color: GameQuizColors.primary,
            ),
            const SizedBox(height: 24),
            Text(
              state.quiz.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              state.errorMessage ?? "Sẵn sàng bắt đầu thử thách?",
              style: const TextStyle(
                color: GameQuizColors.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => notifier.startAttempt(),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: GameQuizColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  "BẮT ĐẦU LÀM BÀI",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _goBack,
              child: const Text(
                "Quay lại",
                style: TextStyle(color: GameQuizColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
