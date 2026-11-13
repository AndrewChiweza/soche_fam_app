import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/payment_due.dart';
import 'admin_payment_stats_screen.dart';

class AdminPaymentsDashboard extends StatelessWidget {
  const AdminPaymentsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payments Panel Management"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00674F),
        onPressed: () => _showCreatePaymentDialog(context),
        icon: const Icon(CupertinoIcons.add, color: Colors.white),
        label: const Text("New Contribution",
            style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('payment_dues')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error loading dues: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00674F)));
          }

          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00674F)));
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child:
                  Text("No contributions created yet. Tap '+' to create one."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final due = PaymentDue.fromMap(
                  docs[index].data() as Map<String, dynamic>, docs[index].id);

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('payments_transactions')
                    .where('paymentDueId', isEqualTo: due.id)
                    .where('status', isEqualTo: 'success')
                    .snapshots(),
                builder: (context, txSnapshot) {
                  double totalCollected = 0.0;
                  if (txSnapshot.hasData) {
                    for (var doc in txSnapshot.data!.docs) {
                      totalCollected += (doc['amountPaid'] as num).toDouble();
                    }
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(due.title,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                            "Collected: MWK ${totalCollected.toStringAsFixed(0)} / Target Per Member: MWK ${due.amount.toStringAsFixed(0)}"),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.graph_square_fill,
                              color: Color(0xFF00674F)),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(CupertinoIcons.trash,
                                color: Colors.redAccent, size: 22),
                            onPressed: () async {
                              final confirmRemove = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Remove Contribution?"),
                                  content: Text(
                                      "Are you sure you want to completely erase '${due.title}'? This action cannot be undone."),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
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

                              if (confirmRemove == true) {
                                await FirebaseFirestore.instance
                                    .collection('payment_dues')
                                    .doc(due.id)
                                    .delete();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Contribution targets removed successfully."),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminPaymentStatsScreen(
                              paymentDue: due,
                              totalCollected: totalCollected,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showCreatePaymentDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isPublishing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Create New Required Payment",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: titleCtrl,
                  enabled: !isPublishing,
                  decoration: const InputDecoration(
                      labelText: "Payment Title (e.g., Choir Uniforms)"),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  enabled: !isPublishing,
                  decoration:
                      const InputDecoration(labelText: "Description / Purpose"),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountCtrl,
                  enabled: !isPublishing,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: "Required Amount per Member (MWK)"),
                  validator: (v) => double.tryParse(v ?? '') == null
                      ? "Enter a valid amount"
                      : null,
                ),
                const SizedBox(height: 20),
                isPublishing
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                  color: Color(0xFF00674F)),
                              SizedBox(height: 8),
                              Text("Publishing & sending push alerts...",
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey)),
                            ],
                          ),
                        ),
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00674F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            setSheetState(() => isPublishing = true);
                            final title = titleCtrl.text.trim();
                            final desc = descCtrl.text.trim();
                            final amount = double.parse(amountCtrl.text.trim());
// 1. Save required contribution to payment_dues
                            await FirebaseFirestore.instance
                                .collection('payment_dues')
                                .add({
                              'title': title,
                              'description': desc,
                              'amount': amount,
                              'createdAt': Timestamp.now(),
                              'dueDate': Timestamp.fromDate(
                                  DateTime.now().add(const Duration(days: 30))),
                            });
// 2. Log into announcements feed for live bell badge & Notifications screen
                            await FirebaseFirestore.instance
                                .collection('announcements')
                                .add({
                              'title': 'New Contribution: $title',
                              'message':
                                  'Amount Required: MWK ${amount.toStringAsFixed(0)}. $desc',
                              'createdAt': Timestamp.now(),
                              'type': 'payment_due',
                            });
// 3. Send lock-screen push alert via Render (with 60s timeout for cold starts)
                            bool pushSent = false;
                            try {
                              final response = await http
                                  .post(
                                    Uri.parse('onrender.com'),
                                    headers: {
                                      'Content-Type': 'application/json'
                                    },
                                    body: jsonEncode({
                                      'title': 'New Contribution: $title',
                                      'body':
                                          'MWK ${amount.toStringAsFixed(0)} required — $desc',
                                      'type': 'payment_due',
                                    }),
                                  )
                                  .timeout(const Duration(seconds: 60));
                              if (response.statusCode == 200) {
                                pushSent = true;
                              } else {
                                debugPrint(
                                    'Render push error (${response.statusCode}): ${response.body}');
                              }
                            } catch (e) {
                              debugPrint('Broadcast notification error: $e');
                            }
                            if (!sheetContext.mounted) return;
                            Navigator.pop(sheetContext);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(pushSent
                                    ? 'Contribution published & push notification sent to all members!'
                                    : 'Contribution saved, but push notification timed out.'),
                                backgroundColor:
                                    pushSent ? Colors.green : Colors.orange,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: const Text("Publish Required Payment"),
                        ),
                      ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
