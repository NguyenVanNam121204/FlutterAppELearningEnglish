import 'package:flutter/material.dart';
// Re-export để các flow file chỉ cần import test_helpers.dart là đủ
export 'package:flutter/material.dart';
export 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test/flutter_test.dart';

// ============================================================
// STATE-BASED WAITING HELPERS
// ============================================================
// Triết lý: "Không quan tâm mất bao nhiêu giây.
//            Chỉ quan tâm hệ thống đã đến trạng thái X chưa."
//
// Không bao giờ dùng delay cứng (delay ms: 5000).
// Thay vào đó: chờ loading biến mất, button xuất hiện,
// text xuất hiện, route chuyển màn...
// ============================================================

/// Chờ cho đến khi widget XUẤT HIỆN trên màn hình.
///
/// Pump từng frame 100ms một và kiểm tra trạng thái UI thực tế.
/// Fail rõ ràng với [reason] nếu quá [timeout].
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 15),
  String? reason,
}) async {
  final deadline = DateTime.now().add(timeout);
  do {
    if (tester.any(finder)) return;
    await tester.pump(const Duration(milliseconds: 100));
  } while (DateTime.now().isBefore(deadline));

  // Lần check cuối sau khi pump
  expect(
    finder,
    findsAtLeastNWidgets(1),
    reason: reason ?? 'Widget không xuất hiện sau $timeout:\n  $finder',
  );
}

/// Chờ cho đến khi widget BIẾN MẤT khỏi màn hình.
///
/// Dùng để xác nhận loading spinner / overlay đã kết thúc
/// thay vì đoán thời gian API trả về.
Future<void> waitForGone(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
  String? reason,
}) async {
  final deadline = DateTime.now().add(timeout);
  do {
    if (!tester.any(finder)) return;
    await tester.pump(const Duration(milliseconds: 100));
  } while (DateTime.now().isBefore(deadline));

  expect(
    finder,
    findsNothing,
    reason: reason ?? 'Widget vẫn còn hiển thị sau $timeout:\n  $finder',
  );
}

/// Chờ CircularProgressIndicator biến mất = tải xong.
///
/// Đây là cách chuẩn để xác nhận "API đã trả về và UI đã cập nhật"
/// thay vì await delay(tester, ms: 3000).
Future<void> waitForLoading(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  // Pump 1 frame để loading có cơ hội xuất hiện nếu chưa có
  await tester.pump(const Duration(milliseconds: 150));

  // Chỉ chờ các vòng xoay loading không xác định (value == null).
  // Điều này giúp loại bỏ lỗi dính vòng lặp với các vòng xoay hiển thị tiến độ (value != null),
  // đồng thời TỰ ĐỘNG CHỜ ảnh CachedNetworkImage tải xong (vì placeholder dùng value == null).
  final loadingFinder = find.byWidgetPredicate(
    (widget) => 
        (widget is CircularProgressIndicator && widget.value == null) ||
        (widget is LinearProgressIndicator && widget.value == null),
    description: 'Indeterminate ProgressIndicator',
  );

  if (tester.any(loadingFinder)) {
    await waitForGone(
      tester,
      loadingFinder,
      timeout: timeout,
      reason: 'Loading indicator hoặc Ảnh từ Minio chưa tải xong sau $timeout',
    );
  }

  // Pump thêm để UI settle hoàn toàn
  await tester.pump(const Duration(milliseconds: 150));
}

// ============================================================
// VISUAL PACING: Khoảng thở ngắn sau khi state đã xác nhận
// ============================================================
// Khác biệt quan trọng với blind delay:
//
//    Blind delay:   tap → delay(5s) → action    (chờ mù quáng)
//    State-based:  tap → waitFor → action       (chờ đúng nhưng quá nhanh)
//    State + pace: tap → waitFor → pause → action (chờ đúng + mắt người kịp thấy)
//
// _visualPause chạy SAU KHI state đã được xác nhận, không phải trước.
// Dùng Future.delayed (thời gian thực) để đảm bảo pause thực sự trên thiết bị.
// ============================================================

/// Khoảng thở ngắn sau khi màn hình đã tải xong, để mắt người kịp quan sát.
///
/// Chỉ được gọi SAU `waitFor` hoặc `waitForLoading` thành công.
Future<void> _visualPause(WidgetTester tester, [int ms = 700]) async {
  await Future.delayed(Duration(milliseconds: ms));
  await tester.pump();
}

