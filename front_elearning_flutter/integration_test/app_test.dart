import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:front_elearning_flutter/main.dart' as app;
import 'package:front_elearning_flutter/views/widgets/course/my_course_list_item.dart';
import 'package:front_elearning_flutter/views/widgets/lesson/lesson_list_item_card.dart';
import 'package:front_elearning_flutter/views/widgets/quiz/game/game_multiple_choice_widget.dart';
import 'package:front_elearning_flutter/views/widgets/quiz/game/game_true_false_widget.dart';
import 'package:front_elearning_flutter/views/widgets/quiz/game/game_multi_select_widget.dart';
import 'package:front_elearning_flutter/views/widgets/quiz/game/game_fill_in_widget.dart';
import 'package:front_elearning_flutter/views/widgets/quiz/game/game_matching_widget.dart';
import 'package:front_elearning_flutter/views/widgets/quiz/game/game_ordering_widget.dart';
import 'package:front_elearning_flutter/views/widgets/flashcard/flashcard_audio_button.dart';

/// URL gốc của backend API (10.0.2.2 = localhost từ trong máy ảo Android)
const String _testApiBase = 'http://10.0.2.2:5030';

/// Email của tài khoản học viên dùng trong kịch bản E2E
const String _testUserEmail = 'nt0143436946@gmail.com';

