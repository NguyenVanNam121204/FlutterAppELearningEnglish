import 'package:flutter/material.dart';
import 'game_quiz_constants.dart';

class GameMultipleChoiceWidget extends StatelessWidget {
  const GameMultipleChoiceWidget({
    super.key,
    required this.question,
    required this.options,
    required this.selectedOptionId,
    required this.onOptionSelected,
  });

  final String question;
  final List<GameQuizOption> options;
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
        const SizedBox(height: 32),
        
        // Options List
        ...options.map((option) {
          final isSelected = selectedOptionId == option.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GestureDetector(
              onTap: () => onOptionSelected(option.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                transform: Matrix4.diagonal3Values(isSelected ? 1.02 : 1.0, isSelected ? 1.02 : 1.0, 1.0),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                ),
                child: Row(
                  children: [
                    // Index Indicator (A, B, C...)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? GameQuizColors.secondary 
                            : Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          option.label,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Option Text
                    Expanded(
                      child: Text(
                        option.text,
                        style: TextStyle(
                          color: isSelected ? Colors.white : GameQuizColors.textSecondary,
                          fontSize: 18,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                    // Checkmark if selected
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: GameQuizColors.secondary,
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

class GameQuizOption {
  final String id;
  final String label;
  final String text;

  GameQuizOption({required this.id, required this.label, required this.text});
}
