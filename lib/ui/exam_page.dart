import 'package:flutter/material.dart';
import '../services/exam_service.dart';
import '../services/semester_service.dart';

class ExamPage extends StatefulWidget {
  final String userId;
  const ExamPage({super.key, required this.userId});

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  final _semesterService = SemesterService();
  final _service = ExamService();

  List<Map<String, Object?>> _semesters = [];
  int? _semesterId;

  List<Map<String, Object?>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSemesters();
  }

  Future<void> _loadSemesters() async {
    setState(() => _loading = true);
    _semesters = await _semesterService.getSemesters();
    _semesterId ??= _semesters.isNotEmpty ? (_semesters.first['id'] as int) : null;
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
    final rows = await _service.getExams(userId: widget.userId, semesterId: _semesterId!);
    setState(() {
      _items = rows;
      _loading = false;
    });
  }

  Future<void> _openEditor({Map<String, Object?>? existing}) async {
    if (_semesterId == null) return;

    final subjectCtrl = TextEditingController(text: existing?['subject'] as String? ?? '');
    final dateCtrl = TextEditingController(text: existing?['date'] as String? ?? '2025-12-20');
    final timeCtrl = TextEditingController(text: existing?['time'] as String? ?? '08:00');
    final roomCtrl = TextEditingController(text: existing?['room'] as String? ?? '');
    final noteCtrl = TextEditingController(text: existing?['note'] as String? ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Thêm lịch thi' : 'Sửa lịch thi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: subjectCtrl, decoration: const InputDecoration(labelText: 'Môn thi')),
              const SizedBox(height: 8),
              TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Ngày (yyyy-mm-dd)')),
              const SizedBox(height: 8),
              TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'Giờ (HH:mm)')),
              const SizedBox(height: 8),
              TextField(controller: roomCtrl, decoration: const InputDecoration(labelText: 'Phòng')),
              const SizedBox(height: 8),
              TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Ghi chú')),
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
      ),
    );

    if (saved != true) return;

    final data = <String, Object?>{
      'user_id': widget.userId,
      'semester_id': _semesterId!,
      'subject': subjectCtrl.text.trim(),
      'date': dateCtrl.text.trim(),
      'time': timeCtrl.text.trim(),
      'room': roomCtrl.text.trim(),
      'note': noteCtrl.text.trim(),
    };

    if (existing == null) {
      await _service.addExam(data);
    } else {
      await _service.updateExam(existing['id'] as int, data);
    }
    await _loadItems();
  }

  Future<void> _delete(int id) async {
    await _service.deleteExam(id);
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
            DropdownButtonFormField<int>(
              value: _semesterId,
              items: semesterItems,
              onChanged: (v) async {
                setState(() => _semesterId = v);
                await _loadItems();
              },
              decoration: const InputDecoration(labelText: 'Học kỳ'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                  ? const Center(child: Text('Chưa có lịch thi'))
                  : ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final it = _items[i];
                  final subject = it['subject'] as String;
                  final date = it['date'] as String;
                  final time = it['time'] as String;
                  final room = (it['room'] as String?) ?? '';
                  final note = (it['note'] as String?) ?? '';

                  return ListTile(
                    title: Text('$subject • $date $time'),
                    subtitle: Text([
                      if (room.isNotEmpty) 'Phòng: $room',
                      if (note.isNotEmpty) 'Note: $note',
                    ].join('  |  ')),
                    onTap: () => _openEditor(existing: it),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(it['id'] as int),
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
