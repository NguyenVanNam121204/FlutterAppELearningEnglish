import '../helpers/test_helpers.dart';
import 'package:front_elearning_flutter/views/widgets/course/my_course_list_item.dart';
import 'package:front_elearning_flutter/views/widgets/lesson/lesson_list_item_card.dart';
import 'package:front_elearning_flutter/views/widgets/flashcard/flashcard_audio_button.dart';

// ============================================================
// BƯỚC 2 + 3: LUỒNG CHỌN KHÓA HỌC & HỌC FLASHCARD
// ============================================================
// State-based approach:
//   Sau khi tap tab Khóa học: chờ loading biến mất
//   Sau khi tap khóa học: chờ nút "VÀO HỌC NGAY" xuất hiện
//   Sau khi tap bài học: chờ mục "Flashcard" xuất hiện
//   Trong vòng lặp học thẻ: chờ thẻ tiếp theo render (key xuất hiện)
//   Kết thúc: chờ màn hình trước (Chi tiết bài học) quay lại
// ============================================================

/// Điều hướng đến khóa học, chọn bài học và học toàn bộ Flashcard.
///
/// Kết thúc khi: Màn hình Chi tiết bài học (có mục "Bài test") đã quay lại.
Future<void> runFlashcardFlow(WidgetTester tester) async {
  logFlowStart('Flashcard Flow');
  await _navigateToCourse(tester);
  await _navigateToLesson(tester);
  await _learnAllFlashcards(tester);
  logFlowPass('Flashcard Flow');
}

// ──────────────────────────────────────────────
// NAVIGATION: Home → Tab Khóa học → Khóa đầu tiên
// ──────────────────────────────────────────────

Future<void> _navigateToCourse(WidgetTester tester) async {
  final coursesTab = find.byTooltip('Khóa học');
  await tester.tap(coursesTab);

  // Xác nhận: Chờ loading biến mất → danh sách đã render
  await waitForLoading(tester);

  // Xác nhận: Thẻ khóa học xuất hiện trong widget MyCourseListItem
  final firstCourseCard = find.descendant(
    of: find.byType(MyCourseListItem),
    matching: find.text('Tiếng anh cơ bản 1'),
  );
  await waitFor(
    tester,
    firstCourseCard,
    timeout: const Duration(seconds: 15),
    reason: '"Tiếng anh cơ bản 1" không xuất hiện trong danh sách khóa học',
  );

  // Tap → Xác nhận: Nút "VÀO HỌC NGAY" xuất hiện = trang Chi tiết đã render
  await tapAndWaitFor(
    tester,
    firstCourseCard,
    find.textContaining('VÀO HỌC NGAY'),
    timeout: const Duration(seconds: 12),
    reason: 'Nút "VÀO HỌC NGAY" không xuất hiện sau khi vào Chi tiết khóa học',
  );
  debugPrint('--- ĐÃ VÀO CHI TIẾT KHÓA HỌC ---');

  // Tap → Xác nhận: LessonListItemCard xuất hiện = Danh sách bài học đã render
  await tapAndWaitFor(
    tester,
    find.textContaining('VÀO HỌC NGAY'),
    find.byType(LessonListItemCard),
    timeout: const Duration(seconds: 15),
    reason: 'Danh sách bài học không xuất hiện sau khi nhấn "VÀO HỌC NGAY"',
  );
  debugPrint('--- ĐÃ VÀO DANH SÁCH BÀI HỌC ---');
}

// ──────────────────────────────────────────────
// NAVIGATION: Danh sách bài học → Bài 1 → Flashcard
// ──────────────────────────────────────────────

Future<void> _navigateToLesson(WidgetTester tester) async {
  final lesson1Card = find.descendant(
    of: find.byType(LessonListItemCard),
    matching: find.text('Bài 1'),
  );
  await waitFor(
    tester,
    lesson1Card,
    timeout: const Duration(seconds: 15),
    reason: '"Bài 1" không xuất hiện trong danh sách bài học',
  );

  // Tap → Xác nhận: Mục "Flashcard" xuất hiện = Chi tiết bài học đã render
  await tapAndWaitFor(
    tester,
    lesson1Card,
    find.text('Flashcard'),
    timeout: const Duration(seconds: 12),
    reason: 'Mục "Flashcard" không xuất hiện trong Chi tiết bài học',
  );
  debugPrint('--- ĐÃ VÀO CHI TIẾT BÀI HỌC ---');

  // Tap → Xác nhận: Nút "Tiếp theo" xuất hiện = thẻ Flashcard đầu tiên đã sẵn sàng
  await tapAndWaitFor(
    tester,
    find.text('Flashcard'),
    find.text('Tiếp theo'),
    timeout: const Duration(seconds: 12),
    reason: 'Màn hình Flashcard không tải được (không thấy nút "Tiếp theo")',
  );
  debugPrint('--- ĐÃ VÀO MÀN HÌNH FLASHCARD ---');
}

// ──────────────────────────────────────────────
// HỌC FLASHCARD: Lặp qua từng thẻ theo trạng thái
// ──────────────────────────────────────────────