/// Tap một widget rồi chờ một widget khác XUẤT HIỆN.
///
/// Flow: tap → waitFor(state) → visualPause → tiếp tục.
/// Khác với delay cứng: chỉ pause SAU KHI đã xác nhận màn hình mới đã sẵn sàng.
Future<void> tapAndWaitFor(
  WidgetTester tester,
  Finder tapTarget,
  Finder waitTarget, {
  Duration timeout = const Duration(seconds: 15),
  String? reason,
}) async {
  await tester.tap(tapTarget);
  // 1. Chờ UI chính xuất hiện
  await waitFor(tester, waitTarget, timeout: timeout, reason: reason);
  // 2. Chờ luôn mọi Loading Indicator (bao gồm Placeholder của Ảnh Minio) biến mất!
  await waitForLoading(tester, timeout: const Duration(seconds: 10));
  // 3. Dừng hình 1 chút cho mắt người nhìn
  await _visualPause(tester); 
}

/// Tap một widget rồi chờ loading indicator biến mất (sau khi gọi API).
///
/// Flow: tap → waitForLoading → visualPause → tiếp tục.
Future<void> tapAndWaitForLoad(
  WidgetTester tester,
  Finder tapTarget, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  await tester.tap(tapTarget);
  await waitForLoading(tester, timeout: timeout);
  await _visualPause(tester); // API xong → cho mắt người thấy rồi mới tiếp
}

// ============================================================
// FINDER UTILITIES: Thay thế cho Finder.or() không có trong flutter_test
// ============================================================

/// Tạo Finder khớp với bất kỳ Text nào trong danh sách.
///
/// Thay thế cú pháp `find.text('A').or(find.text('B'))` không tồn tại.
///
/// Ví dụ:
/// ```dart
/// await waitFor(tester, findAnyText(['HOÀN THÀNH', 'Hoàn thành']));
/// ```
Finder findAnyText(List<String> texts) => find.byWidgetPredicate(
      (w) => w is Text && texts.contains(w.data),
    );

/// Chờ cho đến khi BẤT KỲ widget nào trong danh sách xuất hiện.
///
/// Hữu ích khi màn hình có thể hiển thị nhiều trạng thái khác nhau
/// (ví dụ: "Bắt đầu làm bài mới" HOẶC "Tiếp tục bài đang làm").
Future<Finder> waitForAny(
  WidgetTester tester,
  List<Finder> finders, {
  Duration timeout = const Duration(seconds: 15),
  String? reason,
}) async {
  final deadline = DateTime.now().add(timeout);
  do {
    for (final f in finders) {
      if (tester.any(f)) return f;
    }
    await tester.pump(const Duration(milliseconds: 100));
  } while (DateTime.now().isBefore(deadline));

  fail(
    reason ??
        'Không có widget nào trong danh sách xuất hiện sau $timeout:\n'
            '  ${finders.map((f) => f.toString()).join('\n  ')}',
  );
}

// ============================================================
// FLOW REPORTING: Báo hiệu trạng thái từng flow trong console
// ============================================================

/// In banner báo hiệu một flow đang bắt đầu.
///
/// Giúp phân biệt ranh giới giữa các flow khi đọc log.
///
/// Ví dụ output:
/// ```
/// ┌─────────────────────────────────────┐
/// │  STARTING: Auth Flow                │
/// └─────────────────────────────────────┘
/// ```
void logFlowStart(String flowName) {
  final line = '─' * (flowName.length + 14);
  debugPrint('┌$line┐');
  debugPrint('│  STARTING: $flowName  │');
  debugPrint('└$line┘');
}

/// In banner báo hiệu một flow đã PASS (kết thúc không có lỗi).
///
/// Chỉ được gọi nếu toàn bộ flow chạy qua mà không throw exception.
/// Đây là cách chắc chắn nhất để biết flow đó đã thành công.
///
/// Ví dụ output:
/// ```
/// ╔═════════════════════════════════════╗
/// ║  PASSED: Auth Flow                  ║
/// ╚═════════════════════════════════════╝
/// ```
void logFlowPass(String flowName) {
  final line = '═' * (flowName.length + 12);
  debugPrint('╔$line╗');
  debugPrint('║  PASSED: $flowName  ║');
  debugPrint('╚$line╝');
}
