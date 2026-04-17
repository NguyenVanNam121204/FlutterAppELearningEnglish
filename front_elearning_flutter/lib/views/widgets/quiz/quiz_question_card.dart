import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../models/quiz/quiz_models.dart';
import '../../../viewmodels/quiz/quiz_screen_viewmodel.dart';
import '../common/catalunya_card.dart';

class QuizQuestionCard extends StatefulWidget {
  const QuizQuestionCard({
    super.key,
    required this.question,
    required this.answer,
    required this.hasAttempt,
    required this.onTextChanged,
    required this.onToggleMulti,
    required this.onSelectSingle,
    required this.onSetMatching,
    required this.onSetOrdering,
  });

  final QuizQuestionModel question;
  final QuizAnswerModel? answer;
  final bool hasAttempt;
  final ValueChanged<String> onTextChanged;
  final void Function(String optionId, bool checked) onToggleMulti;
  final ValueChanged<String> onSelectSingle;
  final ValueChanged<Map<String, String>> onSetMatching;
  final ValueChanged<List<String>> onSetOrdering;

  @override
  State<QuizQuestionCard> createState() => _QuizQuestionCardState();
}

class _QuizQuestionCardState extends State<QuizQuestionCard> {
  String? _selectedLeftId;
  String? _selectedRightId;
  List<String> _orderingIds = const <String>[];

  @override
  void initState() {
    super.initState();
    _syncOrderingFromAnswer();
  }

