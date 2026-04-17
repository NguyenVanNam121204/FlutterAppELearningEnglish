import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router/route_paths.dart';
import '../../../core/result/result.dart';
import '../../../models/payment/payment_models.dart';

class PaymentSuccessScreen extends ConsumerStatefulWidget {
  const PaymentSuccessScreen({
    required this.paymentId,
    this.courseId = '',
    this.orderCode = '',
    super.key,
  });
  final String paymentId;
  final String courseId;
  final String orderCode;

  @override
  ConsumerState<PaymentSuccessScreen> createState() =>
      _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends ConsumerState<PaymentSuccessScreen> {
  bool _loading = true;
  bool _enrolled = false;
  bool _isPackage = false;
  String _resolvedCourseId = '';
  String _error = '';

  @override
  void initState() {
    super.initState();
    _confirm();
  }

  Future<void> _confirm() async {
    if (widget.paymentId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Không tìm thấy thông tin thanh toán';
      });
      return;
    }
    final confirm = await ref
        .read(paymentFeatureViewModelProvider)
        .confirmPayment(widget.paymentId);
    if (confirm case Failure(:final error)) {
      setState(() {
        _loading = false;
        _error = error.message;
      });
      return;
    }
    final detail = await ref
        .read(paymentFeatureViewModelProvider)
        .paymentHistory();
    if (detail case Success(:final value)) {
      final found = value.firstWhere(
        (e) => e.paymentId == widget.paymentId,
        orElse: () => const PaymentHistoryItemModel(
          paymentId: '',
          productId: '',
          orderCode: '',
          amount: '',
          status: '',
          productType: '',
          createdAt: '',
        ),
      );
      final productType = found.productType;
      final productId = found.productId;
      if (productType == '2') {
        _isPackage = true;
      }
      if (productType == '1' && productId.isNotEmpty) {
        _resolvedCourseId = productId;
        final enroll = await ref
            .read(paymentFeatureViewModelProvider)
            .enrollCourse(productId);
        _enrolled = enroll is Success<dynamic>;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment Success')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 64),
                const SizedBox(height: 12),
                Text(_error, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context.go(RoutePaths.mainAppHome),
                  child: const Text('Ve trang chu'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Success')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 12),
            Text('PaymentId: ${widget.paymentId}'),
            const SizedBox(height: 8),
            const Text('Thanh toán thành công'),
            if (widget.orderCode.isNotEmpty)
              Text('Mã giao dịch: ${widget.orderCode}'),
            if (_isPackage) const Text('Gói giáo viên đã được kích hoạt'),
            if (_enrolled) const Text('Bạn đã được đăng ký vào khóa học!'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                final cid = widget.courseId.isNotEmpty
                    ? widget.courseId
                    : _resolvedCourseId;
                if (cid.isNotEmpty) {
                  context.go(RoutePaths.courseInCourses(cid));
                } else if (_isPackage) {
                  context.go(RoutePaths.mainAppHome);
                } else {
                  context.go(RoutePaths.mainAppHome);
                }
              },
              child: Text(
                _enrolled
                    ? 'Xem khóa học'
                    : (_isPackage ? 'Đến trang cá nhân' : 'Về trang chủ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
