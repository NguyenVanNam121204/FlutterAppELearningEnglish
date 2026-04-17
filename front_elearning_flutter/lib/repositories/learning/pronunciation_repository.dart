import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../models/learning/pronunciation_models.dart';
import '../../services/api_service.dart';

class PronunciationRepository {
  PronunciationRepository(this._apiService);

  final ApiService _apiService;

  Future<Result<List<PronunciationItemModel>>> pronunciationList(
    String moduleId,
  ) async {
    try {
      final response = await _apiService.get(
        ApiConstants.userPronunciationsByModule(moduleId),
      );
      final list = _asList(response.data);
      return Success(list.map(PronunciationItemModel.fromJson).toList());
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(AppError(message: 'Unable to load pronunciations.'));
    }
  }

  Future<Result<ModulePronunciationSummaryModel>> moduleSummary(
    String moduleId,
  ) async {
    try {
      final response = await _apiService.get(
        ApiConstants.userPronunciationSummaryByModule(moduleId),
      );
      return Success(
        ModulePronunciationSummaryModel.fromJson(_asMap(response.data)),
      );
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(
        AppError(message: 'Unable to load pronunciation summary.'),
      );
    }
  }

  Future<Result<PronunciationAssessmentResultModel>> assessPronunciation({
    required int flashCardId,
    required String filePath,
    required String fileName,
    double? durationInSeconds,
  }) async {
    try {
      MultipartFile audioFile;
      if (kIsWeb) {
        final resp = await Dio().get<List<int>>(
          filePath,
          options: Options(responseType: ResponseType.bytes),
        );
        audioFile = MultipartFile.fromBytes(resp.data!, filename: fileName);
      } else {
        audioFile = await MultipartFile.fromFile(filePath, filename: fileName);
      }

      final formData = FormData.fromMap({
        'file': audioFile,
      });

      final uploadResponse = await _apiService.post(
        ApiConstants.sharedTempFile,
        data: formData,
        queryParameters: {'BucketName': 'pronunciations', 'TempFolder': 'temp'},
      );

      final tempKey = _extractTempKey(uploadResponse.data);
      if (tempKey.isEmpty) {
        return const Failure(
          AppError(message: 'Upload pronunciation audio failed.'),
        );
      }

      final uploadMeta = _extractUploadMeta(uploadResponse.data);
      final fallbackAudioType = _guessAudioTypeFromFileName(fileName);
      final fallbackAudioSize = await _safeReadFileSize(filePath);

      final payload = <String, dynamic>{
        'FlashCardId': flashCardId,
        'AudioTempKey': tempKey,
      };
      final audioType = uploadMeta.audioType.isNotEmpty
          ? uploadMeta.audioType
          : fallbackAudioType;
      if (audioType.isNotEmpty && audioType.length <= 50) {
        payload['AudioType'] = audioType;
      }
      final audioSize = uploadMeta.audioSize ?? fallbackAudioSize;
      if (audioSize != null && audioSize > 0) {
        payload['AudioSize'] = audioSize;
      }
      if (durationInSeconds != null && durationInSeconds > 0) {
        payload['DurationInSeconds'] = durationInSeconds;
      }

      final response = await _apiService.post(
        ApiConstants.userPronunciationAssess,
        data: payload,
      );
      final resultMap = _asMap(response.data);
      if (resultMap.isEmpty) {
        return const Failure(AppError(message: 'Invalid assessment response.'));
      }

      return Success(PronunciationAssessmentResultModel.fromJson(resultMap));
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(
        AppError(message: 'Unable to assess pronunciation.'),
      );
    }
  }

  String _extractTempKey(Object? raw) {
    if (raw is! Map<String, dynamic>) return '';

    final data = raw['data'] ?? raw['Data'] ?? raw;
    if (data is Map<String, dynamic>) {
      return (data['tempKey'] ?? data['TempKey'] ?? '').toString();
    }
    return '';
  }

  ({String audioType, int? audioSize}) _extractUploadMeta(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      return (audioType: '', audioSize: null);
    }

    final data = raw['data'] ?? raw['Data'] ?? raw;
    if (data is! Map<String, dynamic>) {
      return (audioType: '', audioSize: null);
    }

    final audioType =
        (data['AudioType'] ??
                data['audioType'] ??
                data['ImageType'] ??
                data['imageType'] ??
                '')
            .toString();
    final audioSize = int.tryParse(
      (data['AudioSize'] ??
              data['audioSize'] ??
              data['ImageSize'] ??
              data['imageSize'] ??
              '')
          .toString(),
    );

    return (audioType: audioType, audioSize: audioSize);
  }

  String _guessAudioTypeFromFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.m4a')) return 'audio/m4a';
    if (lower.endsWith('.mp3')) return 'audio/mpeg';
    if (lower.endsWith('.wav')) return 'audio/wav';
    if (lower.endsWith('.webm')) return 'audio/webm';
    if (lower.endsWith('.ogg')) return 'audio/ogg';
    return '';
  }

  Future<int?> _safeReadFileSize(String filePath) async {
    if (kIsWeb) return null;
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      return await file.length();
    } catch (_) {
      return null;
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
