# Frontend E-Learning Flutter

Ứng dụng frontend Flutter cho hệ thống học tiếng Anh, xây dựng theo kiến trúc MVVM kết hợp nguyên tắc Clean Architecture, tập trung vào tính nhất quán, khả năng mở rộng và dễ bảo trì.

## Mục tiêu dự án

- Xây dựng trải nghiệm học tiếng Anh đa nền tảng (Android, iOS, Web, Desktop).
- Đồng bộ luồng nghiệp vụ với backend hiện tại.
- Chuẩn hóa cách tổ chức code để team và AI agent có thể phát triển nhanh nhưng vẫn ổn định.

## Kiến trúc và pattern

### Kiến trúc tổng thể

- MVVM theo lớp:
	- View: UI và tương tác người dùng.
	- ViewModel: xử lý nghiệp vụ và quản lý state.
	- Repository: giao tiếp dữ liệu, mapping response.
	- Service: tầng kỹ thuật (HTTP, token, storage).

### Nguyên tắc cốt lõi

- Tách trách nhiệm rõ ràng giữa các layer.
- Quản lý trạng thái và DI qua Riverpod.
- Điều hướng tập trung qua go_router.
- Xử lý API theo Result pattern (Success/Failure), không ném lỗi thô lên UI.
- State bất biến, cập nhật qua copyWith.

## Công nghệ chính

- Flutter
- flutter_riverpod
- go_router
- dio
- flutter_secure_storage
- shared_preferences
- flutter_dotenv
- flutter_markdown

## Cấu trúc thư mục

```text
lib/
	app/            # config app, router, providers, theme
	core/           # constants, errors, logger, result wrapper
	models/         # DTO/model
	repositories/   # data access + map response
	services/       # api service, interceptor, secure storage
	viewmodels/     # business logic + immutable state
	views/
		screens/      # màn hình
		widgets/      # widget tái sử dụng theo feature
```

## Bắt đầu nhanh

### 1. Yêu cầu môi trường

- Flutter SDK: theo phiên bản trong [pubspec.yaml](pubspec.yaml)
- Dart SDK: theo Flutter SDK đi kèm

### 2. Cài dependencies

```bash
flutter pub get
```

### 3. Cấu hình môi trường

- Tạo file `.env` từ mẫu `.env.example`.
- Không commit thông tin nhạy cảm.

### 4. Chạy ứng dụng

```bash
flutter run
```

Chạy web:

```bash
flutter run -d chrome
```

## Chất lượng code

Phân tích static:

```bash
flutter analyze
```

Chạy test:

```bash
flutter test
```

## Quy ước phát triển

- Không gọi API trực tiếp trong screen/widget.
- Không khởi tạo repository/service trực tiếp trong UI.
- Đăng ký dependency tập trung tại `lib/app/providers.dart`.
- Điều hướng qua hằng số trong `lib/app/router/route_paths.dart`.
- Mọi repository trả về `Result<T>`.

## Tài liệu nội bộ liên quan

- Tài liệu hiện được gom tập trung trong README này để dễ theo dõi và bảo trì.
- Nếu cần mở rộng quy chuẩn cho AI agent, tham khảo bộ skill tại [.agents/skills/flutter-mvvm-riverpod-go-router/skill.md](.agents/skills/flutter-mvvm-riverpod-go-router/skill.md).

## Nguồn tham khảo chính thức

- Flutter Docs: https://docs.flutter.dev
- Dart Language: https://dart.dev
- Riverpod: https://riverpod.dev
- go_router: https://pub.dev/packages/go_router
- Dio: https://pub.dev/packages/dio
- flutter_secure_storage: https://pub.dev/packages/flutter_secure_storage

## Định hướng mở rộng

- Chuẩn hóa thêm bộ agent skill để tự động hóa review/refactor theo kiến trúc.
- Bổ sung test theo feature (viewmodel/repository/widget).
- Tối ưu UX web và mobile theo cùng design language.
