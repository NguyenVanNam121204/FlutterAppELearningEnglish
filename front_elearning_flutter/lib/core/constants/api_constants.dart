class ApiConstants {
  static const authBase = '/api/auth';
  static const userBase = '/api/user';
  static const sharedBase = '/api/shared';

  static const login = '$authBase/login';
  static const register = '$authBase/register';
  static const verifyEmail = '$authBase/verify-email';
  static const forgotPassword = '$authBase/forgot-password';
  static const verifyOtp = '$authBase/verify-otp';
  static const setNewPassword = '$authBase/set-new-password';
  static const refreshToken = '$authBase/refresh-token';
  static const profile = '$authBase/profile';
  static const updateProfile = '$authBase/update/profile';
  static const changePassword = '$authBase/change-password';
  static const profileAvatar = '$authBase/profile/avatar';
  static const sharedTempFile = '$sharedBase/files/temp-file';

  static const systemCourses = '$userBase/courses/system-courses';
  static const myEnrolledCourses = '$userBase/enrollments/my-courses';
  static const streak = '$userBase/streaks';

  static const notifications = '$userBase/notifications';
  static const notificationsUnreadCount = '$notifications/unread-count';
  static const vocabularyNotebook = '$userBase/vocabulary/notebook';

  static const paymentProcess = '$userBase/payments/process';
  static const paymentHistory = '$userBase/payments/history';

  static const userEssays = '$userBase/essays';
  static const userEssaySubmissions = '$userBase/essay-submissions';
  static const userEssaySubmissionsSubmit = '$userEssaySubmissions/submit';
  static String userEssaySubmissionStatus(String essayId) =>
      '$userEssaySubmissions/submission-status/essay/$essayId';
  static const userAssessments = '$userBase/assessments';

  static String notificationMarkAsRead(String id) =>
      '$notifications/$id/mark-as-read';
  static String payOsCreateLink(String paymentId) =>
      '$userBase/payments/payos/create-link/$paymentId';
  static String payOsConfirm(String paymentId) =>
      '$userBase/payments/payos/confirm/$paymentId';

  static String quizById(String quizId) => '$userBase/quizzes/quiz/$quizId';
  static String quizzesByAssessment(String assessmentId) =>
      '$userBase/quizzes/assessment/$assessmentId';
  static String quizStartAttemptByQuizId(String quizId) =>
      '$userBase/quiz-attempts/start/$quizId';
  static const quizStartAttempt = '$userBase/quiz-attempts/start';
  static String quizSubmitAttempt(String attemptId) =>
      '$userBase/quiz-attempts/submit/$attemptId';
  static String quizResumeAttempt(String attemptId) =>
      '$userBase/quiz-attempts/resume/$attemptId';
  static String quizUpdateAnswer(String attemptId) =>
      '$userBase/quiz-attempts/update-answer/$attemptId';
  static String quizCheckActiveAttempt(String quizId) =>
      '$userBase/quiz-attempts/check-active/$quizId';
  static String quizAttemptResult(String attemptId) =>
      '$userBase/quiz-attempts/$attemptId/result';

  static String userCourseDetail(String courseId) =>
      '$userBase/courses/$courseId';
  static const userSearchCourses = '$userBase/courses/search';
  static String userLessonsByCourse(String courseId) =>
      '$userBase/lessons/course/$courseId';
  static String userLessonDetail(String lessonId) =>
      '$userBase/lessons/$lessonId';
  static String userModulesByLesson(String lessonId) =>
      '$userBase/modules/lesson/$lessonId';
  static String userStartModule(String moduleId) =>
      '$userBase/modules/$moduleId/start';
  static String userLecturesByModule(String moduleId) =>
      '$userBase/lectures/module/$moduleId';
  static String userLectureTreeByModule(String moduleId) =>
      '$userBase/lectures/module/$moduleId/tree';
  static String userLectureDetail(String lectureId) =>
      '$userBase/lectures/$lectureId';

  static String userPronunciationsByModule(String moduleId) =>
      '$userBase/pronunciation-assessments/module/$moduleId';
  static String userPronunciationSummaryByModule(String moduleId) =>
      '$userBase/pronunciation-assessments/module/$moduleId/summary';
  static const userPronunciationAssess = '$userBase/pronunciation-assessments';

  static String userEssayDetail(String essayId) => '$userEssays/$essayId';
  static String userEssaysByAssessment(String assessmentId) =>
      '$userEssays/assessment/$assessmentId';
  static String userAssessmentDetail(String assessmentId) =>
      '$userAssessments/$assessmentId';
  static String userAssessmentsByModule(String moduleId) =>
      '$userAssessments/module/$moduleId';

  static const enrollCourse = '$userBase/enrollments/course';

  static const userFlashcards = '$userBase/flashcards';
  static const userFlashcardReview = '$userBase/flashcard-review';
  static String userFlashcardReviewStartModule(String moduleId) =>
      '$userFlashcardReview/start-module/$moduleId';
}
