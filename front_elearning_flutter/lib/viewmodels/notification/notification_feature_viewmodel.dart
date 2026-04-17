import '../../core/result/result.dart';
import '../../models/notification/notification_model.dart';
import '../../repositories/notification/notification_repository.dart';

class NotificationFeatureViewModel {
  NotificationFeatureViewModel(this._repository);

  final NotificationRepository _repository;

  Future<Result<List<NotificationItemModel>>> notifications() async {
    return _repository.notifications();
  }

  Future<Result<int>> unreadCount() async {
    return _repository.unreadCount();
  }

  Future<Result<void>> markAsRead(String id) async {
    return _repository.markAsRead(id);
  }

  Future<Result<void>> markAllRead() async {
    return _repository.markAllRead();
  }
}
