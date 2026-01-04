import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  final void Function(String userId) onLoggedIn;
  const LoginPage({super.key, required this.onLoggedIn});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = AuthService();
  final _idCtrl = TextEditingController(text: '123456');
  final _pwCtrl = TextEditingController(text: '123456');
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    final err = await _auth.login(id: _idCtrl.text.trim(), password: _pwCtrl.text);
    setState(() => _loading = false);

    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    widget.onLoggedIn(_idCtrl.text.trim());
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  Image.asset('assets/hutech.png', height: 90),
                  const SizedBox(height: 12),
                  const Text(
                    'HUTECH Timetable',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _idCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ID đăng nhập',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pwCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _login,
                      icon: _loading
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.login),
                      label: Text(_loading ? 'Đang đăng nhập...' : 'Đăng nhập'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Tài khoản demo: ID=123456, PW=123456',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
