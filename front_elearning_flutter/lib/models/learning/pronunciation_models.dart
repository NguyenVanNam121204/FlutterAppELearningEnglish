class PronunciationItemModel {
  const PronunciationItemModel({
    required this.flashCardId,
    required this.word,
    required this.meaning,
    required this.phonetic,
    required this.audioUrl,
    required this.imageUrl,
    required this.example,
    required this.progress,
  });

  final int flashCardId;
  final String word;
  final String meaning;
  final String phonetic;
  final String audioUrl;
  final String imageUrl;
  final String example;
  final PronunciationProgressModel progress;

  PronunciationItemModel copyWith({
    int? flashCardId,
    String? word,
    String? meaning,
    String? phonetic,
    String? audioUrl,
    String? imageUrl,
    String? example,
    PronunciationProgressModel? progress,
  }) {
    return PronunciationItemModel(
      flashCardId: flashCardId ?? this.flashCardId,
      word: word ?? this.word,
      meaning: meaning ?? this.meaning,
      phonetic: phonetic ?? this.phonetic,
      audioUrl: audioUrl ?? this.audioUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      example: example ?? this.example,
      progress: progress ?? this.progress,
    );
  }

  factory PronunciationItemModel.fromJson(Map<String, dynamic> json) {
    return PronunciationItemModel(
      flashCardId:
          int.tryParse(
            (json['flashCardId'] ?? json['FlashCardId'] ?? json['id'] ?? 0)
                .toString(),
          ) ??
          0,
      word: (json['word'] ?? json['Word'] ?? 'Word').toString(),
      meaning:
          (json['meaning'] ??
                  json['Meaning'] ??
                  json['definition'] ??
                  json['Definition'] ??
                  '')
              .toString(),
      phonetic:
          (json['phonetic'] ??
                  json['Phonetic'] ??
                  json['ipa'] ??
                  json['Ipa'] ??
                  '')
              .toString(),
      audioUrl: (json['audioUrl'] ?? json['AudioUrl'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? json['ImageUrl'] ?? '').toString(),
      example: (json['example'] ?? json['Example'] ?? '').toString(),
      progress: PronunciationProgressModel.fromJson(
        (json['progress'] ?? json['Progress']) is Map<String, dynamic>
            ? (json['progress'] ?? json['Progress']) as Map<String, dynamic>
            : const {},
      ),
    );
  }
}

class PronunciationProgressModel {
  const PronunciationProgressModel({
    required this.totalAttempts,
    required this.bestScore,
    required this.lastPronunciationScore,
    required this.isMastered,
    required this.status,
  });

  final int totalAttempts;
  final double bestScore;
  final double lastPronunciationScore;
  final bool isMastered;
  final String status;

  PronunciationProgressModel copyWith({
    int? totalAttempts,
    double? bestScore,
    double? lastPronunciationScore,
    bool? isMastered,
    String? status,
  }) {
    return PronunciationProgressModel(
      totalAttempts: totalAttempts ?? this.totalAttempts,
      bestScore: bestScore ?? this.bestScore,
      lastPronunciationScore:
          lastPronunciationScore ?? this.lastPronunciationScore,
      isMastered: isMastered ?? this.isMastered,
      status: status ?? this.status,
    );
  }

  bool get hasPracticed => totalAttempts > 0;

  factory PronunciationProgressModel.fromJson(Map<String, dynamic> json) {
    return PronunciationProgressModel(
      totalAttempts:
          int.tryParse(
            (json['totalAttempts'] ?? json['TotalAttempts'] ?? 0).toString(),
          ) ??
          0,
      bestScore:
          double.tryParse(
            (json['bestScore'] ?? json['BestScore'] ?? 0).toString(),
          ) ??
          0,
      lastPronunciationScore:
          double.tryParse(
            (json['lastPronunciationScore'] ??
                    json['LastPronunciationScore'] ??
                    0)
                .toString(),
          ) ??
          0,
      isMastered:
          (json['isMastered'] ?? json['IsMastered'] ?? false)
              .toString()
              .toLowerCase() ==
          'true',
      status: (json['status'] ?? json['Status'] ?? 'Not Started').toString(),
    );
  }
}

class ModulePronunciationSummaryModel {
  const ModulePronunciationSummaryModel({
    required this.totalFlashcards,
    required this.totalPracticed,
    required this.masteredCount,
    required this.overallProgress,
    required this.averageScore,
    required this.status,
    required this.grade,
    required this.message,
  });

  final int totalFlashcards;
  final int totalPracticed;
  final int masteredCount;
  final double overallProgress;
  final double averageScore;
  final String status;
  final String grade;
  final String message;

  factory ModulePronunciationSummaryModel.fromJson(Map<String, dynamic> json) {
    return ModulePronunciationSummaryModel(
      totalFlashcards:
          int.tryParse(
            (json['totalFlashCards'] ?? json['TotalFlashCards'] ?? 0)
                .toString(),
          ) ??
          0,
      totalPracticed:
          int.tryParse(
            (json['totalPracticed'] ?? json['TotalPracticed'] ?? 0).toString(),
          ) ??
          0,
      masteredCount:
          int.tryParse(
            (json['masteredCount'] ?? json['MasteredCount'] ?? 0).toString(),
          ) ??
          0,
      overallProgress:
          double.tryParse(
            (json['overallProgress'] ?? json['OverallProgress'] ?? 0)
                .toString(),
          ) ??
          0,
      averageScore:
          double.tryParse(
            (json['averageScore'] ?? json['AverageScore'] ?? 0).toString(),
          ) ??
          0,
      status: (json['status'] ?? json['Status'] ?? '').toString(),
      grade: (json['grade'] ?? json['Grade'] ?? '').toString(),
      message: (json['message'] ?? json['Message'] ?? '').toString(),
    );
  }
}

class PronunciationAssessmentResultModel {
  const PronunciationAssessmentResultModel({
    required this.pronunciationScore,
    required this.feedback,
    required this.accuracyScore,
    required this.fluencyScore,
    required this.completenessScore,
  });

  final double pronunciationScore;
  final String feedback;
  final double accuracyScore;
  final double fluencyScore;
  final double completenessScore;

  factory PronunciationAssessmentResultModel.fromJson(
    Map<String, dynamic> json,
  ) {
    double toDouble(dynamic raw) => double.tryParse(raw.toString()) ?? 0;

    return PronunciationAssessmentResultModel(
      pronunciationScore: toDouble(
        json['pronunciationScore'] ?? json['PronunciationScore'],
      ),
      feedback: (json['feedback'] ?? json['Feedback'] ?? '').toString(),
      accuracyScore: toDouble(json['accuracyScore'] ?? json['AccuracyScore']),
      fluencyScore: toDouble(json['fluencyScore'] ?? json['FluencyScore']),
      completenessScore: toDouble(
        json['completenessScore'] ?? json['CompletenessScore'],
      ),
    );
  }
}
