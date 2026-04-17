import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router/route_paths.dart';
import '../../../core/result/result.dart';
import '../../widgets/common/catalunya_card.dart';
import '../../widgets/common/catalunya_scaffold.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/lesson/lesson_module_card.dart';

class LessonDetailScreen extends ConsumerStatefulWidget {
  const LessonDetailScreen({
    required this.lessonId,
    this.courseId = '',
    super.key,
  });

  final String courseId;
  final String lessonId;

  @override
  ConsumerState<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends ConsumerState<LessonDetailScreen> {
  Future<void> _handleModuleTap({
    required String moduleId,
    required int contentType,
    required String contentTypeName,
  }) async {
    final startResult = await ref
        .read(lessonFeatureViewModelProvider)
        .startModule(moduleId);

    if (startResult case Failure<void>(:final error)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }

    if (!mounted) return;

    final normalizedTypeName = contentTypeName.toLowerCase();
    final isFlashcard =
        contentType == 2 || normalizedTypeName.contains('flash');
    final isAssessment =
        contentType == 3 ||
        normalizedTypeName.contains('assessment') ||
        normalizedTypeName.contains('assignment') ||
        normalizedTypeName.contains('quiz');

    if (isFlashcard) {
      context.push(
        '${RoutePaths.flashcardLearning}?moduleId=$moduleId&lessonId=${widget.lessonId}',
      );
      return;
    }

    if (isAssessment) {
      context.push('${RoutePaths.assignmentDetail}?moduleId=$moduleId');
      return;
    }

    final courseId = widget.courseId;
    if (courseId.isNotEmpty) {
      context.push(
        RoutePaths.courseLessonModule(
          courseId: courseId,
          lessonId: widget.lessonId,
          moduleId: moduleId,
        ),
      );
      return;
    }

    context.push('${RoutePaths.moduleLearning}?moduleId=$moduleId');
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(lessonDetailBundleProvider(widget.lessonId));
    return CatalunyaScaffold(
      appBar: AppBar(title: const Text('Chi tiết bài học')),
      body: asyncData.when(
        data: (data) {
          final lesson = data.lesson;
          final modules = data.modules;
          final title = lesson.title;
          final description = lesson.description;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CatalunyaCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    if (description.isNotEmpty) Text(description),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Nội dung bài học',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...modules.map((m) {
                final moduleId = m.moduleId;
                final type = m.contentType;
                final normalizedTypeName = (m.contentTypeName ?? '')
                    .toLowerCase();

                return LessonModuleCard(
                  module: m,
                  onTap: () {
                    _handleModuleTap(
                      moduleId: moduleId,
                      contentType: type,
                      contentTypeName: normalizedTypeName,
                    );
                  },
                  onPronunciationTap: () {
                    context.push(
                      '${RoutePaths.pronunciation}?moduleId=$moduleId',
                    );
                  },
                );
              }),
            ],
          );
        },
        loading: () => const LoadingStateView(),
        error: (error, _) => ErrorStateView(message: '$error'),
      ),
    );
  }
}
