import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../core/constants/api_constants.dart';
import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../models/user/user_model.dart';
import '../../services/api_service.dart';

class ProfileRepository {
  ProfileRepository(this._apiService);

  final ApiService _apiService;

  Future<Result<UserModel>> profile() async {
    try {
      final response = await _apiService.get(ApiConstants.profile);
      return Success(_asModel(response.data));
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(AppError(message: 'Unable to load profile.'));
    }
  }

  Future<Result<UserModel>> updateProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    try {
      await _apiService.put(
        ApiConstants.updateProfile,
        data: {
          'FirstName': firstName,
          'LastName': lastName,
          'PhoneNumber': phoneNumber,
        },
      );

      return profile();
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(AppError(message: 'Unable to update profile.'));
    }
  }

  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _apiService.put(
        ApiConstants.changePassword,
        data: {'CurrentPassword': currentPassword, 'NewPassword': newPassword},
      );
      return const Success(null);
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(AppError(message: 'Unable to change password.'));
    }
  }

  Future<Result<UserModel>> updateAvatar({
    required String filePath,
    required String fileName,
  }) async {
    try {
      MultipartFile avatarFile;
      if (kIsWeb) {
        final resp = await Dio().get<List<int>>(
          filePath,
          options: Options(responseType: ResponseType.bytes),
        );
        final bytes = resp.data;
        if (bytes == null || bytes.isEmpty) {
          return const Failure(AppError(message: 'Upload avatar failed.'));
        }
        avatarFile = MultipartFile.fromBytes(bytes, filename: fileName);
      } else {
        avatarFile = await MultipartFile.fromFile(filePath, filename: fileName);
      }

      final formData = FormData.fromMap({'file': avatarFile});

      final uploadResponse = await _apiService.post(
        ApiConstants.sharedTempFile,
        data: formData,
        queryParameters: {'bucketName': 'avatars', 'tempFolder': 'temp'},
      );

      final tempKey = _extractTempKey(uploadResponse.data);
      if (tempKey.isEmpty) {
        return const Failure(AppError(message: 'Upload avatar failed.'));
      }

      await _apiService.put(
        ApiConstants.profileAvatar,
        data: {'avatarTempKey': tempKey},
      );

      return profile();
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(AppError(message: 'Unable to update avatar.'));
    }
  }

  UserModel _asModel(Object? raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'] ?? raw['Data'] ?? raw;
      if (data is Map<String, dynamic>) return UserModel.fromJson(data);
      return UserModel.fromJson(raw);
    }
    return const UserModel(id: '', fullName: '-', email: '-');
  }

  String _extractTempKey(Object? raw) {
    if (raw is! Map<String, dynamic>) return '';

    final data = raw['data'] ?? raw['Data'] ?? raw;
    if (data is Map<String, dynamic>) {
      return (data['tempKey'] ?? data['TempKey'] ?? '').toString();
    }
    return '';
  }

  AppError _mapDioException(DioException error) {
    final responseData = error.response?.data;
    final message = responseData is Map<String, dynamic>
        ? (responseData['message'] ??
                  responseData['Message'] ??
                  'Unable to connect to server')
              .toString()
        : 'Unable to connect to server';
    return AppError(message: message, statusCode: error.response?.statusCode);
  }
}
