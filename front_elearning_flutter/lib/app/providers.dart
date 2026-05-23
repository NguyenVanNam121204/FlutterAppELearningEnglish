import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result/result.dart';
import '../models/assignment/assignment_models.dart';
import '../models/notebook/notebook_models.dart';
import '../models/my_course/my_course_models.dart';
import '../models/learning/course_models.dart';
import '../models/learning/lesson_models.dart';
import '../models/learning/lecture_models.dart';
import '../models/learning/pronunciation_models.dart';
import '../models/payment/payment_models.dart';
import '../models/user/user_model.dart';
import '../models/flashcard/flashcard_models.dart';
import '../repositories/assignment/assignment_repository.dart';
import '../repositories/auth/auth_repository.dart';
import '../repositories/flashcard/flashcard_repository.dart';
import '../repositories/home/home_repository.dart';
import '../repositories/learning/course_repository.dart';
import '../repositories/learning/lecture_repository.dart';
import '../repositories/learning/learning_repository.dart';
import '../repositories/learning/lesson_repository.dart';
import '../repositories/learning/pronunciation_repository.dart';
import '../repositories/notebook/notebook_repository.dart';
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
import '../viewmodels/notebook/notebook_viewmodel.dart';
import '../viewmodels/my_course/my_course_viewmodel.dart';
import 'config/app_config.dart';

// Services
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final authSessionProvider = Provider<AuthSessionService>((ref) {
  final service = AuthSessionService();
  ref.onDispose(service.dispose);
  return service;
});

final refreshDioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: Duration(milliseconds: AppConfig.connectTimeoutMs),
    receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeoutMs),
  ));
});

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: Duration(milliseconds: AppConfig.connectTimeoutMs),
    receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeoutMs),
  ));
  final refreshDio = ref.read(refreshDioProvider);
  dio.interceptors.add(
    AuthInterceptor(
      ref.read(secureStorageProvider),
      dio,
      refreshDio,
      ref.read(authSessionProvider),
    ),
  );
  return dio;
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.read(dioProvider));
});

// Repositories
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

final notebookRepositoryProvider = Provider<NotebookRepository>((ref) {
  return NotebookRepository(ref.read(apiServiceProvider));
});

// Feature ViewModels
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

final flashcardFeatureViewModelProvider = Provider<FlashcardFeatureViewModel>((
  ref,
) {
  return FlashcardFeatureViewModel(ref.read(flashcardRepositoryProvider));
});

final dueReviewCardsProvider = FutureProvider.autoDispose<List<FlashcardModel>>(
  (ref) async {
    final result = await ref
        .read(flashcardFeatureViewModelProvider)
        .dueReviewCards();
    return switch (result) {
      Success(:final value) => value,
      Failure(:final error) => throw Exception(error.message),
    };
  },
);

final paymentFeatureViewModelProvider = Provider<PaymentFeatureViewModel>((
  ref,
) {
  return PaymentFeatureViewModel(ref.read(paymentRepositoryProvider));
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

// Future Providers
final profileDataProvider = FutureProvider.autoDispose<UserModel>((ref) async {
  final result = await ref.read(profileRepositoryProvider).profile();
  return switch (result) {
    Success(:final value) => value,
    Failure(:final error) => throw Exception(error.message),
  };
});

final notificationUnreadCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final result = await ref.read(notificationRepositoryProvider).unreadCount();
  return switch (result) {
    Success(:final value) => value,
    Failure() => 0,
  };
});

final vocabularyListProvider = FutureProvider.autoDispose<List<NotebookModel>>((
  ref,
) async {
  final result = await ref
      .read(notebookRepositoryProvider)
      .notebookVocabulary();
  return switch (result) {
    Success(:final value) => value,
    Failure(:final error) => throw Exception(error.message),
  };
});

final myCoursesListProvider =
    FutureProvider.autoDispose<List<MyCourseItemModel>>((ref) async {
      final result = await ref
          .read(courseRepositoryProvider)
          .myEnrolledCourses(pageNumber: 1, pageSize: 20);
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw Exception(error.message),
      };
    });

final searchCoursesProvider = FutureProvider.autoDispose
    .family<List<LearningCourseItem>, String>((ref, keyword) async {
      if (keyword.trim().isEmpty) return const [];
      final result = await ref
          .read(courseRepositoryProvider)
          .searchCourses(keyword);
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw Exception(error.message),
      };
    });

final courseDetailDataProvider = FutureProvider.autoDispose
    .family<CourseDetailModel, String>((ref, id) async {
      final result = await ref.read(courseRepositoryProvider).courseDetail(id);
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw Exception(error.message),
      };
    });

final lessonsByCourseProvider = FutureProvider.autoDispose
    .family<List<LessonListItemModel>, String>((ref, id) async {
      final result = await ref
          .read(lessonRepositoryProvider)
          .lessonsByCourse(id);
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw Exception(error.message),
      };
    });

