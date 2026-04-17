import 'package:flutter/material.dart';

class PaymentCheckoutPanel extends StatelessWidget {
  const PaymentCheckoutPanel({
    required this.status,
    required this.payUrl,
    required this.paymentId,
    required this.onCopyLink,
    required this.onTestSuccess,
    required this.onTestFailed,
    super.key,
  });

  final String status;
  final String payUrl;
  final String paymentId;
  final VoidCallback onCopyLink;
  final VoidCallback onTestSuccess;
  final VoidCallback onTestFailed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (status.isNotEmpty) ...[const SizedBox(height: 8), Text(status)],
        if (payUrl.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Link thanh toán:'),
          const SizedBox(height: 8),
          SelectableText(payUrl),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onCopyLink,
            child: const Text('Sao chép link'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: paymentId.isEmpty ? null : onTestSuccess,
                  child: const Text('Giả lập thành công'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onTestFailed,
                  child: const Text('Giả lập thất bại'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
