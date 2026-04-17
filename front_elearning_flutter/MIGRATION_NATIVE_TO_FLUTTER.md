# Migration Native -> Flutter

Tai lieu nay dinh huong viec chuyen ung dung `NativeELearningEnglish` sang `front_elearning_flutter` voi muc tieu:

- Giu giao dien va hanh vi gan giong Native app.
- Tuan thu mo hinh hien co cua Flutter app: `views` / `viewmodels` / `repositories` / `services`.

## 1) Scope chuc nang can migrate

- Auth: login/register/forgot/reset/otp.
- Main tabs: Home, My Courses, Vocabulary, Notebook, Profile.
- Learning flow: course detail, lesson list/detail, module learning, lecture, assignment, quiz, essay, lesson result.
- Payment: payment screen, success/failed, history, deep-link callback.
- Notification + flashcard learning/review.
- Teacher flow: home/classes/create course/course detail/lesson detail/submissions/quiz attempts.

## 2) Trang thai hien tai (cap nhat)

- Da map day du cac man hinh Native-equivalent sang Flutter (auth, student, payment, teacher, flashcard, notification).
- Route da duoc cau hinh day du trong:
  - `lib/app/router/route_paths.dart`
  - `lib/app/router/app_router.dart`
- Cac file migration tam da duoc xoa:
  - `lib/views/screens/legacy_screens.dart`
  - `lib/views/screens/native_migration/placeholder_screen.dart`
  - `lib/views/screens/common/api_data_screen.dart`
- Flow chinh da hoat dong:
  - Learning flow (course -> lesson -> module -> assignment -> quiz/essay -> result)
  - Payment flow (process -> create pay link -> confirm/polling -> success/failed/history)
  - Teacher flow (home, course, class list, submissions, quiz attempts, detail)
  - Flashcard learning/review + notifications

## 3) Ke hoach con lai de dat 1:1 voi native

1. **UI parity pass**
   - Align spacing, typography, iconography, color, empty/loading/error states theo tung man native.
2. **Interaction parity pass**
   - Hoan thien animation/transition va edge-cases cho payment, quiz, flashcard, teacher review.
3. **Behavior verification pass**
   - Checklist tung man: UI/logic/api params/navigation/result states.

## 4) Mapping tang kien truc (bat buoc)

- Native `src/Services/*.js` -> Flutter `lib/repositories/*_repository.dart` + `lib/services/api_service.dart`.
- Native screen state local -> Flutter `StateNotifier` trong `lib/viewmodels/`.
- Native route names -> Flutter `RoutePaths` (giu ten duong dan de de doi chieu).

## 5) Quy tac coding cho migration

- Moi man hinh migrate xong phai:
  - Co route trong `app_router.dart`.
  - Co viewmodel (neu co business logic).
  - Co repository call API thong qua `ApiService`.
  - Khong call `Dio` truc tiep trong UI.
