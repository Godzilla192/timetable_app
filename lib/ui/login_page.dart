import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  final void Function(String userId) onLoggedIn;
  const LoginPage({super.key, required this.onLoggedIn});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idCtrl = TextEditingController(text: '123456');
  final _pwCtrl = TextEditingController(text: '123456');
  bool _loading = false;

  // Map ID -> email giả để dùng Firebase Email/Password
  String _emailFromId(String id) => '${id.trim()}@timetable-app-2026.local';

  Future<void> _login() async {
    final id = _idCtrl.text.trim();
    final pw = _pwCtrl.text;

    if (id.isEmpty || pw.isEmpty) {
      _toast('Vui lòng nhập ID và mật khẩu');
      return;
    }

    setState(() => _loading = true);
    try {
      final email = _emailFromId(id);

      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pw,
      );

      final user = cred.user;
      if (user == null) throw Exception('Không lấy được thông tin người dùng.');

      // Merge profile (không reset createdAt)
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'loginId': id,
        'email': user.email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      widget.onLoggedIn(user.uid);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _toast(_friendlyAuthError(e));
    } catch (e) {
      if (!mounted) return;
      _toast('Lỗi: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    final id = _idCtrl.text.trim();
    final pw = _pwCtrl.text;

    if (id.isEmpty || pw.isEmpty) {
      _toast('Vui lòng nhập ID và mật khẩu');
      return;
    }

    setState(() => _loading = true);
    try {
      final email = _emailFromId(id);

      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pw,
      );

      final user = cred.user!;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'loginId': id,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      _toast('Đăng ký thành công!');
      widget.onLoggedIn(user.uid);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _toast(_friendlyRegisterError(e));
    } catch (e) {
      if (!mounted) return;
      _toast('Lỗi: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
        return 'Sai mật khẩu.';
      case 'user-not-found':
        return 'ID chưa đăng ký. Hãy bấm Đăng ký.';
      case 'network-request-failed':
        return 'Lỗi mạng. Kiểm tra Internet.';
      default:
        return e.message ?? 'Đăng nhập thất bại.';
    }
  }

  String _friendlyRegisterError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'ID này đã tồn tại. Hãy đăng nhập.';
      case 'weak-password':
        return 'Mật khẩu quá yếu (tối thiểu 6 ký tự).';
      case 'network-request-failed':
        return 'Lỗi mạng. Kiểm tra Internet.';
      default:
        return e.message ?? 'Đăng ký thất bại.';
    }
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

                  // Đăng nhập
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
                      label: Text(_loading ? 'Đang xử lý...' : 'Đăng nhập'),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Đăng ký
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _register,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Đăng ký'),
                    ),
                  ),

                  const SizedBox(height: 10),
                  const Text(
                    'Demo: ID=123456, PW=123456',
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
