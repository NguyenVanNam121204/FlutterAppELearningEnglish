import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    this.matchingPairs = const {},
  });

  final List<MatchingItem> leftItems;
  final List<MatchingItem> rightItems;
  final Function(String leftId, String rightId) onMatchAttempt;
  final Function(String id)? onUnmatch;
  final Set<String> matchedIds;
  final Map<String, String> matchingPairs;

  @override
  State<GameMatchingWidget> createState() => _GameMatchingWidgetState();
}

class _GameMatchingWidgetState extends State<GameMatchingWidget> {
  String? selectedLeftId;
  String? selectedRightId;

  // Danh sách các màu cố định cho các cặp nối (7 màu rực rỡ)
  final List<Color> pairColors = [
    const Color(0xFF00F0FF), // Neon Blue
    const Color(0xFFFFCC00), // Gold
    const Color(0xFFFF6B6B), // Coral
    const Color(0xFFA29BFE), // Soft Purple
    const Color(0xFF55E6C1), // Mint
    const Color(0xFFFD79FB), // Pink
    const Color(0xFFFAB1A0), // Peach
  ];

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
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column
          Expanded(
            child: Column(
              children: widget.leftItems
                  .map((item) => _buildMatchingCard(item, true))
                  .toList(),
            ),
          ),
          const SizedBox(width: 20),
          // Right Column
          Expanded(
            child: Column(
              children: widget.rightItems
                  .map((item) => _buildMatchingCard(item, false))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchingCard(MatchingItem item, bool isLeft) {
    final isMatched = widget.matchedIds.contains(item.id);
    final isSelected = (isLeft ? selectedLeftId : selectedRightId) == item.id;

    // Tìm index của cặp đã matched để lấy màu đồng nhất
    int matchIndex = -1;
    if (isMatched) {
      if (isLeft) {
        matchIndex = widget.leftItems.indexWhere((l) => l.id == item.id);
      } else {
        String? partnerLeftId;
        widget.matchingPairs.forEach((leftId, rightId) {
          if (rightId == item.id) {
            partnerLeftId = leftId;
          }
        });

        if (partnerLeftId != null) {
          matchIndex = widget.leftItems.indexWhere(
            (l) => l.id == partnerLeftId,
          );
        }
      }
    }

    final matchColor = matchIndex != -1
        ? pairColors[matchIndex % pairColors.length]
        : GameQuizColors.correct;

    final borderColor = isMatched
        ? matchColor
        : isSelected
        ? const Color(0xFF0EA5E9)
        : Colors.white.withValues(alpha: 0.1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => _onItemTap(item),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 120, maxHeight: 120),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isMatched
                    ? matchColor.withValues(alpha: 0.1)
                    : isSelected
                    ? const Color(0xFF0EA5E9).withValues(alpha: 0.15)
                    : GameQuizColors.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: borderColor,
                  width: (isMatched || isSelected) ? 2.5 : 1.5,
                ),
                boxShadow: isMatched
                    ? [
                        BoxShadow(
                          color: matchColor.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  item.text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: (isMatched || isSelected)
                        ? Colors.white
                        : const Color(0xFFE2E8F0),
                    fontWeight: (isMatched || isSelected)
                        ? FontWeight.w900
                        : FontWeight.w600,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ),
            ),
            if (isMatched && matchIndex != -1)
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: matchColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${matchIndex + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
