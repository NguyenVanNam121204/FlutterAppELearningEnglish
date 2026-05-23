import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "dart:async";

import "../../../app/providers.dart";
import "../../../app/router/route_paths.dart";
import "../../../models/home/home_course_model.dart";
import "../../widgets/common/catalunya_reveal.dart";
import "../../widgets/common/catalunya_scaffold.dart";
import "../../widgets/home/home_header_card.dart";
import "../../widgets/home/home_notification_button.dart";
import "../../widgets/home/streak_section.dart";
import "../../widgets/home/suggested_courses_section.dart";

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final AppLifecycleListener _lifecycleListener;
  Timer? _notificationPollingTimer;

  Future<void> _openNotifications() async {
    await context.push(RoutePaths.notifications);
    if (!mounted) return;
    ref.invalidate(notificationUnreadCountProvider);
  }

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        if (mounted) {
          ref.read(homeViewModelProvider.notifier).loadHomeData();
          ref.invalidate(notificationUnreadCountProvider);
        }
      },
    );
    Future.microtask(() {
      ref.read(homeViewModelProvider.notifier).loadHomeData();
    });
    _notificationPollingTimer = Timer.periodic(const Duration(seconds: 30), (
      _,
    ) {
      if (!mounted) return;
      ref.invalidate(notificationUnreadCountProvider);
    });
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _notificationPollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _openCourse(HomeCourseModel course) async {
    await context.push(RoutePaths.courseInCourses(course.courseId.toString()));
    if (mounted) {
      ref.read(homeViewModelProvider.notifier).loadHomeData();
    }
  }

  Future<void> _enrollCourse(HomeCourseModel course) async {
    await context.push("${RoutePaths.courseDetail}?courseId=${course.courseId}");
    if (mounted) {
      ref.read(homeViewModelProvider.notifier).loadHomeData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authViewModelProvider).user;
    final homeState = ref.watch(homeViewModelProvider);
    final unreadCountAsync = ref.watch(notificationUnreadCountProvider);
    final unreadCount = unreadCountAsync.valueOrNull ?? 0;
    final isUnreadLoading = unreadCountAsync.isLoading;
    final displayName = (user?.displayName ?? "").trim().isEmpty
        ? "bạn"
        : user!.displayName.trim();
    final initials = displayName
        .split(RegExp(r"\s+"))
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e[0].toUpperCase())
        .join();

    return CatalunyaScaffold(
      appBar: AppBar(
        title: const Text("Catalunya English"),
        actions: [
          HomeNotificationButton(
            unreadCount: unreadCount,
            isLoading: isUnreadLoading,
            onTap: _openNotifications,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                context.go(RoutePaths.mainAppProfile);
              },
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFDFF1FF),
                backgroundImage: (user?.avatarUrl ?? "").trim().isNotEmpty
                    ? NetworkImage(user!.avatarUrl!.trim())
                    : null,
                child: (user?.avatarUrl ?? "").trim().isEmpty
                    ? Text(
                        initials.isEmpty ? "U" : initials,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0A84FF),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(homeViewModelProvider.notifier).loadHomeData();
          ref.invalidate(notificationUnreadCountProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: CatalunyaReveal(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Chào ngày mới,",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: CatalunyaReveal(
                delay: const Duration(milliseconds: 100),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: HomeHeaderCard(displayName: displayName),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: CatalunyaReveal(
                delay: const Duration(milliseconds: 200),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: StreakSection(streak: homeState.streak),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: CatalunyaReveal(
                delay: const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SuggestedCoursesSection(
                    courses: homeState.suggestedCourses,
                    isLoading: homeState.isLoading,
                    onEnrollCourse: _enrollCourse,
                    onOpenCourse: _openCourse,
                  ),
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }
}
