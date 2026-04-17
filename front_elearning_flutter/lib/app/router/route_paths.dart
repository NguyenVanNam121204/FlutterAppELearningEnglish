class RoutePaths {
  static const _courseSegment = 'course';
  static const _lessonsSegment = 'lessons';
  static const _lessonSegment = 'lesson';
  static const _moduleSegment = 'module';

  static const loading = '/loading';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const verifyEmailOtp = '/verify-email-otp';
  static const verifyResetOtp = '/verify-reset-otp';
  static const resetPassword = '/reset-password';
  static const home = '/home';
  static const mainApp = '/main-app';
  static const mainAppHome = '/main-app/home';
  static const mainAppCourses = '/main-app/courses';
  static const mainAppVocabulary = '/main-app/vocabulary';
  static const mainAppNotebook = '/main-app/notebook';
  static const mainAppProfile = '/main-app/profile';
  static const pro = '/pro';

  static String courseInCourses(String courseId) =>
      '$mainAppCourses/$_courseSegment/$courseId';

  static String courseLessons(String courseId) =>
      '${courseInCourses(courseId)}/$_lessonsSegment';

  static String courseLessonDetail({
    required String courseId,
    required String lessonId,
  }) => '${courseInCourses(courseId)}/$_lessonSegment/$lessonId';

  static String courseLessonModule({
    required String courseId,
    required String lessonId,
    required String moduleId,
  }) =>
      '${courseLessonDetail(courseId: courseId, lessonId: lessonId)}/$_moduleSegment/$moduleId';

  // Native-equivalent detail flow (migration roadmap)
  static const courseDetail = '/course-detail';
  static const search = '/search';
  static const lessonList = '/lesson-list';
  static const lessonDetail = '/lesson-detail';
  static const moduleLearning = '/module-learning';
  static const pronunciation = '/pronunciation';
  static const pronunciationDetail = '/pronunciation-detail';
  static const lectureDetail = '/lecture-detail';
  static const assignmentDetail = '/assignment-detail';
  static const quiz = '/quiz';
  static const lessonResult = '/lesson-result';
  static const essay = '/essay';

  static const payment = '/payment';
  static const paymentSuccess = '/payment-success';
  static const paymentFailed = '/payment-failed';
  static const paymentHistory = '/payment-history';
  static const notifications = '/notifications';
  static const flashcardLearning = '/flashcard-learning';
  static const flashcardReview = '/flashcard-review';
}
