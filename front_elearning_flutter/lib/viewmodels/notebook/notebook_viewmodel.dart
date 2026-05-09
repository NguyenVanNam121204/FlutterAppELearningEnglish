import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/result/result.dart';
import '../../models/notebook/notebook_models.dart';
import '../../repositories/notebook/notebook_repository.dart';
import '../flashcard/flashcard_feature_viewmodel.dart';

class NotebookState {
  const NotebookState({
    this.isLoading = false,
    this.items = const [],
    this.stats = const {},
    this.errorMessage,
  });

  final bool isLoading;
  final List<NotebookModel> items;
  final Map<String, dynamic> stats;
  final String? errorMessage;

  NotebookState copyWith({
    bool? isLoading,
    List<NotebookModel>? items,
    Map<String, dynamic>? stats,
    String? errorMessage,
  }) {
    return NotebookState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      stats: stats ?? this.stats,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class NotebookViewModel extends StateNotifier<NotebookState> {
  NotebookViewModel(this._notebookRepository, this._flashcardFeature)
    : super(const NotebookState());

  final NotebookRepository _notebookRepository;
  final FlashcardFeatureViewModel _flashcardFeature;

  Future<void> loadNotebookData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final results = await Future.wait([
      _notebookRepository.notebookVocabulary(),
      _flashcardFeature.reviewStatistics(),
    ]);

    final vocabResult = results[0] as Result<List<NotebookModel>>;
    final statsResult = results[1] as Result<Map<String, dynamic>>;

    List<NotebookModel> items = state.items;
    Map<String, dynamic> stats = state.stats;
    String? error;

    if (vocabResult case Success(value: final value)) {
      items = value;
    } else if (vocabResult case Failure(error: final e)) {
      error = e.message;
    }

    if (statsResult case Success(value: final value)) {
      stats = value;
    }

    state = state.copyWith(
      isLoading: false,
      items: items,
      stats: stats,
      errorMessage: error,
    );
  }

  Future<void> refresh() async {
    await loadNotebookData();
  }
}
