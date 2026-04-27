import 'package:flutter/material.dart';

import 'question_type_styles.dart';

class QuestionCardShell extends StatelessWidget {
  const QuestionCardShell({
    super.key,
    required this.questionLabel,
    required this.questionText,
    required this.child,
  });

  final String questionLabel;
  final String questionText;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: QuizQuestionStyles.cardBackground(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: QuizQuestionStyles.cardBorder(context)),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x120F172A),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: QuizQuestionStyles.infoBackground(context),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              questionLabel,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            questionText,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
