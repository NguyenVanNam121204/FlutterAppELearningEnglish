import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import 'auth_session_service.dart';
import 'secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this._secureStorageService,
    this._dio,
    this._refreshDio,
    this._authSessionService,
  );

  final SecureStorageService _secureStorageService;
  final Dio _dio;
  final Dio _refreshDio;
  final AuthSessionService _authSessionService;

  Future<String?>? _refreshingAccessToken;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorageService.getAccessToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final requestOptions = err.requestOptions;

    if (statusCode != 401 || requestOptions.path == ApiConstants.refreshToken) {
      handler.next(err);
      return;
    }

    final alreadyRetried = requestOptions.extra['retriedAfterRefresh'] == true;
    if (alreadyRetried) {
      await _expireSession();
      handler.next(err);
      return;
    }

    final newAccessToken = await _getOrRefreshAccessToken();
    if (newAccessToken == null || newAccessToken.isEmpty) {
      _authSessionService.notifySessionExpired();
      handler.next(err);
      return;
    }

    try {
      final retriedRequest = requestOptions.copyWith(
        headers: Map<String, dynamic>.from(requestOptions.headers)
          ..['Authorization'] = 'Bearer $newAccessToken',
        extra: Map<String, dynamic>.from(requestOptions.extra)
          ..['retriedAfterRefresh'] = true,
      );

      final response = await _dio.fetch<dynamic>(retriedRequest);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<String?> _getOrRefreshAccessToken() {
    final inFlight = _refreshingAccessToken;
    if (inFlight != null) {
      return inFlight;
    }

    final refreshFuture = _refreshAccessToken();
    _refreshingAccessToken = refreshFuture;

    refreshFuture.whenComplete(() {
      if (identical(_refreshingAccessToken, refreshFuture)) {
        _refreshingAccessToken = null;
      }
    });

    return refreshFuture;
  }

  Future<String?> _refreshAccessToken() async {
    final accessToken = await _secureStorageService.getAccessToken();
    final refreshToken = await _secureStorageService.getRefreshToken();

    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      await _expireSession();
      return null;
    }

    try {
      final response = await _refreshDio.post<dynamic>(
        ApiConstants.refreshToken,
        data: {'accessToken': accessToken, 'refreshToken': refreshToken},
      );

      final responseData = response.data;
      if (responseData is! Map<String, dynamic>) {
        await _expireSession();
        return null;
      }

      final payload =
          (responseData['data'] as Map<String, dynamic>?) ?? responseData;

      final newAccessToken =
          (payload['accessToken'] ?? payload['AccessToken'] ?? '').toString();
      final newRefreshToken =
          (payload['refreshToken'] ?? payload['RefreshToken'] ?? '').toString();

      if (newAccessToken.isEmpty || newRefreshToken.isEmpty) {
        await _expireSession();
        return null;
      }

      await _secureStorageService.saveAccessToken(newAccessToken);
      await _secureStorageService.saveRefreshToken(newRefreshToken);

      return newAccessToken;
    } on DioException {
      await _expireSession();
      return null;
    }
  }

  Future<void> _expireSession() async {
    await _secureStorageService.clearAuth();
    _authSessionService.notifySessionExpired();
  }
}
