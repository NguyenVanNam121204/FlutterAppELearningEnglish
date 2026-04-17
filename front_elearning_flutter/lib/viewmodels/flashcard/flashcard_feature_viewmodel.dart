import '../../core/result/result.dart';
import '../../models/flashcard/flashcard_models.dart';
import '../../repositories/flashcard/flashcard_repository.dart';

class FlashcardFeatureViewModel {
  FlashcardFeatureViewModel(this._repository);

  final FlashcardRepository _repository;

  Future<Result<List<FlashcardModel>>> lessonFlashcards(String lessonId) async {
    return _repository.lessonFlashcards(lessonId);
  }

  Future<Result<List<FlashcardModel>>> moduleFlashcards(String moduleId) async {
    return _repository.moduleFlashcards(moduleId);
  }

  Future<Result<FlashcardModel>> flashcardById(String flashCardId) async {
    return _repository.flashcardById(flashCardId);
  }

  Future<Result<List<FlashcardModel>>> dueReviewCards() async {
    return _repository.dueReviewCards();
  }

  Future<Result<List<FlashcardModel>>> masteredReviewCards() async {
    return _repository.masteredReviewCards();
  }

  Future<Result<Map<String, dynamic>>> reviewStatistics() async {
    return _repository.reviewStatistics();
  }

  Future<Result<void>> reviewCard({
    required String flashCardId,
    required int quality,
  }) async {
    return _repository.reviewCard(flashCardId: flashCardId, quality: quality);
  }

  Future<Result<void>> startLearningModule(String moduleId) async {
    return _repository.startLearningModule(moduleId);
  }
}
