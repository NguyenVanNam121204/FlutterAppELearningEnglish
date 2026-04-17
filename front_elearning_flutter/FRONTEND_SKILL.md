---
name: Flutter Frontend Coding Guidelines
description: Chi tiết về kiến trúc cấu trúc thư mục, quy ước viết code và luồng phát triển cho dự án Frontend Flutter (front_elearning_flutter). Dùng file này để huấn luyện AI hoặc gửi cho team member mới.
---

# 📚 Cẩm Nang Coding (Skill Guidelines) - App English Flutter (Frontend)

Tài liệu này định nghĩa rõ ràng kiến trúc, thư viện cốt lõi, quy tắc và quy trình phát triển cho dự án E-Learning Frontend (Flutter). Hãy **tuân thủ chặt chẽ** các hướng dẫn trong này để duy trì tính nhất quán (consistency), hiệu suất và khả năng mở rộng của source code.

---

## 🏗 1. Kiến Trúc Tổng Quan (Architecture & Tech Stack)

Dự án áp dụng mô hình **MVVM (Model-View-ViewModel)** lai với các nguyên lý của **Clean Architecture**.

*   **Quản lý Trạng thái & Dependency Injection (DI)**: `flutter_riverpod`.
*   **Điều hướng (Navigation)**: `go_router` (Sử dụng Declarative Routing với cơ chế redirect khi trạng thái user thay đổi).
*   **Networking / Call API**: `dio` (Tích hợp custom AuthInterceptor để inject và tự động refresh token).
*   **Bảo mật dữ liệu (Storage)**: `flutter_secure_storage` (Lưu JWT Tokens).
*   **Môi trường (.env)**: `flutter_dotenv`.
*   **Font chữ**: `google_fonts`.

---

## 📁 2. Cấu Trúc Thư Mục Tiêu Chuẩn

Tất cả code dự án nằm gọn trong thư mục `lib/`. **Tuyệt đối không** đặt file lung tung ngoài cấu trúc đã quy định sau:

```text
lib/
├── app/                  # Cấu hình toàn cục cho app
│   ├── config/           # Các biến môi trường (.env config)
│   ├── router/           # Định nghĩa RoutePaths và GoRouter
│   ├── theme/            # Theme, style, color palette
│   ├── app.dart          # Root Widget của ứng dụng
│   └── providers.dart    # ⚠️ TẬP TRUNG TẤT CẢ RIVERPOD PROVIDERS (Services, Repos, ViewModels) TẠI ĐÂY
├── core/                 # Thư mục chứa các code nền tảng, dùng chung cho mọi tính năng
│   ├── constants/        # Các hằng số (API Base URLs, Strings...)
│   ├── errors/           # AppError và các custom exception
│   ├── logger/           # AppLogger (ghi log request/response)
│   └── result/           # ⚠️ QUAN TRỌNG: Pattern Result wrapper (Success/Failure) cho API calls
├── models/               # Data Transfer Objects (DTO) / PODO models (VD: user_model.dart, auth_response_model.dart)
├── repositories/         # Tầng giao tiếp lấy dữ liệu. Gọi ApiService và gói kết quả vào Result<T> hoặc Failure
├── services/             # Triển khai các API thiết bị, network (ApiService, AuthInterceptor, SecureStorageService)
├── viewmodels/           # (Controller) Chứa StateNotifier và State tương ứng để xử lý business logic
└── views/                # UI Layer (Giao diện)
    ├── screens/          # Các trang độc lập (Screen) (VD: login_screen.dart, home_screen.dart)
    └── widgets/          # Các Components/Widgets chia theo feature (auth/, home/, buttons/...)
```

---

## ️⚙️ 3. Quy Tắc Viết Code (Coding Conventions)

### 3.1. Phân Tách Trách Nhiệm (Separation of Concerns)
*   **Views (UI)**: Tuyệt đối **không** thực hiện Call API hoặc xử lý logic phức tạp trong UI. Ưu tiên UI câm (Dumb UI). Chỉ sử dụng `ref.watch`, `ref.listen`, và trigger sự kiện gửi vào ViewModel thông qua `ref.read`.
*   **ViewModels**: Xử lý logic nghiệp vụ, giữ App State. State phải là **Immutable** (dùng phương thức `copyWith` trên object State). ViewModels tham chiếu đến Repositories để lấy/lưu data rồi cập nhật trạng thái mới.
*   **Repositories**: Dịch dữ liệu từ Service API sang Domain Model, bọc Exception vào trong pattern `Result`.
*   **Services**: Chỉ chứa code "thuần kỹ thuật" (thực hiện HTTP request GET/POST, đọc/ghi local storage).

