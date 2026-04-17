import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/result/result.dart';
import '../../models/flashcard/flashcard_models.dart';
import 'flashcard_feature_viewmodel.dart';

class FlashcardReviewSessionState {
  const FlashcardReviewSessionState({
    this.isLoading = true,
    this.isSubmitting = false,
    this.isFinished = false,
    this.index = 0,
    this.cards = const [],
    this.showBack = false,
    this.mastered = 0,
  });

  final bool isLoading;
  final bool isSubmitting;
  final bool isFinished;
  final int index;
  final List<FlashcardModel> cards;
  final bool showBack;
  final int mastered;

  FlashcardReviewSessionState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    bool? isFinished,
    int? index,
    List<FlashcardModel>? cards,
    bool? showBack,
    int? mastered,
  }) {
    return FlashcardReviewSessionState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isFinished: isFinished ?? this.isFinished,
      index: index ?? this.index,
      cards: cards ?? this.cards,
      showBack: showBack ?? this.showBack,
      mastered: mastered ?? this.mastered,
    );
  }
}

class FlashcardReviewSessionViewModel
    extends StateNotifier<FlashcardReviewSessionState> {
  FlashcardReviewSessionViewModel(this._feature)
    : super(const FlashcardReviewSessionState());

  final FlashcardFeatureViewModel _feature;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await loadDueCards();
  }

  Future<void> loadDueCards() async {
    state = state.copyWith(isLoading: true);
    final result = await _feature.dueReviewCards();
    switch (result) {
      case Success(:final value):
        final enriched = await Future.wait(value.map(_enrichCardForReview));
        state = state.copyWith(
          isLoading: false,
          cards: enriched,
          index: 0,
          isFinished: false,
          mastered: 0,
          showBack: false,
        );
      case Failure():
        state = state.copyWith(isLoading: false);
    }
  }

  bool _needsDetail(FlashcardModel card) {
    return card.imageUrl.trim().isEmpty ||
        card.exampleSentence.trim().isEmpty ||
        card.exampleTranslation.trim().isEmpty ||
        card.pronunciation.trim().isEmpty ||
        card.partOfSpeech.trim().isEmpty;
  }

  Future<FlashcardModel> _enrichCardForReview(FlashcardModel card) async {
    final cardId = card.flashCardId.trim();
    if (cardId.isEmpty || !_needsDetail(card)) {
      return card;
    }

    final detailResult = await _feature.flashcardById(cardId);
    return switch (detailResult) {
      Success(:final value) => card.copyWith(
        term: card.term.trim().isNotEmpty ? card.term : value.term,
        definition: card.definition.trim().isNotEmpty
            ? card.definition
            : value.definition,
        pronunciation: card.pronunciation.trim().isNotEmpty
            ? card.pronunciation
            : value.pronunciation,
        partOfSpeech: card.partOfSpeech.trim().isNotEmpty
            ? card.partOfSpeech
            : value.partOfSpeech,
        exampleSentence: card.exampleSentence.trim().isNotEmpty
            ? card.exampleSentence
            : value.exampleSentence,
        exampleTranslation: card.exampleTranslation.trim().isNotEmpty
            ? card.exampleTranslation
            : value.exampleTranslation,
        audioUrl: card.audioUrl.trim().isNotEmpty
            ? card.audioUrl
            : value.audioUrl,
        imageUrl: card.imageUrl.trim().isNotEmpty
            ? card.imageUrl
            : value.imageUrl,
      ),
      Failure() => card,
    };
  }

  void toggleCard() {
    state = state.copyWith(showBack: !state.showBack);
  }

  Future<void> review(int quality) async {
    if (state.isSubmitting || state.index >= state.cards.length) return;
    final card = state.cards[state.index];
    final cardId = card.flashCardId.trim();
    if (cardId.isEmpty || cardId.toLowerCase() == 'null') return;
    state = state.copyWith(isSubmitting: true);
    final result = await _feature.reviewCard(
      flashCardId: cardId,
      quality: quality,
    );
    if (result is Failure<void>) {
      state = state.copyWith(isSubmitting: false);
      return;
    }

    final mastered = quality >= 4 ? state.mastered + 1 : state.mastered;
    if (state.index < state.cards.length - 1) {
      state = state.copyWith(
        index: state.index + 1,
        isSubmitting: false,
        showBack: false,
        mastered: mastered,
      );
    } else {
      state = state.copyWith(
        isFinished: true,
        isSubmitting: false,
        mastered: mastered,
      );
    }
  }
}
