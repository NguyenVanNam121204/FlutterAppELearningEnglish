import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

// ============================================================
// CẤU HÌNH MÔI TRƯỜNG TEST
// ============================================================

/// URL gốc của backend API
/// 10.0.2.2 = localhost từ trong máy ảo Android
const String testApiBase = 'http://10.0.2.2:5030';

/// Email của tài khoản học viên dùng trong kịch bản E2E
const String testUserEmail = 'nt0143436946@gmail.com';

// ============================================================
// PRE-TEST CLEANUP: Dọn sạch dữ liệu tiến độ trước mỗi lần test
// ============================================================
// Gọi API TestController trên backend để xóa toàn bộ lịch sử:
//   - Lịch sử làm Quiz
//   - Lịch sử ôn tập Flashcard
//   - Tiến độ bài học, khóa học, Streaks
//
// Đảm bảo kịch bản E2E luôn bắt đầu từ trạng thái sạch sẽ
// và nhất quán, không bị ảnh hưởng bởi dữ liệu từ lần chạy trước.
// ============================================================

/// Dọn sạch toàn bộ dữ liệu tiến độ của tài khoản test.
///
/// Được gọi trong [setUpAll] trước khi bất kỳ test nào chạy.
/// Không fail test nếu backend chưa khởi động - chỉ in cảnh báo.
Future<void> cleanupTestUserProgress() async {
  debugPrint('=== [PRE-TEST] Bắt đầu dọn sạch dữ liệu tiến độ test ===');

  try {
    // Tắt kiểm tra SSL certificate (Backend local dùng http)
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;

    // Bước 1: Lấy userId của tài khoản test qua API check-env
    final checkUri =
        Uri.parse('$testApiBase/api/test/check-env?email=$testUserEmail');
    final checkRequest = await httpClient.getUrl(checkUri);
    final checkResponse = await checkRequest.close();
    final checkBody =
        await checkResponse.transform(const Utf8Decoder()).join();
    final checkJson = jsonDecode(checkBody) as Map<String, dynamic>;

    final testUser = checkJson['testUser'];
    if (testUser == null) {
      debugPrint(
        '[PRE-TEST] ⚠️ Không tìm thấy tài khoản test "$testUserEmail". Bỏ qua cleanup.',
      );
      return;
    }

    final int userId = testUser['userId'] as int;
    debugPrint(
        '[PRE-TEST] ✅ Tìm thấy tài khoản test (userId=$userId). Đang dọn dẹp...');

    // Bước 2: Gọi API dọn dẹp toàn bộ dữ liệu tiến độ học tập
    final cleanupUri = Uri.parse(
        '$testApiBase/api/test/cleanup-user-progress?userId=$userId');
    final cleanupRequest = await httpClient.postUrl(cleanupUri);
    cleanupRequest.headers.set('Content-Type', 'application/json');
    final cleanupResponse = await cleanupRequest.close();
    final cleanupBody =
        await cleanupResponse.transform(const Utf8Decoder()).join();
    final cleanupJson = jsonDecode(cleanupBody) as Map<String, dynamic>;

    if (cleanupResponse.statusCode == 200 && cleanupJson['success'] == true) {
      final summary = cleanupJson['summary'] as Map<String, dynamic>;
      debugPrint('[PRE-TEST] ✅ Dọn dẹp thành công!');
      debugPrint(
          '[PRE-TEST]   - QuizAttempts đã xóa: ${summary['quizAttemptsDeleted']}');
      debugPrint(
          '[PRE-TEST]   - FlashCardReviews đã xóa: ${summary['flashCardReviewsDeleted']}');
      debugPrint(
          '[PRE-TEST]   - LessonCompletions đã xóa: ${summary['lessonCompletionsDeleted']}');
      debugPrint(
          '[PRE-TEST]   - ModuleCompletions đã xóa: ${summary['moduleCompletionsDeleted']}');
      debugPrint(
          '[PRE-TEST]   - CourseProgresses đã xóa: ${summary['courseProgressesDeleted']}');
      debugPrint(
          '[PRE-TEST]   - Streaks đã xóa: ${summary['streaksDeleted']}');
    } else {
      debugPrint(
          '[PRE-TEST] ⚠️ Cleanup API trả về: ${cleanupResponse.statusCode} - $cleanupBody');
    }

    httpClient.close();
  } catch (e) {
    // Không fail test nếu cleanup lỗi (backend chưa khởi động...)
    // Test sẽ tiếp tục chạy, chỉ cảnh báo để người dùng biết
    debugPrint('[PRE-TEST] ⚠️ Không thể kết nối API cleanup: $e');
    debugPrint('[PRE-TEST]    Hãy đảm bảo backend đang chạy tại $testApiBase');
    debugPrint('[PRE-TEST]    Test sẽ tiếp tục chạy với dữ liệu hiện tại...');
  }

  debugPrint('=== [PRE-TEST] Hoàn tất giai đoạn chuẩn bị môi trường ===');
}
