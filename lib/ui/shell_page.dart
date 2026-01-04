import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_page.dart';
import 'timetable_page.dart';
import 'exam_page.dart';
import 'chat_page.dart';
import 'profile_page.dart';

class ShellPage extends StatefulWidget {
  final String userId;
  final VoidCallback onLoggedOut;
  const ShellPage({super.key, required this.userId, required this.onLoggedOut});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _index = 0;
  final _auth = AuthService();

  Future<void> _logout() async {
    await _auth.logout();
    widget.onLoggedOut();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        onOpenTimetable: () => setState(() => _index = 1),
        onOpenExam: () => setState(() => _index = 2),
        onOpenChat: () => setState(() => _index = 3),
      ),
      TimetablePage(userId: widget.userId),
      ExamPage(userId: widget.userId),
      ChatPage(userId: widget.userId),
      ProfilePage(userId: widget.userId, onLoggedOut: _logout),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        titleSpacing: 12,
        title: Row(
          children: [
            Image.asset(
              'assets/hutech.png',
              height: 34,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Tri thức • Đạo đức • Sáng tạo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'TKB'),
          NavigationDestination(icon: Icon(Icons.assignment), label: 'Lịch thi'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Hỏi đáp'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }
}
