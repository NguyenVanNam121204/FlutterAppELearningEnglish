import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../models/notification/notification_model.dart';
import '../../services/api_service.dart';

class NotificationRepository {
  NotificationRepository(this._apiService);

  final ApiService _apiService;

  Future<Result<List<NotificationItemModel>>> notifications() async {
    try {
      final response = await _apiService.get(ApiConstants.notifications);
      return Success(_asList(response.data));
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(AppError(message: 'Unable to load notifications.'));
    }
  }

  Future<Result<int>> unreadCount() async {
    try {
      final response = await _apiService.get(
        ApiConstants.notificationsUnreadCount,
      );
      return Success(_asInt(response.data));
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(
        AppError(message: 'Unable to load unread notification count.'),
      );
    }
  }

  Future<Result<void>> markAsRead(String id) async {
    try {
      await _apiService.put(ApiConstants.notificationMarkAsRead(id));
      return const Success(null);
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(
        AppError(message: 'Unable to mark notification as read.'),
      );
    }
  }

  Future<Result<void>> markAllRead() async {
    try {
      await _apiService.put('${ApiConstants.notifications}/mark-all-read');
      return const Success(null);
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(
        AppError(message: 'Unable to mark all notifications as read.'),
      );
    }
  }

  List<NotificationItemModel> _asList(Object? raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'] ?? raw['Data'] ?? const [];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(NotificationItemModel.fromJson)
            .toList();
      }
    }
    return const [];
  }

  int _asInt(Object? raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'] ?? raw['Data'] ?? raw['count'] ?? raw['Count'];
      if (data is int) return data;
      if (data is String) return int.tryParse(data) ?? 0;
      if (data is double) return data.toInt();
    }
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw) ?? 0;
    if (raw is double) return raw.toInt();
    return 0;
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
