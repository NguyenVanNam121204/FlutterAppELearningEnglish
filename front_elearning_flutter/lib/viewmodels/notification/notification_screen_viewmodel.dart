import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/result/result.dart';
import '../../models/notification/notification_model.dart';
import 'notification_feature_viewmodel.dart';

class NotificationScreenState {
  const NotificationScreenState({
    this.items = const [],
    this.isLoading = false,
    this.isActing = false,
    this.errorMessage = '',
  });

  final List<NotificationItemModel> items;
  final bool isLoading;
  final bool isActing;
  final String errorMessage;

  NotificationScreenState copyWith({
    List<NotificationItemModel>? items,
    bool? isLoading,
    bool? isActing,
    String? errorMessage,
  }) {
    return NotificationScreenState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isActing: isActing ?? this.isActing,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class NotificationScreenViewModel
    extends StateNotifier<NotificationScreenState> {
  NotificationScreenViewModel(this._feature)
    : super(const NotificationScreenState(isLoading: true));

  final NotificationFeatureViewModel _feature;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, errorMessage: '');
    final result = await _feature.notifications();
    switch (result) {
      case Success(:final value):
        state = state.copyWith(
          items: value,
          isLoading: false,
          errorMessage: '',
        );
      case Failure(:final error):
        state = state.copyWith(isLoading: false, errorMessage: error.message);
    }
  }

  Future<void> markAsRead(NotificationItemModel item) async {
    final id = item.id;
    if (id.isEmpty) return;
    if (item.isRead) return;

    final updatedBeforeCall = state.items
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    state = state.copyWith(items: updatedBeforeCall);

    final result = await _feature.markAsRead(id);
    switch (result) {
      case Success():
        state = state.copyWith(items: updatedBeforeCall);
      case Failure(:final error):
        state = state.copyWith(errorMessage: error.message);
    }
  }

  Future<void> markAllRead() async {
    if (state.isActing) return;

    state = state.copyWith(isActing: true);
    final result = await _feature.markAllRead();
    switch (result) {
      case Success():
        final updated = state.items
            .map((n) => n.copyWith(isRead: true))
            .toList();
        state = state.copyWith(items: updated, isActing: false);
      case Failure(:final error):
        state = state.copyWith(isActing: false, errorMessage: error.message);
    }
  }
}
