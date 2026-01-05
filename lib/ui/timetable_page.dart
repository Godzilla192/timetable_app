import 'package:flutter/material.dart';
import '../services/semester_service.dart';
import '../services/timetable_service.dart';
import 'widgets/timetable_grid.dart';

class TimetablePage extends StatefulWidget {
  final String userId;
  const TimetablePage({super.key, required this.userId});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  final _semesterService = SemesterService();
  final _service = TimetableService();

  bool _loading = true;
  List<Map<String, Object?>> _semesters = [];
  int? _semesterId;

  int _week = 1;
  List<Map<String, Object?>> _items = [];

  final _days = const <int, String>{
    2: 'T2',
    3: 'T3',
    4: 'T4',
    5: 'T5',
    6: 'T6',
    7: 'T7',
    8: 'CN',
  };

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final semesters = await _semesterService.getSemesters();
    setState(() {
      _semesters = semesters;
      _semesterId = semesters.isNotEmpty ? (semesters.first['id'] as int) : null;
    });
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

    setState(() => _loading = true);

    final rows = await _service.getItems(
      semesterId: _semesterId!,
      week: _week,
    );

    setState(() {
      _items = rows;
      _loading = false;
    });
  }

  Future<void> _openEditor({
    Map<String, Object?>? existing,
    int? presetDay,
    int? presetPeriod,
  }) async {
    if (_semesterId == null) return;

    final subjectCtrl = TextEditingController(text: existing?['subject'] as String? ?? '');
    final roomCtrl = TextEditingController(text: existing?['room'] as String? ?? '');
    final teacherCtrl = TextEditingController(text: existing?['teacher'] as String? ?? '');
    final noteCtrl = TextEditingController(text: existing?['note'] as String? ?? '');

    // Focus để nhảy ô, giúp gõ tiếng Việt ổn định hơn + UX tốt
    final focusSubject = FocusNode();
    final focusTeacher = FocusNode();
    final focusRoom = FocusNode();
    final focusNote = FocusNode();

    int day = (existing?['day'] as int?) ?? presetDay ?? 2;
    int period = (existing?['period'] as int?) ?? presetPeriod ?? 1;

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
                  focusNode: focusSubject,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  autocorrect: true,
                  enableSuggestions: true,
                  decoration: const InputDecoration(labelText: 'Môn học'),
                  onSubmitted: (_) => focusTeacher.requestFocus(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: teacherCtrl,
                  focusNode: focusTeacher,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  autocorrect: true,
                  enableSuggestions: true,
                  decoration: const InputDecoration(labelText: 'Giảng viên'),
                  onSubmitted: (_) => focusRoom.requestFocus(),
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
                  focusNode: focusRoom,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  autocorrect: true,
                  enableSuggestions: true,
                  decoration: const InputDecoration(labelText: 'Phòng / Link học'),
                  onSubmitted: (_) => focusNote.requestFocus(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteCtrl,
                  focusNode: focusNote,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  autocorrect: true,
                  enableSuggestions: true,
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

    // cleanup FocusNode
    focusSubject.dispose();
    focusTeacher.dispose();
    focusRoom.dispose();
    focusNote.dispose();

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

    final conflict = await _service.hasConflict(
      semesterId: _semesterId!,
      week: _week,
      day: day,
      period: period,
      excludeId: existing?['id'] as int?,
    );

    if (conflict) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Trùng lịch: đã có môn ở thứ/tiết này')),
      );
      return;
    }

    if (existing == null) {
      await _service.addItem(data);
    } else {
      await _service.updateItem(existing['id'] as int, data);
    }
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(width: 10),
                SizedBox(
                  width: 130,
                  child: DropdownButtonFormField<int>(
                    value: _week,
                    items: List.generate(30, (i) => i + 1)
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
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: TimeTableGrid(
                  items: _items,
                  days: _days,
                  periods: 12,
                  onTapCell: (existing, day, period) {
                    _openEditor(existing: existing, presetDay: day, presetPeriod: period);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
