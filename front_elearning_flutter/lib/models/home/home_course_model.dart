class HomeCourseModel {
  const HomeCourseModel({
    required this.courseId,
    required this.title,
    required this.description,
    this.imageUrl,
    this.price,
    this.isEnrolled = false,
    this.progressPercentage = 0,
    this.totalLessons = 0,
  });

  final int courseId;
  final String title;
  final String description;
  final String? imageUrl;
  final double? price;
  final bool isEnrolled;
  final double progressPercentage;
  final int totalLessons;

  factory HomeCourseModel.fromSystemJson(Map<String, dynamic> json) {
    return HomeCourseModel(
      courseId: (json['courseId'] ?? json['CourseId'] ?? 0) as int,
      title: (json['title'] ?? json['Title'] ?? '').toString(),
      description: (json['description'] ?? json['Description'] ?? '')
          .toString(),
      imageUrl: (json['imageUrl'] ?? json['ImageUrl'])?.toString(),
      price: _toDouble(json['price'] ?? json['Price']),
      isEnrolled: (json['isEnrolled'] ?? json['IsEnrolled'] ?? false) as bool,
      progressPercentage: 0,
      totalLessons: (json['lessonCount'] ?? json['LessonCount'] ?? 0) as int,
    );
  }

  factory HomeCourseModel.fromEnrolledJson(Map<String, dynamic> json) {
    return HomeCourseModel(
      courseId: (json['courseId'] ?? json['CourseId'] ?? 0) as int,
      title: (json['title'] ?? json['Title'] ?? '').toString(),
      description: (json['description'] ?? json['Description'] ?? '')
          .toString(),
      imageUrl: (json['imageUrl'] ?? json['ImageUrl'])?.toString(),
      price: _toDouble(json['price'] ?? json['Price']),
      isEnrolled: true,
      progressPercentage:
          _toDouble(json['progressPercentage'] ?? json['ProgressPercentage']) ??
          0,
      totalLessons: (json['totalLessons'] ?? json['TotalLessons'] ?? 0) as int,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}


