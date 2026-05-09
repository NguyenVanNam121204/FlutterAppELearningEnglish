import 'package:flutter/material.dart';
import 'game_quiz_constants.dart';

class MatchingItem {
  final String id;
  final String text;
  final bool isLeft;

  MatchingItem({required this.id, required this.text, required this.isLeft});
}

class GameMatchingWidget extends StatefulWidget {
  const GameMatchingWidget({
    super.key,
    required this.leftItems,
    required this.rightItems,
    required this.onMatchAttempt,
    this.onUnmatch,
    this.matchedIds = const {},
  });

  final List<MatchingItem> leftItems;
  final List<MatchingItem> rightItems;
  final Function(String leftId, String rightId) onMatchAttempt;
  final Function(String id)? onUnmatch;
  final Set<String> matchedIds;

  @override
  State<GameMatchingWidget> createState() => _GameMatchingWidgetState();
}

class _GameMatchingWidgetState extends State<GameMatchingWidget> {
  String? selectedLeftId;
  String? selectedRightId;

  void _onItemTap(MatchingItem item) {
    if (widget.matchedIds.contains(item.id)) {
      widget.onUnmatch?.call(item.id);
      return;
    }

    setState(() {
      if (item.isLeft) {
        selectedLeftId = (selectedLeftId == item.id) ? null : item.id;
      } else {
        selectedRightId = (selectedRightId == item.id) ? null : item.id;
      }

      if (selectedLeftId != null && selectedRightId != null) {
        widget.onMatchAttempt(selectedLeftId!, selectedRightId!);
        selectedLeftId = null;
        selectedRightId = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column
          Expanded(
            child: Column(
              children: widget.leftItems.map((item) => _buildMatchingCard(item, true)).toList(),
            ),
          ),
          const SizedBox(width: 16),
          // Right Column
          Expanded(
            child: Column(
              children: widget.rightItems.map((item) => _buildMatchingCard(item, false)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchingCard(MatchingItem item, bool isLeft) {
    final isMatched = widget.matchedIds.contains(item.id);
    final isSelected = (isLeft ? selectedLeftId : selectedRightId) == item.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _onItemTap(item),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isMatched
                ? GameQuizColors.correct.withValues(alpha: 0.15)
                : isSelected
                    ? GameQuizColors.primary.withValues(alpha: 0.3)
                    : GameQuizColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isMatched
                  ? GameQuizColors.correct
                  : isSelected
                      ? GameQuizColors.secondary
                      : Colors.white.withValues(alpha: 0.1),
              width: 2,
            ),
            boxShadow: isMatched
                ? GameQuizStyles.neonShadow(GameQuizColors.correct)
                : isSelected
                    ? GameQuizStyles.neonShadow(GameQuizColors.secondary)
                    : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item.text,
                  textAlign: isLeft ? TextAlign.center : TextAlign.left,
                  style: TextStyle(
                    color: (isMatched || isSelected) ? Colors.white : GameQuizColors.textSecondary,
                    fontWeight: (isMatched || isSelected) ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              if (isMatched) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle, color: GameQuizColors.correct, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
