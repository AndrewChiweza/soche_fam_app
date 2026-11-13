import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/push_notify_provider.dart';

class NotificationDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> notification;

  const NotificationDetailsScreen({Key? key, required this.notification})
      : super(key: key);

  String formatDate(DateTime date) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    const days = [
      "Sunday",
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday"
    ];

    return "${days[date.weekday % 7]}, ${date.day} ${months[date.month - 1]} ${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final announcementsProv = Provider.of<AnnouncementsProvider>(context);
    final pushProv = Provider.of<PushNotificationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Notification"),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.delete, color: Colors.red),
            onPressed: () {
              if (notification['type'] == 'announcement') {
                announcementsProv.deleteById(notification['id']);
              } else {
                pushProv.messages.removeWhere(
                    (m) => m.hashCode.toString() == notification['id']);
                pushProv.notifyListeners();
              }

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.green,
                  content: Text(
                    "Notification deleted successfully",
                    style: TextStyle(color: Colors.white),
                  ),
                  behavior: SnackBarBehavior.floating,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification['title'],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              notification['message'],
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Text(
              formatDate(notification['createdAt']),
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
