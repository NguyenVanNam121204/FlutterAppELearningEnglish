import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router/route_paths.dart';
import '../../../models/assignment/assignment_models.dart';
import '../../../models/quiz/quiz_models.dart';
import '../../../core/result/result.dart';
import '../../widgets/common/catalunya_card.dart';
import '../../widgets/common/catalunya_nav_tile.dart';
import '../../widgets/common/catalunya_reveal.dart';
import '../../widgets/common/catalunya_scaffold.dart';
import '../../widgets/common/state_views.dart';

class AssignmentDetailScreen extends ConsumerStatefulWidget {
  const AssignmentDetailScreen({
    required this.assessmentId,
    required this.moduleId,
    super.key,
  });
  final String assessmentId;
  final String moduleId;

  @override
  ConsumerState<AssignmentDetailScreen> createState() =>
      _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState
    extends ConsumerState<AssignmentDetailScreen> {
  bool _didAutoRouteToSingleAssessment = false;

  Future<void> _showQuizIntro(AssignmentQuizItemModel quiz) async {
    String? activeAttemptId;
    final activeResult = await ref
        .read(quizRepositoryProvider)
        .checkActiveAttempt(quiz.quizId);
    if (activeResult is Success<QuizActiveAttemptModel>) {
      if (activeResult.value.hasActiveAttempt &&
          (activeResult.value.attemptId ?? '').isNotEmpty) {
        activeAttemptId = activeResult.value.attemptId;
      }
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF40C4D8),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.help_outline_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        quiz.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 34,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    children: [
                      _QuizIntroTextBlock(label: 'Tiêu đề', value: quiz.title),
                      const SizedBox(height: 10),
                      _QuizIntroTextBlock(
                        label: 'Mô tả',
                        value: quiz.description.trim().isNotEmpty
                            ? quiz.description
                            : 'Không có mô tả',
                      ),
                      const SizedBox(height: 10),
                      _QuizIntroTextBlock(
                        label: 'Hướng dẫn',
                        value: quiz.instructions.trim().isNotEmpty
                            ? quiz.instructions
                            : 'Không có hướng dẫn',
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _QuizStatCard(
                              label: 'Thời gian làm bài',
                              value: quiz.durationLabel.isNotEmpty
                                  ? quiz.durationLabel
                                  : '--',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuizStatCard(
                              label: 'Tổng số câu hỏi',
                              value: quiz.totalQuestions?.toString() ?? '--',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _QuizStatCard(
                              label: 'Điểm đạt',
                              value: quiz.passingScore != null
                                  ? '${quiz.passingScore} điểm'
                                  : '--',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuizStatCard(
                              label: 'Số lần làm tối đa',
                              value: quiz.maxAttempts != null
                                  ? '${quiz.maxAttempts} lần'
                                  : 'Không giới hạn',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      children: [
                        if ((activeAttemptId ?? '').isNotEmpty)
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(modalContext).pop();
                                context.push(
                                  '${RoutePaths.quiz}?quizId=${quiz.quizId}&attemptId=$activeAttemptId',
                                );
                              },
                              child: const Text('Tiếp tục bài đang làm'),
                            ),
                          ),
                        if ((activeAttemptId ?? '').isNotEmpty)
                          const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF40C4D8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(modalContext).pop();
                              final forceNew =
                                  (activeAttemptId ?? '').isNotEmpty
                                  ? '&forceNew=1'
                                  : '';
                              context.push(
                                '${RoutePaths.quiz}?quizId=${quiz.quizId}$forceNew',
                              );
                            },
                            child: Text(
                              (activeAttemptId ?? '').isNotEmpty
                                  ? 'Bắt đầu làm bài mới'
                                  : 'Bắt đầu làm bài',
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: () => Navigator.of(modalContext).pop(),
                          child: const Text('Hủy'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final arg = '${widget.assessmentId}::${widget.moduleId}';
    final asyncData = ref.watch(assignmentDetailProvider(arg));
    return CatalunyaScaffold(
      appBar: AppBar(title: const Text('Chi tiết bài tập')),
      body: asyncData.when(
        data: (data) {
          final assessments = data.assessments;
          final quizzes = data.quizzes;
          final essays = data.essays;

          if (widget.assessmentId.isEmpty &&
              assessments.length == 1 &&
              !_didAutoRouteToSingleAssessment) {
            _didAutoRouteToSingleAssessment = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              context.go(
                '${RoutePaths.assignmentDetail}?moduleId=${widget.moduleId}&assessmentId=${assessments.first.assessmentId}',
              );
            });
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CatalunyaReveal(
                child: CatalunyaCard(
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                          ),
                        ),
                        child: const Icon(
                          Icons.assignment_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Bài tập của module',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (widget.assessmentId.isEmpty) ...[
                Text(
                  'Danh sách bài kiểm tra',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (assessments.isEmpty)
                  const CatalunyaCard(
                    child: Text('Chưa có bài kiểm tra nào trong module này.'),
                  )
                else
                  ...assessments.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return CatalunyaReveal(
                      delay: Duration(milliseconds: index * 45),
                      child: CatalunyaNavTile(
                        title: item.title,
                        subtitle: item.timeLimit.trim().isNotEmpty
                            ? 'Thời lượng: ${item.timeLimit}'
                            : (item.description.trim().isNotEmpty
                                  ? item.description
                                  : 'Xem chi tiết bài kiểm tra'),
                        leading: const Icon(Icons.fact_check_outlined),
                        onTap: () => context.push(
                          '${RoutePaths.assignmentDetail}?moduleId=${widget.moduleId}&assessmentId=${item.assessmentId}',
                        ),
                      ),
                    );
                  }),
              ] else ...[
                Text('Quiz', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (quizzes.isEmpty)
                  const CatalunyaCard(
                    child: Text('Chưa có quiz trong bài tập này.'),
                  )
                else
                  ...quizzes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final q = entry.value;
                    return CatalunyaReveal(
                      delay: Duration(milliseconds: index * 45),
                      child: CatalunyaNavTile(
                        title: q.title,
                        subtitle: 'Bắt đầu làm quiz',
                        leading: const Icon(Icons.quiz_outlined),
                        onTap: () => _showQuizIntro(q),
                      ),
                    );
                  }),
                const SizedBox(height: 16),
                Text('Tự luận', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (essays.isEmpty)
                  const CatalunyaCard(
                    child: Text('Chưa có bài tự luận trong bài tập này.'),
                  )
                else
                  ...essays.asMap().entries.map((entry) {
                    final index = entry.key;
                    final e = entry.value;
                    return CatalunyaReveal(
                      delay: Duration(milliseconds: 80 + index * 45),
                      child: CatalunyaNavTile(
                        title: e.title,
                        subtitle: 'Viết và nộp bài tự luận',
                        leading: const Icon(Icons.edit_note_rounded),
                        onTap: () => context.push(
                          '${RoutePaths.essay}?essayId=${e.essayId}',
                        ),
                      ),
                    );
                  }),
              ],
            ],
          );
        },
        loading: () => const LoadingStateView(),
        error: (error, _) => ErrorStateView(message: '$error'),
      ),
    );
  }
}

class _QuizIntroTextBlock extends StatelessWidget {
  const _QuizIntroTextBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_square, size: 16, color: Color(0xFF40C4D8)),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value),
        ],
      ),
    );
  }
}

class _QuizStatCard extends StatelessWidget {
  const _QuizStatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
