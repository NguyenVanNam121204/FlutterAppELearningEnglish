import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/result/result.dart';
import '../../models/learning/lesson_models.dart';
import '../../models/quiz/quiz_models.dart';
import '../../repositories/quiz/quiz_repository.dart';

class QuizAnswerModel {
  const QuizAnswerModel({
    this.textAnswer,
    this.singleOptionId,
    this.multiOptionIds = const <String>{},
    this.matchingPairs = const <String, String>{},
    this.orderingOptionIds = const <String>[],
  });

  final String? textAnswer;
  final String? singleOptionId;
  final Set<String> multiOptionIds;
  final Map<String, String> matchingPairs;
  final List<String> orderingOptionIds;

  Object? toRequestValue() {
    if (matchingPairs.isNotEmpty) {
      return matchingPairs.map<String, Object>(
        (left, right) => MapEntry(
          (int.tryParse(left) ?? left).toString(),
          int.tryParse(right) ?? right,
        ),
      );
    }
    if (orderingOptionIds.isNotEmpty) {
      return orderingOptionIds
          .map((id) => int.tryParse(id) ?? id)
          .toList(growable: false);
    }
    if (multiOptionIds.isNotEmpty) {
      return multiOptionIds
          .map((id) => int.tryParse(id) ?? id)
          .toList(growable: false);
    }
    if ((singleOptionId ?? '').isNotEmpty) {
      return int.tryParse(singleOptionId!) ?? singleOptionId;
    }
    if ((textAnswer ?? '').isNotEmpty) return textAnswer;
    return null;
  }
}

class QuizScreenState {
  const QuizScreenState({
    this.isLoading = false,
    this.errorMessage,
    this.quiz = const QuizDetailModel.empty(),
    this.questions = const [],
    this.attemptId,
    this.isStarting = false,
    this.isSubmitting = false,
    this.answers = const {},
    this.currentIndex = 0,
    this.remainingSeconds,
    this.submittedAttemptId,
    this.submittedResult,
  });

  final bool isLoading;
  final String? errorMessage;
  final QuizDetailModel quiz;
  final List<QuizQuestionModel> questions;
  final String? attemptId;
  final bool isStarting;
  final bool isSubmitting;
  final Map<String, QuizAnswerModel> answers;
  final int currentIndex;
  final int? remainingSeconds;
  final String? submittedAttemptId;
  final LessonResultModel? submittedResult;

  bool get hasAttempt => (attemptId ?? '').isNotEmpty;

  QuizScreenState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    QuizDetailModel? quiz,
    List<QuizQuestionModel>? questions,
    String? attemptId,
    bool clearAttemptId = false,
    bool? isStarting,
    bool? isSubmitting,
    Map<String, QuizAnswerModel>? answers,
    int? currentIndex,
    int? remainingSeconds,
    bool clearRemainingSeconds = false,
    String? submittedAttemptId,
    bool clearSubmittedAttemptId = false,
    LessonResultModel? submittedResult,
    bool clearSubmittedResult = false,
  }) {
    return QuizScreenState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      quiz: quiz ?? this.quiz,
      questions: questions ?? this.questions,
      attemptId: clearAttemptId ? null : attemptId ?? this.attemptId,
      isStarting: isStarting ?? this.isStarting,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      answers: answers ?? this.answers,
      currentIndex: currentIndex ?? this.currentIndex,
      remainingSeconds: clearRemainingSeconds
          ? null
          : remainingSeconds ?? this.remainingSeconds,
      submittedAttemptId: clearSubmittedAttemptId
          ? null
          : submittedAttemptId ?? this.submittedAttemptId,
      submittedResult: clearSubmittedResult
          ? null
          : submittedResult ?? this.submittedResult,
    );
  }
}

class QuizScreenViewModel extends StateNotifier<QuizScreenState> {
  QuizScreenViewModel(this._repository) : super(const QuizScreenState());

  static const String _cannotContinueMessage =
      'Bài quiz này đã được nộp hoặc không thể tiếp tục. Vui lòng quay lại danh sách bài tập để làm quiz mới.';

  final QuizRepository _repository;
  Timer? _timer;
  String? _quizId;
  String? _resumeAttemptId;
  bool _forceStartNew = false;
  final Map<String, Timer> _answerSyncTimers = <String, Timer>{};

  @override
  void dispose() {
    _timer?.cancel();
    for (final timer in _answerSyncTimers.values) {
      timer.cancel();
    }
    _answerSyncTimers.clear();
    super.dispose();
  }

  Future<void> initialize(
    String quizId, {
    String? resumeAttemptId,
    bool forceStartNew = false,
  }) async {
    if (_quizId == quizId && state.questions.isNotEmpty) return;
    _quizId = quizId;
    _resumeAttemptId = (resumeAttemptId ?? '').trim().isNotEmpty
        ? resumeAttemptId
        : null;
    _forceStartNew = forceStartNew;
    _timer?.cancel();
    state = const QuizScreenState(isLoading: true);
    final result = await _repository.quizById(quizId);
    switch (result) {
      case Success(:final value):
        final quiz = value;
        state = state.copyWith(
          isLoading: false,
          quiz: quiz,
          questions: quiz.questions,
          currentIndex: 0,
          answers: const {},
          clearError: true,
          clearAttemptId: true,
          clearRemainingSeconds: true,
          clearSubmittedAttemptId: true,
          clearSubmittedResult: true,
        );
        await startAttempt(
          resumeAttemptId: _resumeAttemptId,
          forceStartNew: _forceStartNew,
        );
      case Failure(:final error):
        state = state.copyWith(isLoading: false, errorMessage: error.message);
    }
  }

