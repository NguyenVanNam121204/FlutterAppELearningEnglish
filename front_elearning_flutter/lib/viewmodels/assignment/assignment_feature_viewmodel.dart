import '../../core/result/result.dart';
import '../../models/assignment/assignment_models.dart';
import '../../repositories/assignment/assignment_repository.dart';

class AssignmentFeatureViewModel {
  AssignmentFeatureViewModel(this._repository);

  final AssignmentRepository _repository;

  Future<Result<AssignmentDetailModel>> assignmentDetail({
    required String assessmentId,
    required String moduleId,
  }) async {
    return _repository.assignmentDetail(
      assessmentId: assessmentId,
      moduleId: moduleId,
    );
  }

  Future<Result<EssayDetailModel>> essayDetail(String essayId) async {
    return _repository.essayDetail(essayId);
  }

  Future<Result<void>> submitEssay({
    required String essayId,
    required String content,
  }) async {
    return _repository.submitEssay(essayId: essayId, content: content);
  }
}
