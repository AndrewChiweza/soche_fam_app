import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soche_fam/screens/admin_payments_dashboard.dart';

import '../../providers/admins_provider.dart';
import '../../providers/push_notify_provider.dart';

import 'admin_songs_screen.dart';
import 'admin_announcements_screen.dart';
import 'admin_members_screen.dart';
import 'admin_manage_admins_screen.dart';
import 'admin_admin_form_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  bool _registrationOpen = true;
  bool _loadingRegStatus = true;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AdminsProvider>();
    if (!provider.isLoggedIn) {
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, '/admin-sign-in');
      });
    }
    _loadRegistrationStatus();
  }

  Future<void> _loadRegistrationStatus() async {
    final doc = await FirebaseFirestore.instance
        .collection('settings')
        .doc('app')
        .get();
    if (doc.exists) {
      setState(() {
        _registrationOpen = doc.data()?['registrationOpen'] ?? true;
        _loadingRegStatus = false;
      });
    } else {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('app')
          .set({'registrationOpen': true});
      setState(() => _loadingRegStatus = false);
    }
  }

  Future<void> _toggleRegistration(bool value) async {
    setState(() => _registrationOpen = value);
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('app')
          .update({'registrationOpen': value});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
              value ? "Registration Enabled" : "Registration Disabled",
              style: const TextStyle(color: Colors.white)),
          backgroundColor: value ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      setState(() => _registrationOpen = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update registration",
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 📊 Inner Tile Component Helper for Firestore metrics tracking streams
  Widget _statsTile(BuildContext context,
      {required Stream<QuerySnapshot> stream,
      required IconData icon,
      required String title,
      required Widget page,
      required String suffix}) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        String total = "...";
        if (snapshot.hasData) {
          total = snapshot.data!.docs.length.toString();
        }
        return ListTile(
          tileColor: Theme.of(context).cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Icon(icon, color: Theme.of(context).primaryColor),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("$total $suffix stored"),
          trailing: const Icon(CupertinoIcons.chevron_right, size: 18),
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (BuildContext ctx) => page)),
        );
      },
    );
  }

  /// 📢 Inner Simple Navigation Tile Component Helper
  Widget _simpleTile(BuildContext context,
      {required IconData icon, required String title, required Widget page}) {
    return ListTile(
      tileColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: const Icon(CupertinoIcons.chevron_right, size: 18),
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (BuildContext ctx) => page)),
    );
  }

  /// ⚙️ Intake management tile
  Widget _registrationTile() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.person_crop_circle_badge_plus,
                size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Membership Intake",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                    _registrationOpen
                        ? "Open to public entries"
                        : "Intake locked",
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          CupertinoSwitch(
            value: _registrationOpen,
            activeColor: const Color(0xFF00674F),
            onChanged: (v) => _toggleRegistration(v),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminsProvider>();
    final admin = provider.currentAdmin;

    String initials = '';
    String displayRole = 'Admin';
    if (admin != null && admin.name.isNotEmpty) {
      final parts = admin.name.split(' ');
      initials = parts
          .take(2)
          .map((e) => e.isNotEmpty ? e[0] : '')
          .join()
          .toUpperCase();

      if (admin.isChair) displayRole = "Club Chair (Super-Admin)";
      if (admin.isMusicDirector) displayRole = "Music Director";
      if (admin.isTreasurer) displayRole = "Treasurer";
    }

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            automaticallyImplyLeading: false,
            title: const Text("Dashboard"),
            actions: [
              GestureDetector(
                onTap: () {
                  if (admin != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext ctx) =>
                              AdminAdminFormScreen(admin: admin)),
                    );
                  }
                },
                child: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(initials,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  // Unsubscribe in the background so logout never hangs
                  context
                      .read<PushNotificationProvider>()
                      .unsubscribeAdminFromPaymentAlerts();

                  await provider.signOut();
                  final box = Hive.box("AppPrefs");
                  await box.put("admin_logged_in", false);

                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                },
              ),
            ],
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Welcome👋",
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    admin?.name ?? "Administrator",
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      displayRole,
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  /// 🎵 MANAGE SONGS (Chair & Music Director Only)
                  if (admin != null &&
                      (admin.isChair || admin.isMusicDirector)) ...[
                    _statsTile(
                      context,
                      stream: FirebaseFirestore.instance
                          .collection("songs")
                          .snapshots(),
                      icon: CupertinoIcons.music_note_list,
                      title: "Manage Songs",
                      page: AdminSongsScreen(),
                      suffix: "songs",
                    ),
                    const SizedBox(height: 14),
                  ],

                  /// 📢 ANNOUNCEMENTS (Everyone has access)
                  _simpleTile(
                    context,
                    icon: CupertinoIcons.bell_fill,
                    title: "Announcements",
                    page: const AdminAnnouncementsScreen(),
                  ),
                  const SizedBox(height: 14),

                  /// 💳 PAYMENTS PANEL (Chair & Treasurer Only)
                  if (admin != null &&
                      (admin.isChair || admin.isTreasurer)) ...[
                    _statsTile(
                      context,
                      stream: FirebaseFirestore.instance
                          .collection("payment_dues")
                          .snapshots(),
                      icon: CupertinoIcons.creditcard_fill,
                      title: "Payments Panel",
                      page: const AdminPaymentsDashboard(),
                      suffix: "dues",
                    ),
                    const SizedBox(height: 14),
                  ],

                  /// 👥 REGISTERED MEMBERS (Chair Only)
                  if (admin != null && admin.isChair) ...[
                    _statsTile(
                      context,
                      stream: FirebaseFirestore.instance
                          .collection("members")
                          .snapshots(),
                      icon: CupertinoIcons.group_solid,
                      title: "Registered Members",
                      page: const AdminMembersScreen(),
                      suffix: "members",
                    ),
                    const SizedBox(height: 14),
                  ],

                  /// ⚙️ MANAGE ADMINS (Everyone can open list, controls inside protect fields)
                  _statsTile(
                    context,
                    stream: FirebaseFirestore.instance
                        .collection("admins")
                        .snapshots(),
                    icon: CupertinoIcons.settings_solid,
                    title: "Manage Admins",
                    page: const AdminManageAdminsScreen(),
                    suffix: "admins",
                  ),
                  const SizedBox(height: 14),

                  /// ─── Registration Open Gate Control (Chair Only) ───
                  if (admin != null && admin.isChair)
                    _loadingRegStatus
                        ? const Center(child: CircularProgressIndicator())
                        : _registrationTile(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
