# Screen To Skill Rule Map

Muc tieu: cho biet man hinh nao nen uu tien ap dung rule nao trong skill flutter-mvvm-riverpod-go-router.

## Main Tabs

| Man hinh | Route | Rule uu tien |
| --- | --- | --- |
| HomeScreen | RoutePaths.mainAppHome | ui-loading-error-empty-consistency, reliability-context-mounted-after-await, navigation-route-path-constants, state-viewmodel-only-business-logic |
| OnionScreen (Khoa hoc) | RoutePaths.mainAppCourses | ui-loading-error-empty-consistency, navigation-route-path-constants, state-viewmodel-only-business-logic |
| VocabularyScreen (On tap) | RoutePaths.mainAppVocabulary | ui-loading-error-empty-consistency, architecture-providers-single-registry, reliability-no-blocking-in-build |
| GymScreen (So tay) | RoutePaths.mainAppNotebook | ui-loading-error-empty-consistency, reliability-context-mounted-after-await, architecture-providers-single-registry |
| ProfileScreen | RoutePaths.mainAppProfile | ui-loading-error-empty-consistency, state-viewmodel-only-business-logic |

## Learning Flow

| Man hinh | Route | Rule uu tien |
| --- | --- | --- |
| CourseDetailScreen | RoutePaths.courseInCourses(courseId) | data-repository-result-pattern, navigation-route-path-constants, reliability-context-mounted-after-await |
| LessonListScreen | RoutePaths.courseLessons(courseId) | ui-loading-error-empty-consistency, state-viewmodel-only-business-logic |
| LessonDetailScreen | RoutePaths.courseLessonDetail(...) | navigation-route-path-constants, reliability-context-mounted-after-await, state-viewmodel-only-business-logic |
| ModuleLearningScreen | RoutePaths.courseLessonModule(...) | state-immutable-copywith, ui-loading-error-empty-consistency |
| PronunciationScreen / PronunciationDetailScreen | RoutePaths.pronunciation, RoutePaths.pronunciationDetail | reliability-context-mounted-after-await, reliability-no-blocking-in-build |

## Auth Flow

| Man hinh | Route | Rule uu tien |
| --- | --- | --- |
| Login / Register | RoutePaths.login, RoutePaths.register | navigation-router-redirect-source-of-truth, navigation-route-path-constants |
| Forgot/Reset Password | RoutePaths.forgotPassword, RoutePaths.verifyResetOtp, RoutePaths.resetPassword | navigation-router-redirect-source-of-truth, reliability-context-mounted-after-await |

## Other Feature Screens

| Man hinh | Route | Rule uu tien |
| --- | --- | --- |
| SearchScreen | RoutePaths.search | navigation-route-path-constants, ui-loading-error-empty-consistency |
| NotificationScreen | RoutePaths.notifications | ui-loading-error-empty-consistency, reliability-no-blocking-in-build |
| Payment screens | RoutePaths.payment, RoutePaths.paymentSuccess, RoutePaths.paymentFailed | data-repository-result-pattern, navigation-route-path-constants |
| QuizScreen | RoutePaths.quiz | state-immutable-copywith, reliability-context-mounted-after-await |


