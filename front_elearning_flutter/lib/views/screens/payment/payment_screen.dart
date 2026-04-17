import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router/route_paths.dart';
import '../../../viewmodels/payment/payment_screen_viewmodel.dart';
import '../../widgets/common/catalunya_scaffold.dart';
import '../../widgets/payment/payment_checkout_panel.dart';
import '../../widgets/payment/payment_create_controls.dart';
import '../../widgets/payment/payment_product_summary_card.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({
    required this.paymentId,
    this.courseId = '',
    this.courseTitle = '',
    this.packageId = '',
    this.packageName = '',
    this.price = '',
    super.key,
  });
  final String paymentId;
  final String courseId;
  final String courseTitle;
  final String packageId;
  final String packageName;
  final String price;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final TextEditingController _productIdController = TextEditingController();
  late final PaymentScreenArgs _args;

  @override
  void initState() {
    super.initState();
    _args = PaymentScreenArgs(
      paymentId: widget.paymentId,
      courseId: widget.courseId,
      packageId: widget.packageId,
    );
    _productIdController.addListener(() {
      ref
          .read(paymentScreenViewModelProvider(_args).notifier)
          .setProductIdInput(_productIdController.text);
    });
  }

  @override
  void dispose() {
    _productIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentScreenViewModelProvider(_args));
    final notifier = ref.read(paymentScreenViewModelProvider(_args).notifier);
    if (_productIdController.text != state.productIdInput) {
      _productIdController.text = state.productIdInput;
    }
    ref.listen(paymentScreenViewModelProvider(_args), (prev, next) {
      final becameSuccess =
          prev?.status != 'Thanh toan thanh cong' &&
          next.status == 'Thanh toan thanh cong' &&
          next.paymentId.isNotEmpty;
      if (becameSuccess) {
        context.push(
          '${RoutePaths.paymentSuccess}?paymentId=${next.paymentId}&orderCode=${next.paymentId}',
        );
      }
    });

    return CatalunyaScaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            PaymentProductSummaryCard(
              courseTitle: widget.courseTitle,
              packageName: widget.packageName,
              price: widget.price,
            ),
            if (widget.courseTitle.isNotEmpty || widget.packageName.isNotEmpty)
              const SizedBox(height: 12),
            PaymentCreateControls(
              controller: _productIdController,
              state: state,
              onTypeChanged: notifier.setTypeProduct,
              onCreatePayment: notifier.createPayment,
              onConfirmPayment: notifier.confirmPayment,
            ),
            PaymentCheckoutPanel(
              status: state.status,
              payUrl: state.payUrl,
              paymentId: state.paymentId,
              onCopyLink: () async {
                await Clipboard.setData(ClipboardData(text: state.payUrl));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép link')),
                );
              },
              onTestSuccess: () => context.push(
                '${RoutePaths.paymentSuccess}?paymentId=${state.paymentId}&orderCode=${state.paymentId}',
              ),
              onTestFailed: () => context.push(
                '${RoutePaths.paymentFailed}?reason=Thanh+toan+khong+thanh+cong',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

