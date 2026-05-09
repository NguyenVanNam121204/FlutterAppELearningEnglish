import 'package:flutter/material.dart';
import 'game_quiz_constants.dart';

class GameTrueFalseWidget extends StatelessWidget {
  const GameTrueFalseWidget({
    super.key,
    required this.question,
    required this.options,
    required this.selectedOptionId,
    required this.onOptionSelected,
  });

  final String question;
  final List<GameTrueFalseOption> options; // Expecting exactly 2 options
  final String? selectedOptionId;
  final Function(String) onOptionSelected;

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
          child: Text(
            question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 48),
        
        // True/False Buttons
        Row(
          children: options.map((option) {
            final isSelected = selectedOptionId == option.id;
            final isTrue = option.text.toLowerCase().contains('true') || 
                          option.text.toLowerCase().contains('đúng') ||
                          option.text.toLowerCase().contains('yes');
            
            final color = isTrue ? GameQuizColors.correct : GameQuizColors.incorrect;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GestureDetector(
                  onTap: () => onOptionSelected(option.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? color.withValues(alpha: 0.2) 
                          : GameQuizColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected 
                            ? color 
                            : Colors.white.withValues(alpha: 0.1),
                        width: 3,
                      ),
                      boxShadow: isSelected ? GameQuizStyles.neonShadow(color) : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isTrue ? Icons.check_circle_outline : Icons.cancel_outlined,
                          size: 48,
                          color: isSelected ? color : GameQuizColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          option.text.toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : GameQuizColors.textSecondary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class GameTrueFalseOption {
  final String id;
  final String text;

  GameTrueFalseOption({required this.id, required this.text});
}
