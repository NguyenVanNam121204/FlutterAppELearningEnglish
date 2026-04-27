import 'package:flutter/material.dart';

import '../../../../models/quiz/quiz_models.dart';
import '../../../../viewmodels/quiz/quiz_screen_viewmodel.dart';
import 'question_card_shell.dart';
import 'question_type_styles.dart';

class FillBlankQuestion extends StatefulWidget {
  const FillBlankQuestion({
    super.key,
    required this.question,
    required this.answer,
    required this.hasAttempt,
    required this.questionLabel,
    required this.onTextChanged,
  });

  final QuizQuestionModel question;
  final QuizAnswerModel? answer;
  final bool hasAttempt;
  final String questionLabel;
  final ValueChanged<String> onTextChanged;

  @override
  State<FillBlankQuestion> createState() => _FillBlankQuestionState();
}

class _FillBlankQuestionState extends State<FillBlankQuestion> {
  late final TextEditingController _singleInputController;
  final List<TextEditingController> _blankControllers =
      <TextEditingController>[];

  @override
  void initState() {
    super.initState();
    _singleInputController = TextEditingController(
      text: widget.answer?.textAnswer ?? '',
    );
    _setupBlankControllers();
  }

  @override
  void didUpdateWidget(covariant FillBlankQuestion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.questionId != widget.question.questionId) {
      _singleInputController.text = widget.answer?.textAnswer ?? '';
      _disposeBlankControllers();
      _setupBlankControllers();
      return;
    }

    if (oldWidget.answer?.textAnswer != widget.answer?.textAnswer &&
        (widget.answer?.textAnswer ?? '') != _singleInputController.text) {
      _singleInputController.text = widget.answer?.textAnswer ?? '';
    }
  }

  @override
  void dispose() {
    _singleInputController.dispose();
    _disposeBlankControllers();
    super.dispose();
  }

  void _setupBlankControllers() {
    final parts = _splitQuestionParts(widget.question.content);
    final blanks = parts.where((p) => _isBlankToken(p)).length;
    final answers = (widget.answer?.textAnswer ?? '')
        .split(',')
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList();

    if (blanks <= 0) return;
    for (var i = 0; i < blanks; i++) {
      _blankControllers.add(
        TextEditingController(text: i < answers.length ? answers[i] : ''),
      );
    }
  }

  void _disposeBlankControllers() {
    for (final controller in _blankControllers) {
      controller.dispose();
    }
    _blankControllers.clear();
  }

  List<String> _splitQuestionParts(String content) {
    final exp = RegExp(r'\[.*?\]');
    final parts = <String>[];
    var current = 0;

    for (final match in exp.allMatches(content)) {
      if (match.start > current) {
        parts.add(content.substring(current, match.start));
      }
      parts.add(content.substring(match.start, match.end));
      current = match.end;
    }

    if (current < content.length) {
      parts.add(content.substring(current));
    }

    return parts;
  }

  bool _isBlankToken(String part) {
    return part.startsWith('[') && part.endsWith(']');
  }

  @override
  Widget build(BuildContext context) {
    final parts = _splitQuestionParts(widget.question.content);
    final blanksCount = parts.where((part) => _isBlankToken(part)).length;

    return QuestionCardShell(
      questionLabel: widget.questionLabel,
      questionText: blanksCount > 0
          ? 'Dien vao cho trong:'
          : widget.question.content,
      child: blanksCount > 0
          ? _buildInlineBlanks(context, parts)
          : _buildSingleInput(context),
    );
  }

  Widget _buildInlineBlanks(BuildContext context, List<String> parts) {
    var blankIndex = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final part in parts)
              if (_isBlankToken(part))
                SizedBox(
                  width: 130,
                  child: TextField(
                    controller: _blankControllers[blankIndex++],
                    enabled: widget.hasAttempt,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '......',
                      filled: true,
                      fillColor: QuizQuestionStyles.infoBackground(context),
                      border: const UnderlineInputBorder(),
                    ),
                    onChanged: (_) => _submitJoinedBlanks(),
                  ),
                )
              else
                Text(part, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: QuizQuestionStyles.infoBackground(context),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text('Nhap tung o trong theo noi dung cau hoi.'),
        ),
      ],
    );
  }

  Widget _buildSingleInput(BuildContext context) {
    return TextField(
      controller: _singleInputController,
      enabled: widget.hasAttempt,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        hintText: 'Nhap dap an tai day',
        filled: true,
        fillColor: QuizQuestionStyles.subtleBackground(context),
      ),
      onChanged: (value) => widget.onTextChanged(value.trim()),
    );
  }

  void _submitJoinedBlanks() {
    final joined = _blankControllers
        .map((controller) => controller.text.trim())
        .join(', ');
    widget.onTextChanged(joined);
  }
}