### 3.2. Tiêu Chuẩn Quản Lý Dependency (Providers)
*   Tất cả dependencies (Dio, Services, Repositories, ViewModels, GoRouter) **phải** được tiêm (inject) qua file `lib/app/providers.dart`.
*   Không được phép khởi tạo object bằng từ khóa `new` hay constructor gọi trực tiếp (Ví dụ: Không dùng `AuthRepository()` ở View. Phải dùng `ref.read(authRepositoryProvider)`).

### 3.3. Xử Lý Lỗi (Error & API Handling Pattern)
Tại Repositories, luôn kết hợp với file `result.dart` sử dụng pattern của `sealed class Result<T>`:
```dart
// Mẫu trong Repository
Future<Result<UserModel>> getUser() async {
  try {
    final response = await _apiService.getUser();
    return Success(UserModel.fromJson(response.data));
  } catch (e) {
    return Failure(AppError(message: 'Lỗi lấy user'));
  }
}
```
Tại ViewModel, phân giải Result bằng `switch`:
```dart
// Mẫu trong ViewModel
final result = await _userRepository.getUser();
switch (result) {
  case Success(value: final user):
    state = state.copyWith(user: user, isLoading: false);
  case Failure(error: final error):
    state = state.copyWith(errorMessage: error.message, isLoading: false);
}
```

### 3.4. Định Tuyến (Routing & Redirect)
*   Sử dụng hằng số trong `route_paths.dart` để định hướng (VD: `context.go(RoutePaths.home)`). Không truyền hard-code string `'/home'`.
*   Việc check Authentication (Đã login hay chưa) được xử lý tập trung tại thuộc tính `redirect:` của `go_router` bên trong `lib/app/router/app_router.dart`. 

### 3.5. Quy ước Đặt Tên (Naming)
*   *Lớp (Classes), Enum*: `PascalCase` (VD: `HomeScreen`, `AuthRepository`).
*   *File & Thư mục*: `snake_case` (VD: `home_screen.dart`, `auth_repository.dart`). Không tạo thư mục viết hoa.
*   *Biến, Tham số, Phương thức*: `camelCase` (VD: `getUser()`, `isLoading`).
*   *Provider*: Hậu tố là `Provider` (VD: `homeViewModelProvider`, `apiServiceProvider`).

---

## 🚀 4. Workflow Để Thêm 1 Feature Mới

Khi có yêu cầu thêm một module (hoặc tính năng) mới, hãy chạy thứ tự theo trình tự này:

1.  **Hiểu Dữ Liệu**: Thêm các đối tượng hứng dữ liệu vào `lib/models/[feature]_model.dart`.
2.  **Network**: Tạo các method gọi endpoint API mới trong `lib/services/api_service.dart`.
3.  **Repository**: Tạo file `lib/repositories/[feature]_repository.dart` và map API data vào pattern `Result`.
4.  **Đăng ký DI (Layer Data)**: Cập nhật `lib/app/providers.dart` bằng cách khai báo `[feature]RepositoryProvider`.
5.  **State & ViewModel**: 
    - Tạo file `lib/viewmodels/[feature]_viewmodel.dart`.
    - Tạo class State class cho feature (`[Feature]State`) phải chứa parameter như `isLoading`, `errorMessage` cùng thuộc tính data. Mở rộng với hàm `copyWith`.
    - Khởi tạo class extends `StateNotifier` để xử lý logic, gọi các function từ Repository.
6.  **Đăng ký DI (Layer ViewModel)**: Cập nhật `lib/app/providers.dart` bằng cách khai báo `[feature]ViewModelProvider` (`StateNotifierProvider`).
7.  **Xây Dựng Views**: 
    - Xây các widget tái sử dụng vào `lib/views/widgets/[feature]/...`
    - Xây class màn hình (kế thừa `ConsumerWidget` hoặc dùng `ConsumerStatefulWidget` của Riverpod) vào `lib/views/screens/[feature]_screen.dart`.
8.  **Routing**: Tạo hằng số con đường tại `lib/app/router/route_paths.dart` và đăng ký màn hình vào list routes trong `app_router.dart`.
