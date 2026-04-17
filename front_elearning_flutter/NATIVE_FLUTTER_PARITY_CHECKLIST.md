# Native -> Flutter Parity Checklist

Muc tieu danh gia: **UI + logic + navigation flow + API behavior**.

Quy uoc:
- `PASS`: Da dat muc gan 1:1 o muc man hinh + flow chinh.
- `FAIL`: Con lech ro ve UI/logic/edge cases so voi native.

## Auth

- `Auth/LoginPage.jsx` -> `auth/login_screen.dart`: **PASS**
- `Auth/RegisterPage.jsx` -> `auth/register_screen.dart`: **PASS**
- `Auth/ForgotPasswordPage.jsx` -> `auth/forgot_password_screen.dart`: **PASS**
- `Auth/OTPVerificationPage.jsx` -> `auth/verify_email_otp_screen.dart`: **PASS**
- `Auth/ResetPasswordPage.jsx` -> `auth/reset_password_screen.dart`: **PASS**
- `Auth/OTPVerificationPage.jsx` (reset flow) -> `auth/verify_reset_otp_screen.dart`: **PASS**

## Student Core Learning

- `Course/CourseDetailScreen.jsx` -> `course/course_detail_screen.dart`: **PASS**
- `Search/SearchScreen.jsx` -> `search/search_screen.dart`: **PASS**
- `Lesson/LessonListScreen.jsx` -> `lesson/lesson_list_screen.dart`: **PASS**
- `Lesson/LessonDetailScreen.jsx` -> `lesson/lesson_detail_screen.dart`: **PASS**
- `Lesson/ModuleLearningScreen.jsx` -> `lesson/module_learning_screen.dart`: **PASS**
- `Lesson/Lecture/LectureDetailScreen.jsx` -> `lesson/lecture_detail_screen.dart`: **PASS**
- `Lesson/Assignment/AssignmentDetailScreen.jsx` -> `assignment/assignment_detail_screen.dart`: **PASS**
- `Lesson/Quiz/QuizScreen.jsx` -> `quiz/quiz_screen.dart`: **PASS**
- `Lesson/LessonResultScreen.jsx` -> `lesson/lesson_result_screen.dart`: **PASS**
- `Lesson/Assignment/EssayScreen.jsx` -> `assignment/essay_screen.dart`: **PASS**

## Pronunciation + Flashcard

- `Lesson/Pronunciation/PronunciationScreen.jsx` -> `lesson/pronunciation_screen.dart`: **PASS**
- `Lesson/PronunciationDetail/PronunciationDetailScreen.jsx` -> `lesson/pronunciation_detail_screen.dart`: **PASS**
- `Lesson/Flashcard/FlashcardLearningScreen.jsx` -> `flashcard/flashcard_learning_screen.dart`: **PASS**
- `FlashCard/FlashCardLearningScreen.jsx` -> `flashcard/flashcard_learning_screen.dart`: **PASS**
- `FlashCard/FlashCardReviewSession.jsx` -> `flashcard/flashcard_review_session_screen.dart`: **PASS**

## Main Tabs + General

- `Home/HomeScreen.jsx` -> `home/home_screen.dart`: **PASS**
- `Onion/OnionScreen.jsx` -> `onion/onion_screen.dart`: **PASS**
- `Vocabulary/VocabularyScreen.jsx` -> `vocabulary/vocabulary_screen.dart`: **PASS**
- `Gym/GymScreen.jsx` -> `gym/gym_screen.dart`: **PASS**
- `Profile/ProfileScreen.jsx` -> `profile/profile_screen.dart`: **PASS**
- `Pro/ProScreen.jsx` -> `pro/pro_screen.dart`: **PASS**
- `Notification/NotificationScreen.jsx` -> `notification/notification_screen.dart`: **PASS**
- `Loading/LoadingPage.jsx` -> `loading/loading_page.dart`: **PASS**

## Payment

- `Payment/PaymentScreen.jsx` -> `payment/payment_screen.dart`: **PASS**
- `Payment/PaymentSuccess.jsx` -> `payment/payment_success_screen.dart`: **PASS**
- `Payment/PaymentFailed.jsx` -> `payment/payment_failed_screen.dart`: **PASS**
- `Payment/PaymentHistoryScreen.jsx` -> `payment/payment_history_screen.dart`: **PASS**

## Teacher

- `Teacher/TeacherHomeScreen.jsx` -> `teacher/teacher_home_screen.dart`: **PASS**
- `Teacher/CreateCourseScreen.jsx` -> `teacher/create_course_screen.dart`: **PASS**
- `Teacher/TeacherCourseDetailScreen.jsx` -> `teacher/teacher_course_detail_screen.dart`: **PASS**
- `Teacher/TeacherClassListScreen.jsx` -> `teacher/teacher_class_list_screen.dart`: **PASS**
- `Teacher/TeacherLessonDetailScreen.jsx` -> `teacher/teacher_lesson_detail_screen.dart`: **PASS**
- `Teacher/TeacherCourseSubmissionsScreen.jsx` -> `teacher/teacher_course_submissions_screen.dart`: **PASS**
- `Teacher/TeacherEssaySubmissionsScreen.jsx` -> `teacher/teacher_essay_submissions_screen.dart`: **PASS**
- `Teacher/TeacherSubmissionDetailScreen.jsx` -> `teacher/teacher_submission_detail_screen.dart`: **PASS**
- `Teacher/TeacherQuizAttemptsScreen.jsx` -> `teacher/teacher_quiz_attempts_screen.dart`: **PASS**
- `Teacher/TeacherQuizAttemptDetailScreen.jsx` -> `teacher/teacher_quiz_attempt_detail_screen.dart`: **PASS**

## Tong ket nhanh

- Tong so man native da doi chieu: **42**
- `PASS`: **42**
- `FAIL`: **0**

## Danh sach uu tien fix tiep (FAIL)

Khong con man hinh FAIL trong checklist hien tai.

