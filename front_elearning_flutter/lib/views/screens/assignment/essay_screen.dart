import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/result/result.dart';
import '../../widgets/common/catalunya_card.dart';
import '../../widgets/common/catalunya_scaffold.dart';
import '../../widgets/common/state_views.dart';

class EssayScreen extends ConsumerStatefulWidget {
  const EssayScreen({required this.essayId, super.key});
  final String essayId;

  @override
  ConsumerState<EssayScreen> createState() => _EssayScreenState();
}

class _EssayScreenState extends ConsumerState<EssayScreen> {
  final _controller = TextEditingController();
  bool _submitting = false;

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    final result = await ref
        .read(assignmentFeatureViewModelProvider)
        .submitEssay(essayId: widget.essayId, content: _controller.text.trim());
    setState(() => _submitting = false);
    if (!mounted) return;
    final msg = switch (result) {
      Success() => 'Nộp bài thành công',
      Failure(:final error) => error.message,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncEssay = ref.watch(essayDetailProvider(widget.essayId));
    return CatalunyaScaffold(
      appBar: AppBar(title: const Text('Bài tự luận')),
      body: asyncEssay.when(
        data: (essay) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                essay.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              CatalunyaCard(child: Text(essay.instruction)),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Nội dung bài làm',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? 'Đang nộp...' : 'Nộp bài'),
              ),
            ],
          );
        },
        loading: () => const LoadingStateView(),
        error: (error, _) => ErrorStateView(message: '$error'),
      ),
    );
  }
}
