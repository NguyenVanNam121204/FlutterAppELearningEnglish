import 'package:flutter/material.dart';
import 'dart:math' as math;

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
            leading: _StreakFlameBadge(
              isActiveToday: isActiveToday,
              currentStreak: currentStreak,
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

class _StreakFlameBadge extends StatefulWidget {
  const _StreakFlameBadge({
    required this.isActiveToday,
    required this.currentStreak,
  });

  final bool isActiveToday;
  final int currentStreak;

  @override
  State<_StreakFlameBadge> createState() => _StreakFlameBadgeState();
}

class _StreakFlameBadgeState extends State<_StreakFlameBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streakLevel = widget.currentStreak >= 7 ? 1.0 : 0.6;
    final activeIntensity = widget.isActiveToday ? 1.0 : 0.72;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final pulse = 0.92 + (0.12 * t);
        final flicker = 0.96 + (0.06 * math.sin(t * 2 * math.pi * 3));
        final glowOpacity = (0.22 + (0.22 * t)) * activeIntensity;
        final flameOpacity = (0.88 + (0.12 * t)) * activeIntensity;

        return Transform.scale(
          scale: pulse,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFF3E0),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFFFF7A00,
                  ).withValues(alpha: glowOpacity * streakLevel),
                  blurRadius: 18,
                  spreadRadius: 1 + (2 * t),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Transform.scale(
              scale: flicker,
              child: Icon(
                Icons.local_fire_department,
                color: Color.lerp(
                  const Color(0xFFFF4D00),
                  const Color(0xFFFFB020),
                  t,
                )?.withValues(alpha: flameOpacity),
                size: 24,
              ),
            ),
          ),
        );
      },
    );
  }
}
