# Flutter ứng dụng "Catalunya English" - Phân tích chi tiết

## 📋 Tổng quan dự án

**Tên ứng dụng:** front_elearning_flutter (Catalunya English)  
**Mục đích:** Ứng dụng học tiếng Anh trên di động  
**Trạng thái:** Đang phát triển  
**Phiên bản Dart:** ^3.10.7

---

## 🏗️ Kiến trúc ứng dụng

### **Mô hình kiến trúc: MVVM (Model-View-ViewModel)**

```
┌─────────────────────────────────────────────────────────┐
│                      Views (UI Layer)                    │
│  - LoginScreen, RegisterScreen, HomeScreen, etc.        │
│                                                          │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│            ViewModels (Business Logic)                   │
│  - AuthViewModel, HomeViewModel                          │
│  - State management với Riverpod                         │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│           Repositories (Data Access Layer)               │
│  - AuthRepository, HomeRepository                        │
│  - Trung gian giữa Services và ViewModels               │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│              Services (API & Storage)                    │
│  - ApiService (Dio), SecureStorageService              │
│  - AuthInterceptor, AuthSessionService                  │
└─────────────────────────────────────────────────────────┘
```

---

## 📦 Cấu trúc thư mục

```
lib/
├── main.dart                    # Điểm nhập vào ứng dụng
├── app/
│   ├── app.dart                # Widget chính của ứng dụng
│   ├── config/
│   │   └── app_config.dart     # Cấu hình API, timeouts, logging
│   ├── router/
│   │   ├── app_router.dart     # Cấu hình Go Router
│   │   └── route_paths.dart    # Định nghĩa các route
│   ├── providers.dart          # Tất cả Riverpod providers
│   └── theme/
│       └── app_theme.dart      # Theme Material Design
│
├── core/                        # Lõi của ứng dụng
│   ├── constants/              # Các hằng số
│   ├── errors/                 # Xử lý lỗi (AppError)
│   ├── logger/                 # Logging
│   └── result/                 # Mô hình Result<T> (Success/Failure)
│
├── models/                      # Data models
│   ├── user_model.dart
│   ├── auth_response_model.dart
│   ├── home_course_model.dart
│   └── streak_model.dart
│
├── services/                    # Tầng dịch vụ
│   ├── api_service.dart        # HTTP client (Dio)
│   ├── auth_interceptor.dart   # Xử lý token trong requests
│   ├── auth_session_service.dart # Quản lý session
│   └── secure_storage_service.dart # Lưu trữ an toàn (tokens, etc.)
│
├── repositories/               # Lớp access dữ liệu
│   ├── auth_repository.dart    # Các API liên quan auth
│   └── home_repository.dart    # Các API liên quan home
│
├── viewmodels/                 # Business logic & state
│   ├── auth_viewmodel.dart     # Quản lý trạng thái xác thực
│   └── home_viewmodel.dart     # Quản lý trạng thái home
│
└── views/                       # UI Screens
    ├── screens/
    │   ├── login_screen.dart
    │   ├── register_screen.dart
    │   ├── forgot_password_screen.dart
    │   ├── verify_email_otp_screen.dart
    │   ├── verify_reset_otp_screen.dart
    │   ├── reset_password_screen.dart
    │   └── home_screen.dart
    └── widgets/                # Reusable UI components
```

---

## 🔧 Công nghệ & Thư viện chính

| Thư viện | Phiên bản | Mục đích |
|---------|----------|---------|
| **flutter_riverpod** | ^2.6.1 | State management (thay thế Provider) |
| **go_router** | ^14.8.1 | Navigation & routing |
| **dio** | ^5.8.0+1 | HTTP client để gọi API |
| **flutter_secure_storage** | ^9.2.4 | Lưu trữ an toàn (tokens, passwords) |
| **google_fonts** | ^6.3.0 | Custom fonts từ Google Fonts |
| **cupertino_icons** | ^1.0.8 | iOS style icons |

---

## 🔐 Luồng xác thực (Authentication Flow)

```
User Input
    ↓
[LoginScreen]
    ↓
AuthViewModel.login()
    ↓
AuthRepository.login()
    ↓
ApiService.post() ← [AuthInterceptor]
    ↓
[API Response]
    ↓
AuthSessionService.saveSession()
    ↓
SecureStorageService.saveToken()
    ↓
[Session Restored] ← AuthViewModel.restoreSession()
    ↓
GoRouter Redirect → HomeScreen
```

### Các bước chính:
1. User nhập email/password trên LoginScreen
2. AuthViewModel gọi AuthRepository.login()
3. AuthRepository sử dụng ApiService để gọi API
4. Token được lưu vào Secure Storage
5. AuthSessionService quản lý session lifetime
6. Khi token hết hạn, tự động redirect về LoginScreen

---

## 📱 Màn hình chính

| Màn hình | Mục đích | Điều kiện truy cập |
|---------|---------|-------------------|
| **LoginScreen** | Đăng nhập tài khoản | Chưa xác thực |
| **RegisterScreen** | Đăng ký tài khoản mới | Chưa xác thực |
| **ForgotPasswordScreen** | Bắt đầu quy trình reset mật khẩu | Chưa xác thực |
| **VerifyEmailOtpScreen** | Xác nhận OTP qua email | Chưa xác thực |
| **VerifyResetOtpScreen** | Xác nhận OTP cho reset password | Chưa xác thực |
| **ResetPasswordScreen** | Đặt lại mật khẩu mới | Chưa xác thực |
| **HomeScreen** | Trang chính, hiển thị khóa học | Đã xác thực |

