import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../main.dart';

// Simple Sign Up Screen
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _confirmC = TextEditingController();
  bool _loading = false;

  void _signup() async {
    final email = _emailC.text.trim();
    final pass = _passC.text;
    final conf = _confirmC.text;

    if (email.isEmpty || pass.isEmpty) {
      messengerKey.currentState?.showSnackBar(const SnackBar(content: Text('Enter email and password')));
      return;
    }
    if (pass != conf) {
      messengerKey.currentState?.showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final exists = await DBHelper.instance.userExists(email);
      if (exists) {
        if (!mounted) return;
        setState(() => _loading = false);
        messengerKey.currentState?.showSnackBar(const SnackBar(content: Text('Email already registered')));
        return;
      }

      final created = await DBHelper.instance.createUser(email, pass);
      if (!mounted) return;
      setState(() => _loading = false);

      if (created) {
        messengerKey.currentState?.showSnackBar(const SnackBar(content: Text('Account created. Please log in.')));
        navKey.currentState?.pop();
      } else {
        messengerKey.currentState?.showSnackBar(const SnackBar(content: Text('Failed to create account')));
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      messengerKey.currentState?.showSnackBar(SnackBar(content: Text('Sign up error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _emailC, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: _passC, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 12),
            TextField(controller: _confirmC, decoration: const InputDecoration(labelText: 'Confirm password'), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _loading ? null : _signup, child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Sign up')),
          ],
        ),
      ),
    );
  }
}
