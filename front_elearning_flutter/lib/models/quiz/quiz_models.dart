Map<String, dynamic>? _asStringMap(Object? raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) {
    return raw.map((key, value) => MapEntry('$key', value));
  }
  return null;
}

List<Map<String, dynamic>> _asMapList(Object? raw) {
  if (raw is! List) return const [];
  final result = <Map<String, dynamic>>[];
  for (final item in raw) {
    final map = _asStringMap(item);
    if (map != null) {
      result.add(map);
    }
  }
  return result;
}

class QuizOptionModel {
  const QuizOptionModel({
    required this.optionId,
    required this.text,
    this.isCorrect,
  });

  final String optionId;
  final String text;
  final bool? isCorrect;

  factory QuizOptionModel.fromJson(Map<String, dynamic> json) {
    return QuizOptionModel(
      optionId:
          (json['answerId'] ??
                  json['AnswerId'] ??
                  json['optionId'] ??
                  json['OptionId'] ??
                  '')
              .toString(),
      text:
          (json['answerText'] ??
                  json['AnswerText'] ??
                  json['optionText'] ??
                  json['OptionText'] ??
                  '')
              .toString(),
      isCorrect: json['isCorrect'] is bool
          ? json['isCorrect'] as bool
          : (json['IsCorrect'] is bool ? json['IsCorrect'] as bool : null),
    );
  }
}

class QuizQuestionModel {
  const QuizQuestionModel({
    required this.questionId,
    required this.content,
    required this.type,
    required this.options,
    this.metadataJson,
  });

  final String questionId;
  final String content;
  final int type;
  final List<QuizOptionModel> options;
  final String? metadataJson;

  bool get isTextQuestion => type == 4;
  bool get isMultiChoice => type == 2;
  bool get isMatching => type == 5;
  bool get isOrdering => type == 6;

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    final typeRaw = json['type'] ?? json['Type'] ?? 1;
    final optionsRaw = _asMapList(
      json['options'] ?? json['Options'] ?? json['answers'] ?? json['Answers'],
    );
    return QuizQuestionModel(
      questionId: (json['questionId'] ?? json['QuestionId'] ?? '').toString(),
      content:
          (json['content'] ??
                  json['Content'] ??
                  json['questionText'] ??
                  json['QuestionText'] ??
                  '')
              .toString(),
      type: typeRaw is int ? typeRaw : int.tryParse(typeRaw.toString()) ?? 1,
      options: optionsRaw.map(QuizOptionModel.fromJson).toList(),
      metadataJson: (json['metadataJson'] ?? json['MetadataJson'])?.toString(),
    );
  }
}

class QuizDetailModel {
  const QuizDetailModel({
    required this.quizId,
    required this.title,
    required this.questions,
  });

  const QuizDetailModel.empty()
    : quizId = '',
      title = 'Quiz',
      questions = const [];

  final String quizId;
  final String title;
  final List<QuizQuestionModel> questions;

  QuizDetailModel copyWith({
    String? quizId,
    String? title,
    List<QuizQuestionModel>? questions,
  }) {
    return QuizDetailModel(
      quizId: quizId ?? this.quizId,
      title: title ?? this.title,
      questions: questions ?? this.questions,
    );
  }

  factory QuizDetailModel.fromJson(Map<String, dynamic> json) {
    final directQuestions = _asMapList(json['questions'] ?? json['Questions'])
        .map(QuizQuestionModel.fromJson)
        .where((q) => q.questionId.isNotEmpty)
        .toList();

    if (directQuestions.isNotEmpty) {
      return QuizDetailModel(
        quizId: (json['quizId'] ?? json['QuizId'] ?? '').toString(),
        title: (json['title'] ?? json['Title'] ?? 'Quiz').toString(),
        questions: directQuestions,
      );
    }

    final sections = _asMapList(json['quizSections'] ?? json['QuizSections']);
    final flattened = <QuizQuestionModel>[];
    for (final section in sections) {
      final items = _asMapList(section['items'] ?? section['Items']);
      for (final item in items) {
        if (item['questionId'] != null || item['QuestionId'] != null) {
          final question = QuizQuestionModel.fromJson(item);
          if (question.questionId.isNotEmpty) {
            flattened.add(question);
          }
          continue;
        }
        final nestedQuestions =
            _asMapList(item['questions'] ?? item['Questions'])
                .map(QuizQuestionModel.fromJson)
                .where((q) => q.questionId.isNotEmpty)
                .toList();
        flattened.addAll(nestedQuestions);
      }
    }

    return QuizDetailModel(
      quizId: (json['quizId'] ?? json['QuizId'] ?? '').toString(),
      title: (json['title'] ?? json['Title'] ?? 'Quiz').toString(),
      questions: flattened,
    );
  }
}

