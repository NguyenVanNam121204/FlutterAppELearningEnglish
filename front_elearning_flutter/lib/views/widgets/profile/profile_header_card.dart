import 'package:flutter/material.dart';

import '../../../models/user/user_model.dart';
import '../common/catalunya_card.dart';

class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    super.key,
    required this.user,
    required this.onEditAvatar,
    this.isUpdatingAvatar = false,
  });

  final UserModel user;
  final VoidCallback onEditAvatar;
  final bool isUpdatingAvatar;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = user.displayName;
    final initials = name
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e[0].toUpperCase())
        .join();

    return CatalunyaCard(
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: const Color(0xFFDDF2FF),
                backgroundImage: (user.avatarUrl ?? '').trim().isNotEmpty
                    ? NetworkImage(user.avatarUrl!.trim())
                    : null,
                child: (user.avatarUrl ?? '').trim().isEmpty
                    ? Text(
                        initials.isEmpty ? 'U' : initials,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0A84FF),
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Material(
                  color: colorScheme.surface,
                  elevation: 1,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: isUpdatingAvatar ? null : onEditAvatar,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: isUpdatingAvatar
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.camera_alt_rounded,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