final lessonDetailBundleProvider = FutureProvider.autoDispose
    .family<LessonDetailBundleModel, String>((ref, id) async {
      final result = await ref
          .read(lessonRepositoryProvider)
          .lessonDetailBundle(id);
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw Exception(error.message),
      };
    });

final lectureDetailProvider = FutureProvider.autoDispose
    .family<LectureDetailModel, String>((ref, id) async {
      final result = await ref
          .read(lectureRepositoryProvider)
          .lectureDetail(id);
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw Exception(error.message),
      };
    });

final moduleLectureTreeProvider = FutureProvider.autoDispose
    .family<List<LectureTreeItemModel>, String>((ref, moduleId) async {
      final result = await ref
          .read(lectureRepositoryProvider)
          .moduleLectureTree(moduleId);
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw Exception(error.message),
      };
    });

final pronunciationListProvider = FutureProvider.autoDispose
    .family<List<PronunciationItemModel>, String>((ref, moduleId) async {
      final result = await ref
          .read(pronunciationRepositoryProvider)
          .pronunciationList(moduleId);
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw Exception(error.message),
      };
    });

final pronunciationSummaryProvider = FutureProvider.autoDispose
    .family<ModulePronunciationSummaryModel, String>((ref, moduleId) async {
      final result = await ref
          .read(pronunciationRepositoryProvider)
          .moduleSummary(moduleId);
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw Exception(error.message),
      };
    });

final lessonResultProvider = FutureProvider.autoDispose
    .family<LessonResultModel, String>((ref, id) async {
      final result = await ref.read(lessonRepositoryProvider).lessonResult(id);
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw Exception(error.message),
      };
    });

final paymentHistoryDataProvider =
    FutureProvider.autoDispose<List<PaymentHistoryItemModel>>((ref) async {
      final result = await ref.read(paymentRepositoryProvider).paymentHistory();
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw Exception(error.message),
      };
    });

final assignmentDetailProvider = FutureProvider.autoDispose
    .family<AssignmentDetailModel, String>((ref, arg) async {
      final parts = arg.split('::');
      final assessmentId = parts[0];
      final moduleId = parts.length > 1 ? parts[1] : '';
      final result = await ref
          .read(assignmentRepositoryProvider)
          .assignmentDetail(assessmentId: assessmentId, moduleId: moduleId);
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw Exception(error.message),
      };
    });

final essayDetailProvider = FutureProvider.autoDispose
    .family<EssayDetailModel, String>((ref, id) async {
      final result = await ref
          .read(assignmentRepositoryProvider)
          .essayDetail(id);
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw Exception(error.message),
      };
    });

final essaySubmissionStatusProvider = FutureProvider.autoDispose
    .family<EssaySubmissionModel?, String>((ref, id) async {
      final result = await ref
          .read(assignmentRepositoryProvider)
          .getEssaySubmissionStatus(id);
      return switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw Exception(error.message),
      };
    });

// StateNotifier Providers
final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((
  ref,
) {
  return AuthViewModel(
    ref.read(authRepositoryProvider),
    ref.read(secureStorageProvider),
    ref.read(authSessionProvider),
  );
});

final notebookViewModelProvider =
    StateNotifierProvider<NotebookViewModel, NotebookState>((ref) {
      return NotebookViewModel(
        ref.read(notebookRepositoryProvider),
        ref.read(flashcardFeatureViewModelProvider),
      );
    });

final myCourseViewModelProvider =
    StateNotifierProvider<MyCourseViewModel, MyCourseState>((ref) {
      return MyCourseViewModel(ref.read(courseRepositoryProvider));
    });

final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeState>((
  ref,
) {
  return HomeViewModel(ref.read(homeRepositoryProvider));
});

final quizScreenViewModelProvider = StateNotifierProvider.autoDispose
    .family<QuizScreenViewModel, QuizScreenState, String>((
  ref,
  quizId,
) {
  return QuizScreenViewModel(ref.read(quizRepositoryProvider));
});

final flashcardLearningViewModelProvider =
    StateNotifierProvider.family<
      FlashcardLearningViewModel,
      FlashcardLearningState,
      String
    >((ref, key) {
      final vm = FlashcardLearningViewModel(
        ref.read(flashcardFeatureViewModelProvider),
      );
      vm.initialize(key);
      return vm;
    });

final flashcardReviewSessionViewModelProvider =
    StateNotifierProvider.autoDispose<
      FlashcardReviewSessionViewModel,
      FlashcardReviewSessionState
    >((ref) {
      return FlashcardReviewSessionViewModel(
        ref.read(flashcardFeatureViewModelProvider),
        ref,
      );
    });

final notificationScreenViewModelProvider =
    StateNotifierProvider<NotificationScreenViewModel, NotificationScreenState>(
      (ref) {
        return NotificationScreenViewModel(
          ref.read(notificationFeatureViewModelProvider),
        );
      },
    );

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