---

## 🌐 Cấu hình API

**File:** `lib/app/config/app_config.dart`

### Cấu hình mặc định:
```dart
API_BASE_URL: 'http://localhost:5030'
APP_ENV: 'dev'
CONNECT_TIMEOUT_MS: 15000
RECEIVE_TIMEOUT_MS: 15000
ENABLE_NETWORK_LOG: true
```

### Cách thay đổi khi build:
```bash
# Dev
flutter run

# Staging
flutter run --dart-define=API_BASE_URL=https://staging-api.example.com

# Production
flutter run --dart-define=API_BASE_URL=https://api.example.com --dart-define=APP_ENV=prod
```

---

## 🛣️ Navigation (Go Router)

**File:** `lib/app/router/app_router.dart`

### Các route:
- `/login` - Đăng nhập
- `/register` - Đăng ký
- `/forgot-password` - Quên mật khẩu
- `/verify-email-otp?email=...` - Xác nhận OTP email
- `/verify-reset-otp?email=...` - Xác nhận OTP reset
- `/reset-password?email=...&otpCode=...` - Reset password
- `/home` - Trang chính

### Guard Logic:
- Nếu chưa xác thực và truy cập non-auth page → redirect về `/login`
- Nếu đã xác thực và truy cập auth page → redirect về `/home`

---

## 💾 Lưu trữ dữ liệu

### SecureStorageService
- **Mục đích:** Lưu trữ nhạy cảm (tokens, refresh tokens)
- **Sử dụng:** flutter_secure_storage plugin
- **Ưu điểm:** Mã hóa tự động trên cả iOS (Keychain) và Android (Keystore)

### AuthSessionService
- **Mục đích:** Quản lý vòng đời session
- **Chức năng:** 
  - Lắng nghe sự kiện hết hạn session
  - Kích hoạt logout tự động
  - Thông báo khi session expiry sắp tới

---

## 🔍 Error Handling

### Result<T> Pattern
```dart
// Success case
Result<AuthResponseModel>
  ↓
Success(AuthResponseModel)

// Error case
Result<AuthResponseModel>
  ↓
Failure(AppError)
    ├── message: String
    ├── code: int?
    └── exception: Exception?
```

### Error Mapping
- `DioException` → `AppError` (trong Repository)
- Các lỗi khác → Generic error message

---

## 📊 State Management (Riverpod)

**File:** `lib/app/providers.dart`

### Providers chính:
```dart
// Auth ViewModel
final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>

// Home ViewModel  
final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeState>

// Go Router
final goRouterProvider = Provider<GoRouter>
```

### Ưu điểm Riverpod:
- ✅ Type-safe, compile-time safety
- ✅ Có hỗ trợ dependency injection
- ✅ Performance tốt (smart caching)
- ✅ Dễ test

---

## 🔐 Token Management

### Luồng Token:
1. **Refresh Token:** Lưu trong SecureStorage
2. **Access Token:** Lưu trong SecureStorage
3. **Interceptor:** Tự động thêm token vào request headers
4. **Session Expiry:** Stream thông báo khi token hết hạn

### Auth Interceptor
- Thêm `Authorization: Bearer <token>` vào mọi request
- Xử lý 401 response (token hết hạn)
- Có thể retry request sau khi refresh token

---

## 📱 Platform Support

Được cấu hình cho:
- ✅ Android (`android/`)
- ✅ iOS (`ios/`)
- ✅ Web (`web/`)
- ✅ Windows (`windows/`)
- ✅ macOS (`macos/`)
- ✅ Linux (`linux/`)

---

## ⚠️ Các điểm cần chú ý

### 1. **API Base URL hardcoded**
   - ⚠️ Localhost (5030) trong config mặc định
   - ✅ Có thể override bằng `--dart-define`

### 2. **Network Logging**
   - ⚠️ Enabled mặc định (có thể log sensitive data)
   - ✅ Nên disable trong production

### 3. **Token Refresh**
   - Cần kiểm tra logic refresh token trong AuthInterceptor
   - Có thể cần xử lý retry exponential backoff

### 4. **Error Messages**
   - Lỗi hiện tại:`"Da xay ra loi khong mong muon."`
   - Nên localize tất cả error messages

---

## 🚀 Next Steps (Gợi ý cải thiện)

### Ngắn hạn:
- [ ] Thêm support đa ngôn ngữ (i18n/localization)
- [ ] Thêm unit tests cho ViewModels
- [ ] Thêm mock API service cho testing
- [ ] Cấu hình linting rules (analysis_options.yaml)

### Dài hạn:
- [ ] Thêm offline caching
- [ ] Implement feature modules (modular architecture)
- [ ] Thêm analytics tracking
- [ ] Implement push notifications
- [ ] Auto-update mechanism

---

## 🔗 Kết nối với Backend

**Backend:** .NET API (`http://localhost:5030`)
**Mô tả:** LearningEnglish.API với các endpoints:
- Authentication (login, register, forgot password)
- User management
- Course/content management
- Progress tracking

---

## 📝 Ghi chú

- Dự án sử dụng **Riverpod** thay vì Provider (modern state management)
- Kiến trúc MVVM rõ ràng và dễ bảo trì
- Separation of concerns tốt (UI, Business Logic, Data)
- Ready cho testing và scaling
