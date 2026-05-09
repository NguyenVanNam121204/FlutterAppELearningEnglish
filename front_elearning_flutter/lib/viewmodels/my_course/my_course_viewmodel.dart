import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/result/result.dart';
import '../../models/my_course/my_course_models.dart';
import '../../repositories/learning/course_repository.dart';

class MyCourseState {
  const MyCourseState({
    this.isLoading = false,
    this.courses = const [],
    this.errorMessage,
  });

  final bool isLoading;
  final List<MyCourseItemModel> courses;
  final String? errorMessage;

  MyCourseState copyWith({
    bool? isLoading,
    List<MyCourseItemModel>? courses,
    String? errorMessage,
  }) {
    return MyCourseState(
      isLoading: isLoading ?? this.isLoading,
      courses: courses ?? this.courses,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class MyCourseViewModel extends StateNotifier<MyCourseState> {
  MyCourseViewModel(this._courseRepository) : super(const MyCourseState());

  final CourseRepository _courseRepository;

  Future<void> loadMyCourses() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _courseRepository.myEnrolledCourses();

    if (result case Success(value: final value)) {
      state = state.copyWith(isLoading: false, courses: value);
    } else if (result case Failure(error: final e)) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> refresh() async {
    await loadMyCourses();
  }
}
