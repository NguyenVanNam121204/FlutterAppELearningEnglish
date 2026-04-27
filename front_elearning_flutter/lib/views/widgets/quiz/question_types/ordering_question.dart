import 'package:flutter/material.dart';

import '../../../../models/quiz/quiz_models.dart';
import '../../../../viewmodels/quiz/quiz_screen_viewmodel.dart';
import 'question_card_shell.dart';
import 'question_type_styles.dart';

class OrderingQuestion extends StatefulWidget {
  const OrderingQuestion({
    super.key,
    required this.question,
    required this.answer,
    required this.hasAttempt,
    required this.questionLabel,
    required this.onSetOrdering,
  });

  final QuizQuestionModel question;
  final QuizAnswerModel? answer;
  final bool hasAttempt;
  final String questionLabel;
  final ValueChanged<List<String>> onSetOrdering;

  @override
  State<OrderingQuestion> createState() => _OrderingQuestionState();
}

class _OrderingQuestionState extends State<OrderingQuestion> {
  List<String> _orderingIds = const <String>[];

  @override
  void initState() {
    super.initState();
    _syncOrderingFromAnswer();
  }

  @override
  void didUpdateWidget(covariant OrderingQuestion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.questionId != widget.question.questionId ||
        oldWidget.answer != widget.answer) {
      _syncOrderingFromAnswer();
    }
  }

  void _syncOrderingFromAnswer() {
    final currentIds = widget.answer?.orderingOptionIds ?? const <String>[];
    final optionIds = widget.question.options.map((o) => o.optionId).toList();

    if (currentIds.isEmpty) {
      _orderingIds = optionIds;
      return;
    }

    final merged = <String>[];
    for (final id in currentIds) {
      if (optionIds.contains(id) && !merged.contains(id)) {
        merged.add(id);
      }
    }
    for (final id in optionIds) {
      if (!merged.contains(id)) {
        merged.add(id);
      }
    }
    _orderingIds = merged;
  }

  @override
  Widget build(BuildContext context) {
    final idToOption = <String, QuizOptionModel>{
      for (final option in widget.question.options) option.optionId: option,
    };
    final orderedOptions = _orderingIds
        .map((id) => idToOption[id])
        .whereType<QuizOptionModel>()
        .toList();

    return QuestionCardShell(
      questionLabel: widget.questionLabel,
      questionText: widget.question.content,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: QuizQuestionStyles.infoBackground(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('Sap xep dap an bang mui ten len va xuong.'),
          ),
          const SizedBox(height: 12),
          for (final entry in orderedOptions.asMap().entries)
            _buildOrderingTile(
              context,
              entry.key,
              entry.value,
              orderedOptions.length,
            ),
        ],
      ),
    );
  }

  Widget _buildOrderingTile(
    BuildContext context,
    int index,
    QuizOptionModel option,
    int length,
  ) {
    final isFirst = index == 0;
    final isLast = index == length - 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: QuizQuestionStyles.cardBorder(context)),
        color: QuizQuestionStyles.subtleBackground(context),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(option.text)),
          IconButton(
            onPressed: (!widget.hasAttempt || isFirst)
                ? null
                : () => _moveOrdering(index, -1),
            icon: const Icon(Icons.keyboard_arrow_up),
          ),
          IconButton(
            onPressed: (!widget.hasAttempt || isLast)
                ? null
                : () => _moveOrdering(index, 1),
            icon: const Icon(Icons.keyboard_arrow_down),
          ),
        ],
      ),
    );
  }

  void _moveOrdering(int index, int delta) {
    final nextIndex = index + delta;
    if (nextIndex < 0 || nextIndex >= _orderingIds.length) return;

    final reordered = List<String>.from(_orderingIds);
    final item = reordered.removeAt(index);
    reordered.insert(nextIndex, item);

    setState(() => _orderingIds = reordered);
    widget.onSetOrdering(reordered);
  }
}
