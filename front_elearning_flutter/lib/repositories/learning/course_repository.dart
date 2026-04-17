import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../models/learning/course_models.dart';
import '../../services/api_service.dart';

class CourseRepository {
  CourseRepository(this._apiService);

  final ApiService _apiService;

  Future<Result<CourseDetailModel>> courseDetail(String courseId) async {
    try {
      final response = await _apiService.get(
        ApiConstants.userCourseDetail(courseId),
      );
      return Success(CourseDetailModel.fromJson(_asMap(response.data)));
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(AppError(message: 'Unable to load course detail.'));
    }
  }

  Future<Result<List<LearningCourseItem>>> searchCourses(String keyword) async {
    try {
      final response = await _apiService.get(
        ApiConstants.userSearchCourses,
        queryParameters: {'keyword': keyword},
      );
      return Success(
        _asList(response.data).map(LearningCourseItem.fromJson).toList(),
      );
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(AppError(message: 'Unable to search courses.'));
    }
  }

  Map<String, dynamic> _asMap(Object? raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'] ?? raw['Data'] ?? raw;
      if (data is Map<String, dynamic>) return data;
      return raw;
    }
    return const {};
  }

  List<Map<String, dynamic>> _asList(Object? raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'] ?? raw['Data'] ?? raw['items'] ?? raw['Items'];
      if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    } else if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
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
