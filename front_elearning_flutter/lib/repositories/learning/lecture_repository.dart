import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../../models/learning/lecture_models.dart';
import '../../services/api_service.dart';

class LectureRepository {
  LectureRepository(this._apiService);

  final ApiService _apiService;

  Future<Result<List<LectureListItemModel>>> moduleLectures(
    String moduleId,
  ) async {
    final treeResult = await moduleLectureTree(moduleId);
    return switch (treeResult) {
      Success(:final value) => Success(
        value.expand((node) => node.flattenLeaves()).toList()..sort((a, b) {
          final byOrder = a.orderIndex.compareTo(b.orderIndex);
          if (byOrder != 0) return byOrder;
          return a.title.compareTo(b.title);
        }),
      ),
      Failure(:final error) => Failure(error),
    };
  }

  Future<Result<List<LectureTreeItemModel>>> moduleLectureTree(
    String moduleId,
  ) async {
    try {
      final response = await _apiService.get(
        ApiConstants.userLectureTreeByModule(moduleId),
      );
      final roots = _asTreeList(response.data);
      if (roots.isNotEmpty) {
        return Success(roots);
      }

      final fallback = await _apiService.get(
        ApiConstants.userLecturesByModule(moduleId),
      );
      return Success(_asTreeList(fallback.data));
    } on DioException {
      try {
        final fallback = await _apiService.get(
          ApiConstants.userLecturesByModule(moduleId),
        );
        return Success(_asTreeList(fallback.data));
      } on DioException catch (error) {
        return Failure(_mapDioException(error));
      }
    } catch (_) {
      return const Failure(AppError(message: 'Unable to load lectures.'));
    }
  }

  Future<Result<LectureDetailModel>> lectureDetail(String lectureId) async {
    try {
      final response = await _apiService.get(
        ApiConstants.userLectureDetail(lectureId),
      );
      return Success(LectureDetailModel.fromJson(_asMap(response.data)));
    } on DioException catch (error) {
      return Failure(_mapDioException(error));
    } catch (_) {
      return const Failure(AppError(message: 'Unable to load lecture detail.'));
    }
  }

