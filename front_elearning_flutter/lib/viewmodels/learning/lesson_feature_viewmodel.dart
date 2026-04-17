import '../../core/result/result.dart';
import '../../models/learning/course_models.dart';
import '../../models/learning/lecture_models.dart';
import '../../models/learning/lesson_models.dart';
import '../../models/learning/pronunciation_models.dart';
import '../../repositories/learning/course_repository.dart';
import '../../repositories/learning/lecture_repository.dart';
import '../../repositories/learning/lesson_repository.dart';
import '../../repositories/learning/pronunciation_repository.dart';

class LessonFeatureViewModel {
  LessonFeatureViewModel(
    this._courseRepository,
    this._lessonRepository,
    this._lectureRepository,
    this._pronunciationRepository,
  );

  final CourseRepository _courseRepository;
  final LessonRepository _lessonRepository;
  final LectureRepository _lectureRepository;
  final PronunciationRepository _pronunciationRepository;

  Future<Result<CourseDetailModel>> courseDetail(String courseId) async {
    return _courseRepository.courseDetail(courseId);
  }

  Future<Result<List<LearningCourseItem>>> searchCourses(String keyword) async {
    return _courseRepository.searchCourses(keyword);
  }

  Future<Result<List<LessonListItemModel>>> lessonsByCourse(
    String courseId,
  ) async {
    return _lessonRepository.lessonsByCourse(courseId);
  }

  Future<Result<LessonDetailBundleModel>> lessonDetailBundle(
    String lessonId,
  ) async {
    return _lessonRepository.lessonDetailBundle(lessonId);
  }

  Future<Result<List<LectureListItemModel>>> moduleLectures(
    String moduleId,
  ) async {
    return _lectureRepository.moduleLectures(moduleId);
  }

  Future<Result<List<LectureTreeItemModel>>> moduleLectureTree(
    String moduleId,
  ) async {
    return _lectureRepository.moduleLectureTree(moduleId);
  }

  Future<Result<LectureDetailModel>> lectureDetail(String lectureId) async {
    return _lectureRepository.lectureDetail(lectureId);
  }

  Future<Result<List<PronunciationItemModel>>> pronunciationList(
    String moduleId,
  ) async {
    return _pronunciationRepository.pronunciationList(moduleId);
  }

  Future<Result<ModulePronunciationSummaryModel>> pronunciationSummary(
    String moduleId,
  ) async {
    return _pronunciationRepository.moduleSummary(moduleId);
  }

  Future<Result<PronunciationAssessmentResultModel>> assessPronunciation({
    required int flashCardId,
    required String filePath,
    required String fileName,
    double? durationInSeconds,
  }) async {
    return _pronunciationRepository.assessPronunciation(
      flashCardId: flashCardId,
      filePath: filePath,
      fileName: fileName,
      durationInSeconds: durationInSeconds,
    );
  }

  Future<Result<LessonResultModel>> lessonResult(String attemptId) async {
    return _lessonRepository.lessonResult(attemptId);
  }

  Future<Result<void>> startModule(String moduleId) async {
    return _lessonRepository.startModule(moduleId);
  }
}