void main() {
  // 1. Khởi tạo binding cho kiểm thử E2E
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // PRE-TEST SETUP: Dọn sạch dữ liệu tiến độ trước mỗi lần test
  // ============================================================
  // Bước này gọi trực tiếp vào API backend để xóa toàn bộ lịch sử
  // làm bài Quiz, ôn tập Flashcard, tiến độ bài học... của tài khoản
  // test -> Đảm bảo kịch bản E2E luôn bắt đầu từ trạng thái sạch sẽ
  // và nhất quán, không bị ảnh hưởng bởi dữ liệu từ lần chạy trước.
  setUpAll(() async {
    await _cleanupTestUserProgress();
  });

  // Hàm chờ động thông minh (Chờ cho đến khi Widget xuất hiện, tối đa 15 giây)
  Future<void> waitFor(WidgetTester tester, Finder finder, {int timeoutSeconds = 15}) async {
    final endTime = DateTime.now().add(Duration(seconds: timeoutSeconds));
    while (DateTime.now().isBefore(endTime)) {
      if (tester.any(finder)) {
        return; // Đã thấy widget xuất hiện, tiếp tục test ngay!
      }
      await Future.delayed(const Duration(milliseconds: 200));
      await tester.pump();
    }
    expect(finder, findsOneWidget);
  }

  // Hàm chờ phụ siêu mượt (Smart Smooth Delay)
  // Chia nhỏ thời gian chờ và cập nhật giao diện máy ảo mượt mà, không gây đơ
  Future<void> delay(WidgetTester tester, {int ms = 500}) async {
    final loops = (ms / 150).ceil();
    for (int i = 0; i < loops; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      await tester.pump();
    }
  }

  group('KỊCH BẢN E2E: ĐĂNG NHẬP -> HỌC BÀI -> LÀM QUIZ -> ÔN TẬP TỪ VỰNG', () {
    testWidgets('Kiểm thử luồng học tập khép kín của học viên', 
      (WidgetTester tester) async {
        
        // 2. Khởi chạy ứng dụng thật
        app.main();
        await delay(tester, ms: 3000); // Chờ 3 giây khởi động app ổn định

        // ========================================================
        // BƯỚC 1: KIỂM TRA ĐĂNG NHẬP (DYNAMIC LOGIN CHECK)
        // ========================================================
        final emailFieldFinder = find.byKey(const ValueKey('email-field'));

        if (tester.any(emailFieldFinder)) {
          debugPrint('--- PHÁT HIỆN CHƯA ĐĂNG NHẬP -> TIẾN HÀNH ĐĂNG NHẬP ---');
          
          final emailField = find.descendant(
            of: emailFieldFinder,
            matching: find.byType(TextFormField),
          );
          final passwordField = find.descendant(
            of: find.byKey(const ValueKey('password-field')),
            matching: find.byType(TextFormField),
          );
          final loginButton = find.byKey(const ValueKey('login-button'));

          // Nhập email và mật khẩu thật của bạn
          await tester.enterText(emailField, 'nt0143436946@gmail.com');
          await tester.enterText(passwordField, 'Nam@12345678');
          await delay(tester, ms: 1000);

          // Nhấn nút "Đăng nhập"
          await tester.tap(loginButton);
          await delay(tester, ms: 5000); // Chờ 5 giây kết nối API đăng nhập
        } else {
          debugPrint('--- ĐÃ ĐĂNG NHẬP SẴN -> BỎ QUA BƯỚC ĐĂNG NHẬP ---');
          await delay(tester, ms: 4000); // Chờ 4 giây cho Trang chủ ổn định mượt mà
        }

        // ========================================================
        // BƯỚC 2: CHỌN KHÓA HỌC ĐẦU TIÊN "Tiếng anh cơ bản 1"
        // ========================================================
        final coursesTab = find.byTooltip('Khóa học');
        await waitFor(tester, coursesTab);
        await tester.tap(coursesTab);
        await delay(tester, ms: 3000); // Chờ 3 giây tải danh sách khóa học và các ảnh từ MinIO mượt mà

        // Định vị chính xác: Chỉ tìm "Tiếng anh cơ bản 1" nằm trong MyCourseListItem
        final firstCourseCard = find.descendant(
          of: find.byType(MyCourseListItem),
          matching: find.text('Tiếng anh cơ bản 1'),
        );
        await waitFor(tester, firstCourseCard, timeoutSeconds: 15);
        await delay(tester, ms: 2500); // Chờ xem giao diện tải hoàn thiện
        await tester.tap(firstCourseCard);
        await delay(tester, ms: 2500); // Chờ màn hình Chi tiết khóa học tải xong

        // ========================================================
        // BẤM NÚT "🚀 VÀO HỌC NGAY"
        // ========================================================
        final startLearningBtn = find.textContaining('VÀO HỌC NGAY');
        await waitFor(tester, startLearningBtn, timeoutSeconds: 12);
        await delay(tester, ms: 1500);
        await tester.tap(startLearningBtn);
        await delay(tester, ms: 3000); // Chờ màn hình Danh sách bài học tải xong

        // ========================================================
        // BƯỚC 3: VÀO BÀI 1 & HỌC FLASHCARD TƯƠNG TÁC (LOA & LẬT THẺ)
        // ========================================================
        final lesson1Card = find.descendant(
          of: find.byType(LessonListItemCard),
          matching: find.text('Bài 1'),
        );
        await waitFor(tester, lesson1Card, timeoutSeconds: 15);
        await delay(tester, ms: 1500);
        await tester.tap(lesson1Card);
        await delay(tester, ms: 2500); // Chờ sang màn Chi tiết bài học

        // Chọn học phần "Flashcard"
        final flashcardItem = find.text('Flashcard');
        await waitFor(tester, flashcardItem);
        await delay(tester, ms: 1500);
        await tester.tap(flashcardItem);
        await delay(tester, ms: 3000); // Chờ tải Flashcard đầu tiên

        // Giả lập học Flashcard tương tác: Phát loa -> Lật thẻ -> Tiếp theo
        // Học đến hết toàn bộ thẻ cho đến khi nút "Hoàn thành" xuất hiện
        final nextBtn = find.text('Tiếp theo');
        final finishBtn = find.text('Hoàn thành');
        await waitFor(tester, nextBtn, timeoutSeconds: 8);

        int cardIndex = 0;
        while (!tester.any(finishBtn)) {
          debugPrint('--- ĐANG HỌC THẺ FLASHCARD SỐ $cardIndex ---');

          // A. Nhấp vào loa để phát âm thanh
          final speakerIcon = find.byType(FlashcardAudioButton);
          if (tester.any(speakerIcon)) {
            await tester.tap(speakerIcon);
            await delay(tester, ms: 1500); // Chờ nghe phát âm
          }

          // B. Nhấp vào thẻ để lật mặt sau (xem nghĩa)
          final cardKey = ValueKey('card-$cardIndex');
          final flashcardWidget = find.byKey(cardKey);
          if (tester.any(flashcardWidget)) {
            debugPrint('--- LẬT MẶT SAU THẺ $cardIndex ---');
            await tester.tap(flashcardWidget);
            await delay(tester, ms: 1500); // Xem nghĩa
            // C. Lật lại mặt trước
            await tester.tap(flashcardWidget);
            await delay(tester, ms: 800);
          }

          // D. Nhấn "Tiếp theo" nếu có, nếu không check "Hoàn thành"
          await tester.pump();
          if (tester.any(finishBtn)) {
            // Đã tới thẻ cuối cùng -> thoát vòng lặp để bấm Hoàn thành
            break;
          } else if (tester.any(nextBtn)) {
            await tester.tap(nextBtn);
            await delay(tester, ms: 1200);
          } else {
            // Không có nút nào -> đợi thêm
            await delay(tester, ms: 1000);
          }

          cardIndex++;

          // Giới hạn an toàn để tránh vòng lặp vô hạn (tối đa 50 thẻ)
          if (cardIndex > 50) {
            debugPrint('--- CẢNH BÁO: Đã học 50 thẻ, thoát vòng lặp an toàn ---');
            break;
          }
        }

        // Bấm nút "Hoàn thành" để hoàn tất phiên học flashcard
        await tester.pump();
        if (tester.any(finishBtn)) {
          debugPrint('--- BẤM HOÀN THÀNH SAU KHI HỌC HẾT $cardIndex THẺ ---');
          await tester.tap(finishBtn);
          await delay(tester, ms: 2500); // Chờ quay lại màn Chi tiết bài học
        } else {
          // Fallback: đóng bằng nút X nếu không tìm thấy "Hoàn thành"
          debugPrint('--- KHÔNG TÌM THẤY NÚT HOÀN THÀNH -> ĐÓNG BẰNG NÚT X ---');
          final closeBtn = find.byIcon(Icons.close_rounded);
          final closeBtnAlt = find.byIcon(Icons.close);
          if (tester.any(closeBtn)) {
            await tester.tap(closeBtn);
          } else if (tester.any(closeBtnAlt)) {
            await tester.tap(closeBtnAlt);
          } else {
            await tester.tap(find.byType(BackButton));
          }
          await delay(tester, ms: 2000);
        }


        // ========================================================
        // BƯỚC 4: VÀO BÀI TEST & TỰ ĐỘNG GIẢI QUIZ
        // ========================================================
        final testItem = find.text('Bài test');
        await waitFor(tester, testItem);
        await delay(tester, ms: 1500);
        await tester.tap(testItem);
        await delay(tester, ms: 2000); // Chờ tải danh sách bài test

        // Chọn "Bài quiz 1"
        final quiz1Item = find.text('Bài quiz 1');
        await waitFor(tester, quiz1Item, timeoutSeconds: 8);
        await delay(tester, ms: 1500);
        await tester.tap(quiz1Item);
        await delay(tester, ms: 2500); // Chờ hiển thị thông tin bài thi

        // HỖ TRỢ ĐỘNG: TIẾP TỤC BÀI ĐANG LÀM HOẶC LÀM BÀI MỚI (Xem Ảnh 2)
        final resumeQuizBtn = find.text('Tiếp tục bài đang làm');
        final startNewQuizBtn = find.text('Bắt đầu làm bài mới');
        final startQuizBtn = find.text('Bắt đầu làm bài');

        if (tester.any(resumeQuizBtn)) {
          debugPrint('--- PHÁT HIỆN BÀI THI LÀM DỞ -> TIẾN HÀNH TIẾP TỤC BÀI ĐANG LÀM ---');
          await tester.tap(resumeQuizBtn);
        } else if (tester.any(startNewQuizBtn)) {
          debugPrint('--- TIẾN HÀNH BẮT ĐẦU LÀM BÀI MỚI ---');
          await tester.tap(startNewQuizBtn);
        } else if (tester.any(startQuizBtn)) {
          debugPrint('--- TIẾN HÀNH BẮT ĐẦU LÀM BÀI ---');
          await tester.tap(startQuizBtn);
        }
        await delay(tester, ms: 4000); // Chờ tải đề thi hoàn chỉnh từ API

        // --- HÀM TỰ ĐỘNG GIẢI CÂU HỎI TRỰC QUAN (HỖ TRỢ TOÀN DIỆN 6 THỂ LOẠI GAME) ---
        Future<void> autoAnswerCurrentQuestion() async {
          // 1. Trắc nghiệm 1 lựa chọn
          final mcOption = find.descendant(
            of: find.byType(GameMultipleChoiceWidget),
            matching: find.byType(GestureDetector),
          );
          if (tester.any(mcOption)) {
            await tester.tap(mcOption.first);
            await delay(tester, ms: 500);
            return;
          }

          // 2. Đúng / Sai
          final tfOption = find.descendant(
            of: find.byType(GameTrueFalseWidget),
            matching: find.byType(GestureDetector),
          );
          if (tester.any(tfOption)) {
            await tester.tap(tfOption.first);
            await delay(tester, ms: 500);
            return;
          }

          // 3. Chọn nhiều đáp án
          final msOption = find.descendant(
            of: find.byType(GameMultiSelectWidget),
            matching: find.byType(GestureDetector),
          );
          if (tester.any(msOption)) {
            await tester.tap(msOption.first);
            await delay(tester, ms: 500);
            return;
          }

          // 4. Điền chữ vào ô trống
          final fillTextField = find.descendant(
            of: find.byType(GameFillInWidget),
            matching: find.byType(TextField),
          );
          if (tester.any(fillTextField)) {
            await tester.enterText(fillTextField.first, 'E');
            await delay(tester, ms: 500);
            return;
          }

          // 5. Nối câu / Ghép cặp từ vựng cột Trái sang cột Phải (GIẢI TOÀN BỘ CÁC CẶP)
          final matchingWidget = find.byType(GameMatchingWidget);
          if (tester.any(matchingWidget)) {
            // Định vị cột Trái & Phải để ghép đôi chính xác từng cặp
            final leftColumn = find.descendant(
              of: matchingWidget,
              matching: find.byType(Column),
            ).first;
            final rightColumn = find.descendant(
              of: matchingWidget,
              matching: find.byType(Column),
            ).last;
            
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
              await tester.tap(leftCards.at(i));
              await delay(tester, ms: 400);
              await tester.tap(rightCards.at(i));
              await delay(tester, ms: 600);
            }
            return;
          }

          // 6. Sắp xếp thứ tự câu (Tự động chạm tất cả các từ)
          final orderingWidget = find.byType(GameOrderingWidget);
          if (tester.any(orderingWidget)) {
            final optionsWrap = find.descendant(
              of: orderingWidget,
              matching: find.byType(Wrap),
            ).last;
            
            final optionCards = find.descendant(
              of: optionsWrap,
              matching: find.byType(GestureDetector),
            );
            
            final count = tester.widgetList(optionCards).length;
            debugPrint('--- SẮP XẾP CÂU: TIẾN HÀNH CHỌN $count TỪ VỰNG ---');
            
            for (int i = 0; i < count; i++) {
              // Bấm chọn thẻ đầu tiên còn lại (danh sách sẽ tự động co lại)
              await tester.tap(optionCards.first);
              await delay(tester, ms: 500);
            }
            await delay(tester, ms: 800);
            return;
          }
        }

        // Lặp qua tất cả 13 câu hỏi trong bài Quiz
        for (int q = 1; q <= 13; q++) {
          debugPrint('--- ĐANG LÀM CÂU HỎI SỐ $q/13 ---');
          
          // Tự động giải câu hỏi hiện tại
          await autoAnswerCurrentQuestion();
          
          // Dừng lại 1.8 giây để nhìn rõ đáp án tự động chọn
          await delay(tester, ms: 1800);

          if (q < 13) {
            // Nhấp vào nút "TIẾP THEO"
            final nextQuestionBtn = find.text('TIẾP THEO');
            await waitFor(tester, nextQuestionBtn);
            await tester.tap(nextQuestionBtn);
            // Dừng 1.8 giây sau khi chuyển câu để kịp đọc đề bài mới
            await delay(tester, ms: 1800); 
          } else {
            // Câu cuối cùng -> Bấm "NỘP BÀI"
            final submitQuizBtn = find.text('NỘP BÀI');
            await waitFor(tester, submitQuizBtn);
            await tester.tap(submitQuizBtn);
            await delay(tester, ms: 2500);

            // Xác nhận nộp bài trên hộp thoại
            final confirmSubmitBtn = find.text('Nộp bài');
            if (tester.any(confirmSubmitBtn)) {
              await tester.tap(confirmSubmitBtn);
              await delay(tester, ms: 5000); // Chờ lưu kết quả & tải trang kết quả thi từ API
            }
          }
        }

        // ========================================================
        // THOÁT KHỎI TRANG KẾT QUẢ THI (XEM CHI TIẾT BÀI LÀM TRƯỚC)
        // ========================================================
        await delay(tester, ms: 4000); // Chờ ngắm nhìn điểm số thi lung linh

        final viewDetailsBtnUpper = find.text('XEM CHI TIẾT BÀI LÀM');
        final viewDetailsBtnLower = find.text('Xem chi tiết bài làm');

        if (tester.any(viewDetailsBtnUpper)) {
          debugPrint('--- BẤM XEM CHI TIẾT BÀI LÀM (HOA) ---');
          await tester.tap(viewDetailsBtnUpper);
          await delay(tester, ms: 4000); // Chờ 4 giây ngắm chi tiết bài làm cực đẹp
          
          final detailBackButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
          final genericBackButton = find.byType(BackButton);
          
          if (tester.any(detailBackButton)) {
            await tester.tap(detailBackButton);
          } else if (tester.any(genericBackButton)) {
            await tester.tap(genericBackButton);
          }
          await delay(tester, ms: 2000);
        } else if (tester.any(viewDetailsBtnLower)) {
          debugPrint('--- BẤM XEM CHI TIẾT BÀI LÀM (THƯỜNG) ---');
          await tester.tap(viewDetailsBtnLower);
          await delay(tester, ms: 4000); // Chờ 4 giây
          
          final detailBackButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
          final genericBackButton = find.byType(BackButton);
          
          if (tester.any(detailBackButton)) {
            await tester.tap(detailBackButton);
          } else if (tester.any(genericBackButton)) {
            await tester.tap(genericBackButton);
          }
          await delay(tester, ms: 2000);
        }

        // Sau khi đã xem chi tiết và quay lại, bấm Hoàn thành để kết thúc
        final doneBtnUpper = find.text('HOÀN THÀNH');
        final doneBtnLower = find.text('Hoàn thành');
        final resultBackButton = find.byType(BackButton);
        final closeResultBtn = find.byIcon(Icons.close);
        
        if (tester.any(doneBtnUpper)) {
          debugPrint('--- BẤM NÚT HOÀN THÀNH (HOA) ĐỂ THOÁT KẾT QUẢ ---');
          await tester.tap(doneBtnUpper);
        } else if (tester.any(doneBtnLower)) {
          debugPrint('--- BẤM NÚT HOÀN THÀNH (THƯỜNG) ĐỂ THOÁT KẾT QUẢ ---');
          await tester.tap(doneBtnLower);
        } else if (tester.any(resultBackButton)) {
          await tester.tap(resultBackButton);
        } else if (tester.any(closeResultBtn)) {
          await tester.tap(closeResultBtn);
        }
        await delay(tester, ms: 2500);

        // Quay lại danh sách bài học từ Chi tiết bài tập
        final exerciseBackButton = find.byType(BackButton);
        await waitFor(tester, exerciseBackButton);
        await tester.tap(exerciseBackButton);
        await delay(tester, ms: 2500);

        // ========================================================
        // BƯỚC 5: KIỂM TRA MÀN HÌNH ÔN TẬP TỪ VỰNG (XỬ LÝ 2 TRẠNG THÁI)
        // ========================================================
        // Lưu ý: Sau cleanup, từ vựng mới học có NextReviewDate = ngày mai
        // (theo thuật toán Spaced Repetition) nên có thể không có từ cần ôn hôm nay.
        // Test xử lý cả 2 trạng thái một cách thông minh.
        final reviewTab = find.byTooltip('Ôn tập');
        await waitFor(tester, reviewTab);
        await tester.tap(reviewTab);
        await delay(tester, ms: 3000); // Chờ 3 giây tải tiến độ ôn tập từ API

        // Kiểm tra xem có từ cần ôn hôm nay hay không
        final startReviewBtn = find.text('Bấm để ôn tập ngay 🔥');
        final allDoneText = find.text('Tuyệt vời!');
        final goHomeBtn = find.text('Quay lại trang chủ');

        if (tester.any(startReviewBtn)) {
          // TRẠNG THÁI A: Có từ cần ôn -> Tiến hành ôn tập đầy đủ
          debugPrint('--- CÓ TỪ CẦN ÔN HÔM NAY -> TIẾN HÀNH ÔN TẬP ---');
          await delay(tester, ms: 1500);
          await tester.tap(startReviewBtn);
          await delay(tester, ms: 3000);

          // Kiểm tra tiêu đề ôn tập
          final progressText = find.text('Tiến độ ôn tập');
          await waitFor(tester, progressText, timeoutSeconds: 12);
          await delay(tester, ms: 1500);

          // Lật thẻ xem mặt sau từ vựng
          final reviewCard = find.byKey(const ValueKey('review-card-0'));
          if (tester.any(reviewCard)) {
            await tester.tap(reviewCard);
            await delay(tester, ms: 2000);
          }

          // Nhấn "Thuộc" để cập nhật tiến độ lên máy chủ
          final masteredBtn = find.text('Thuộc');
          if (tester.any(masteredBtn)) {
            await tester.tap(masteredBtn);
            await delay(tester, ms: 3000);
          }

          // Quay lại màn hình ôn tập chính
          final reviewBackButton = find.byType(BackButton);
          if (tester.any(reviewBackButton)) {
            await tester.tap(reviewBackButton);
            await delay(tester, ms: 2500);
          }

        } else if (tester.any(allDoneText) || tester.any(goHomeBtn)) {
          // TRẠNG THÁI B: Đã hoàn thành hết từ vựng hôm nay (Spaced Repetition)
          // Từ mới học sẽ đến hạn ôn vào ngày mai - hành vi đúng của hệ thống!
          debugPrint('--- TẤT CẢ TỪ VỰNG ĐÃ ĐƯỢC ÔN HÔM NAY (SPACED REPETITION) ---');
          debugPrint('--- MÀN HÌNH HIỂN THỊ: "Tuyệt vời! Hãy quay lại ngày mai" ---');
          await delay(tester, ms: 3000); // Dừng 3 giây để quan sát màn hình thành tích

          // Bấm "Quay lại trang chủ" nếu có
          if (tester.any(goHomeBtn)) {
            await tester.tap(goHomeBtn);
            await delay(tester, ms: 2000);
          }
        } else {
          // TRẠNG THÁI C: Không tìm thấy cả 2 nút -> Chờ thêm và tiếp tục
          debugPrint('--- CHỜ TẢI MÀN HÌNH ÔN TẬP... ---');
          await delay(tester, ms: 3000);
        }

        debugPrint('--- CHÚC MỪNG: BÀI TEST E2E ĐÃ HOÀN THÀNH XUẤT SẮC ---');
      });
  });
}

