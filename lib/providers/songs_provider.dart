import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/song.dart';

class SongsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Song> _songs = [];
  List<Song> get songs => List.unmodifiable(_songs);

  /// Fetch songs from Firestore
  Future<void> loadSongs() async {
    try {
      final snapshot = await _firestore
          .collection('songs')
          .orderBy("createdAt", descending: false)
          .get();

      _songs =
          snapshot.docs.map((doc) => Song.fromMap(doc.data(), doc.id)).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading songs: $e');
    }
  }

  Song? findById(String id) {
    try {
      return _songs.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Song> search(String q) {
    final low = q.toLowerCase();
    return _songs
        .where((s) =>
            s.title.toLowerCase().contains(low) ||
            s.lyrics.toLowerCase().contains(low))
        .toList();
  }

  Future<void> addSong(Song s) async {
    try {
      final doc = _firestore.collection('songs').doc();

      final newSong = Song(
        id: doc.id,
        title: s.title,
        lyrics: s.lyrics,
        isFavorite: false,
        createdAt: DateTime.now(),
      );

      await doc.set(newSong.toMap());

      _songs.add(newSong);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding song: $e');
    }
  }

  Future<void> updateSong(Song s) async {
    try {
      await _firestore.collection('songs').doc(s.id).update(s.toMap());

      final idx = _songs.indexWhere((el) => el.id == s.id);
      if (idx >= 0) {
        _songs[idx] = s;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating song: $e');
    }
  }

  Future<void> removeSong(String id) async {
    try {
      await _firestore.collection('songs').doc(id).delete();

      _songs.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing song: $e');
    }
  }

  /// Return favorite songs using IDs stored in Hive
  List<Song> favoriteSongs(Set<String> ids) {
    return _songs.where((s) => ids.contains(s.id)).toList();
  }
}
