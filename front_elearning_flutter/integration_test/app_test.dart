import 'package:integration_test/integration_test.dart';
import 'package:front_elearning_flutter/main.dart' as app;

import 'helpers/api_cleanup.dart';
import 'helpers/test_helpers.dart';
import 'flows/auth_flow.dart';
import 'flows/flashcard_flow.dart';
import 'flows/quiz_flow.dart';
import 'flows/review_flow.dart';

// ============================================================
// ENTRY POINT: KỊCH BẢN E2E KHÉP KÍN
// ============================================================
// Kiến trúc:
//   helpers/test_helpers.dart  → Các hàm chờ state-based (waitFor, waitForGone...)
//   helpers/api_cleanup.dart   → Dọn dữ liệu tiến độ trước test
//   flows/auth_flow.dart       → BƯỚC 1: Kiểm tra & đăng nhập
//   flows/flashcard_flow.dart  → BƯỚC 2+3: Chọn khóa học & học Flashcard
//   flows/quiz_flow.dart       → BƯỚC 4: Tự động giải Quiz
//   flows/review_flow.dart     → BƯỚC 5: Ôn tập từ vựng
// ============================================================

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Dọn sạch dữ liệu tiến độ trước khi chạy test
  // → Đảm bảo môi trường luôn nhất quán và không bị ảnh hưởng bởi lần chạy trước
  setUpAll(() async {
    await cleanupTestUserProgress();
  });

  group(
    'KỊCH BẢN E2E: ĐĂNG NHẬP → HỌC BÀI → LÀM QUIZ → ÔN TẬP TỪ VỰNG',
    () {
      testWidgets(
        'Kiểm thử luồng học tập khép kín của học viên',
        (WidgetTester tester) async {
          // Khởi chạy ứng dụng thật
          app.main();

          // Chờ màn hình đầu tiên render: login form HOẶC home
          // (dùng waitForAny vì Flutter test không có Finder.or())
          await waitForAny(
            tester,
            [
              find.byKey(const ValueKey('email-field')),
              find.byTooltip('Khóa học'),
            ],
            timeout: const Duration(seconds: 10),
            reason: 'App không khởi động được trong 10 giây',
          );

          // ── BƯỚC 1: Đăng nhập (nếu chưa đăng nhập) ──────────
          await runAuthFlow(tester);

          // ── BƯỚC 2+3: Chọn khóa học & học Flashcard ──────────
          await runFlashcardFlow(tester);

          // ── BƯỚC 4: Làm Quiz và xem kết quả ──────────────────
          await runQuizFlow(tester);

          // ── BƯỚC 5: Ôn tập từ vựng ───────────────────────────
          await runReviewFlow(tester);

          debugPrint('');
          debugPrint('╔══════════════════════════════════════════╗');
          debugPrint('║  ALL FLOWS PASSED - E2E COMPLETE         ║');
          debugPrint('╚══════════════════════════════════════════╝');
        },
      );
    },
  );
}
