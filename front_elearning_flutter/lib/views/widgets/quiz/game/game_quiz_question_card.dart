import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../models/quiz/quiz_models.dart';
import '../../../../viewmodels/quiz/quiz_screen_viewmodel.dart';
import 'game_quiz_constants.dart';
import 'game_multiple_choice_widget.dart';
import 'game_fill_in_widget.dart';
import 'game_matching_widget.dart';
import 'game_ordering_widget.dart';
import 'game_true_false_widget.dart';
import 'game_multi_select_widget.dart';

class GameQuizQuestionCard extends StatelessWidget {
  const GameQuizQuestionCard({
    super.key,
    required this.question,
    required this.answer,
    required this.onTextChanged,
    required this.onToggleMulti,
    required this.onSelectSingle,
    required this.onSetMatching,
    required this.onSetOrdering,
  });

  final QuizQuestionModel question;
  final QuizAnswerModel? answer;
  final Function(String) onTextChanged;
  final Function(String, bool) onToggleMulti;
  final Function(String) onSelectSingle;
  final Function(Map<String, String>) onSetMatching;
  final Function(List<String>) onSetOrdering;

  @override
  Widget build(BuildContext context) {
    // Determine the type of UI to show based on question type and data
    if (question.isTrueFalse && question.options.length <= 2) {
      return GameTrueFalseWidget(
        key: ValueKey(question.questionId),
        question: question.content,
        options: question.options
            .map((o) => GameTrueFalseOption(id: o.optionId, text: o.text))
            .toList(),
        selectedOptionId: answer?.singleOptionId,
        onOptionSelected: onSelectSingle,
      );
    }

    if (question.isMultiSelect) {
      return GameMultiSelectWidget(
        key: ValueKey(question.questionId),
        question: question.content,
        options: question.options
            .map((o) => GameMultiSelectOption(id: o.optionId, text: o.text))
            .toList(),
        selectedOptionIds: answer?.multiOptionIds ?? {},
        onOptionToggled: onToggleMulti,
      );
    }

    if (question.isMultiChoice || (question.isTrueFalse && question.options.length > 2)) {
      return GameMultipleChoiceWidget(
        key: ValueKey(question.questionId),
        question: question.content,
        options: question.options
            .asMap()
            .entries
            .map((e) => GameQuizOption(
                  id: e.value.optionId,
                  label: String.fromCharCode(65 + e.key), // A, B, C...
                  text: e.value.text,
                ))
            .toList(),
        selectedOptionId: answer?.singleOptionId,
        onOptionSelected: onSelectSingle,
      );
    }

    if (question.isTextQuestion) {
      final initialMap = <int, String>{};
      final rawText = answer?.textAnswer ?? '';
      if (rawText.isNotEmpty) {
        final parts = rawText.split(", ");
        for (int i = 0; i < parts.length; i++) {
          initialMap[i] = parts[i];
        }
      }

      return GameFillInWidget(
        key: ValueKey(question.questionId),
        content: question.content,
        onAnswerChanged: (answers) {
          final sortedKeys = answers.keys.toList()..sort();
          onTextChanged(sortedKeys.map((k) => answers[k]).join(", "));
        },
        initialAnswers: initialMap,
      );
    }

    if (question.isMatching) {
      List<QuizOptionModel> leftOptions = [];
      List<QuizOptionModel> rightOptions = [];

      // Try 1: Using isCorrect classification
      leftOptions = question.options.where((o) => o.isCorrect == true).toList();
      rightOptions = question.options.where((o) => o.isCorrect == false).toList();

      // Try 2: If isCorrect fails, use metadataJson (standard for this backend)
      if (leftOptions.isEmpty || rightOptions.isEmpty) {
        try {
          final metadata = question.metadataJson != null 
              ? Map<String, dynamic>.from(jsonDecode(question.metadataJson!)) 
              : <String, dynamic>{};
          
          final leftTexts = List<String>.from(metadata['left'] ?? []);
          final rightTexts = List<String>.from(metadata['right'] ?? []);

          if (leftTexts.isNotEmpty && rightTexts.isNotEmpty) {
            final availableOptions = List<QuizOptionModel>.from(question.options);
            leftOptions = [];
            rightOptions = [];

            for (var text in leftTexts) {
              final cleanText = text.trim().toLowerCase();
              final idx = availableOptions.indexWhere((o) => o.text.trim().toLowerCase() == cleanText);
              if (idx != -1) {
                leftOptions.add(availableOptions.removeAt(idx));
              }
            }
            for (var text in rightTexts) {
              final cleanText = text.trim().toLowerCase();
              final idx = availableOptions.indexWhere((o) => o.text.trim().toLowerCase() == cleanText);
              if (idx != -1) {
                rightOptions.add(availableOptions.removeAt(idx));
              }
            }
          }
        } catch (_) {
          // Fallback to empty if parsing fails
        }
      }

      if (leftOptions.isEmpty && rightOptions.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: GameQuizColors.incorrect, size: 48),
              const SizedBox(height: 16),
              Text(
                "Dữ liệu câu hỏi nối thẻ không hợp lệ.\n(Kiểm tra metadataJson hoặc thuộc tính isCorrect)",
                textAlign: TextAlign.center,
                style: TextStyle(color: GameQuizColors.textSecondary),
              ),
            ],
          ),
        );
      }

      return GameMatchingWidget(
        key: ValueKey(question.questionId),
        leftItems: leftOptions
            .map((o) => MatchingItem(id: o.optionId, text: o.text, isLeft: true))
            .toList(),
        rightItems: rightOptions
            .map((o) => MatchingItem(id: o.optionId, text: o.text, isLeft: false))
            .toList(),
        matchedIds: {
          ...(answer?.matchingPairs.keys ?? []),
          ...(answer?.matchingPairs.values ?? []),
        },
        onUnmatch: (id) {
          final newPairs = Map<String, String>.from(answer?.matchingPairs ?? {});
          // If it's a left ID (key), remove the entry
          if (newPairs.containsKey(id)) {
            newPairs.remove(id);
          } else {
            // If it's a right ID (value), find which left ID is matched to it and remove
            newPairs.removeWhere((k, v) => v == id);
          }
          onSetMatching(newPairs);
        },
        onMatchAttempt: (left, right) {
          final newPairs = Map<String, String>.from(answer?.matchingPairs ?? {});
          
          // Enforce 1-1 matching: if this right side was already matched, remove the old left side
          newPairs.removeWhere((k, v) => v == right);
          
          newPairs[left] = right;
          onSetMatching(newPairs);
        },
      );
    }

    if (question.isOrdering) {
      return GameOrderingWidget(
        key: ValueKey(question.questionId),
        options: question.options
            .map((o) => GameOrderingOption(id: o.optionId, text: o.text))
            .toList(),
        onOrderChanged: onSetOrdering,
        initialOrder: answer?.orderingOptionIds ?? [],
      );
    }

    return Center(
      child: Text(
        "Loại câu hỏi này chưa hỗ trợ phong cách Game.",
        style: TextStyle(color: GameQuizColors.textSecondary),
      ),
    );
  }
}
