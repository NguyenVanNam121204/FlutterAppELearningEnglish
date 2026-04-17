import '../../core/result/result.dart';
import '../../models/payment/payment_models.dart';
import '../../repositories/payment/payment_repository.dart';

class PaymentFeatureViewModel {
  PaymentFeatureViewModel(this._repository);

  final PaymentRepository _repository;

  Future<Result<PaymentLinkModel>> createPaymentAndLink({
    required int productId,
    required int typeProduct,
  }) async {
    return _repository.createPaymentAndLink(
      productId: productId,
      typeProduct: typeProduct,
    );
  }

  Future<Result<void>> confirmPayment(String paymentId) async {
    return _repository.confirmPayment(paymentId);
  }

  Future<Result<void>> enrollCourse(String courseId) async {
    return _repository.enrollCourse(courseId);
  }

  Future<Result<List<PaymentHistoryItemModel>>> paymentHistory() async {
    return _repository.paymentHistory();
  }
}
