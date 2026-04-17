import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result/result.dart';
import '../core/logger/app_logger.dart';
import '../core/search/search_matcher.dart';
import '../models/assignment/assignment_models.dart';
import '../models/user/user_model.dart';
import '../models/learning/course_models.dart';
import '../models/learning/lecture_models.dart';
import '../models/learning/lesson_models.dart';
import '../models/learning/pronunciation_models.dart';
import '../models/payment/payment_models.dart';
import '../repositories/assignment/assignment_repository.dart';
import '../repositories/auth/auth_repository.dart';
import '../repositories/flashcard/flashcard_repository.dart';
import '../repositories/home/home_repository.dart';
import '../repositories/learning/course_repository.dart';
import '../repositories/learning/lecture_repository.dart';
import '../repositories/learning/learning_repository.dart';
import '../repositories/learning/lesson_repository.dart';
import '../repositories/learning/pronunciation_repository.dart';
import '../repositories/notification/notification_repository.dart';
import '../repositories/payment/payment_repository.dart';
import '../repositories/profile/profile_repository.dart';
import '../repositories/quiz/quiz_repository.dart';
import '../services/api_service.dart';
import '../services/auth_interceptor.dart';
import '../services/auth_session_service.dart';
import '../services/secure_storage_service.dart';
import '../viewmodels/auth/auth_viewmodel.dart';
import '../viewmodels/flashcard/flashcard_feature_viewmodel.dart';
import '../viewmodels/flashcard/flashcard_learning_viewmodel.dart';
import '../viewmodels/flashcard/flashcard_review_session_viewmodel.dart';
import '../viewmodels/home/home_viewmodel.dart';
import '../viewmodels/learning/learning_feature_viewmodel.dart';
import '../viewmodels/learning/lesson_feature_viewmodel.dart';
import '../viewmodels/notification/notification_feature_viewmodel.dart';
import '../viewmodels/notification/notification_screen_viewmodel.dart';
import '../viewmodels/payment/payment_feature_viewmodel.dart';
import '../viewmodels/payment/payment_screen_viewmodel.dart';
import '../viewmodels/profile/profile_feature_viewmodel.dart';
import '../viewmodels/quiz/quiz_screen_viewmodel.dart';
import '../viewmodels/assignment/assignment_feature_viewmodel.dart';
import 'config/app_config.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final authSessionProvider = Provider<AuthSessionService>((ref) {
  final service = AuthSessionService();
  ref.onDispose(service.dispose);
  return service;
});

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: Duration(milliseconds: AppConfig.connectTimeoutMs),
      receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeoutMs),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  final refreshDio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: Duration(milliseconds: AppConfig.connectTimeoutMs),
      receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeoutMs),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      ref.read(secureStorageProvider),
      dio,
      refreshDio,
      ref.read(authSessionProvider),
    ),
  );

  if (AppConfig.enableNetworkLog) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          AppLogger.info('${options.method} ${options.uri}');
          handler.next(options);
        },
        onError: (error, handler) {
          AppLogger.error('${error.requestOptions.uri} - ${error.message}');
          handler.next(error);
        },
      ),
    );
  }

  return dio;
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.read(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(apiServiceProvider));
});

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(ref.read(apiServiceProvider));
});

final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  return AssignmentRepository(ref.read(apiServiceProvider));
});

final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  return LearningRepository(ref.read(apiServiceProvider));
});

final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  return LessonRepository(ref.read(apiServiceProvider));
});

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepository(ref.read(apiServiceProvider));
});

final lectureRepositoryProvider = Provider<LectureRepository>((ref) {
  return LectureRepository(ref.read(apiServiceProvider));
});

final pronunciationRepositoryProvider = Provider<PronunciationRepository>((
  ref,
) {
  return PronunciationRepository(ref.read(apiServiceProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.read(apiServiceProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.read(apiServiceProvider));
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.read(apiServiceProvider));
});

final flashcardRepositoryProvider = Provider<FlashcardRepository>((ref) {
  return FlashcardRepository(ref.read(apiServiceProvider));
});

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepository(ref.read(apiServiceProvider));
});

final lessonFeatureViewModelProvider = Provider<LessonFeatureViewModel>((ref) {
  return LessonFeatureViewModel(
    ref.read(courseRepositoryProvider),
    ref.read(lessonRepositoryProvider),
    ref.read(lectureRepositoryProvider),
    ref.read(pronunciationRepositoryProvider),
  );
});

