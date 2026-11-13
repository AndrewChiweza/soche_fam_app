import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:soche_fam/theme/app_theme.dart';
import '../models/song.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;

  const SongTile({Key? key, required this.song, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        song.title,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 18),
      ),
      trailing: Icon(CupertinoIcons.chevron_compact_right,
          size: 16, color: AppTheme.primaryGreen),
    );
  }
}
