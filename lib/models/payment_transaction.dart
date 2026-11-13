import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentTransaction {
  final String id;
  final String paymentDueId;
  final String memberName;
  final String phoneNumber;
  final double amountPaid;
  final String operatorUsed;
  final String transactionRef;
  final DateTime paidAt;

  PaymentTransaction({
    required this.id,
    required this.paymentDueId,
    required this.memberName,
    required this.phoneNumber,
    required this.amountPaid,
    required this.operatorUsed,
    required this.transactionRef,
    required this.paidAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'paymentDueId': paymentDueId,
      'memberName': memberName,
      'phoneNumber': phoneNumber,
      'amountPaid': amountPaid,
      'operatorUsed': operatorUsed,
      'transactionRef': transactionRef,
      'paidAt': Timestamp.fromDate(paidAt),
    };
  }

  factory PaymentTransaction.fromMap(Map<String, dynamic> map, String id) {
    return PaymentTransaction(
      id: id,
      paymentDueId: map['paymentDueId'] ?? '',
      memberName: map['memberName'] ?? 'Anonymous Member',
      phoneNumber: map['phoneNumber'] ?? '',
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
      operatorUsed: map['operatorUsed'] ?? 'Unknown',
      transactionRef: map['transactionRef'] ?? '',
      paidAt: map['paidAt'] != null
          ? (map['paidAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
