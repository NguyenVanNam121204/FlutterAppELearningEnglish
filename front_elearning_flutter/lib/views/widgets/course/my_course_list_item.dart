import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../models/my_course/my_course_models.dart';

class MyCourseListItem extends StatelessWidget {
  const MyCourseListItem({
    super.key,
    required this.item,
    required this.index,
    required this.onTap,
  });

  final MyCourseItemModel item;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final normalizedProgress = (item.progressPercentage / 100).clamp(0.0, 1.0);
    final hasLessonTotal = item.totalLessons > 0;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course Thumbnail or Number Badge
                      Stack(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: item.imageUrl != null &&
                                    item.imageUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: CachedNetworkImage(
                                      imageUrl: item.imageUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(
                                        child: SizedBox(
                                          width: 20, height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                                    ),
                                  )
                                : const Icon(
                                    Icons.menu_book_rounded,
                                    color: Color(0xFF64748B),
                                    size: 28,
                                  ),
                          ),
                          Positioned(
                            top: -2,
                            left: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0EA5E9),
                                    Color(0xFF22C55E)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(10),
                                ),
                                border: Border.all(
                                    color: theme.cardColor, width: 2),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: theme.textTheme.titleLarge?.color,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark 
                                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                                    : const Color(0xFFF0F9FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                hasLessonTotal
                                    ? '${item.completedLessons}/${item.totalLessons} bài học'
                                    : 'Bắt đầu học ngay',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark 
                                      ? theme.colorScheme.primary.withValues(alpha: 0.9)
                                      : const Color(0xFF0284C7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tiến độ học tập',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      Text(
                        '${item.progressPercentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: theme.textTheme.titleMedium?.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.white.withValues(alpha: 0.05)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutQuart,
                        height: 8,
                        width: MediaQuery.of(context).size.width *
                            0.75 *
                            normalizedProgress,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
                          ),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0EA5E9)
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
