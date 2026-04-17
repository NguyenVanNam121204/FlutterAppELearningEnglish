import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../models/payment/payment_models.dart';
import '../../services/api_service.dart';

class PaymentRepository {
  PaymentRepository(this._apiService);

  final ApiService _apiService;

  Future<Result<PaymentLinkModel>> createPaymentAndLink({
    required int productId,
    required int typeProduct,
  }) async {
    try {
      final processResponse = await _apiService.post(
        ApiConstants.paymentProcess,
        data: {
          'ProductId': productId,
          'typeproduct': typeProduct,
          'IdempotencyKey': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      final processMap = _asMap(processResponse.data);
      final paymentId =
          (processMap['paymentId'] ?? processMap['PaymentId'] ?? '').toString();
      if (paymentId.isEmpty) {
        return const Success(PaymentLinkModel(paymentId: '', checkoutUrl: ''));
      }

      final linkResponse = await _apiService.post(
        ApiConstants.payOsCreateLink(paymentId),
      );
      final linkMap = _asMap(linkResponse.data);

      return Success(
        PaymentLinkModel(
          paymentId: paymentId,
          checkoutUrl:
              (linkMap['checkoutUrl'] ??
                      linkMap['CheckoutUrl'] ??
                      linkMap['url'] ??
                      '')
                  .toString(),
        ),
      );
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(AppError(message: 'Unable to create payment link.'));
    }
  }

  Future<Result<void>> confirmPayment(String paymentId) async {
    try {
      await _apiService.post(ApiConstants.payOsConfirm(paymentId));
      return const Success(null);
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(AppError(message: 'Unable to confirm payment.'));
    }
  }

  Future<Result<void>> enrollCourse(String courseId) async {
    try {
      await _apiService.post(
        ApiConstants.enrollCourse,
        data: {'courseId': int.tryParse(courseId) ?? courseId},
      );
      return const Success(null);
    } on DioException catch (_) {
      try {
        await _apiService.post(
          ApiConstants.enrollCourse,
          data: {'CourseId': int.tryParse(courseId) ?? courseId},
        );
        return const Success(null);
      } on DioException catch (error) {
        return Failure(_mapDioException(error));
      } catch (_) {
        return const Failure(AppError(message: 'Unable to enroll course.'));
      }
    } catch (_) {
      return const Failure(AppError(message: 'Unable to enroll course.'));
    }
  }

  Future<Result<List<PaymentHistoryItemModel>>> paymentHistory() async {
    try {
      final response = await _apiService.get(
        ApiConstants.paymentHistory,
        queryParameters: {'pageNumber': 1, 'pageSize': 20},
      );
      return Success(_asList(response.data));
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(
        AppError(message: 'Unable to load payment history.'),
      );
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

  List<PaymentHistoryItemModel> _asList(Object? raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'] ?? raw['Data'];
      if (data is Map<String, dynamic>) {
        final items = data['items'] ?? data['Items'];
        if (items is List) {
          return items
              .whereType<Map<String, dynamic>>()
              .map(PaymentHistoryItemModel.fromJson)
              .toList();
        }
      }
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(PaymentHistoryItemModel.fromJson)
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
