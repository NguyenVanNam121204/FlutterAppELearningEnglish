
import '../helpers/test_helpers.dart';
import 'package:front_elearning_flutter/views/widgets/quiz/game/game_multiple_choice_widget.dart';
import 'package:front_elearning_flutter/views/widgets/quiz/game/game_true_false_widget.dart';
import 'package:front_elearning_flutter/views/widgets/quiz/game/game_multi_select_widget.dart';
import 'package:front_elearning_flutter/views/widgets/quiz/game/game_fill_in_widget.dart';
import 'package:front_elearning_flutter/views/widgets/quiz/game/game_matching_widget.dart';
import 'package:front_elearning_flutter/views/widgets/quiz/game/game_ordering_widget.dart';


// ============================================================
// BƯỚC 4: LUỒNG LÀM QUIZ (QUIZ FLOW)
// ============================================================
// State-based approach:
//   ✅ Chờ nút bắt đầu (1 trong 3 loại) xuất hiện → chọn đúng loại
//   ✅ Sau khi trả lời: chờ nút TIẾP THEO / NỘP BÀI xuất hiện
//      (= câu đã được chấm điểm và sẵn sàng cho bước tiếp theo)
//   ✅ Sau khi nộp bài: chờ trang kết quả xuất hiện (nút HOÀN THÀNH)
//   ✅ Sau khi xem chi tiết: chờ quay lại kết quả (nút HOÀN THÀNH lại)
// ============================================================

/// Luồng hoàn chỉnh: Điều hướng đến Quiz → Giải tự động → Xem kết quả.
///
/// Kết thúc khi: Đã bấm Hoàn thành thoát kết quả và quay về danh sách bài học.
Future<void> runQuizFlow(WidgetTester tester) async {
  logFlowStart('Quiz Flow');
  await _navigateToQuiz(tester);
  await _solveAllQuestions(tester);
  await _handleQuizResult(tester);
  logFlowPass('Quiz Flow');
}

// ──────────────────────────────────────────────
// NAVIGATION: Chi tiết bài học → Bài test → Bài quiz 1 → Bắt đầu
// ──────────────────────────────────────────────

Future<void> _navigateToQuiz(WidgetTester tester) async {
  // Tap "Bài test" → Xác nhận: "Bài quiz 1" xuất hiện = danh sách đã tải
  await tapAndWaitFor(
    tester,
    find.text('Bài test'),
    find.text('Bài quiz 1'),
    timeout: const Duration(seconds: 10),
    reason: '"Bài quiz 1" không xuất hiện trong danh sách bài test',
  );

  // Tap "Bài quiz 1" → Xác nhận: Một trong 3 nút bắt đầu xuất hiện
  final resumeBtn = find.text('Tiếp tục bài đang làm');
  final startNewBtn = find.text('Bắt đầu làm bài mới');
  final startBtn = find.text('Bắt đầu làm bài');

  await tester.tap(find.text('Bài quiz 1'));

  final startTrigger = await waitForAny(
    tester,
    [resumeBtn, startNewBtn, startBtn],
    timeout: const Duration(seconds: 10),
    reason: 'Không tìm thấy nút bắt đầu quiz sau khi vào Chi tiết bài thi',
  );

  // Phân nhánh: Bài làm dở / Làm mới / Lần đầu
  if (tester.any(resumeBtn)) {
    debugPrint('--- PHÁT HIỆN BÀI THI LÀM Dở → TIẾP TỤC ---');
  } else if (tester.any(startNewBtn)) {
    debugPrint('--- TIẺN HÀNH BẮT ĐẦU LÀM BÀI MỚI ---');
  } else {
    debugPrint('--- TIẺN HÀNH BẮT ĐẦU LÀM BÀI ---');
  }

  // ensureVisible: scroll nút vào vùng nhìn thấy trước khi tap
  // (cần thiết khi nút ở dưới cùng và bị khuất khỏi viewport)
  await tester.ensureVisible(startTrigger);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(startTrigger);

  // Người dùng báo: Khi bấm bắt đầu có SnackBar hiện lên từ dưới màn hình
  // SnackBar này có thể che nút "TIẾP THEO" ở đáy màn hình.
  // Do đó, ta phải đợi nó biến mất hoàn toàn trước khi tiếp tục.
  // Pump 1 phát để đảm bảo SnackBar kịp xuất hiện trong widget tree (nếu có)
  await tester.pump(const Duration(milliseconds: 100));
  final snackBar = find.byType(SnackBar);
  if (tester.any(snackBar)) {
    debugPrint('--- ĐANG CHỜ THÔNG BÁO (SNACKBAR) ẨN ĐI ---');
    await waitForGone(tester, snackBar, timeout: const Duration(seconds: 5));
  }

  // Xác nhận: Câu hỏi đầu tiên sẵn sàng = nút TIẾP THEO hoặc NỘP BÀI xuất hiện
  await waitFor(
    tester,
    findAnyText(['TIẾP THEO', 'NỘP BÀI']),
    timeout: const Duration(seconds: 15),
    reason: 'Câu hỏi đầu tiên không tải được',
  );
  debugPrint('--- ✅ ĐÃ TẢI XONG ĐỀ THI ---');
}

