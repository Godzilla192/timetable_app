import '../db/app_db.dart';

class ChatService {
  Future<int> _getOrCreateSession(String userId) async {
    final db = await AppDb.instance.db;

    final rows = await db.query(
      'chat_sessions',
      where: 'user_id=?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (rows.isNotEmpty) {
      return rows.first['id'] as int;
    }

    final id = await db.insert('chat_sessions', {
      'user_id': userId,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    return id;
  }

  Future<List<Map<String, Object?>>> getMessages(String userId) async {
    final db = await AppDb.instance.db;
    final sessionId = await _getOrCreateSession(userId);

    return db.query(
      'chat_messages',
      where: 'session_id=?',
      whereArgs: [sessionId],
      orderBy: 'created_at ASC',
    );
  }

  Future<void> sendUserMessage({
    required String userId,
    required String text,
  }) async {
    final db = await AppDb.instance.db;
    final sessionId = await _getOrCreateSession(userId);

    await db.insert('chat_messages', {
      'session_id': sessionId,
      'sender': 'user',
      'text': text,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });

    final reply = await _makeBotReply(userId: userId, question: text);

    await db.insert('chat_messages', {
      'session_id': sessionId,
      'sender': 'bot',
      'text': reply,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ===================== BOT REPLY =====================

  Future<String> _makeBotReply({
    required String userId,
    required String question,
  }) async {
    final q = _norm(question);

    // 1) Tuần trước học môn gì?
    if (_matchAny(q, [
      'tuan truoc hoc mon gi',
      'tuan truoc hoc gi',
      'tuan truoc hoc mon nao',
      'hoc tuan truoc',
    ])) {
      final r = await _answerLastWeekSubjects(userId);
      if (r != null) return r;
    }

    // 2) Hôm qua có bài tập gì?
    if (_matchAny(q, [
      'hom qua co bai tap gi',
      'hom qua bai tap gi',
      'hom qua co bai gi',
      'bai tap hom qua',
    ])) {
      final r = await _answerYesterdayHomework(userId);
      if (r != null) return r;
    }

    // 3) Bài kiểm tra lần trước mấy điểm?
    if (_matchAny(q, [
      'bai kiem tra lan truoc may diem',
      'lan truoc may diem',
      'kiem tra lan truoc may diem',
      'diem bai kiem tra lan truoc',
      'diem lan truoc',
    ])) {
      final r = await _answerLastTestScore(userId);
      if (r != null) return r;
    }

    // 4) fallback: FAQ như cũ
    return _faqFallback(q);
  }

  // ===================== Q&A HANDLERS =====================

  Future<int?> _getCurrentSemesterId() async {
    final db = await AppDb.instance.db;
    final rows = await db.query('semesters', orderBy: 'id DESC', limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['id'] as int;
  }

  /// Lấy tuần hiện tại theo start_date của semester (nếu có), fallback = 1
  Future<int> _getCurrentWeekInSemester(int semesterId) async {
    final db = await AppDb.instance.db;
    final sem = await db.query('semesters', where: 'id=?', whereArgs: [semesterId], limit: 1);
    if (sem.isEmpty) return 1;

    final start = sem.first['start_date'] as String?;
    if (start == null || start.isEmpty) return 1;

    final startDate = DateTime.tryParse(start);
    if (startDate == null) return 1;

    final now = DateTime.now();
    final diffDays = now.difference(startDate).inDays;
    final week = (diffDays ~/ 7) + 1;
    return week < 1 ? 1 : week;
  }

  Future<String?> _answerLastWeekSubjects(String userId) async {
    final db = await AppDb.instance.db;
    final semesterId = await _getCurrentSemesterId();
    if (semesterId == null) return null;

    final currentWeek = await _getCurrentWeekInSemester(semesterId);
    final lastWeek = currentWeek - 1;
    if (lastWeek < 1) {
      return '[Học tập]\nChưa có “tuần trước” để thống kê (hiện đang là tuần 1).';
    }

    final rows = await db.query(
      'timetable_items',
      columns: ['subject', 'day', 'period', 'room', 'teacher'],
      where: 'user_id=? AND semester_id=? AND week=?',
      whereArgs: [userId, semesterId, lastWeek],
      orderBy: 'day ASC, period ASC',
    );

    if (rows.isEmpty) {
      return '[Học tập]\nMình không thấy dữ liệu TKB của tuần $lastWeek trong học kỳ hiện tại.';
    }

    // gom môn + lịch tóm tắt
    final subjects = <String>{};
    final lines = <String>[];

    for (final r in rows) {
      final sub = (r['subject'] as String?) ?? '';
      if (sub.isEmpty) continue;
      subjects.add(sub);

      final day = r['day'] as int? ?? 0;
      final period = r['period'] as int? ?? 0;
      final room = (r['room'] as String?) ?? '';
      lines.add('- ${_dayName(day)} • Tiết $period • $sub${room.isNotEmpty ? ' • $room' : ''}');
    }

    final listSubjects = subjects.toList()..sort();
    return '[Học tập]\nTuần $lastWeek bạn học ${listSubjects.length} môn:\n'
        '${listSubjects.map((e) => '• $e').join('\n')}\n\n'
        'Chi tiết:\n${lines.join('\n')}';
  }

  Future<String?> _answerYesterdayHomework(String userId) async {
    final db = await AppDb.instance.db;
    final semesterId = await _getCurrentSemesterId();
    if (semesterId == null) return null;

    final y = DateTime.now().subtract(const Duration(days: 1));
    final yStr = _fmtDate(y);

    final rows = await db.query(
      'homework',
      columns: ['subject', 'content', 'date'],
      where: 'user_id=? AND semester_id=? AND date=?',
      whereArgs: [userId, semesterId, yStr],
      orderBy: 'id DESC',
    );

    if (rows.isEmpty) {
      return '[Bài tập]\nHôm qua ($yStr) mình không thấy bài tập nào trong dữ liệu.';
    }

    final lines = rows.map((r) {
      final sub = (r['subject'] as String?) ?? '';
      final content = (r['content'] as String?) ?? '';
      return '- $sub: $content';
    }).join('\n');

    return '[Bài tập]\nBài tập hôm qua ($yStr):\n$lines';
  }

  Future<String?> _answerLastTestScore(String userId) async {
    final db = await AppDb.instance.db;
    final semesterId = await _getCurrentSemesterId();
    if (semesterId == null) return null;

    final rows = await db.query(
      'tests',
      where: 'user_id=? AND semester_id=?',
      whereArgs: [userId, semesterId],
      orderBy: 'date DESC, id DESC',
      limit: 1,
    );

    if (rows.isEmpty) {
      return '[Kiểm tra]\nMình chưa thấy bạn nhập dữ liệu kiểm tra/điểm.';
    }

    final r = rows.first;
    final date = (r['date'] as String?) ?? '';
    final subject = (r['subject'] as String?) ?? '';
    final title = (r['title'] as String?) ?? 'Bài kiểm tra';
    final score = r['score'];
    final note = (r['note'] as String?) ?? '';

    return '[Kiểm tra]\nLần kiểm tra gần nhất:\n'
        '- Môn: $subject\n'
        '- Loại: $title\n'
        '- Ngày: $date\n'
        '- Điểm: $score\n'
        '${note.isNotEmpty ? '- Ghi chú: $note\n' : ''}';
  }

  // ===================== FAQ FALLBACK (giữ logic cũ) =====================

  Future<String> _faqFallback(String normalizedQuestion) async {
    final db = await AppDb.instance.db;
    final faqs = await db.query('faq');

    int bestScore = 0;
    Map<String, Object?>? best;

    for (final f in faqs) {
      final keywords = (f['keywords'] as String).split(',');
      int score = 0;

      for (final kw in keywords) {
        final k = _norm(kw);
        if (k.isEmpty) continue;
        if (normalizedQuestion.contains(k)) score += 2;
      }

      final faqQ = _norm(f['question'] as String);
      if (faqQ.isNotEmpty && normalizedQuestion.contains(faqQ)) score += 3;

      if (score > bestScore) {
        bestScore = score;
        best = f;
      }
    }

    if (best == null || bestScore < 2) {
      return 'Mình chưa chắc câu này. Bạn có thể hỏi theo dạng:\n'
          '• "Tuần trước học môn gì?"\n'
          '• "Hôm qua có bài tập gì?"\n'
          '• "Bài kiểm tra lần trước mấy điểm?"\n\n'
          'Hoặc các từ khoá như: "gia hạn học phí", "đóng học phí", "đăng ký môn".';
    }

    final answer = best['answer'] as String;
    final category = (best['category'] as String?) ?? 'FAQ';
    return '[$category]\n$answer';
  }

  // ===================== HELPERS =====================

  bool _matchAny(String q, List<String> patterns) {
    for (final p in patterns) {
      if (q.contains(p)) return true;
    }
    return false;
  }

  String _fmtDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  String _dayName(int d) {
    switch (d) {
      case 1:
        return 'T2';
      case 2:
        return 'T3';
      case 3:
        return 'T4';
      case 4:
        return 'T5';
      case 5:
        return 'T6';
      case 6:
        return 'T7';
      case 7:
        return 'CN';
      default:
        return 'N/A';
    }
  }

  // Chuẩn hoá: lowercase + bỏ dấu đơn giản + bỏ ký tự lạ
  String _norm(String s) {
    var x = s.toLowerCase().trim();

    const map = {
      'à': 'a',
      'á': 'a',
      'ạ': 'a',
      'ả': 'a',
      'ã': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ậ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ặ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'è': 'e',
      'é': 'e',
      'ẹ': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ệ': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ì': 'i',
      'í': 'i',
      'ị': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ò': 'o',
      'ó': 'o',
      'ọ': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ộ': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ợ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ù': 'u',
      'ú': 'u',
      'ụ': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ự': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ỳ': 'y',
      'ý': 'y',
      'ỵ': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'đ': 'd',
    };

    final b = StringBuffer();
    for (final ch in x.split('')) {
      b.write(map[ch] ?? ch);
    }

    x = b.toString();
    x = x.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    x = x.replaceAll(RegExp(r'\s+'), ' ').trim();
    return x;
  }
}
