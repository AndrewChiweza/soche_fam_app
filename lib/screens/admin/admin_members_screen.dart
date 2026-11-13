import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:soche_fam/models/member.dart';
import 'package:soche_fam/services/firestore_service.dart';
import 'member_details_screen.dart';
import 'package:soche_fam/screens/registration_form_screen.dart';

class AdminMembersScreen extends StatefulWidget {
  const AdminMembersScreen({Key? key}) : super(key: key);

  @override
  State<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends State<AdminMembersScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left),
          onPressed: () {
            // This button navigates back to the previous screen
            Navigator.of(context).pop();
          },
          // Optional: customize the color
        ),
        title: const Text('Registered Members'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(CupertinoIcons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),
        ),
      ),

      // 🔥 Create New Member Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MemberRegistrationScreen()),
          );
        },
        child: const Icon(CupertinoIcons.add),
      ),

      body: StreamBuilder<List<Member>>(
        stream: _firestoreService.getMembers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No members registered yet.'));
          }

          final members = snapshot.data!
              .where((m) =>
                  m.name.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final member = members[i];

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MemberDetailsScreen(member: member),
                    ),
                  );
                },
                child: Card(
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 25,
                          child: Icon(CupertinoIcons.person, size: 30),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.name,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text('Email: ${member.email}'),
                              Text('Voice: ${member.voiceType}'),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
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
