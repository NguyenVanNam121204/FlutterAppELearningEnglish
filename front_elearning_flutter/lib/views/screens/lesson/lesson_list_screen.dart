import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router/route_paths.dart';
import '../../widgets/common/catalunya_scaffold.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/lesson/lesson_list_item_card.dart';

class LessonListScreen extends ConsumerStatefulWidget {
  const LessonListScreen({required this.courseId, super.key});
  final String courseId;

  @override
  ConsumerState<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends ConsumerState<LessonListScreen> {
  @override
  Widget build(BuildContext context) {
    final asyncLessons = ref.watch(lessonsByCourseProvider(widget.courseId));
    return CatalunyaScaffold(
      appBar: AppBar(title: const Text('Danh sách bài học')),
      body: asyncLessons.when(
        data: (lessons) {
          if (lessons.isEmpty) {
            return const Center(
              child: EmptyStateView(
                message: 'Không có bài học',
                icon: Icons.library_books_outlined,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final item = lessons[index];
              return LessonListItemCard(
                item: item,
                displayOrder: index + 1,
                onTap: () => context.push(
                  RoutePaths.courseLessonDetail(
                    courseId: widget.courseId,
                    lessonId: item.lessonId,
                  ),
                ),
              );
            },
          );
        },
        loading: () => const LoadingStateView(),
        error: (error, _) => ErrorStateView(message: '$error'),
      ),
    );
  }
}
