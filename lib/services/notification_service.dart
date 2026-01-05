import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  // Background messages are handled by the system notification
}

/// Service for managing push notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _initialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request notification permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get and save FCM token
      await _saveFCMToken();

      // Listen for token refresh
      _fcm.onTokenRefresh.listen(_updateFCMToken);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      _initialized = true;
      print('NotificationService initialized successfully');
    } catch (e) {
      print('Error initializing NotificationService: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional notification permission');
    } else {
      print('User declined notification permission');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const channel = AndroidNotificationChannel(
      'skillconnect_notifications',
      'SkillConnect Notifications',
      description: 'Notifications for bookings, messages, and updates',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// Get and save FCM token to Firestore
  Future<void> _saveFCMToken() async {
    try {
      final token = await _fcm.getToken();
      print('=== FCM TOKEN ===');
      print('Token: $token');

      if (token != null) {
        final userId = _auth.currentUser?.uid;
        print('Current User ID: $userId');

        if (userId != null) {
          await _firestore.collection('users').doc(userId).update({
            'fcmToken': token,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          });
          print('✓ FCM token saved successfully to Firestore');
        } else {
          print('✗ ERROR: No user logged in, cannot save FCM token');
        }
      } else {
        print('✗ ERROR: Failed to get FCM token from device');
      }
      print('=================');
    } catch (e) {
      print('✗ ERROR saving FCM token: $e');
    }
  }

  /// Update FCM token when it refreshes
  Future<void> _updateFCMToken(String token) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        print('FCM token updated: $token');
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Foreground message received: ${message.messageId}');

    // Do NOT save to Firestore here, as the notification likely originated from Firestore
    // and saving it again would trigger the Cloud Function loop.

    // Show local notification
    await _showLocalNotification(message);
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'skillconnect_notifications',
      'SkillConnect Notifications',
      channelDescription: 'Notifications for bookings, messages, and updates',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: message.data['type'],
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Navigation will be handled by the app's navigation logic
    // The payload contains the notification type
  }

  /// Handle notification tap when app is in background
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification opened app: ${message.data}');
    // Navigation logic will be implemented in the main app
  }

  /// Send notification to a specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('=== SENDING NOTIFICATION ===');
      print('To User ID: $userId');
      print('Title: $title');
      print('Body: $body');
      print('Type: $type');

      // Save notification to Firestore
      final notification = NotificationModel(
        id: '',
        userId: userId,
        title: title,
        body: body,
        type: type,
        timestamp: DateTime.now(),
        isRead: false,
        data: data,
      );

      final docRef = await _firestore
          .collection('notifications')
          .add(notification.toFirestore());

      print('✓ Notification saved to Firestore with ID: ${docRef.id}');

      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        print('✗ ERROR: User document not found for userId: $userId');
        return;
      }

      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken != null) {
        print('✓ User has FCM token: ${fcmToken.substring(0, 20)}...');
        print('✓ Cloud Function should send push notification now');
      } else {
        print(
          '✗ WARNING: User has no FCM token saved. Push notification will not be sent.',
        );
        print('  User needs to open the app to register FCM token.');
      }

      print('=== NOTIFICATION PROCESS COMPLETE ===');
    } catch (e) {
      print('✗ ERROR sending notification: $e');
      rethrow;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  /// Clear all notifications for current user
  Future<void> clearAllNotifications() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }
}
