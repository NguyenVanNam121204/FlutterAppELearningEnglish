import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../models/assignment/assignment_models.dart';
import '../../services/api_service.dart';

class AssignmentRepository {
  AssignmentRepository(this._apiService);

  final ApiService _apiService;

  Future<Result<AssignmentDetailModel>> assignmentDetail({
    required String assessmentId,
    required String moduleId,
  }) async {
    try {
      if (assessmentId.isEmpty) {
        final response = await _apiService.get(
          ApiConstants.userAssessmentsByModule(moduleId),
        );
        final list = _asList(response.data)
            .map(AssignmentAssessmentItemModel.fromJson)
            .where((item) => item.assessmentId.isNotEmpty)
            .where((item) => item.isPublished)
            .toList();

        return Success(
          AssignmentDetailModel(
            assessments: list,
            quizzes: const [],
            essays: const [],
          ),
        );
      }

      final quizzesResponse = await _apiService.get(
        ApiConstants.quizzesByAssessment(assessmentId),
      );
      final essaysResponse = await _apiService.get(
        ApiConstants.userEssaysByAssessment(assessmentId),
      );

      final quizzes = _asList(quizzesResponse.data)
          .map(AssignmentQuizItemModel.fromJson)
          .where((item) => item.quizId.isNotEmpty)
          .toList();
      final essays = _asList(essaysResponse.data)
          .map(AssignmentEssayItemModel.fromJson)
          .where((item) => item.essayId.isNotEmpty)
          .toList();

      return Success(
        AssignmentDetailModel(
          assessments: const [],
          quizzes: quizzes,
          essays: essays,
        ),
      );
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(
        AppError(message: 'Unable to load assignment detail.'),
      );
    }
  }

  Future<Result<EssayDetailModel>> essayDetail(String essayId) async {
    try {
      final response = await _apiService.get(
        ApiConstants.userEssayDetail(essayId),
      );
      return Success(EssayDetailModel.fromJson(_asMap(response.data)));
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(AppError(message: 'Unable to load essay detail.'));
    }
  }

  Future<Result<void>> submitEssay({
    required String essayId,
    required String content,
  }) async {
    try {
      await _apiService.post(
        ApiConstants.userEssaySubmissionsSubmit,
        data: {
          'EssayId': int.tryParse(essayId) ?? essayId,
          'TextContent': content,
        },
      );
      return const Success(null);
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(AppError(message: 'Unable to submit essay.'));
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
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }
    }

    if (raw is List) {
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
