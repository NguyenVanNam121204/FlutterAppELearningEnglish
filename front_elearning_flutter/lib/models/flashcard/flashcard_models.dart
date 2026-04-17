class FlashcardModel {
  const FlashcardModel({
    required this.flashCardId,
    required this.term,
    required this.definition,
    required this.pronunciation,
    required this.partOfSpeech,
    required this.exampleSentence,
    required this.exampleTranslation,
    required this.audioUrl,
    required this.imageUrl,
  });

  final String flashCardId;
  final String term;
  final String definition;
  final String pronunciation;
  final String partOfSpeech;
  final String exampleSentence;
  final String exampleTranslation;
  final String audioUrl;
  final String imageUrl;

  String get reviewFront => term;
  String get reviewBack => definition;

  FlashcardModel copyWith({
    String? flashCardId,
    String? term,
    String? definition,
    String? pronunciation,
    String? partOfSpeech,
    String? exampleSentence,
    String? exampleTranslation,
    String? audioUrl,
    String? imageUrl,
  }) {
    return FlashcardModel(
      flashCardId: flashCardId ?? this.flashCardId,
      term: term ?? this.term,
      definition: definition ?? this.definition,
      pronunciation: pronunciation ?? this.pronunciation,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      exampleTranslation: exampleTranslation ?? this.exampleTranslation,
      audioUrl: audioUrl ?? this.audioUrl,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  static String _firstNonEmpty(Iterable<Object?> values) {
    for (final raw in values) {
      if (raw == null) continue;
      final value = raw.toString().trim();
      if (value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }
    return '';
  }

  factory FlashcardModel.fromJson(Map<String, dynamic> json) {
    final nested = json['flashCard'];
    final nestedMap = nested is Map<String, dynamic> ? nested : null;
    final source = nestedMap != null
        ? <String, dynamic>{...nestedMap, ...json}
        : json;

    return FlashcardModel(
      flashCardId: _firstNonEmpty([
        source['flashCardId'],
        source['flashcardId'],
        source['FlashCardId'],
        source['FlashcardId'],
        source['cardId'],
        source['CardId'],
        json['flashCardId'],
        json['flashcardId'],
        json['FlashCardId'],
        json['FlashcardId'],
        json['cardId'],
        json['CardId'],
        nestedMap?['flashCardId'],
        nestedMap?['flashcardId'],
        nestedMap?['FlashCardId'],
        nestedMap?['FlashcardId'],
        nestedMap?['cardId'],
        nestedMap?['CardId'],
        source['id'],
        source['Id'],
        json['id'],
        json['Id'],
        nestedMap?['id'],
        nestedMap?['Id'],
      ]),
      term:
          (source['term'] ??
                  source['Term'] ??
                  source['frontText'] ??
                  source['word'] ??
                  source['Word'] ??
                  '')
              .toString(),
      definition:
          (source['definition'] ??
                  source['Definition'] ??
                  source['backText'] ??
                  source['meaning'] ??
                  source['Meaning'] ??
                  '')
              .toString(),
      pronunciation: (source['pronunciation'] ?? source['Pronunciation'] ?? '')
          .toString(),
      partOfSpeech: (source['partOfSpeech'] ?? source['PartOfSpeech'] ?? 'word')
          .toString(),
      exampleSentence:
          (source['exampleSentence'] ??
                  source['ExampleSentence'] ??
                  source['example'] ??
                  source['Example'] ??
                  '')
              .toString(),
      exampleTranslation:
          (source['exampleTranslation'] ??
                  source['ExampleTranslation'] ??
                  source['exampleVi'] ??
                  source['ExampleVi'] ??
                  '')
              .toString(),
      audioUrl: (source['audioUrl'] ?? source['AudioUrl'] ?? '').toString(),
      imageUrl: (source['imageUrl'] ?? source['ImageUrl'] ?? '').toString(),
    );
  }
}