final learningFeatureViewModelProvider = Provider<LearningFeatureViewModel>((
  ref,
) {
  return LearningFeatureViewModel(ref.read(learningRepositoryProvider));
});

final profileFeatureViewModelProvider = Provider<ProfileFeatureViewModel>((
  ref,
) {
  return ProfileFeatureViewModel(ref.read(profileRepositoryProvider));
});

final notificationFeatureViewModelProvider =
    Provider<NotificationFeatureViewModel>((ref) {
      return NotificationFeatureViewModel(
        ref.read(notificationRepositoryProvider),
      );
    });

final assignmentFeatureViewModelProvider = Provider<AssignmentFeatureViewModel>(
  (ref) {
    return AssignmentFeatureViewModel(ref.read(assignmentRepositoryProvider));
  },
);

final paymentFeatureViewModelProvider = Provider<PaymentFeatureViewModel>((
  ref,
) {
  return PaymentFeatureViewModel(ref.read(paymentRepositoryProvider));
});

final flashcardFeatureViewModelProvider = Provider<FlashcardFeatureViewModel>((
  ref,
) {
  return FlashcardFeatureViewModel(ref.read(flashcardRepositoryProvider));
});

final vocabularyListProvider =
    FutureProvider.autoDispose<List<LearningVocabularyItem>>((ref) async {
      final result = await ref
          .read(learningFeatureViewModelProvider)
          .notebookVocabulary();
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw Exception(error.message),
      };
    });

final myCoursesListProvider =
    FutureProvider.autoDispose<List<LearningCourseItem>>((ref) async {
      final result = await ref
          .read(learningFeatureViewModelProvider)
          .myCourses(pageNumber: 1, pageSize: 20);
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw Exception(error.message),
      };
    });

final profileDataProvider = FutureProvider.autoDispose<UserModel>((ref) async {
  final result = await ref.read(profileFeatureViewModelProvider).profile();
  return switch (result) {
    Success(:final value) => value,
    Failure(:final error) => throw Exception(error.message),
  };
});

final searchCoursesProvider = FutureProvider.autoDispose
    .family<List<LearningCourseItem>, String>((ref, keyword) async {
      final trimmedKeyword = keyword.trim();
      final normalizedKeyword = normalizeSearchText(trimmedKeyword);

      if (normalizedKeyword.isEmpty) {
        return const [];
      }

      final result = await ref
          .read(lessonFeatureViewModelProvider)
          .searchCourses(trimmedKeyword);

      return switch (result) {
        Success(:final value) =>
          value
              .where((item) => matchesCourseTitle(item.title, trimmedKeyword))
              .toList(growable: false),
        Failure(:final error) => throw Exception(error.message),
      };
    });

final courseDetailDataProvider = FutureProvider.autoDispose
    .family<CourseDetailModel, String>((ref, courseId) async {
      final result = await ref
          .read(lessonFeatureViewModelProvider)
          .courseDetail(courseId);
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw Exception(error.message),
      };
    });

final lessonsByCourseProvider = FutureProvider.autoDispose
    .family<List<LessonListItemModel>, String>((ref, courseId) async {
      final result = await ref
          .read(lessonFeatureViewModelProvider)
          .lessonsByCourse(courseId);
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw Exception(error.message),
      };
    });

final lessonDetailBundleProvider = FutureProvider.autoDispose
    .family<LessonDetailBundleModel, String>((ref, lessonId) async {
      final result = await ref
          .read(lessonFeatureViewModelProvider)
          .lessonDetailBundle(lessonId);
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw Exception(error.message),
      };
    });

final moduleLecturesProvider = FutureProvider.autoDispose
    .family<List<LectureListItemModel>, String>((ref, moduleId) async {
      final result = await ref
          .read(lessonFeatureViewModelProvider)
          .moduleLectures(moduleId);
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw Exception(error.message),
      };
    });

final moduleLectureTreeProvider = FutureProvider.autoDispose
    .family<List<LectureTreeItemModel>, String>((ref, moduleId) async {
      final result = await ref
          .read(lessonFeatureViewModelProvider)
          .moduleLectureTree(moduleId);
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw Exception(error.message),
      };
    });

