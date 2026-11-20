import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import 'providers/admins_provider.dart';
import 'providers/songs_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/push_notify_provider.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'screens/admin/admin_sign_in_screen.dart';
import 'screens/admin/admin_panel_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Hive.initFlutter();
  await Hive.openBox("AppPrefs");

  runApp(const SocheFamAdminWebApp());
}

class SocheFamAdminWebApp extends StatelessWidget {
  const SocheFamAdminWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdminsProvider()),
        ChangeNotifierProvider(create: (_) => SongsProvider()),
        ChangeNotifierProvider(create: (_) => AnnouncementsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PushNotificationProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'SOCHE FAM — Admin Portal',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routes: {
              '/admin-sign-in': (_) => const AdminSignInScreen(),
              '/admin-panel': (_) => const AdminPanelScreen(),
            },
            home: const _AdminWebStartupGate(),
          );
        },
      ),
    );
  }
}

class _AdminWebStartupGate extends StatefulWidget {
  const _AdminWebStartupGate();

  @override
  State<_AdminWebStartupGate> createState() => _AdminWebStartupGateState();
}

class _AdminWebStartupGateState extends State<_AdminWebStartupGate> {
  @override
  void initState() {
    super.initState();
    _restoreAdminSession();
  }

  Future<void> _restoreAdminSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await context.read<AdminsProvider>().signInWithUid(user.uid);
      if (!mounted) return;
      if (context.read<AdminsProvider>().isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
        );
        return;
      }
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AdminSignInScreen()),
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
            Text(
              "Loading Soche Fam Admin Portal...",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
