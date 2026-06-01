import 'package:flutter/material.dart';
import 'game_quiz_constants.dart';

class GameMultiSelectWidget extends StatelessWidget {
  const GameMultiSelectWidget({
    super.key,
    required this.question,
    required this.options,
    required this.selectedOptionIds,
    required this.onOptionToggled,
  });

  final String question;
  final List<GameMultiSelectOption> options;
  final Set<String> selectedOptionIds;
  final Function(String, bool) onOptionToggled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Question Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: GameQuizStyles.glassDecoration(
            opacity: 0.1,
            borderRadius: 24,
          ),
          child: Column(
            children: [
              Text(
                question,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "(Chọn nhiều đáp án)",
                style: TextStyle(
                  color: GameQuizColors.secondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Options List
        ...options.map((option) {
          final isSelected = selectedOptionIds.contains(option.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GestureDetector(
              onTap: () => onOptionToggled(option.id, !isSelected),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? GameQuizColors.primary.withValues(alpha: 0.2)
                      : GameQuizColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? GameQuizColors.secondary
                        : Colors.white.withValues(alpha: 0.1),
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? GameQuizStyles.neonShadow(GameQuizColors.secondary)
                      : null,
                ),
                child: Row(
                  children: [
                    // Checkbox indicator
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? GameQuizColors.secondary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? GameQuizColors.secondary
                              : Colors.white38,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 20,
                              color: Colors.black,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    // Option Text
                    Expanded(
                      child: Text(
                        option.text,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : GameQuizColors.textSecondary,
                          fontSize: 18,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class GameMultiSelectOption {
  final String id;
  final String text;

  GameMultiSelectOption({required this.id, required this.text});
}
