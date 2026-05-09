import 'package:flutter/material.dart';
import 'game_quiz_constants.dart';

class GameOrderingOption {
  final String id;
  final String text;
  const GameOrderingOption({required this.id, required this.text});
}

class GameOrderingWidget extends StatefulWidget {
  const GameOrderingWidget({
    super.key,
    required this.options,
    required this.onOrderChanged,
    this.initialOrder = const [],
  });

  final List<GameOrderingOption> options;
  final Function(List<String>) onOrderChanged; // Returns IDs
  final List<String> initialOrder; // Contains IDs

  @override
  State<GameOrderingWidget> createState() => _GameOrderingWidgetState();
}

class _GameOrderingWidgetState extends State<GameOrderingWidget> {
  late List<String> currentOrder; // List of IDs
  late List<GameOrderingOption> availableOptions;

  @override
  void initState() {
    super.initState();
    currentOrder = List.from(widget.initialOrder);
    _updateAvailable();
  }

  void _updateAvailable() {
    availableOptions = List.from(widget.options);
    availableOptions.removeWhere((opt) => currentOrder.contains(opt.id));
  }

  void _addItem(String id) {
    setState(() {
      currentOrder.add(id);
      _updateAvailable();
      widget.onOrderChanged(currentOrder);
    });
  }

  void _removeItem(int index) {
    setState(() {
      currentOrder.removeAt(index);
      _updateAvailable();
      widget.onOrderChanged(currentOrder);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Drop Zone
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 150),
          padding: const EdgeInsets.all(16),
          decoration: GameQuizStyles.glassDecoration(opacity: 0.05),
          child: Wrap(
            spacing: 8,
            runSpacing: 12,
            children: [
              ...currentOrder.asMap().entries.map((entry) {
                final option = widget.options.firstWhere(
                  (o) => o.id == entry.value,
                  orElse: () => GameOrderingOption(id: entry.value, text: entry.value),
                );
                return GestureDetector(
                  onTap: () => _removeItem(entry.key),
                  child: _buildOrderPill(option.text, isOrdered: true),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 48),
        
        // Options Zone
        const Text(
          "Chạm để sắp xếp thứ tự câu:",
          style: TextStyle(color: GameQuizColors.textSecondary, fontSize: 16),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ...availableOptions.map((option) {
              return GestureDetector(
                onTap: () => _addItem(option.id),
                child: _buildOrderPill(option.text),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderPill(String text, {bool isOrdered = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isOrdered ? GameQuizColors.primary.withValues(alpha: 0.2) : GameQuizColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOrdered ? GameQuizColors.secondary : Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: isOrdered ? GameQuizStyles.neonShadow(GameQuizColors.secondary) : null,
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }
}
