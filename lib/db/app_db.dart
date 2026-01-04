import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDb {
  AppDb._();
  static final AppDb instance = AppDb._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final basePath = await getDatabasesPath();
    final dbPath = p.join(basePath, 'timetable_app.db');

    return openDatabase(
      dbPath,
      version: 3, // ✅ nâng lên 3 để thêm email + homework + tests
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seed(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // v1 -> v2: chat schema + FAQ
        if (oldVersion < 2) {
          await _createChatSchema(db);
          await _seedFaqIfEmpty(db);
        }

        // v2 -> v3: thêm email + homework + tests + grade items
        if (oldVersion < 3) {
          // ✅ email cho users
          await db.execute("ALTER TABLE users ADD COLUMN email TEXT");

          // ✅ homework + tests
          await _createStudySchema(db);

          // seed mẫu (nếu chưa có)
          await _seedStudyIfEmpty(db, userId: '123456');
        }
      },
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
CREATE TABLE users(
  id TEXT PRIMARY KEY,
  full_name TEXT NOT NULL,
  email TEXT,                 -- ✅ Gmail
  salt TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  avatar_path TEXT,
  created_at INTEGER NOT NULL
);
''');

    await db.execute('''
CREATE TABLE semesters(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  start_date TEXT,
  end_date TEXT
);
''');

    await db.execute('''
CREATE TABLE timetable_items(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  semester_id INTEGER NOT NULL,
  week INTEGER NOT NULL,
  day INTEGER NOT NULL,      -- 1=Mon..7
  period INTEGER NOT NULL,   -- 1..12
  subject TEXT NOT NULL,
  room TEXT,
  teacher TEXT,
  note TEXT,
  FOREIGN KEY(user_id) REFERENCES users(id),
  FOREIGN KEY(semester_id) REFERENCES semesters(id)
);
''');

    await db.execute(
      'CREATE INDEX idx_timetable_u_s_w ON timetable_items(user_id, semester_id, week);',
    );

    await db.execute('''
CREATE TABLE exams(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  semester_id INTEGER NOT NULL,
  subject TEXT NOT NULL,
  date TEXT NOT NULL,   -- yyyy-mm-dd
  time TEXT NOT NULL,   -- HH:mm
  room TEXT,
  note TEXT,
  FOREIGN KEY(user_id) REFERENCES users(id),
  FOREIGN KEY(semester_id) REFERENCES semesters(id)
);
''');

    await db.execute(
      'CREATE INDEX idx_exams_u_s ON exams(user_id, semester_id);',
    );

    // ✅ Chat/FAQ schema
    await _createChatSchema(db);

    // ✅ Study schema (homework/tests)
    await _createStudySchema(db);
  }

  Future<void> _createStudySchema(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS homework(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  semester_id INTEGER NOT NULL,
  date TEXT NOT NULL,        -- yyyy-mm-dd
  subject TEXT NOT NULL,
  content TEXT NOT NULL,
  FOREIGN KEY(user_id) REFERENCES users(id),
  FOREIGN KEY(semester_id) REFERENCES semesters(id)
);
''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_homework_u_s_d ON homework(user_id, semester_id, date);',
    );

    await db.execute('''
CREATE TABLE IF NOT EXISTS tests(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  semester_id INTEGER NOT NULL,
  date TEXT NOT NULL,        -- yyyy-mm-dd
  subject TEXT NOT NULL,
  title TEXT NOT NULL,       -- VD: Kiểm tra 15p, Giữa kỳ...
  score REAL NOT NULL,       -- điểm
  note TEXT,
  FOREIGN KEY(user_id) REFERENCES users(id),
  FOREIGN KEY(semester_id) REFERENCES semesters(id)
);
''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_tests_u_s_d ON tests(user_id, semester_id, date);',
    );
  }

  Future<void> _seed(Database db) async {
    // Seed semesters
    final semester1Id = await db.insert('semesters', {
      'name': 'HK1 2025-2026',
      'start_date': '2025-09-01',
      'end_date': '2026-01-15',
    });
    final semester2Id = await db.insert('semesters', {
      'name': 'HK2 2025-2026',
      'start_date': '2026-02-15',
      'end_date': '2026-06-30',
    });

    // Seed default user
    final salt = _genSalt();
    final hash = hashPassword(password: '123456', salt: salt);

    await db.insert('users', {
      'id': '123456',
      'full_name': 'Sinh viên HUTECH',
      'email': 'sv123456@gmail.com', // ✅ Gmail mặc định (đổi được)
      'salt': salt,
      'password_hash': hash,
      'avatar_path': null,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });

    // Seed sample timetable
    await db.insert('timetable_items', {
      'user_id': '123456',
      'semester_id': semester1Id,
      'week': 1,
      'day': 2,
      'period': 1,
      'subject': 'Lập trình Flutter',
      'room': 'E1-05.02',
      'teacher': 'GV A',
      'note': 'Mang laptop',
    });

    await db.insert('timetable_items', {
      'user_id': '123456',
      'semester_id': semester1Id,
      'week': 1,
      'day': 5,
      'period': 7,
      'subject': 'Cơ sở dữ liệu',
      'room': 'E1-03.01',
      'teacher': 'GV B',
      'note': '',
    });

    // Seed exam
    await db.insert('exams', {
      'user_id': '123456',
      'semester_id': semester1Id,
      'subject': 'Lập trình Flutter',
      'date': '2025-12-20',
      'time': '08:00',
      'room': 'A2-101',
      'note': 'Mang thẻ SV',
    });

    // Seed one item semester2
    await db.insert('timetable_items', {
      'user_id': '123456',
      'semester_id': semester2Id,
      'week': 1,
      'day': 3,
      'period': 4,
      'subject': 'Kỹ thuật phần mềm',
      'room': 'E2-02.03',
      'teacher': 'GV C',
      'note': '',
    });

    // ✅ Seed FAQ
    await _seedFaqIfEmpty(db);

    // ✅ Seed homework/tests cho HK1
    await _seedStudyIfEmpty(db, userId: '123456');
  }

  Future<void> _seedStudyIfEmpty(Database db, {required String userId}) async {
    // lấy semester_id đầu tiên (HK1)
    final sem = await db.rawQuery('SELECT id FROM semesters ORDER BY id LIMIT 1');
    if (sem.isEmpty) return;
    final semesterId = sem.first['id'] as int;

    final hwCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM homework WHERE user_id=?', [userId]),
    ) ??
        0;
    final testCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM tests WHERE user_id=?', [userId]),
    ) ??
        0;

    if (hwCount == 0) {
      await db.insert('homework', {
        'user_id': userId,
        'semester_id': semesterId,
        'date': '2025-11-10',
        'subject': 'Lập trình Flutter',
        'content': 'Bài tập: làm UI Scaffold + Row/Column + Card',
      });
      await db.insert('homework', {
        'user_id': userId,
        'semester_id': semesterId,
        'date': '2025-11-11',
        'subject': 'Cơ sở dữ liệu',
        'content': 'Bài tập: viết truy vấn SELECT + JOIN cơ bản',
      });
    }

    if (testCount == 0) {
      await db.insert('tests', {
        'user_id': userId,
        'semester_id': semesterId,
        'date': '2025-11-08',
        'subject': 'Lập trình Flutter',
        'title': 'Kiểm tra 15 phút',
        'score': 8.5,
        'note': 'Ôn widget cơ bản',
      });
      await db.insert('tests', {
        'user_id': userId,
        'semester_id': semesterId,
        'date': '2025-11-05',
        'subject': 'Cơ sở dữ liệu',
        'title': 'Quiz 1',
        'score': 7.0,
        'note': '',
      });
    }
  }

  Future<void> _createChatSchema(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS faq(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category TEXT,
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  keywords TEXT NOT NULL
);
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS chat_sessions(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  created_at INTEGER NOT NULL
);
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS chat_messages(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL,
  sender TEXT NOT NULL,      -- 'user' | 'bot'
  text TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  FOREIGN KEY(session_id) REFERENCES chat_sessions(id)
);
''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_chat_sessions_user ON chat_sessions(user_id, created_at);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_chat_messages_session ON chat_messages(session_id, created_at);',
    );
  }

  Future<void> _seedFaqIfEmpty(Database db) async {
    final r = await db.rawQuery('SELECT COUNT(*) as c FROM faq');
    final count = (r.first['c'] as int?) ?? 0;
    if (count > 0) return;

    final faqs = <Map<String, Object?>>[
      {
        'category': 'Học phí',
        'question': 'Gia hạn học phí như thế nào?',
        'answer':
        'Bạn thường cần: (1) Đơn xin gia hạn học phí, (2) Lý do/Minh chứng (nếu có), '
            '(3) Thông tin MSSV, lớp. Quy trình phổ biến: nộp đơn theo hướng dẫn của Khoa/Phòng Tài chính – Kế toán '
            'hoặc theo cổng dịch vụ SV (nếu trường có).',
        'keywords': 'gia hạn,học phí,trễ hạn,đóng học phí,đơn gia hạn',
      },
      {
        'category': 'Lịch thi',
        'question': 'Xem lịch thi ở đâu?',
        'answer':
        'Bạn xem trong tab “Lịch thi” của app (nếu đã nhập) hoặc trên cổng sinh viên/website thông báo.',
        'keywords': 'lịch thi,xem lịch thi,phòng thi,giờ thi',
      },
    ];

    for (final f in faqs) {
      await db.insert('faq', f);
    }
  }

  static String _genSalt() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String hashPassword({required String password, required String salt}) {
    final bytes = utf8.encode('$salt|$password');
    return sha256.convert(bytes).toString();
  }
}
