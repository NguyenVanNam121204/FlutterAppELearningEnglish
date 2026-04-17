import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../models/learning/lesson_models.dart';
import '../../services/api_service.dart';

class LessonRepository {
  LessonRepository(this._apiService);

  final ApiService _apiService;

  Future<Result<List<LessonListItemModel>>> lessonsByCourse(
    String courseId,
  ) async {
    try {
      final response = await _apiService.get(
        ApiConstants.userLessonsByCourse(courseId),
      );
      final lessons =
          _asList(response.data).map(LessonListItemModel.fromJson).toList()
            ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      return Success(lessons);
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(
        AppError(message: 'Unable to load lessons by course.'),
      );
    }
  }

  Future<Result<LessonDetailBundleModel>> lessonDetailBundle(
    String lessonId,
  ) async {
    try {
      final lessonResponse = await _apiService.get(
        ApiConstants.userLessonDetail(lessonId),
      );
      final modulesResponse = await _apiService.get(
        ApiConstants.userModulesByLesson(lessonId),
      );
      return Success(
        LessonDetailBundleModel(
          lesson: LessonDetailModel.fromJson(_asMap(lessonResponse.data)),
          modules:
              _asList(
                  modulesResponse.data,
                ).map(LessonModuleItemModel.fromJson).toList()
                ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex)),
        ),
      );
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(AppError(message: 'Unable to load lesson detail.'));
    }
  }

  Future<Result<LessonResultModel>> lessonResult(String attemptId) async {
    try {
      final response = await _apiService.get(
        ApiConstants.quizAttemptResult(attemptId),
      );
      return Success(LessonResultModel.fromJson(_asMap(response.data)));
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(AppError(message: 'Unable to load lesson result.'));
    }
  }

  Future<Result<void>> startModule(String moduleId) async {
    try {
      await _apiService.post(ApiConstants.userStartModule(moduleId));
      return const Success(null);
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(AppError(message: 'Unable to start module.'));
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
