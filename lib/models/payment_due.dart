import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentDue {
  final String id;
  final String title;
  final double amount;
  final String description;
  final DateTime dueDate;
  final DateTime createdAt;

  PaymentDue({
    required this.id,
    required this.title,
    required this.amount,
    required this.description,
    required this.dueDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PaymentDue.fromMap(Map<String, dynamic> map, String id) {
    return PaymentDue(
      id: id,
      title: map['title'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
      dueDate: map['dueDate'] != null
          ? (map['dueDate'] as Timestamp).toDate()
          : DateTime.now(),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