  Future<void> startAttempt({
    String? resumeAttemptId,
    bool forceStartNew = false,
  }) async {
    if ((_quizId ?? '').isEmpty || state.isStarting) return;
    state = state.copyWith(isStarting: true, clearError: true);

    final explicitAttemptId = (resumeAttemptId ?? '').trim();
    if (explicitAttemptId.isNotEmpty) {
      final resumeResult = await _repository.resumeAttempt(explicitAttemptId);
      switch (resumeResult) {
        case Success(:final value):
          _hydrateAttemptState(value);
          return;
        case Failure(:final error):
          state = state.copyWith(
            isStarting: false,
            errorMessage: _mapResumeFailureMessage(error.message),
          );
          return;
      }
    }

    final activeAttemptResult = await _repository.checkActiveAttempt(_quizId!);
    if (activeAttemptResult case Success(:final value)) {
      if (value.hasActiveAttempt && (value.attemptId ?? '').isNotEmpty) {
        if (forceStartNew) {
          final submitOld = await _repository.submitAttempt(
            attemptId: value.attemptId!,
          );
          if (submitOld case Failure(:final error)) {
            state = state.copyWith(
              isStarting: false,
              errorMessage: error.message,
            );
            return;
          }
        } else {
          final resumeResult = await _repository.resumeAttempt(
            value.attemptId!,
          );
          switch (resumeResult) {
            case Success(:final value):
              _hydrateAttemptState(value);
              return;
            case Failure(:final error):
              state = state.copyWith(
                isStarting: false,
                errorMessage: error.message,
              );
              return;
          }
        }
      }
    }

    final result = await _repository.startAttempt(_quizId);
    switch (result) {
      case Success(:final value):
        _hydrateAttemptState(value);
      case Failure(:final error):
        state = state.copyWith(isStarting: false, errorMessage: error.message);
    }
  }