// ──────────────────────────────────────────────
// GIẢI TỰ ĐỘNG: Lặp qua 13 câu hỏi
// ──────────────────────────────────────────────

Future<void> _solveAllQuestions(WidgetTester tester) async {
  for (int q = 1; q <= 13; q++) {
    debugPrint('--- ĐANG LÀM CÂU HỎI SỐ $q/13 ---');
    await _autoAnswerCurrentQuestion(tester);

      if (q < 13) {
      // Xác nhận: Nút TIẾP THEO xuất hiện = câu đã được chấm điểm
      final nextQuestionBtn = find.text('TIẾP THEO');
      await waitFor(
        tester,
        nextQuestionBtn,
        reason: 'Nút TIẾP THEO không xuất hiện sau khi trả lời câu $q',
      );
      
      // Cuộn đến nút TIẾP THEO nếu nó bị khuất ở dưới
      await tester.ensureVisible(nextQuestionBtn);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(nextQuestionBtn, warnIfMissed: false);

      // Xác nhận: Đã chuyển sang câu tiếp theo (chờ text chỉ số câu hỏi thay đổi)
      await waitFor(
        tester,
        find.textContaining('Câu hỏi ${q + 1}/'),
        reason: 'Câu hỏi số ${q + 1} không xuất hiện',
      );
      
      // Chờ thêm 600ms để hiệu ứng cuộn PageView hoàn tất trước khi làm câu tiếp
      await tester.pump(const Duration(milliseconds: 600));
    } else {
      // Câu cuối → Nộp bài
      await _submitQuiz(tester);
    }
  }
}

/// Nộp bài và chờ trang kết quả xuất hiện.
Future<void> _submitQuiz(WidgetTester tester) async {
  final submitQuizBtn = find.text('NỘP BÀI');
  await waitFor(
    tester,
    submitQuizBtn,
    reason: 'Nút NỘP BÀI không xuất hiện ở câu cuối',
  );
  await tester.ensureVisible(submitQuizBtn);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(submitQuizBtn, warnIfMissed: false);

  // Xác nhận: Hộp thoại xác nhận xuất hiện (nếu có)
  final confirmSubmitBtn = find.text('Nộp bài');
  await waitFor(
    tester,
    confirmSubmitBtn,
    timeout: const Duration(seconds: 5),
    reason: 'Hộp thoại xác nhận nộp bài',
  ).catchError((_) {}); // Hộp thoại không bắt buộc

  if (tester.any(confirmSubmitBtn)) {
    await tester.tap(confirmSubmitBtn);
  }

  // Xác nhận: Trang kết quả đã tải = nút HOÀN THÀNH hoặc XEM CHI TIẾT xuất hiện
  await waitFor(
    tester,
    findAnyText([
      'HOÀN THÀNH',
      'Hoàn thành',
      'XEM CHI TIẾT BÀI LÀM',
      'Xem chi tiết bài làm',
    ]),
    timeout: const Duration(seconds: 20),
    reason: 'Trang kết quả không tải được sau khi nộp bài',
  );
  debugPrint('--- ✅ ĐÃ NỘP BÀI THÀNH CÔNG ---');
}

// ──────────────────────────────────────────────
// XỬ LÝ KẾT QUẢ: Xem chi tiết → Quay lại → Hoàn thành
// ──────────────────────────────────────────────

