import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:soche_fam/models/member.dart';
import 'package:soche_fam/services/firestore_service.dart';
import 'package:soche_fam/screens/registration_form_screen.dart';
import '../../theme/app_theme.dart'; // For consistent colors

class MemberDetailsScreen extends StatelessWidget {
  final Member member;

  const MemberDetailsScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(member.name),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.pencil),
            onPressed: () async {
              // Navigate to edit screen and wait for result
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => MemberRegistrationScreen(
                    existingMember: member,
                  ),
                ),
              );

              if (result == true) {
                _showSnackbar(context, "Member updated successfully!", true);
              }
            },
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.delete),
            onPressed: () => _confirmDelete(context, firestore),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  child: Icon(CupertinoIcons.person, size: 50),
                ),
              ),
              const SizedBox(height: 25),
              _infoTile("Name", member.name),
              _infoTile("Email", member.email),
              _infoTile("Baptised", member.baptised ? "Yes" : "No"),
              _infoTile("Local Church", member.localChurch),
              _infoTile("Purpose", member.purpose),
              _infoTile("Voice Type", member.voiceType),
              _infoTile(
                "Joined",
                "${member.joinedAt.year}-${member.joinedAt.month}-${member.joinedAt.day}",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontSize: 16)),
          const Divider(),
        ],
      ),
    );
  }

  void _showSnackbar(BuildContext context, String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmDelete(BuildContext context, FirestoreService firestore) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete ${member.name}?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await firestore.deleteMember(member.id);
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to list
                _showSnackbar(context, "Member deleted successfully!", true);
              } catch (e) {
                Navigator.pop(context); // Close dialog
                _showSnackbar(context, "Failed to delete member", false);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
