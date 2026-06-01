import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../models/quiz/quiz_models.dart';
import '../../../viewmodels/quiz/quiz_result_detail_viewmodel.dart';

class QuizResultDetailScreen extends ConsumerWidget {
  const QuizResultDetailScreen({super.key, required this.attemptId});

  final String attemptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizResultDetailProvider(attemptId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Chi tiết bài làm',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF40C4D8)),
            )
          : state.errorMessage != null
          ? _buildErrorState(state.errorMessage!)
          : _buildContent(context, state.result!),
    );
  }

  Widget _buildContent(BuildContext context, QuizAttemptResultModel result) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Summary Header
        SliverToBoxAdapter(child: _buildSummaryHeader(context, result)),

        // Questions List Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Text(
              'DANH SÁCH CÂU HỎI',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.grey,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),

        // Questions List
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return _buildQuestionCard(
                context,
                result.questions[index],
                index + 1,
              );
            }, childCount: result.questions.length),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildSummaryHeader(
    BuildContext context,
    QuizAttemptResultModel result,
  ) {
    final double percentage = result.percentage;

    // Consistent color logic: >= 80% Green, >= 50% Orange, < 50% Red
    final Color themeColor = percentage >= 80
        ? const Color(0xFF10B981)
        : percentage >= 50
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    final Color secondaryColor = percentage >= 80
        ? const Color(0xFF059669)
        : percentage >= 50
        ? const Color(0xFFD97706)
        : const Color(0xFFDC2626);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [themeColor, secondaryColor],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng điểm',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: _formatScore(result.totalScore),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: '/${_formatScore(result.totalPossibleScore)}',
                          style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${result.percentage.toStringAsFixed(1)}%',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryStat(
                  'Số câu đúng',
                  '${result.questions.where((q) => q.isCorrect).length}/${result.questions.length}',
                  Icons.check_circle_rounded,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                _buildSummaryStat(
                  'Thời gian',
                  '${result.timeSpentSeconds}s',
                  Icons.speed_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(
    BuildContext context,
    QuestionReviewModel question,
    int index,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = question.isCorrect
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      index.toString(),
                      style: GoogleFonts.outfit(
                        color: accentColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.questionText,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E293B),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildAnswerSection(context, question),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  question.isCorrect
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: accentColor,
                  size: 28,
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.stars_rounded,
                  size: 16,
                  color: accentColor.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  'Điểm: ${_formatScore(question.score)} / ${_formatScore(question.points)}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: (isDark ? Colors.white : const Color(0xFF1E293B))
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerSection(
    BuildContext context,
    QuestionReviewModel question,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnswerRow(
          context,
          'CÂU TRẢ LỜI CỦA BẠN',
          question.userAnswerText ?? 'Chưa trả lời',
          question.isCorrect
              ? const Color(0xFF10B981)
              : const Color(0xFFEF4444),
        ),
        if (!question.isCorrect) ...[
          const SizedBox(height: 16),
          _buildAnswerRow(
            context,
            'ĐÁP ÁN ĐÚNG',
            question.correctAnswerText ?? '-',
            const Color(0xFF10B981),
          ),
        ],
      ],
    );
  }

  Widget _buildAnswerRow(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: valueColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: valueColor.withValues(alpha: 0.1)),
          ),
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  String _formatScore(double score) {
    if (score == score.toInt()) {
      return score.toInt().toString();
    }
    return score.toStringAsFixed(1);
  }

  Widget _buildErrorState(String message) {
    return Center(child: Text(message));
  }
}