Future<void> _handleQuizResult(WidgetTester tester) async {
  final viewDetailsBtnUpper = find.text('XEM CHI TIẾT BÀI LÀM');
  final viewDetailsBtnLower = find.text('Xem chi tiết bài làm');

  // Xem chi tiết bài làm nếu có
  if (tester.any(viewDetailsBtnUpper)) {
    debugPrint('--- BẤM XEM CHI TIẾT BÀI LÀM ---');
    await tester.ensureVisible(viewDetailsBtnUpper);
    await tester.pump(const Duration(milliseconds: 300));
    await _viewAndReturnFromDetails(tester, viewDetailsBtnUpper);
  } else if (tester.any(viewDetailsBtnLower)) {
    debugPrint('--- BẤM XEM CHI TIẾT BÀI LÀM ---');
    await tester.ensureVisible(viewDetailsBtnLower);
    await tester.pump(const Duration(milliseconds: 300));
    await _viewAndReturnFromDetails(tester, viewDetailsBtnLower);
  }

  // Bấm Hoàn thành để thoát màn kết quả
  // Xác nhận: Màn Chi tiết bài học xuất hiện = đã thoát thành công
  final doneBtnUpper = find.text('HOÀN THÀNH');
  final doneBtnLower = find.text('Hoàn thành');

  if (tester.any(doneBtnUpper)) {
    debugPrint('--- BẤM NÚT HOÀN THÀNH ĐỂ THOÁT KẾT QUẢ ---');
    await tester.ensureVisible(doneBtnUpper);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(doneBtnUpper, warnIfMissed: false);
  } else if (tester.any(doneBtnLower)) {
    debugPrint('--- BẤM NÚT HOÀN THÀNH ĐỂ THOÁT KẾT QUẢ ---');
    await tester.ensureVisible(doneBtnLower);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(doneBtnLower, warnIfMissed: false);
  } else if (tester.any(find.byIcon(Icons.close))) {
    await tester.tap(find.byIcon(Icons.close), warnIfMissed: false);
  } else {
    await tester.tap(find.byType(BackButton).last, warnIfMissed: false);
  }

  // Xác nhận: Quay lại danh sách bài tập (BackButton xuất hiện)
  final exerciseBackButton = find.byType(BackButton);
  await waitFor(
    tester,
    exerciseBackButton,
    timeout: const Duration(seconds: 10),
    reason: 'Không quay về màn Chi tiết bài học sau khi bấm Hoàn thành',
  );
  
  // Liên tục bấm Back để trở về tận màn hình Home (nơi có thanh điều hướng dưới cùng)
  // Việc này giúp Test không bị kẹt ở các màn hình phụ khi chuyển sang luồng tiếp theo.
  debugPrint('--- QUAY VỀ MÀN HÌNH CHÍNH (HOME) ---');
  while (tester.any(find.byType(BackButton))) {
    await tester.ensureVisible(find.byType(BackButton).last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(BackButton).last, warnIfMissed: false);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
  }

  debugPrint('--- ✅ HOÀN THÀNH PHIÊN LÀM QUIZ ---');
}

/// Vào trang chi tiết bài làm rồi quay lại trang kết quả.
Future<void> _viewAndReturnFromDetails(
  WidgetTester tester,
  Finder viewDetailsBtn,
) async {
  // Tap → Xác nhận: Nút back xuất hiện = trang Chi tiết đã render
  final backArrow = find.byIcon(Icons.arrow_back_ios_new_rounded);
  await tester.tap(viewDetailsBtn, warnIfMissed: false);
  await waitForAny(
    tester,
    [backArrow, find.byType(BackButton)],
    timeout: const Duration(seconds: 10),
    reason: 'Trang Chi tiết bài làm không tải được',
  );

  // Chờ cho tất cả các Loading Indicator (của ảnh CachedNetworkImage) biến mất
  await waitForLoading(tester, timeout: const Duration(seconds: 10));

  // Thêm 1 giây dừng hình để người xem có thể nhìn thấy Chi tiết bài làm đã tải đầy đủ ảnh
  debugPrint('--- ĐANG XEM CHI TIẾT BÀI LÀM (1s) ---');
  await tester.pump(const Duration(seconds: 1));

  if (tester.any(backArrow)) {
    await tester.tap(backArrow);
    await waitForGone(tester, backArrow, timeout: const Duration(seconds: 5));
  } else {
    final backBtn = find.byType(BackButton);
    await tester.tap(backBtn);
    await waitForGone(tester, backBtn, timeout: const Duration(seconds: 5));
  }
  
  // Đợi thêm 1 chút để đảm bảo animation lùi trang hoàn tất
  await tester.pump(const Duration(milliseconds: 600));

  // Xác nhận: Đã quay lại trang kết quả = nút HOÀN THÀNH xuất hiện
  await waitFor(
    tester,
    findAnyText(['HOÀN THÀNH', 'Hoàn thành']),
    timeout: const Duration(seconds: 10),
    reason: 'Không quay lại trang kết quả sau khi xem Chi tiết bài làm',
  );
}

