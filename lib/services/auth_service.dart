import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/app_db.dart';

class AuthService {
  static const _kUserId = 'current_user_id';

  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUserId);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserId);
  }

  Future<Map<String, Object?>?> getUser(String userId) async {
    final db = await AppDb.instance.db;
    final rows =
    await db.query('users', where: 'id = ?', whereArgs: [userId], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<String?> login({required String id, required String password}) async {
    final db = await AppDb.instance.db;
    final rows =
    await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return 'ID không tồn tại';

    final user = rows.first;
    final salt = user['salt'] as String;
    final stored = user['password_hash'] as String;
    final hash = AppDb.hashPassword(password: password, salt: salt);

    if (hash != stored) return 'Sai mật khẩu';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserId, id);
    return null;
  }

  // ✅ Validate email
  bool isValidEmail(String email) {
    final x = email.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(x);
  }

  // ✅ Update Gmail
  Future<String?> updateEmail({required String userId, required String email}) async {
    final e = email.trim();
    if (e.isEmpty) return 'Email không được để trống';
    if (!isValidEmail(e)) return 'Email không hợp lệ';

    final db = await AppDb.instance.db;
    await db.update('users', {'email': e}, where: 'id=?', whereArgs: [userId]);
    return null;
  }

  Future<String?> updateFullName(
      {required String userId, required String fullName}) async {
    final db = await AppDb.instance.db;
    await db.update('users', {'full_name': fullName.trim()},
        where: 'id=?', whereArgs: [userId]);
    return null;
  }

  Future<String?> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final db = await AppDb.instance.db;
    final rows =
    await db.query('users', where: 'id=?', whereArgs: [userId], limit: 1);
    if (rows.isEmpty) return 'User không tồn tại';

    final user = rows.first;
    final salt = user['salt'] as String;
    final stored = user['password_hash'] as String;

    final currentHash = AppDb.hashPassword(password: currentPassword, salt: salt);
    if (currentHash != stored) return 'Mật khẩu hiện tại không đúng';

    final newHash = AppDb.hashPassword(password: newPassword, salt: salt);
    await db.update('users', {'password_hash': newHash},
        where: 'id=?', whereArgs: [userId]);
    return null;
  }

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

      final db = await AppDb.instance.db;
      await db.update('users', {'avatar_path': targetPath},
          where: 'id=?', whereArgs: [userId]);
      return null;
    } catch (e) {
      return 'Không thể lưu ảnh: $e';
    }
  }
}
