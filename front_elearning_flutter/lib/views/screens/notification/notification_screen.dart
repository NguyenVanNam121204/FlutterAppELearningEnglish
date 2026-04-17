import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../models/notification/notification_model.dart';
import '../../widgets/common/catalunya_scaffold.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/notification/notification_list_item.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  static const _estimatedItemExtent = 104.0;
  final ScrollController _scrollController = ScrollController();
  final Set<String> _autoMarkedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollAutoMark);
    Future.microtask(() async {
      await ref.read(notificationScreenViewModelProvider.notifier).initialize();
      if (!mounted) return;
      final items = ref.read(notificationScreenViewModelProvider).items;
      if (items.isNotEmpty) {
        await _markVisibleUnread(items);
      }
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScrollAutoMark)
      ..dispose();
    super.dispose();
  }

  Future<void> _markAsRead(NotificationItemModel item) async {
    await ref
        .read(notificationScreenViewModelProvider.notifier)
        .markAsRead(item);
    ref.invalidate(notificationUnreadCountProvider);
  }

  void _handleTapMarkAsRead(NotificationItemModel item) {
    _markAsRead(item);
  }

  Future<void> _markAllRead() async {
    await ref.read(notificationScreenViewModelProvider.notifier).markAllRead();
    ref.invalidate(notificationUnreadCountProvider);
  }

  void _handleTapMarkAllRead() {
    _markAllRead();
  }

  void _onScrollAutoMark() {
    final state = ref.read(notificationScreenViewModelProvider);
    if (state.items.isEmpty) return;
    _markVisibleUnread(state.items);
  }

  Future<void> _markVisibleUnread(List<NotificationItemModel> items) async {
    if (!_scrollController.hasClients) return;

    final maxOffset = _scrollController.position.maxScrollExtent;
    final rawOffset = _scrollController.offset;
    final offset = rawOffset < 0
        ? 0.0
        : (rawOffset > maxOffset ? maxOffset : rawOffset);
    final viewport = _scrollController.position.viewportDimension;
    final firstCandidate = (offset / _estimatedItemExtent).floor();
    final lastCandidate = ((offset + viewport) / _estimatedItemExtent).ceil();
    final first = firstCandidate < 0
        ? 0
        : (firstCandidate >= items.length ? items.length - 1 : firstCandidate);
    final last = lastCandidate < 0
        ? 0
        : (lastCandidate >= items.length ? items.length - 1 : lastCandidate);

    var changed = false;
    for (var i = first; i <= last; i++) {
      final item = items[i];
      if (item.isRead || item.id.isEmpty || _autoMarkedIds.contains(item.id)) {
        continue;
      }
      _autoMarkedIds.add(item.id);
      changed = true;
      await ref
          .read(notificationScreenViewModelProvider.notifier)
          .markAsRead(item);
    }

    if (changed) {
      ref.invalidate(notificationUnreadCountProvider);
    }
  }

  String _formatTime(String value) {
    final raw = value;
    if (raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)} • ${two(local.day)}/${two(local.month)}/${local.year}';
  }

  IconData _iconOf(int type) {
    switch (type) {
      case 1:
        return Icons.settings;
      case 2:
        return Icons.menu_book;
      case 3:
        return Icons.payments;
      case 4:
        return Icons.alarm;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationScreenViewModelProvider);

    Widget buildStaticBody(Widget child) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(child: child),
          ),
        ],
      );
    }

    return CatalunyaScaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          TextButton(
            onPressed: state.isActing ? null : _handleTapMarkAllRead,
            child: const Text('Đọc hết'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(notificationScreenViewModelProvider.notifier)
              .refresh();
        },
        child: switch ((
          state.isLoading,
          state.errorMessage.isNotEmpty,
          state.items.isEmpty,
        )) {
          (true, _, _) => buildStaticBody(const CircularProgressIndicator()),
          (_, true, true) => buildStaticBody(
            EmptyStateView(
              message: state.errorMessage,
              icon: Icons.error_outline_rounded,
            ),
          ),
          (_, _, true) => buildStaticBody(
            const EmptyStateView(
              message: 'Không có thông báo nào',
              icon: Icons.notifications_off_rounded,
            ),
          ),
          _ => ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 6, bottom: 12),
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              return NotificationListItem(
                item: item,
                formatTime: _formatTime,
                iconOf: _iconOf,
                onTap: () {
                  _handleTapMarkAsRead(item);
                },
              );
            },
          ),
        },
      ),
    );
  }
}
