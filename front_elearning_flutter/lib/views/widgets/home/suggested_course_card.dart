import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../models/home/home_course_model.dart';
import '../common/catalunya_card.dart';

class SuggestedCourseCard extends StatefulWidget {
  const SuggestedCourseCard({
    super.key,
    required this.course,
    required this.onOpenCourse,
    required this.onEnroll,
    required this.imageHeight,
    this.isEnrolling = false,
  });

  final HomeCourseModel course;
  final VoidCallback onOpenCourse;
  final VoidCallback onEnroll;
  final double imageHeight;
  final bool isEnrolling;

  @override
  State<SuggestedCourseCard> createState() => _SuggestedCourseCardState();
}

class _SuggestedCourseCardState extends State<SuggestedCourseCard> {
  bool _isHovering = false;

  String _formatPrice(double? price) {
    if (price == null || price == 0) {
      return 'Miễn phí';
    }
    return '${price.toStringAsFixed(0)}đ';
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final targetImageHeightPx = (widget.imageHeight * devicePixelRatio).round();
    final isEnrolled = course.isEnrolled;
    final title = course.title.trim().isEmpty ? 'Khóa học' : course.title;
    final titleSlotHeight = 52.0 + ((textScale - 1).clamp(0.0, 0.6)) * 18;
    final hasLessonCount = course.totalLessons > 0;
    final lessonText = '${course.totalLessons} bài học';
    final actionLabel = isEnrolled ? 'Vào học' : 'Đăng ký';
    final actionIcon = isEnrolled
        ? Icons.arrow_forward_rounded
        : Icons.add_circle_outline_rounded;
    final scale = _isHovering ? 1.015 : 1.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: CatalunyaCard(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onOpenCourse,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    SizedBox(
                      height: widget.imageHeight,
                      child:
                          course.imageUrl == null ||
                              course.imageUrl!.trim().isEmpty
                          ? Container(
                              color: const Color(0xFFE8F2FF),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.menu_book_rounded,
                                size: 42,
                              ),
                            )
                          : ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: course.imageUrl!.trim(),
                                width: double.infinity,
                                fit: BoxFit.cover,
                                memCacheHeight: targetImageHeightPx,
                                placeholder: (context, url) {
                                  return Container(
                                    color: const Color(0xFFE8F2FF),
                                    alignment: Alignment.center,
                                    child: const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                },
                                errorWidget: (context, url, error) {
                                  return Container(
                                    color: const Color(0xFFE8F2FF),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.menu_book_rounded,
                                      size: 42,
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.06),
                              Colors.black.withValues(alpha: 0.26),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (hasLessonCount)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            lessonText,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF364152),
                            ),
                          ),
                        ),
                      ),
                    if (isEnrolled)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Đã tham gia',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: titleSlotHeight,
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatPrice(course.price),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: widget.isEnrolling
                                ? null
                                : (isEnrolled
                                      ? widget.onOpenCourse
                                      : widget.onEnroll),
                            icon: widget.isEnrolling
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(actionIcon, size: 18),
                            label: Text(
                              widget.isEnrolling ? 'Đang xử lý' : actionLabel,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.fade,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
