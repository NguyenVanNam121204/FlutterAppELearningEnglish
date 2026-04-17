import 'package:flutter/material.dart';

import '../../../models/streak/streak_model.dart';

class StreakSection extends StatelessWidget {
  const StreakSection({super.key, required this.streak, this.errorMessage});

  final StreakModel? streak;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final isActiveToday = streak?.isActiveToday ?? false;
    final currentStreak = streak?.currentStreak ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFFFF3E0),
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.deepOrange,
              ),
            ),
            title: Text('Streak hiện tại: $currentStreak ngày'),
            subtitle: Text(
              isActiveToday
                  ? 'Bạn đã học hôm nay. Tiếp tục giữ phong độ!'
                  : 'Hôm nay bạn chưa học. Vào học ngay nhé!',
            ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 10),
          Text(
            errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}

