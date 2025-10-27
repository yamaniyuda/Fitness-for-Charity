import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../main.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

// Simple Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  bool _loading = false;

  void _login() async {
    final email = _emailC.text.trim();
    final pass = _passC.text;

    if (email.isEmpty || pass.isEmpty) {
      messengerKey.currentState?.showSnackBar(const SnackBar(content: Text('Enter email and password')));
      return;
    }

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final ok = await DBHelper.instance.validateUser(email, pass);

      if (!mounted) return;
      setState(() => _loading = false);

      if (ok) {
        navKey.currentState?.pushReplacement(MaterialPageRoute(builder: (_) =>  const HomeScreen()));
      } else {
        messengerKey.currentState?.showSnackBar(const SnackBar(content: Text('Invalid credentials')));
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      messengerKey.currentState?.showSnackBar(SnackBar(content: Text('Login error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _emailC, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: _passC, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _login,
              child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Login'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => navKey.currentState?.push(MaterialPageRoute(builder: (_) => const SignUpScreen())),
              child: const Text('Don\'t have an account? Sign up'),
            )
          ],
        ),
      ),
    );
  }
}
