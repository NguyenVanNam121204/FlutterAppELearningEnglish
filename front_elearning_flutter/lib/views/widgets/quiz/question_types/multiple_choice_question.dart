import 'package:flutter/material.dart';

import '../../../../models/quiz/quiz_models.dart';
import '../../../../viewmodels/quiz/quiz_screen_viewmodel.dart';
import 'question_card_shell.dart';
import 'question_type_styles.dart';

class MultipleChoiceQuestion extends StatelessWidget {
  const MultipleChoiceQuestion({
    super.key,
    required this.question,
    required this.answer,
    required this.hasAttempt,
    required this.questionLabel,
    required this.onSelectSingle,
  });

  final QuizQuestionModel question;
  final QuizAnswerModel? answer;
  final bool hasAttempt;
  final String questionLabel;
  final ValueChanged<String> onSelectSingle;

  @override
  Widget build(BuildContext context) {
    return QuestionCardShell(
      questionLabel: questionLabel,
      questionText: question.content,
      child: Column(
        children: [
          for (final entry in question.options.asMap().entries)
            _ChoiceTile(
              label:
                  '${String.fromCharCode(65 + entry.key)}. ${entry.value.text}',
              selected: answer?.singleOptionId == entry.value.optionId,
              enabled: hasAttempt,
              onTap: () => onSelectSingle(entry.value.optionId),
            ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
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
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : const Color(0xFF94A3B8),
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
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
