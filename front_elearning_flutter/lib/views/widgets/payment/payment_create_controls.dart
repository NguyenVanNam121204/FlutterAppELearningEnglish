import 'package:flutter/material.dart';

import '../../../viewmodels/payment/payment_screen_viewmodel.dart';

class PaymentCreateControls extends StatelessWidget {
  const PaymentCreateControls({
    required this.controller,
    required this.state,
    required this.onTypeChanged,
    required this.onCreatePayment,
    required this.onConfirmPayment,
    super.key,
  });

  final TextEditingController controller;
  final PaymentScreenState state;
  final ValueChanged<int> onTypeChanged;
  final VoidCallback onCreatePayment;
  final VoidCallback onConfirmPayment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Mã sản phẩm',
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 1, label: Text('Khóa học')),
            ButtonSegment(value: 2, label: Text('Gói giáo viên')),
          ],
          selected: {state.typeProduct},
          onSelectionChanged: (s) => onTypeChanged(s.first),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: state.isLoading ? null : onCreatePayment,
          child: Text(state.isLoading ? 'Đang tạo đơn...' : 'Tạo thanh toán'),
        ),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: (state.isConfirming || state.paymentId.isEmpty)
              ? null
              : onConfirmPayment,
          child: Text(
            state.isConfirming
                ? 'Đang kiểm tra giao dịch...'
                : 'Kiểm tra trạng thái thanh toán',
          ),
        ),
      ],
    );
  }
}
