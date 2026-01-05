import 'package:flutter/material.dart';

class TimeTableGrid extends StatelessWidget {
  final List<Map<String, Object?>> items;
  final Map<int, String> days; // 2..8 (T2..CN)
  final int periods; // ví dụ 12

  /// Tap vào ô:
  /// - existing != null => ô có môn (sửa)
  /// - existing == null => ô trống (thêm)
  final void Function(Map<String, Object?>? existing, int day, int period) onTapCell;

  /// (Tuỳ chọn) long press để mở menu Sửa/Xoá
  final void Function(Map<String, Object?> existing)? onLongPressCell;

  const TimeTableGrid({
    super.key,
    required this.items,
    required this.days,
    this.periods = 12,
    required this.onTapCell,
    this.onLongPressCell,
  });

  @override
  Widget build(BuildContext context) {
    // map key: "day-period" -> item
    final cellMap = <String, Map<String, Object?>>{};
    for (final it in items) {
      final d = it['day'] as int?;
      final p = it['period'] as int?;
      if (d == null || p == null) continue;
      cellMap['$d-$p'] = it;
    }

    final dayKeys = days.keys.toList()..sort(); // [2..8]

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Table(
          defaultColumnWidth: const FixedColumnWidth(130),
          border: TableBorder.all(color: Theme.of(context).dividerColor),
          children: [
            _buildHeaderRow(context, dayKeys),
            for (int period = 1; period <= periods; period++)
              _buildPeriodRow(context, dayKeys, period, cellMap),
          ],
        ),
      ),
    );
  }

  TableRow _buildHeaderRow(BuildContext context, List<int> dayKeys) {
    return TableRow(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      children: [
        _headerCell(context, 'Tiết'),
        for (final day in dayKeys) _headerCell(context, days[day] ?? 'Thứ $day'),
      ],
    );
  }

  TableRow _buildPeriodRow(
      BuildContext context,
      List<int> dayKeys,
      int period,
      Map<String, Map<String, Object?>> cellMap,
      ) {
    return TableRow(
      children: [
        _periodCell(context, period),
        for (final day in dayKeys)
          _lessonCell(
            context: context,
            item: cellMap['$day-$period'],
            onTap: () => onTapCell(cellMap['$day-$period'], day, period),
            onLongPress: () {
              final existing = cellMap['$day-$period'];
              if (existing != null && onLongPressCell != null) {
                onLongPressCell!(existing);
              }
            },
          ),
      ],
    );
  }

  Widget _headerCell(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _periodCell(BuildContext context, int period) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(10),
      child: Text(
        '$period',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _lessonCell({
    required BuildContext context,
    required Map<String, Object?>? item,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) {
    final subject = (item?['subject'] as String?)?.trim() ?? '';
    final room = (item?['room'] as String?)?.trim() ?? '';
    final teacher = (item?['teacher'] as String?)?.trim() ?? '';

    final hasData = subject.isNotEmpty;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.all(8),
        child: hasData
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subject,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            if (room.isNotEmpty)
              Text(
                room,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (teacher.isNotEmpty)
              Text(
                teacher,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        )
            : Center(
          child: Text(
            '—',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
        ),
      ),
    );
  }
}
