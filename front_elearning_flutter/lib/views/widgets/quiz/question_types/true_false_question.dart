import 'package:flutter/material.dart';

import '../../../../models/quiz/quiz_models.dart';
import '../../../../viewmodels/quiz/quiz_screen_viewmodel.dart';
import 'question_card_shell.dart';
import 'question_type_styles.dart';

class TrueFalseQuestion extends StatelessWidget {
  const TrueFalseQuestion({
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
    final trueOption = question.options.firstWhere(
      (opt) {
        final text = opt.text.toLowerCase();
        return text.contains('true') || text.contains('dung');
      },
      orElse: () => question.options.isNotEmpty
          ? question.options.first
          : const QuizOptionModel(optionId: '1', text: 'Dung'),
    );

    final falseOption = question.options.firstWhere(
      (opt) {
        final text = opt.text.toLowerCase();
        return text.contains('false') || text.contains('sai');
      },
      orElse: () => question.options.length > 1
          ? question.options[1]
          : const QuizOptionModel(optionId: '0', text: 'Sai'),
    );

    return QuestionCardShell(
      questionLabel: questionLabel,
      questionText: question.content,
      child: Row(
        children: [
          Expanded(
            child: _DecisionTile(
              text: trueOption.text,
              selected: answer?.singleOptionId == trueOption.optionId,
              enabled: hasAttempt,
              onTap: () => onSelectSingle(trueOption.optionId),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _DecisionTile(
              text: falseOption.text,
              selected: answer?.singleOptionId == falseOption.optionId,
              enabled: hasAttempt,
              onTap: () => onSelectSingle(falseOption.optionId),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionTile extends StatelessWidget {
  const _DecisionTile({
    required this.text,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
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
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: selected ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ),
      ),
    );
  }
}
