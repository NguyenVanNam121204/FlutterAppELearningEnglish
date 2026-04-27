import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../models/learning/lesson_models.dart';
import '../../widgets/common/catalunya_scaffold.dart';
import '../../widgets/common/state_views.dart';

class LessonResultScreen extends ConsumerWidget {
  const LessonResultScreen({
    required this.attemptId,
    this.initialResult,
    super.key,
  });
  final String attemptId;
  final LessonResultModel? initialResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (initialResult != null) {
      return _LessonResultBody(result: initialResult!);
    }

    final asyncData = ref.watch(lessonResultProvider(attemptId));
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
      },
      child: CatalunyaScaffold(
        appBar: AppBar(
          title: const Text('Kết quả bài học'),
          automaticallyImplyLeading: false,
        ),
        body: asyncData.when(
          data: (data) => _LessonResultCard(data: data),
          loading: () => const LoadingStateView(),
          error: (error, _) => ErrorStateView(message: '$error'),
        ),
      ),
    );
  }
}

class _LessonResultBody extends StatelessWidget {
  const _LessonResultBody({required this.result});

  final LessonResultModel result;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Ngăn chặn nút quay lại vật lý
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Có thể thực hiện logic điều hướng ở đây nếu muốn
      },
      child: CatalunyaScaffold(
        appBar: AppBar(
          title: const Text('Kết quả bài học'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false, // Xóa nút mũi tên quay lại
        ),
        body: _LessonResultCard(data: result),
      ),
    );
  }
}

class _LessonResultCard extends StatelessWidget {
  const _LessonResultCard({required this.data});

  final LessonResultModel data;

  @override
  Widget build(BuildContext context) {
    final double scoreValue = double.tryParse(data.score) ?? 0.0;
    final bool isPassed = data.isPassed ?? (scoreValue >= 5.0);
    final themeColor = isPassed ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            themeColor.withValues(alpha: 0.1),
            Colors.white,
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              // Icon & Status Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPassed ? Icons.emoji_events_rounded : Icons.sentiment_very_dissatisfied_rounded,
                  size: 80,
                  color: themeColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isPassed ? 'Chúc mừng!' : 'Cố gắng lên!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: themeColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isPassed ? 'Bạn đã hoàn thành xuất sắc bài tập' : 'Hãy luyện tập thêm để đạt kết quả tốt hơn',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),

              // Score Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'ĐIỂM SỐ',
                      style: TextStyle(
                        letterSpacing: 2,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data.score,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    _ResultStatRow(
                      label: 'Số câu đúng',
                      value: '${data.correctAnswers} / ${data.totalQuestions}',
                      icon: Icons.check_circle_outline,
                      iconColor: const Color(0xFF10B981),
                    ),
                    const SizedBox(height: 16),
                    if (data.percentage != null)
                      _ResultStatRow(
                        label: 'Tỷ lệ chính xác',
                        value: '${data.percentage!.toStringAsFixed(1)}%',
                        icon: Icons.analytics_outlined,
                        iconColor: const Color(0xFF3B82F6),
                      ),
                    const SizedBox(height: 16),
                    if (data.timeSpentSeconds != null)
                      _ResultStatRow(
                        label: 'Thời gian',
                        value: '${data.timeSpentSeconds} giây',
                        icon: Icons.timer_outlined,
                        iconColor: const Color(0xFFF59E0B),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 60),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'HOÀN THÀNH',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultStatRow extends StatelessWidget {
  const _ResultStatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
