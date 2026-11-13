import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class FavoritesProvider with ChangeNotifier {
  static const _boxName = 'Favorites';
  static const _key = 'favorite_song_ids';

  final Box _box = Hive.box(_boxName);
  final Set<String> _favoriteIds = {};

  FavoritesProvider() {
    _loadFromHive();
  }

  Set<String> get ids => _favoriteIds;

  bool isFavorite(String id) => _favoriteIds.contains(id);

  /// Toggle favorite status
  Future<void> toggleFavorite(String id) async {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    notifyListeners();
    await _saveToHive();
  }

  /// Load favorite IDs from Hive
  void _loadFromHive() {
    final list = _box.get(_key, defaultValue: <String>[]);
    _favoriteIds.clear();
    _favoriteIds.addAll(List<String>.from(list));
    notifyListeners();
  }

  /// Save favorite IDs to Hive
  Future<void> _saveToHive() async {
    await _box.put(_key, _favoriteIds.toList());
  }

  /// Mark songs as favorite based on stored IDs
  void syncFavoritesWithSongs(List<dynamic> songs) {
    for (var song in songs) {
      song.isFavorite = _favoriteIds.contains(song.id);
    }
    notifyListeners();
  }
}
