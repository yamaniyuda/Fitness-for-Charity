import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

import '../database/database_helper.dart';
import '../main.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _confirmC = TextEditingController();
  final _usernameC = TextEditingController();

  bool _loading = false;
  bool _fetchingCountryList = true;

  String? _selectedCountry;
  List<String> _countries = [];

  double _passwordStrength = 0.0;
  String _passwordFeedback = "";

  @override
  void initState() {
    super.initState();
    _fetchCountryList();

    _passC.addListener(() {
      _checkPasswordStrength(_passC.text);
    });
  }

  // Fetch country list (name only)
  Future<void> _fetchCountryList() async {
    try {
      final uri = Uri.parse(
          'https://restcountries.com/v3.1/independent?status=true&fields=name');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        final countryNames = data
            .map((e) => e['name']?['common'])
            .whereType<String>()
            .toList()
          ..sort((a, b) => a.compareTo(b));

        if (mounted) {
          setState(() {
            _countries = countryNames;
            _fetchingCountryList = false;
            _selectedCountry ??=
                _countries.isNotEmpty ? _countries.first : null;
          });
        }
      } else {
        setState(() => _fetchingCountryList = false);
        print('Failed to fetch countries. Status: ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _fetchingCountryList = false);
      print('Error fetching countries: $e');
    }
  }

  // Password strength + Have I Been Pwned check
  Future<void> _checkPasswordStrength(String password) async {
    if (password.isEmpty) {
      setState(() {
        _passwordStrength = 0;
        _passwordFeedback = "";
      });
      return;
    }

    double strength = 0;
    String feedback = "Weak password";

    // Basic strength checks
    if (password.length >= 8) strength += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[!@#\$&*~]').hasMatch(password)) strength += 0.25;

    // Check if password has been pwned
    try {
      final hash = sha1.convert(utf8.encode(password)).toString().toUpperCase();
      final prefix = hash.substring(0, 5);
      final suffix = hash.substring(5);

      final res = await http.get(
          Uri.parse('https://api.pwnedpasswords.com/range/$prefix'));

      if (res.statusCode == 200) {
        final lines = res.body.split('\n');
        final match = lines.firstWhere(
          (line) => line.startsWith(suffix),
          orElse: () => '',
        );

        if (match.isNotEmpty) {
          final count = int.tryParse(match.split(':')[1]) ?? 0;
          if (count > 0) {
            strength = 0.1; // force weak
            feedback = "This password appeared in $count breaches!";
          }
        }
      }
    } catch (e) {
      print("HIBP API check failed: $e");
    }

    // Feedback message
    if (strength < 0.25) {
      feedback = "Very Weak";
    } else if (strength < 0.5) {
      feedback = "Weak";
    } else if (strength < 0.75) {
      feedback = "Medium";
    } else {
      feedback = "Strong";
    }

    setState(() {
      _passwordStrength = strength;
      _passwordFeedback = feedback;
    });
  }

  // Sign-up logic
  void _signup() async {
    final email = _emailC.text.trim();
    final pass = _passC.text;
    final conf = _confirmC.text;
    final username = _usernameC.text.trim();
    final country = _selectedCountry ?? '';

    if (email.isEmpty || pass.isEmpty || username.isEmpty || country.isEmpty) {
      messengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (pass != conf) {
      messengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final exists = await DBHelper.instance.userExists(email);
      if (exists) {
        setState(() => _loading = false);
        messengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Email already registered')),
        );
        return;
      }

      final created =
          await DBHelper.instance.createUser(email, pass, username, country);

      setState(() => _loading = false);

      if (created) {
        messengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Account created. Please log in.')),
        );
        navKey.currentState?.pop();
      } else {
        messengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Failed to create account')),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Sign up error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameC,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 12),
            _fetchingCountryList
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : DropdownButtonFormField2<String>(
                    value: _selectedCountry,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                    dropdownStyleData: DropdownStyleData(
                      maxHeight: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: _countries
                        .map((country) => DropdownMenuItem(
                              value: country,
                              child: Text(country),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedCountry = value),
                  ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailC,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passC,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _passwordStrength,
              backgroundColor: Colors.grey.shade300,
              color: _passwordStrength < 0.5
                  ? Colors.red
                  : _passwordStrength < 0.75
                      ? Colors.orange
                      : Colors.green,
              minHeight: 6,
            ),
            const SizedBox(height: 4),
            Text(
              _passwordFeedback,
              style: TextStyle(
                color: _passwordStrength < 0.5
                    ? Colors.red
                    : _passwordStrength < 0.75
                        ? Colors.orange
                        : Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmC,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _signup,
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
