import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../models/quiz/quiz_models.dart';
import '../../../../viewmodels/quiz/quiz_screen_viewmodel.dart';
import 'question_card_shell.dart';
import 'question_type_styles.dart';

class MatchingQuestion extends StatefulWidget {
  const MatchingQuestion({
    super.key,
    required this.question,
    required this.answer,
    required this.hasAttempt,
    required this.questionLabel,
    required this.onSetMatching,
  });

  final QuizQuestionModel question;
  final QuizAnswerModel? answer;
  final bool hasAttempt;
  final String questionLabel;
  final ValueChanged<Map<String, String>> onSetMatching;

  @override
  State<MatchingQuestion> createState() => _MatchingQuestionState();
}

class _MatchingQuestionState extends State<MatchingQuestion> {
  String? _selectedLeftId;
  String? _selectedRightId;

  @override
  void didUpdateWidget(covariant MatchingQuestion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.questionId != widget.question.questionId) {
      _selectedLeftId = null;
      _selectedRightId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pairs = widget.answer?.matchingPairs ?? const <String, String>{};
    final (left, right) = _resolveColumns(widget.question);

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
            child: const Text(
              'Chon cot trai, sau do chon cot phai de noi cap.',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildColumn(
                  context,
                  title: 'Cot trai',
                  options: left,
                  isLeft: true,
                  pairs: pairs,
                  right: right,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildColumn(
                  context,
                  title: 'Cot phai',
                  options: right,
                  isLeft: false,
                  pairs: pairs,
                  right: right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Da noi ${pairs.length}/${left.length} cap'),
        ],
      ),
    );
  }

  Widget _buildColumn(
    BuildContext context, {
    required String title,
    required List<QuizOptionModel> options,
    required bool isLeft,
    required Map<String, String> pairs,
    required List<QuizOptionModel> right,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        for (final entry in options.asMap().entries)
          _buildMatchingItem(
            context,
            option: entry.value,
            isLeft: isLeft,
            index: entry.key,
            pairs: pairs,
            rightOptions: right,
          ),
      ],
    );
  }

  Widget _buildMatchingItem(
    BuildContext context, {
    required QuizOptionModel option,
    required bool isLeft,
    required int index,
    required Map<String, String> pairs,
    required List<QuizOptionModel> rightOptions,
  }) {
    final selected = isLeft
        ? _selectedLeftId == option.optionId
        : _selectedRightId == option.optionId;
    final matched = isLeft
        ? pairs[option.optionId] != null
        : pairs.values.contains(option.optionId);

    String? rightText;
    if (isLeft) {
      for (final item in rightOptions) {
        if (item.optionId == pairs[option.optionId]) {
          rightText = item.text;
          break;
        }
      }
    }

    return InkWell(
      onTap: !widget.hasAttempt
          ? null
          : () => _onTapOption(
              isLeft: isLeft,
              optionId: option.optionId,
              pairs: pairs,
            ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : matched
                ? const Color(0xFF10B981)
                : QuizQuestionStyles.cardBorder(context),
            width: 2,
          ),
          color: matched
              ? QuizQuestionStyles.successBackground(context)
              : selected
              ? QuizQuestionStyles.activeBackground(context)
              : QuizQuestionStyles.subtleBackground(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 11,
                  child: Text(
                    isLeft ? '${index + 1}' : String.fromCharCode(65 + index),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(option.text)),
                if (matched && isLeft)
                  const Icon(
                    Icons.check_circle,
                    size: 18,
                    color: Color(0xFF10B981),
                  ),
              ],
            ),
            if ((rightText ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '-> $rightText',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF059669),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onTapOption({
    required bool isLeft,
    required String optionId,
    required Map<String, String> pairs,
  }) {
    if (isLeft) {
      final alreadyMatched = pairs[optionId];
      if (alreadyMatched != null) {
        final updated = Map<String, String>.from(pairs)..remove(optionId);
        widget.onSetMatching(updated);
        return;
      }
      setState(
        () => _selectedLeftId = _selectedLeftId == optionId ? null : optionId,
      );
      if (_selectedRightId != null) {
        final updated = Map<String, String>.from(pairs)
          ..removeWhere((_, value) => value == _selectedRightId)
          ..[_selectedLeftId!] = _selectedRightId!;
        widget.onSetMatching(updated);
        setState(() {
          _selectedLeftId = null;
          _selectedRightId = null;
        });
      }
      return;
    }

    if (pairs.values.contains(optionId)) return;
    setState(
      () => _selectedRightId = _selectedRightId == optionId ? null : optionId,
    );
    if (_selectedLeftId != null) {
      final updated = Map<String, String>.from(pairs)
        ..removeWhere((_, value) => value == optionId)
        ..[_selectedLeftId!] = optionId;
      widget.onSetMatching(updated);
      setState(() {
        _selectedLeftId = null;
        _selectedRightId = null;
      });
    }
  }

  (List<QuizOptionModel>, List<QuizOptionModel>) _resolveColumns(
    QuizQuestionModel question,
  ) {
    final options = question.options;
    final leftTexts = <String>[];
    final rightTexts = <String>[];

    final rawMeta = question.metadataJson;
    if ((rawMeta ?? '').trim().isNotEmpty) {
      try {
        final parsed = jsonDecode(rawMeta!);
        if (parsed is Map<String, dynamic>) {
          if (parsed['left'] is List) {
            leftTexts.addAll((parsed['left'] as List).map((e) => e.toString()));
          }
          if (parsed['right'] is List) {
            rightTexts.addAll(
              (parsed['right'] as List).map((e) => e.toString()),
            );
          }
        }
      } catch (_) {}
    }

    var left = <QuizOptionModel>[];
    var right = <QuizOptionModel>[];

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

    if (left.isEmpty || right.isEmpty) {
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
