import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../../../app/providers.dart';
import '../../../app/router/route_paths.dart';
import '../../../core/result/result.dart';
import '../../../models/home/home_course_model.dart';
import '../../widgets/common/catalunya_reveal.dart';
import '../../widgets/common/catalunya_scaffold.dart';
import '../../widgets/home/enroll_course_modal.dart';
import '../../widgets/home/home_header_card.dart';
import '../../widgets/home/home_notification_button.dart';
import '../../widgets/home/streak_section.dart';
import '../../widgets/home/suggested_courses_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Set<int>? _enrollingCourseIdsState;
  Timer? _notificationPollingTimer;

  Set<int> get _enrollingCourseIds => _enrollingCourseIdsState ??= <int>{};

  Future<void> _openNotifications() async {
    await context.push(RoutePaths.notifications);
    if (!mounted) return;
    ref.invalidate(notificationUnreadCountProvider);
  }

  @override
  void initState() {
    super.initState();
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
    _notificationPollingTimer?.cancel();
    super.dispose();
  }

  void _openCourse(HomeCourseModel course) {
    context.push(RoutePaths.courseInCourses(course.courseId.toString()));
  }

  String _formatPrice(double? price) {
    if (price == null || price == 0) {
      return 'Mien phi';
    }
    return '${price.toStringAsFixed(0)}d';
  }

  Future<void> _enrollCourse(HomeCourseModel course) async {
    if (_enrollingCourseIds.contains(course.courseId)) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return EnrollCourseModal(
          courseTitle: course.title,
          priceLabel: _formatPrice(course.price),
          onConfirm: () => Navigator.of(context).pop(true),
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _enrollingCourseIds.add(course.courseId));

    final result = await ref
        .read(paymentFeatureViewModelProvider)
        .enrollCourse(course.courseId.toString());

    if (!mounted) return;
    setState(() => _enrollingCourseIds.remove(course.courseId));

    switch (result) {
      case Success<void>():
        ref.invalidate(notificationUnreadCountProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đăng ký khóa học "${course.title}" thành công. Bạn có thể kiểm tra thông báo và email.',
            ),
          ),
        );
        await ref.read(homeViewModelProvider.notifier).loadHomeData();
        _openCourse(course);
      case Failure<void>(:final error):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authViewModelProvider).user;
    final homeState = ref.watch(homeViewModelProvider);
    final unreadCountAsync = ref.watch(notificationUnreadCountProvider);
    final unreadCount = unreadCountAsync.valueOrNull ?? 0;
    final isUnreadLoading = unreadCountAsync.isLoading;
    final displayName = (user?.displayName ?? '').trim().isEmpty
        ? 'bạn'
        : user!.displayName.trim();
    final initials = displayName
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e[0].toUpperCase())
        .join();

    return CatalunyaScaffold(
      appBar: AppBar(
        title: const Text('Catalunya English'),
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
                backgroundImage: (user?.avatarUrl ?? '').trim().isNotEmpty
                    ? NetworkImage(user!.avatarUrl!.trim())
                    : null,
                child: (user?.avatarUrl ?? '').trim().isEmpty
                    ? Text(
                        initials.isEmpty ? 'U' : initials,
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            CatalunyaReveal(child: HomeHeaderCard(displayName: displayName)),
            const SizedBox(height: 14),
            CatalunyaReveal(
              delay: const Duration(milliseconds: 90),
              child: StreakSection(
                streak: homeState.streak,
                errorMessage: homeState.errorMessage,
              ),
            ),
            const SizedBox(height: 18),
            CatalunyaReveal(
              delay: const Duration(milliseconds: 160),
              child: SuggestedCoursesSection(
                courses: homeState.suggestedCourses,
                isLoading: homeState.isLoading,
                enrollingCourseIds: _enrollingCourseIds,
                onOpenCourse: _openCourse,
                onEnrollCourse: _enrollCourse,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
