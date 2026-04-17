import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../widgets/common/catalunya_card.dart';
import '../../widgets/common/catalunya_scaffold.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/state_views.dart';

class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(paymentHistoryDataProvider);
    return CatalunyaScaffold(
      appBar: AppBar(title: const Text('Lá»‹ch sá»­ thanh toÃ¡n')),
      body: asyncItems.when(
        data: (items) => items.isEmpty
            ? const Center(
                child: EmptyStateView(
                  message: 'ChÆ°a cÃ³ giao dá»‹ch nÃ o',
                  icon: Icons.receipt_long_outlined,
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final it = items[index];
                  final code = it.orderCode;
                  final amount = it.amount;
                  final status = it.status;
                  final productType = it.productType;
                  final createdAt = it.createdAt;
                  final success =
                      status.toLowerCase().contains('success') || status == '2';
                  return CatalunyaCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Icon(
                        success ? Icons.check_circle : Icons.pending,
                        color: success ? Colors.green : Colors.orange,
                      ),
                      title: Text('MÃ£ Ä‘Æ¡n: $code'),
                      subtitle: Text(
                        'Sá»‘ tiá»n: $amount\nLoáº¡i: $productType â€¢ Tráº¡ng thÃ¡i: $status\n$createdAt',
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
        loading: () => const LoadingStateView(),
        error: (error, _) => ErrorStateView(message: '$error'),
      ),
    );
  }
}

