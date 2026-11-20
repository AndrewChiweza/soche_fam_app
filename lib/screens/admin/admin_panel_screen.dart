import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:web/web.dart' as web;

import '../../providers/admins_provider.dart';
import '../../providers/push_notify_provider.dart';
import '../admin_payments_dashboard.dart';
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
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AdminsProvider>();
    if (!provider.isLoggedIn) {
      Future.microtask(() {
        if (!mounted) return;
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
    if (doc.exists && mounted) {
      setState(() {
        _registrationOpen = doc.data()?['registrationOpen'] ?? true;
      });
    } else if (mounted) {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('app')
          .set({'registrationOpen': true});
    }
  }

  Future<void> _toggleRegistration(bool value) async {
    setState(() => _registrationOpen = value);
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('app')
          .update({'registrationOpen': value});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
              value ? "Membership Intake Enabled" : "Membership Intake Locked",
              style: const TextStyle(color: Colors.white)),
          backgroundColor: value ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _registrationOpen = !value);
    }
  }

  /// 📊 Generates and downloads an Excel-ready CSV file for any Choir Module
  Future<void> _exportCsvReport(String category) async {
    setState(() => _isExporting = true);
    try {
      final db = FirebaseFirestore.instance;
      final List<List<String>> rows = [];
      String fileName = "soche_fam_${category.toLowerCase()}_report.csv";

      if (category == 'Payments') {
        rows.add([
          'Reference ID',
          'Member Name',
          'Phone Number',
          'Amount Paid (MWK)',
          'Operator',
          'Status',
          'Date'
        ]);
        final snap = await db
            .collection('payments_transactions')
            .orderBy('paidAt', descending: true)
            .get();
        for (var doc in snap.docs) {
          final d = doc.data();
          final date = (d['paidAt'] as Timestamp?)?.toDate().toString() ?? '';
          rows.add([
            d['transactionRef']?.toString() ?? doc.id,
            d['memberName']?.toString() ?? '',
            d['phoneNumber']?.toString() ?? '',
            d['amountPaid']?.toString() ?? '0',
            d['operatorUsed']?.toString() ?? '',
            d['status']?.toString() ?? '',
            date,
          ]);
        }
      } else if (category == 'Members') {
        rows.add(['Full Name', 'Voice Part', 'Phone', 'Email', 'Role/Status']);
        final snap = await db.collection('members').get();
        for (var doc in snap.docs) {
          final d = doc.data();
          rows.add([
            d['name']?.toString() ?? d['fullName']?.toString() ?? '',
            d['voicePart']?.toString() ?? d['part']?.toString() ?? '',
            d['phone']?.toString() ?? d['phoneNumber']?.toString() ?? '',
            d['email']?.toString() ?? '',
            d['status']?.toString() ?? 'Active',
          ]);
        }
      } else if (category == 'Songs') {
        rows.add(['Song Title', 'Category/Key', 'Composer/Notes']);
        final snap = await db.collection('songs').get();
        for (var doc in snap.docs) {
          final d = doc.data();
          rows.add([
            d['title']?.toString() ?? '',
            d['category']?.toString() ?? d['key']?.toString() ?? '',
            (d['lyrics']?.toString() ?? '').replaceAll('\n', ' '),
          ]);
        }
      } else if (category == 'Announcements') {
        rows.add(['Title', 'Message', 'Published Date']);
        final snap = await db
            .collection('announcements')
            .orderBy('createdAt', descending: true)
            .get();
        for (var doc in snap.docs) {
          final d = doc.data();
          final date =
              (d['createdAt'] as Timestamp?)?.toDate().toString() ?? '';
          rows.add([
            d['title']?.toString() ?? '',
            (d['message']?.toString() ?? '').replaceAll('\n', ' '),
            date,
          ]);
        }
      }

      // Build RFC-4180 compliant CSV string
      final csvContent = rows
          .map((row) => row
              .map((cell) => '"${cell.replaceAll('"', '""')}"')
              .join(','))
          .join('\n');

      if (kIsWeb) {
        final bytes = utf8.encode(csvContent);
        final blob = web.Blob(
          [bytes.toJS].toJS,
          web.BlobPropertyBag(type: 'text/csv;charset=utf-8;'),
        );
        final url = web.URL.createObjectURL(blob);
        final anchor = web.document.createElement('a') as web.HTMLAnchorElement
          ..href = url
          ..download = fileName;
        anchor.click();
        web.URL.revokeObjectURL(url);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$category report downloaded ($fileName)"),
          backgroundColor: const Color(0xFF00674F),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error generating report: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  /// KPI Metric Card Widget
  Widget _kpiCard({
    required String label,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              Icon(CupertinoIcons.arrow_up_right,
                  size: 16, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Management Action Card
  Widget _moduleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget destination,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => destination),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00674F).withValues(alpha: 0.1),
borderRadius: BorderRadius.circular(12),
),
child: Icon(icon, color: const Color(0xFF00674F), size: 24),
),
const SizedBox(width: 16),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(title,
style: const TextStyle(
fontWeight: FontWeight.bold, fontSize: 16)),
const SizedBox(height: 2),
Text(subtitle,
style:
TextStyle(color: Colors.grey.shade600, fontSize: 13)),
],
),
),
const Icon(CupertinoIcons.chevron_right,
size: 18, color: Colors.grey),
],
),
),
);
}
/// CSV Report Export Button Pill
Widget _reportButton(String label, IconData icon, String category) {
return OutlinedButton.icon(
style: OutlinedButton.styleFrom(
foregroundColor: const Color(0xFF00674F),
side: const BorderSide(color: Color(0xFF00674F)),
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
),
icon: Icon(icon, size: 18),
label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
onPressed: _isExporting ? null : () => _exportCsvReport(category),
);
}
@override
Widget build(BuildContext context) {
final provider = context.watch();
final admin = provider.currentAdmin;
final screenWidth = MediaQuery.of(context).size.width;
final bool isDesktop = screenWidth >= 850;
String initials = 'AD';
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
appBar: AppBar(
automaticallyImplyLeading: false,
elevation: 0,
title: const Row(
children: [
Icon(CupertinoIcons.music_note_2, color: Color(0xFF00674F)),
SizedBox(width: 10),
Text("SOCHE FAM — Admin Console",
style: TextStyle(fontWeight: FontWeight.bold)),
],
),
actions: [
if (isExporting)
const Padding(
padding: EdgeInsets.symmetric(horizontal: 16),
child: Center(
child: SizedBox(
width: 20,
height: 20,
child: CircularProgressIndicator(
strokeWidth: 2, color: Color(0xFF00674F)),
),
),
),
GestureDetector(
onTap: () {
if (admin != null) {
Navigator.push(
context,
MaterialPageRoute(
builder: () => AdminAdminFormScreen(admin: admin)),
);
}
},
child: CircleAvatar(
backgroundColor: const Color(0xFF00674F),
child: Text(initials,
style: const TextStyle(
color: Colors.white, fontWeight: FontWeight.bold)),
),
),
const SizedBox(width: 12),
IconButton(
tooltip: "Sign Out",
icon: const Icon(Icons.logout),
onPressed: () async {
context
.read()
.unsubscribeAdminFromPaymentAlerts();
await provider.signOut();
final box = Hive.box("AppPrefs");
await box.put("admin_logged_in", false);
if (!context.mounted) return;
Navigator.pushReplacementNamed(context, '/admin-sign-in');
},
),
const SizedBox(width: 12),
],
),
body: SingleChildScrollView(
physics: const BouncingScrollPhysics(),
padding: EdgeInsets.symmetric(
horizontal: isDesktop ? 32 : 16,
vertical: 24,
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// Header Welcome Banner
Container(
padding: const EdgeInsets.all(24),
decoration: BoxDecoration(
gradient: const LinearGradient(
colors: [Color(0xFF00674F), Color(0xFF004D3B)],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
borderRadius: BorderRadius.circular(20),
),
child: Flex(
direction: isDesktop ? Axis.horizontal : Axis.vertical,
mainAxisAlignment: MainAxisAlignment.spaceBetween,
crossAxisAlignment: isDesktop
? CrossAxisAlignment.center
: CrossAxisAlignment.start,
children: [
Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
"Welcome back, ${admin?.name ?? 'Administrator'}",
style: const TextStyle(
color: Colors.white,
fontSize: 22,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 6),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 12, vertical: 4),
decoration: BoxDecoration(
color: Colors.white.withValues(alpha: 0.18),
borderRadius: BorderRadius.circular(20),
),
child: Text(
displayRole,
style: const TextStyle(
color: Colors.white,
fontSize: 13,
fontWeight: FontWeight.w500),
),
),
],
),
if (!isDesktop) const SizedBox(height: 16),
// Membership Intake Quick Switch
Container(
padding:
const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
decoration: BoxDecoration(
color: Colors.white.withValues(alpha: 0.12),
borderRadius: BorderRadius.circular(14),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
const Icon(CupertinoIcons.person_badge_plus,
color: Colors.white, size: 20),
const SizedBox(width: 10),
Text(
_registrationOpen
? "Intake: Open"
: "Intake: Locked",
style: const TextStyle(
color: Colors.white, fontWeight: FontWeight.w600),
),
const SizedBox(width: 10),
CupertinoSwitch(
value: _registrationOpen,
activeTrackColor: Colors.greenAccent.shade700,
onChanged: _toggleRegistration,
),
],
),
),
],
),
),
const SizedBox(height: 28),
const Text(
"Live Choir KPIs & Analytics",
style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),
const SizedBox(height: 14),
// Responsive 4-Column (Desktop) / 2-Column (Mobile) KPI Grid
StreamBuilder(
stream: FirebaseFirestore.instance
.collection('payments_transactions')
.where('status', isEqualTo: 'success')
.snapshots(),
builder: (context, txSnap) {
double totalRevenue = 0;
int txCount = 0;
if (txSnap.hasData) {
txCount = txSnap.data!.docs.length;
for (var doc in txSnap.data!.docs) {
totalRevenue += (doc['amountPaid'] as num).toDouble();
}
}
return StreamBuilder(
stream: FirebaseFirestore.instance
.collection('members')
.snapshots(),
builder: (context, memSnap) {
final memberCount = memSnap.data?.docs.length ?? 0;
return StreamBuilder(
stream: FirebaseFirestore.instance
.collection('songs')
.snapshots(),
builder: (context, songSnap) {
final songCount = songSnap.data?.docs.length ?? 0;
return StreamBuilder(
stream: FirebaseFirestore.instance
.collection('announcements')
.snapshots(),
builder: (context, annSnap) {
final annCount = annSnap.data?.docs.length ?? 0;
return GridView.count(
crossAxisCount: isDesktop ? 4 : 2,
shrinkWrap: true,
physics: const NeverScrollableScrollPhysics(),
crossAxisSpacing: 16,
mainAxisSpacing: 16,
childAspectRatio: isDesktop ? 1.35 : 1.05,
children: [
_kpiCard(
label: "Total Contributions",
value: "MWK ${totalRevenue.toStringAsFixed(0)}",
subtitle: "$txCount verified payments",
icon: CupertinoIcons.money_dollar_circle_fill,
accentColor: const Color(0xFF00674F),
),
_kpiCard(
label: "Registered Members",
value: memberCount.toString(),
subtitle: "Active choir roster",
icon: CupertinoIcons.person_3_fill,
accentColor: Colors.blue.shade700,
),
_kpiCard(
label: "Choir Repertoire",
value: songCount.toString(),
subtitle: "Hymns & songs stored",
icon: CupertinoIcons.music_albums_fill,
accentColor: Colors.purple.shade700,
),
_kpiCard(
label: "Announcements",
value: annCount.toString(),
subtitle: "Broadcasts published",
icon: CupertinoIcons.bell_fill,
accentColor: Colors.orange.shade800,
),
],
);
},
);
},
);
},
);
},
),
const SizedBox(height: 28),
// One-Click CSV Report Generation Bar
Container(
width: double.infinity,
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(
color: Theme.of(context).cardColor,
borderRadius: BorderRadius.circular(18),
border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Row(
children: [
Icon(CupertinoIcons.doc_chart_fill,
color: Color(0xFF00674F)),
SizedBox(width: 8),
Text(
"Generate & Export Choir Reports (CSV / Excel)",
style: TextStyle(
fontSize: 16, fontWeight: FontWeight.bold),
),
],
),
const SizedBox(height: 6),
Text(
"Download full real-time spreadsheets for treasurer audits, attendance, or songbook backups.",
style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
),
const SizedBox(height: 16),
Wrap(
spacing: 12,
runSpacing: 12,
children: [
_reportButton("Payments Ledger",
CupertinoIcons.creditcard, "Payments"),
_reportButton("Members Roster",
CupertinoIcons.person_2, "Members"),
_reportButton("Songbook Archive",
CupertinoIcons.music_note, "Songs"),
_reportButton("Announcements Log",
CupertinoIcons.speaker_2, "Announcements"),
],
),
],
),
),
const SizedBox(height: 28),
const Text(
"Management Modules",
style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),
const SizedBox(height: 14),
// Responsive 2-Column (Desktop) / 1-Column (Mobile) Management Grid
GridView.count(
crossAxisCount: isDesktop ? 2 : 1,
shrinkWrap: true,
physics: const NeverScrollableScrollPhysics(),
crossAxisSpacing: 16,
mainAxisSpacing: 14,
childAspectRatio: isDesktop ? 4.2 : 3.4,
children: [
_moduleCard(
icon: CupertinoIcons.music_note_list,
title: "Manage Songs",
subtitle: "Add, edit, or organize choir lyrics",
destination: const AdminSongsScreen(),
),
_moduleCard(
icon: CupertinoIcons.bell_circle_fill,
title: "Announcements",
subtitle: "Send push broadcasts & notices to members",
destination: const AdminAnnouncementsScreen(),
),
_moduleCard(
icon: CupertinoIcons.creditcard_fill,
title: "Payments & Contributions",
subtitle: "Track member dues & PayChangu transactions",
destination: const AdminPaymentsDashboard(),
),
_moduleCard(
icon: CupertinoIcons.person_3_fill,
title: "Registered Members",
subtitle: "View voice parts, contacts, & choir profiles",
destination: const AdminMembersScreen(),
),
if (admin?.isChair == true)
_moduleCard(
icon: CupertinoIcons.shield_lefthalf_fill,
title: "Manage Admins",
subtitle: "Assign Treasurer & Music Director roles",
destination: const AdminManageAdminsScreen(),
),
],
),
const SizedBox(height: 40),
],
),
),
);
}
}