class QuizAttemptStartModel {
  const QuizAttemptStartModel({
    required this.attemptId,
    required this.durationMinutes,
    this.quizTitle,
    this.questions = const [],
    this.currentAnswers = const {},
  });

  final String attemptId;
  final int? durationMinutes;
  final String? quizTitle;
  final List<QuizQuestionModel> questions;
  final Map<String, Object?> currentAnswers;

  factory QuizAttemptStartModel.fromJson(Map<String, dynamic> json) {
    final durationRaw =
        json['duration'] ??
        json['Duration'] ??
        json['timeLimit'] ??
        json['TimeLimit'];
    final duration = durationRaw is int
        ? durationRaw
        : int.tryParse(durationRaw?.toString() ?? '');

    final questions = <QuizQuestionModel>[];
    final answers = <String, Object?>{};

    final sectionsRaw = _asMapList(
      json['quizSections'] ??
          json['QuizSections'] ??
          json['sections'] ??
          json['Sections'],
    );

    for (final section in sectionsRaw) {
      final items = _asMapList(section['items'] ?? section['Items']);

      for (final item in items) {
        final itemType = (item['itemType'] ?? item['ItemType'] ?? '')
            .toString()
            .toLowerCase();

        if (itemType == 'question' ||
            item['questionId'] != null ||
            item['QuestionId'] != null) {
          final q = QuizQuestionModel.fromJson(item);
          if (q.questionId.isNotEmpty) {
            questions.add(q);
            final userAnswer = item['userAnswer'] ?? item['UserAnswer'];
            if (userAnswer != null) {
              answers[q.questionId] = userAnswer;
            }
          }
          continue;
        }

        final nested = _asMapList(item['questions'] ?? item['Questions']);

        for (final rawQuestion in nested) {
          final q = QuizQuestionModel.fromJson(rawQuestion);
          if (q.questionId.isEmpty) continue;
          questions.add(q);
          final userAnswer =
              rawQuestion['userAnswer'] ?? rawQuestion['UserAnswer'];
          if (userAnswer != null) {
            answers[q.questionId] = userAnswer;
          }
        }
      }
    }

    if (questions.isEmpty) {
      final seen = <String>{};

      void collect(Object? node) {
        if (node is List) {
          for (final item in node) {
            collect(item);
          }
          return;
        }

        final map = _asStringMap(node);
        if (map == null) return;

        final qidRaw = map['questionId'] ?? map['QuestionId'];
        final questionId = qidRaw?.toString() ?? '';
        if (questionId.isNotEmpty && !seen.contains(questionId)) {
          final parsed = QuizQuestionModel.fromJson(map);
          if (parsed.questionId.isNotEmpty) {
            questions.add(parsed);
            seen.add(parsed.questionId);

            final userAnswer = map['userAnswer'] ?? map['UserAnswer'];
            if (userAnswer != null) {
              answers[parsed.questionId] = userAnswer;
            }
          }
        }

        for (final value in map.values) {
          collect(value);
        }
      }

      collect(json);
    }

    return QuizAttemptStartModel(
      attemptId:
          (json['quizAttemptId'] ??
                  json['QuizAttemptId'] ??
                  json['attemptId'] ??
                  json['AttemptId'] ??
                  '')
              .toString(),
      durationMinutes: duration,
      quizTitle:
          (json['quizTitle'] ??
                  json['QuizTitle'] ??
                  json['title'] ??
                  json['Title'])
              ?.toString(),
      questions: questions,
      currentAnswers: answers,
    );
  }
}

class QuizActiveAttemptModel {
  const QuizActiveAttemptModel({
    required this.hasActiveAttempt,
    required this.attemptId,
    required this.timeRemainingSeconds,
  });

  final bool hasActiveAttempt;
  final String? attemptId;
  final int? timeRemainingSeconds;

  factory QuizActiveAttemptModel.fromJson(Map<String, dynamic> json) {
    final remainRaw =
        json['timeRemainingSeconds'] ?? json['TimeRemainingSeconds'];
    final remain = remainRaw is int
        ? remainRaw
        : int.tryParse('${remainRaw ?? ''}');

    final attemptIdRaw = json['attemptId'] ?? json['AttemptId'];
    final hasAttempt =
        (json['hasActiveAttempt'] ?? json['HasActiveAttempt']) == true;

    return QuizActiveAttemptModel(
      hasActiveAttempt: hasAttempt,
      attemptId: attemptIdRaw?.toString(),
      timeRemainingSeconds: remain,
    );
  }
}
