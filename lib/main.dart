import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'ui/login_page.dart';
import 'ui/shell_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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

class _Bootstrapper extends StatelessWidget {
  const _Bootstrapper();

  @override
  Widget build(BuildContext context) {
    // Lắng nghe trạng thái đăng nhập FirebaseAuth
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        // Đang load trạng thái đăng nhập
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snap.data;
        if (user == null) {
          // Chưa đăng nhập
          return LoginPage(
            onLoggedIn: (_) {
              // Không cần setState nữa vì authStateChanges sẽ tự cập nhật UI
            },
          );
        }

        // Đã đăng nhập
        return ShellPage(
          userId: user.uid,
          onLoggedOut: () async {
            await FirebaseAuth.instance.signOut();
          },
        );
      },
    );
  }
}
