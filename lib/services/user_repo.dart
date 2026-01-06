import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRepo {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  String? get currentUid => _auth.currentUser?.uid;

  /// Tạo/ cập nhật hồ sơ user trong Firestore
  Future<void> upsertProfile({required String loginId}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).set({
      'loginId': loginId,
      'email': user.email,
      'updatedAt': FieldValue.serverTimestamp(),
      // createdAt chỉ set lần đầu (merge true vẫn ok)
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Lấy profile user (nếu cần)
  Future<Map<String, dynamic>?> getProfile(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    return snap.data();
  }
}
