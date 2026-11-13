import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:soche_fam/theme/app_theme.dart';
import '../../models/song.dart';
import '../../services/firestore_service.dart';

class SongFormScreen extends StatefulWidget {
  final Song? existingSong;

  const SongFormScreen({super.key, this.existingSong});

  @override
  State<SongFormScreen> createState() => _SongFormScreenState();
}

class _SongFormScreenState extends State<SongFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestore = FirestoreService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _lyricsController = TextEditingController();

  bool isEditing = false;
  String? songId;

  @override
  void initState() {
    super.initState();
    if (widget.existingSong != null) {
      isEditing = true;
      final s = widget.existingSong!;
      songId = s.id;
      _titleController.text = s.title;
      _lyricsController.text = s.lyrics;
    }
  }

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Theme.of(context).cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  /// Helper method for showing success snackbars
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveSong() async {
    if (!_formKey.currentState!.validate()) return;

    final song = Song(
      id: songId ?? "",
      title: _titleController.text.trim(),
      lyrics: _lyricsController.text.trim(),
      createdAt: widget.existingSong?.createdAt ?? DateTime.now(),
    );

    if (isEditing) {
      await _firestore.updateSong(songId!, song);
      _showSuccessSnackbar("Song updated successfully!");
    } else {
      await _firestore.addSong(song);
      _showSuccessSnackbar("Song added successfully!");
    }

    // Close the screen after showing the snackbar
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          /// 🔷 APP BAR
          SliverAppBar(
            pinned: true,
            elevation: 2,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
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
            title: Text(
              isEditing ? "Edit Song" : "Add Song",
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            centerTitle: true,
          ),

          /// 📝 FORM
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Material(
                  elevation: 3,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: _input(
                            "Song Title",
                            CupertinoIcons.music_note,
                          ),
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _lyricsController,
                          maxLines: 12,
                          decoration: _input(
                            "Lyrics",
                            CupertinoIcons.doc_text,
                          ),
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveSong,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              isEditing ? "Update Song" : "Add Song",
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
