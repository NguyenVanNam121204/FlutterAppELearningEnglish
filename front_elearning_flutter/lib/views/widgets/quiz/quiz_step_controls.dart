import 'package:flutter/material.dart';

class QuizStepControls extends StatelessWidget {
  const QuizStepControls({
    super.key,
    required this.canGoBack,
    required this.canGoNext,
    required this.onBack,
    required this.onNext,
  });

  final bool canGoBack;
  final bool canGoNext;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: canGoBack ? onBack : null,
          icon: const Icon(Icons.chevron_left_rounded),
          label: const Text('Trước'),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: canGoNext ? onNext : null,
          icon: const Icon(Icons.chevron_right_rounded),
          label: const Text('Tiếp'),
        ),
      ],
    );
  }
}
