import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../models/auth/auth_response_model.dart';
import '../../models/user/user_model.dart';
import '../../services/api_service.dart';

class AuthRepository {
  AuthRepository(this._apiService);

  final ApiService _apiService;

  Future<Result<AuthResponseModel>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      return Success(AuthResponseModel.fromJson(data));
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(AppError(message: 'Đã sảy ra lỗi không mong muốn.'));
    }
  }

  Future<Result<void>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phoneNumber,
    required bool isMale,
    DateTime? dateOfBirth,
  }) async {
    try {
      await _apiService.post(
        ApiConstants.register,
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
          'phoneNumber': phoneNumber,
          'isMale': isMale,
          'dateOfBirth': dateOfBirth?.toUtc().toIso8601String(),
        },
      );

      return const Success(null);
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(AppError(message: 'Đã sảy ra lỗi không mong muốn.'));
    }
  }

  Future<Result<void>> forgotPassword(String email) async {
    try {
      await _apiService.post(
        ApiConstants.forgotPassword,
        data: {'email': email},
      );

      return const Success(null);
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(AppError(message: 'Đã sảy ra lỗi không mong muốn.'));
    }
  }

  Future<Result<void>> verifyEmailOtp({
    required String email,
    required String otpCode,
  }) async {
    try {
      await _apiService.post(
        ApiConstants.verifyEmail,
        data: {'email': email, 'otpCode': otpCode},
      );

      return const Success(null);
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(AppError(message: 'Đã sảy ra lỗi không mong muốn.'));
    }
  }

  Future<Result<void>> verifyResetOtp({
    required String email,
    required String otpCode,
  }) async {
    try {
      await _apiService.post(
        ApiConstants.verifyOtp,
        data: {'email': email, 'otpCode': otpCode},
      );

      return const Success(null);
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(AppError(message: 'Đã sảy ra lỗi không mong muốn.'));
    }
  }

  Future<Result<void>> setNewPassword({
    required String email,
    required String otpCode,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _apiService.post(
        ApiConstants.setNewPassword,
        data: {
          'email': email,
          'otpCode': otpCode,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );

      return const Success(null);
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(AppError(message: 'Đã sảy ra lỗi không mong muốn.'));
    }
  }

  Future<Result<UserModel>> profile() async {
    try {
      final response = await _apiService.get(ApiConstants.profile);
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        final data = raw['data'] ?? raw['Data'] ?? raw;
        if (data is Map<String, dynamic>) {
          return Success(UserModel.fromJson(data));
        }
      }
      return const Failure(
        AppError(message: 'Không thể đọc dữ liệu người dùng.'),
      );
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(AppError(message: 'Đã sảy ra lỗi không mong muốn.'));
    }
  }

  AppError _mapDioException(DioException error) {
    final responseData = error.response?.data;
    final message = responseData is Map<String, dynamic>
        ? (responseData['message'] ??
                  responseData['Message'] ??
                  'không thấy thông báo lỗi cụ thể nào')
              .toString()
        : 'Không thể kết nối đến hệ thống';

    return AppError(message: message, statusCode: error.response?.statusCode);
  }
}
