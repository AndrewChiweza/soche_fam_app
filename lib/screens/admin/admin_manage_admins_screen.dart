import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soche_fam/components/app_snack_bar.dart';
import '../../providers/admins_provider.dart';
import '../../models/admin_user.dart';
import 'admin_admin_form_screen.dart';

class AdminManageAdminsScreen extends StatelessWidget {
  const AdminManageAdminsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminsProvider>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text("Manage Admin Users"),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      floatingActionButton: provider.currentAdmin?.isChair == true
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdminAdminFormScreen()),
                );
              },
              backgroundColor: Theme.of(context).cardColor,
              child: const Icon(CupertinoIcons.person_add),
            )
          : null,
      body: StreamBuilder<List<AdminUser>>(
        stream: provider.streamAdmins(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text("Error fetching records: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00674F)));
          }

          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00674F)));
          }

          final admins = snapshot.data!;
          final current = provider.currentAdmin;

          if (current == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF00674F)),
                  SizedBox(height: 12),
                  Text("Verifying authorization profile..."),
                ],
              ),
            );
          }

          if (admins.isEmpty) {
            return const Center(
              child: Text(
                "No admins yet",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: admins.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final admin = admins[i];
              final canEdit = current.isChair || admin.id == current.id;

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Theme.of(context).cardColor,
                child: ListTile(
                  enabled: canEdit,
                  title: Text(
                    admin.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(admin.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: admin.isChair
                              ? Colors.amber.shade800
                              : admin.isMusicDirector
                                  ? Colors.blue.shade700
                                  : Colors.teal.shade700,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          admin.isChair
                              ? "Chair"
                              : admin.isMusicDirector
                                  ? "Music"
                                  : "Treasurer",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (current.isChair && admin.id != current.id) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(CupertinoIcons.trash,
                              color: Colors.redAccent),
                          onPressed: () async {
                            final confirmDelete = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text("Remove Admin"),
                                content: Text(
                                    "Are you sure you want to delete ${admin.name} from the administrator registry?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text("Delete",
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );

                            if (confirmDelete == true) {
                              final error = await context
                                  .read<AdminsProvider>()
                                  .deleteAdmin(admin.id);
                              if (error != null) {
                                AppSnackBar.showError(context, error);
                              } else {
                                AppSnackBar.showSuccess(context,
                                    "Admin profile removed successfully.");
                              }
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                  onTap: canEdit
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AdminAdminFormScreen(admin: admin),
                            ),
                          );
                        }
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
