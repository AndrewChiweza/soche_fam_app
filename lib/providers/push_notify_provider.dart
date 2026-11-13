import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../main.dart';
import '../screens/member_payments_list_screen.dart';
import '../screens/notifications_screen.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Background FCM received: ${message.notification?.title}");
}

class PushNotificationProvider with ChangeNotifier {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Fixed to point to your live Render Node.js backend API
  static const String _backendUrl = "https://soche-fam-backend.onrender.com";

  final List<RemoteMessage> _messages = [];
  List<RemoteMessage> get messages => _messages;

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  PushNotificationProvider() {
    _initNotifications();
  }

  /// Routes the user directly to Payments or Announcements based on notification type
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'] ?? 'announcement';

    if (type == 'payment_due') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const MemberPaymentsListScreen()),
      );
    } else {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      );
    }
  }

  Future<void> _initNotifications() async {
    try {
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (!kIsWeb) {
        await _fcm.subscribeToTopic('all_members');
      }
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'soche_fam_alerts',
        'Soche Fam Announcements & Alerts',
        description:
            'Notifications for new choir announcements and contributions',
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // 1. Handle taps on foreground local notification banners
      await _localNotifications.initialize(
        const InitializationSettings(android: androidSettings),
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payloadType = response.payload ?? 'announcement';
          _handleNotificationNavigation({'type': payloadType});
        },
      );

      // 2. Handle taps when app is in the background (minimized)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationNavigation(message.data);
      });

      // 3. Handle taps when app was completely closed (terminated)
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleNotificationNavigation(initialMessage.data);
        });
      }

      // 4. Listen for incoming foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _messages.insert(0, message);
        notifyListeners();

        final notification = message.notification;
        if (notification != null) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                importance: Importance.max,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
            ),
            payload: message.data['type'] ?? 'announcement',
          );
        }
      });
    } catch (e) {
      debugPrint("FCM initialization error: $e");
    }
  }

  Future<void> subscribeAdminToPaymentAlerts() async {
    if (kIsWeb) return;
    try {
      await _fcm.subscribeToTopic('admins');
    } catch (e) {
      debugPrint("Failed to subscribe admin topic: $e");
    }
  }

  Future<void> unsubscribeAdminFromPaymentAlerts() async {
    if (kIsWeb) return;
    try {
      await _fcm.unsubscribeFromTopic('admins');
    } catch (e) {
      debugPrint("Failed to unsubscribe admin topic: $e");
    }
  }

  Future<void> sendBroadcastToAllMembers({
    required String title,
    required String body,
    String type = 'announcement',
  }) async {
    try {
      await http.post(
        Uri.parse('$_backendUrl/notify-members'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'body': body,
          'type': type,
        }),
      );
    } catch (e) {
      debugPrint("Failed to trigger broadcast push: $e");
    }
  }
}
