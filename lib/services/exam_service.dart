import '../db/app_db.dart';

class ExamService {
  Future<List<Map<String, Object?>>> getExams({
    required String userId,
    required int semesterId,
  }) async {
    final db = await AppDb.instance.db;
    return db.query(
      'exams',
      where: 'user_id=? AND semester_id=?',
      whereArgs: [userId, semesterId],
      orderBy: 'date ASC, time ASC',
    );
  }

  Future<int> addExam(Map<String, Object?> data) async {
    final db = await AppDb.instance.db;
    return db.insert('exams', data);
  }

  Future<void> updateExam(int id, Map<String, Object?> data) async {
    final db = await AppDb.instance.db;
    await db.update('exams', data, where: 'id=?', whereArgs: [id]);
  }

  Future<void> deleteExam(int id) async {
    final db = await AppDb.instance.db;
    await db.delete('exams', where: 'id=?', whereArgs: [id]);
  }
}
