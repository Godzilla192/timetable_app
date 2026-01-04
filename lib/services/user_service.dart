import '../db/app_db.dart';

class UserService {
  Future<Map<String, Object?>?> getUser(String userId) async {
    final db = await AppDb.instance.db;
    final rows = await db.query(
      'users',
      where: 'id=?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> updateEmail({
    required String userId,
    required String email,
  }) async {
    final db = await AppDb.instance.db;
    await db.update(
      'users',
      {'email': email},
      where: 'id=?',
      whereArgs: [userId],
    );
  }
}
