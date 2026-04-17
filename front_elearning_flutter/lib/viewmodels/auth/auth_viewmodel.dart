import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../core/result/result.dart';
import '../../models/user/user_model.dart';
import '../../repositories/auth/auth_repository.dart';
import '../../services/auth_session_service.dart';
import '../../services/secure_storage_service.dart';

class AuthState {
  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.errorMessage,
    this.user,
  });

  final bool isLoading;
  final bool isAuthenticated;
  final String? errorMessage;
  final UserModel? user;

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? errorMessage,
    UserModel? user,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      user: user ?? this.user,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  AuthViewModel(
    this._authRepository,
    this._secureStorageService,
    this._authSessionService,
  ) : super(const AuthState()) {
    _sessionExpiredSubscription = _authSessionService.onSessionExpired.listen((
      _,
    ) {
      _handleSessionExpired();
    });
    restoreSession();
  }

  final AuthRepository _authRepository;
  final SecureStorageService _secureStorageService;
  final AuthSessionService _authSessionService;
  late final StreamSubscription<void> _sessionExpiredSubscription;

  @override
  void dispose() {
    _sessionExpiredSubscription.cancel();
    super.dispose();
  }

  Future<void> restoreSession() async {
    final token = await _secureStorageService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      state = state.copyWith(isLoading: true, isAuthenticated: true);
      await refreshProfile(silent: true);
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _authRepository.login(
      email: email,
      password: password,
    );

    switch (result) {
      case Success(value: final auth):
        if (auth.accessToken.isNotEmpty) {
          await _secureStorageService.saveAccessToken(auth.accessToken);
        }
        if (auth.refreshToken.isNotEmpty) {
          await _secureStorageService.saveRefreshToken(auth.refreshToken);
        }

        var user = auth.user;
        if (user == null || user.fullName.trim().isEmpty) {
          final profileResult = await _authRepository.profile();
          if (profileResult case Success<UserModel>(:final value)) {
            user = value;
          }
        }

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
          clearError: true,
        );
        return true;
      case Failure(error: final error):
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          errorMessage: error.message,
        );
        return false;
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phoneNumber,
    required bool isMale,
    DateTime? dateOfBirth,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _authRepository.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      phoneNumber: phoneNumber,
      isMale: isMale,
      dateOfBirth: dateOfBirth,
    );

    switch (result) {
      case Success():
        state = state.copyWith(isLoading: false, clearError: true);
        return true;
      case Failure(error: final error):
        state = state.copyWith(isLoading: false, errorMessage: error.message);
        return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _authRepository.forgotPassword(email);

    switch (result) {
      case Success():
        state = state.copyWith(isLoading: false, clearError: true);
        return true;
      case Failure(error: final error):
        state = state.copyWith(isLoading: false, errorMessage: error.message);
        return false;
    }
  }

  Future<bool> verifyEmailOtp({
    required String email,
    required String otpCode,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _authRepository.verifyEmailOtp(
      email: email,
      otpCode: otpCode,
    );

    switch (result) {
      case Success():
        state = state.copyWith(isLoading: false, clearError: true);
        return true;
      case Failure(error: final error):
        state = state.copyWith(isLoading: false, errorMessage: error.message);
        return false;
    }
  }

  Future<bool> verifyResetOtp({
    required String email,
    required String otpCode,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _authRepository.verifyResetOtp(
      email: email,
      otpCode: otpCode,
    );

    switch (result) {
      case Success():
        state = state.copyWith(isLoading: false, clearError: true);
        return true;
      case Failure(error: final error):
        state = state.copyWith(isLoading: false, errorMessage: error.message);
        return false;
    }
  }

  Future<bool> setNewPassword({
    required String email,
    required String otpCode,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _authRepository.setNewPassword(
      email: email,
      otpCode: otpCode,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );

    switch (result) {
      case Success():
        state = state.copyWith(isLoading: false, clearError: true);
        return true;
      case Failure(error: final error):
        state = state.copyWith(isLoading: false, errorMessage: error.message);
        return false;
    }
  }

  Future<void> logout() async {
    await _secureStorageService.clearAuth();
    state = const AuthState();
  }

  Future<void> refreshProfile({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    final result = await _authRepository.profile();
    switch (result) {
      case Success<UserModel>(:final value):
        state = state.copyWith(
          user: value,
          isAuthenticated: true,
          isLoading: false,
          clearError: true,
        );
      case Failure<UserModel>(:final error):
        state = state.copyWith(isLoading: false, errorMessage: error.message);
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void _handleSessionExpired() {
    state = const AuthState(
      isAuthenticated: false,
      errorMessage: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    );
  }
}
