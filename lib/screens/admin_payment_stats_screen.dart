import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_due.dart';
import '../models/payment_transaction.dart';

class AdminPaymentStatsScreen extends StatelessWidget {
  final PaymentDue paymentDue;
  final double totalCollected;

  const AdminPaymentStatsScreen({
    super.key,
    required this.paymentDue,
    required this.totalCollected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${paymentDue.title} Audit Summary")),
      body: Column(
        children: [
          // Highlight Stats Summary Section Container Area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: const Color(0xFF00674F),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "TOTAL FUNDS RECOVERED",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "MWK ${totalCollected.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Target Single Premium: MWK ${paymentDue.amount.toStringAsFixed(0)}",
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),

          // Real-time Transactions Title Header Row
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Fulfillment Statement Ledger",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          // List details execution engine loop snapshot
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('payments_transactions')
                  .where('paymentDueId', isEqualTo: paymentDue.id)
                  // 📄 FIXED: Removed .orderBy() to resolve infinite loading spinner exception
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF00674F)));
                }

                if (!snapshot.hasData) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF00674F)));
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No transactions completed for this item yet.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                // 🔄 Alternative client-side sorting: Sort documents locally by payment date safely
                final List<PaymentTransaction> transactions = docs.map((doc) {
                  return PaymentTransaction.fromMap(
                      doc.data() as Map<String, dynamic>, doc.id);
                }).toList();

                transactions.sort((a, b) => b.paidAt.compareTo(a.paidAt));

                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.memberName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${tx.phoneNumber} • ${tx.operatorUsed}",
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "+MWK ${tx.amountPaid.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${tx.paidAt.day}/${tx.paidAt.month} ${tx.paidAt.hour}:${tx.paidAt.minute.toString().padLeft(2, '0')}",
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
