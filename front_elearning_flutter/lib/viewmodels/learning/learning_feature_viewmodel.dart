import '../../models/learning/course_models.dart';
import '../../core/result/result.dart';
import '../../repositories/learning/learning_repository.dart';

class LearningFeatureViewModel {
  LearningFeatureViewModel(this._repository);

  final LearningRepository _repository;

  Future<Result<void>> pingSystemCourses() async {
    return _repository.pingSystemCourses();
  }

  Future<Result<List<LearningVocabularyItem>>> notebookVocabulary() async {
    return _repository.notebookVocabulary();
  }

  Future<Result<List<LearningCourseItem>>> myCourses({
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    return _repository.myCourses(pageNumber: pageNumber, pageSize: pageSize);
  }
}
