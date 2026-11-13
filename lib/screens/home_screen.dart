import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soche_fam/models/notification.dart';

import 'package:soche_fam/providers/favorites_provider.dart';
import 'package:soche_fam/providers/notifications_provider.dart';
import 'package:soche_fam/providers/songs_provider.dart';

import 'package:soche_fam/screens/admin/admin_sign_in_screen.dart';
import 'package:soche_fam/screens/member_payments_list_screen.dart';
import 'package:soche_fam/screens/registration_form_screen.dart';
import 'package:soche_fam/theme/app_theme.dart';
import '../screens/lyrics_screen.dart';
import '../screens/notifications_screen.dart';
import '../components/song_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _q = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final songsProv = context.read<SongsProvider>();
      final favProv = context.read<FavoritesProvider>();
      final notProv = context.read<AnnouncementsProvider>();

      await songsProv.loadSongs();
      favProv.syncFavoritesWithSongs(songsProv.songs);
      await notProv.loadAnnouncements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final songsProv = context.watch<SongsProvider>();
    final songs = _q.isEmpty ? songsProv.songs : songsProv.search(_q);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          /// 🔰 SLIVER APP BAR
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
                // How collapsed the app bar is (0 = fully collapsed, 1 = fully expanded)
                final collapseFactor =
                    ((top - kToolbarHeight) / (140 - kToolbarHeight))
                        .clamp(0.0, 1.0);

                return Stack(
                  children: [
                    FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                      title: GestureDetector(
                        onLongPress: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminSignInScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "SOCHE FAM",
                          style: TextStyle(letterSpacing: 1.2),
                        ),
                      ),
                      centerTitle: false,
                    ),
                    // 🔹 Line under title with space and fade-out on collapse
                    Positioned(
                      left: 16,
                      bottom: 12, // space between title and line
                      child: Opacity(
                        opacity: collapseFactor, // fades out as we scroll
                        child: Container(
                          width: 80, // width under the text
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
              /// 🔍 SEARCH
              IconButton(
                icon: const Icon(CupertinoIcons.search),
                onPressed: () async {
                  final res = await showSearch(
                    context: context,
                    delegate: _SongSearchDelegate(songsProv),
                  );
                  if (res != null) setState(() => _q = res);
                },
              ),

              /// 🔔 NOTIFICATIONS
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(CupertinoIcons.bell),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: StreamBuilder<List<Announcement>>(
                      stream: context
                          .read<AnnouncementsProvider>()
                          .announcementsStream,
                      builder: (context, snapshot) {
                        final count = snapshot.data?.length ?? 0;
                        if (count == 0) return const SizedBox.shrink();

                        return Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              /// ⋮ MENU

              /// ⋮ MENU (Includes Be a Member and Payments)
              PopupMenuButton<String>(
                color: Theme.of(context).cardColor,
                icon: const Icon(CupertinoIcons.ellipsis_vertical),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onSelected: (value) {
                  if (value == 'register') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MemberRegistrationScreen(),
                      ),
                    );
                  } else if (value == 'payments') {
                    // ✅ Dynamic redirection to public billing statement list dashboard panel
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MemberPaymentsListScreen(),
                      ),
                    );
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem<String>(
                    value: 'register',
                    child: Row(
                      children: [
                        Icon(Icons.person_add_outlined),
                        SizedBox(width: 8),
                        Text("Be a Member"),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'payments',
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.creditcard, size: 22),
                        SizedBox(width: 8),
                        Text("Payments & Dues"),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
            ],
          ),

          /// 📜 SONG LIST WITH SPACING AND DIVIDERS (NO CONTAINER, NO SHADOW)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final song = songs[i];

                  return Column(
                    children: [
                      if (i != 0)
                        const Divider(
                          height: 0.2,
                          indent: 0,
                          endIndent: 0,
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: SongTile(
                          song: song,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LyricsScreen(songId: song.id),
                            ),
                          ),
                        ),
                      ),
                      if (i != songs.length - 1)
                        const Divider(
                          height: 0.2,
                          indent: 0,
                          endIndent: 0,
                        ),
                    ],
                  );
                },
                childCount: songs.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------- SEARCH DELEGATE ----------------

/// ---------------- SEARCH DELEGATE ----------------

class _SongSearchDelegate extends SearchDelegate<String> {
  final SongsProvider provider;
  _SongSearchDelegate(this.provider);

  @override
  String? get searchFieldLabel => "Type song title or number...";

  @override
  TextStyle? get searchFieldStyle => const TextStyle(fontSize: 16);

  /// 🔹 MATCH SEARCH BAR THEME
  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: theme.iconTheme,
        elevation: 0,
        toolbarTextStyle: theme.textTheme.titleLarge,
        titleTextStyle: theme.textTheme.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: theme.cardColor,
        filled: true,
        hintStyle: theme.textTheme.bodyMedium,
      ),
    );
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(CupertinoIcons.chevron_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(CupertinoIcons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = provider.search(query);

    // ✅ FIXED: Gives interactive visual feedback if results are empty [INDEX]
    if (results.isEmpty && query.trim().isNotEmpty) {
      return _buildNoResultsWidget();
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: results.length,
      itemBuilder: (_, i) => ListTile(
        leading: const Icon(Icons.music_note),
        title: Text(results[i].title),
        onTap: () {
          close(context, '');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LyricsScreen(songId: results[i].id),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = provider.search(query);

    // ✅ FIXED: Gives interactive visual feedback if suggestions are empty [INDEX]
    if (suggestions.isEmpty && query.trim().isNotEmpty) {
      return _buildNoResultsWidget();
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: suggestions.length,
      itemBuilder: (_, i) => ListTile(
        leading: const Icon(Icons.music_note_outlined),
        title: Text(suggestions[i].title),
        onTap: () {
          close(context, '');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LyricsScreen(songId: suggestions[i].id),
            ),
          );
        },
      ),
    );
  }

  /// 🎨 Reusable helper widget to draw the "No results found" panel cleanly [INDEX]
  Widget _buildNoResultsWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.search_circle,
                size: 68, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              "No results found for '$query'",
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              "Verify your spelling parameters or try searching for another hymn keyword or number.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}
