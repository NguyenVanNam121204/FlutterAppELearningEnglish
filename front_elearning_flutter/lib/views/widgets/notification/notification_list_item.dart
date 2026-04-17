import 'package:flutter/material.dart';

import '../../../models/notification/notification_model.dart';

class NotificationListItem extends StatelessWidget {
  const NotificationListItem({
    required this.item,
    required this.formatTime,
    required this.iconOf,
    required this.onTap,
    super.key,
  });

  final NotificationItemModel item;
  final String Function(String value) formatTime;
  final IconData Function(int type) iconOf;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = item.title;
    final body = item.message;
    final createdAt = item.createdAtRaw;
    final isRead = item.isRead;
    final type = item.type;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isRead ? null : const Color(0xFFF0F7FF),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFEFF2FF),
              child: Icon(
                iconOf(type),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(body),
                  const SizedBox(height: 4),
                  Text(
                    formatTime(createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
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

