import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/result/result.dart';
import '../../models/quiz/quiz_models.dart';
import '../../repositories/quiz/quiz_repository.dart';
import '../../app/providers.dart';

class QuizHistoryState {
  const QuizHistoryState({
    this.isLoading = false,
    this.errorMessage,
    this.history = const [],
  });

  final bool isLoading;
  final String? errorMessage;
  final List<QuizHistoryItemModel> history;

  QuizHistoryState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<QuizHistoryItemModel>? history,
  }) {
    return QuizHistoryState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      history: history ?? this.history,
    );
  }
}

class QuizHistoryViewModel extends StateNotifier<QuizHistoryState> {
  QuizHistoryViewModel(this._repository) : super(const QuizHistoryState());

  final QuizRepository _repository;

  Future<void> loadHistory(String quizId) async {
    state = state.copyWith(isLoading: true);

    final response = await _repository.getQuizHistory(quizId);

    state = switch (response) {
      Success(:final value) => state.copyWith(isLoading: false, history: value),
      Failure(:final error) => state.copyWith(
        isLoading: false,
        errorMessage: error.message,
      ),
    };
  }
}

final quizHistoryProvider = StateNotifierProvider.autoDispose
    .family<QuizHistoryViewModel, QuizHistoryState, String>((ref, quizId) {
      final vm = QuizHistoryViewModel(ref.read(quizRepositoryProvider));
      vm.loadHistory(quizId);
      return vm;
    });
