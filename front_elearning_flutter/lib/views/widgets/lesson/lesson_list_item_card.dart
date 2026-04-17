import 'package:flutter/material.dart';

import '../../../models/learning/lesson_models.dart';
import '../common/catalunya_card.dart';

class LessonListItemCard extends StatelessWidget {
  const LessonListItemCard({
    super.key,
    required this.item,
    required this.displayOrder,
    required this.onTap,
  });

  final LessonListItemModel item;
  final int displayOrder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = (item.imageUrl ?? '').trim().isNotEmpty;
    final subtitleText = (item.description ?? '').trim().isNotEmpty
        ? '$displayOrder. ${item.description}'
        : '$displayOrder. ${item.title}';

    return CatalunyaCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFE8F2FF),
                  ),
                  child: hasImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _LessonIndexBadge(order: displayOrder);
                            },
                          ),
                        )
                      : _LessonIndexBadge(order: displayOrder),
                ),
                if (item.isCompleted)
                  const Positioned(
                    right: -4,
                    top: -4,
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitleText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, size: 30),
          ],
        ),
      ),
    );
  }
}

class _LessonIndexBadge extends StatelessWidget {
  const _LessonIndexBadge({required this.order});

  final int order;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$order',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0EA5E9),
        ),
      ),
    );
  }
}
