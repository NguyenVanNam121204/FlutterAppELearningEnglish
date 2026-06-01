class MyCourseItemModel {
  const MyCourseItemModel({
    required this.courseId,
    required this.title,
    this.imageUrl,
    this.price,
    this.isEnrolled = true,
    this.progressPercentage = 0,
    this.totalLessons = 0,
    this.completedLessons = 0,
  });

  final String courseId;
  final String title;
  final String? imageUrl;
  final double? price;
  final bool isEnrolled;
  final double progressPercentage;
  final int totalLessons;
  final int completedLessons;

  factory MyCourseItemModel.fromJson(Map<String, dynamic> json) {
    final rawProgress =
        json['progressPercentage'] ?? json['ProgressPercentage'];
    return MyCourseItemModel(
      courseId: (json['courseId'] ?? json['CourseId'] ?? '').toString(),
      title: (json['title'] ?? json['Title'] ?? 'Course').toString(),
      imageUrl: (json['imageUrl'] ?? json['ImageUrl'])?.toString(),
      price: _toDouble(json['price'] ?? json['Price']),
      isEnrolled: (json['isEnrolled'] ?? json['IsEnrolled'] ?? true) as bool,
      progressPercentage: _toDouble(rawProgress) ?? 0,
      totalLessons: _toInt(json['totalLessons'] ?? json['TotalLessons']),
      completedLessons: _toInt(
        json['completedLessons'] ?? json['CompletedLessons'],
      ),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
