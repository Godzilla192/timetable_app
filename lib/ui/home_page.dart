import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final VoidCallback onOpenTimetable;
  final VoidCallback onOpenExam;
  final VoidCallback onOpenChat;

  const HomePage({
    super.key,
    required this.onOpenTimetable,
    required this.onOpenExam,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const Text(
          'Truy cập nhanh',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12),
            boxShadow: const [
              BoxShadow(
                blurRadius: 12,
                spreadRadius: 0,
                offset: Offset(0, 6),
                color: Color(0x14000000),
              ),
            ],
          ),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,

            // ✅ cao hơn để chữ 2 dòng không tràn
            childAspectRatio: 0.92,

            children: [
              _QuickTile(
                icon: Icons.table_rows_rounded,
                label: 'Thời khóa biểu',
                color: const Color(0xFF1E88E5),
                onTap: onOpenTimetable,
              ),
              _QuickTile(
                icon: Icons.assignment_rounded,
                label: 'Lịch thi',
                color: const Color(0xFF8E24AA),
                onTap: onOpenExam,
              ),
              _QuickTile(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Hỏi đáp',
                color: const Color(0xFF43A047),
                onTap: onOpenChat,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tip: Vào TKB để xem theo tuần/học kỳ và đặt nhắc lịch trước giờ học.',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F9FC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 10),

              // ✅ fix overflow: cho tối đa 2 dòng + ellipsis
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
