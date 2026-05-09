import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router/route_paths.dart';
import '../../widgets/common/catalunya_reveal.dart';
import '../../widgets/common/catalunya_scaffold.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/course/my_course_list_item.dart';

class MyCourseScreen extends ConsumerStatefulWidget {
  const MyCourseScreen({super.key});

  @override
  ConsumerState<MyCourseScreen> createState() => _MyCourseScreenState();
}

class _MyCourseScreenState extends ConsumerState<MyCourseScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(myCourseViewModelProvider.notifier).loadMyCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myCourseViewModelProvider);

    Future<void> onRefresh() async {
      await ref.read(myCourseViewModelProvider.notifier).refresh();
    }

    if (state.isLoading && state.courses.isEmpty) {
      return const CatalunyaScaffold(
        appBar: null,
        body: LoadingStateView(),
      );
    }

    if (state.errorMessage != null && state.courses.isEmpty) {
      return CatalunyaScaffold(
        appBar: AppBar(title: const Text('Khóa học của tôi')),
        body: ErrorStateView(
          message: state.errorMessage!,
        ),
      );
    }

    return CatalunyaScaffold(
      appBar: AppBar(
        title: const Text('Khóa học của tôi'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: Builder(
          builder: (context) {
            final courses = state.courses;
            if (courses.isEmpty) {
              return const Center(
                child: EmptyStateView(
                  message: 'Bạn chưa đăng ký khóa học nào',
                  icon: Icons.library_books_outlined,
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final c = courses[index];
                return CatalunyaReveal(
                  delay: Duration(milliseconds: index * 40),
                  child: MyCourseListItem(
                    item: c,
                    index: index,
                    onTap: () =>
                        context.push(RoutePaths.courseInCourses(c.courseId)),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
