import 'package:flutter/material.dart';

import '../../../models/learning/course_models.dart';
import '../common/catalunya_card.dart';
import '../common/catalunya_reveal.dart';

class SearchResultCourseCard extends StatelessWidget {
  const SearchResultCourseCard({
    super.key,
    required this.item,
    required this.index,
    required this.isEnrolled,
    required this.onTap,
  });

  final LearningCourseItem item;
  final int index;
  final bool isEnrolled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = !isEnrolled
        ? 'Chưa đăng ký khóa học'
        : item.progressPercentage > 0
        ? '${item.progressPercentage.toStringAsFixed(0)}% hoàn thành'
        : 'Khóa học sẵn sàng để bắt đầu';

    return CatalunyaReveal(
      delay: Duration(milliseconds: index * 50),
      child: CatalunyaCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: _LeadingImage(imageUrl: item.imageUrl),
          title: Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          trailing: Icon(
            isEnrolled
                ? Icons.chevron_right_rounded
                : Icons.add_circle_outline_rounded,
            color: isEnrolled ? null : Theme.of(context).colorScheme.primary,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _LeadingImage extends StatelessWidget {
  const _LeadingImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final hasImage = (imageUrl ?? '').trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 52,
        height: 52,
        color: const Color(0xFFE8F2FF),
        child: hasImage
            ? Image.network(
                imageUrl!.trim(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.school_rounded);
                },
              )
            : const Icon(Icons.school_rounded),
      ),
    );
  }
}
