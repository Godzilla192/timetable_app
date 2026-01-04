import '../db/app_db.dart';

class SemesterService {
  Future<List<Map<String, Object?>>> getSemesters() async {
    final db = await AppDb.instance.db;
    return db.query('semesters', orderBy: 'id DESC');
  }
}