// ──────────────────────────────────────────────
// TỰ ĐỘNG GIẢI CÂU HỎI: Hỗ trợ 6 thể loại game
// ──────────────────────────────────────────────

/// Phát hiện loại câu hỏi hiện tại và tự động chọn đáp án.
///
/// Hỗ trợ: Trắc nghiệm, Đúng/Sai, Chọn nhiều, Điền chỗ trống,
///         Nối câu (Matching), Sắp xếp thứ tự (Ordering).
Future<void> _autoAnswerCurrentQuestion(WidgetTester tester) async {
  // 1. Trắc nghiệm 1 lựa chọn
  final mcOption = find.descendant(
    of: find.byType(GameMultipleChoiceWidget),
    matching: find.byType(GestureDetector),
  );
  if (tester.any(mcOption)) {
    await tester.ensureVisible(mcOption.first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(mcOption.first, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));
    return;
  }

  // 2. Đúng / Sai
  final tfOption = find.descendant(
    of: find.byType(GameTrueFalseWidget),
    matching: find.byType(GestureDetector),
  );
  if (tester.any(tfOption)) {
    await tester.ensureVisible(tfOption.first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(tfOption.first, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));
    return;
  }

  // 3. Chọn nhiều đáp án
  final msOption = find.descendant(
    of: find.byType(GameMultiSelectWidget),
    matching: find.byType(GestureDetector),
  );
  if (tester.any(msOption)) {
    await tester.ensureVisible(msOption.first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(msOption.first, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));
    return;
  }

  // 4. Điền chữ vào ô trống
  final fillTextField = find.descendant(
    of: find.byType(GameFillInWidget),
    matching: find.byType(TextField),
  );
  if (tester.any(fillTextField)) {
    await tester.ensureVisible(fillTextField.first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(fillTextField.first, 'E');
    await tester.pump(const Duration(milliseconds: 300));
    return;
  }

  // 5. Nối câu / Ghép cặp từ vựng (Matching)
  final matchingWidget = find.byType(GameMatchingWidget);
  if (tester.any(matchingWidget)) {
    final leftColumn = find
        .descendant(of: matchingWidget, matching: find.byType(Column))
        .first;
    final rightColumn = find
        .descendant(of: matchingWidget, matching: find.byType(Column))
        .last;

    final leftCards = find.descendant(
      of: leftColumn,
      matching: find.byType(GestureDetector),
    );
    final rightCards = find.descendant(
      of: rightColumn,
      matching: find.byType(GestureDetector),
    );

    final leftCount = tester.widgetList(leftCards).length;
    debugPrint('--- NỐI CÂU: TIẾN HÀNH GHÉP ĐÔI $leftCount CẶP TỪ VỰNG ---');

    for (int i = 0; i < leftCount; i++) {
      await tester.ensureVisible(leftCards.at(i));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(leftCards.at(i), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 200));

      await tester.ensureVisible(rightCards.at(i));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(rightCards.at(i), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
    }
    return;
  }

  // 6. Sắp xếp thứ tự câu (Ordering)
  final orderingWidget = find.byType(GameOrderingWidget);
  if (tester.any(orderingWidget)) {
    final optionsWrap = find
        .descendant(of: orderingWidget, matching: find.byType(Wrap))
        .last;
    final optionCards = find.descendant(
      of: optionsWrap,
      matching: find.byType(GestureDetector),
    );

    final optionCount = tester.widgetList(optionCards).length;
    debugPrint('--- SẮP XẾP: CHỌN LẦN LƯỢT $optionCount TỪ ---');

    for (int i = 0; i < optionCount; i++) {
      await tester.ensureVisible(optionCards.at(0));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(optionCards.at(0), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
    }
    return;
  }
}
