import 'package:cloud_firestore/cloud_firestore.dart';

class Song {
  final String id;
  final String title;
  final String lyrics;
  bool isFavorite;
  final DateTime createdAt;

  Song({
    required this.id,
    required this.title,
    required this.lyrics,
    this.isFavorite = false,
    required this.createdAt,
  });

  factory Song.fromMap(Map<String, dynamic> data, String id) {
    return Song(
      id: id,
      title: data['title'] ?? '',
      lyrics: data['lyrics'] ?? '',
      isFavorite: data['isFavorite'] ?? false,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'lyrics': lyrics,
        'isFavorite': isFavorite,
        'createdAt': createdAt,
      };
}
