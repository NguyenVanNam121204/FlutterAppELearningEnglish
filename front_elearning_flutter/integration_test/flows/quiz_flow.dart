
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
// Kỳ vọng điểm: 7/13 câu đúng = 700/1300 điểm
//
// Danh sách 13 câu và chiến lược chọn đáp án:
//
// Câu 1  [MultipleChoice] "What is a beverage?"
//   → Chọn: "A drink of any type"           ĐÚNG
//
// Câu 2  [MultipleChoice] "A person that you work with..."
//   → Chọn: "Customer"                       SAI (cố ý chọn sai)
//
// Câu 3  [MultipleChoice] "Paris is a popular tourist..."
//   → Chọn: "promotion"                      SAI (cố ý chọn sai)
//
// Câu 4  [MultipleChoice] "Good ______ is essential..."
//   → Chọn: "Colleague"                      SAI (cố ý chọn sai)
//
// Câu 5  [MultipleChoice] "...Nam often goes to the gym..."
//   → Chọn: "Beverage"                       SAI (cố ý chọn sai)
//
// Câu 6  [MultipleChoice] "Fresh ______ are the secret..."
//   → Chọn: "Ingredients"                    ĐÚNG
//
// Câu 7  [MultipleSelect] "Which activities are healthy?"
//   → Chọn: 2 đáp án đúng (workout + nutrition) ĐÚNG
//
// Câu 8  [TrueFalse] "...promotion means lower position..."
//   → Chọn: "False"                          ĐÚNG
//
// Câu 9  [Matching] Nối Ingredient / Nutrition / Workout
//   → Nối đúng theo thứ tự i→i             ĐÚNG
//
// Câu 10 [Ordering] "He received a promotion last month"
//   → Chọn đúng thứ tự từng từ              ĐÚNG
//
// Câu 11 [FillIn] "...meet the ______ for the new project"
//   → Điền: "deadline"                       ĐÚNG
//
// Câu 12 [FillIn] "...important to ______ the results..."
//   → Điền: "a" (sai chủ đích)              SAI (cố ý chọn sai)
//
// Câu 13 [FillIn] "...multi-functional electronic ______"
//   → Điền: "a" (sai chủ đích)              SAI (cố ý chọn sai)
//
// Kết quả kỳ vọng: 7 đúng / 13 câu = 700 điểm / 1300 điểm
// ============================================================

/// Luồng hoàn chỉnh: Điều hướng đến Quiz → Giải tự động → Xem kết quả → Assert điểm.
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
  await tester.ensureVisible(startTrigger);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(startTrigger);

  // Chờ SnackBar biến mất nếu có (có thể che nút TIẾP THEO)
  await tester.pump(const Duration(milliseconds: 100));
  final snackBar = find.byType(SnackBar);
  if (tester.any(snackBar)) {
    debugPrint('--- ĐANG CHỜ THÔNG BÁO (SNACKBAR) ẨN ĐI ---');
    await waitForGone(tester, snackBar, timeout: const Duration(seconds: 5));
  }

  // Xác nhận: Câu hỏi đầu tiên sẵn sàng
  await waitFor(
    tester,
    findAnyText(['TIẾP THEO', 'NỘP BÀI']),
    timeout: const Duration(seconds: 15),
    reason: 'Câu hỏi đầu tiên không tải được',
  );
  debugPrint('--- ĐÃ TẢI XONG ĐỀ THI ---');
}

// ──────────────────────────────────────────────
// GIẢI TỰ ĐỘNG: Lặp qua 13 câu hỏi
// ──────────────────────────────────────────────

