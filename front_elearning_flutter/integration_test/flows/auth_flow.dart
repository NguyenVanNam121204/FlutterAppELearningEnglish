import '../helpers/test_helpers.dart';

// ============================================================
// BƯỚC 1: LUỒNG ĐĂNG NHẬP (AUTH FLOW)
// ============================================================
// State-based approach:
//   Chờ form login HOẶC màn home xuất hiện → biết app đã sẵn sàng
//   Sau khi tap Login: chờ loading biến mất thay vì delay 5s
//   Xác nhận login thành công: chờ thanh BottomNav xuất hiện
// ============================================================

/// Kiểm tra trạng thái và thực hiện đăng nhập nếu cần.
///
/// Tự động phát hiện:
///   - Chưa đăng nhập → điền thông tin và đăng nhập
///   - Đã đăng nhập sẵn → bỏ qua, tiếp tục ngay
///
/// Kết thúc khi: Tab "Khóa học" trên BottomNav đã xuất hiện.
Future<void> runAuthFlow(WidgetTester tester) async {
  logFlowStart('Auth Flow');
  final emailFieldFinder = find.byKey(const ValueKey('email-field'));

  if (tester.any(emailFieldFinder)) {
    debugPrint('--- PHÁT HIỆN CHƯA ĐĂNG NHẬP → TIẾN HÀNH ĐĂNG NHẬP ---');
    await _performLogin(tester);
  } else {
    debugPrint('--- ĐÃ ĐĂNG NHẬP SẴN → BỎ QUA BƯỚC ĐĂNG NHẬP ---');
  }

  // Xác nhận thành công: BottomNav với tab "Khóa học" phải xuất hiện
  await waitFor(
    tester,
    find.byTooltip('Khóa học'),
    timeout: const Duration(seconds: 15),
    reason: 'Không vào được màn hình Home sau đăng nhập',
  );

  // Tự động đứng chờ API và Ảnh trên màn hình Home (nếu có) tải xong hoàn toàn
  await waitForLoading(tester, timeout: const Duration(seconds: 15));

  debugPrint('--- ĐÃ VÀO MÀN HÌNH HOME VÀ TẢI XONG ẢNH ---');
  logFlowPass('Auth Flow');
}

/// Thực hiện đăng nhập: nhập email/mật khẩu → tap button → chờ API xong.
Future<void> _performLogin(WidgetTester tester) async {
  final emailField = find.descendant(
    of: find.byKey(const ValueKey('email-field')),
    matching: find.byType(TextFormField),
  );
  final passwordField = find.descendant(
    of: find.byKey(const ValueKey('password-field')),
    matching: find.byType(TextFormField),
  );
  final loginButton = find.byKey(const ValueKey('login-button'));

  await tester.enterText(emailField, 'nt0143436946@gmail.com');
  await tester.enterText(passwordField, 'Nam@12345678');

  // Tap và chờ loading biến mất = API đăng nhập đã trả về
  await tapAndWaitForLoad(
    tester,
    loginButton,
    timeout: const Duration(seconds: 20),
  );
}
