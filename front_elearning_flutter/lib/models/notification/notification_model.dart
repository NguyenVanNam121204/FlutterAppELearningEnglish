class NotificationItemModel {
  const NotificationItemModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAtRaw,
  });

  final String id;
  final String title;
  final String message;
  final int type;
  final bool isRead;
  final String createdAtRaw;

  NotificationItemModel copyWith({bool? isRead}) {
    return NotificationItemModel(
      id: id,
      title: title,
      message: message,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAtRaw: createdAtRaw,
    );
  }

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    final typeRaw = json['type'] ?? json['Type'] ?? 0;
    return NotificationItemModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      title: (json['title'] ?? json['Title'] ?? 'Notification').toString(),
      message: (json['message'] ?? json['Message'] ?? '').toString(),
      type: typeRaw is int ? typeRaw : int.tryParse(typeRaw.toString()) ?? 0,
      isRead: (json['isRead'] ?? json['IsRead'] ?? false) == true,
      createdAtRaw: (json['createdAt'] ?? json['CreatedAt'] ?? '').toString(),
    );
  }
}
