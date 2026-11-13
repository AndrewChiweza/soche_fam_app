import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  factory Announcement.fromMap(Map<String, dynamic> data, String id) {
    return Announcement(
      id: id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'createdAt': createdAt,
    };
  }
}
