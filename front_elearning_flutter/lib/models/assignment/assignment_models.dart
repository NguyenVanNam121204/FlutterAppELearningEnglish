class AssignmentQuizItemModel {
  const AssignmentQuizItemModel({
    required this.quizId,
    required this.title,
    this.description = '',
    this.instructions = '',
    this.durationMinutes,
    this.totalQuestions,
    this.passingScore,
    this.maxAttempts,
  });

  final String quizId;
  final String title;
  final String description;
  final String instructions;
  final int? durationMinutes;
  final int? totalQuestions;
  final int? passingScore;
  final int? maxAttempts;

  String get durationLabel {
    if ((durationMinutes ?? 0) <= 0) return '';
    return '${durationMinutes!} phút';
  }

  factory AssignmentQuizItemModel.fromJson(Map<String, dynamic> json) {
    final durationRaw = json['duration'] ?? json['Duration'];
    final totalRaw = json['totalQuestions'] ?? json['TotalQuestions'];
    final passingRaw = json['passingScore'] ?? json['PassingScore'];
    final maxAttemptsRaw = json['maxAttempts'] ?? json['MaxAttempts'];

    return AssignmentQuizItemModel(
      quizId: (json['quizId'] ?? json['QuizId'] ?? '').toString(),
      title: (json['title'] ?? json['Title'] ?? 'Quiz').toString(),
      description: (json['description'] ?? json['Description'] ?? '')
          .toString(),
      instructions: (json['instructions'] ?? json['Instructions'] ?? '')
          .toString(),
      durationMinutes: durationRaw is int
          ? durationRaw
          : int.tryParse('${durationRaw ?? ''}'),
      totalQuestions: totalRaw is int
          ? totalRaw
          : int.tryParse('${totalRaw ?? ''}'),
      passingScore: passingRaw is int
          ? passingRaw
          : int.tryParse('${passingRaw ?? ''}'),
      maxAttempts: maxAttemptsRaw is int
          ? maxAttemptsRaw
          : int.tryParse('${maxAttemptsRaw ?? ''}'),
    );
  }
}

class AssignmentEssayItemModel {
  const AssignmentEssayItemModel({required this.essayId, required this.title});

  final String essayId;
  final String title;

  factory AssignmentEssayItemModel.fromJson(Map<String, dynamic> json) {
    return AssignmentEssayItemModel(
      essayId: (json['essayId'] ?? json['EssayId'] ?? '').toString(),
      title: (json['title'] ?? json['Title'] ?? 'Essay').toString(),
    );
  }
}

class AssignmentDetailModel {
  const AssignmentDetailModel({
    required this.assessments,
    required this.quizzes,
    required this.essays,
  });

  const AssignmentDetailModel.empty()
    : assessments = const [],
      quizzes = const [],
      essays = const [];

  final List<AssignmentAssessmentItemModel> assessments;

  final List<AssignmentQuizItemModel> quizzes;
  final List<AssignmentEssayItemModel> essays;

  bool get hasAssessmentList => assessments.isNotEmpty;
  bool get hasAssessmentContent => quizzes.isNotEmpty || essays.isNotEmpty;

  factory AssignmentDetailModel.fromJson(Map<String, dynamic> json) {
    final rawAssessmentList = json['data'] ?? json['Data'] ?? json;
    if (rawAssessmentList is List) {
      final assessments = rawAssessmentList
          .whereType<Map<String, dynamic>>()
          .map(AssignmentAssessmentItemModel.fromJson)
          .where((item) => item.assessmentId.isNotEmpty)
          .where((item) => item.isPublished)
          .toList();

      return AssignmentDetailModel(
        assessments: assessments,
        quizzes: const [],
        essays: const [],
      );
    }

    final quizzesRaw =
        (json['quizzes'] ?? json['Quizzes']) as List? ?? const [];
    final essaysRaw = (json['essays'] ?? json['Essays']) as List? ?? const [];

    return AssignmentDetailModel(
      assessments: const [],
      quizzes: quizzesRaw
          .whereType<Map<String, dynamic>>()
          .map(AssignmentQuizItemModel.fromJson)
          .toList(),
      essays: essaysRaw
          .whereType<Map<String, dynamic>>()
          .map(AssignmentEssayItemModel.fromJson)
          .toList(),
    );
  }
}

class AssignmentAssessmentItemModel {
  const AssignmentAssessmentItemModel({
    required this.assessmentId,
    required this.title,
    required this.description,
    required this.timeLimit,
    required this.isPublished,
  });

  final String assessmentId;
  final String title;
  final String description;
  final String timeLimit;
  final bool isPublished;

  factory AssignmentAssessmentItemModel.fromJson(Map<String, dynamic> json) {
    return AssignmentAssessmentItemModel(
      assessmentId: (json['assessmentId'] ?? json['AssessmentId'] ?? '')
          .toString(),
      title: (json['title'] ?? json['Title'] ?? 'Assessment').toString(),
      description: (json['description'] ?? json['Description'] ?? '')
          .toString(),
      timeLimit: (json['timeLimit'] ?? json['TimeLimit'] ?? '').toString(),
      isPublished:
          (json['isPublished'] ?? json['IsPublished'] ?? false) == true,
    );
  }
}

class EssayDetailModel {
  const EssayDetailModel({required this.title, required this.instruction});

  final String title;
  final String instruction;

  factory EssayDetailModel.fromJson(Map<String, dynamic> json) {
    return EssayDetailModel(
      title: (json['title'] ?? json['Title'] ?? 'Essay').toString(),
      instruction:
          (json['description'] ??
                  json['Description'] ??
                  json['instruction'] ??
                  json['Instruction'] ??
                  '')
              .toString(),
    );
  }
}
