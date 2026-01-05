import '../db/app_db.dart';

class TimetableService {
  /// Lấy danh sách tiết theo học kỳ + tuần
  /// (Không lọc theo user)
  Future<List<Map<String, Object?>>> getItems({
    required int semesterId,
    required int week,
  }) async {
    final db = await AppDb.instance.db;
    return db.query(
      'timetable_items',
      where: 'semester_id=? AND week=?',
      whereArgs: [semesterId, week],
      orderBy: 'day ASC, period ASC',
    );
  }

  /// Trả về true nếu (semesterId, week, day, period) đã tồn tại bản ghi khác.
  /// - excludeId: dùng khi sửa, để bỏ qua chính bản ghi đang sửa.
  Future<bool> hasConflict({
    required int semesterId,
    required int week,
    required int day,
    required int period,
    int? excludeId,
  }) async {
    final db = await AppDb.instance.db;

    final where = excludeId == null
        ? 'semester_id=? AND week=? AND day=? AND period=?'
        : 'semester_id=? AND week=? AND day=? AND period=? AND id<>?';

    final args = excludeId == null
        ? <Object?>[semesterId, week, day, period]
        : <Object?>[semesterId, week, day, period, excludeId];

    final rows = await db.query(
      'timetable_items',
      columns: const ['id'],
      where: where,
      whereArgs: args,
      limit: 1,
    );

    return rows.isNotEmpty;
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
