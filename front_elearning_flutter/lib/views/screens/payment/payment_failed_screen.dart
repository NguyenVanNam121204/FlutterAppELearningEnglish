import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';

class PaymentFailedScreen extends StatefulWidget {
  const PaymentFailedScreen({this.reason = '', super.key});
  final String reason;

  @override
  State<PaymentFailedScreen> createState() => _PaymentFailedScreenState();
}

class _PaymentFailedScreenState extends State<PaymentFailedScreen> {
  int _countdown = 5;

  @override
  void initState() {
    super.initState();
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_countdown <= 1) {
        context.go(RoutePaths.mainAppHome);
        return false;
      }
      setState(() => _countdown -= 1);
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Failed')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cancel, color: Colors.red, size: 72),
              const SizedBox(height: 12),
              const Text(
                'Thanh toan that bai',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              if (widget.reason.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(widget.reason, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 12),
              Text('Đang chuyển về trang chủ trong $_countdown giay...'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go(RoutePaths.mainAppHome),
                child: const Text('Ve trang chu ngay'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
