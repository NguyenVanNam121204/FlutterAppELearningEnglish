import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../../../app/providers.dart';
import '../../../core/search/search_matcher.dart';
import '../../../app/router/route_paths.dart';
import '../../widgets/common/catalunya_scaffold.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/search/search_feedback_panel.dart';
import '../../widgets/search/search_query_bar.dart';
import '../../widgets/search/search_result_course_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({required this.keyword, super.key});

  final String keyword;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  static const _debounceDuration = Duration(milliseconds: 320);

  late final TextEditingController _controller;
  Timer? _debounce;
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    final initialKeyword = widget.keyword.trim();
    _keyword = initialKeyword;
    _controller = TextEditingController(text: initialKeyword);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleDebouncedSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      if (!mounted) return;
      setState(() {
        _keyword = value.trim();
      });
    });
  }

  void _submitSearch([String? value]) {
    _debounce?.cancel();
    final nextKeyword = (value ?? _controller.text).trim();

    setState(() {
      _keyword = nextKeyword;
    });

    final target = nextKeyword.isEmpty
        ? RoutePaths.search
        : '${RoutePaths.search}?keyword=${Uri.encodeQueryComponent(nextKeyword)}';
    context.go(target);
  }

  @override
  Widget build(BuildContext context) {
    final asyncItems = ref.watch(searchCoursesProvider(_keyword));
    final myCoursesAsync = ref.watch(myCoursesListProvider);
    final enrolledCourseIds =
        myCoursesAsync.valueOrNull
            ?.map((item) => item.courseId.trim())
            .toSet() ??
        const <String>{};
    final trimmedKeyword = _keyword.trim();
    final hasKeyword = trimmedKeyword.isNotEmpty;

    return CatalunyaScaffold(
      appBar: AppBar(title: const Text('Tìm khóa học')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SearchQueryBar(
              controller: _controller,
              onChanged: _scheduleDebouncedSearch,
              onSubmitted: _submitSearch,
              onSearchTap: _submitSearch,
            ),
            const SizedBox(height: 12),
            if (hasKeyword)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Đang tìm cho "$_keyword"',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4A5875),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: !hasKeyword
                    ? const SearchFeedbackPanel(
                        key: ValueKey('search-idle'),
                        message:
                            'Nhập từ khóa để tìm khóa học phù hợp bạn nhé !',
                        icon: Icons.manage_search_rounded,
                      )
                    : asyncItems.when(
                        data: (items) {
                          final matchedItems = items
                              .where(
                                (item) => matchesCourseTitle(
                                  item.title,
                                  trimmedKeyword,
                                ),
                              )
                              .toList(growable: false);

                          if (matchedItems.isEmpty) {
                            return const SearchFeedbackPanel(
                              key: ValueKey('search-empty'),
                              message: 'Không có kết quả phù hợp',
                              icon: Icons.search_off_rounded,
                            );
                          }

                          return ListView.separated(
                            key: const ValueKey('search-results'),
                            itemCount: matchedItems.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = matchedItems[index];
                              final isEnrolled =
                                  item.isEnrolled ||
                                  enrolledCourseIds.contains(
                                    item.courseId.trim(),
                                  );
                              return SearchResultCourseCard(
                                item: item,
                                index: index,
                                isEnrolled: isEnrolled,
                                onTap: () => context.go(
                                  RoutePaths.courseInCourses(item.courseId),
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const LoadingStateView(
                          key: ValueKey('search-loading'),
                        ),
                        error: (error, _) => ErrorStateView(
                          key: const ValueKey('search-error'),
                          message: 'Không thể tải kết quả tìm kiếm: $error',
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
