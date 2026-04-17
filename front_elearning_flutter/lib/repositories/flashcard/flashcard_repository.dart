import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../models/flashcard/flashcard_models.dart';
import '../../services/api_service.dart';

class FlashcardRepository {
  FlashcardRepository(this._apiService);

  final ApiService _apiService;

  Future<Result<List<FlashcardModel>>> lessonFlashcards(String lessonId) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.userFlashcards}/lesson/$lessonId',
      );
      return Success(_asList(response.data));
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(AppError(message: 'Unable to load flashcards.'));
    }
  }

  Future<Result<List<FlashcardModel>>> moduleFlashcards(String moduleId) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.userFlashcards}/module/$moduleId',
      );
      return Success(_asList(response.data));
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(AppError(message: 'Unable to load flashcards.'));
    }
  }

  Future<Result<FlashcardModel>> flashcardById(String flashCardId) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.userFlashcards}/$flashCardId',
      );
      final item = _asItem(response.data);
      if (item == null) {
        return const Failure(
          AppError(message: 'Unable to load flashcard detail.'),
        );
      }
      return Success(item);
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(
        AppError(message: 'Unable to load flashcard detail.'),
      );
    }
  }

  Future<Result<List<FlashcardModel>>> dueReviewCards() async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.userFlashcardReview}/due',
      );
      return Success(_asList(response.data));
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(AppError(message: 'Unable to load review cards.'));
    }
  }

  Future<Result<List<FlashcardModel>>> masteredReviewCards() async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.userFlashcardReview}/mastered',
      );
      return Success(_asList(response.data));
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(AppError(message: 'Unable to load mastered cards.'));
    }
  }

  Future<Result<Map<String, dynamic>>> reviewStatistics() async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.userFlashcardReview}/statistics',
      );
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        final data = raw['data'] ?? raw['Data'] ?? raw;
        if (data is Map<String, dynamic>) {
          return Success(data);
        }
      }
      return const Success({});
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(
        AppError(message: 'Unable to load review statistics.'),
      );
    }
  }

  Future<Result<void>> reviewCard({
    required String flashCardId,
    required int quality,
  }) async {
    try {
      await _apiService.post(
        '${ApiConstants.userFlashcardReview}/review',
        data: {'FlashCardId': flashCardId, 'Quality': quality},
      );
      return const Success(null);
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(AppError(message: 'Unable to review flashcard.'));
    }
  }

  Future<Result<void>> startLearningModule(String moduleId) async {
    try {
      await _apiService.post(
        ApiConstants.userFlashcardReviewStartModule(moduleId),
      );
      return const Success(null);
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(
        AppError(message: 'Unable to start flashcard review module.'),
      );
    }
  }

  List<FlashcardModel> _asList(Object? raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'] ?? raw['Data'] ?? raw;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(FlashcardModel.fromJson)
            .toList();
      }
      if (data is Map<String, dynamic>) {
        final cards = data['flashCards'] ?? data['cards'] ?? data['data'];
        if (cards is List) {
          return cards
              .whereType<Map<String, dynamic>>()
              .map(FlashcardModel.fromJson)
              .toList();
        }
      }
    } else if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(FlashcardModel.fromJson)
          .toList();
    }
    return const [];
  }

  FlashcardModel? _asItem(Object? raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'] ?? raw['Data'] ?? raw;
      if (data is Map<String, dynamic>) {
        return FlashcardModel.fromJson(data);
      }
    }
    return null;
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
