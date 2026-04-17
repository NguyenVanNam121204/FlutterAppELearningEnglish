import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../models/learning/lesson_models.dart';
import '../../widgets/common/catalunya_card.dart';
import '../../widgets/common/catalunya_scaffold.dart';
import '../../widgets/common/state_views.dart';

class LessonResultScreen extends ConsumerWidget {
  const LessonResultScreen({
    required this.attemptId,
    this.initialResult,
    super.key,
  });
  final String attemptId;
  final LessonResultModel? initialResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (initialResult != null) {
      return _LessonResultBody(result: initialResult!);
    }

    final asyncData = ref.watch(lessonResultProvider(attemptId));
    return CatalunyaScaffold(
      appBar: AppBar(title: const Text('Kết quả bài học')),
      body: asyncData.when(
        data: (data) => _LessonResultCard(data: data),
        loading: () => const LoadingStateView(),
        error: (error, _) => ErrorStateView(message: '$error'),
      ),
    );
  }
}

class _LessonResultBody extends StatelessWidget {
  const _LessonResultBody({required this.result});

  final LessonResultModel result;

  @override
  Widget build(BuildContext context) {
    return CatalunyaScaffold(
      appBar: AppBar(title: const Text('Kết quả bài học')),
      body: _LessonResultCard(data: result),
    );
  }
}

class _LessonResultCard extends StatelessWidget {
  const _LessonResultCard({required this.data});

  final LessonResultModel data;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: CatalunyaCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                data.isPassed == false
                    ? Icons.highlight_off_rounded
                    : Icons.emoji_events_rounded,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                'Điểm: ${data.score}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text('Đúng ${data.correctAnswers} / ${data.totalQuestions} câu'),
              if (data.percentage != null) ...[
                const SizedBox(height: 6),
                Text('Tỉ lệ đúng: ${data.percentage!.toStringAsFixed(1)}%'),
              ],
              if (data.timeSpentSeconds != null) ...[
                const SizedBox(height: 6),
                Text('Thời gian làm bài: ${data.timeSpentSeconds}s'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
