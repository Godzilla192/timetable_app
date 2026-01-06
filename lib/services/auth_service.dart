import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  /// Giữ UI cũ: ID đăng nhập -> email giả để dùng Firebase Email/Password
  /// Ví dụ id=123456 -> 123456@timetable-app-2026.local
  String _emailFromId(String id) => '${id.trim()}@timetable-app-2026.local';

  /// Trả về uid Firebase (hoặc null nếu chưa login)
  Future<String?> getCurrentUserId() async {
    return _auth.currentUser?.uid;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Lấy user profile từ Firestore
  /// Trả về map giống kiểu cũ để UI dùng.
  Future<Map<String, Object?>?> getUser(String userId) async {
    final snap = await _fs.collection('users').doc(userId).get();
    final data = snap.data();
    if (data == null) return null;

    // Ép kiểu về Map<String, Object?> cho giống code cũ
    return data.map((k, v) => MapEntry(k, v as Object?));
  }

  /// Login theo UI cũ (id + password).
  /// - Nếu tài khoản chưa tồn tại -> tự tạo (giữ trải nghiệm demo)
  /// - Thành công -> ghi/merge profile vào Firestore users/{uid}
  Future<String?> login({required String id, required String password}) async {
    final loginId = id.trim();
    final pw = password;

    if (loginId.isEmpty || pw.isEmpty) return 'Vui lòng nhập ID và mật khẩu';

    try {
      final email = _emailFromId(loginId);

      UserCredential cred;
      try {
        cred = await _auth.signInWithEmailAndPassword(email: email, password: pw);
      } on FirebaseAuthException catch (e) {
        // Nếu chưa có thì tạo mới
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          cred = await _auth.createUserWithEmailAndPassword(email: email, password: pw);
        } else if (e.code == 'wrong-password') {
          return 'Sai mật khẩu';
        } else {
          return _friendlyAuthError(e);
        }
      }

      final user = cred.user;
      if (user == null) return 'Không lấy được thông tin người dùng';

      await _fs.collection('users').doc(user.uid).set({
        'loginId': loginId,
        'email': user.email,
        'full_name': null,
        'avatar_path': null,
        'updatedAt': FieldValue.serverTimestamp(),
        // merge để không ghi đè dữ liệu cũ
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return null; // OK
    } on FirebaseAuthException catch (e) {
      return _friendlyAuthError(e);
    } catch (e) {
      return 'Lỗi: $e';
    }
  }

  // ✅ Validate email
  bool isValidEmail(String email) {
    final x = email.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(x);
  }

  // ✅ Update email: cập nhật cả FirebaseAuth email + Firestore profile
  // ✅ Update email: cập nhật cả FirebaseAuth email + Firestore profile
  Future<String?> updateEmail({required String userId, required String email}) async {
    final e = email.trim();
    if (e.isEmpty) return 'Email không được để trống';
    if (!isValidEmail(e)) return 'Email không hợp lệ';

    try {
      final current = _auth.currentUser;
      if (current == null || current.uid != userId) return 'Chưa đăng nhập';

      // FirebaseAuth bản mới: yêu cầu xác minh trước khi đổi email
      await current.verifyBeforeUpdateEmail(e);

      // Lưu vào Firestore (để hiển thị ngay trong app)
      await _fs.collection('users').doc(userId).set({
        'email': e,
        'updatedAt': FieldValue.serverTimestamp(),
        'email_pending_verify': true,
      }, SetOptions(merge: true));

      return 'Đã gửi email xác minh. Hãy kiểm tra hộp thư để hoàn tất đổi email.';
    } on FirebaseAuthException catch (err) {
      if (err.code == 'requires-recent-login') {
        return 'Vui lòng đăng nhập lại rồi thử cập nhật email.';
      }
      return _friendlyAuthError(err);
    } catch (e) {
      return 'Lỗi: $e';
    }
  }


  Future<String?> updateFullName({required String userId, required String fullName}) async {
    final name = fullName.trim();
    try {
      await _fs.collection('users').doc(userId).set({
        'full_name': name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return null;
    } catch (e) {
      return 'Lỗi: $e';
    }
  }

  /// Đổi mật khẩu Firebase:
  /// - re-auth bằng email/password hiện tại
  /// - rồi updatePassword
  Future<String?> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final current = _auth.currentUser;
      if (current == null || current.uid != userId) return 'Chưa đăng nhập';

      final email = current.email;
      if (email == null) return 'Tài khoản không có email';

      // Re-auth
      final cred = EmailAuthProvider.credential(email: email, password: currentPassword);
      await current.reauthenticateWithCredential(cred);

      // Update
      await current.updatePassword(newPassword);

      await _fs.collection('users').doc(userId).set({
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Mật khẩu hiện tại không đúng';
      }
      if (e.code == 'weak-password') {
        return 'Mật khẩu mới quá yếu (tối thiểu 6 ký tự).';
      }
      if (e.code == 'requires-recent-login') {
        return 'Vui lòng đăng nhập lại rồi đổi mật khẩu.';
      }
      return _friendlyAuthError(e);
    } catch (e) {
      return 'Lỗi: $e';
    }
  }

  /// Avatar:
  /// - vẫn copy file về thư mục app như trước
  /// - nhưng lưu đường dẫn vào Firestore users/{uid}.avatar_path
  /// (Chưa dùng Firebase Storage để khỏi thêm package)
  Future<String?> updateAvatarFromPickedPath({
    required String userId,
    required String pickedImagePath,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final ext = p.extension(pickedImagePath);
      final fileName = 'avatar_$userId$ext';
      final targetPath = p.join(dir.path, fileName);

      final src = File(pickedImagePath);
      await src.copy(targetPath);

      await _fs.collection('users').doc(userId).set({
        'avatar_path': targetPath,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return null;
    } catch (e) {
      return 'Không thể lưu ảnh: $e';
    }
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('FirebaseAuthException: ${e.code} ${e.message}');
    }
    switch (e.code) {
      case 'network-request-failed':
        return 'Lỗi mạng. Kiểm tra Internet.';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'user-disabled':
        return 'Tài khoản đã bị khóa.';
      default:
        return e.message ?? 'Đăng nhập thất bại.';
    }
  }
}