  @override
  void didUpdateWidget(covariant QuizQuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.questionId != widget.question.questionId ||
        oldWidget.answer != widget.answer) {
      _selectedLeftId = null;
      _selectedRightId = null;
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
    final question = widget.question;
    final answer = widget.answer;

    return CatalunyaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question.content),
          const SizedBox(height: 10),
          if (question.isTextQuestion)
            TextFormField(
              enabled: widget.hasAttempt,
              initialValue: answer?.textAnswer,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Nhap dap an',
              ),
              onChanged: widget.onTextChanged,
            )
          else if (question.isMultiChoice)
            ...question.options.map((o) {
              final selected =
                  answer?.multiOptionIds.contains(o.optionId) ?? false;
              return CheckboxListTile(
                value: selected,
                title: Text(o.text),
                onChanged: !widget.hasAttempt
                    ? null
                    : (v) => widget.onToggleMulti(o.optionId, v == true),
              );
            })
          else if (question.isMatching)
            _buildMatching(context)
          else if (question.isOrdering)
            _buildOrdering(context)
          else
            ...question.options.map((o) {
              final selected = answer?.singleOptionId == o.optionId;
              return InkWell(
                onTap: !widget.hasAttempt
                    ? null
                    : () => widget.onSelectSingle(o.optionId),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : const Color(0xFFD5E1F1),
                    ),
                    color: selected ? const Color(0xFFEFF8FF) : Colors.white,
                  ),
                  child: Text(o.text),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMatching(BuildContext context) {
    final pairs = widget.answer?.matchingPairs ?? const <String, String>{};
    final split = _resolveMatchingColumns(widget.question);
    final left = split.$1;
    final right = split.$2;

    String? getMatchedRightId(String leftId) => pairs[leftId];

    bool isRightMatched(String rightId) {
      return pairs.values.any((value) => value == rightId);
    }

    void submitPairs(Map<String, String> value) {
      widget.onSetMatching(value);
      setState(() {
        _selectedLeftId = null;
        _selectedRightId = null;
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Noi cap tuong ung: chon cot trai roi chon cot phai.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final useVertical = constraints.maxWidth < 420;
            if (useVertical) {
              return Column(
                children: [
                  _buildMatchingColumn(
                    context,
                    title: 'Cot trai',
                    options: left,
                    isLeft: true,
                    pairs: pairs,
                    getMatchedRightId: getMatchedRightId,
                    isRightMatched: isRightMatched,
                    submitPairs: submitPairs,
                  ),
                  const SizedBox(height: 12),
                  _buildMatchingColumn(
                    context,
                    title: 'Cot phai',
                    options: right,
                    isLeft: false,
                    pairs: pairs,
                    getMatchedRightId: getMatchedRightId,
                    isRightMatched: isRightMatched,
                    submitPairs: submitPairs,
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildMatchingColumn(
                    context,
                    title: 'Cot trai',
                    options: left,
                    isLeft: true,
                    pairs: pairs,
                    getMatchedRightId: getMatchedRightId,
                    isRightMatched: isRightMatched,
                    submitPairs: submitPairs,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMatchingColumn(
                    context,
                    title: 'Cot phai',
                    options: right,
                    isLeft: false,
                    pairs: pairs,
                    getMatchedRightId: getMatchedRightId,
                    isRightMatched: isRightMatched,
                    submitPairs: submitPairs,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Text('Da noi ${pairs.length}/${left.length} cap'),
      ],
    );
  }

  Widget _buildMatchingColumn(
    BuildContext context, {
    required String title,
    required List<QuizOptionModel> options,
    required bool isLeft,
    required Map<String, String> pairs,
    required String? Function(String leftId) getMatchedRightId,
    required bool Function(String rightId) isRightMatched,
    required ValueChanged<Map<String, String>> submitPairs,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...options.map((option) {
          final selected = isLeft
              ? _selectedLeftId == option.optionId
              : _selectedRightId == option.optionId;
          final matched = isLeft
              ? getMatchedRightId(option.optionId) != null
              : isRightMatched(option.optionId);

          return InkWell(
            onTap: !widget.hasAttempt
                ? null
                : () {
                    if (isLeft) {
                      final existing = getMatchedRightId(option.optionId);
                      if (existing != null) {
                        final updated = Map<String, String>.from(pairs)
                          ..remove(option.optionId);
                        submitPairs(updated);
                        return;
                      }

                      setState(() {
                        _selectedLeftId = _selectedLeftId == option.optionId
                            ? null
                            : option.optionId;
                      });

                      if (_selectedRightId != null) {
                        final updated = Map<String, String>.from(pairs);
                        updated.removeWhere(
                          (_, value) => value == _selectedRightId,
                        );
                        updated[option.optionId] = _selectedRightId!;
                        submitPairs(updated);
                      }
                    } else {
                      if (isRightMatched(option.optionId)) return;
                      setState(() {
                        _selectedRightId = _selectedRightId == option.optionId
                            ? null
                            : option.optionId;
                      });

                      if (_selectedLeftId != null) {
                        final updated = Map<String, String>.from(pairs)
                          ..removeWhere((_, value) => value == option.optionId)
                          ..[_selectedLeftId!] = option.optionId;
                        submitPairs(updated);
                      }
                    }
                  },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : matched
                      ? const Color(0xFF10B981)
                      : const Color(0xFFD5E1F1),
                ),
                color: selected
                    ? const Color(0xFFEFF8FF)
                    : matched
                    ? const Color(0xFFECFDF5)
                    : Colors.white,
              ),
              child: Text(option.text),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildOrdering(BuildContext context) {
    final idToOption = <String, QuizOptionModel>{
      for (final option in widget.question.options) option.optionId: option,
    };
    final orderedOptions = _orderingIds
        .map((id) => idToOption[id])
        .whereType<QuizOptionModel>()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sap xep dap an dung thu tu bang mui ten len/xuong.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        ...orderedOptions.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isFirst = index == 0;
          final isLast = index == orderedOptions.length - 1;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD5E1F1)),
              color: Colors.white,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: const Color(0xFFEFF8FF),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(fontSize: 12),
                  ),
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
        }),
      ],
    );
  }

  void _moveOrdering(int index, int delta) {
    final nextIndex = index + delta;
    if (nextIndex < 0 || nextIndex >= _orderingIds.length) return;
    final reordered = List<String>.from(_orderingIds);
    final item = reordered.removeAt(index);
    reordered.insert(nextIndex, item);
    setState(() {
      _orderingIds = reordered;
    });
    widget.onSetOrdering(reordered);
  }

  (List<QuizOptionModel>, List<QuizOptionModel>) _resolveMatchingColumns(
    QuizQuestionModel question,
  ) {
    final options = question.options;
    final leftTexts = <String>[];
    final rightTexts = <String>[];

    final rawMeta = question.metadataJson;
    if ((rawMeta ?? '').trim().isNotEmpty) {
      try {
        final dynamic parsed = jsonDecode(rawMeta!);
        if (parsed is Map<String, dynamic>) {
          final leftRaw = parsed['left'];
          final rightRaw = parsed['right'];
          if (leftRaw is List) {
            leftTexts.addAll(leftRaw.map((e) => e.toString()));
          }
          if (rightRaw is List) {
            rightTexts.addAll(rightRaw.map((e) => e.toString()));
          }
        }
      } catch (_) {}
    }

    List<QuizOptionModel> left = const <QuizOptionModel>[];
    List<QuizOptionModel> right = const <QuizOptionModel>[];

    if (leftTexts.isNotEmpty) {
      left = leftTexts
          .map((text) {
            for (final option in options) {
              if (option.text.trim() == text.trim()) return option;
            }
            return null;
          })
          .whereType<QuizOptionModel>()
          .toList();
      right = rightTexts
          .map((text) {
            for (final option in options) {
              if (option.text.trim() == text.trim()) return option;
            }
            return null;
          })
          .whereType<QuizOptionModel>()
          .toList();
    }

    if (left.isEmpty) {
      left = options.where((o) => o.isCorrect == true).toList();
      right = options.where((o) => o.isCorrect == false).toList();
    }

    if (left.isEmpty || right.isEmpty) {
      final half = (options.length / 2).ceil();
      left = options.take(half).toList();
      right = options.skip(half).toList();
    }

    return (left, right);
  }
}