  Map<String, dynamic> _asMap(Object? raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'] ?? raw['Data'] ?? raw;
      if (data is Map<String, dynamic>) return data;
      return raw;
    }
    return const {};
  }

  String _lectureId(Map<String, dynamic> raw) {
    return (raw['lectureId'] ?? raw['LectureId'] ?? '').toString().trim();
  }

  String _parentLectureId(Map<String, dynamic> raw) {
    return (raw['parentLectureId'] ??
            raw['ParentLectureId'] ??
            raw['parentId'] ??
            raw['ParentId'] ??
            '')
        .toString()
        .trim();
  }

  bool _containsNestedChildren(List<Map<String, dynamic>> source) {
    for (final item in source) {
      final childrenRaw =
          item['children'] ??
          item['Children'] ??
          item['lectures'] ??
          item['Lectures'];
      if (childrenRaw is List && childrenRaw.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  bool _containsParentRefs(List<Map<String, dynamic>> source) {
    for (final item in source) {
      if (_parentLectureId(item).isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  Map<String, dynamic> _mergeNodeMaps(
    Map<String, dynamic> current,
    Map<String, dynamic> incoming,
  ) {
    return {
      ...current,
      ...incoming,
      'title': _preferNonEmpty(
        incoming['title'] ?? incoming['Title'],
        current['title'] ?? current['Title'],
      ),
      'description': _preferNonEmpty(
        incoming['description'] ??
            incoming['Description'] ??
            incoming['subtitle'] ??
            incoming['Subtitle'],
        current['description'] ??
            current['Description'] ??
            current['subtitle'] ??
            current['Subtitle'],
      ),
      'numberingLabel': _preferNonEmpty(
        incoming['numberingLabel'] ?? incoming['NumberingLabel'],
        current['numberingLabel'] ?? current['NumberingLabel'],
      ),
      'isCompleted':
          (incoming['isCompleted'] ?? incoming['IsCompleted'] ?? false) ==
              true ||
          (current['isCompleted'] ?? current['IsCompleted'] ?? false) == true,
    };
  }

  List<LectureTreeItemModel> _buildTreeFromFlatSource(
    List<Map<String, dynamic>> source,
  ) {
    final merged = <String, Map<String, dynamic>>{};
    for (final item in source) {
      final id = _lectureId(item);
      if (id.isEmpty) continue;
      final current = merged[id];
      merged[id] = current == null ? item : _mergeNodeMaps(current, item);
    }

    final childrenByParent = <String, List<String>>{};
    for (final entry in merged.entries) {
      final parentId = _parentLectureId(entry.value);
      if (parentId.isEmpty) continue;
      childrenByParent.putIfAbsent(parentId, () => <String>[]).add(entry.key);
    }

    LectureTreeItemModel? buildById(String id, Set<String> visiting) {
      if (visiting.contains(id)) return null;
      final raw = merged[id];
      if (raw == null) return null;
      visiting.add(id);

      final childIds = childrenByParent[id] ?? const <String>[];
      final children = <LectureTreeItemModel>[];
      for (final childId in childIds.toSet()) {
        final child = buildById(childId, visiting);
        if (child != null) children.add(child);
      }
      children.sort((a, b) {
        final byOrder = a.orderIndex.compareTo(b.orderIndex);
        if (byOrder != 0) return byOrder;
        return a.title.compareTo(b.title);
      });

      visiting.remove(id);
      return LectureTreeItemModel(
        lectureId: id,
        title: (raw['title'] ?? raw['Title'] ?? 'Lecture').toString(),
        subtitle: _preferNonEmpty(
          raw['description'] ??
              raw['Description'] ??
              raw['subtitle'] ??
              raw['Subtitle'],
          '',
        ).toString(),
        orderIndex: _parseOrder(raw['orderIndex'] ?? raw['OrderIndex']),
        isCompleted:
            (raw['isCompleted'] ?? raw['IsCompleted'] ?? false) == true,
        numberingLabel: (raw['numberingLabel'] ?? raw['NumberingLabel'] ?? '')
            .toString(),
        children: children,
      );
    }

    final mergedIds = merged.keys.toSet();
    final rootIds = merged.entries
        .where((entry) {
          final parentId = _parentLectureId(entry.value);
          return parentId.isEmpty || !mergedIds.contains(parentId);
        })
        .map((entry) => entry.key)
        .toList();

    final roots = <LectureTreeItemModel>[];
    for (final id in rootIds) {
      final root = buildById(id, <String>{});
      if (root != null) roots.add(root);
    }
    roots.sort((a, b) {
      final byOrder = a.orderIndex.compareTo(b.orderIndex);
      if (byOrder != 0) return byOrder;
      return a.title.compareTo(b.title);
    });
    return roots;
  }

  List<LectureTreeItemModel> _asTreeList(Object? raw) {
    final source = _extractTreeSource(raw);
    if (source.isEmpty) return const [];

    if (!_containsNestedChildren(source) && _containsParentRefs(source)) {
      return _buildTreeFromFlatSource(source);
    }

    final roots = <LectureTreeItemModel>[];
    final seenRootIds = <String>{};
    for (final item in source) {
      final node = _toTreeItem(item);
      if (node == null) continue;
      if (seenRootIds.contains(node.lectureId)) continue;
      seenRootIds.add(node.lectureId);
      roots.add(node);
    }

    roots.sort((a, b) {
      final byOrder = a.orderIndex.compareTo(b.orderIndex);
      if (byOrder != 0) return byOrder;
      return a.title.compareTo(b.title);
    });
    return roots;
  }

  List<Map<String, dynamic>> _extractTreeSource(Object? raw) {
    if (raw is Map<String, dynamic>) {
      final data =
          raw['data'] ?? raw['Data'] ?? raw['items'] ?? raw['Items'] ?? raw;
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }
      if (data is Map<String, dynamic>) {
        return [data];
      }
    }
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }

  LectureTreeItemModel? _toTreeItem(Map<String, dynamic> raw) {
    final id = _lectureId(raw);
    if (id.isEmpty) return null;

    final childrenRaw =
        raw['children'] ??
        raw['Children'] ??
        raw['lectures'] ??
        raw['Lectures'] ??
        const [];
    final childrenMaps = childrenRaw is List
        ? childrenRaw.whereType<Map<String, dynamic>>().toList()
        : const <Map<String, dynamic>>[];

    final childNodes = <LectureTreeItemModel>[];
    final seenChildIds = <String>{};
    for (final childRaw in childrenMaps) {
      final child = _toTreeItem(childRaw);
      if (child == null) continue;
      if (seenChildIds.contains(child.lectureId)) continue;
      seenChildIds.add(child.lectureId);
      childNodes.add(child);
    }

    childNodes.sort((a, b) {
      final byOrder = a.orderIndex.compareTo(b.orderIndex);
      if (byOrder != 0) return byOrder;
      return a.title.compareTo(b.title);
    });

    return LectureTreeItemModel(
      lectureId: id,
      title: (raw['title'] ?? raw['Title'] ?? 'Lecture').toString(),
      subtitle: _preferNonEmpty(
        raw['description'] ??
            raw['Description'] ??
            raw['subtitle'] ??
            raw['Subtitle'],
        '',
      ).toString(),
      orderIndex: _parseOrder(raw['orderIndex'] ?? raw['OrderIndex']),
      isCompleted: (raw['isCompleted'] ?? raw['IsCompleted'] ?? false) == true,
      numberingLabel: (raw['numberingLabel'] ?? raw['NumberingLabel'] ?? '')
          .toString(),
      children: childNodes,
    );
  }

  int _parseOrder(Object? raw) {
    if (raw is int) return raw;
    return int.tryParse('${raw ?? 0}') ?? 0;
  }

  Object? _preferNonEmpty(Object? preferred, Object? fallback) {
    final p = preferred?.toString().trim() ?? '';
    if (p.isNotEmpty) return preferred;
    return fallback;
  }

  AppError _mapDioException(DioException error) {
    final responseData = error.response?.data;
    final message = responseData is Map<String, dynamic>
        ? (responseData['message'] ??
                  responseData['Message'] ??
                  'Unable to connect to server')
              .toString()
        : 'Unable to connect to server';
    return AppError(message: message, statusCode: error.response?.statusCode);
  }
}