  Future<String?> submitAttempt() async {
    if (!state.hasAttempt || state.isSubmitting) return null;
    await _flushPendingAnswerSync();
    state = state.copyWith(isSubmitting: true, clearError: true);
    final attemptId = state.attemptId!;
    final result = await _repository.submitAttempt(attemptId: attemptId);
    switch (result) {
      case Success(:final value):
        _timer?.cancel();
        state = state.copyWith(
          isSubmitting: false,
          submittedAttemptId: attemptId,
          submittedResult: value,
        );
        return attemptId;
      case Failure(:final error):
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: error.message,
        );
        return null;
    }
  }

  void nextQuestion() {
    final clamped = state.currentIndex.clamp(0, state.questions.length - 1);
    if (clamped >= state.questions.length - 1) return;
    state = state.copyWith(currentIndex: clamped + 1);
  }

  void previousQuestion() {
    final clamped = state.currentIndex.clamp(0, state.questions.length - 1);
    if (clamped <= 0) return;
    state = state.copyWith(currentIndex: clamped - 1);
  }

  void setTextAnswer(String questionId, String value) {
    final next = Map<String, QuizAnswerModel>.from(state.answers);
    next[questionId] = QuizAnswerModel(textAnswer: value);
    state = state.copyWith(answers: next);
    _scheduleAnswerSync(questionId, next[questionId]!);
  }

  void toggleMultiAnswer(String questionId, String optionId, bool checked) {
    final next = Map<String, QuizAnswerModel>.from(state.answers);
    final selected = Set<String>.from(
      next[questionId]?.multiOptionIds ?? const <String>{},
    );
    if (checked) {
      selected.add(optionId);
    } else {
      selected.remove(optionId);
    }
    next[questionId] = QuizAnswerModel(multiOptionIds: selected);
    state = state.copyWith(answers: next);
    _scheduleAnswerSync(questionId, next[questionId]!);
  }

  void setSingleAnswer(String questionId, String optionId) {
    final next = Map<String, QuizAnswerModel>.from(state.answers);
    next[questionId] = QuizAnswerModel(singleOptionId: optionId);
    state = state.copyWith(answers: next);
    _scheduleAnswerSync(questionId, next[questionId]!);
  }

  void setMatchingAnswer(String questionId, Map<String, String> pairs) {
    final next = Map<String, QuizAnswerModel>.from(state.answers);
    next[questionId] = QuizAnswerModel(matchingPairs: Map.of(pairs));
    state = state.copyWith(answers: next);
    _scheduleAnswerSync(questionId, next[questionId]!);
  }

  void setOrderingAnswer(String questionId, List<String> orderedOptionIds) {
    final next = Map<String, QuizAnswerModel>.from(state.answers);
    next[questionId] = QuizAnswerModel(
      orderingOptionIds: List<String>.from(orderedOptionIds),
    );
    state = state.copyWith(answers: next);
    _scheduleAnswerSync(questionId, next[questionId]!);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearSubmittedAttempt() {
    state = state.copyWith(
      clearSubmittedAttemptId: true,
      clearSubmittedResult: true,
    );
  }

  void _scheduleAnswerSync(String questionId, QuizAnswerModel answer) {
    if (!state.hasAttempt) return;
    final value = answer.toRequestValue();
    if (value == null) return;

    _answerSyncTimers[questionId]?.cancel();
    _answerSyncTimers[questionId] = Timer(
      const Duration(milliseconds: 450),
      () {
        unawaited(_syncAnswerNow(questionId, value));
      },
    );
  }

  Future<void> _syncAnswerNow(String questionId, Object value) async {
    if (!state.hasAttempt) return;
    final attemptId = state.attemptId!;
    final result = await _repository.updateAnswer(
      attemptId: attemptId,
      questionId: questionId,
      userAnswer: value,
    );
    if (result case Failure<void>(:final error)) {
      state = state.copyWith(errorMessage: error.message);
    }
  }

  Future<void> _flushPendingAnswerSync() async {
    final timers = _answerSyncTimers.values.toList();
    for (final timer in timers) {
      timer.cancel();
    }
    _answerSyncTimers.clear();

    for (final entry in state.answers.entries) {
      final value = entry.value.toRequestValue();
      if (value == null) continue;
      await _syncAnswerNow(entry.key, value);
    }
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();
    if (!state.hasAttempt || (state.remainingSeconds ?? 0) <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (state.isSubmitting) return;
      final remaining = state.remainingSeconds;
      if (remaining == null) {
        _timer?.cancel();
        return;
      }
      if (remaining <= 0) {
        _timer?.cancel();
        await submitAttempt();
        return;
      }
      state = state.copyWith(remainingSeconds: remaining - 1);
    });
  }

  void _hydrateAttemptState(QuizAttemptStartModel attempt) {
    final hydratedAnswers = <String, QuizAnswerModel>{};
    final nextQuestions = attempt.questions.isNotEmpty
        ? attempt.questions
        : state.questions;
    final questionTypeById = <String, int>{
      for (final q in nextQuestions) q.questionId: q.type,
    };

    for (final entry in attempt.currentAnswers.entries) {
      final raw = entry.value;
      final type = questionTypeById[entry.key] ?? 1;
      if (raw is Map) {
        final pairs = <String, String>{};
        for (final mapEntry in raw.entries) {
          final left = mapEntry.key.toString();
          final right = mapEntry.value?.toString();
          if (left.isEmpty || (right ?? '').isEmpty) continue;
          pairs[left] = right!;
        }
        if (pairs.isNotEmpty) {
          hydratedAnswers[entry.key] = QuizAnswerModel(matchingPairs: pairs);
          continue;
        }
      }
      if (raw is List) {
        final values = raw.map((e) => e.toString()).toList(growable: false);
        if (type == 6) {
          hydratedAnswers[entry.key] = QuizAnswerModel(
            orderingOptionIds: values,
          );
        } else {
          hydratedAnswers[entry.key] = QuizAnswerModel(
            multiOptionIds: values.toSet(),
          );
        }
      } else if (type == 4) {
        hydratedAnswers[entry.key] = QuizAnswerModel(
          textAnswer: raw?.toString() ?? '',
        );
      } else if (raw != null) {
        hydratedAnswers[entry.key] = QuizAnswerModel(
          singleOptionId: raw.toString(),
        );
      }
    }

    final nextQuiz = state.quiz.copyWith(
      title: (attempt.quizTitle ?? '').trim().isNotEmpty
          ? attempt.quizTitle!
          : state.quiz.title,
      questions: nextQuestions,
    );

    if (nextQuestions.isEmpty) {
      state = state.copyWith(
        isStarting: false,
        attemptId: attempt.attemptId,
        quiz: nextQuiz,
        questions: const <QuizQuestionModel>[],
        answers: const <String, QuizAnswerModel>{},
        currentIndex: 0,
        clearRemainingSeconds: true,
        errorMessage: _cannotContinueMessage,
      );
      return;
    }

    state = state.copyWith(
      isStarting: false,
      attemptId: attempt.attemptId,
      quiz: nextQuiz,
      questions: nextQuestions,
      answers: hydratedAnswers.isNotEmpty ? hydratedAnswers : state.answers,
      currentIndex: 0,
      remainingSeconds:
          (attempt.durationMinutes != null && attempt.durationMinutes! > 0)
          ? attempt.durationMinutes! * 60
          : state.remainingSeconds,
    );
    _startTimerIfNeeded();
  }

  String _mapResumeFailureMessage(String message) {
    final lowered = message.toLowerCase();
    if (lowered.contains('not in progress') ||
        lowered.contains('time has expired') ||
        lowered.contains('auto-submitted') ||
        lowered.contains('attempt not found')) {
      return _cannotContinueMessage;
    }
    return message;
  }
}
