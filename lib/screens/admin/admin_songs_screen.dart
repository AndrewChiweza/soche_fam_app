import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/song.dart';
import '../../services/firestore_service.dart';
import 'song_form_screen.dart';

class AdminSongsScreen extends StatelessWidget {
  final FirestoreService _firestore = FirestoreService();

  AdminSongsScreen({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    Song song,
  ) async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text("Delete Song"),
        content: Text(
          "Are you sure you want to delete \"${song.title}\"?\n\nThis action cannot be undone.",
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text("Delete"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestore.deleteSong(song.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
              content: const Text("Song Deleted")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Manage Songs",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(CupertinoIcons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SongFormScreen(),
            ),
          );
        },
      ),
      body: StreamBuilder<List<Song>>(
        stream: _firestore.getSongs(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final songs = snapshot.data!;

          if (songs.isEmpty) {
            return const Center(
              child: Text(
                "No songs added yet",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];

              return Card(
                color: Theme.of(context).cardColor,
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  title: Text(
                    song.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      song.lyrics.length > 30
                          ? "${song.lyrics.substring(0, 30)}..."
                          : song.lyrics,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: "Edit",
                        icon: const Icon(
                          CupertinoIcons.pencil,
                          color: Colors.blue,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SongFormScreen(existingSong: song),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: "Delete",
                        icon: const Icon(
                          CupertinoIcons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () => _confirmDelete(context, song),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
