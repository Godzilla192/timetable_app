import 'package:flutter/material.dart';
import '../services/semester_service.dart';
import '../services/timetable_service.dart';

class TimetablePage extends StatefulWidget {
  final String userId;
  const TimetablePage({super.key, required this.userId});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  final _semesterService = SemesterService();
  final _service = TimetableService();

  List<Map<String, Object?>> _semesters = [];
  int? _semesterId;
  int _week = 1;

  List<Map<String, Object?>> _items = [];
  bool _loading = true;

  static const _days = <int, String>{
    1: 'Thứ 2',
    2: 'Thứ 3',
    3: 'Thứ 4',
    4: 'Thứ 5',
    5: 'Thứ 6',
    6: 'Thứ 7',
    7: 'CN',
  };

  @override
  void initState() {
    super.initState();
    _loadSemesters();
  }

  Future<void> _loadSemesters() async {
    setState(() => _loading = true);
    final semesters = await _semesterService.getSemesters();
    _semesters = semesters;
    _semesterId ??= semesters.isNotEmpty ? (semesters.first['id'] as int) : null;
    await _loadItems();
  }

  Future<void> _loadItems() async {
    if (_semesterId == null) {
      setState(() {
        _items = [];
        _loading = false;
      });
      return;
    }
    final rows = await _service.getItems(
      userId: widget.userId,
      semesterId: _semesterId!,
      week: _week,
    );
    setState(() {
      _items = rows;
      _loading = false;
    });
  }

  Future<void> _openEditor({Map<String, Object?>? existing}) async {
    if (_semesterId == null) return;

    final subjectCtrl = TextEditingController(text: existing?['subject'] as String? ?? '');
    final roomCtrl = TextEditingController(text: existing?['room'] as String? ?? '');
    final teacherCtrl = TextEditingController(text: existing?['teacher'] as String? ?? '');
    final noteCtrl = TextEditingController(text: existing?['note'] as String? ?? '');

    int day = (existing?['day'] as int?) ?? 1;
    int period = (existing?['period'] as int?) ?? 1;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(existing == null ? 'Thêm môn học' : 'Sửa môn học'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subjectCtrl,
                  decoration: const InputDecoration(labelText: 'Môn học'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: day,
                        items: _days.entries
                            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: (v) => day = v ?? day,
                        decoration: const InputDecoration(labelText: 'Thứ'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: period,
                        items: List.generate(12, (i) => i + 1)
                            .map((p) => DropdownMenuItem(value: p, child: Text('Tiết $p')))
                            .toList(),
                        onChanged: (v) => period = v ?? period,
                        decoration: const InputDecoration(labelText: 'Tiết'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: roomCtrl,
                  decoration: const InputDecoration(labelText: 'Phòng'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: teacherCtrl,
                  decoration: const InputDecoration(labelText: 'Giảng viên'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(labelText: 'Ghi chú'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () {
                if (subjectCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );

    if (saved != true) return;

    final data = <String, Object?>{
      'user_id': widget.userId,
      'semester_id': _semesterId!,
      'week': _week,
      'day': day,
      'period': period,
      'subject': subjectCtrl.text.trim(),
      'room': roomCtrl.text.trim(),
      'teacher': teacherCtrl.text.trim(),
      'note': noteCtrl.text.trim(),
    };

    if (existing == null) {
      await _service.addItem(data);
    } else {
      await _service.updateItem(existing['id'] as int, data);
    }
    await _loadItems();
  }

  Future<void> _deleteItem(int id) async {
    await _service.deleteItem(id);
    await _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    final semesterItems = _semesters
        .map((s) => DropdownMenuItem<int>(
      value: s['id'] as int,
      child: Text(s['name'] as String),
    ))
        .toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _semesterId,
                    items: semesterItems,
                    onChanged: (v) async {
                      setState(() => _semesterId = v);
                      await _loadItems();
                    },
                    decoration: const InputDecoration(labelText: 'Học kỳ'),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 130,
                  child: DropdownButtonFormField<int>(
                    value: _week,
                    items: List.generate(20, (i) => i + 1)
                        .map((w) => DropdownMenuItem(value: w, child: Text('Tuần $w')))
                        .toList(),
                    onChanged: (v) async {
                      setState(() => _week = v ?? 1);
                      await _loadItems();
                    },
                    decoration: const InputDecoration(labelText: 'Tuần'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                  ? const Center(child: Text('Chưa có thời khóa biểu tuần này'))
                  : ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final it = _items[i];
                  final day = _days[it['day'] as int] ?? 'Thứ ?';
                  final period = it['period'] as int;
                  final subject = it['subject'] as String;
                  final room = (it['room'] as String?) ?? '';
                  final teacher = (it['teacher'] as String?) ?? '';
                  final note = (it['note'] as String?) ?? '';
                  return ListTile(
                    title: Text('$day • Tiết $period • $subject'),
                    subtitle: Text([
                      if (room.isNotEmpty) 'Phòng: $room',
                      if (teacher.isNotEmpty) 'GV: $teacher',
                      if (note.isNotEmpty) 'Note: $note',
                    ].join('  |  ')),
                    onTap: () => _openEditor(existing: it),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteItem(it['id'] as int),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
