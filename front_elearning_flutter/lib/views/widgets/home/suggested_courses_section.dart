import 'package:flutter/material.dart';

import '../../../models/home/home_course_model.dart';
import '../common/catalunya_card.dart';
import '../common/catalunya_reveal.dart';
import '../common/catalunya_shimmer.dart';
import 'home_section_title.dart';
import 'suggested_course_card.dart';

class SuggestedCoursesSection extends StatelessWidget {
  const SuggestedCoursesSection({
    super.key,
    required this.courses,
    required this.isLoading,
    required this.onOpenCourse,
    required this.onEnrollCourse,
    this.enrollingCourseIds,
  });

  final List<HomeCourseModel> courses;
  final bool isLoading;
  final ValueChanged<HomeCourseModel> onOpenCourse;
  final ValueChanged<HomeCourseModel> onEnrollCourse;
  final Set<int>? enrollingCourseIds;

  @override
  Widget build(BuildContext context) {
    final activeEnrollments = enrollingCourseIds ?? const <int>{};
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 980 ? 3 : 2;
    final childAspectRatio = width >= 980 ? 0.80 : 0.74;
    final showSkeleton = isLoading && courses.isEmpty;
    final skeletonCount = width >= 980 ? 6 : 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeSectionTitle(title: 'Danh sách khóa học hệ thống'),
        const SizedBox(height: 12),
        if (showSkeleton)
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: skeletonCount,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: childAspectRatio,
            ),
            itemBuilder: (context, index) => CatalunyaReveal(
              delay: Duration(milliseconds: 50 * index),
              child: const _SuggestedCourseCardSkeleton(),
            ),
          )
        else if (courses.isEmpty)
          const CatalunyaCard(child: Text('Chưa có khóa học hệ thống.'))
        else
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: courses.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: childAspectRatio,
            ),
            itemBuilder: (context, index) {
              final course = courses[index];
              return CatalunyaReveal(
                delay: Duration(milliseconds: 65 * index),
                child: SuggestedCourseCard(
                  course: course,
                  isEnrolling: activeEnrollments.contains(course.courseId),
                  onOpenCourse: () => onOpenCourse(course),
                  onEnroll: () => onEnrollCourse(course),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _SuggestedCourseCardSkeleton extends StatelessWidget {
  const _SuggestedCourseCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return CatalunyaCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: CatalunyaShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 134,
              decoration: const BoxDecoration(
                color: Color(0xFFE9EEF6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9EEF6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: 92,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9EEF6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9EEF6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
