import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soche_fam/theme/app_theme.dart';

import '../models/member.dart';
import '../services/firestore_service.dart';

class MemberRegistrationScreen extends StatefulWidget {
  final Member? existingMember;

  const MemberRegistrationScreen({super.key, this.existingMember});

  @override
  State<MemberRegistrationScreen> createState() =>
      _MemberRegistrationScreenState();
}

class _MemberRegistrationScreenState extends State<MemberRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestore = FirestoreService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _churchController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();

  final List<String> _voiceTypes = [
    'Soprano',
    'Alto / Baritone',
    'Tenor',
    'Bass',
  ];

  String? _selectedVoice;
  bool _baptised = false;
  bool isEditing = false;
  bool _isSaving = false;
  bool _registrationOpen = true; // ✅ default
  bool _loadingRegStatus = true; // Loading flag
  String? memberId;

  @override
  void initState() {
    super.initState();
    _loadRegistrationStatus(); // Load registration status first
    if (widget.existingMember != null) {
      isEditing = true;
      final m = widget.existingMember!;
      memberId = m.id;

      _nameController.text = m.name;
      _emailController.text = m.email;
      _phoneController.text = m.phone;
      _churchController.text = m.localChurch;
      _purposeController.text = m.purpose;
      _selectedVoice = m.voiceType;
      _baptised = m.baptised;
    }
  }

  Future<void> _loadRegistrationStatus() async {
    try {
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
    } catch (e) {
      setState(() => _loadingRegStatus = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _churchController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool success = true}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _saveMember() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_registrationOpen && !isEditing) {
      _showSnackBar(
        "Registration is currently closed. Please contact admin.",
        success: false,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final exists = await _firestore.emailExists(
        _emailController.text.trim(),
        excludeId: memberId,
      );

      if (exists) {
        _showSnackBar(
          "This email is already registered",
          success: false,
        );
        setState(() => _isSaving = false);
        return;
      }

      final member = Member(
        id: memberId ?? "",
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        baptised: _baptised,
        localChurch: _churchController.text.trim(),
        purpose: _purposeController.text.trim(),
        voiceType: _selectedVoice!,
        phone: _phoneController.text.trim(),
        joinedAt: widget.existingMember?.joinedAt ?? DateTime.now(),
      );

      if (isEditing) {
        await _firestore.updateMember(memberId!, member);
      } else {
        await _firestore.addMember(member);
      }

      if (!mounted) return;

      _showSnackBar(
        isEditing ? "Member updated successfully" : "Registration successful",
      );

      Navigator.pop(context);
    } catch (e) {
      _showSnackBar(
        "Registration failed. Please try again.",
        success: false,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Theme.of(context).cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingRegStatus) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 2,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            leading: IconButton(
              icon: const Icon(CupertinoIcons.chevron_left),
              onPressed: _isSaving ? null : () => Navigator.pop(context),
            ),
            title: Text(
              isEditing ? "Edit Member" : "Register as Member",
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(CupertinoIcons.refresh),
                onPressed: _loadingRegStatus
                    ? null
                    : () async {
                        setState(() => _loadingRegStatus = true);
                        await _loadRegistrationStatus();
                        _showSnackBar(
                          _registrationOpen
                              ? "Registration is OPEN now"
                              : "Registration is currently CLOSED",
                          success: _registrationOpen,
                        );
                      },
                tooltip: "Refresh Registration Status",
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: !_registrationOpen && !isEditing
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(CupertinoIcons.lock_fill,
                              size: 60, color: Colors.red),
                          SizedBox(height: 12),
                          Text(
                            "Registration is currently closed.\nPlease contact the admin.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.red),
                          ),
                        ],
                      ),
                    )
                  : Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _FormCard(
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  decoration: _input(
                                      "Full Name", CupertinoIcons.person),
                                  validator: (v) =>
                                      v!.isEmpty ? "Required" : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _emailController,
                                  decoration:
                                      _input("Email", CupertinoIcons.mail),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) =>
                                      v!.isEmpty ? "Required" : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _phoneController,
                                  decoration: _input(
                                      "Phone Number", CupertinoIcons.phone),
                                  keyboardType: TextInputType.phone,
                                  validator: (v) =>
                                      v!.isEmpty ? "Required" : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _FormCard(
                            child: Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  value: _selectedVoice,
                                  items: _voiceTypes
                                      .map(
                                        (voice) => DropdownMenuItem(
                                          value: voice,
                                          child: Text(voice),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: _isSaving
                                      ? null
                                      : (v) =>
                                          setState(() => _selectedVoice = v),
                                  decoration: _input(
                                    "Voice Type",
                                    CupertinoIcons.music_note,
                                  ),
                                  validator: (v) =>
                                      v == null ? "Select voice type" : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _churchController,
                                  decoration: _input(
                                      "Current Resident", CupertinoIcons.house),
                                  validator: (v) =>
                                      v!.isEmpty ? "Required" : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _purposeController,
                                  maxLines: 2,
                                  decoration: _input(
                                    "Why are you joining?",
                                    CupertinoIcons.flag,
                                  ),
                                  validator: (v) =>
                                      v!.isEmpty ? "Required" : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _FormCard(
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text("Are you Baptised?"),
                              value: _baptised,
                              onChanged: _isSaving
                                  ? null
                                  : (v) => setState(() => _baptised = v),
                            ),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveMember,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      isEditing ? "Update Member" : "Register",
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.white),
                                    ),
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

class _FormCard extends StatelessWidget {
  final Widget child;
  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
