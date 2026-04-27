import 'package:flutter/material.dart';

import '../../../models/quiz/quiz_models.dart';
import '../../../viewmodels/quiz/quiz_screen_viewmodel.dart';
import 'question_types/fill_blank_question.dart';
import 'question_types/matching_question.dart';
import 'question_types/multiple_answers_question.dart';
import 'question_types/multiple_choice_question.dart';
import 'question_types/ordering_question.dart';
import 'question_types/true_false_question.dart';

class QuizQuestionCard extends StatelessWidget {
  const QuizQuestionCard({
    super.key,
    required this.question,
    required this.answer,
    required this.hasAttempt,
    required this.questionNumber,
    required this.totalQuestions,
    required this.onTextChanged,
    required this.onToggleMulti,
    required this.onSelectSingle,
    required this.onSetMatching,
    required this.onSetOrdering,
  });

  final QuizQuestionModel question;
  final QuizAnswerModel? answer;
  final bool hasAttempt;
  final int questionNumber;
  final int totalQuestions;
  final ValueChanged<String> onTextChanged;
  final void Function(String optionId, bool checked) onToggleMulti;
  final ValueChanged<String> onSelectSingle;
  final ValueChanged<Map<String, String>> onSetMatching;
  final ValueChanged<List<String>> onSetOrdering;

  @override
  Widget build(BuildContext context) {
    final label = 'Cau $questionNumber/$totalQuestions';

    switch (question.type) {
      case 2:
        return MultipleAnswersQuestion(
          question: question,
          answer: answer,
          hasAttempt: hasAttempt,
          questionLabel: label,
          onToggleMulti: onToggleMulti,
        );
      case 3:
        return TrueFalseQuestion(
          question: question,
          answer: answer,
          hasAttempt: hasAttempt,
          questionLabel: label,
          onSelectSingle: onSelectSingle,
        );
      case 4:
        return FillBlankQuestion(
          question: question,
          answer: answer,
          hasAttempt: hasAttempt,
          questionLabel: label,
          onTextChanged: onTextChanged,
        );
      case 5:
        return MatchingQuestion(
          question: question,
          answer: answer,
          hasAttempt: hasAttempt,
          questionLabel: label,
          onSetMatching: onSetMatching,
        );
      case 6:
        return OrderingQuestion(
          question: question,
          answer: answer,
          hasAttempt: hasAttempt,
          questionLabel: label,
          onSetOrdering: onSetOrdering,
        );
      default:
        return MultipleChoiceQuestion(
          question: question,
          answer: answer,
          hasAttempt: hasAttempt,
          questionLabel: label,
          onSelectSingle: onSelectSingle,
        );
    }
  }
}
