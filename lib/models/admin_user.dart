import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUser {
  final String id; // SAME AS FirebaseAuth UID
  final String name;
  final String email;
  final String
      role; // Stores structural roles: 'chair', 'music_director', 'treasurer'
  final DateTime createdAt;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  /// Checkers to simplify reading permission state trees throughout your views
  bool get isChair => role == 'chair';
  bool get isMusicDirector => role == 'music_director';
  bool get isTreasurer => role == 'treasurer';

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AdminUser.fromMap(Map<String, dynamic> map, String id) {
    // 🔄 Fallback handling strategy for existing records
    String inferredRole = map['role'] ?? '';
    if (inferredRole.isEmpty) {
      final bool oldIsSuper = map['isSuperAdmin'] ?? false;
      inferredRole = oldIsSuper ? 'chair' : 'music_director';
    }

    return AdminUser(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: inferredRole,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
