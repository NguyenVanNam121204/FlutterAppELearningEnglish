import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router/route_paths.dart';
import '../../../core/result/result.dart';
import '../../widgets/common/catalunya_card.dart';
import '../../widgets/common/catalunya_scaffold.dart';
import '../../widgets/common/state_views.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  const CourseDetailScreen({required this.courseId, super.key});
  final String courseId;

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  bool _isEnrolling = false;

  Future<void> _enrollCourse({
    required String courseId,
    required String courseTitle,
  }) async {
    if (_isEnrolling) return;
    setState(() => _isEnrolling = true);

    final result = await ref
        .read(paymentFeatureViewModelProvider)
        .enrollCourse(courseId);

    if (!mounted) return;
    setState(() => _isEnrolling = false);

    switch (result) {
      case Success<void>():
        ref.invalidate(myCoursesListProvider);
        ref.invalidate(notificationUnreadCountProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đăng ký khóa học "$courseTitle" thành công. Vui lòng kiểm tra thông báo và email.',
            ),
          ),
        );
      case Failure<void>(:final error):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncCourse = ref.watch(courseDetailDataProvider(widget.courseId));
    final myCoursesAsync = ref.watch(myCoursesListProvider);
    return CatalunyaScaffold(
      appBar: AppBar(title: const Text('Chi tiết khóa học')),
      body: asyncCourse.when(
        data: (course) {
          final title = course.title;
          final description = course.description;
          final imageUrl = course.imageUrl;
          final courseId = course.courseId.isEmpty
              ? widget.courseId
              : course.courseId;
          final isEnrolled = myCoursesAsync.valueOrNull?.any(
            (item) => item.courseId == courseId,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              CatalunyaCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          imageUrl,
                          height: 190,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    if (imageUrl.isNotEmpty) const SizedBox(height: 14),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    MarkdownBody(
                      data: description,
                      selectable: true,
                      styleSheet:
                          MarkdownStyleSheet.fromTheme(
                            Theme.of(context),
                          ).copyWith(
                            p: Theme.of(context).textTheme.bodyLarge,
                            h2: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (isEnrolled == null)
                const SizedBox(
                  height: 48,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (isEnrolled)
                FilledButton.icon(
                  onPressed: () =>
                      context.push(RoutePaths.courseLessons(courseId)),
                  icon: const Icon(Icons.menu_book_rounded),
                  label: const Text('Vào danh sách bài học'),
                )
              else
                FilledButton.icon(
                  onPressed: _isEnrolling
                      ? null
                      : () => _enrollCourse(
                          courseId: courseId,
                          courseTitle: title,
                        ),
                  icon: _isEnrolling
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_circle_outline_rounded),
                  label: Text(
                    _isEnrolling ? 'Đang đăng ký...' : 'Đăng ký ngay',
                  ),
                ),
            ],
          );
        },
        loading: () => const LoadingStateView(),
        error: (error, _) =>
            ErrorStateView(message: 'Không thể tải khóa học: $error'),
      ),
    );
  }
}
