class LessonListItemModel {
  const LessonListItemModel({
    required this.lessonId,
    required this.title,
    this.description,
    this.imageUrl,
    this.isCompleted = false,
    this.orderIndex = 0,
  });

  final String lessonId;
  final String title;
  final String? description;
  final String? imageUrl;
  final bool isCompleted;
  final int orderIndex;

  factory LessonListItemModel.fromJson(Map<String, dynamic> json) {
    final rawOrder = json['orderIndex'] ?? json['OrderIndex'] ?? 0;
    return LessonListItemModel(
      lessonId: (json['lessonId'] ?? json['LessonId'] ?? '').toString(),
      title: (json['title'] ?? json['Title'] ?? 'Lesson').toString(),
      description: (json['description'] ?? json['Description'])?.toString(),
      imageUrl: (json['imageUrl'] ?? json['ImageUrl'])?.toString(),
      isCompleted:
          (json['isCompleted'] ?? json['IsCompleted'] ?? false) as bool,
      orderIndex: rawOrder is int ? rawOrder : int.tryParse('$rawOrder') ?? 0,
    );
  }
}

class LessonDetailModel {
  const LessonDetailModel({
    required this.lessonId,
    required this.title,
    required this.description,
  });

  final String lessonId;
  final String title;
  final String description;

  factory LessonDetailModel.fromJson(Map<String, dynamic> json) {
    return LessonDetailModel(
      lessonId: (json['lessonId'] ?? json['LessonId'] ?? '').toString(),
      title: (json['title'] ?? json['Title'] ?? 'Lesson').toString(),
      description: (json['description'] ?? json['Description'] ?? '')
          .toString(),
    );
  }
}

class LessonModuleItemModel {
  const LessonModuleItemModel({
    required this.moduleId,
    required this.name,
    required this.contentType,
    this.contentTypeName,
    this.description,
    this.imageUrl,
    this.isCompleted = false,
    this.isPronunciationCompleted = false,
    this.orderIndex = 0,
  });

  final String moduleId;
  final String name;
  final int contentType;
  final String? contentTypeName;
  final String? description;
  final String? imageUrl;
  final bool isCompleted;
  final bool isPronunciationCompleted;
  final int orderIndex;

  factory LessonModuleItemModel.fromJson(Map<String, dynamic> json) {
    final rawType = json['contentType'] ?? json['ContentType'] ?? 1;
    final rawOrder = json['orderIndex'] ?? json['OrderIndex'] ?? 0;
    return LessonModuleItemModel(
      moduleId: (json['moduleId'] ?? json['ModuleId'] ?? '').toString(),
      name: (json['name'] ?? json['Name'] ?? 'Module').toString(),
      contentType: rawType is int
          ? rawType
          : int.tryParse(rawType.toString()) ?? 1,
      contentTypeName: (json['contentTypeName'] ?? json['ContentTypeName'])
          ?.toString(),
      description: (json['description'] ?? json['Description'])?.toString(),
      imageUrl: (json['imageUrl'] ?? json['ImageUrl'])?.toString(),
      isCompleted:
          (json['isCompleted'] ?? json['IsCompleted'] ?? false) as bool,
      isPronunciationCompleted:
          (json['isPronunciationCompleted'] ??
                  json['IsPronunciationCompleted'] ??
                  false)
              as bool,
      orderIndex: rawOrder is int ? rawOrder : int.tryParse('$rawOrder') ?? 0,
    );
  }
}

class LessonDetailBundleModel {
  const LessonDetailBundleModel({required this.lesson, required this.modules});

  final LessonDetailModel lesson;
  final List<LessonModuleItemModel> modules;
}

class LessonResultModel {
  const LessonResultModel({
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    this.percentage,
    this.isPassed,
    this.timeSpentSeconds,
  });

  final String score;
  final String correctAnswers;
  final String totalQuestions;
  final double? percentage;
  final bool? isPassed;
  final int? timeSpentSeconds;

  factory LessonResultModel.fromJson(Map<String, dynamic> json) {
    final percentageRaw = json['percentage'] ?? json['Percentage'];
    final percentage = percentageRaw is num
        ? percentageRaw.toDouble()
        : double.tryParse('$percentageRaw');

    final questionsRaw =
        ((json['questions'] ?? json['Questions']) as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        const <Map<String, dynamic>>[];

    final scoresByQuestionRaw =
        (json['scoresByQuestion'] ?? json['ScoresByQuestion'])
            as Map<String, dynamic>?;

    final derivedTotalQuestions = questionsRaw.isNotEmpty
        ? questionsRaw.length
        : (scoresByQuestionRaw?.length ?? 0);
    final derivedCorrectAnswers = questionsRaw.isNotEmpty
        ? questionsRaw
              .where((q) => (q['isCorrect'] ?? q['IsCorrect']) == true)
              .length
        : (scoresByQuestionRaw?.values
                  .where((v) => double.tryParse('$v') != null)
                  .where((v) => double.parse('$v') > 0)
                  .length ??
              0);

    return LessonResultModel(
      score:
          (json['score'] ??
                  json['Score'] ??
                  json['totalScore'] ??
                  json['TotalScore'] ??
                  '-')
              .toString(),
      correctAnswers:
          (json['correctAnswers'] ??
                  json['CorrectAnswers'] ??
                  (derivedCorrectAnswers > 0 ? derivedCorrectAnswers : '-'))
              .toString(),
      totalQuestions:
          (json['totalQuestions'] ??
                  json['TotalQuestions'] ??
                  (derivedTotalQuestions > 0 ? derivedTotalQuestions : '-'))
              .toString(),
      percentage: percentage,
      isPassed: (json['isPassed'] ?? json['IsPassed']) as bool?,
      timeSpentSeconds:
          (json['timeSpentSeconds'] ?? json['TimeSpentSeconds']) as int?,
    );
  }
}
