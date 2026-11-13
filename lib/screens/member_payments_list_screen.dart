import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_due.dart';
import 'payment_checkout_screen.dart'; // Launches the PayChangu checkout view built previously

class MemberPaymentsListScreen extends StatelessWidget {
  const MemberPaymentsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Required Contributions"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('payment_dues')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text("No contribution targets created yet.",
                  style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final due = PaymentDue.fromMap(
                  docs[index].data() as Map<String, dynamic>, docs[index].id);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(due.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(due.description,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "MWK ${due.amount.toStringAsFixed(0)}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00674F),
                            fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      const Icon(CupertinoIcons.chevron_right,
                          size: 16, color: Colors.grey),
                    ],
                  ),
                  onTap: () {
                    // Route to Checkout.
                    // Pass active user metrics here if stored locally via your member profile cache system
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentCheckoutScreen(
                          payment: due,
                          currentMemberName:
                              "Choir Member", // Pass dynamic data if available
                          currentMemberEmail: "member@sochefam.com",
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
