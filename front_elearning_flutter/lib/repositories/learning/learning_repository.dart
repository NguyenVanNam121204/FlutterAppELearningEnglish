import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../models/learning/course_models.dart';
import '../../services/api_service.dart';

class LearningRepository {
  LearningRepository(this._apiService);

  final ApiService _apiService;

  Future<Result<void>> pingSystemCourses() async {
    try {
      await _apiService.get(ApiConstants.systemCourses);
      return const Success(null);
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(AppError(message: 'Unable to load system courses.'));
    }
  }

  Future<Result<List<LearningVocabularyItem>>> notebookVocabulary() async {
    try {
      final response = await _apiService.get(ApiConstants.vocabularyNotebook);
      return Success(_asVocabularyList(response.data));
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(
        AppError(message: 'Unable to load vocabulary notebook.'),
      );
    }
  }

  Future<Result<List<LearningCourseItem>>> myCourses({
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConstants.myEnrolledCourses,
        queryParameters: {'pageNumber': pageNumber, 'pageSize': pageSize},
      );
      return Success(_asCourseItems(response.data));
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(AppError(message: 'Unable to load your courses.'));
    }
  }

  List<LearningVocabularyItem> _asVocabularyList(Object? raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'] ?? raw['Data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(LearningVocabularyItem.fromJson)
            .toList();
      }
    } else if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(LearningVocabularyItem.fromJson)
          .toList();
    }
    return const [];
  }

  List<LearningCourseItem> _asCourseItems(Object? raw) {
    if (raw is Map<String, dynamic>) {
      final payload = raw['data'] ?? raw['Data'];
      if (payload is Map<String, dynamic>) {
        final items = payload['items'] ?? payload['Items'] ?? const [];
        if (items is List) {
          return items
              .whereType<Map<String, dynamic>>()
              .map(LearningCourseItem.fromJson)
              .toList();
        }
      }
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
