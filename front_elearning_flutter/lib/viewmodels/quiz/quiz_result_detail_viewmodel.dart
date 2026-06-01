import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/result/result.dart';
import '../../models/quiz/quiz_models.dart';
import '../../repositories/quiz/quiz_repository.dart';
import '../../app/providers.dart';

class QuizResultDetailState {
  const QuizResultDetailState({
    this.isLoading = false,
    this.errorMessage,
    this.result,
  });

  final bool isLoading;
  final String? errorMessage;
  final QuizAttemptResultModel? result;

  QuizResultDetailState copyWith({
    bool? isLoading,
    String? errorMessage,
    QuizAttemptResultModel? result,
  }) {
    return QuizResultDetailState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      result: result ?? this.result,
    );
  }
}

class QuizResultDetailViewModel extends StateNotifier<QuizResultDetailState> {
  QuizResultDetailViewModel(this._repository)
    : super(const QuizResultDetailState());

  final QuizRepository _repository;

  Future<void> initialize(String attemptId) async {
    state = state.copyWith(isLoading: true);

    final response = await _repository.getAttemptResult(attemptId);

    state = switch (response) {
      Success(:final value) => state.copyWith(isLoading: false, result: value),
      Failure(:final error) => state.copyWith(
        isLoading: false,
        errorMessage: error.message,
      ),
    };
  }
}

final quizResultDetailProvider = StateNotifierProvider.autoDispose
    .family<QuizResultDetailViewModel, QuizResultDetailState, String>((
      ref,
      attemptId,
    ) {
      final vm = QuizResultDetailViewModel(ref.read(quizRepositoryProvider));
      vm.initialize(attemptId);
      return vm;
    });
