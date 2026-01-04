import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  final String userId;
  final VoidCallback onLoggedOut;

  const ProfilePage({
    super.key,
    required this.userId,
    required this.onLoggedOut,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = AuthService();
  Map<String, Object?>? _user;
  bool _loading = true;

  final _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _user = await _auth.getUser(widget.userId);
    _emailCtrl.text = (_user?['email'] as String?) ?? '';
    setState(() => _loading = false);
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;

    final err = await _auth.updateAvatarFromPickedPath(
      userId: widget.userId,
      pickedImagePath: x.path,
    );

    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    await _load();
  }

  Future<void> _editName() async {
    final ctrl = TextEditingController(text: (_user?['full_name'] as String?) ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi họ tên'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Họ tên'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
        ],
      ),
    );
    if (ok != true) return;

    final name = ctrl.text.trim();
    if (name.isEmpty) return;
    await _auth.updateFullName(userId: widget.userId, fullName: name);
    await _load();
  }

  Future<void> _saveEmail() async {
    final email = _emailCtrl.text.trim();
    final err = await _auth.updateEmail(userId: widget.userId, email: email);

    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật Gmail')));
    await _load();
  }

  Future<void> _changePassword() async {
    final curCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi mật khẩu'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: curCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nhập lại mật khẩu mới'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đổi')),
        ],
      ),
    );

    if (ok != true) return;

    final cur = curCtrl.text;
    final nw = newCtrl.text;
    final cf = confirmCtrl.text;

    if (nw.length < 4) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu mới tối thiểu 4 ký tự')),
      );
      return;
    }
    if (nw != cf) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xác nhận mật khẩu không khớp')),
      );
      return;
    }

    final err = await _auth.changePassword(
      userId: widget.userId,
      currentPassword: cur,
      newPassword: nw,
    );

    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đổi mật khẩu thành công')),
    );
  }

  Future<void> _logout() async {
    await _auth.logout();
    widget.onLoggedOut();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_user == null) return const Center(child: Text('Không tải được user'));

    final fullName = (_user!['full_name'] as String?) ?? 'Sinh viên';
    final avatarPath = _user!['avatar_path'] as String?;
    final email = (_user!['email'] as String?) ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: _pickAvatar,
              child: CircleAvatar(
                radius: 38,
                backgroundImage: (avatarPath != null && File(avatarPath).existsSync())
                    ? FileImage(File(avatarPath))
                    : null,
                child: (avatarPath == null) ? const Icon(Icons.person, size: 42) : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('MSSV: ${widget.userId}', style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(email.isEmpty ? 'Gmail: (chưa đặt)' : 'Gmail: $email',
                      style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: _pickAvatar,
                        icon: const Icon(Icons.image),
                        label: const Text('Đổi ảnh'),
                      ),
                      TextButton.icon(
                        onPressed: _editName,
                        icon: const Icon(Icons.edit),
                        label: const Text('Đổi tên'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),
        const Text('Cập nhật Gmail', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'vd: sv123456@gmail.com',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 46,
          child: FilledButton.icon(
            onPressed: _saveEmail,
            icon: const Icon(Icons.save),
            label: const Text('Lưu Gmail'),
          ),
        ),

        const SizedBox(height: 10),
        ListTile(
          leading: const Icon(Icons.lock),
          title: const Text('Đổi mật khẩu'),
          onTap: _changePassword,
        ),

        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Đăng xuất'),
          ),
        ),
      ],
    );
  }
}
