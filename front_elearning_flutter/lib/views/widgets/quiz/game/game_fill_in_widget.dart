import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_quiz_constants.dart';

class QuizFragment {
  final String text;
  final bool isBlank;
  final int? blankIndex;

  QuizFragment({required this.text, this.isBlank = false, this.blankIndex});
}

class GameFillInWidget extends StatefulWidget {
  const GameFillInWidget({
    super.key,
    required this.content,
    required this.onAnswerChanged,
    this.initialAnswers = const {},
  });

  final String content;
  final Function(Map<int, String>) onAnswerChanged;
  final Map<int, String> initialAnswers;

  @override
  State<GameFillInWidget> createState() => _GameFillInWidgetState();
}

class _GameFillInWidgetState extends State<GameFillInWidget> {
  late List<QuizFragment> fragments;
  late Map<int, String> currentAnswers;

  @override
  void initState() {
    super.initState();
    currentAnswers = Map.from(widget.initialAnswers);
    _parseContent();
  }

  void _parseContent() {
    fragments = [];
    final regex = RegExp(r'\[(.*?)\]');
    final matches = regex.allMatches(widget.content);

    int lastEnd = 0;
    int blankCounter = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        fragments.add(QuizFragment(
          text: widget.content.substring(lastEnd, match.start),
        ));
      }
      fragments.add(QuizFragment(
        text: match.group(1) ?? '',
        isBlank: true,
        blankIndex: blankCounter++,
      ));
      lastEnd = match.end;
    }

    if (lastEnd < widget.content.length) {
      fragments.add(QuizFragment(text: widget.content.substring(lastEnd)));
    }
  }

  void _onBlankChanged(int index, String value) {
    setState(() {
      currentAnswers[index] = value;
    });
    widget.onAnswerChanged(currentAnswers);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: GameQuizStyles.glassDecoration(opacity: 0.1, borderRadius: 24),
      child: Wrap(
        spacing: 12,
        runSpacing: 24,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ...fragments.map((f) {
            if (f.isBlank) {
              return GameLetterBoxGroup(
                length: f.text.length,
                initialValue: currentAnswers[f.blankIndex] ?? '',
                onChanged: (val) => _onBlankChanged(f.blankIndex!, val),
              );
            } else {
              return Text(
                f.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              );
            }
          }),
        ],
      ),
    );
  }
}

class GameLetterBoxGroup extends StatefulWidget {
  const GameLetterBoxGroup({
    super.key,
    required this.length,
    required this.onChanged,
    this.initialValue = '',
  });

  final int length;
  final String initialValue;
  final Function(String) onChanged;

  @override
  State<GameLetterBoxGroup> createState() => _GameLetterBoxGroupState();
}

class _GameLetterBoxGroupState extends State<GameLetterBoxGroup> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (i) => TextEditingController(
        text: widget.initialValue.length > i ? widget.initialValue[i] : '',
      ),
    );
    _focusNodes = List.generate(widget.length, (i) => FocusNode());
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _updateValue() {
    final value = _controllers.map((c) => c.text).join();
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(widget.length, (index) {
        return _buildLetterBox(index);
      }),
    );
  }

  Widget _buildLetterBox(int index) {
    final isFilled = _controllers[index].text.isNotEmpty;
    final isFocused = _focusNodes[index].hasFocus;
    
    return Container(
      width: 26,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: (isFilled || isFocused)
                ? GameQuizColors.secondary 
                : GameQuizColors.secondary.withValues(alpha: 0.3),
            width: 3.0,
          ),
        ),
      ),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent && 
              event.logicalKey == LogicalKeyboardKey.backspace &&
              _controllers[index].text.isEmpty &&
              index > 0) {
            _focusNodes[index - 1].requestFocus();
            _controllers[index - 1].clear();
          }
        },
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          maxLength: 1,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
          style: TextStyle(
            color: (isFilled || isFocused) ? GameQuizColors.secondary : Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          cursorColor: GameQuizColors.secondary,
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
            filled: false,
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              if (index < widget.length - 1) {
                _focusNodes[index + 1].requestFocus();
              }
            }
            _updateValue();
            setState(() {});
          },
        ),
      ),
    );
  }
}
