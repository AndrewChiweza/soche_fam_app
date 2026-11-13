import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notification.dart';
import '../../providers/notifications_provider.dart';
// for consistent colors

class AnnouncementFormScreen extends StatefulWidget {
  final Announcement? announcement;

  const AnnouncementFormScreen({super.key, this.announcement});

  @override
  State<AnnouncementFormScreen> createState() => _AnnouncementFormScreenState();
}

class _AnnouncementFormScreenState extends State<AnnouncementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _messageCtrl;

  bool get isEditing => widget.announcement != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.announcement?.title ?? '');
    _messageCtrl =
        TextEditingController(text: widget.announcement?.message ?? '');
  }

  /// Helper to show success snackbar
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AnnouncementsProvider>();

    if (isEditing) {
      provider.editAnnouncement(
        Announcement(
          id: widget.announcement!.id,
          title: _titleCtrl.text,
          message: _messageCtrl.text,
          createdAt: widget.announcement!.createdAt,
        ),
      );
      _showSuccessSnackbar("Announcement updated successfully!");
    } else {
      provider.addAnnouncement(
        Announcement(
          id: "",
          title: _titleCtrl.text,
          message: _messageCtrl.text,
          createdAt: DateTime.now(),
        ),
      );
      _showSuccessSnackbar("Announcement added successfully!");
    }

    // Close the screen after a short delay so snackbar is visible
    Future.delayed(const Duration(milliseconds: 500), () {
      if (context.mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEditing ? "Edit Announcement" : "New Announcement"),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: "Title",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _messageCtrl,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: "Message",
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white),
                        onPressed: _save,
                        child: Text(isEditing ? "Save Changes" : "Create"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
