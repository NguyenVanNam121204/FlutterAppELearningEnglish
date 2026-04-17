import 'package:flutter/material.dart';

import '../../../models/home/home_course_model.dart';
import 'course_progress_card.dart';
import 'home_section_title.dart';

class MyCoursesSection extends StatelessWidget {
  const MyCoursesSection({
    super.key,
    required this.isLoading,
    required this.courses,
  });

  final bool isLoading;
  final List<HomeCourseModel> courses;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeSectionTitle(title: 'Khóa học của bạn'),
        const SizedBox(height: 12),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (courses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDDE8F7)),
            ),
            child: const Text('Bạn chưa đăng ký khóa học nào.'),
          )
        else
          ...courses.map(
            (course) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CourseProgressCard(
                title: course.title,
                progress: (course.progressPercentage / 100).clamp(0, 1),
                lessonCount: course.totalLessons,
              ),
            ),
          ),
      ],
    );
  }
}
