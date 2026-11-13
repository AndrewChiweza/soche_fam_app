import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member.dart';
import '../models/song.dart';
import '../models/notification.dart';
import '../models/admin_user.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==========================
  // MEMBERS CRUD
  // ==========================

  Future<void> addMember(Member member) async {
    await _db.collection("members").add(member.toMap());
  }

  /// ✅ CHECK IF EMAIL ALREADY EXISTS (PREVENT DUPLICATES)
  Future<bool> emailExists(String email, {String? excludeId}) async {
    final query =
        await _db.collection("members").where("email", isEqualTo: email).get();

    if (query.docs.isEmpty) return false;

    // When editing, ignore the current member
    if (excludeId != null) {
      return query.docs.any((doc) => doc.id != excludeId);
    }

    return true;
  }

  Stream<List<Member>> getMembers() {
    return _db
        .collection("members")
        .orderBy("joinedAt", descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Member.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> updateMember(String id, Member member) async {
    await _db.collection("members").doc(id).update(member.toMap());
  }

  Future<void> deleteMember(String id) async {
    await _db.collection("members").doc(id).delete();
  }

  // ==========================
  // SONGS CRUD
  // ==========================

  Future<void> addSong(Song song) async {
    final doc = _db.collection("songs").doc();

    final songWithId = Song(
      id: doc.id,
      title: song.title,
      lyrics: song.lyrics,
      isFavorite: song.isFavorite,
      createdAt: DateTime.now(),
    );

    await doc.set(songWithId.toMap());
  }

  Future<void> updateSong(String id, Song song) async {
    await _db.collection("songs").doc(id).update(song.toMap());
  }

  Future<void> deleteSong(String id) async {
    await _db.collection("songs").doc(id).delete();
  }

  Stream<List<Song>> getSongs() {
    return _db
        .collection("songs")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => Song.fromMap(doc.data(), doc.id)).toList(),
        );
  }

  // ==========================
  // ANNOUNCEMENTS CRUD
  // ==========================

  Future<void> createAnnouncement(Announcement ann) async {
    await _db.collection('announcements').add(ann.toMap());
  }

  Future<void> updateAnnouncement(Announcement ann) async {
    await _db.collection('announcements').doc(ann.id).update(ann.toMap());
  }

  Future<void> deleteAnnouncement(String id) async {
    await _db.collection('announcements').doc(id).delete();
  }

  Stream<List<Announcement>> getAnnouncements() {
    return _db
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Announcement.fromMap(d.data(), d.id))
            .toList());
  }

  // ==========================
  // ADMINS CRUD
  // ==========================

  Future<void> createAdmin(AdminUser admin) async {
    await _db.collection("admins").add(admin.toMap());
  }

  Stream<List<AdminUser>> getAdmins() {
    return _db.collection("admins").snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => AdminUser.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> updateAdmin(String id, AdminUser admin) async {
    await _db.collection("admins").doc(id).update(admin.toMap());
  }

  Future<void> deleteAdmin(String id) async {
    await _db.collection("admins").doc(id).delete();
  }

  /// REGISTRATION STATUS STREAM
  Stream<bool> registrationOpenStream() {
    return FirebaseFirestore.instance
        .collection('settings')
        .doc('app')
        .snapshots()
        .map((doc) => doc.data()?['registrationOpen'] ?? true);
  }

  /// UPDATE REGISTRATION STATUS (ADMIN)
  Future<void> setRegistrationOpen(bool value) async {
    await FirebaseFirestore.instance
        .collection('settings')
        .doc('app')
        .set({'registrationOpen': value}, SetOptions(merge: true));
  }
}
