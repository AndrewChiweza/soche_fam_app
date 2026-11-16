import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:soche_fam/components/main_tabs.dart';
import 'package:soche_fam/providers/push_notify_provider.dart';
import 'package:soche_fam/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:soche_fam/theme/theme_provider.dart';
import 'firebase_options.dart';

import 'providers/songs_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/notifications_provider.dart';
import 'screens/welcome_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await Hive.initFlutter();
  await Hive.openBox("Favorites");
  await Hive.openBox("AppPrefs");

  runApp(const SongLyricsApp());
}

class SongLyricsApp extends StatelessWidget {
  const SongLyricsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SongsProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => AnnouncementsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
            create: (_) => PushNotificationProvider(), lazy: false),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'SOCHE FAM',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const StartupScreen(),
          );
        },
      ),
    );
  }
}

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    _checkStartup();
  }

  Future<void> _checkStartup() async {
    final box = Hive.box("AppPrefs");
    final isFirstLaunch = box.get("first_launch", defaultValue: true);

    await Future.delayed(const Duration(milliseconds: 600));

    if (isFirstLaunch) {
      box.put("first_launch", false);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomePage()),
      );
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainTabs()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF00674F)),
            SizedBox(height: 16),
            Text("Loading Soche Fam...",
                style:
                    TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
