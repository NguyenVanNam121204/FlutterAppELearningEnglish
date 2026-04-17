import 'package:flutter/material.dart';

import '../../../models/learning/lesson_models.dart';
import '../common/catalunya_card.dart';
import '../common/catalunya_pill_button.dart';

class LessonModuleCard extends StatelessWidget {
  const LessonModuleCard({
    super.key,
    required this.module,
    required this.onTap,
    this.onPronunciationTap,
  });

  final LessonModuleItemModel module;
  final VoidCallback onTap;
  final VoidCallback? onPronunciationTap;

  bool get _isFlashCard {
    final typeName = (module.contentTypeName ?? '').toLowerCase();
    return module.contentType == 2 || typeName.contains('flash');
  }

  IconData get _fallbackIcon {
    final typeName = (module.contentTypeName ?? '').toLowerCase();
    if (module.contentType == 2 || typeName.contains('flash')) {
      return Icons.style_rounded;
    }
    if (module.contentType == 3 ||
        typeName.contains('assessment') ||
        typeName.contains('quiz') ||
        typeName.contains('assignment')) {
      return Icons.edit_note_rounded;
    }
    return Icons.menu_book_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = (module.description ?? '').trim().isNotEmpty
        ? module.description!.trim()
        : (module.contentTypeName ?? 'Nội dung bài học');

    return CatalunyaCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 52,
                height: 52,
                color: const Color(0xFFE8F2FF),
                child: (module.imageUrl ?? '').trim().isNotEmpty
                    ? Image.network(
                        module.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(_fallbackIcon, size: 24);
                        },
                      )
                    : Icon(_fallbackIcon, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (_isFlashCard)
              CatalunyaPillButton(
                label: 'pronunciation',
                icon: Icons.mic_rounded,
                enabled: module.isCompleted,
                onTap: onPronunciationTap,
              ),
            if (!_isFlashCard)
              const Icon(Icons.chevron_right_rounded, size: 30),
          ],
        ),
      ),
    );
  }
}
