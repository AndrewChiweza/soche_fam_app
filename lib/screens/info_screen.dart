import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:soche_fam/theme/app_theme.dart';
import 'package:soche_fam/theme/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({Key? key}) : super(key: key);

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  void shareApp() {
    Share.share(
      '🎶 *SOCHE FAM Songs App* 🎶\n\n'
      'Download the latest APK here:\n'
      '👉 https://drive.google.com/file/d/1c9Gdyg89mZDeuHomY68gnqszRe5IT9Z1/view?usp=sharing\n\n'
      'Be blessed! 🙏',
      subject: 'SOCHE FAM App',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          /// 🔰 SLIVER APP BAR
          SliverAppBar(
            scrolledUnderElevation: 0.0,
            pinned: true,
            expandedHeight: 100,
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
                    FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                      title: const Text(
                        "Info",
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
          ),

          /// 📜 CONTENT
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Container(
                  height: 150,
                  width: 150,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.asset('images/ic_launcher.png'),
                  ),
                ),
                const SizedBox(height: 17),
                const Text(
                  'SOCHE FAM SONGS APP',
                  style: TextStyle(letterSpacing: 1),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                Text(
                  "Version 1.0.0",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Card(
                  color: Theme.of(context).cardColor,
                  elevation: 4,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      _infoTile(
                        context: context,
                        icon: FontAwesomeIcons.github,
                        title: "View source code",
                        onTap: () =>
                            _launch("https://github.com/AndrewChiweza"),
                      ),
                      _divider(),
                      _infoTile(
                        context: context,
                        icon: FontAwesomeIcons.facebook,
                        iconColor: Colors.blue,
                        title: "Facebook Developer",
                        onTap: () =>
                            _launch("https://facebook.com/andrew.chiweza"),
                      ),
                      _divider(),
                      _infoTile(
                        context: context,
                        icon: FontAwesomeIcons.shareNodes,
                        title: "Share this app...",
                        onTap: shareApp,
                      ),
                      _divider(),
                      _infoTile(
                        context: context,
                        icon: Icons.help_outline,
                        title: "Help or Feedback",
                        onTap: () async {
                          final email =
                              Uri.encodeComponent("andrewchiwz@gmail.com");
                          final subject = Uri.encodeComponent(
                              "SOCHE FAM songs App feedback");
                          final body = Uri.encodeComponent(
                              "Hi Andrew, I have this feedback on Soche Fam Songs app:... ");
                          final Uri mail = Uri.parse(
                              "mailto:$email?subject=$subject&body=$body");

                          if (await canLaunchUrl(mail)) {
                            await launchUrl(mail,
                                mode: LaunchMode.externalApplication);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Could not open email app')),
                            );
                          }
                        },
                      ),
                      _divider(),
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, child) {
                          return SwitchListTile(
                            title: const Text("Dark Mode"),
                            value: themeProvider.isDark,
                            onChanged: (value) =>
                                themeProvider.toggleTheme(value),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                Text(
                  "This app was made with love by Andrew Chiweza, a Software Developer and a member of Soche Future Adventist Men.\n\n"
                  "With gratitude of what the community has done for him. May God bless you as you are ministering through singing.\n\n"
                  "Please consider leaving a review in the Help or feedback, it helps more than you can imagine.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.2,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 50),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- CUSTOM WIDGETS ---------------- //

  Widget _divider() => const Divider(height: 1, thickness: 0.4);

  Widget _infoTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        size: 22,
        color: iconColor ?? Theme.of(context).iconTheme.color,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
      trailing: Icon(
        CupertinoIcons.chevron_forward,
        size: 18,
        color: Theme.of(context).iconTheme.color,
      ),
      onTap: onTap,
    );
  }
}