final lectureDetailProvider = FutureProvider.autoDispose
    .family<LectureDetailModel, String>((ref, lectureId) async {
      final result = await ref
          .read(lessonFeatureViewModelProvider)
          .lectureDetail(lectureId);
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw Exception(error.message),
      };
    });

final pronunciationListProvider = FutureProvider.autoDispose
    .family<List<PronunciationItemModel>, String>((ref, moduleId) async {
      final result = await ref
          .read(lessonFeatureViewModelProvider)
          .pronunciationList(moduleId);
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw Exception(error.message),
      };
    });

final pronunciationSummaryProvider = FutureProvider.autoDispose
    .family<ModulePronunciationSummaryModel, String>((ref, moduleId) async {
      final result = await ref
          .read(lessonFeatureViewModelProvider)
          .pronunciationSummary(moduleId);
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw Exception(error.message),
      };
    });

final lessonResultProvider = FutureProvider.autoDispose
    .family<LessonResultModel, String>((ref, attemptId) async {
      final result = await ref
          .read(lessonFeatureViewModelProvider)
          .lessonResult(attemptId);
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw Exception(error.message),
      };
    });

final assignmentDetailProvider = FutureProvider.autoDispose
    .family<AssignmentDetailModel, String>((ref, combinedArg) async {
      final split = combinedArg.split('::');
      final assessmentId = split.isNotEmpty ? split.first : '';
      final moduleId = split.length > 1 ? split[1] : '';
      final result = await ref
          .read(assignmentFeatureViewModelProvider)
          .assignmentDetail(assessmentId: assessmentId, moduleId: moduleId);
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw Exception(error.message),
      };
    });

final essayDetailProvider = FutureProvider.autoDispose
    .family<EssayDetailModel, String>((ref, essayId) async {
      final result = await ref
          .read(assignmentFeatureViewModelProvider)
          .essayDetail(essayId);
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw Exception(error.message),
      };
    });

final paymentHistoryDataProvider =
    FutureProvider.autoDispose<List<PaymentHistoryItemModel>>((ref) async {
      final result = await ref
          .read(paymentFeatureViewModelProvider)
          .paymentHistory();
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw Exception(error.message),
      };
    });

final notificationScreenViewModelProvider =
    StateNotifierProvider<NotificationScreenViewModel, NotificationScreenState>(
      (ref) {
        return NotificationScreenViewModel(
          ref.read(notificationFeatureViewModelProvider),
        );
      },
    );

final notificationUnreadCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final result = await ref
      .read(notificationFeatureViewModelProvider)
      .unreadCount();
  return switch (result) {
    Success(:final value) => value,
    Failure(:final error) => throw Exception(error.message),
  };
});

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((
  ref,
) {
  return AuthViewModel(
    ref.read(authRepositoryProvider),
    ref.read(secureStorageProvider),
    ref.read(authSessionProvider),
  );
});

final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeState>((
  ref,
) {
  return HomeViewModel(ref.read(homeRepositoryProvider));
});

final quizScreenViewModelProvider =
    StateNotifierProvider.family<QuizScreenViewModel, QuizScreenState, String>((
      ref,
      _,
    ) {
      return QuizScreenViewModel(ref.read(quizRepositoryProvider));
    });

final paymentScreenViewModelProvider =
    StateNotifierProvider.family<
      PaymentScreenViewModel,
      PaymentScreenState,
      PaymentScreenArgs
    >((ref, args) {
      final vm = PaymentScreenViewModel(
        ref.read(paymentFeatureViewModelProvider),
      );
      vm.initialize(args);
      return vm;
    });

final flashcardLearningViewModelProvider =
    StateNotifierProvider.family<
      FlashcardLearningViewModel,
      FlashcardLearningState,
      String
    >((ref, targetKey) {
      final vm = FlashcardLearningViewModel(
        ref.read(flashcardFeatureViewModelProvider),
      );
      vm.initialize(targetKey);
      return vm;
    });

final flashcardReviewSessionViewModelProvider =
    StateNotifierProvider<
      FlashcardReviewSessionViewModel,
      FlashcardReviewSessionState
    >((ref) {
      final vm = FlashcardReviewSessionViewModel(
        ref.read(flashcardFeatureViewModelProvider),
      );
      vm.initialize();
      return vm;
    });
