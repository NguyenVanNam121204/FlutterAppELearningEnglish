import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../app/providers.dart';
import '../../../app/router/route_paths.dart';
import '../../../core/result/result.dart';
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
  Set<String>? _enrolledCourseIdsState;

  Set<String> get _enrolledCourseIds => _enrolledCourseIdsState ??= <String>{};

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
        setState(() => _enrolledCourseIds.add(courseId));
        ref.invalidate(myCoursesListProvider);
        ref.invalidate(notificationUnreadCountProvider);
        unawaited(ref.read(homeViewModelProvider.notifier).loadHomeData());
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: asyncCourse.when(
        data: (course) {
          final title = course.title;
          final description = course.description;
          final imageUrl = course.imageUrl;
          final courseId = course.courseId.isEmpty
              ? widget.courseId
              : course.courseId;

          final isEnrolledFromServer = myCoursesAsync.valueOrNull?.any(
            (item) => item.courseId == courseId,
          );
          final isEnrolled =
              _enrolledCourseIds.contains(courseId) ||
              (isEnrolledFromServer ?? false);
          final isEnrollmentChecking =
              !_enrolledCourseIds.contains(courseId) &&
              isEnrolledFromServer == null;

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // Immersive Header Image
                  SliverAppBar(
                    expandedHeight: 300,
                    pinned: true,
                    stretch: true,
                    backgroundColor: const Color(0xFF0EA5E9),
                    leading: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: Color(0xFF0F172A),
                        ),
                        onPressed: () => context.pop(),
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      stretchModes: const [StretchMode.zoomBackground],
                      titlePadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      centerTitle: false,
                      title: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: 1.0,
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(color: Colors.black45, blurRadius: 10),
                            ],
                          ),
                        ),
                      ),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (imageUrl.isNotEmpty)
                            Hero(
                              tag: 'course_image_$courseId',
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Container(color: const Color(0xFFE2E8F0)),
                                errorWidget: (context, url, error) => Container(
                                  color: const Color(0xFFE2E8F0),
                                  child: const Icon(
                                    Icons.broken_image_rounded,
                                    size: 48,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF0EA5E9),
                                    Color(0xFF38BDF8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Icon(
                                Icons.menu_book_rounded,
                                size: 80,
                                color: Colors.white24,
                              ),
                            ),
                          // Subtle overlay gradient for better text contrast
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.transparent, Colors.black87],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: [0.5, 1.0],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Course Information Section
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0F9FF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'E-LEARNING',
                                        style: TextStyle(
                                          color: Color(0xFF0284C7),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F172A),
                                        height: 1.1,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              if (isEnrollmentChecking)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                _buildEnrollmentChip(isEnrolled),
                            ],
                          ),

                          const SizedBox(height: 24),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 24),

                          const Row(
                            children: [
                              Icon(
                                Icons.description_rounded,
                                color: Color(0xFF0EA5E9),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Giới thiệu khóa học',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          MarkdownBody(
                            data: description,
                            selectable: true,
                            styleSheet:
                                MarkdownStyleSheet.fromTheme(
                                  Theme.of(context),
                                ).copyWith(
                                  p: const TextStyle(
                                    fontSize: 16,
                                    height: 1.7,
                                    color: Color(0xFF334155),
                                  ),
                                  h2: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                    height: 2.0,
                                  ),
                                ),
                          ),
                          const SizedBox(
                            height: 140,
                          ), // Bottom padding for button
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom Action Button
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    20,
                    24,
                    MediaQuery.of(context).padding.bottom + 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 40,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: isEnrollmentChecking
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          height: 60,
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: isEnrolled
                                  ? null
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFF0EA5E9),
                                        Color(0xFF2563EB),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                              boxShadow: [
                                if (!isEnrolled)
                                  BoxShadow(
                                    color: const Color(
                                      0xFF0EA5E9,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: isEnrolled
                                  ? () => context.push(
                                      RoutePaths.courseLessons(courseId),
                                    )
                                  : (_isEnrolling
                                        ? null
                                        : () => _enrollCourse(
                                            courseId: courseId,
                                            courseTitle: title,
                                          )),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isEnrolled
                                    ? const Color(0xFFF1F5F9)
                                    : Colors.transparent,
                                foregroundColor: isEnrolled
                                    ? const Color(0xFF0EA5E9)
                                    : Colors.white,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 0,
                              ),
                              child: _isEnrolling
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isEnrolled
                                              ? Icons.rocket_launch_rounded
                                              : Icons.bolt_rounded,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          isEnrolled
                                              ? 'VÀO HỌC NGAY'
                                              : 'ĐĂNG KÝ NGAY',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
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

  Widget _buildEnrollmentChip(bool isEnrolled) {
    final backgroundColor = isEnrolled
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFEFF6FF);
    final textColor = isEnrolled
        ? const Color(0xFF15803D)
        : const Color(0xFF2563EB);
    final label = isEnrolled ? 'Đã đăng ký' : 'Chưa đăng ký';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
