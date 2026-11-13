import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_user.dart';

class AdminsProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AdminUser? _currentAdmin;
  AdminUser? get currentAdmin => _currentAdmin;
  bool get isLoggedIn => _currentAdmin != null;

  /// Helper getters to verify RBAC access levels easily across your UI layout screens
  bool get isChair => _currentAdmin?.role == 'chair';
  bool get isMusicDirector => _currentAdmin?.role == 'music_director';
  bool get isTreasurer => _currentAdmin?.role == 'treasurer';

  /// Reactive constructor to automatically restore active sessions on app wake-up
  AdminsProvider() {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        await signInWithUid(user.uid);
      } else {
        _currentAdmin = null;
        notifyListeners();
      }
    });
  }

  /// ====================================================
  /// SESSION RESTORATION BY UID (Fixes anonymous dashboard)
  /// ====================================================
  Future<void> signInWithUid(String uid) async {
    try {
      final doc = await _db.collection('admins').doc(uid).get();
      if (doc.exists) {
        _currentAdmin = AdminUser.fromMap(doc.data()!, doc.id);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Background session restoration error: $e");
    }
  }

  /// =========================
  /// SIGN IN
  /// =========================
  Future<String?> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = result.user!.uid;
      final doc = await _db.collection('admins').doc(uid).get();

      if (!doc.exists) {
        await _auth.signOut();
        return "No admin profile found for this account.";
      }

      _currentAdmin = AdminUser.fromMap(doc.data()!, doc.id);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// =========================
  /// SIGN OUT
  /// =========================
  Future<void> signOut() async {
    await _auth.signOut();
    _currentAdmin = null;
    notifyListeners();
  }

  /// =========================
  /// STREAM ADMINS
  /// =========================
  Stream<List<AdminUser>> streamAdmins() {
    return _db.collection("admins").snapshots().map(
          (s) => s.docs.map((d) => AdminUser.fromMap(d.data(), d.id)).toList(),
        );
  }

  /// =========================
  /// CREATE ADMIN (With RBAC Role integration)
  /// =========================
  Future<String?> createAdmin(AdminUser admin, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: admin.email,
        password: password,
      );

      final uid = cred.user!.uid;

      await _db.collection("admins").doc(uid).set({
        'name': admin.name,
        'email': admin.email,
        'role': admin.role,
        'createdAt': admin.createdAt,
      });

      return null; // ✅ success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// =========================
  /// UPDATE ADMIN
  /// =========================
  Future<String?> updateAdmin(
    AdminUser admin, {
    String? newPassword,
  }) async {
    try {
      // Update Firestore profile mapping fields
      await _db.collection("admins").doc(admin.id).update({
        'name': admin.name,
        'email': admin.email,
        'role': admin.role,
      });

      if (newPassword != null && newPassword.isNotEmpty) {
        final currentUser = _auth.currentUser;

        /// CASE 1: Updating OWN password profile credentials
        if (currentUser != null && currentUser.uid == admin.id) {
          await currentUser.updatePassword(newPassword);
          await currentUser.reload(); // 🔥 IMPORTANT
        }

        /// CASE 2: Super admin (Chair) editing ANOTHER administrator
        else if (isChair) {
          await _auth.sendPasswordResetEmail(email: admin.email);
        }
      }

      // If the current admin modified their own info, refresh current state tracking values
      if (_currentAdmin?.id == admin.id) {
        final doc = await _db.collection('admins').doc(admin.id).get();
        if (doc.exists) {
          _currentAdmin = AdminUser.fromMap(doc.data()!, doc.id);
          notifyListeners();
        }
      }

      return null; // ✅ success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return "Please log in again to change your password.";
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// =========================
  /// DELETE ADMIN
  /// =========================
  Future<String?> deleteAdmin(String id) async {
    try {
      await _db.collection("admins").doc(id).delete();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// =========================
  /// RESET PASSWORD & FORGOT PASSWORD LINK ALIAS
  /// =========================
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// This satisfies the explicit naming hook used in your Sign-In dashboard interface screen setup
  Future<String?> sendForgotPasswordEmail(String email) async {
    return await resetPassword(email);
  }
}
