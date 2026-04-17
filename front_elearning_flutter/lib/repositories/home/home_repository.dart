import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../models/home/home_course_model.dart';
import '../../models/streak/streak_model.dart';
import '../../services/api_service.dart';

class HomeRepository {
  HomeRepository(this._apiService);

  final ApiService _apiService;

  Future<Result<List<HomeCourseModel>>> getSuggestedCourses() async {
    try {
      final response = await _apiService.get(ApiConstants.systemCourses);
      final data = response.data as Map<String, dynamic>;
      final rawList = (data['data'] as List<dynamic>?) ?? const [];

      final courses = rawList
          .map(
            (item) =>
                HomeCourseModel.fromSystemJson(item as Map<String, dynamic>),
          )
          .toList();

      return Success(courses);
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(
        AppError(message: 'Không thể tải dữ liệu khóa học đề xuất.'),
      );
    }
  }

  Future<Result<List<HomeCourseModel>>> getMyCourses({
    int pageNumber = 1,
    int pageSize = 8,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConstants.myEnrolledCourses,
        queryParameters: {'pageNumber': pageNumber, 'pageSize': pageSize},
      );

      final data = response.data as Map<String, dynamic>;
      final paged = (data['data'] as Map<String, dynamic>?) ?? const {};
      final rawItems =
          (paged['items'] ?? paged['Items'] ?? <dynamic>[]) as List<dynamic>;

      final courses = rawItems
          .map(
            (item) =>
                HomeCourseModel.fromEnrolledJson(item as Map<String, dynamic>),
          )
          .toList();

      return Success(courses);
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(
        AppError(message: 'Không thể tải dữ liệu khóa học của bạn.'),
      );
    }
  }

  Future<Result<StreakModel>> getStreak() async {
    try {
      final response = await _apiService.get(ApiConstants.streak);
      final data = response.data as Map<String, dynamic>;
      final raw = (data['data'] as Map<String, dynamic>?) ?? const {};

      return Success(StreakModel.fromJson(raw));
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(
        AppError(message: 'Không thể tải thông tin streak.'),
      );
    }
  }

  AppError _mapDioException(DioException error) {
    final responseData = error.response?.data;
    final message = responseData is Map<String, dynamic>
        ? (responseData['message'] ??
                  responseData['Message'] ??
                  'Không thể kết nối đến hệ thống')
              .toString()
        : 'Không thể kết nối đến hệ thống';

    return AppError(message: message, statusCode: error.response?.statusCode);
  }
}
