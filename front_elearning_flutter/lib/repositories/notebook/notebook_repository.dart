import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../models/notebook/notebook_models.dart';
import '../../services/api_service.dart';

class NotebookRepository {
  NotebookRepository(this._apiService);

  final ApiService _apiService;

  Future<Result<List<NotebookModel>>> notebookVocabulary() async {
    try {
      final response = await _apiService.get(ApiConstants.vocabularyNotebook);
      return Success(_asNotebookList(response.data));
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(
        AppError(message: 'Unable to load vocabulary notebook.'),
      );
    }
  }

  List<NotebookModel> _asNotebookList(Object? raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'] ?? raw['Data'] ?? raw;
      List<dynamic>? items;

      if (data is Map<String, dynamic>) {
        items = (data['flashCards'] ?? data['FlashCards']) as List<dynamic>?;
      } else if (data is List) {
        items = data;
      }

      if (items != null) {
        return items
            .whereType<Map<String, dynamic>>()
            .map(NotebookModel.fromJson)
            .toList();
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
