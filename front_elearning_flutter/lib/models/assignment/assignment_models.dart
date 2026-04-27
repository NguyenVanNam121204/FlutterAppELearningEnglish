import 'package:flutter/foundation.dart';
import '../../app/config/app_config.dart';

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
    this.isCompleted = false,
    this.isPassed,
    this.userScore,
  });

  final String quizId;
  final String title;
  final String description;
  final String instructions;
  final int? durationMinutes;
  final int? totalQuestions;
  final int? passingScore;
  final int? maxAttempts;
  final bool isCompleted;
  final bool? isPassed;
  final String? userScore;

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
      isCompleted: (json['isCompleted'] ?? json['IsCompleted'] ?? false) == true,
      isPassed: json['isPassed'] ?? json['IsPassed'],
      userScore: (json['userScore'] ?? json['UserScore'] ?? json['score'] ?? json['Score'])?.toString(),
    );
  }
}

class AssignmentEssayItemModel {
  const AssignmentEssayItemModel({
    required this.essayId,
    required this.title,
    this.isSubmitted = false,
    this.isGraded = false,
    this.score,
  });

  final String essayId;
  final String title;
  final bool isSubmitted;
  final bool isGraded;
  final String? score;

  factory AssignmentEssayItemModel.fromJson(Map<String, dynamic> json) {
    return AssignmentEssayItemModel(
      essayId: (json['essayId'] ?? json['EssayId'] ?? '').toString(),
      title: (json['title'] ?? json['Title'] ?? 'Essay').toString(),
      isSubmitted: (json['isSubmitted'] ?? json['IsSubmitted'] ?? false) == true,
      isGraded: (json['isGraded'] ?? json['IsGraded'] ?? false) == true,
      score: (json['score'] ?? json['Score'])?.toString(),
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
  const EssayDetailModel({
    required this.title,
    required this.instruction,
    this.audioUrl,
    this.imageUrl,
  });

  final String title;
  final String instruction;
  final String? audioUrl;
  final String? imageUrl;

  factory EssayDetailModel.fromJson(Map<String, dynamic> json) {
    return EssayDetailModel(
      title: (json['title'] ?? json['Title'] ?? 'Essay').toString(),
      instruction: (json['description'] ??
              json['Description'] ??
              json['instruction'] ??
              json['Instruction'] ??
              '')
          .toString(),
      audioUrl: (json['audioUrl'] ?? json['AudioUrl'])?.toString(),
      imageUrl: (json['imageUrl'] ?? json['ImageUrl'])?.toString(),
    );
  }
}

class EssaySubmissionModel {
  const EssaySubmissionModel({
    required this.submissionId,
    required this.textContent,
    this.attachmentUrl,
    this.submittedAt,
    this.score,
    this.feedback,
  });

  final String submissionId;
  final String textContent;
  final String? attachmentUrl;
  final String? submittedAt;
  final String? score;
  final String? feedback;

  bool get isGraded => score != null;

  String? get fullAttachmentUrl {
    if (attachmentUrl == null || attachmentUrl!.isEmpty) return null;

    String url = attachmentUrl!;
    if (!url.startsWith('http')) {
      final baseUrl = AppConfig.apiBaseUrl;
      if (url.startsWith('/')) {
        url = '$baseUrl$url';
      } else {
        url = '$baseUrl/$url';
      }
    }

    // Normalize localhost for Android emulator
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      url = url
          .replaceFirst('://localhost', '://10.0.2.2')
          .replaceFirst('://127.0.0.1', '://10.0.2.2');
    }

    return url;
  }

  factory EssaySubmissionModel.fromJson(Map<String, dynamic> json) {
    return EssaySubmissionModel(
      submissionId:
          (json['submissionId'] ?? json['SubmissionId'] ?? '').toString(),
      textContent:
          (json['textContent'] ?? json['TextContent'] ?? '').toString(),
      attachmentUrl:
          (json['attachmentUrl'] ?? json['AttachmentUrl'])?.toString(),
      submittedAt: (json['submittedAt'] ?? json['SubmittedAt'])?.toString(),
      score: (json['score'] ??
              json['Score'] ??
              json['teacherScore'] ??
              json['TeacherScore'] ??
              json['aiScore'] ??
              json['AiScore'])
          ?.toString(),
      feedback: (json['feedback'] ??
              json['Feedback'] ??
              json['teacherFeedback'] ??
              json['TeacherFeedback'] ??
              json['aiFeedback'] ??
              json['AiFeedback'])
          ?.toString(),
    );
  }
}
