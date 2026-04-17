class StreakModel {
  const StreakModel({
    required this.currentStreak,
    required this.isActiveToday,
    this.lastActivityDate,
  });

  final int currentStreak;
  final bool isActiveToday;
  final DateTime? lastActivityDate;

  factory StreakModel.fromJson(Map<String, dynamic> json) {
    final rawDate = json['lastActivityDate'] ?? json['LastActivityDate'];

    return StreakModel(
      currentStreak:
          (json['currentStreak'] ?? json['CurrentStreak'] ?? 0) as int,
      isActiveToday:
          (json['isActiveToday'] ?? json['IsActiveToday'] ?? false) as bool,
      lastActivityDate: rawDate == null
          ? null
          : DateTime.tryParse(rawDate.toString()),
    );
  }
}
