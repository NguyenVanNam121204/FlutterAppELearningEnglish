import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router/route_paths.dart';
import '../../../models/learning/lecture_models.dart';
import '../../widgets/common/catalunya_scaffold.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/state_views.dart';

class ModuleLearningScreen extends ConsumerStatefulWidget {
  const ModuleLearningScreen({required this.moduleId, super.key});
  final String moduleId;

  @override
  ConsumerState<ModuleLearningScreen> createState() =>
      _ModuleLearningScreenState();
}

class _ModuleLearningScreenState extends ConsumerState<ModuleLearningScreen> {
  bool _started = false;
  bool _expansionInitialized = false;
  final Set<String> _expandedIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_started || !mounted) return;
      _started = true;
      await ref
          .read(lessonFeatureViewModelProvider)
          .startModule(widget.moduleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncLectures = ref.watch(moduleLectureTreeProvider(widget.moduleId));
    return CatalunyaScaffold(
      appBar: AppBar(title: const Text('Học theo module')),
      body: asyncLectures.when(
        data: (treeLectures) {
          if (treeLectures.isEmpty) {
            return const Center(
              child: EmptyStateView(
                message: 'Không có bài giảng hoặc module đang được cập nhật',
                icon: Icons.menu_book_outlined,
              ),
            );
          }

          final leaves = treeLectures
              .expand((node) => node.flattenLeaves())
              .toList();
          final currentIndex = leaves.indexWhere((item) => !item.isCompleted);
          final focusIndex = currentIndex >= 0 ? currentIndex : 0;
          final focusLeafId = leaves[focusIndex].lectureId;

          if (!_expansionInitialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _expansionInitialized) return;
              setState(() {
                _expandPathToFocus(treeLectures, focusLeafId);
                _expansionInitialized = true;
              });
            });
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withValues(alpha: 0.9),
                  border: Border.all(color: const Color(0xFFD8E6F8)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F4FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.menu_book_rounded),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Danh sách bài giảng',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Đang học ${focusIndex + 1}/${leaves.length} • ${leaves.where((e) => e.isCompleted).length} đã hoàn thành',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...treeLectures.map(
                (node) => _buildTreeNode(
                  context: context,
                  node: node,
                  level: 0,
                  focusLeafId: focusLeafId,
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingStateView(),
        error: (error, _) => ErrorStateView(message: '$error'),
      ),
    );
  }

  void _expandPathToFocus(
    List<LectureTreeItemModel> roots,
    String focusLeafId,
  ) {
    bool walk(LectureTreeItemModel node) {
      if (node.lectureId == focusLeafId) {
        return true;
      }
      for (final child in node.children) {
        if (walk(child)) {
          if (node.hasChildren) {
            _expandedIds.add(node.lectureId);
          }
          return true;
        }
      }
      return false;
    }

    for (final root in roots) {
      walk(root);
    }
    for (final root in roots) {
      if (root.hasChildren) {
        _expandedIds.add(root.lectureId);
      }
    }
  }

  Widget _buildTreeNode({
    required BuildContext context,
    required LectureTreeItemModel node,
    required int level,
    required String focusLeafId,
  }) {
    final isLeaf = !node.hasChildren;
    final isExpanded = _expandedIds.contains(node.lectureId);
    final isCurrentLeaf = isLeaf && node.lectureId == focusLeafId;
    final subtitle = node.subtitle.trim().isNotEmpty
        ? node.subtitle
        : isLeaf
        ? (node.isCompleted
              ? 'Đã hoàn thành • Mở lại bài giảng'
              : 'Mở bài giảng')
        : '';
    final orderText = node.numberingLabel.trim().isNotEmpty
        ? node.numberingLabel
        : '${node.orderIndex > 0 ? node.orderIndex : 1}';

    final row = Container(
      margin: EdgeInsets.only(left: level * 20.0, bottom: 8),
      decoration: BoxDecoration(
        color: isCurrentLeaf ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrentLeaf
              ? const Color(0xFFBFDBFE)
              : node.isCompleted
              ? const Color(0xFFB9EBCF)
              : const Color(0xFFDCE8F8),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            if (isLeaf) {
              context.push(
                '${RoutePaths.lectureDetail}?lectureId=${node.lectureId}',
              );
              return;
            }
            setState(() {
              if (isExpanded) {
                _expandedIds.remove(node.lectureId);
              } else {
                _expandedIds.add(node.lectureId);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: node.isCompleted
                        ? const Color(0xFFE7F9EF)
                        : isCurrentLeaf
                        ? const Color(0xFFE7F1FF)
                        : const Color(0xFFE8F2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: node.isCompleted
                        ? const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: Color(0xFF10B981),
                          )
                        : isLeaf
                        ? Text(
                            orderText,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: isCurrentLeaf
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF0EA5E9),
                                ),
                          )
                        : Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.keyboard_arrow_right_rounded,
                            size: 20,
                            color: const Color(0xFF64748B),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isCurrentLeaf
                                  ? const Color(0xFF1D4ED8)
                                  : const Color(0xFF1F2937),
                            ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (isCurrentLeaf) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Text(
                            'Đang học',
                            style: TextStyle(
                              color: Color(0xFF1D4ED8),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isLeaf) const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );

    if (!node.hasChildren || !isExpanded) {
      return row;
    }

    return Column(
      children: [
        row,
        ...node.children.map(
          (child) => _buildTreeNode(
            context: context,
            node: child,
            level: level + 1,
            focusLeafId: focusLeafId,
          ),
        ),
      ],
    );
  }
}