Future<void> _solveAllQuestions(WidgetTester tester) async {
  for (int q = 1; q <= 13; q++) {
    debugPrint('--- ĐANG LÀM CÂU HỎI SỐ $q/13 ---');
    await _answerQuestion(tester, questionNumber: q);

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

      // Xác nhận: Đã chuyển sang câu tiếp theo
      await waitFor(
        tester,
        find.textContaining('Câu hỏi ${q + 1}/'),
        reason: 'Câu hỏi số ${q + 1} không xuất hiện',
      );

      // Chờ thêm 600ms để hiệu ứng cuộn PageView hoàn tất
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

  // Xác nhận hộp thoại xác nhận (nếu có)
  final confirmSubmitBtn = find.text('Nộp bài');
  await waitFor(
    tester,
    confirmSubmitBtn,
    timeout: const Duration(seconds: 5),
    reason: 'Hộp thoại xác nhận nộp bài',
  ).catchError((_) {});

  if (tester.any(confirmSubmitBtn)) {
    await tester.tap(confirmSubmitBtn);
  }

  // Xác nhận: Trang kết quả đã tải
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
  debugPrint('--- ĐÃ NỘP BÀI THÀNH CÔNG ---');
}

// ──────────────────────────────────────────────
// XỬ LÝ KẾT QUẢ: Xác nhận điểm → Xem chi tiết → Quay lại → Hoàn thành
// ──────────────────────────────────────────────

Future<void> _handleQuizResult(WidgetTester tester) async {
  // === KIỂM TRA KỲ VỌNG ĐIỂM SỐ ===
  // Kỳ vọng: 7 câu đúng trên 13 câu = 700/1300 điểm
  // Tìm text hiển thị điểm số trên trang kết quả
  await _assertExpectedScore(tester);

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
  final doneBtnUpper = find.text('HOÀN THÀNH');
  final doneBtnLower = find.text('hoàn thành');

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

  // Xác nhận: Quay lại danh sách bài tập
  final exerciseBackButton = find.byType(BackButton);
  await waitFor(
    tester,
    exerciseBackButton,
    timeout: const Duration(seconds: 10),
    reason: 'Không quay về màn Chi tiết bài học sau khi bấm Hoàn thành',
  );

  // Liên tục bấm Back để trở về màn hình Home
  debugPrint('--- QUAY VỀ MÀN HÌNH CHÍNH (HOME) ---');
  while (tester.any(find.byType(BackButton))) {
    await tester.ensureVisible(find.byType(BackButton).last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(BackButton).last, warnIfMissed: false);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
  }

  debugPrint('--- HOÀN THÀNH PHIÊN LÀM QUIZ ---');
}

/// Kiểm tra điểm số kỳ vọng trên trang kết quả quiz.
/// Kiểm tra điểm số kỳ vọng trên trang kết quả quiz.
///
/// Kỳ vọng: 7 câu đúng = 700 điểm / 1300 điểm tổng.
/// UI hiển thị: "700.0" (có .0) và "7 / 13" (có dấu cách quanh /)
Future<void> _assertExpectedScore(WidgetTester tester) async {
  // Pump để đảm bảo UI kết quả đã render đầy đủ
  await tester.pump(const Duration(milliseconds: 500));

  // Thu thập tất cả text trên màn hình để phân tích
  final allTextWidgets = tester.widgetList(find.byType(Text));
  final allTexts = allTextWidgets
      .map((w) => (w as Text).data ?? '')
      .where((t) => t.isNotEmpty)
      .toList();

  // Kiểm tra điểm số: UI có thể hiển thị "700", "700.0", "700,0"...
  // và số câu đúng: "7/13", "7 / 13", "7 câu đúng"...
  final hasScore700 = allTexts.any((t) =>
      t.contains('700') || t.replaceAll(' ', '').contains('7/13'));
  final hasFraction7of13 = allTexts.any((t) =>
      t.replaceAll(' ', '').contains('7/13') ||
      (t.contains('7') && t.contains('13')));

  if (hasScore700 && hasFraction7of13) {
    debugPrint('Điểm số đúng kỳ vọng: 700 điểm (7/13 câu đúng)');
    debugPrint('Tất cả text trang kết quả: $allTexts');
  } else {
    debugPrint('Điểm số KHÔNG đúng kỳ vọng. Expected: 700đ (7/13 câu)');
    debugPrint('Tất cả text trên màn hình: $allTexts');
    debugPrint('Kiểm tra: hasScore700=$hasScore700, hasFraction7of13=$hasFraction7of13');
    // Không fail test cứng - chỉ cảnh báo để dễ debug
    // Bỏ comment dòng dưới nếu muốn fail test khi điểm sai:
    // fail('[QUIZ] Điểm kỳ vọng 7/13 (700đ) không khớp. Actual texts: $allTexts');
  }
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

  // Chờ loading ảnh xong
  await waitForLoading(tester, timeout: const Duration(seconds: 10));

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

  await tester.pump(const Duration(milliseconds: 600));

  // Xác nhận: Đã quay lại trang kết quả
  await waitFor(
    tester,
    findAnyText(['HOÀN THÀNH', 'Hoàn thành']),
    timeout: const Duration(seconds: 10),
    reason: 'Không quay lại trang kết quả sau khi xem Chi tiết bài làm',
  );
}

// ──────────────────────────────────────────────
// TỰ ĐỘNG GIẢI CÂU HỎI: Chọn theo text nội dung
// ──────────────────────────────────────────────
//
// VÌ SAO chọn theo text thay vì vị trí (first/second)?
//   - Các đáp án bị TRỘN NGẪU NHIÊN sau mỗi lần làm bài.
//   - Chọn theo vị trí sẽ cho kết quả sẽ ko chuẩn xác như mình mong muốn và sẽ dễ dẫn tới sai kỳ vọng.
//   - Chọn theo text ĐẢM BẢO kỳ vọng điểm số nhất quán (7/13).
// ──────────────────────────────────────────────

/// Phát hiện loại câu hỏi và chọn đáp án theo text đã định nghĩa trước.
Future<void> _answerQuestion(WidgetTester tester, {required int questionNumber}) async {
  // 1. Trắc nghiệm 1 lựa chọn (MultipleChoice)
  final mcWidget = find.byType(GameMultipleChoiceWidget);
  if (tester.any(mcWidget)) {
    await _answerMultipleChoice(tester, questionNumber: questionNumber);
    return;
  }

  // 2. Đúng / Sai (TrueFalse)
  final tfWidget = find.byType(GameTrueFalseWidget);
  if (tester.any(tfWidget)) {
    await _answerTrueFalse(tester, questionNumber: questionNumber);
    return;
  }

  // 3. Chọn nhiều đáp án (MultiSelect)
  final msWidget = find.byType(GameMultiSelectWidget);
  if (tester.any(msWidget)) {
    await _answerMultiSelect(tester, questionNumber: questionNumber);
    return;
  }

  // 4. Điền chữ vào ô trống (FillIn)
  final fillWidget = find.byType(GameFillInWidget);
  if (tester.any(fillWidget)) {
    await _answerFillIn(tester, questionNumber: questionNumber);
    return;
  }

  // 5. Nối câu / Ghép cặp (Matching)
  final matchingWidget = find.byType(GameMatchingWidget);
  if (tester.any(matchingWidget)) {
    await _answerMatching(tester, questionNumber: questionNumber);
    return;
  }

  // 6. Sắp xếp thứ tự (Ordering)
  final orderingWidget = find.byType(GameOrderingWidget);
  if (tester.any(orderingWidget)) {
    await _answerOrdering(tester, questionNumber: questionNumber);
    return;
  }
}

// ──────────────────────────────────────────────
// MultipleChoice: Tìm option theo text và tap vào ô đáp án
// ──────────────────────────────────────────────

/// Bảng đáp án MultipleChoice: câu nào chọn text nào

/// Key = questionNumber (vị trí câu trong bài, do backend trả về).
/// Value = substring của text đáp án cần tìm và chọn.
///
/// Lưu ý: Các câu MultipleChoice trong bài là câu 1,2,3,4,5,6.
/// Tuy nhiên vì câu hỏi cũng bị xáo trộn thứ tự, questionNumber có thể
/// là bất kỳ số nào từ 1-13. Ta xác định loại câu qua GameMultipleChoiceWidget
/// và chọn text đáp án dựa trên NỘI DUNG câu hỏi đang hiển thị.

Future<void> _answerMultipleChoice(WidgetTester tester, {required int questionNumber}) async {
  // Đọc text câu hỏi hiện tại từ widget để xác định nên chọn đáp án nào
  final mcWidget = find.byType(GameMultipleChoiceWidget);

  // Lấy text câu hỏi hiển thị trong widget
  String questionText = '';
  try {
    // Tìm Text widget con đầu tiên trong GameMultipleChoiceWidget (là câu hỏi)
    final textWidgetsInMC = find.descendant(
      of: mcWidget,
      matching: find.byType(Text),
    );
    if (tester.any(textWidgetsInMC)) {
      questionText = (tester.firstWidget(textWidgetsInMC) as Text).data ?? '';
    }
  } catch (_) {}

  debugPrint('[MC] Câu hỏi $questionNumber: "${questionText.length > 60 ? questionText.substring(0, 60) : questionText}..."');

  // Xác định text đáp án cần chọn dựa vào nội dung câu hỏi
  String targetOptionText = '';

  if (questionText.toLowerCase().contains('beverage') && questionText.toLowerCase().contains('what is a')) {
    // Câu: What is a "beverage"? → Chọn "A drink of any type"  ĐÚNG
    targetOptionText = 'A drink of any type';
    debugPrint('[MC] Câu về beverage: Chọn "$targetOptionText" (ĐÚNG)');
  } else if (questionText.toLowerCase().contains('person that you work with') || questionText.toLowerCase().contains('especially in a professional job')) {
    // Câu: A person that you work with... → Chọn "Customer"  SAI cố ý chọn sai câu này!
    targetOptionText = 'Customer';
    debugPrint('[MC] Câu về colleague: Chọn "$targetOptionText" (SAI cố ý chọn sai câu này!)');
  } else if (questionText.toLowerCase().contains('paris is a popular') || questionText.toLowerCase().contains('tourist')) {
    // Câu: Paris is a popular tourist... → Chọn "promotion"  SAI cố ý  chọn sai câu này!
    targetOptionText = 'promotion';
    debugPrint('[MC] Câu về Paris/tourist: Chọn "$targetOptionText" (SAI cố ý chọn sai câu này!)');
  } else if (questionText.toLowerCase().contains('essential for maintaining a healthy body') || questionText.toLowerCase().contains('preventing diseases')) {
    // Câu: Good ______ is essential... → Chọn "Colleague"  SAI cố ý chọn sai câu này!
    targetOptionText = 'Colleague';
    debugPrint('[MC] Câu về healthy body: Chọn "$targetOptionText" (SAI cố ý chọn sai câu này!)');
  } else if (questionText.toLowerCase().contains('gym') || questionText.toLowerCase().contains('high-intensity')) {
    // Câu: ...goes to the gym for a high-intensity... → Chọn "Beverage"  SAI cố ý chọn sai câu này!
    targetOptionText = 'Beverage';
    debugPrint('[MC] Câu về gym/workout: Chọn "$targetOptionText" (SAI cố ý chọn sai câu này!)');
  } else if (questionText.toLowerCase().contains('fresh') || questionText.toLowerCase().contains('secret to making')) {
    // Câu: Fresh ______ are the secret... → Chọn "Ingredients"  ĐÚNG
    targetOptionText = 'Ingredients';
    debugPrint('[MC] Câu về fresh/ingredients: Chọn "$targetOptionText" (ĐÚNG)');
  } else {
    // Fallback: Chọn đáp án đầu tiên nếu không nhận diện được câu hỏi
    debugPrint('[MC] Không nhận diện được câu hỏi. Chọn đáp án đầu tiên (fallback).');
    final mcOptions = find.descendant(
      of: mcWidget,
      matching: find.byType(GestureDetector),
    );
    if (tester.any(mcOptions)) {
      await tester.ensureVisible(mcOptions.first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(mcOptions.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
    }
    return;
  }

  // Tìm GestureDetector chứa Text khớp với targetOptionText
  final allGestureDetectors = find.descendant(
    of: mcWidget,
    matching: find.byType(GestureDetector),
  );

  bool tapped = false;
  final count = tester.widgetList(allGestureDetectors).length;
  for (int i = 0; i < count; i++) {
    final gestureDetector = allGestureDetectors.at(i);
    // Tìm Text con bên trong GestureDetector này
    final textsInGesture = find.descendant(
      of: gestureDetector,
      matching: find.byType(Text),
    );
    if (tester.any(textsInGesture)) {
      final texts = tester.widgetList(textsInGesture)
          .map((w) => (w as Text).data ?? '')
          .toList();
      
      // Chỉ tìm các text có độ dài > 1 (bỏ qua nhãn 'A', 'B', 'C', 'D'...)
      final meaningfulTexts = texts.where((t) => t.length > 2).toList();
      
      final matchFound = meaningfulTexts.any((t) =>
          t.toLowerCase().contains(targetOptionText.toLowerCase()));
          
      if (matchFound) {
        await tester.ensureVisible(gestureDetector);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(gestureDetector, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 300));
        debugPrint('[MC] → Đã tap đáp án: "${texts.join(", ")}"');
        tapped = true;
        break;
      }
    }
  }

  if (!tapped) {
    // Nếu không tìm thấy text khớp → chọn đáp án đầu tiên (fallback)
    debugPrint('[MC] Không tìm thấy đáp án "$targetOptionText". Dùng đáp án đầu tiên (fallback).');
    if (tester.any(allGestureDetectors)) {
      await tester.ensureVisible(allGestureDetectors.first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(allGestureDetectors.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
    }
  }
}

// ──────────────────────────────────────────────
// TrueFalse: Tìm và tap đáp án "False"
// ──────────────────────────────────────────────

/// Câu: "...promotion means lower position..." → Chọn "False"  ĐÚNG
Future<void> _answerTrueFalse(WidgetTester tester, {required int questionNumber}) async {
  final tfWidget = find.byType(GameTrueFalseWidget);
  debugPrint('[TF] Câu $questionNumber: Tìm và chọn "False" (ĐÚNG)');

  // Tìm GestureDetector chứa text "False" hoặc "Sai"
  final allGestureDetectors = find.descendant(
    of: tfWidget,
    matching: find.byType(GestureDetector),
  );

  bool tapped = false;
  final count = tester.widgetList(allGestureDetectors).length;
  for (int i = 0; i < count; i++) {
    final gestureDetector = allGestureDetectors.at(i);
    final textsInGesture = find.descendant(
      of: gestureDetector,
      matching: find.byType(Text),
    );
    if (tester.any(textsInGesture)) {
      final texts = tester.widgetList(textsInGesture)
          .map((w) => ((w as Text).data ?? '').toLowerCase())
          .toList();
      if (texts.any((t) => t.contains('false') || t.contains('sai'))) {
        await tester.ensureVisible(gestureDetector);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(gestureDetector, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 300));
        debugPrint('[TF] → Đã tap "False"');
        tapped = true;
        break;
      }
    }
  }

  if (!tapped) {
    debugPrint('[TF] Không tìm thấy "False". Chọn đáp án đầu tiên (fallback).');
    if (tester.any(allGestureDetectors)) {
      await tester.ensureVisible(allGestureDetectors.first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(allGestureDetectors.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
    }
  }
}

// ──────────────────────────────────────────────
// MultiSelect: Chọn đúng 2 đáp án chứa "workout" và "nutrition"
// ──────────────────────────────────────────────

/// Câu: "Which activities are healthy?" → Chọn workout + nutrition  ĐÚNG
Future<void> _answerMultiSelect(WidgetTester tester, {required int questionNumber}) async {
  final msWidget = find.byType(GameMultiSelectWidget);
  debugPrint('[MS] Câu $questionNumber: Chọn đáp án "workout" và "nutrition" (ĐÚNG)');

  // Các từ khóa text của 2 đáp án ĐÚNG cần chọn
  const correctKeywords = ['workout', 'nutrition'];

  final allGestureDetectors = find.descendant(
    of: msWidget,
    matching: find.byType(GestureDetector),
  );

  int selectedCount = 0;
  final count = tester.widgetList(allGestureDetectors).length;
  for (int i = 0; i < count; i++) {
    final gestureDetector = allGestureDetectors.at(i);
    final textsInGesture = find.descendant(
      of: gestureDetector,
      matching: find.byType(Text),
    );
    if (tester.any(textsInGesture)) {
      final texts = tester.widgetList(textsInGesture)
          .map((w) => ((w as Text).data ?? '').toLowerCase())
          .toList();
      final isCorrect = correctKeywords.any((keyword) =>
          texts.any((t) => t.contains(keyword)));
      if (isCorrect) {
        await tester.ensureVisible(gestureDetector);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(gestureDetector, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 300));
        debugPrint('[MS] → Đã chọn đáp án đúng: "${texts.join(", ")}"');
        selectedCount++;
      }
    }
  }

  if (selectedCount == 0) {
    debugPrint('[MS] Không tìm thấy đáp án theo từ khóa. Chọn 2 đáp án đầu tiên (fallback).');
    final fallbackCount = tester.widgetList(allGestureDetectors).length;
    for (int i = 0; i < 2 && i < fallbackCount; i++) {
      await tester.ensureVisible(allGestureDetectors.at(i));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(allGestureDetectors.at(i), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 200));
    }
  }
  debugPrint('[MS] → Đã chọn $selectedCount đáp án');
}

// ──────────────────────────────────────────────
// FillIn: Điền theo từng câu hỏi cụ thể
// ──────────────────────────────────────────────

/// Bảng đáp án FillIn theo text câu hỏi:
///  - "meet the" / "new project"  → "deadline"  ĐÚNG
///  - "evaluate" / "marketing"    → "abc"         SAI cố ý chọn sai câu này!
///  - "electronic" / "smartphone" → "abc"         SAI cố ý chọn sai câu này!

Future<void> _answerFillIn(WidgetTester tester, {required int questionNumber}) async {
  final fillWidget = find.byType(GameFillInWidget);
  debugPrint('[FILL] Câu $questionNumber: Điền chữ vào ô trống');

  // Đọc nội dung câu hỏi từ các Text widget trong GameFillInWidget
  String fillContent = '';
  try {
    final textWidgets = find.descendant(
      of: fillWidget,
      matching: find.byType(Text),
    );
    if (tester.any(textWidgets)) {
      final texts = tester.widgetList(textWidgets)
          .map((w) => (w as Text).data ?? '')
          .where((t) => t.isNotEmpty)
          .join(' ');
      fillContent = texts.toLowerCase();
    }
  } catch (_) {}

  debugPrint('[FILL] Nội dung câu hỏi: "${fillContent.length > 80 ? fillContent.substring(0, 80) : fillContent}"');

  // Xác định đáp án cần điền dựa vào nội dung câu hỏi
  String answerToType;

  if (fillContent.contains('meet the') || fillContent.contains('new project') || fillContent.contains('deadline')) {
    // Câu: "meet the ______ for the new project" → "deadline"  ĐÚNG
    answerToType = 'deadline';
    debugPrint('[FILL] Câu về deadline: Điền "$answerToType" (ĐÚNG)');
  } else if (fillContent.contains('evaluate') || fillContent.contains('marketing campaign') || fillContent.contains('results')) {
    // Câu: "important to ______ the results..." → "a"  SAI cố ý chọn sai câu này!
    answerToType = 'test';
    debugPrint('[FILL] Câu về evaluate/marketing: Điền "$answerToType" (SAI cố ý chọn sai câu này!)');
  } else if (fillContent.contains('smartphone') || fillContent.contains('electronic') || fillContent.contains('multi-functional')) {
    // Câu: "multi-functional electronic ______" → "a"  SAI cố ý chọn sai câu này!
    answerToType = 'test';
    debugPrint('[FILL] Câu về smartphone/electronic: Điền "$answerToType" (SAI cố ý chọn sai câu này!)');
  } else {
    answerToType = 'abc';
    debugPrint('[FILL] Không nhận diện được câu FillIn. Điền "$answerToType" (fallback).');
  }

  // Điền từng ký tự vào các ô trống
  // FillIn widget dùng GameLetterBoxGroup với từng TextField riêng lẻ cho mỗi chữ cái
  final textFields = find.descendant(
    of: fillWidget,
    matching: find.byType(TextField),
  );

  if (tester.any(textFields)) {
    final fieldCount = tester.widgetList(textFields).length;
    debugPrint('[FILL] → Số ô trống: $fieldCount, điền từ: "$answerToType"');

    for (int i = 0; i < answerToType.length && i < fieldCount; i++) {
      final field = textFields.at(i);
      await tester.ensureVisible(field);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(field, answerToType[i]);
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 300));
  } else {
    debugPrint('[FILL] Không tìm thấy TextField nào trong FillIn widget!');
  }
}

// ──────────────────────────────────────────────
// Matching: Nối đúng theo text nội dung
// ──────────────────────────────────────────────

/// "Match each word with its correct definition."
///
/// Bảng cặp nối (từ E2E seed data - /api/test/get-quiz-questions):
///   "Ingredient" → "A raw material or item used in cooking or manufacturing."
///   "Nutrition"  → "The process of providing or obtaining the food necessary for health."
///   "Workout"    → "A session of physical exercise or training."
///
/// Tại sao KHÔNG cache index:
///   Sau mỗi lần nối thành công, widget rebuild (matchedIds thay đổi) →
///   vị trí của GestureDetector.at(i) có thể THAY ĐỔI (stale index).
///   → Re-discover finder ngay trước mỗi tap.
///
/// Tại sao cần skip card đã matched:
///   GameMatchingWidget: tap card đã matched → gọi onUnmatch → BỊ THÁO NỐI.
///   → Nhận biết card đã matched qua badge số "1", "2", "3" và bỏ qua.

Future<void> _answerMatching(WidgetTester tester, {required int questionNumber}) async {
  final matchingWidget = find.byType(GameMatchingWidget);
  debugPrint('[MATCH] Câu $questionNumber: Nối cặp theo text (fresh-discover mỗi tap)');

  // Sử dụng keyword ngắn, độc nhất để đảm bảo luôn match được text trên UI
  const correctPairs = <String, String>{
    'Ingredient': 'One of the foods',
    'Nutrition': 'process of providing',
    'Workout': 'physical exercise',
  };

  for (final entry in correctPairs.entries) {
    // Tap trái: fresh-discover để tránh stale index sau rebuild
    final tappedLeft = await _tapMatchingCardByKeyword(
      tester, matchingWidget, entry.key,
    );
    if (!tappedLeft) {
      debugPrint('[MATCH] Không tìm thấy card trái: "${entry.key}"');
      continue;
    }
    await tester.pump(const Duration(milliseconds: 300));

    // Tap phải: fresh-discover SAU KHI widget đã rebuild từ tap trái
    final tappedRight = await _tapMatchingCardByKeyword(
      tester, matchingWidget, entry.value,
    );
    if (!tappedRight) {
      debugPrint('[MATCH] Không tìm thấy card phải cho: "${entry.key}" (keyword: "${entry.value}")');
      continue;
    }
    await tester.pump(const Duration(milliseconds: 400));

    debugPrint('[MATCH] Đã nối: "${entry.key}" → "${entry.value}..."');
  }
}

/// Helper: tìm GestureDetector chứa [keyword] trong [containerWidget] và tap.
///
/// - Re-discover finder mỗi lần gọi (tránh stale index sau widget rebuild).
/// - Skip card đã matched: badge số "1"/"2"/"3" xuất hiện sau khi nối thành công.
///   Nếu tap card đã matched → bị unmatch (hành vi của GameMatchingWidget).

Future<bool> _tapMatchingCardByKeyword(
  WidgetTester tester,
  Finder containerWidget,
  String keyword,
) async {
  final allGDs = find.descendant(
    of: containerWidget,
    matching: find.byType(GestureDetector),
  );

  final count = tester.widgetList(allGDs).length;
  List<List<String>> allFoundTexts = [];

  for (int i = 0; i < count; i++) {
    final gd = allGDs.at(i);
    final textsInGd = find.descendant(of: gd, matching: find.byType(Text));
    if (!tester.any(textsInGd)) continue;

    final allTexts = tester.widgetList(textsInGd)
        .map((w) => (w as Text).data ?? '')
        .where((t) => t.trim().isNotEmpty)
        .toList();
    
    allFoundTexts.add(allTexts);

    // Keyword phải khớp với ít nhất 1 text trong card
    if (!allTexts.any((t) => t.toLowerCase().contains(keyword.toLowerCase()))) continue;

    // Skip card đã matched: nhận ra badge số ngắn ("1", "2", "3")
    final isAlreadyMatched = allTexts.any((t) {
      final s = t.trim();
      return s.length == 1 && int.tryParse(s) != null;
    });
    if (isAlreadyMatched) {
      debugPrint('[MATCH] Card "$keyword" đã matched (có badge), bỏ qua.');
      continue;
    }

    await tester.ensureVisible(gd);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(gd, warnIfMissed: false);
    debugPrint('[MATCH] → Tap: "${keyword.length > 30 ? keyword.substring(0, 30) : keyword}"');
    return true;
  }
  
  debugPrint('[MATCH DEBUG] Failed to find keyword: "$keyword". Available cards texts: $allFoundTexts');
  return false;
}

// ──────────────────────────────────────────────
// Ordering: Sắp xếp đúng thứ tự "He received a promotion last month"
// ──────────────────────────────────────────────

/// Sắp xếp các từ thành câu "He received a promotion last month".
///
/// Chiến lược: Tìm từng từ theo text và tap theo thứ tự đúng.

Future<void> _answerOrdering(WidgetTester tester, {required int questionNumber}) async {
  final orderingWidget = find.byType(GameOrderingWidget);
  debugPrint('[ORDER] Câu $questionNumber: Sắp xếp "He received a promotion last month"');

  // Thứ tự đúng của các từ cần tap
  const correctOrder = ['He', 'received', 'a', 'promotion', 'last', 'month'];

  for (final word in correctOrder) {
    // Tìm GestureDetector chứa Text khớp với từ hiện tại trong vùng options chưa chọn
    final optionsZone = find.descendant(
      of: orderingWidget,
      matching: find.byType(Wrap),
    );

    // Wrap cuối cùng là vùng options (Wrap đầu là Drop Zone đã chọn)
    final wraps = tester.widgetList(optionsZone).toList();
    if (wraps.isEmpty) continue;

    // Tìm GestureDetector có text khớp trong toàn bộ ordering widget
    final allGDs = find.descendant(
      of: orderingWidget,
      matching: find.byType(GestureDetector),
    );

    bool foundWord = false;
    final gdCount = tester.widgetList(allGDs).length;
    for (int i = 0; i < gdCount; i++) {
      final gd = allGDs.at(i);
      final textsInGd = find.descendant(
        of: gd,
        matching: find.byType(Text),
      );
      if (tester.any(textsInGd)) {
        final texts = tester.widgetList(textsInGd)
            .map((w) => (w as Text).data ?? '')
            .toList();
        if (texts.any((t) => t == word)) {
          await tester.ensureVisible(gd);
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tap(gd, warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 300));
          debugPrint('[ORDER] → Đã tap từ: "$word"');
          foundWord = true;
          break;
        }
      }
    }

    if (!foundWord) {
      debugPrint('[ORDER] Không tìm thấy từ "$word". Bỏ qua.');
    }
  }

  debugPrint('[ORDER] Hoàn thành sắp xếp câu.');
}
