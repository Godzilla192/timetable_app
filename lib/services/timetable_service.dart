import '../db/app_db.dart';

class TimetableService {
  Future<List<Map<String, Object?>>> getItems({
    required String userId,
    required int semesterId,
    required int week,
  }) async {
    final db = await AppDb.instance.db;
    return db.query(
      'timetable_items',
      where: 'user_id=? AND semester_id=? AND week=?',
      whereArgs: [userId, semesterId, week],
      orderBy: 'day ASC, period ASC',
    );
  }

  Future<int> addItem(Map<String, Object?> data) async {
    final db = await AppDb.instance.db;
    return db.insert('timetable_items', data);
  }

  Future<void> updateItem(int id, Map<String, Object?> data) async {
    final db = await AppDb.instance.db;
    await db.update('timetable_items', data, where: 'id=?', whereArgs: [id]);
  }

  Future<void> deleteItem(int id) async {
    final db = await AppDb.instance.db;
    await db.delete('timetable_items', where: 'id=?', whereArgs: [id]);
  }
}
