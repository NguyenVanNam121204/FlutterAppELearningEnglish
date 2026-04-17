import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../widgets/common/catalunya_card.dart';
import '../../widgets/common/catalunya_scaffold.dart';

class ProScreen extends StatelessWidget {
  const ProScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CatalunyaScaffold(
      appBar: AppBar(title: const Text('Nâng cấp tài khoản')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: CatalunyaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Mở khóa toàn bộ tính năng học nâng cao, bao gồm đề thi premium và theo dõi tiến độ chi tiết.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.push(RoutePaths.payment),
                icon: const Icon(Icons.workspace_premium_rounded),
                label: const Text('Nâng cấp ngay'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
