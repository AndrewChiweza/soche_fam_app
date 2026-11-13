import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/notification.dart';

class AnnouncementsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _backendUrl =
      "https://soche-fam-backend.onrender.com/api";

  List<Announcement> _items = [];
  List<Announcement> get items => List.unmodifiable(_items);

  /// STREAM for admin & users
  Stream<List<Announcement>> get announcementsStream {
    return _firestore
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Announcement(
                id: doc.id,
                title: doc['title'] ?? '',
                message: doc['message'] ?? '',
                createdAt: (doc['createdAt'] as Timestamp).toDate(),
              ))
          .toList();
    });
  }

  /// Load announcements
  Future<void> loadAnnouncements() async {
    try {
      final snapshot = await _firestore
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .get();

      _items = snapshot.docs
          .map((doc) => Announcement(
                id: doc.id,
                title: doc['title'] ?? '',
                message: doc['message'] ?? '',
                createdAt: (doc['createdAt'] as Timestamp).toDate(),
              ))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading announcements: $e');
    }
  }

  /// Add announcement and broadcast push notification via Render
  Future<void> addAnnouncement(Announcement a) async {
    try {
      final doc = await _firestore.collection('announcements').add({
        'title': a.title,
        'message': a.message,
        'createdAt': a.createdAt,
      });

      _items.insert(
        0,
        Announcement(
          id: doc.id,
          title: a.title,
          message: a.message,
          createdAt: a.createdAt,
        ),
      );

      notifyListeners();

      // Trigger lock-screen push notification to all devices subscribed to 'all_members'
      await http.post(
        Uri.parse('$_backendUrl/notify-members'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': a.title,
          'body': a.message,
          'type': 'announcement',
        }),
      );
    } catch (e) {
      debugPrint('Error adding announcement: $e');
    }
  }

  /// Edit existing announcement
  Future<void> editAnnouncement(Announcement a) async {
    try {
      await _firestore.collection('announcements').doc(a.id).update({
        'title': a.title,
        'message': a.message,
      });

      final index = _items.indexWhere((x) => x.id == a.id);
      if (index != -1) {
        _items[index] = a;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error editing announcement: $e');
    }
  }

  /// Delete announcement
  Future<void> deleteAnnouncement(String id) async {
    try {
      await _firestore.collection('announcements').doc(id).delete();
      _items.removeWhere((x) => x.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting announcement: $e');
    }
  }

  void clearAll() {
    _items.clear();
    notifyListeners();
  }

  Future<void> removeAnnouncement(String id) async {
    return deleteAnnouncement(id);
  }

  void deleteById(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }
}
