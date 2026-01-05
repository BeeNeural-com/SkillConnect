import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skillconnect/services/notification_service.dart';
import '../models/notification_model.dart';

/// Provider for notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Provider for user notifications stream
final userNotificationsProvider = StreamProvider<List<NotificationModel>>((
  ref,
) {
  final userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: userId)
      .orderBy('timestamp', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList();
      });
});

/// Provider for unread notification count
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId == null) {
    return Stream.value(0);
  }

  return FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: userId)
      .where('isRead', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

/// Provider for marking notification as read
final markNotificationAsReadProvider = Provider<Future<void> Function(String)>((
  ref,
) {
  final notificationService = ref.watch(notificationServiceProvider);
  return (String notificationId) =>
      notificationService.markAsRead(notificationId);
});

/// Provider for deleting notification
final deleteNotificationProvider = Provider<Future<void> Function(String)>((
  ref,
) {
  final notificationService = ref.watch(notificationServiceProvider);
  return (String notificationId) =>
      notificationService.deleteNotification(notificationId);
});

/// Provider for clearing all notifications
final clearAllNotificationsProvider = Provider<Future<void> Function()>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return () => notificationService.clearAllNotifications();
});
