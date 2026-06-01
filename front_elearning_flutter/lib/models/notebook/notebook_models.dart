import '../flashcard/flashcard_models.dart';

class NotebookModel {
  const NotebookModel({
    required this.flashcard,
    this.savedAt,
    this.isMastered = false,
  });

  final FlashcardModel flashcard;
  final DateTime? savedAt;
  final bool isMastered;

  factory NotebookModel.fromJson(Map<String, dynamic> json) {
    final nextReviewDate = _parseDate(
      json['nextReviewDate'] ?? json['NextReviewDate'],
    );
    // In many SRS systems, a date far in the future or null next review date means mastered
    final isMasteredFlag =
        (json['isMastered'] ?? json['IsMastered'] ?? false) as bool;
    final isMasteredByDate =
        nextReviewDate != null && nextReviewDate.year > 2100;

    return NotebookModel(
      flashcard: FlashcardModel.fromJson(json),
      savedAt: _parseDate(json['savedAt'] ?? json['SavedAt']),
      isMastered: isMasteredFlag || isMasteredByDate,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
