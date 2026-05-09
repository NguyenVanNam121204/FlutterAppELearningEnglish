import '../../core/result/result.dart';
import '../../repositories/learning/learning_repository.dart';

class LearningFeatureViewModel {
  LearningFeatureViewModel(this._repository);

  final LearningRepository _repository;

  Future<Result<void>> pingSystemCourses() async {
    return _repository.pingSystemCourses();
  }
}
