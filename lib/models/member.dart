import 'package:cloud_firestore/cloud_firestore.dart';

class Member {
  final String id;
  final String name;
  final String email;
  final String phone;
  final bool baptised;
  final String localChurch;
  final String purpose;
  final String voiceType;
  final DateTime joinedAt;

  Member({
    this.id = '',
    required this.name,
    required this.email,
    required this.phone,
    required this.baptised,
    required this.localChurch,
    required this.purpose,
    required this.voiceType,
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'baptised': baptised,
      'localChurch': localChurch,
      'purpose': purpose,
      'voiceType': voiceType,
      'joinedAt': Timestamp.fromDate(joinedAt), // FIXED
    };
  }

  factory Member.fromMap(Map<String, dynamic> map, String id) {
    return Member(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      baptised: map['baptised'] ?? false,
      localChurch: map['localChurch'] ?? '',
      purpose: map['purpose'] ?? '',
      voiceType: map['voiceType'] ?? '',
      joinedAt: (map['joinedAt'] as Timestamp).toDate(),
    );
  }
}
