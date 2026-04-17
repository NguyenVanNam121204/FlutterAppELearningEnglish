import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/result/result.dart';
import 'payment_feature_viewmodel.dart';

class PaymentScreenArgs {
  const PaymentScreenArgs({
    required this.paymentId,
    required this.courseId,
    required this.packageId,
  });

  final String paymentId;
  final String courseId;
  final String packageId;
}

class PaymentScreenState {
  const PaymentScreenState({
    this.productIdInput = '',
    this.typeProduct = 1,
    this.isLoading = false,
    this.isConfirming = false,
    this.payUrl = '',
    this.paymentId = '',
    this.status = '',
  });

  final String productIdInput;
  final int typeProduct;
  final bool isLoading;
  final bool isConfirming;
  final String payUrl;
  final String paymentId;
  final String status;

  PaymentScreenState copyWith({
    String? productIdInput,
    int? typeProduct,
    bool? isLoading,
    bool? isConfirming,
    String? payUrl,
    String? paymentId,
    String? status,
  }) {
    return PaymentScreenState(
      productIdInput: productIdInput ?? this.productIdInput,
      typeProduct: typeProduct ?? this.typeProduct,
      isLoading: isLoading ?? this.isLoading,
      isConfirming: isConfirming ?? this.isConfirming,
      payUrl: payUrl ?? this.payUrl,
      paymentId: paymentId ?? this.paymentId,
      status: status ?? this.status,
    );
  }
}

class PaymentScreenViewModel extends StateNotifier<PaymentScreenState> {
  PaymentScreenViewModel(this._feature) : super(const PaymentScreenState());

  final PaymentFeatureViewModel _feature;
  Timer? _polling;
  bool _initialized = false;

  @override
  void dispose() {
    _polling?.cancel();
    super.dispose();
  }

  Future<void> initialize(PaymentScreenArgs args) async {
    if (_initialized) return;
    _initialized = true;

    if (args.paymentId.isNotEmpty) {
      state = state.copyWith(
        paymentId: args.paymentId,
        status: 'Da nhan paymentId tu callback',
      );
      _startPolling();
      return;
    }
    if (args.courseId.isNotEmpty) {
      state = state.copyWith(productIdInput: args.courseId, typeProduct: 1);
      await createPayment();
      return;
    }
    if (args.packageId.isNotEmpty) {
      state = state.copyWith(productIdInput: args.packageId, typeProduct: 2);
      await createPayment();
    }
  }

  void setProductIdInput(String value) {
    state = state.copyWith(productIdInput: value);
  }

  void setTypeProduct(int value) {
    state = state.copyWith(typeProduct: value);
  }

  Future<void> createPayment() async {
    final productId = int.tryParse(state.productIdInput.trim());
    if (productId == null || state.isLoading) return;
    state = state.copyWith(isLoading: true);
    final process = await _feature.createPaymentAndLink(
      productId: productId,
      typeProduct: state.typeProduct,
    );
    switch (process) {
      case Success(:final value):
        final paymentId = value.paymentId;
        if (paymentId.isNotEmpty) {
          state = state.copyWith(
            isLoading: false,
            paymentId: paymentId,
            payUrl: value.checkoutUrl,
            status: 'Da tao link thanh toan',
          );
          _startPolling();
        } else {
          state = state.copyWith(isLoading: false, status: 'Tao link that bai');
        }
      case Failure():
        state = state.copyWith(
          isLoading: false,
          status: 'Khoi tao thanh toan that bai',
        );
    }
  }

  Future<bool> confirmPayment() async {
    if (state.paymentId.isEmpty || state.isConfirming) return false;
    state = state.copyWith(isConfirming: true);
    final res = await _feature.confirmPayment(state.paymentId);
    switch (res) {
      case Success():
        _polling?.cancel();
        state = state.copyWith(
          isConfirming: false,
          status: 'Thanh toan thanh cong',
        );
        return true;
      case Failure(:final error):
        state = state.copyWith(
          isConfirming: false,
          status: 'Dang cho thanh toan: ${error.message}',
        );
        return false;
    }
  }

  void _startPolling() {
    _polling?.cancel();
    _polling = Timer.periodic(
      const Duration(seconds: 3),
      (_) => confirmPayment(),
    );
  }
}

