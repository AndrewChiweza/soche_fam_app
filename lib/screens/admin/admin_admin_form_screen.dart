import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/admin_user.dart';
import '../../providers/admins_provider.dart';

class AdminAdminFormScreen extends StatefulWidget {
  final AdminUser? admin;
  const AdminAdminFormScreen({super.key, this.admin});

  @override
  State<AdminAdminFormScreen> createState() => _AdminAdminFormScreenState();
}

class _AdminAdminFormScreenState extends State<AdminAdminFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  String assignedRole =
      'music_director'; // Defaults to standard operational access
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.admin != null) {
      isEditing = true;
      nameCtrl.text = widget.admin!.name;
      emailCtrl.text = widget.admin!.email;
      assignedRole = widget.admin!.role;
    }
  }

  void _showSnackBar(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AdminsProvider>();
    final current = provider.currentAdmin;

    if (current == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Only the Club Chair (Super Admin) or the owner of the profile can edit these fields
    final canEdit = current.isChair || widget.admin?.id == current.id;

    // Control password modification field visibility dynamically
    final showPasswordField = (!isEditing && current.isChair) ||
        (isEditing && (current.isChair || widget.admin?.id == current.id));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEditing ? "Edit Admin" : "Add Admin"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // NAME
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: "Full Name",
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                    enabled: canEdit,
                  ),
                  const SizedBox(height: 16),

                  // EMAIL
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                    enabled: canEdit,
                  ),
                  const SizedBox(height: 16),

                  // PASSWORD
                  if (showPasswordField)
                    TextFormField(
                      controller: passwordCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: isEditing
                            ? "New Password (leave empty to keep current)"
                            : "Password",
                        prefixIcon: const Icon(Icons.lock),
                      ),
                      validator: (v) {
                        if (!isEditing && (v == null || v.isEmpty)) {
                          return "Password required";
                        }
                        return null;
                      },
                    ),
                  if (showPasswordField) const SizedBox(height: 16),

                  // ROLE-BASED ACCESS CONTROL DROPDOWN
                  if (current.isChair)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: assignedRole,
                        decoration: const InputDecoration(
                          labelText: "Admin Operational Role",
                          border: InputBorder.none,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'chair',
                            child: Text('Club Chair (Super-Admin)'),
                          ),
                          DropdownMenuItem(
                            value: 'music_director',
                            child: Text('Music Director'),
                          ),
                          DropdownMenuItem(
                            value: 'treasurer',
                            child: Text('Treasurer'),
                          ),
                        ],
                        onChanged: (newRole) {
                          if (newRole != null) {
                            setState(() => assignedRole = newRole);
                          }
                        },
                      ),
                    ),

                  const SizedBox(height: 24),

                  // SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: canEdit
                          ? () async {
                              if (!_formKey.currentState!.validate()) return;

                              final admin = AdminUser(
                                id: widget.admin?.id ?? "",
                                name: nameCtrl.text.trim(),
                                email: emailCtrl.text.trim(),
                                role: assignedRole, // Updated field
                                createdAt:
                                    widget.admin?.createdAt ?? DateTime.now(),
                              );

                              final newPassword =
                                  passwordCtrl.text.trim().isEmpty
                                      ? null
                                      : passwordCtrl.text.trim();

                              String? result;

                              if (isEditing) {
                                result = await provider.updateAdmin(
                                  admin,
                                  newPassword: newPassword,
                                );
                              } else {
                                result = await provider.createAdmin(
                                  admin,
                                  passwordCtrl.text.trim(),
                                );
                              }

                              if (!mounted) return;

                              if (result == null) {
                                _showSnackBar(
                                  isEditing
                                      ? "Admin updated successfully"
                                      : "Admin created successfully",
                                  true,
                                );
                                Navigator.pop(context);
                              } else {
                                _showSnackBar(result, false);
                              }
                            }
                          : null,
                      child: Text(isEditing ? "Update Admin" : "Create Admin"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
