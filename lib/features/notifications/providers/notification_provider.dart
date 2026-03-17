import 'package:flutter/material.dart';
import '../data/repositories/notification_repository.dart';
import '../../clubs/data/repositories/club_repository.dart';
import '../data/models/notification.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository;
  final ClubRepository _clubRepository;
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  NotificationProvider(this._repository, this._clubRepository);

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchNotifications() async {
    _setLoading(true);
    _error = null;
    try {
      _notifications = await _repository.getNotifications();
      _unreadCount = await _repository.getUnreadCount();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      // Local update
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        // Since models are immutable, we'd normally copyWith, 
        // but for this implementation we'll just re-fetch for simplicity 
        // OR just update the unread count local state.
        await fetchNotifications(); 
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> handleInvitation(String invitationId, bool accept) async {
    _setLoading(true);
    _error = null;
    try {
      if (accept) {
        await _clubRepository.acceptInvitation(invitationId);
      } else {
        await _clubRepository.declineInvitation(invitationId);
      }
      await fetchNotifications();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> handleClubRequest(String requestId, bool approve) async {
    _setLoading(true);
    _error = null;
    try {
      if (approve) {
        await _clubRepository.approveClubRequest(requestId);
      } else {
        await _clubRepository.rejectClubRequest(requestId);
      }
      await fetchNotifications();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }
}
