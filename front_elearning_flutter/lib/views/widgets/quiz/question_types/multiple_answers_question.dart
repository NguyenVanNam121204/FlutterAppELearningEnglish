import 'package:flutter/material.dart';

import '../../../../models/quiz/quiz_models.dart';
import '../../../../viewmodels/quiz/quiz_screen_viewmodel.dart';
import 'question_card_shell.dart';
import 'question_type_styles.dart';

class MultipleAnswersQuestion extends StatelessWidget {
  const MultipleAnswersQuestion({
    super.key,
    required this.question,
    required this.answer,
    required this.hasAttempt,
    required this.questionLabel,
    required this.onToggleMulti,
  });

  final QuizQuestionModel question;
  final QuizAnswerModel? answer;
  final bool hasAttempt;
  final String questionLabel;
  final void Function(String optionId, bool checked) onToggleMulti;

  @override
  Widget build(BuildContext context) {
    return QuestionCardShell(
      questionLabel: questionLabel,
      questionText: question.content,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: QuizQuestionStyles.infoBackground(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Co the chon nhieu dap an.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          for (final entry in question.options.asMap().entries)
            _MultipleTile(
              label:
                  '${String.fromCharCode(65 + entry.key)}. ${entry.value.text}',
              selected:
                  answer?.multiOptionIds.contains(entry.value.optionId) ??
                  false,
              enabled: hasAttempt,
              onTap: () {
                final selected =
                    answer?.multiOptionIds.contains(entry.value.optionId) ??
                    false;
                onToggleMulti(entry.value.optionId, !selected);
              },
            ),
        ],
      ),
    );
  }
}

class _MultipleTile extends StatelessWidget {
  const _MultipleTile({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : QuizQuestionStyles.cardBorder(context),
            width: 2,
          ),
          color: selected
              ? QuizQuestionStyles.activeBackground(context)
              : QuizQuestionStyles.subtleBackground(context),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : const Color(0xFF94A3B8),
                  width: 2,
                ),
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