Future<void> _learnAllFlashcards(WidgetTester tester) async {
  final nextBtn = find.text('Tiếp theo');
  final finishBtn = find.text('Hoàn thành');

  int cardIndex = 0;

  while (!tester.any(finishBtn)) {
    if (cardIndex > 50) {
      debugPrint('--- CẢNH BÁO: Đã học 50 thẻ, thoát vòng lặp an toàn ---');
      break;
    }

    debugPrint('--- ĐANG HỌC THẺ FLASHCARD SỐ $cardIndex ---');

    // A. Tìm chính xác thẻ hiện tại (để không tap nhầm thẻ cũ đang bay ra)
    final cardFinder = find.byKey(ValueKey('card-$cardIndex'));
    await tester.pumpAndSettle(); // Đợi card mới vào hẳn vị trí

    // B. Tap loa phát âm của thẻ HIỆN TẠI
    final speakerIcon = find.descendant(
      of: cardFinder,
      matching: find.byType(FlashcardAudioButton),
    );

    if (tester.any(speakerIcon)) {
      await tester.tap(speakerIcon.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
    }

    // C. Lật mặt sau → xem nghĩa
    if (tester.any(cardFinder)) {
      debugPrint('--- LẬT MẶT SAU THẺ $cardIndex ---');
      await tester.tap(cardFinder);
      await tester.pump(const Duration(milliseconds: 400));

      // C. Chờ âm thanh đọc xong (dựa vào trạng thái giao diện thay vì delay cứng)
      final playingAudioFinder = find.byTooltip('Dừng phát âm');

      try {
        // Máy ảo có độ trễ tải âm thanh (buffered). Ta cho nó tối đa 3 giây để BẮT ĐẦU phát.
        // Khi loa thực sự bắt đầu phát, tooltip sẽ đổi thành 'Dừng phát âm'.
        await waitFor(
          tester,
          playingAudioFinder,
          timeout: const Duration(seconds: 3),
        );

        // Sau khi loa đã phát, ta chờ cho đến khi nó ĐỌC XONG (tooltip biến mất)
        await waitForGone(
          tester,
          playingAudioFinder,
          timeout: const Duration(seconds: 10),
          reason: 'Âm thanh phát quá lâu',
        );
      } catch (e) {
        // Nếu loa không thể khởi động (có thể do lỗi mạng tải file audio), ta bỏ qua để test không bị đứng
        debugPrint(
          '--- Loa không phản hồi hoặc không có file audio, bỏ qua chờ âm thanh ---',
        );
      }

      await tester.tap(cardFinder); // Lật lại mặt trước
      await tester.pump(const Duration(milliseconds: 300));
    }

    // C. Pump để cập nhật trạng thái nút
    await tester.pump();

    if (tester.any(finishBtn)) {
      // Đã đến thẻ cuối → thoát vòng lặp để bấm Hoàn thành
      break;
    } else if (tester.any(nextBtn)) {
      await tester.tap(nextBtn);
      // Xác nhận: Thẻ tiếp theo đã render (key mới xuất hiện)
      final nextCardFinder = find.byKey(ValueKey('card-${cardIndex + 1}'));
      await waitFor(
        tester,
        nextCardFinder,
        timeout: const Duration(seconds: 8),
        reason: 'Thẻ flashcard số ${cardIndex + 1} không xuất hiện',
      );
    } else {
      // Không có nút nào → chờ thêm 1 frame
      await tester.pump(const Duration(milliseconds: 300));
    }

    cardIndex++;
  }

  // Bấm "Hoàn thành" → Xác nhận: Màn hình Chi tiết bài học quay lại
  await tester.pump();
  if (tester.any(finishBtn)) {
    debugPrint('--- BẤM HOÀN THÀNH SAU KHI HỌC HẾT $cardIndex THẺ ---');
    await tapAndWaitFor(
      tester,
      finishBtn,
      find.text('Bài test'),
      timeout: const Duration(seconds: 10),
      reason:
          'Không quay lại màn Chi tiết bài học sau khi bấm Hoàn thành Flashcard',
    );
  } else {
    await _fallbackCloseFlashcard(tester);
  }

  debugPrint('--- HOÀN THÀNH PHIÊN HỌC FLASHCARD ---');
}

/// Đóng màn hình Flashcard theo phương án dự phòng nếu không tìm thấy nút "Hoàn thành".
Future<void> _fallbackCloseFlashcard(WidgetTester tester) async {
  debugPrint('--- KHÔNG TÌM THẤY NÚT HOÀN THÀNH → ĐÓNG BẰNG NÚT X ---');

  final closeRounded = find.byIcon(Icons.close_rounded);
  final closeRegular = find.byIcon(Icons.close);

  if (tester.any(closeRounded)) {
    await tester.tap(closeRounded);
  } else if (tester.any(closeRegular)) {
    await tester.tap(closeRegular);
  } else {
    await tester.tap(find.byType(BackButton));
  }

  // Xác nhận: Loading biến mất = đã quay lại thành công
  await waitForLoading(tester);
}
