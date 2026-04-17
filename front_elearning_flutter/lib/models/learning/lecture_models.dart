class LectureListItemModel {
  const LectureListItemModel({
    required this.lectureId,
    required this.title,
    this.subtitle = '',
    this.orderIndex = 0,
    this.isCompleted = false,
    this.numberingLabel = '',
  });

  final String lectureId;
  final String title;
  final String subtitle;
  final int orderIndex;
  final bool isCompleted;
  final String numberingLabel;

  factory LectureListItemModel.fromJson(Map<String, dynamic> json) {
    final rawOrder = json['orderIndex'] ?? json['OrderIndex'] ?? 0;
    final subtitle =
        (json['description'] ??
                json['Description'] ??
                json['subtitle'] ??
                json['Subtitle'] ??
                '')
            .toString();

    return LectureListItemModel(
      lectureId: (json['lectureId'] ?? json['LectureId'] ?? '').toString(),
      title: (json['title'] ?? json['Title'] ?? 'Lecture').toString(),
      subtitle: subtitle,
      isCompleted:
          (json['isCompleted'] ?? json['IsCompleted'] ?? false) == true,
      numberingLabel: (json['numberingLabel'] ?? json['NumberingLabel'] ?? '')
          .toString(),
      orderIndex: rawOrder is int ? rawOrder : int.tryParse('$rawOrder') ?? 0,
    );
  }
}

class LectureTreeItemModel {
  const LectureTreeItemModel({
    required this.lectureId,
    required this.title,
    this.subtitle = '',
    this.orderIndex = 0,
    this.isCompleted = false,
    this.numberingLabel = '',
    this.children = const [],
  });

  final String lectureId;
  final String title;
  final String subtitle;
  final int orderIndex;
  final bool isCompleted;
  final String numberingLabel;
  final List<LectureTreeItemModel> children;

  bool get hasChildren => children.isNotEmpty;

  static int _parseOrder(Object? raw) {
    if (raw is int) return raw;
    return int.tryParse('${raw ?? 0}') ?? 0;
  }

  factory LectureTreeItemModel.fromJson(Map<String, dynamic> json) {
    final rawChildren =
        json['children'] ??
        json['Children'] ??
        json['lectures'] ??
        json['Lectures'] ??
        const [];
    final children = rawChildren is List
        ? rawChildren
              .whereType<Map<String, dynamic>>()
              .map(LectureTreeItemModel.fromJson)
              .toList()
        : <LectureTreeItemModel>[];
    children.sort((a, b) {
      final byOrder = a.orderIndex.compareTo(b.orderIndex);
      if (byOrder != 0) return byOrder;
      return a.title.compareTo(b.title);
    });

    final subtitle =
        (json['description'] ??
                json['Description'] ??
                json['subtitle'] ??
                json['Subtitle'] ??
                '')
            .toString();

    return LectureTreeItemModel(
      lectureId: (json['lectureId'] ?? json['LectureId'] ?? '').toString(),
      title: (json['title'] ?? json['Title'] ?? 'Lecture').toString(),
      subtitle: subtitle,
      isCompleted:
          (json['isCompleted'] ?? json['IsCompleted'] ?? false) == true,
      numberingLabel: (json['numberingLabel'] ?? json['NumberingLabel'] ?? '')
          .toString(),
      orderIndex: _parseOrder(json['orderIndex'] ?? json['OrderIndex']),
      children: children,
    );
  }

  List<LectureListItemModel> flattenLeaves() {
    if (children.isEmpty) {
      return [
        LectureListItemModel(
          lectureId: lectureId,
          title: title,
          subtitle: subtitle,
          orderIndex: orderIndex,
          isCompleted: isCompleted,
          numberingLabel: numberingLabel,
        ),
      ];
    }

    return children.expand((item) => item.flattenLeaves()).toList();
  }
}

class LectureDetailModel {
  const LectureDetailModel({
    required this.lectureId,
    required this.moduleId,
    required this.title,
    required this.markdownContent,
    required this.mediaUrl,
    required this.type,
    required this.typeName,
    required this.numberingLabel,
    required this.childrenCount,
    required this.parentLectureId,
  });

  final String lectureId;
  final String moduleId;
  final String title;
  final String markdownContent;
  final String mediaUrl;
  final int type;
  final String typeName;
  final String numberingLabel;
  final int childrenCount;
  final String parentLectureId;

  bool get isVideoType => type == 3 || typeName.toLowerCase() == 'video';
  bool get isDocumentType => type == 2 || typeName.toLowerCase() == 'document';

  factory LectureDetailModel.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] ?? json['Type'] ?? 0;
    return LectureDetailModel(
      lectureId: (json['lectureId'] ?? json['LectureId'] ?? '').toString(),
      moduleId: (json['moduleId'] ?? json['ModuleId'] ?? '').toString(),
      title: (json['title'] ?? json['Title'] ?? 'Lecture').toString(),
      markdownContent:
          (json['markdownContent'] ??
                  json['MarkdownContent'] ??
                  json['content'] ??
                  json['Content'] ??
                  '')
              .toString(),
      mediaUrl:
          (json['mediaUrl'] ??
                  json['MediaUrl'] ??
                  json['videoUrl'] ??
                  json['VideoUrl'] ??
                  '')
              .toString(),
      type: rawType is int ? rawType : int.tryParse('$rawType') ?? 0,
      typeName: (json['typeName'] ?? json['TypeName'] ?? '').toString(),
      numberingLabel: (json['numberingLabel'] ?? json['NumberingLabel'] ?? '')
          .toString(),
      childrenCount:
          int.tryParse(
            '${json['childrenCount'] ?? json['ChildrenCount'] ?? 0}',
          ) ??
          0,
      parentLectureId:
          (json['parentLectureId'] ?? json['ParentLectureId'] ?? '').toString(),
    );
  }
}
