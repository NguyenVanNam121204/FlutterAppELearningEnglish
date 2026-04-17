import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/home/home_course_model.dart';
import '../../models/streak/streak_model.dart';
import '../../repositories/home/home_repository.dart';
import '../../core/result/result.dart';

class HomeState {
  const HomeState({
    this.isLoading = false,
    this.errorMessage,
    this.myCourses = const [],
    this.suggestedCourses = const [],
    this.streak,
  });

  final bool isLoading;
  final String? errorMessage;
  final List<HomeCourseModel> myCourses;
  final List<HomeCourseModel> suggestedCourses;
  final StreakModel? streak;

  HomeState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<HomeCourseModel>? myCourses,
    List<HomeCourseModel>? suggestedCourses,
    StreakModel? streak,
    bool clearError = false,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      myCourses: myCourses ?? this.myCourses,
      suggestedCourses: suggestedCourses ?? this.suggestedCourses,
      streak: streak ?? this.streak,
    );
  }
}

class HomeViewModel extends StateNotifier<HomeState> {
  HomeViewModel(this._homeRepository) : super(const HomeState());

  final HomeRepository _homeRepository;

  Future<void> loadHomeData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final suggestedResult = await _homeRepository.getSuggestedCourses();
    final myCoursesResult = await _homeRepository.getMyCourses();
    final streakResult = await _homeRepository.getStreak();

    final suggestedCourses = switch (suggestedResult) {
      Success(value: final items) => items,
      Failure() => <HomeCourseModel>[],
    };

    final myCourses = switch (myCoursesResult) {
      Success(value: final items) => items,
      Failure() => <HomeCourseModel>[],
    };

    final streak = switch (streakResult) {
      Success(value: final value) => value,
      Failure() => null,
    };

    String? error;
    if (myCoursesResult case Failure(error: final e)) {
      error = e.message;
    } else if (suggestedResult case Failure(error: final e)) {
      error = e.message;
    } else if (streakResult case Failure(error: final e)) {
      error = e.message;
    }

    state = state.copyWith(
      isLoading: false,
      errorMessage: error,
      myCourses: myCourses,
      suggestedCourses: suggestedCourses,
      streak: streak,
    );
  }
}
