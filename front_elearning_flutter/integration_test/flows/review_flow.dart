import '../helpers/test_helpers.dart';

// ============================================================
// BƯỚC 5: LUỒNG ÔN TẬP TỪ VỰNG (REVIEW FLOW)
// ============================================================
// State-based approach:
//   Sau khi tap tab Ôn tập: chờ một trong các trạng thái xuất hiện
//      (nút Bắt đầu ôn / text "Tuyệt vời!" / nút Quay lại trang chủ)
//   Sau khi lật thẻ: chờ nút "Thuộc" xuất hiện (= animation lật xong)
//   Sau khi tap "Thuộc": chờ loading biến mất (= API cập nhật xong)
// ============================================================

/// Điều hướng đến tab Ôn tập và thực hiện ôn từ vựng (nếu có).
///
/// Xử lý thông minh 3 trạng thái:
///   - Trạng thái A: Có từ cần ôn hôm nay → Tiến hành ôn tập
///   - Trạng thái B: Đã hoàn thành (Spaced Repetition) → Ghi nhận & thoát
///   - Trạng thái C: Chưa xác định → Cảnh báo và tiếp tục
Future<void> runReviewFlow(WidgetTester tester) async {
  logFlowStart('Review Flow');
  // Tap tab Ôn tập → Xác nhận: Màn ôn tập đã render (1 trong 3 trạng thái xuất hiện)
  final reviewTab = find.byTooltip('Ôn tập');
  await tapAndWaitFor(
    tester,
    reviewTab,
    find.byWidgetPredicate(
      (w) =>
          w is Text &&
          (w.data == 'Bấm để ôn tập ngay 🔥' ||
              w.data == 'Tuyệt vời!' ||
              w.data == 'Quay lại trang chủ'),
    ),
    timeout: const Duration(seconds: 15),
    reason: 'Màn hình Ôn tập không tải được',
  );

  final startReviewBtn = find.text('Bấm để ôn tập ngay 🔥');
  final allDoneText = find.text('Tuyệt vời!');
  final goHomeBtn = find.text('Quay lại trang chủ');

  if (tester.any(startReviewBtn)) {
    // TRẠNG THÁI A: Có từ cần ôn hôm nay
    await _performReviewSession(tester);
  } else if (tester.any(allDoneText) || tester.any(goHomeBtn)) {
    // TRẠNG THÁI B: Spaced Repetition - Từ mới học chưa đến hạn ôn
    // Hành vi hoàn toàn đúng của hệ thống!
    debugPrint('--- TẤT CẢ TỪ VỰNG ĐÃ ĐƯỢC ÔN HÔM NAY (SPACED REPETITION) ---');
    debugPrint('--- MÀN HÌNH HIỂN THỊ: "Tuyệt vời! Hãy quay lại ngày mai" ---');

    if (tester.any(goHomeBtn)) {
      await tapAndWaitForLoad(tester, goHomeBtn);
    }
  } else {
    // TRẠNG THÁI C: Không xác định được trạng thái
    debugPrint('--- KHÔNG XÁC ĐỊNH ĐƯỢC TRẠNG THÁI MÀN HÌNH ÔN TẬP ---');
  }
  logFlowPass('Review Flow');
}

// ──────────────────────────────────────────────
// PHIÊN ÔN TẬP: Lật thẻ → Đánh giá mức độ thuộc
// ──────────────────────────────────────────────

Future<void> _performReviewSession(WidgetTester tester) async {
  debugPrint('--- CÓ TỪ CẦN ÔN HÔM NAY → TIẾN HÀNH ÔN TẬP ---');

  // Tap Bắt đầu ôn → Xác nhận: "Tiến độ ôn tập" xuất hiện = màn ôn đã mở
  await tapAndWaitFor(
    tester,
    find.text('Bấm để ôn tập ngay 🔥'),
    find.text('Tiến độ ôn tập'),
    timeout: const Duration(seconds: 12),
    reason: 'Màn hình ôn tập không mở được',
  );

  // Lật thẻ xem mặt sau từ vựng
  final reviewCard = find.byKey(const ValueKey('review-card-0'));
  if (tester.any(reviewCard)) {
    await tester.tap(reviewCard);

    // Xác nhận: Nút "Thuộc" xuất hiện = animation lật đã hoàn thành
    // (Đây là trạng thái chính xác thay vì delay 2s)
    final masteredBtn = find.text('Thuộc');
    await waitFor(
      tester,
      masteredBtn,
      timeout: const Duration(seconds: 5),
      reason: 'Nút "Thuộc" không xuất hiện sau khi lật thẻ ôn tập',
    );

    // Tap "Thuộc" → Xác nhận: Loading biến mất = API đã cập nhật tiến độ
    await tapAndWaitForLoad(
      tester,
      masteredBtn,
      timeout: const Duration(seconds: 10),
    );
  }

  // Quay lại màn hình ôn tập chính
  final reviewBackButton = find.byType(BackButton);
  if (tester.any(reviewBackButton)) {
    await tester.tap(reviewBackButton);
    // Thay vì waitForLoading (bị nhầm với vòng tiến độ học tập 100%),
    // ta chờ màn hình chính xuất hiện lại (có text 'Ôn tập từ vựng')
    await waitFor(
      tester,
      find.text('Ôn tập từ vựng'),
      timeout: const Duration(seconds: 5),
    );
    await tester.pump(const Duration(milliseconds: 600)); // Chờ animation
  }

  debugPrint('--- HOÀN THÀNH PHIÊN ÔN TẬP TỪ VỰNG ---');
}