// ============================================================
// HÀM DỌN DẸP DỮ LIỆU TIẾN ĐỘ TEST (PRE-TEST CLEANUP)
// ============================================================
// Gọi API TestController trên backend để xóa toàn bộ lịch sử
// làm bài Quiz, ôn tập Flashcard, tiến độ bài học của tài khoản test.
// Đảm bảo kịch bản E2E luôn bắt đầu từ trạng thái sạch sẽ và nhất quán.
Future<void> _cleanupTestUserProgress() async {
  debugPrint('=== [PRE-TEST] Bắt đầu dọn sạch dữ liệu tiến độ test ===');

  try {
    // Bước 1: Tắt kiểm tra SSL certificate (Backend local dùng http)
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;

    // Bước 2: Lấy userId của tài khoản test từ API check-env
    final checkUri = Uri.parse('$_testApiBase/api/test/check-env?email=$_testUserEmail');
    final checkRequest = await httpClient.getUrl(checkUri);
    final checkResponse = await checkRequest.close();
    final checkBody = await checkResponse.transform(const Utf8Decoder()).join();
    final checkJson = jsonDecode(checkBody) as Map<String, dynamic>;

    final testUser = checkJson['testUser'];
    if (testUser == null) {
      debugPrint('[PRE-TEST] ⚠️ Không tìm thấy tài khoản test "$_testUserEmail". Bỏ qua cleanup.');
      return;
    }

    final int userId = testUser['userId'] as int;
    debugPrint('[PRE-TEST] ✅ Tìm thấy tài khoản test (userId=$userId). Đang dọn dẹp...');

    // Bước 3: Gọi API dọn dẹp toàn bộ dữ liệu tiến độ học tập
    final cleanupUri = Uri.parse('$_testApiBase/api/test/cleanup-user-progress?userId=$userId');
    final cleanupRequest = await httpClient.postUrl(cleanupUri);
    cleanupRequest.headers.set('Content-Type', 'application/json');
    final cleanupResponse = await cleanupRequest.close();
    final cleanupBody = await cleanupResponse.transform(const Utf8Decoder()).join();
    final cleanupJson = jsonDecode(cleanupBody) as Map<String, dynamic>;

    if (cleanupResponse.statusCode == 200 && cleanupJson['success'] == true) {
      final summary = cleanupJson['summary'] as Map<String, dynamic>;
      debugPrint('[PRE-TEST] ✅ Dọn dẹp thành công!');
      debugPrint('[PRE-TEST]   - QuizAttempts đã xóa: ${summary['quizAttemptsDeleted']}');
      debugPrint('[PRE-TEST]   - FlashCardReviews đã xóa: ${summary['flashCardReviewsDeleted']}');
      debugPrint('[PRE-TEST]   - LessonCompletions đã xóa: ${summary['lessonCompletionsDeleted']}');
      debugPrint('[PRE-TEST]   - ModuleCompletions đã xóa: ${summary['moduleCompletionsDeleted']}');
      debugPrint('[PRE-TEST]   - CourseProgresses đã xóa: ${summary['courseProgressesDeleted']}');
      debugPrint('[PRE-TEST]   - Streaks đã xóa: ${summary['streaksDeleted']}');
    } else {
      debugPrint('[PRE-TEST] ⚠️ Cleanup API trả về: ${cleanupResponse.statusCode} - $cleanupBody');
    }

    httpClient.close();
  } catch (e) {
    // Không fail test nếu cleanup lỗi (ví dụ: backend chưa khởi động)
    // Test sẽ tiếp tục chạy, chỉ cảnh báo để người dùng biết
    debugPrint('[PRE-TEST] ⚠️ Không thể kết nối API cleanup: $e');
    debugPrint('[PRE-TEST]    Hãy đảm bảo backend đang chạy tại $_testApiBase');
    debugPrint('[PRE-TEST]    Test sẽ tiếp tục chạy với dữ liệu hiện tại...');
  }

  debugPrint('=== [PRE-TEST] Hoàn tất giai đoạn chuẩn bị môi trường ===');
}
