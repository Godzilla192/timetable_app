import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'ui/login_page.dart';
import 'ui/shell_page.dart';

void main() {
  runApp(const TimetableApp());
}

class TimetableApp extends StatelessWidget {
  const TimetableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HUTECH Timetable',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const _Bootstrapper(),
    );
  }
}

class _Bootstrapper extends StatefulWidget {
  const _Bootstrapper();

  @override
  State<_Bootstrapper> createState() => _BootstrapperState();
}

class _BootstrapperState extends State<_Bootstrapper> {
  final _auth = AuthService();
  String? _uid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = await _auth.getCurrentUserId();
    setState(() => _uid = id);
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return LoginPage(
        onLoggedIn: (id) => setState(() => _uid = id),
      );
    }
    return ShellPage(
      userId: _uid!,
      onLoggedOut: () => setState(() => _uid = null),
    );
  }
}
