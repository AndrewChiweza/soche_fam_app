import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soche_fam/theme/app_theme.dart';

import '../../providers/favorites_provider.dart';
import '../../providers/songs_provider.dart';
import '../screens/lyrics_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final songsProv = Provider.of<SongsProvider>(context);
    final favProv = Provider.of<FavoritesProvider>(context);
    final favSongs = songsProv.favoriteSongs(favProv.ids);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            scrolledUnderElevation: 0.0,
            pinned: true,
            expandedHeight: 140,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final top = constraints.biggest.height;
                final collapseFactor =
                    ((top - kToolbarHeight) / (140 - kToolbarHeight))
                        .clamp(0.0, 1.0);

                return Stack(
                  children: [
                    const FlexibleSpaceBar(
                      titlePadding: EdgeInsets.only(left: 16, bottom: 16),
                      title: Text(
                        "Favorites",
                        style: TextStyle(letterSpacing: 1.2),
                      ),
                      centerTitle: false,
                    ),
                    Positioned(
                      left: 16,
                      bottom: 12,
                      child: Opacity(
                        opacity: collapseFactor,
                        child: Container(
                          width: 80,
                          height: 4,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            actions: [
              if (favSongs.isNotEmpty)
                IconButton(
                  icon: const Icon(CupertinoIcons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Clear Favorites"),
                        content: const Text(
                            "Are you sure you want to remove all favorites?"),
                        backgroundColor: Theme.of(context).cardColor,
                        actions: [
                          TextButton(
                            child: const Text("Cancel"),
                            onPressed: () => Navigator.pop(context),
                          ),
                          TextButton(
                            child: const Text(
                              "Clear",
                              style: TextStyle(color: Colors.red),
                            ),
                            onPressed: () {
                              for (var s in favSongs) {
                                favProv.toggleFavorite(s.id);
                              }
                              Navigator.pop(context);

                              _showSnackBar(
                                context,
                                "All favorites songs removed!",
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),

          /// NO FAVORITES
          if (favSongs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'Favorite Songs will appear here!',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            )
          else

            /// FAVORITES LIST
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 12,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final song = favSongs[i];
                    final isFav = favProv.isFavorite(song.id);

                    return Column(
                      children: [
                        if (i != 0) const Divider(height: 0.2),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => LyricsScreen(songId: song.id),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    song.title,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    isFav
                                        ? CupertinoIcons.heart_fill
                                        : CupertinoIcons.heart,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    favProv.toggleFavorite(song.id);

                                    _showSnackBar(
                                      context,
                                      "Song removed from favorites",
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (i != favSongs.length - 1)
                          const Divider(height: 0.2),
                      ],
                    );
                  },
                  childCount: favSongs.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
