import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../app/providers.dart';
import '../../widgets/common/catalunya_card.dart';
import '../../widgets/common/catalunya_scaffold.dart';
import '../../widgets/common/state_views.dart';

class LectureDetailScreen extends ConsumerWidget {
  const LectureDetailScreen({required this.lectureId, super.key});
  final String lectureId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(lectureDetailProvider(lectureId));
    return CatalunyaScaffold(
      appBar: AppBar(title: const Text('Chi tiết bài giảng')),
      body: asyncData.when(
        data: (data) {
          final content = data.markdownContent.trim();
          final mediaUrl = data.mediaUrl.trim();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CatalunyaCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nội dung bài giảng',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (mediaUrl.isNotEmpty)
                CatalunyaCard(
                  child: Row(
                    children: [
                      Icon(
                        data.isDocumentType
                            ? Icons.description_outlined
                            : Icons.play_circle_outline_rounded,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SelectableText(
                          mediaUrl,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              CatalunyaCard(
                child: content.isNotEmpty
                    ? MarkdownBody(data: content)
                    : (mediaUrl.isNotEmpty
                          ? const Text('Bài giảng có tài liệu/media đính kèm.')
                          : const Text('Nội dung đang cập nhật.')),
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
